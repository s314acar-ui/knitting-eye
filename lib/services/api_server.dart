import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/scan_result.dart';
import '../models/work_order.dart';
import 'config_service.dart';

class ApiServer {
  HttpServer? _server;
  WorkOrder? _currentWorkOrder;
  ScanResult? _currentScanResult;
  String? _serverAddress;
  Uint8List? _lastImage; // Son taranan görsel
  Map<String, dynamic>? _configBasedJson; // Config tabanlı JSON
  String? _lastBarcode; // Son okunan barkod
  DateTime? _lastBarcodeTime; // Barkod okuma zamanı

  bool get isRunning => _server != null;
  String? get address => _serverAddress;
  WorkOrder? get currentWorkOrder => _currentWorkOrder;

  /// Sunucuyu başlat
  Future<String> start({int port = 8080}) async {
    if (_server != null) {
      return _serverAddress!;
    }

    // Cihazın IP adresini bul
    String ipAddress = await _getDeviceIp();

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _serverAddress = 'http://$ipAddress:$port';

    print('API Server başlatıldı: $_serverAddress');

    _server!.listen((HttpRequest request) async {
      // CORS headers
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers
          .add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      request.response.headers
          .add('Access-Control-Allow-Headers', 'Content-Type');
      request.response.headers.contentType = ContentType.json;

      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }

      try {
        switch (request.uri.path) {
          case '/':
          case '/api':
            await _handleApiInfo(request);
            break;
          case '/api/work-order':
          case '/api/workorder':
            await _handleWorkOrder(request);
            break;
          case '/api/raw':
            await _handleRawData(request);
            break;
          case '/api/status':
            await _handleStatus(request);
            break;
          case '/api/image':
            await _handleImage(request);
            break;
          case '/api/barcode':
            await _handleBarcode(request);
            break;
          default:
            request.response.statusCode = HttpStatus.notFound;
            request.response.write(jsonEncode({
              'error': 'Not Found',
              'message': 'Endpoint bulunamadı: ${request.uri.path}',
              'available_endpoints': [
                '/api - API bilgisi',
                '/api/work-order - İş emri JSON',
                '/api/raw - Ham OCR verisi',
                '/api/status - Sunucu durumu',
                '/api/image - Son taranan görsel',
                '/api/barcode - Son okunan barkod',
              ]
            }));
        }
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write(jsonEncode({
          'error': 'Internal Server Error',
          'message': e.toString(),
        }));
      }

      await request.response.close();
    });

    return _serverAddress!;
  }

  /// Sunucuyu durdur
  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _serverAddress = null;
    print('API Server durduruldu');
  }

  /// Mevcut iş emrini güncelle
  void updateWorkOrder(ScanResult scanResult) {
    _currentScanResult = scanResult;
    _currentWorkOrder = _convertToWorkOrder(scanResult);
    _updateConfigBasedJson(scanResult);
  }

  /// Mevcut iş emrini görsel ile güncelle
  void updateWorkOrderWithImage(ScanResult scanResult, String imagePath) {
    _currentScanResult = scanResult;
    _currentWorkOrder = _convertToWorkOrder(scanResult);
    _updateConfigBasedJson(scanResult);

    // Görseli oku ve kaydet
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        _lastImage = file.readAsBytesSync();
      }
    } catch (e) {
      print('Görsel okunamadı: $e');
    }
  }

  /// Config tabanlı JSON oluştur
  void _updateConfigBasedJson(ScanResult scanResult) {
    if (!configService.hasConfig) {
      _configBasedJson = null;
      return;
    }

    // OCR verilerini key-value map'e çevir
    final ocrData = <String, String>{};
    for (final line in scanResult.parsedLines) {
      if (line.type == LineType.keyValue && line.value != null) {
        ocrData[line.key] = line.value!;
      }
    }

    // Config servisini kullanarak JSON'a dönüştür
    _configBasedJson = configService.convertToJson(ocrData);

    // İplikleri ekle
    bool inYarnsSection = false;
    int yarnSeq = 1;
    for (final line in scanResult.parsedLines) {
      if (line.type == LineType.section && line.key == 'İPLİKLER') {
        inYarnsSection = true;
        continue;
      }
      if (inYarnsSection && line.type == LineType.tableRow) {
        final yarnMap = _parseYarnLine(line.key);
        if (yarnMap != null) {
          configService.addYarnToJson(
              _configBasedJson!,
              {
                'code': yarnMap['kod'] ?? '',
                'desc': yarnMap['tanim'] ?? '',
                'lot': yarnMap['lot'] ?? '',
                'qty_kg': yarnMap['miktar'] ?? '0',
                'waste_pct': '0',
                'ratio_pct': '0',
              },
              yarnSeq++);
        }
      }
    }
  }

  /// API bilgisi
  Future<void> _handleApiInfo(HttpRequest request) async {
    request.response.write(jsonEncode({
      'name': 'OCR Scanner API',
      'version': '1.0.0',
      'endpoints': {
        '/api/work-order': 'GET - Son taranan iş emrini JSON olarak döndürür',
        '/api/raw': 'GET - Ham OCR verisini döndürür',
        '/api/status': 'GET - Sunucu durumunu döndürür',
      },
      'has_data': _currentWorkOrder != null,
    }));
  }

  /// İş emri endpoint
  Future<void> _handleWorkOrder(HttpRequest request) async {
    if (_currentWorkOrder == null) {
      request.response.statusCode = HttpStatus.noContent;
      request.response.write(jsonEncode({
        'error': 'No Data',
        'message': 'Henüz tarama yapılmadı. Lütfen önce bir belge tarayın.',
      }));
      return;
    }

    // Config tabanlı JSON varsa onu döndür, yoksa varsayılan dönüşümü kullan
    if (_configBasedJson != null) {
      request.response.write(jsonEncode(_configBasedJson));
    } else {
      request.response.write(jsonEncode(_currentWorkOrder!.toJson()));
    }
  }

  /// Ham veri endpoint
  Future<void> _handleRawData(HttpRequest request) async {
    if (_currentScanResult == null) {
      request.response.statusCode = HttpStatus.noContent;
      request.response.write(jsonEncode({
        'error': 'No Data',
        'message': 'Henüz tarama yapılmadı.',
      }));
      return;
    }

    final data = {
      'id': _currentScanResult!.id,
      'raw_text': _currentScanResult!.rawText,
      'parsed_lines': _currentScanResult!.parsedLines
          .map((line) => {
                'key': line.key,
                'value': line.value,
                'type': line.type.toString(),
              })
          .toList(),
      'created_at': _currentScanResult!.createdAt.toIso8601String(),
    };

    request.response.write(jsonEncode(data));
  }

  /// Durum endpoint
  Future<void> _handleStatus(HttpRequest request) async {
    request.response.write(jsonEncode({
      'status': 'running',
      'address': _serverAddress,
      'has_data': _currentWorkOrder != null,
      'has_image': _lastImage != null,
      'last_scan': _currentScanResult?.createdAt.toIso8601String(),
    }));
  }

  /// Görsel endpoint
  Future<void> _handleImage(HttpRequest request) async {
    if (_lastImage == null) {
      request.response.statusCode = HttpStatus.noContent;
      request.response.write(jsonEncode({
        'error': 'No Image',
        'message': 'Henüz taranan görsel yok. Lütfen önce bir belge tarayın.',
      }));
      return;
    }

    // JPEG görsel olarak döndür
    request.response.headers.contentType = ContentType('image', 'jpeg');
    request.response.add(_lastImage!);
  }

  /// Barkod endpoint
  Future<void> _handleBarcode(HttpRequest request) async {
    if (_lastBarcode == null) {
      request.response.statusCode = HttpStatus.noContent;
      request.response.write(jsonEncode({
        'error': 'No Barcode',
        'message': 'Henüz okunan barkod yok.',
      }));
      return;
    }

    request.response.write(jsonEncode({
      'barcode': _lastBarcode,
      'timestamp': _lastBarcodeTime?.toIso8601String(),
    }));
  }

  /// Barkod verisini güncelle
  void updateBarcode(String barcode) {
    _lastBarcode = barcode;
    _lastBarcodeTime = DateTime.now();
  }

  /// Cihazın IP adresini bul
  Future<String> _getDeviceIp() async {
    String ipAddress = '127.0.0.1';

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (var interface in interfaces) {
        // WiFi veya ethernet arayüzünü bul
        if (interface.name.toLowerCase().contains('wlan') ||
            interface.name.toLowerCase().contains('wifi') ||
            interface.name.toLowerCase().contains('en') ||
            interface.name.toLowerCase().contains('eth')) {
          for (var addr in interface.addresses) {
            if (!addr.address.startsWith('127.')) {
              ipAddress = addr.address;
              break;
            }
          }
        }
      }

      // Eğer hala bulunamadıysa, herhangi bir non-localhost IP al
      if (ipAddress == '127.0.0.1') {
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (!addr.address.startsWith('127.')) {
              ipAddress = addr.address;
              break;
            }
          }
          if (ipAddress != '127.0.0.1') break;
        }
      }
    } catch (e) {
      print('IP adresi alınamadı: $e');
    }

    return ipAddress;
  }

  /// ScanResult'ı WorkOrder'a dönüştür
  WorkOrder _convertToWorkOrder(ScanResult scanResult) {
    final Map<String, String> fields = {};
    final List<Map<String, String>> yarnData = [];

    bool inYarnsSection = false;

    for (final line in scanResult.parsedLines) {
      if (line.type == LineType.section && line.key == 'İPLİKLER') {
        inYarnsSection = true;
        continue;
      }

      if (line.type == LineType.keyValue && line.value != null) {
        fields[line.key] = line.value!;
      }

      if (inYarnsSection && line.type == LineType.tableRow) {
        // İplik satırını parse et
        final yarn = _parseYarnLine(line.key);
        if (yarn != null) {
          yarnData.add(yarn);
        }
      }
    }

    // Puss / Fein parse et
    int puss = 0;
    int fein = 0;
    final pussFein = fields['Puss / Fein'] ?? '';
    final pussFeinMatch = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(pussFein);
    if (pussFeinMatch != null) {
      puss = int.tryParse(pussFeinMatch.group(1) ?? '') ?? 0;
      fein = int.tryParse(pussFeinMatch.group(2) ?? '') ?? 0;
    }

    // Kart miktarını parse et
    double totalKg = 0;
    final kartMiktari = fields['Kart Miktarı'] ?? '';
    final kgMatch = RegExp(r'([\d.,]+)').firstMatch(kartMiktari);
    if (kgMatch != null) {
      totalKg =
          double.tryParse(kgMatch.group(1)?.replaceAll(',', '.') ?? '') ?? 0;
    }

    // T/M parse et
    int turnsPerPiece = 0;
    final tm = fields['T/M'] ?? '';
    final tmMatch = RegExp(r'(\d+)').firstMatch(tm);
    if (tmMatch != null) {
      turnsPerPiece = int.tryParse(tmMatch.group(1) ?? '') ?? 0;
    }

    // Proses listesini parse et
    List<String> processList = [];
    final proses = fields['Proses'] ?? '';
    if (proses.isNotEmpty) {
      processList = proses
          .split('+')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // İplikleri oluştur
    final yarns = yarnData.asMap().entries.map((entry) {
      final idx = entry.key;
      final data = entry.value;

      double qtyKg = 0;
      final qtyMatch = RegExp(r'([\d.,]+)').firstMatch(data['miktar'] ?? '');
      if (qtyMatch != null) {
        qtyKg =
            double.tryParse(qtyMatch.group(1)?.replaceAll(',', '.') ?? '') ?? 0;
      }

      return Yarn(
        seq: idx + 1,
        code: data['kod'] ?? '',
        desc: data['tanim'] ?? '',
        lot: data['lot'] ?? '',
        qtyKg: qtyKg,
        wastePct: 0,
        ratioPct: 0,
      );
    }).toList();

    return WorkOrder(
      recipeId: fields['Rp.No'] ?? fields['Kumaş Parti No'] ?? '',
      date: fields['Tarih'] ?? '',
      factory: '',
      order: Order(
        no: fields['Sipariş No'] ?? '',
        main: fields['Ana Sipariş No'] ?? '',
        customer: fields['Firma'] ?? '',
        delivery: fields['Sipariş Termini'] ?? '',
      ),
      fabric: Fabric(
        name: fields['Kumaş Parti No'] ?? '',
        type: fields['Kumaş Cinsi'] ?? '',
        totalKg: totalKg,
        pieceCount: 0,
        pieceWeightKg: 0,
      ),
      machine: Machine(
        id: fields['Makina No'] ?? '',
        type: fields['T/M'] ?? '',
        gauge: Gauge(puss: puss, fein: fein),
        courseLength: fields['CL (Course Lenght)'] ?? '',
        turnsPerPiece: turnsPerPiece,
      ),
      yarns: yarns,
      process: processList,
      notes: fields['Açıklama'] ?? '',
    );
  }

  /// İplik satırını parse et
  Map<String, String>? _parseYarnLine(String line) {
    final parts = line
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;

    String kod = '';
    String tanim = '';
    String miktar = '';
    String lot = '';
    String depo = '';

    for (final part in parts) {
      final upperPart = part.toUpperCase();

      // Stok kodu (IP ile başlayan)
      if (upperPart.startsWith('IP') && kod.isEmpty) {
        kod = part;
        continue;
      }

      // Tanım (PENYE, POLYESTER, İPLİK içeren)
      if ((upperPart.contains('PENYE') ||
              upperPart.contains('POLYESTER') ||
              upperPart.contains('IPLIK') ||
              upperPart.contains('İPLİK') ||
              upperPart.contains('PAMUK') ||
              upperPart.contains('DN') ||
              upperPart.contains('FL')) &&
          tanim.isEmpty) {
        tanim = part;
        continue;
      }

      // Miktar (virgüllü sayı)
      if (part.contains(',') &&
          RegExp(r'^\d').hasMatch(part) &&
          miktar.isEmpty) {
        miktar = part;
        continue;
      }

      // Lot No
      if ((RegExp(r'^\d+[A-Z\-/]').hasMatch(upperPart) ||
              upperPart.contains('-S') ||
              upperPart.contains('C-')) &&
          lot.isEmpty) {
        lot = part;
        continue;
      }

      // Depo No
      if ((upperPart.startsWith('DS') || upperPart.startsWith('ES')) &&
          depo.isEmpty) {
        depo = part;
        continue;
      }
    }

    if (kod.isEmpty && tanim.isEmpty) return null;

    return {
      'kod': kod,
      'tanim': tanim,
      'miktar': miktar,
      'lot': lot,
      'depo': depo,
    };
  }
}

// Singleton instance
final apiServer = ApiServer();
