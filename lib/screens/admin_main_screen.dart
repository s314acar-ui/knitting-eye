import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../services/kiosk_service.dart';
import 'home_tab.dart';
import 'barcode_screen.dart';
import 'ocr_screen.dart';
import 'settings_screen.dart';
import 'config_screen.dart';
import 'login_screen.dart';
import 'kiosk_admin_screen.dart';
import 'update_screen.dart';

/// Admin (Firma Yetkilisi) için ana ekran
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  late Timer _clockTimer;
  String _currentTime = '';
  String _appVersion = '';

  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();
  final GlobalKey<OcrScreenState> _ocrScreenKey = GlobalKey<OcrScreenState>();

  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _updateTime();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    // Ayarlar sadece developer için
    _screens = [
      HomeTab(key: _homeTabKey, onNavigateToOcr: () => _navigateToOcr()),
      BarcodeScreen(onComplete: () => _navigateTo(0)),
      OcrScreen(key: _ocrScreenKey, onComplete: () => _navigateTo(0)),
      const ConfigScreen(),
      if (authService.isDeveloper) SettingsScreen(onUrlSaved: _onUrlSaved),
    ];

    // Developer girişinde kiosk modunu kapat ve uygulama yükleme iznini kontrol et
    if (authService.isDeveloper) {
      _disableKioskMode();
      _checkInstallPermission();
    } else {
      // Yönetici (admin) girişinde kiosk mode'u etkinleştir
      _enableKioskMode();
    }
  }

  /// Kiosk modunu otomatik olarak etkinleştir (sadece yönetici için)
  Future<void> _enableKioskMode() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final success = await kioskService.setKioskMode(true);
      if (success) {
        debugPrint('✅ Admin kiosk mode etkinleştirildi');
      } else {
        debugPrint('⚠️ Admin kiosk mode etkinleştirilemedi');
      }
    } catch (e) {
      debugPrint('❌ Admin kiosk mode hatası: $e');
    }
  }

  /// Kiosk modunu devre dışı bırak (sadece developer için)
  Future<void> _disableKioskMode() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final success = await kioskService.setKioskMode(false);
      if (success) {
        debugPrint('✅ Developer kiosk mode devre dışı bırakıldı');
      } else {
        debugPrint('⚠️ Developer kiosk mode kapatılamadı');
      }
    } catch (e) {
      debugPrint('❌ Developer kiosk mode hatası: $e');
    }
  }

  /// Developer ilk girişinde uygulama yükleme izni iste
  Future<void> _checkInstallPermission() async {
    try {
      final updateService = UpdateService();
      final canInstall = await updateService.canInstallPackages();
      if (!canInstall && mounted) {
        // İzin yoksa dialog göster
        _showInstallPermissionDialog();
      }
    } catch (e) {
      debugPrint('⚠️ Install permission check error: $e');
    }
  }

  void _showInstallPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.orange),
            SizedBox(width: 8),
            Text('Uygulama Yükleme İzni'),
          ],
        ),
        content: const Text(
          'Güncelleme sisteminin çalışması için "Bilinmeyen kaynaklardan uygulama yükleme" izninin verilmesi gerekiyor.\n\n'
          'Açılacak ayarlar ekranında bu izni etkinleştirin ve geri dönün.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sonra'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final updateService = UpdateService();
              await updateService.requestInstallPermission();
            },
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('İzin Ver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${packageInfo.version}';
    });
  }

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToOcr() {
    setState(() {
      _currentIndex = 2;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ocrScreenKey.currentState?.openCamera();
    });
  }

  void _onUrlSaved() {
    _homeTabKey.currentState?.refreshPage();
    _navigateTo(0);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış'),
        content: const Text('Oturumu kapatmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF424242),
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Developer çıkış yaparken kiosk modunu tekrar aç
      if (authService.isDeveloper) {
        try {
          await kioskService.setKioskMode(true);
          debugPrint('✅ Developer çıkışında kiosk mode tekrar etkinleştirildi');
        } catch (e) {
          debugPrint('❌ Developer çıkış kiosk mode hatası: $e');
        }
      }
      
      await authService.logout();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _openKioskAdmin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KioskAdminScreen()),
    );
  }

  void _openUpdateScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UpdateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildNavBar(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sol - Logo + Admin badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Yatay Logo
                Image.asset(
                  'assets/images/logo_horizontal.png',
                  height: 36,
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: authService.isDeveloper ? Colors.purple : Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    authService.isDeveloper ? 'DEVELOPER' : 'YÖNETİCİ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Versiyon bilgisi - sadece developer için
                if (authService.isDeveloper) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _appVersion.isEmpty ? 'v-.-.-' : _appVersion,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Orta - Saat
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _currentTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),

          // Sağ - Navigasyon Butonları
          _buildNavButton(
              index: 0, 
              icon: Icons.home, 
              label: 'Anasayfa',
              onTap: () {
                if (_currentIndex == 0) {
                  // Zaten ana sayfadaysa, sayfayı yenile
                  _homeTabKey.currentState?.refreshPage();
                } else {
                  // Ana sayfaya git
                  _navigateTo(0);
                }
              }),
          _buildNavButton(
              index: 1, icon: Icons.qr_code_scanner, label: 'Barkod'),
          _buildNavButton(
              index: 2,
              icon: Icons.document_scanner,
              label: 'İş Emri',
              onTap: _navigateToOcr),
          _buildNavButton(index: 3, icon: Icons.tune, label: 'Config'),
          // Ayarlar sadece developer için
          if (authService.isDeveloper)
            _buildNavButton(index: 4, icon: Icons.settings, label: 'Ayarlar'),

          // Güncelleme butonu - Admin ve Developer için
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openUpdateScreen,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.system_update, color: Colors.blue, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Güncelle',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Kiosk butonu - Sadece developer için
          if (authService.isDeveloper) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openKioskAdmin(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.amber, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Kiosk',
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Çıkış butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, color: Colors.orange, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Çıkış',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required int index,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => _navigateTo(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
