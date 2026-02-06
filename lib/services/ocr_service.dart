import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/scan_result.dart';

class OCRService {
  // Türkçe ve Latin karakter desteği için
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  // Bilinen form alanları - Türkçe (normalize edilmiş)
  static const Map<String, String> _fieldMappings = {
    'tarih': 'Tarih',
    'kumas parti no': 'Kumaş Parti No',
    'kumasprtno': 'Kumaş Parti No',
    'siparis no': 'Sipariş No',
    'siparisno': 'Sipariş No',
    'ana siparis no': 'Ana Sipariş No',
    'anasiparis no': 'Ana Sipariş No',
    'firma': 'Firma',
    'kumas cinsi': 'Kumaş Cinsi',
    'kumascinsi': 'Kumaş Cinsi',
    'kart miktari': 'Kart Miktarı',
    'kartmiktari': 'Kart Miktarı',
    'siparis termini': 'Sipariş Termini',
    'siparistermini': 'Sipariş Termini',
    'makina no': 'Makina No',
    'makinano': 'Makina No',
    't / m': 'T / M',
    't/m': 'T / M',
    'tm': 'T / M',
    'ham en': 'Ham En',
    'hamen': 'Ham En',
    'gramaj': 'Gramaj',
    'ham en / gramaj': 'Ham En / Gramaj',
    'hamen/gramaj': 'Ham En / Gramaj',
    'cl': 'CL (Course Lenght)',
    'cl (course lenght)': 'CL (Course Lenght)',
    'course lenght': 'CL (Course Lenght)',
    'course length': 'CL (Course Lenght)',
    'puss': 'Puss / Fein',
    'fein': 'Puss / Fein',
    'puss / fein': 'Puss / Fein',
    'puss/fein': 'Puss / Fein',
    'proses': 'Proses',
    'uretime girilis tarihi': 'Üretime Giriliş Tarihi',
    'uretimegirilis tarihi': 'Üretime Giriliş Tarihi',
    'kg / top': 'Kg / Top',
    'kg/top': 'Kg / Top',
    'kgtop': 'Kg / Top',
    'yag ayarlari': 'Yağ Ayarları',
    'yagayarlari': 'Yağ Ayarları',
    'aciklama': 'Açıklama',
    'stok kodu': 'Stok Kodu',
    'stokkodu': 'Stok Kodu',
    'tanimi': 'Tanımı',
    'renk': 'Renk',
    'marka': 'Marka',
    'fire': 'Fire',
    'miktar': 'Miktar',
    'sistem sayisi': 'Sistem Sayısı',
    'sistemsayisi': 'Sistem Sayısı',
    'lot no': 'Lot No',
    'lotno': 'Lot No',
    'depo': 'Depo',
    'p.no': 'P.No',
    'pno': 'P.No',
    'sira': 'Sıra',
    'rp no': 'Rp No',
    'rpno': 'Rp No',
  };

  // Bölüm başlıkları
  static const List<String> _sectionHeaders = [
    'ÖRGÜ İŞ EMRİ',
    'ORGU IS EMRI',
    'İPLİKLER',
    'IPLIKLER',
    'İhracat',
    'Ihracat',
  ];

  Future<ScanResult> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    // Tüm text bloklarını koordinatlarıyla birlikte topla
    List<_TextElement> allElements = [];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        allElements.add(_TextElement(
          text: line.text.trim(),
          top: line.boundingBox.top,
          left: line.boundingBox.left,
          right: line.boundingBox.right,
          bottom: line.boundingBox.bottom,
        ));
      }
    }

    // Y koordinatına göre sırala (yukarıdan aşağıya)
    allElements.sort((a, b) {
      // Önce Y koordinatı (satır)
      int yCompare = a.top.compareTo(b.top);
      if (yCompare.abs() < 15) {
        // Aynı satırda ise X koordinatına göre (soldan sağa)
        return a.left.compareTo(b.left);
      }
      return yCompare;
    });

    // Satırları grupla (aynı Y koordinatındakiler)
    List<List<_TextElement>> groupedLines = _groupIntoLines(allElements);

    // Parse edilmiş satırları oluştur
    List<ParsedLine> parsedLines = [];
    List<TableData> tables = [];

    StringBuffer rawTextBuffer = StringBuffer();

    bool inTable = false;
    List<String> tableHeaders = [];
    List<List<String>> tableRows = [];

    for (var lineGroup in groupedLines) {
      String combinedText = lineGroup.map((e) => e.text).join(' ').trim();

      if (combinedText.isEmpty) continue;

      rawTextBuffer.writeln(combinedText);

      // Bölüm başlığı mı kontrol et
      bool isSection = _sectionHeaders
          .any((h) => combinedText.toUpperCase().contains(h.toUpperCase()));

      if (isSection) {
        // Önceki tabloyu kaydet
        if (inTable && tableRows.isNotEmpty) {
          tables.add(TableData(headers: tableHeaders, rows: tableRows));
          tableHeaders = [];
          tableRows = [];
        }
        inTable = false;

        parsedLines.add(ParsedLine(
          key: combinedText,
          type: combinedText.toUpperCase().contains('İPLİKLER')
              ? LineType.section
              : LineType.header,
        ));
        continue;
      }

      // İPLİKLER tablosu başlıkları
      if (combinedText.contains('Sıra') && combinedText.contains('Stok')) {
        inTable = true;
        tableHeaders = _parseTableRow(combinedText);
        parsedLines.add(ParsedLine(
          key: combinedText,
          type: LineType.tableHeader,
        ));
        continue;
      }

      // Tablo satırı (sayı ile başlıyorsa ve tablodaysak)
      if (inTable && RegExp(r'^\d+\s').hasMatch(combinedText)) {
        tableRows.add(_parseTableRow(combinedText));
        parsedLines.add(ParsedLine(
          key: combinedText,
          type: LineType.tableRow,
        ));
        continue;
      }

      // Anahtar: Değer formatı mı kontrol et
      ParsedLine? parsed = _parseKeyValue(combinedText, lineGroup);

      if (parsed != null) {
        parsedLines.add(parsed);
      } else {
        parsedLines.add(ParsedLine(key: combinedText, type: LineType.normal));
      }
    }

    // Son tabloyu kaydet
    if (tableRows.isNotEmpty) {
      tables.add(TableData(headers: tableHeaders, rows: tableRows));
    }

    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rawText: rawTextBuffer.toString(),
      parsedLines: parsedLines,
      tables: tables,
      createdAt: DateTime.now(),
      imagePath: imagePath,
    );
  }

  List<List<_TextElement>> _groupIntoLines(List<_TextElement> elements) {
    if (elements.isEmpty) return [];

    // Ortalama satır yüksekliğini hesapla
    double avgHeight =
        elements.map((e) => e.bottom - e.top).reduce((a, b) => a + b) /
            elements.length;
    // Satır toleransı: ortalama yüksekliğin yarısı veya minimum 20 piksel
    double lineTolerance = (avgHeight * 0.6).clamp(20, 50);

    List<List<_TextElement>> lines = [];
    List<_TextElement> currentLine = [elements.first];
    double currentY =
        (elements.first.top + elements.first.bottom) / 2; // Merkez Y kullan

    for (int i = 1; i < elements.length; i++) {
      final element = elements[i];
      double elementCenterY = (element.top + element.bottom) / 2;

      // Aynı satırda mı? (Y merkez farkı tolerans içinde)
      if ((elementCenterY - currentY).abs() < lineTolerance) {
        currentLine.add(element);
        // Satır merkezini güncelle
        currentY = currentLine
                .map((e) => (e.top + e.bottom) / 2)
                .reduce((a, b) => a + b) /
            currentLine.length;
      } else {
        // Mevcut satırı X'e göre sırala
        currentLine.sort((a, b) => a.left.compareTo(b.left));
        lines.add(currentLine);
        currentLine = [element];
        currentY = elementCenterY;
      }
    }

    if (currentLine.isNotEmpty) {
      currentLine.sort((a, b) => a.left.compareTo(b.left));
      lines.add(currentLine);
    }

    return lines;
  }

  // Metni normalize et (Türkçe karakterleri ve boşlukları düzenle)
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Bilinen alan adı mı kontrol et
  String? _matchKnownField(String text) {
    final normalized = _normalizeText(text);

    // Direkt eşleşme
    if (_fieldMappings.containsKey(normalized)) {
      return _fieldMappings[normalized];
    }

    // Kısmi eşleşme
    for (final entry in _fieldMappings.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    return null;
  }

  ParsedLine? _parseKeyValue(String text, List<_TextElement> elements) {
    // : ile ayrılmış anahtar-değer
    if (text.contains(':')) {
      final colonIndex = text.indexOf(':');
      final key = text.substring(0, colonIndex).trim();
      final value = text.substring(colonIndex + 1).trim();

      // Bilinen alan adı mı?
      final matchedField = _matchKnownField(key);

      if (matchedField != null) {
        return ParsedLine(
          key: matchedField,
          value: value,
          type: LineType.keyValue,
        );
      }

      // Kısa anahtar ve değer varsa kabul et
      if (key.length < 30 && value.isNotEmpty) {
        return ParsedLine(
          key: key,
          value: value,
          type: LineType.keyValue,
        );
      }
    }

    // İki veya daha fazla parçalı satır (anahtar solda, değer sağda)
    if (elements.length >= 2) {
      // Sol taraftaki elemanları anahtar olarak birleştir
      final leftElements = <_TextElement>[];
      final rightElements = <_TextElement>[];

      // Elemanları konumlarına göre ayır
      double midPoint =
          elements.map((e) => e.left).reduce((a, b) => a + b) / elements.length;

      for (final elem in elements) {
        if (elem.left < midPoint) {
          leftElements.add(elem);
        } else {
          rightElements.add(elem);
        }
      }

      if (leftElements.isNotEmpty && rightElements.isNotEmpty) {
        final key = leftElements.map((e) => e.text).join(' ').trim();
        final value = rightElements.map((e) => e.text).join(' ').trim();

        // Bilinen alan adı mı?
        final matchedField = _matchKnownField(key);

        if (matchedField != null) {
          return ParsedLine(
            key: matchedField,
            value: value,
            type: LineType.keyValue,
          );
        }

        // Solda kısa metin, sağda değer varsa kabul et
        final gap = rightElements.first.left - leftElements.last.right;
        if (gap > 15 && key.length < 30) {
          return ParsedLine(
            key: key,
            value: value,
            type: LineType.keyValue,
          );
        }
      }
    }

    // Bilinen alan adıyla başlıyorsa
    for (final entry in _fieldMappings.entries) {
      final normalizedText = _normalizeText(text);
      if (normalizedText.startsWith(entry.key)) {
        final value = text.substring(entry.key.length).trim();
        // : ile başlıyorsa kaldır
        final cleanValue =
            value.startsWith(':') ? value.substring(1).trim() : value;
        if (cleanValue.isNotEmpty) {
          return ParsedLine(
            key: entry.value,
            value: cleanValue,
            type: LineType.keyValue,
          );
        }
      }
    }

    return null;
  }

  List<String> _parseTableRow(String text) {
    // Birden fazla boşlukla ayır
    return text
        .split(RegExp(r'\s{2,}'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class _TextElement {
  final String text;
  final double top;
  final double left;
  final double right;
  final double bottom;

  _TextElement({
    required this.text,
    required this.top,
    required this.left,
    required this.right,
    required this.bottom,
  });
}
