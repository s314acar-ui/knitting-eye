// Satır tipleri
enum LineType {
  header,      // Belge başlığı (ÖRGÜ İŞ EMRİ vb.)
  section,     // Bölüm başlığı (İPLİKLER vb.)
  keyValue,    // Anahtar: Değer formatı
  tableHeader, // Tablo başlık satırı
  tableRow,    // Tablo veri satırı
  normal,      // Normal metin
}

// Ayrıştırılmış satır
class ParsedLine {
  final String key;
  final String? value;
  final LineType type;
  
  ParsedLine({
    required this.key,
    this.value,
    required this.type,
  });
  
  @override
  String toString() {
    if (value != null && value!.isNotEmpty) {
      return '$key: $value';
    }
    return key;
  }
}

// Tablo verisi
class TableData {
  final List<String> headers;
  final List<List<String>> rows;
  
  TableData({
    required this.headers,
    required this.rows,
  });
}

class DocumentField {
  final String label;
  final String value;
  
  DocumentField({required this.label, this.value = ''});
  
  bool get hasValue => value.isNotEmpty;
  
  @override
  String toString() => hasValue ? '$label: $value' : label;
}

class TableRow {
  final List<String> cells;
  
  TableRow(this.cells);
}

class DocumentTable {
  final List<String> headers;
  final List<TableRow> rows;
  
  DocumentTable({required this.headers, required this.rows});
}

class ParsedDocument {
  final String? title;
  final String? subtitle;
  final String? documentNumber;
  final String? date;
  final List<DocumentField> headerFields;
  final List<DocumentField> mainFields;
  final List<DocumentTable> tables;
  final List<String> footerLines;
  
  ParsedDocument({
    this.title,
    this.subtitle,
    this.documentNumber,
    this.date,
    this.headerFields = const [],
    this.mainFields = const [],
    this.tables = const [],
    this.footerLines = const [],
  });
}

class ScanResult {
  final String id;
  final String rawText;
  final List<ParsedLine> parsedLines;
  final List<TableData> tables;
  final DateTime createdAt;
  final String? imagePath;

  ScanResult({
    required this.id,
    required this.rawText,
    required this.parsedLines,
    this.tables = const [],
    required this.createdAt,
    this.imagePath,
  });

  String get text => rawText;
  
  List<String> get lines => rawText
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': rawText,
    'createdAt': createdAt.toIso8601String(),
    'imagePath': imagePath,
  };

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'],
      rawText: json['text'],
      parsedLines: [],
      tables: [],
      createdAt: DateTime.parse(json['createdAt']),
      imagePath: json['imagePath'],
    );
  }
}
