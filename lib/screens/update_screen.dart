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
  List<UpdateInfo> _allReleases = [];
  String? _errorMessage;
  File? _downloadedApk;
  String? _downloadingVersion;

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
      _allReleases = [];
    });

    try {
      // Hem en son sürümü hem de tüm sürümleri al
      final updateInfo = await _updateService.checkForUpdates();
      final allReleases = await _updateService.getAllReleases();
      
      setState(() {
        _updateInfo = updateInfo;
        _allReleases = allReleases;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Güncelleme kontrolü başarısız: $e';
        _isChecking = false;
      });
    }
  }

  Future<void> _downloadAndInstall(UpdateInfo release) async {
    if (release.downloadUrl.isEmpty) {
      setState(() {
        _errorMessage = 'APK indirme linki bulunamadı';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
      _downloadingVersion = release.version;
    });

    try {
      final apkFile = await _updateService.downloadApk(
        release.downloadUrl,
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

    if (_allReleases.isNotEmpty) {
      return _buildAllReleases();
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

  Widget _buildAllReleases() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık
          if (_updateInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: [
                  const Icon(Icons.system_update, color: Colors.blue, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yeni Sürüm Mevcut!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'v${_updateService.currentVersion} → v${_updateInfo!.version}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // İndirme progress
          if (_isDownloading) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3D3D3D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: const Color(0xFF2D2D2D),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'v$_downloadingVersion indiriliyor... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // İndirme tamamlandı mesajı
          if (_downloadedApk != null) ...[
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
            const SizedBox(height: 16),
          ],

          // Tüm versiyonlar başlığı
          Row(
            children: [
              const Icon(Icons.history, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Tüm Versiyonlar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_allReleases.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Versiyon listesi
          ..._allReleases.map((release) => _buildReleaseCard(release)).toList(),
        ],
      ),
    );
  }

  Widget _buildReleaseCard(UpdateInfo release) {
    final isNewer = release.isNewerThan(_updateService.currentVersion);
    final borderColor = release.isCurrent
        ? Colors.green
        : isNewer
            ? Colors.blue
            : Colors.white.withOpacity(0.2);
    final bgColor = release.isCurrent
        ? Colors.green.withOpacity(0.1)
        : isNewer
            ? Colors.blue.withOpacity(0.1)
            : const Color(0xFF3D3D3D);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Versiyon bilgisi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'v${release.version}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (release.isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'KURULU',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (isNewer)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'YENİ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (release.formattedDate.isNotEmpty) ...[
                            Icon(Icons.calendar_today,
                                size: 12, color: Colors.white.withOpacity(0.6)),
                            const SizedBox(width: 4),
                            Text(
                              release.formattedDate,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(Icons.file_download,
                              size: 12, color: Colors.white.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            release.formattedSize,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // İndir butonu
                if (!release.isCurrent && !_isDownloading)
                  ElevatedButton.icon(
                    onPressed: () => _downloadAndInstall(release),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('İndir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isNewer ? Colors.blue : Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Release notları (genişletilebilir)
          if (release.releaseNotes.isNotEmpty)
            ExpansionTile(
              title: const Text(
                'Yenilikler',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              iconColor: Colors.white70,
              collapsedIconColor: Colors.white70,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.black.withOpacity(0.2),
                  child: Text(
                    release.releaseNotes,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
