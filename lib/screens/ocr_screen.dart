import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/scan_result.dart';
import '../services/document_ai_service.dart';
import '../services/api_server.dart';

class OcrScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const OcrScreen({super.key, this.onComplete});
  
  @override
  State<OcrScreen> createState() => OcrScreenState();
}

class OcrScreenState extends State<OcrScreen> {
  final ImagePicker _picker = ImagePicker();
  final DocumentAIService _documentAI = DocumentAIService();
  bool _isProcessing = false;
  String _statusMessage = 'Fotoğraf çekmek için butona basın';
  ScanResult? _lastResult;
  bool _showResult = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
  }

  void openCamera() {
    if (!_isProcessing) {
      _takePhoto();
    }
  }

  Future<void> _takePhoto() async {
    if (_isProcessing) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
      );
      if (image != null) {
        await _processImage(File(image.path));
      } else {
        setState(() => _statusMessage = 'Fotoğraf çekilmedi');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Kamera hatası: $e');
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _showResult = false;
      _statusMessage = 'Belge analiz ediliyor...';
    });
    try {
      final result = await _documentAI.processImage(imageFile.path);
      setState(() {
        _lastResult = result;
        _isProcessing = false;
        _showResult = true;
        _statusMessage = 'Tarama tamamlandı!';
      });
      apiServer.updateWorkOrderWithImage(result, imageFile.path);
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) widget.onComplete?.call();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _showResult = false;
        _statusMessage = 'Belge işlenemedi.';
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(color: const Color(0xFF424242).withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(_isProcessing ? Icons.hourglass_top : Icons.document_scanner, size: 60, color: const Color(0xFF424242)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Belge Tarama', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF424242))),
                  const SizedBox(height: 8),
                  Text(_statusMessage, style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  if (_isProcessing)
                    const Column(children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Lütfen bekleyin...')])
                  else if (_hasError)
                    Column(children: [
                      const Icon(Icons.error_outline, color: Colors.grey, size: 64),
                      const SizedBox(height: 16),
                      Text(_statusMessage, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _hasError = false);
                          _takePhoto();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF424242), foregroundColor: Colors.white),
                      ),
                    ])
                  else if (_showResult)
                    const Column(children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 64),
                      SizedBox(height: 16),
                      Text('Tarama tamamlandı!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      SizedBox(height: 8),
                      Text('Anasayfaya yönlendiriliyorsunuz...'),
                    ])
                  else
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt, size: 28),
                      label: const Padding(padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24), child: Text('FOTOĞRAF ÇEK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF424242), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.history, color: Color(0xFF424242)), SizedBox(width: 8), Text('Son Tarama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF424242)))]),
                  const Divider(),
                  Expanded(
                    child: _lastResult == null
                        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.document_scanner_outlined, size: 64, color: Colors.grey), SizedBox(height: 16), Text('Henüz tarama yapılmadı', style: TextStyle(color: Colors.grey, fontSize: 16))]))
                        : ListView.builder(
                            itemCount: _lastResult!.parsedLines.length,
                            itemBuilder: (context, index) {
                              final line = _lastResult!.parsedLines[index];
                              if (line.type == LineType.header || line.type == LineType.section) {
                                return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(line.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));
                              }
                              if (line.type == LineType.keyValue) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 140, child: Text(line.key, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 12))),
                                      Expanded(child: Text(line.value ?? '', style: const TextStyle(fontSize: 12))),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
