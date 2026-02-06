import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/document_ai_service.dart';
import '../services/api_server.dart';

/// Basit OCR ekranı - Sadece operatör için
/// Sadece kamera + işlem göstergesi
class SimpleOcrScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const SimpleOcrScreen({super.key, this.onComplete});

  @override
  State<SimpleOcrScreen> createState() => SimpleOcrScreenState();
}

class SimpleOcrScreenState extends State<SimpleOcrScreen> {
  CameraController? _cameraController;
  final DocumentAIService _documentAI = DocumentAIService();
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _showCamera = false;
  String _statusMessage = 'Kamera başlatılıyor...';
  bool _showResult = false;
  bool _isInitializing = false; // Kamera başlatma işlemi devam ediyor mu?
  
  // Kamera özellikleri
  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Kamera kontrolcüsünü güvenli şekilde temizle
    final controller = _cameraController;
    _cameraController = null;
    controller?.dispose();
    super.dispose();
  }

  // Navigation butonuyla çağrılır - kamerayı aç
  Future<void> openCamera() async {
    // Eğer kamera başlatma işlemi zaten devam ediyorsa veya işlem yapılıyorsa çık
    if (_isInitializing || _isProcessing || _showCamera) {
      return;
    }
    await _initCamera();
  }

  Future<void> _initCamera() async {
    // Çift tıklama kontrolü
    if (_isInitializing) return;
    
    setState(() {
      _isInitializing = true;
    });
    
    try {
      setState(() {
        _statusMessage = 'Kamera başlatılıyor...';
        _showCamera = true;
      });

      _availableCameras = await availableCameras();
      
      // Ön kamerayı varsayılan olarak seç
      _currentCameraIndex = _availableCameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
      );
      // Ön kamera yoksa arka kamerayı seç
      if (_currentCameraIndex == -1) {
        _currentCameraIndex = _availableCameras.indexWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
        );
      }
      if (_currentCameraIndex == -1) _currentCameraIndex = 0;

      await _startCamera(_availableCameras[_currentCameraIndex]);
    } catch (e) {
      setState(() {
        _statusMessage = 'Kamera hatası: $e';
        _showCamera = false;
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    // Önce mevcut kamerayı kapat
    await _cameraController?.dispose();
    _cameraController = null;

    setState(() {
      _isCameraInitialized = false;
      _statusMessage = 'Kamera başlatılıyor...';
    });

    try {
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Zoom limitleri al
      _minZoom = await _cameraController!.getMinZoomLevel();
      _maxZoom = await _cameraController!.getMaxZoomLevel();
      _currentZoom = 1.0;

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _statusMessage = 'Kamera hazır';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Kamera başlatılamadı';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2 || _isProcessing) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _availableCameras.length;
    await _startCamera(_availableCameras[_currentCameraIndex]);
  }

  Future<void> _setZoom(double zoom) async {
    if (_cameraController == null || !_isCameraInitialized) return;

    // Zoom değerini limitlere göre ayarla
    final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
    await _cameraController!.setZoomLevel(clampedZoom);
    setState(() {
      _currentZoom = clampedZoom;
    });
  }

  Future<void> _setFocusPoint(Offset point) async {
    if (_cameraController == null || !_isCameraInitialized) return;

    try {
      await _cameraController!.setFocusPoint(point);
      await _cameraController!.setExposurePoint(point);
    } catch (e) {
      // Bazı cihazlar odak ayarını desteklemeyebilir
    }
  }

  Future<void> _takePhoto() async {
    if (_isProcessing || _cameraController == null || !_isCameraInitialized) return;

    try {
      setState(() {
        _isProcessing = true;
        _statusMessage = 'Fotoğraf çekiliyor...';
      });

      final image = await _cameraController!.takePicture();
      
      // Kamerayı kapat
      await _closeCamera();
      
      // Fotoğrafı işle
      await _processImage(File(image.path));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Kamera hatası';
        });
      }
    }
  }

  Future<void> _closeCamera() async {
    // Kamera kontrolcüsünü güvenli şekilde kapat
    final controller = _cameraController;
    _cameraController = null;
    
    if (mounted) {
      setState(() {
        _showCamera = false;
        _isCameraInitialized = false;
        _isInitializing = false;
      });
    }
    
    // Dispose işlemini en son yap
    await controller?.dispose();
  }

  // Kamerayı kapat ve anasayfaya dön (operatör için)
  Future<void> _closeCameraAndGoHome() async {
    await _closeCamera();
    if (mounted) {
      widget.onComplete?.call();
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _showResult = false;
      _statusMessage = 'Belge okunuyor...';
    });

    try {
      final result = await _documentAI.processImage(imageFile.path);

      setState(() {
        _isProcessing = false;
        _showResult = true;
        _statusMessage = 'Belge okundu!';
      });

      // API sunucusuna görsel ile birlikte gönder
      apiServer.updateWorkOrderWithImage(result, imageFile.path);

      // 2 saniye bekle ve anasayfaya dön
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        widget.onComplete?.call();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _showResult = false;
        _statusMessage = 'Belge okunamadı';
      });
      
      // Hata durumunda 2 saniye bekle ve anasayfaya dön
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        widget.onComplete?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer kamera açıksa, kamera önizleme göster
    if (_showCamera) {
      return _buildCameraView();
    }

    // İşlem ekranı
    return Container(
      color: const Color(0xFF424242),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İkon veya spinner
              if (_isProcessing)
                const Column(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                )
              else if (_showResult)
                const Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                    SizedBox(height: 32),
                  ],
                )
              else
                const Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.orange,
                      size: 80,
                    ),
                    SizedBox(height: 32),
                  ],
                ),

              // Durum mesajı
              Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (_isProcessing) ...[
                const SizedBox(height: 16),
                const Text(
                  'Lütfen bekleyin...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Container(
      color: Colors.black,
      child: _isCameraInitialized && 
             _cameraController != null && 
             _cameraController!.value.isInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Tam ekran kamera önizlemesi - odak için GestureDetector
                GestureDetector(
                  onTapUp: (details) {
                    final renderBox = context.findRenderObject() as RenderBox;
                    final position = details.localPosition;
                    final offset = Offset(
                      position.dx / renderBox.size.width,
                      position.dy / renderBox.size.height,
                    );
                    _setFocusPoint(offset);
                  },
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
                
                // Kapat butonu - sol üst (operatör için anasayfaya döner)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _closeCameraAndGoHome,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),

                // Kamera değiştirme butonu - sağ üst
                if (_availableCameras.length > 1)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: _switchCamera,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(
                            Icons.flip_camera_android,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Zoom kontrolleri - sağ orta
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // x2 zoom
                          _buildZoomButton('2×', 2.0),
                          const SizedBox(height: 4),
                          // x1 zoom (normal)
                          _buildZoomButton('1×', 1.0),
                          const SizedBox(height: 4),
                          // x0.5 zoom (geniş açı)
                          if (_minZoom < 1.0)
                            _buildZoomButton('0.5×', 0.5),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fotoğraf çek butonu - orta alt
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 8,
                      child: InkWell(
                        onTap: _isProcessing ? null : _takePhoto,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 5,
                            ),
                          ),
                          child: _isProcessing
                              ? const Padding(
                                  padding: EdgeInsets.all(22.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Color(0xFF424242),
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 45,
                                  color: Color(0xFF424242),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Durum mesajı - üst orta
                if (_isProcessing)
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 24),
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildZoomButton(String label, double zoom) {
    final isSelected = (_currentZoom - zoom).abs() < 0.1;
    
    return Material(
      color: isSelected 
          ? Colors.white.withValues(alpha: 0.9)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _setZoom(zoom),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
