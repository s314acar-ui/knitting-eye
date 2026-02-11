import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';
import 'admin_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _showAdminLogin = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    // Uygulama açıldığında otomatik operatör girişi
    setState(() => _isLoading = true);

    // Operatör olarak giriş yap
    await authService.loginAsOperator();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  Future<void> _loginAsOperator() async {
    setState(() => _isLoading = true);
    await authService.loginAsOperator();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  Future<void> _loginAsAdmin() async {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Şifre giriniz');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await authService.loginAsAdmin(password);

    if (user != null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminMainScreen()),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Yanlış şifre';
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_showAdminLogin) {
      return Scaffold(
        backgroundColor: const Color(0xFF3D3D3D),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Yatay Logo
              Image.asset(
                'assets/images/logo_horizontal.png',
                height: 60,
              ),
              const SizedBox(height: 16),
              // Alt yazılar
              Text(
                'ELiAR',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Knitting Eye',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF424242),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  'assets/images/logo_white.png',
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 32),

              if (!_showAdminLogin) ...[
                // Operatör Girişi
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loginAsOperator,
                    icon: const Icon(Icons.person),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Operatör Girişi',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF424242),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Firma Yetkilisi butonu
                TextButton(
                  onPressed: () => setState(() => _showAdminLogin = true),
                  child: const Text(
                    'Firma Yetkilisi Girişi',
                    style: TextStyle(
                      color: Color(0xFF424242),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ] else ...[
                // Admin login form
                const Text(
                  'Firma Yetkilisi Girişi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  authService.hasAdminPassword
                      ? 'Şifrenizi giriniz'
                      : 'İlk giriş - Yeni şifre belirleyin',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Şifre alanı
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    errorText: _errorMessage,
                  ),
                  onSubmitted: (_) => _loginAsAdmin(),
                ),
                const SizedBox(height: 24),

                // Giriş butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginAsAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF424242),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Giriş Yap',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Geri butonu
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAdminLogin = false;
                      _errorMessage = null;
                      _passwordController.clear();
                    });
                  },
                  child: const Text(
                    '← Geri',
                    style: TextStyle(color: Color(0xFF424242)),
                  ),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}
