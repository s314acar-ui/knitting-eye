import 'dart:async';
import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'barcode_screen.dart';
import 'simple_ocr_screen.dart';
import 'admin_main_screen.dart';
import '../services/auth_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late Timer _clockTimer;
  String _currentTime = '';

  // GlobalKey'ler
  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();
  final GlobalKey<SimpleOcrScreenState> _ocrScreenKey = GlobalKey<SimpleOcrScreenState>();

  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    _screens = [
      HomeTab(key: _homeTabKey, onNavigateToOcr: () => _navigateToOcr()),
      BarcodeScreen(onComplete: () => _navigateTo(0)),
      SimpleOcrScreen(key: _ocrScreenKey, onComplete: () => _navigateTo(0)),
    ];
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

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToOcr() {
    // OCR'a git ve kamerayı aç
    setState(() {
      _currentIndex = 2;
    });
    // Kamerayı aç
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ocrScreenKey.currentState?.openCamera();
    });
  }

  void _showAdminLogin() {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          title: const Text('Yönetici Girişi', style: TextStyle(fontSize: 18)),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  authService.hasAdminPassword
                      ? 'Şifrenizi giriniz'
                      : 'İlk giriş - Yeni şifre belirleyin',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                      ),
                      onPressed: () => setDialogState(
                          () => obscurePassword = !obscurePassword),
                    ),
                    errorText: errorMessage,
                    errorStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passwordController.text.trim();
                if (password.isEmpty) {
                  setDialogState(() => errorMessage = 'Şifre giriniz');
                  return;
                }

                final user = await authService.loginAsAdmin(password);
                if (user != null) {
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const AdminMainScreen()),
                    );
                  }
                } else {
                  setDialogState(() => errorMessage = 'Yanlış şifre');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF424242),
                foregroundColor: Colors.white,
              ),
              child: const Text('Giriş'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Üst Navigation Bar
          _buildNavBar(),
          // İçerik
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
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sol - Yatay Logo (tıklanabilir)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showAdminLogin,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.asset(
                    'assets/images/logo_horizontal.png',
                    height: 36,
                  ),
                ),
              ),
            ),
          ),

          // Orta - Saat
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
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

          // Sağ - Navigasyon Butonları (büyük)
          _buildNavButton(
            index: 0,
            icon: Icons.home,
            label: 'Anasayfa',
          ),
          _buildNavButton(
            index: 1,
            icon: Icons.qr_code_scanner,
            label: 'Barkod',
          ),
          _buildNavButton(
            index: 2,
            icon: Icons.document_scanner,
            label: 'İş Emri',
            onTap: _navigateToOcr,
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => _navigateTo(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
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
