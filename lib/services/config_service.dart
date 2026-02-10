import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// OCR alanları ile JSON key eşleştirme için config servisi
/// Yeni yapı: jsonKey -> ocrField (aynı ocrField birden fazla jsonKey'e atanabilir)
class ConfigService {
  static const String _configFileName = 'eliar_field_config.json';

  // Yeni yapı: jsonKey -> ocrField
  Map<String, String> _fieldMappings = {};
  bool _isLearningMode = false;
  List<String> _learnedOcrFields = [];

  Map<String, String> get fieldMappings => _fieldMappings;
  bool get isLearningMode => _isLearningMode;
  List<String> get learnedOcrFields => _learnedOcrFields;
  bool get hasConfig => _fieldMappings.isNotEmpty;

  /// Gruplanmış JSON key'ler (görüntüdeki gibi)
  static const Map<String, List<Map<String, String>>> groupedJsonKeys = {
    'Sipariş Bilgileri': [
      {'key': 'order.no', 'label': 'İŞ EMRİ *', 'hint': 'İş emri numarası'},
      {
        'key': 'order.siparis_no',
        'label': 'SİPARİŞ NO',
        'hint': 'Sipariş numarası'
      },
      {'key': 'order.main', 'label': 'ANA SİPARİŞ', 'hint': 'Ana sipariş no'},
      {'key': 'order.customer', 'label': 'MÜŞTERİ', 'hint': 'Müşteri adı'},
      {
        'key': 'order.delivery',
        'label': 'TESLİMAT TARİHİ',
        'hint': 'Teslim tarihi'
      },
    ],
    'Kumaş Bilgileri': [
      {'key': 'fabric.name', 'label': 'KUMAŞ ADI', 'hint': 'Kumaş adı'},
      {
        'key': 'fabric.type',
        'label': 'KUMAŞ TİPİ *',
        'hint': 'Örn: Süprem, Penye'
      },
      {'key': 'fabric.total_kg', 'label': 'TOPLAM KG', 'hint': '0'},
      {'key': 'fabric.piece_count', 'label': 'TOP HEDEF *', 'hint': '100'},
      {
        'key': 'fabric.piece_weight_kg',
        'label': 'TOP AĞIRLIĞI (KG)',
        'hint': '0'
      },
    ],
    'Makine Bilgileri': [
      {'key': 'machine.id', 'label': 'MAKİNE ID', 'hint': 'Makine ID'},
      {'key': 'machine.type', 'label': 'MAKİNE TİPİ', 'hint': 'Makine tipi'},
      {'key': 'machine.gauge.puss', 'label': 'GAUGE - PUSS', 'hint': '0'},
      {'key': 'machine.gauge.fein', 'label': 'GAUGE - FEİN', 'hint': '0'},
      {
        'key': 'machine.course_length',
        'label': 'COURSE LENGTH',
        'hint': 'Course length'
      },
      {'key': 'machine.turns_per_piece', 'label': 'TUR HEDEF *', 'hint': '650'},
    ],
    'İplik Bilgileri': [
      {
        'key': 'yarn.type',
        'label': 'İPLİK TİPİ *',
        'hint': 'Örn: Pamuk, Pamuk 30/1'
      },
    ],
    'Diğer': [
      {'key': 'recipe_id', 'label': 'BARKOD', 'hint': 'Örn: RCP-2024-001'},
      {'key': 'date', 'label': 'TARİH', 'hint': 'Tarih'},
      {'key': 'factory', 'label': 'FABRİKA', 'hint': 'Fabrika adı'},
      {'key': 'process', 'label': 'PROSES', 'hint': 'Proses listesi'},
      {'key': 'notes', 'label': 'NOTLAR', 'hint': 'Açıklama/Notlar'},
    ],
  };

  /// JSON formatındaki tüm key'ler
  static const List<String> jsonKeys = [
    'recipe_id',
    'date',
    'factory',
    'order.no',
    'order.main',
    'order.customer',
    'order.delivery',
    'fabric.name',
    'fabric.type',
    'fabric.total_kg',
    'fabric.piece_count',
    'fabric.piece_weight_kg',
    'machine.id',
    'machine.type',
    'machine.gauge.puss',
    'machine.gauge.fein',
    'machine.course_length',
    'machine.turns_per_piece',
    'yarn.type',
    'process',
    'notes',
  ];

  /// JSON key açıklamaları (Türkçe)
  static const Map<String, String> jsonKeyDescriptions = {
    'recipe_id': 'Barkod/Reçete No',
    'date': 'Tarih',
    'factory': 'Fabrika',
    'order.no': 'İş Emri No',
    'order.main': 'Ana Sipariş No',
    'order.customer': 'Müşteri/Firma',
    'order.delivery': 'Teslim Tarihi',
    'fabric.name': 'Kumaş Adı',
    'fabric.type': 'Kumaş Tipi',
    'fabric.total_kg': 'Toplam Kg',
    'fabric.piece_count': 'Top Hedef',
    'fabric.piece_weight_kg': 'Top Ağırlığı (Kg)',
    'machine.id': 'Makine ID',
    'machine.type': 'Makine Tipi',
    'machine.gauge.puss': 'Gauge - Puss',
    'machine.gauge.fein': 'Gauge - Fein',
    'machine.course_length': 'Course Length',
    'machine.turns_per_piece': 'Tur Hedef',
    'yarn.type': 'İplik Tipi',
    'process': 'Proses',
    'notes': 'Açıklama/Notlar',
  };

  /// Config dosyasının yolunu al
  Future<String> get _configFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_configFileName';
  }

  /// Config'i yükle
  Future<void> loadConfig() async {
    try {
      final filePath = await _configFilePath;
      final file = File(filePath);

      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;

        _fieldMappings = Map<String, String>.from(json['fieldMappings'] ?? {});
      }
    } catch (e) {
      print('Config yüklenirken hata: $e');
      _fieldMappings = {};
    }
  }

  /// Config'i kaydet
  Future<void> saveConfig() async {
    try {
      final filePath = await _configFilePath;
      final file = File(filePath);

      final json = {
        'fieldMappings': _fieldMappings,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      print('Config kaydedilirken hata: $e');
    }
  }

  /// Öğrenme modunu aç/kapat
  void setLearningMode(bool enabled) {
    _isLearningMode = enabled;
    if (enabled) {
      _learnedOcrFields = [];
    }
  }

  /// OCR'dan okunan alanları öğren
  void learnOcrFields(List<String> ocrFields) {
    _learnedOcrFields = ocrFields.toSet().toList();
    _learnedOcrFields.sort();
  }

  /// Alan eşleştirmesi ekle/güncelle (jsonKey -> ocrField)
  void setFieldMapping(String jsonKey, String ocrField) {
    _fieldMappings[jsonKey] = ocrField;
  }

  /// Alan eşleştirmesini kaldır (jsonKey bazlı)
  void removeFieldMapping(String jsonKey) {
    _fieldMappings.remove(jsonKey);
  }

  /// Tüm eşleştirmeleri temizle
  Future<void> clearAllMappings() async {
    _fieldMappings = {};
    await saveConfig();
  }

  /// OCR sonuçlarını JSON formatına dönüştür
  Map<String, dynamic> convertToJson(Map<String, String> ocrData) {
    final result = _createEmptyWorkOrderJson();

    // fieldMappings artık jsonKey -> ocrField formatında
    for (final entry in _fieldMappings.entries) {
      final jsonKey = entry.key;
      final ocrField = entry.value;

      // OCR verisinde bu alan var mı?
      if (ocrData.containsKey(ocrField)) {
        final value = ocrData[ocrField]!;
        _setNestedValue(result, jsonKey, value);
      }
    }

    return result;
  }

  /// Boş work order JSON oluştur
  Map<String, dynamic> _createEmptyWorkOrderJson() {
    return {
      'recipe_id': '',
      'date': '',
      'factory': '',
      'order': {
        'no': '',
        'main': '',
        'customer': '',
        'delivery': '',
      },
      'fabric': {
        'name': '',
        'type': '',
        'total_kg': 0,
        'piece_count': 0,
        'piece_weight_kg': 0,
      },
      'machine': {
        'id': '',
        'type': '',
        'gauge': {
          'puss': 0,
          'fein': 0,
        },
        'course_length': '',
        'turns_per_piece': 0,
      },
      'yarns': <Map<String, dynamic>>[],
      'process': <String>[],
      'notes': '',
    };
  }

  /// İç içe JSON değerini ayarla
  void _setNestedValue(Map<String, dynamic> map, String key, String value) {
    final parts = key.split('.');

    if (parts.length == 1) {
      // process için özel işlem
      if (key == 'process') {
        map[key] = value.split('+').map((e) => e.trim()).toList();
      } else {
        map[key] = _parseValue(key, value);
      }
      return;
    }

    // İç içe obje
    var current = map;
    for (int i = 0; i < parts.length - 1; i++) {
      if (current[parts[i]] == null) {
        current[parts[i]] = <String, dynamic>{};
      }
      current = current[parts[i]] as Map<String, dynamic>;
    }

    final lastKey = parts.last;
    current[lastKey] = _parseValue(lastKey, value);
  }

  /// Değeri uygun tipe çevir
  dynamic _parseValue(String key, String value) {
    // Sayısal alanlar
    if (key.contains('kg') || key.contains('weight') || key.contains('pct')) {
      return double.tryParse(
              value.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '')) ??
          0.0;
    }
    if (key.contains('count') ||
        key.contains('piece') ||
        key == 'puss' ||
        key == 'fein' ||
        key == 'seq' ||
        key.contains('turns')) {
      return int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    }
    return value;
  }

  /// İplik verilerini JSON'a ekle
  void addYarnToJson(
      Map<String, dynamic> json, Map<String, String> yarnData, int seq) {
    final yarn = {
      'seq': seq,
      'code': yarnData['code'] ?? '',
      'desc': yarnData['desc'] ?? '',
      'lot': yarnData['lot'] ?? '',
      'qty_kg':
          double.tryParse(yarnData['qty_kg']?.replaceAll(',', '.') ?? '0') ?? 0,
      'waste_pct':
          double.tryParse(yarnData['waste_pct']?.replaceAll(',', '.') ?? '0') ??
              0,
      'ratio_pct':
          double.tryParse(yarnData['ratio_pct']?.replaceAll(',', '.') ?? '0') ??
              0,
    };

    (json['yarns'] as List).add(yarn);
  }
}

/// Global config service instance
final configService = ConfigService();
