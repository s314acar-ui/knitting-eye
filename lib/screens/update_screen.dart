import 'dart:io';
import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../services/kiosk_service.dart';
import '../services/auth_service.dart';

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
      debugPrint('🔄 Update screen: Starting update check...');
      
      // Hem en son sürümü hem de tüm sürümleri al
      final updateInfo = await _updateService.checkForUpdates();
      final allReleases = await _updateService.getAllReleases();
      
      debugPrint('✅ Update Check: Found ${allReleases.length} releases');
      if (allReleases.isEmpty) {
        debugPrint('⚠️ WARNING: No releases found! This might be a private repo issue.');
      }
      for (var release in allReleases) {
        debugPrint('  📦 v${release.version} - ${release.isCurrent ? "CURRENT" : release.isNewerThan(_updateService.currentVersion) ? "NEWER" : "OLDER"}');
      }
      
      if (mounted) {
        setState(() {
          _updateInfo = updateInfo;
          _allReleases = allReleases;
          _isChecking = false;
          
          // Eğer release bulunamadıysa hata mesajı göster
          if (allReleases.isEmpty) {
            _errorMessage = 'GitHub\'dan versiyon bilgisi alınamadı.\n\nOlası sebep: Repository private olabilir.\nÇözüm: Repository\'yi public yapın veya authentication ekleyin.';
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Update check error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Güncelleme kontrolü başarısız: $e';
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _downloadAndInstall(UpdateInfo release) async {
    if (release.downloadUrl.isEmpty) {
      setState(() {
        _errorMessage = 'APK indirme linki bulunamadı';
      });
      return;
    }

    // Downgrade uyarısı göster
    final isDowngrade = !release.isNewerThan(_updateService.currentVersion);
    if (isDowngrade && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text('Eski Versiyon', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'v${release.version} eski bir versiyondur.',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yükleme Başarısız Olabilir',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Android eski versiyonları yüklemeyi engelleyebilir.\n\n'
                      'Çözüm: Önce mevcut uygulamayı silin, ardından Downloads klasöründen APK\'yı manuel yükleyin.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Yine de İndir'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
      _downloadingVersion = release.version;
    });

    bool wasInKioskMode = false; // APK indirme öncesi kiosk durumu

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

        debugPrint('📦 APK downloaded: ${apkFile.path}');
        debugPrint('📦 File size: ${(await apkFile.length()) / 1024 / 1024} MB');
        
        // Yönetici kiosk modundaysa kurulum için geçici gevşet
        if (!authService.isDeveloper) {
          wasInKioskMode = true;
          await kioskService.setKioskMode(false);
          debugPrint('🔓 Kiosk mode geçici olarak devre dışı (kurulum için)');
        }
        
        // Native Android intent ile APK yükleme
        final result = await _updateService.installApk(apkFile);
        debugPrint('📦 Install result: $result');
        
        if (result == 'PERMISSION_REQUESTED') {
          // İzin sayfası açıldı, kullanıcıya bilgi ver
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('İzin verdikten sonra tekrar "İndir" butonuna basın.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else if (result == 'INSTALLING') {
          // Yükleme başladı
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'APK yükleme ekranı açıldı.\n'
                  'APK ayrıca Downloads klasörüne kaydedildi.',
                  style: TextStyle(fontSize: 13),
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else {
          // Hata - kiosk mode'u geri aç
          if (mounted) {
            setState(() {
              _errorMessage = 'APK yüklenemedi: $result';
            });
          }
          
          if (wasInKioskMode) {
            await Future.delayed(const Duration(milliseconds: 500));
            await kioskService.setKioskMode(true);
            debugPrint('🔒 Kiosk mode tekrar etkinleştirildi (kurulum hatası)');
          }
        }
      } else {
        debugPrint('❌ APK download returned null or file does not exist');
        setState(() {
          _errorMessage = 'İndirme başarısız oldu. Lütfen tekrar deneyin.';
          _isDownloading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'İndirme hatası: $e';
        _isDownloading = false;
      });
    }
    
    // Not: Başarılı yüklemede uygulama kapanacağı için kiosk mode'u tekrar açmaya gerek yok
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            const Text(
              'APK Yükleme İzni',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'APK dosyalarını indirip yüklemek için izin gereklidir.',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildPermissionItem(
              Icons.install_mobile,
              'Bilinmeyen Kaynaklardan Yükleme',
              'Uygulama güncellemelerini yüklemek için',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'İlk İndirmede İzin İstenecek',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'İndirmeye başladığınızda Android otomatik olarak izin dialogu gösterecektir. "İzin ver" veya "Allow" seçeneğine tıklayın.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Manuel Ayar (Opsiyonel)',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ayarlar > Güvenlik > Bilinmeyen uygulamaları yükle\n\n'
                    'Not: İlk indirme denemesinden sonra listede görünecektir.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.orange, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D3D3D),
        title: const Text('Güncelleme Kontrol'),
        actions: [
          // İzin bilgisi ikonu
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showPermissionDialog,
            tooltip: 'İzin Bilgisi',
          ),
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
          ..._allReleases.map((release) => _buildReleaseCard(release)),
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
                    icon: Icon(
                      isNewer ? Icons.download : Icons.arrow_downward,
                      size: 18,
                    ),
                    label: Text(isNewer ? 'İndir' : 'Downgrade'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isNewer ? Colors.blue : Colors.orange,
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
