import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../services/update_service.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final UpdateService _updateService = UpdateService();
  
  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  UpdateInfo? _updateInfo;
  String? _errorMessage;
  File? _downloadedApk;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _updateInfo = null;
    });

    try {
      final updateInfo = await _updateService.checkForUpdates();
      
      setState(() {
        _updateInfo = updateInfo;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Güncelleme kontrolü başarısız: $e';
        _isChecking = false;
      });
    }
  }

  Future<void> _downloadAndInstall() async {
    if (_updateInfo?.downloadUrl.isEmpty ?? true) {
      setState(() {
        _errorMessage = 'APK indirme linki bulunamadı';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final apkFile = await _updateService.downloadApk(
        _updateInfo!.downloadUrl,
        (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      if (apkFile != null && await apkFile.exists()) {
        setState(() {
          _downloadedApk = apkFile;
          _isDownloading = false;
        });

        // APK'yı aç
        final result = await OpenFile.open(apkFile.path);
        
        if (result.type != ResultType.done) {
          setState(() {
            _errorMessage = 'APK açılamadı: ${result.message}';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'APK indirilemedi';
          _isDownloading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'İndirme hatası: $e';
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D3D3D),
        title: const Text('Güncelleme Kontrol'),
        actions: [
          if (!_isChecking && !_isDownloading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _checkForUpdates,
              tooltip: 'Yeniden Kontrol Et',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isChecking) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_updateInfo != null) {
      return _buildUpdateAvailable();
    }

    return _buildUpToDate();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Güncelleme kontrol ediliyor...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkForUpdates,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF424242),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpToDate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Güncel Sürüm',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'v${_updateService.currentVersion}',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 24),
            const Text(
              'Uygulamanız güncel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateAvailable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Güncelleme ikonu
          const Icon(
            Icons.system_update,
            color: Colors.blue,
            size: 64,
          ),
          const SizedBox(height: 16),
          
          // Başlık
          const Text(
            'Yeni Sürüm Mevcut!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Versiyon bilgisi
          Text(
            'v${_updateService.currentVersion} → v${_updateInfo!.version}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          
          // APK boyutu
          if (_updateInfo!.apkSize > 0)
            Text(
              'Boyut: ${_updateInfo!.formattedSize}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          const SizedBox(height: 24),
          
          // Güncelleme notları
          if (_updateInfo!.releaseNotes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3D3D3D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yenilikler:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _updateInfo!.releaseNotes,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // İndirme progress
          if (_isDownloading) ...[
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: const Color(0xFF3D3D3D),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_downloadProgress * 100).toStringAsFixed(0)}% İndiriliyor...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
          ],
          
          // Butonlar
          if (!_isDownloading) ...[
            ElevatedButton.icon(
              onPressed: _downloadAndInstall,
              icon: const Icon(Icons.download),
              label: const Text('İndir ve Yükle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Daha Sonra'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
          
          // İndirme tamamlandı mesajı
          if (_downloadedApk != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'APK indirildi. Kurulum ekranı açıldı.',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
