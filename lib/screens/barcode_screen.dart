import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import '../services/settings_service.dart';
import '../services/api_server.dart';

class BarcodeScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const BarcodeScreen({super.key, this.onComplete});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  BarcodeScanner? _barcodeScanner;
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _hasError = false;
  String? _lastBarcode;
  final List<String> _recentBarcodes = [];
  String _statusMessage = 'Kamera başlatılıyor...';
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _barcodeScanner?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _reinitCamera();
    }
  }

  Future<void> _reinitCamera() async {
    if (!mounted) return;
    _stopCamera();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      await _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (!mounted) return;

    try {
      setState(() {
        _hasError = false;
        _statusMessage = 'Kamera başlatılıyor...';
      });

      // Kamera izni kontrolü
      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          if (mounted) {
            setState(() {
              _statusMessage = 'Kamera izni gerekli';
              _hasError = true;
            });
          }
          return;
        }
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Kamera bulunamadı';
            _hasError = true;
          });
        }
        return;
      }

      final camera = cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      if (mounted &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        setState(() {
          _isCameraInitialized = true;
          _hasError = false;
          _statusMessage = 'Barkod tarayın';
        });
        _startImageStream();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Kamera hatası';
          _hasError = true;
          _isCameraInitialized = false;
        });
      }
    }
  }

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    try {
      _cameraController!.startImageStream((image) {
        if (!_isProcessing && _isScanning && mounted) {
          _processImage(image);
        }
      });
    } catch (e) {
      // Stream başlatılamadı
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing || !_isScanning) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final barcodes = await _barcodeScanner!.processImage(inputImage);

      if (barcodes.isNotEmpty && mounted) {
        final barcode = barcodes.first;
        final value = barcode.rawValue ?? '';

        if (value.isNotEmpty && value != _lastBarcode) {
          setState(() {
            _lastBarcode = value;
            _recentBarcodes.insert(0, value);
            if (_recentBarcodes.length > 10) {
              _recentBarcodes.removeLast();
            }
            _statusMessage = 'Barkod okundu!';
          });

          // API'ye gönder
          await _sendToApi(value);
        }
      }
    } catch (e) {
      // Sessiz hata
    }

    _isProcessing = false;
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      final rotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation);

      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _sendToApi(String barcode) async {
    // Önce local API server'a kaydet
    apiServer.updateBarcode(barcode);

    final apiUrl = settingsService.barcodeApiUrl;
    if (apiUrl.isEmpty) return;

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'barcode': barcode,
              'timestamp': DateTime.now().toIso8601String(),
              'device_ip': settingsService.deviceIp,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _statusMessage = 'API\'ye gönderildi ✓';
          });
        }
      }
    } catch (e) {
      // API hatası sessiz geçilir
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _cameraController?.stopImageStream();
    } catch (e) {
      // Ignore
    }
    try {
      await _cameraController?.dispose();
    } catch (e) {
      // Ignore
    }
    _cameraController = null;
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
      _statusMessage = _isScanning ? 'Barkod tarayın' : 'Tarama durduruldu';
    });
  }

  void _clearHistory() {
    setState(() {
      _recentBarcodes.clear();
      _lastBarcode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sol taraf - Kamera
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Kamera önizleme veya hata ekranı
                  if (_hasError)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videocam_off,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _reinitCamera,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tekrar Dene'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_isCameraInitialized && _cameraController != null)
                    Center(
                      child: CameraPreview(_cameraController!),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),

                  // Tarama çerçevesi
                  Center(
                    child: Container(
                      width: 280,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isScanning ? Colors.green : Colors.orange,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Köşe işaretleri
                          ...List.generate(4, (index) {
                            return Positioned(
                              top: index < 2 ? 0 : null,
                              bottom: index >= 2 ? 0 : null,
                              left: index % 2 == 0 ? 0 : null,
                              right: index % 2 == 1 ? 0 : null,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: index < 2
                                        ? BorderSide(
                                            color: _isScanning
                                                ? Colors.green
                                                : Colors.orange,
                                            width: 4)
                                        : BorderSide.none,
                                    bottom: index >= 2
                                        ? BorderSide(
                                            color: _isScanning
                                                ? Colors.green
                                                : Colors.orange,
                                            width: 4)
                                        : BorderSide.none,
                                    left: index % 2 == 0
                                        ? BorderSide(
                                            color: _isScanning
                                                ? Colors.green
                                                : Colors.orange,
                                            width: 4)
                                        : BorderSide.none,
                                    right: index % 2 == 1
                                        ? BorderSide(
                                            color: _isScanning
                                                ? Colors.green
                                                : Colors.orange,
                                            width: 4)
                                        : BorderSide.none,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Durum mesajı
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Tarama toggle butonu
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      onPressed: _toggleScanning,
                      icon: Icon(
                        _isScanning ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Sağ taraf - Son okunanlar
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Başlık
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF424242),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Son Okunanlar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _clearHistory,
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Geçmişi Temizle',
                      ),
                    ],
                  ),
                ),

                // Son barkod (büyük)
                if (_lastBarcode != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.green[50],
                    child: Column(
                      children: [
                        const Text(
                          'Son Okunan',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastBarcode!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                // Liste
                Expanded(
                  child: _recentBarcodes.isEmpty
                      ? const Center(
                          child: Text(
                            'Henüz barkod okunmadı',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _recentBarcodes.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? Colors.green[100]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${index + 1}.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _recentBarcodes[index],
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
