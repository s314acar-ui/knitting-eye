import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import '../models/scan_result.dart';

class DocumentAIService {
  static const String projectId = 'myapp-470212';
  static const String location = 'eu';
  static const String processorId = '2078fc8cbc2c937f';

  static const Map<String, dynamic> _serviceAccountCredentials = {
    "type": "service_account",
    "project_id": "myapp-470212",
    "private_key_id": "ece1b0823d573019e196277f290a841bf48a7b61",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDMP977ZYMk0V/2\nKE5R5Zgbg5I0mnM+2GrnxX6VrY6ZvQUlsD73T5WeyYvUBsEV18JHrvzUYWifWYrC\nUIReD0d5waGAXtvBUG3gZD2QgNf/m3tfRYgw3SyLA0D6Ah6dSGP86E0JORanSvpP\nWypENUThpr867dRFpSTl63K77sLUGpoec+TmX45rMUFiAzR0yD6n9Frd3ZN7hbBM\nNqyfyI2VaAaeN1tLgPFX8v+XxnIzqzRc4yFvVsodzTGwLVrSmZKfi7g0H7vDN8k+\n757PiRprSFdDHZ3szC/UwDDbHSfVLPM5HykNujofQwzUFWKVdSEAtMUTuh3t5PLu\nVl/6ysGnAgMBAAECggEAAKJcI2SzzQv3Y9DJOXjgiYlVjWNDY1kRr+mNlJJm5HRR\nTUYoU+VD3ivbCswAknxKhqV09IXe6MvC4gqU9qPOgYLH6RmiTg3dYXp+NHIp+Ym2\njtus6hXtuvrGG2ChTrS4VsMz5gju2JMjhtaOIYsWzSqS4nB1nce+/xXFk+7QXQ88\nqrU2c6rGb+1XQq7KPlH+l/2gL6iAvYFHsiD673zahv0OqKvKXaIMZf1vcPXOGak1\nJXdfcVjhujiclko9Qpe1JmXTMbch6bZ8VkeOnOZ8+HnYjKhASEJHSQ4KGyTELn7t\nDBVmQWWX5LNK/IIb8mkV5pA8vywL3Q5K9j6En7NSGQKBgQDnYpGHFS3l8slZW0l1\n+g3b+ssokNEY/cVNEjDBlwlnIEfWSBPpLuSrq1SpLoMv1BV9jVi0pNqcBTmAMWMU\na0/DRu/sTGrozW+BywSUvrifaz9cEdW9FbpLnEF/bS5yEbdxw1hAoUfV5Ax06tEJ\ny1v09kQr8NyF75/NYOPhoUxuWQKBgQDh+k5aMcX4GRQDrBZMfjPjo3Mx8ZtjNWRN\nU5cibQWUGdDAFqyFE+mZSDBZsAdt0QuT/1HuFi9ZXffxxra2k1u+3Bl6ttzrDnDJ\nUhXyN69OYwSL21wVCK8VfeeIUIfGaqK9M8zFdNBgFn9SV9l5eOrdOrLhlZo/LT92\npV/KLsqv/wKBgDWDaW7Zah0VcpXU8/9yDoSC0zuVipaCEoCJpXcQbF9KavLXBqvW\naZJ+dH0QQczs+u9nok1dFyYgWzUXtveA/hiGrnRzFAK1iIV3I58XIPHVxviPM2Sg\nws473DYRVT2SdV+9Mwr3gfqo3Gyp5iCixKi5z/hto0LisY25S9riCCA5AoGBAM25\nQUFtVKwTsJvTO42xyu1vLP0H1o2P2ttmwQ1vMQfuJJPrUG3qfdy00oej8G9yQ1cd\ntmnIupxiJspuPIKkTn7IA04rUZ2QTO+Kkj4roaX8EPR95Cul9zbao0D/B0yEYdlb\nYg1U1irT8F93aJ3kjfSPbrBdsMnZGJCb50O6K33jAoGBAMKeDXMfH7tb6JaZcvWq\n8cRHSfafzFy/+umrQZ0WC2iEngy15ydhPFSL++13xR+afmWJ+h/13xllP2fsgP7N\nVVTPIyLkKqmtDT53gPueRQP+bLYFvMNyZe1wv+Lm3Mp7op0Os7LBvylZlgXlMFqa\nZpGMF/rjCJSzjUmLUkb7sYMd\n-----END PRIVATE KEY-----\n",
    "client_email": "document-ai-service@myapp-470212.iam.gserviceaccount.com",
    "client_id": "109667604549917634078",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
  };

  static const List<String> _fieldOrder = [
    'Kumaş Parti No',
    'Sipariş No',
    'Ana Sipariş No',
    'Firma',
    'Kumaş Cinsi',
    'Kart Miktarı',
    'Sipariş Termini',
    'Makina No',
    'T/M',
    'Ham En / Gramaj',
    'CL (Course Lenght)',
    'Puss / Fein',
    'Proses',
    'Üretime Giriliş Tarihi',
    'Kg / Top',
    'Yağ Ayarları',
    'Açıklama',
    'Tarih',
  ];

  AutoRefreshingAuthClient? _authClient;

  Future<void> _authenticate() async {
    if (_authClient != null) return;
    final credentials = ServiceAccountCredentials.fromJson(_serviceAccountCredentials);
    _authClient = await clientViaServiceAccount(
      credentials,
      ['https://www.googleapis.com/auth/cloud-platform'],
    );
  }

  Future<ScanResult> processImage(String imagePath) async {
    await _authenticate();

    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final extension = imagePath.split('.').last.toLowerCase();
    String mimeType = 'image/jpeg';
    if (extension == 'png') mimeType = 'image/png';
    if (extension == 'gif') mimeType = 'image/gif';
    if (extension == 'webp') mimeType = 'image/webp';

    final url = Uri.parse(
      'https://$location-documentai.googleapis.com/v1/projects/$projectId/locations/$location/processors/$processorId:process',
    );

    final requestBody = {
      'rawDocument': {
        'content': base64Image,
        'mimeType': mimeType,
      },
    };

    final response = await _authClient!.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception('Document AI hatası: ${response.statusCode} - ${response.body}');
    }

    final jsonResponse = jsonDecode(response.body);
    return _parseResponse(jsonResponse, imagePath);
  }

  ScanResult _parseResponse(Map<String, dynamic> response, String imagePath) {
    final document = response['document'] ?? {};
    final text = document['text'] ?? '';
    final pages = document['pages'] as List? ?? [];

    List<ParsedLine> parsedLines = [];
    List<TableData> tables = [];
    Map<String, String> keyValuePairs = {};
    List<ParsedLine> tableLines = [];

    for (final page in pages) {
      // Form alanlarını işle
      final formFields = page['formFields'] as List? ?? [];
      for (final field in formFields) {
        String fieldName = _extractText(field['fieldName'], text).trim();
        String fieldValue = _extractText(field['fieldValue'], text).trim();

        fieldName = _cleanFieldName(fieldName);
        fieldValue = _cleanFieldValue(fieldValue);
        
        // İplik kodlarını ana tablodan filtrele (sadece İPLİKLER bölümünde görünsün)
        if (_isYarnCode(fieldName) || _isYarnCode(fieldValue)) {
          continue;
        }
        
        // Sipariş No bilgisini tablolardan da yakala
        if (fieldValue.toLowerCase().contains('sipariş no') || 
            fieldValue.toLowerCase().contains('siparis no') ||
            fieldValue.contains('2025.') || fieldValue.contains('2026.')) {
          // Sipariş numaralarını parse et
          final siparisPattern = RegExp(r'Sipariş No[:\s]*(\d+[.\d]+)', caseSensitive: false);
          final anaSiparisPattern = RegExp(r'Ana Sipariş No[:\s]*(\d+[.\d]+)', caseSensitive: false);
          
          final siparisMatch = siparisPattern.firstMatch(fieldValue);
          final anaSiparisMatch = anaSiparisPattern.firstMatch(fieldValue);
          
          if (siparisMatch != null) {
            keyValuePairs['Sipariş No'] = siparisMatch.group(1) ?? '';
          }
          if (anaSiparisMatch != null) {
            keyValuePairs['Ana Sipariş No'] = anaSiparisMatch.group(1) ?? '';
          }
          continue;
        }
        
        // İplik detaylarını kumaş cinsi alanından çıkar
        fieldValue = _removeYarnDetailsFromFabricType(fieldName, fieldValue);

        if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
          // Birleşik alanları ayır
          final splitResult = _splitCombinedFields(fieldName, fieldValue);
          for (final entry in splitResult.entries) {
            // Sadece daha önce eklenmemiş veya daha uzun değere sahipse ekle
            if (!keyValuePairs.containsKey(entry.key) || 
                entry.value.length > (keyValuePairs[entry.key]?.length ?? 0)) {
              keyValuePairs[entry.key] = entry.value;
            }
          }
        }
      }

      // Tabloları işle
      final pageTables = page['tables'] as List? ?? [];
      for (final table in pageTables) {
        final headerRows = table['headerRows'] as List? ?? [];
        final bodyRows = table['bodyRows'] as List? ?? [];

        List<String> headers = [];
        List<List<String>> rows = [];

        for (final headerRow in headerRows) {
          final cells = headerRow['cells'] as List? ?? [];
          headers = cells.map((cell) => _extractText(cell['layout'], text).trim()).toList();
        }

        for (final bodyRow in bodyRows) {
          final cells = bodyRow['cells'] as List? ?? [];
          List<String> row = cells.map((cell) => _extractText(cell['layout'], text).trim()).toList();
          if (row.any((cell) => cell.isNotEmpty)) {
            rows.add(row);
          }
        }

        if (headers.isNotEmpty || rows.isNotEmpty) {
          tables.add(TableData(headers: headers, rows: rows));
          if (headers.isNotEmpty) {
            tableLines.add(ParsedLine(key: headers.join(' | '), type: LineType.tableHeader));
          }
          for (final row in rows) {
            final rowText = row.join(' | ');
            final rowTextLower = rowText.toLowerCase();
            
            // Boş veya sadece | karakteri içeren satırları atla
            final cleanedRowText = rowText.replaceAll('|', '').replaceAll(' ', '').trim();
            if (cleanedRowText.isEmpty) continue;
            
            // Sipariş No içeren satırları İPLİKLER bölümüne ekleme
            if (rowTextLower.contains('sipariş no') || 
                rowTextLower.contains('siparis no') ||
                rowTextLower.contains('ana sipariş') ||
                rowTextLower.contains('ana siparis')) {
              // Bu satır sipariş bilgisi, parse edelim
              final siparisPattern = RegExp(r'Sipariş No[:\s]*(\d+[.\d]+)', caseSensitive: false);
              final anaSiparisPattern = RegExp(r'Ana Sipariş No[:\s]*(\d+[.\d]+)', caseSensitive: false);
              
              final siparisMatch = siparisPattern.firstMatch(rowText);
              final anaSiparisMatch = anaSiparisPattern.firstMatch(rowText);
              
              if (siparisMatch != null && !keyValuePairs.containsKey('Sipariş No')) {
                keyValuePairs['Sipariş No'] = siparisMatch.group(1) ?? '';
              }
              if (anaSiparisMatch != null && !keyValuePairs.containsKey('Ana Sipariş No')) {
                keyValuePairs['Ana Sipariş No'] = anaSiparisMatch.group(1) ?? '';
              }
              continue; // Bu satırı İPLİKLER'e ekleme
            }
            
            // Firma, Kumaş Cinsi gibi ana tablo bilgilerini atla
            if (rowTextLower.contains('firma') ||
                rowTextLower.contains('kumaş cinsi') ||
                rowTextLower.contains('kumas cinsi') ||
                rowTextLower.contains('kart miktarı') ||
                rowTextLower.contains('sipariş termini') ||
                rowTextLower.contains('makina no') ||
                rowTextLower.contains('üretime giriş') ||
                rowTextLower.contains('uretime giris') ||
                rowTextLower.contains('kg / top') ||
                rowTextLower.contains('kg/top') ||
                rowTextLower.contains('yağ ayarları') ||
                rowTextLower.contains('yag ayarlari') ||
                rowTextLower.contains('ham en') ||
                rowTextLower.contains('gramaj') ||
                rowTextLower.contains('açıklama') ||
                rowTextLower.contains('aciklama') ||
                rowTextLower.contains('proses') ||
                rowTextLower.contains('puss') ||
                rowTextLower.contains('fein') ||
                rowTextLower.contains('course') ||
                rowTextLower.contains('t/m') ||
                rowTextLower.contains('işil') ||
                rowTextLower.contains('isil') ||
                rowTextLower.contains('merkez')) {
              continue; // Bu satırı İPLİKLER'e ekleme, ana tabloya ait
            }
            
            // Sadece iplik bilgisi içeren satırları ekle
            // İplik satırları genellikle: IP ile başlayan kod, DN, FL, POLYESTER, PENYE, İPLİK içerir
            final isYarnLine = rowText.toUpperCase().contains('IP') ||
                              rowText.contains('DN') ||
                              rowText.contains('FL') ||
                              rowTextLower.contains('polyester') ||
                              rowTextLower.contains('penye') ||
                              rowTextLower.contains('pamuk') ||
                              rowTextLower.contains('iplik') ||
                              rowTextLower.contains('íplik') ||
                              rowTextLower.contains('teksture') ||
                              rowTextLower.contains('gipe') ||
                              rowTextLower.contains('likra');
            
            if (isYarnLine) {
              tableLines.add(ParsedLine(key: rowText, type: LineType.tableRow));
            }
          }
        }
      }

      // Satırları işle (form alanı olarak tanınmayanlar için)
      final lines = page['lines'] as List? ?? [];
      for (final line in lines) {
        final lineText = _extractText(line['layout'], text).trim();
        if (lineText.isNotEmpty && lineText.contains(':')) {
          final colonIndex = lineText.indexOf(':');
          final key = lineText.substring(0, colonIndex).trim();
          final value = lineText.substring(colonIndex + 1).trim();
          if (key.isNotEmpty && key.length < 40 && !keyValuePairs.containsKey(_cleanFieldName(key))) {
            keyValuePairs[_cleanFieldName(key)] = value;
          }
        }
      }
    }

    // Raw text'ten Sipariş No ve Ana Sipariş No'yu yakala
    final siparisTextPattern = RegExp(r'Sipariş No[:\s]*(\d+[.\d]+)', caseSensitive: false);
    final anaSiparisTextPattern = RegExp(r'Ana Sipariş No[:\s]*(\d+[.\d]+)', caseSensitive: false);
    
    final siparisTextMatch = siparisTextPattern.firstMatch(text);
    final anaSiparisTextMatch = anaSiparisTextPattern.firstMatch(text);
    
    if (siparisTextMatch != null && !keyValuePairs.containsKey('Sipariş No')) {
      keyValuePairs['Sipariş No'] = siparisTextMatch.group(1) ?? '';
    }
    if (anaSiparisTextMatch != null && !keyValuePairs.containsKey('Ana Sipariş No')) {
      keyValuePairs['Ana Sipariş No'] = anaSiparisTextMatch.group(1) ?? '';
    }

    // Başlıkları ekle
    if (text.toUpperCase().contains('ÖRGÜ İŞ EMRİ') || text.toUpperCase().contains('ORGU IS EMRI')) {
      parsedLines.add(ParsedLine(key: 'ÖRGÜ İŞ EMRİ', type: LineType.header));
    }
    if (text.contains('İhracat') || text.contains('Ihracat')) {
      parsedLines.add(ParsedLine(key: '* İhracat', type: LineType.section));
    }

    // Key-value çiftlerini sırala - iplik kodlarını filtrele
    for (final fieldName in _fieldOrder) {
      if (keyValuePairs.containsKey(fieldName)) {
        final value = keyValuePairs[fieldName] ?? '';
        // İplik kodlarını ana tablodan çıkar
        if (!_isYarnCode(fieldName) && !_isYarnCode(value)) {
          parsedLines.add(ParsedLine(key: fieldName, value: value, type: LineType.keyValue));
        }
        keyValuePairs.remove(fieldName);
      }
    }
    
    // Kalan alanları ekle - iplik kodlarını filtrele
    keyValuePairs.forEach((key, value) {
      if (!_isYarnCode(key) && !_isYarnCode(value)) {
        parsedLines.add(ParsedLine(key: key, value: value, type: LineType.keyValue));
      }
    });

    // İPLİKLER bölümü
    if (tableLines.isNotEmpty) {
      parsedLines.add(ParsedLine(key: 'İPLİKLER', type: LineType.section));
      parsedLines.addAll(tableLines);
    }

    // Eğer hiç veri yoksa raw text'i satır satır ekle
    if (parsedLines.isEmpty && text.isNotEmpty) {
      final textLines = text.split('\n');
      for (final line in textLines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          if (trimmed.contains(':')) {
            final colonIndex = trimmed.indexOf(':');
            final key = trimmed.substring(0, colonIndex).trim();
            final value = trimmed.substring(colonIndex + 1).trim();
            parsedLines.add(ParsedLine(key: key, value: value, type: LineType.keyValue));
          } else {
            parsedLines.add(ParsedLine(key: trimmed, type: LineType.normal));
          }
        }
      }
    }

    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rawText: text,
      parsedLines: parsedLines,
      tables: tables,
      createdAt: DateTime.now(),
      imagePath: imagePath,
    );
  }

  // İplik kodu pattern'i - bunları ana tablodan filtrele
  bool _isYarnCode(String text) {
    final cleanText = text.trim().toUpperCase();
    // IPSGPLK757, IPKPNCP301, IPSTK6836 gibi iplik kodları
    if (RegExp(r'^IP[A-Z0-9]+$').hasMatch(cleanText)) return true;
    // 75 DN 72 FL POLYESTER 40 DN gibi iplik açıklamaları
    if (RegExp(r'^\d+\s*DN\s*\d+\s*FL').hasMatch(cleanText)) return true;
    // Sadece iplik kodu ise
    if (RegExp(r'^[A-Z]{2,4}\d{3,}$').hasMatch(cleanText)) return true;
    return false;
  }

  String _cleanFieldName(String name) {
    name = name.replaceAll(':', '').trim();
    
    final corrections = {
      'kumaş parti no': 'Kumaş Parti No',
      'kumas parti no': 'Kumaş Parti No',
      'sipariş no': 'Sipariş No',
      'siparis no': 'Sipariş No',
      'ana sipariş no': 'Ana Sipariş No',
      'ana siparis no': 'Ana Sipariş No',
      'firma': 'Firma',
      'kumaş cinsi': 'Kumaş Cinsi',
      'kumas cinsi': 'Kumaş Cinsi',
      'kart miktarı': 'Kart Miktarı',
      'kart miktari': 'Kart Miktarı',
      'sipariş termini': 'Sipariş Termini',
      'siparis termini': 'Sipariş Termini',
      'makina no': 'Makina No',
      't/m': 'T/M',
      't / m': 'T/M',
      'ham en / gramaj': 'Ham En / Gramaj',
      'cl (course lenght)': 'CL (Course Lenght)',
      'puss / fein': 'Puss / Fein',
      'proses': 'Proses',
      'üretime giriliş tarihi': 'Üretime Giriliş Tarihi',
      'uretime girilis tarihi': 'Üretime Giriliş Tarihi',
      'kg / top': 'Kg / Top',
      'yağ ayarları': 'Yağ Ayarları',
      'yag ayarlari': 'Yağ Ayarları',
      'açıklama': 'Açıklama',
      'aciklama': 'Açıklama',
      'tarih': 'Tarih',
      'rp.no': 'Rp.No',
      'rp no': 'Rp.No',
    };
    
    final lowerName = name.toLowerCase();
    for (final entry in corrections.entries) {
      if (lowerName == entry.key || lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    return name;
  }

  String _cleanFieldValue(String value) {
    if (value.startsWith(':')) {
      value = value.substring(1).trim();
    }
    return value.trim();
  }

  String _removeYarnDetailsFromFabricType(String fieldName, String value) {
    // Eğer bu "Kumaş Cinsi" alanıysa temizle
    if (fieldName == 'Kumaş Cinsi' || fieldName.toLowerCase().contains('kumaş') || fieldName.toLowerCase().contains('kumas')) {
      // Önce "Firma : XXX" kısmını temizle
      // Pattern: "Firma : 1 IŞIL (MERKEZ) 30/1 PENYE..." -> "30/1 PENYE..."
      // Firma bilgisi genellikle sayı + firma adı + parantezli yer şeklinde
      var cleanedValue = value;
      
      // "Firma :" veya "Firma:" ile başlıyorsa, firma kısmını çıkar
      final firmaPattern = RegExp(
        r'Firma\s*:\s*\d*\s*[A-ZÇĞİÖŞÜa-zçğıöşü\s()]+?\s+(?=\d+/\d+|[A-Z]{2,}\s)',
        caseSensitive: false
      );
      cleanedValue = cleanedValue.replaceFirst(firmaPattern, '');
      
      // Eğer hala "Firma" ile başlıyorsa alternatif temizlik
      if (cleanedValue.toLowerCase().trim().startsWith('firma')) {
        // "Firma : 1 IŞIL (MERKEZ)" kısmını bul ve sil
        // Kumaş cinsi genellikle sayı/sayı ile başlar (30/1, 70/40) veya büyük harfle (PENYE)
        final fabricStartPattern = RegExp(r'\d+/\d+|PENYE|POLY|COTTON|OTTOMAN|RIBANA|INTERLOK|SÜPREM', caseSensitive: false);
        final fabricMatch = fabricStartPattern.firstMatch(cleanedValue);
        if (fabricMatch != null) {
          cleanedValue = cleanedValue.substring(fabricMatch.start);
        }
      }
      
      final lines = cleanedValue.split('\n');
      final cleanedLines = <String>[];
      
      for (final line in lines) {
        final lineTrimmed = line.trim();
        
        // Boş satırları atla
        if (lineTrimmed.isEmpty) continue;
        
        // İplik numarası pattern'leri: DN, FL, POLYESTER, D (denier)
        // Örnek: "75 DN 72 FL POLYESTER 40 DN", "IPSGPLK757"
        // Ama "70 DN POLY OTTOMAN" gibi kumaş cinslerini tutmalıyız
        final isYarnCode = RegExp(r'^\d+\s+DN\s+\d+\s+FL', caseSensitive: false).hasMatch(lineTrimmed) ||
                           RegExp(r'^[A-Z]+\d+$').hasMatch(lineTrimmed); // IPSGPLK757 gibi kodlar
        
        if (!isYarnCode) {
          cleanedLines.add(line);
        }
      }
      
      return cleanedLines.join('\n').trim();
    }
    
    // Eğer "Tarih" alanıysa, sadece geçerli tarihi al
    if (fieldName == 'Tarih' || fieldName.toLowerCase().contains('tarih')) {
      // Tarih formatı: DD.MM.YYYY
      final datePattern = RegExp(r'\b(\d{1,2}[./]\d{1,2}[./]\d{4})\b');
      final match = datePattern.firstMatch(value);
      if (match != null) {
        return match.group(1) ?? value;
      }
      // Alternatif olarak sadece ilk satırı al
      final lines = value.split('\n').where((e) => e.trim().isNotEmpty).toList();
      if (lines.isNotEmpty) {
        return lines[0].trim();
      }
    }
    
    // Eğer "Firma" alanıysa, sadece firma ismini al (ilk satır genellikle firma)
    if (fieldName == 'Firma' || fieldName.toLowerCase().contains('firma')) {
      final lines = value.split('\n').where((e) => e.trim().isNotEmpty).toList();
      if (lines.isNotEmpty) {
        // Sadece ilk satırı al, diğer detaylar muhtemelen kumaş/iplik bilgisi
        final firstLine = lines[0];
        // Fabric composition patterns (penye, poly, cotton, vs)
        final hasFabricDetails = firstLine.toLowerCase().contains('penye') ||
                                 firstLine.toLowerCase().contains('poly') ||
                                 firstLine.toLowerCase().contains('cotton') ||
                                 firstLine.toLowerCase().contains('ottoman') ||
                                 RegExp(r'\d+/\d+').hasMatch(firstLine); // 30/1, 70/40 gibi
        
        if (!hasFabricDetails) {
          return firstLine;
        } else {
          // İlk satırda kumaş detayı varsa, sadece firma ismini al
          // Örnek: "1 IŞIL (MERKEZ) 30/1 PENYE..." -> "1 IŞIL (MERKEZ)"
          final match = RegExp(r'^([^0-9]*\d+\s+[A-ZÇĞİÖŞÜ\s()]+?)(?=\s+\d+/\d+|\s+[A-Z]{2,}\s)').firstMatch(firstLine);
          if (match != null) {
            return match.group(1)?.trim() ?? firstLine;
          }
          // Eğer pattern match etmezse, ilk büyük harf kelimelerini al
          final words = firstLine.split(' ');
          final firmaPart = <String>[];
          for (final word in words) {
            if (RegExp(r'^[0-9A-ZÇĞİÖŞÜ()]+$').hasMatch(word)) {
              firmaPart.add(word);
            } else if (word.contains('/') || word.toLowerCase() == 'penye' || word.toLowerCase() == 'poly') {
              break;
            } else {
              firmaPart.add(word);
            }
          }
          return firmaPart.join(' ').trim();
        }
      }
    }
    
    // Eğer "Makina No" alanıysa, tüm değeri al (Int. Rib dahil)
    if (fieldName == 'Makina No' || fieldName.toLowerCase().contains('makina')) {
      // Değerin tamamını döndür, sadece satır sonu karakterlerini temizle
      return value.replaceAll('\n', ' ').trim();
    }
    
    // Eğer "Kg / Top" veya "Yağ Ayarları" alanıysa
    if (fieldName == 'Kg / Top' || fieldName.toLowerCase().contains('kg')) {
      return value.replaceAll('\n', ' ').trim();
    }
    
    if (fieldName == 'Yağ Ayarları' || fieldName.toLowerCase().contains('yağ') || fieldName.toLowerCase().contains('yag')) {
      return value.replaceAll('\n', ' ').trim();
    }
    
    return value;
  }

  Map<String, String> _splitCombinedFields(String fieldName, String fieldValue) {
    Map<String, String> result = {};
    
    // Özel durum: "Sipariş No" ve "Ana Sipariş No" aynı alanda
    // Örnek: fieldName = "Sipariş No Ana Sipariş No", fieldValue = "12345 67890"
    if (fieldName.toLowerCase().contains('sipariş no') || fieldName.toLowerCase().contains('siparis no')) {
      // Ana Sipariş No var mı kontrol et
      final hasAnaSiparis = fieldName.toLowerCase().contains('ana sipariş') || 
                            fieldName.toLowerCase().contains('ana siparis');
      
      if (hasAnaSiparis) {
        // Değerleri ayır
        final values = fieldValue.split(RegExp(r'\s+')).where((e) => e.trim().isNotEmpty).toList();
        if (values.length >= 2) {
          result['Sipariş No'] = values[0];
          result['Ana Sipariş No'] = values[1];
        } else if (values.length == 1) {
          result['Sipariş No'] = values[0];
        }
        return result;
      }
    }
    
    // Satır bazlı ayırma
    final nameLines = fieldName.split('\n').where((e) => e.trim().isNotEmpty).toList();
    final valueLines = fieldValue.split('\n').where((e) => e.trim().isNotEmpty).toList();
    
    if (nameLines.length > 1 && nameLines.length == valueLines.length) {
      // Her satır kendi değerine sahip
      for (int i = 0; i < nameLines.length; i++) {
        final cleanName = _cleanFieldName(nameLines[i].trim());
        final cleanValue = _cleanFieldValue(valueLines[i].trim());
        if (cleanName.isNotEmpty && cleanValue.isNotEmpty) {
          result[cleanName] = cleanValue;
        }
      }
    } else if (nameLines.length == 1 && valueLines.length == 1) {
      // Tek satır - normal ekleme
      result[fieldName] = fieldValue;
    } else {
      // Karmaşık durum - en uygun eşleştirmeyi yap
      // Eğer tek isim varsa, tüm değerleri birleştir
      if (nameLines.length == 1) {
        result[fieldName] = valueLines.join(' ').trim();
      } else {
        // Birden fazla isim var - her birine değer atamaya çalış
        for (int i = 0; i < nameLines.length; i++) {
          final cleanName = _cleanFieldName(nameLines[i].trim());
          if (cleanName.isNotEmpty) {
            if (i < valueLines.length) {
              result[cleanName] = _cleanFieldValue(valueLines[i].trim());
            } else {
              result[cleanName] = '';
            }
          }
        }
      }
    }
    
    return result;
  }

  String _extractText(Map<String, dynamic>? layout, String fullText) {
    if (layout == null) return '';

    final textAnchor = layout['textAnchor'] as Map<String, dynamic>?;
    if (textAnchor == null) return '';

    final textSegments = textAnchor['textSegments'] as List? ?? [];
    StringBuffer result = StringBuffer();

    for (final segment in textSegments) {
      final startIndex = int.tryParse(segment['startIndex']?.toString() ?? '0') ?? 0;
      final endIndex = int.tryParse(segment['endIndex']?.toString() ?? '0') ?? 0;

      if (endIndex > startIndex && endIndex <= fullText.length) {
        result.write(fullText.substring(startIndex, endIndex));
      }
    }

    return result.toString().trim();
  }

  void dispose() {
    _authClient?.close();
  }
}
