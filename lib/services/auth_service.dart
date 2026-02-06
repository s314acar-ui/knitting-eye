import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';

/// Kimlik doğrulama servisi
class AuthService {
  static const String _adminPasswordKey = 'admin_password';
  static const String _lastRoleKey = 'last_role';
  static const String _developerPassword =
      'el1984'; // Gizli geliştirici şifresi

  SharedPreferences? _prefs;
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isDeveloper => _currentUser?.isDeveloper ?? false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Operatör olarak giriş yap (şifresiz)
  Future<User> loginAsOperator() async {
    _currentUser = User(role: UserRole.operator, name: 'Operatör');
    await _prefs?.setString(_lastRoleKey, 'operator');
    return _currentUser!;
  }

  /// Firma yetkilisi olarak giriş yap
  Future<User?> loginAsAdmin(String password) async {
    // Geliştirici şifresi - her zaman çalışır ve developer yetkisi verir
    if (password == _developerPassword) {
      _currentUser = User(
        role: UserRole.admin,
        name: 'Developer',
        isDeveloper: true,
      );
      await _prefs?.setString(_lastRoleKey, 'admin');
      return _currentUser;
    }

    final savedPassword = _prefs?.getString(_adminPasswordKey);

    // İlk kez giriş - şifre yoksa yeni şifre olarak kaydet
    if (savedPassword == null || savedPassword.isEmpty) {
      await _prefs?.setString(_adminPasswordKey, password);
      _currentUser = User(
        role: UserRole.admin,
        name: 'Firma Yetkilisi',
        isDeveloper: false,
      );
      await _prefs?.setString(_lastRoleKey, 'admin');
      return _currentUser;
    }

    // Şifre doğrulama
    if (password == savedPassword) {
      _currentUser = User(
        role: UserRole.admin,
        name: 'Firma Yetkilisi',
        isDeveloper: false,
      );
      await _prefs?.setString(_lastRoleKey, 'admin');
      return _currentUser;
    }

    return null; // Yanlış şifre
  }

  /// Admin şifresi ayarlanmış mı?
  bool get hasAdminPassword {
    final savedPassword = _prefs?.getString(_adminPasswordKey);
    return savedPassword != null && savedPassword.isNotEmpty;
  }

  /// Mevcut admin şifresini al (sadece dahili kullanım)
  String? get currentAdminPassword => _prefs?.getString(_adminPasswordKey);

  /// Admin şifresini değiştir
  Future<bool> changeAdminPassword(
      String currentPassword, String newPassword) async {
    final savedPassword = _prefs?.getString(_adminPasswordKey);

    // Geliştirici şifresi veya mevcut şifre ile değiştirebilir
    if (currentPassword == _developerPassword ||
        savedPassword == currentPassword) {
      await _prefs?.setString(_adminPasswordKey, newPassword);
      return true;
    }
    return false;
  }

  /// Admin şifresini sıfırla/sil (şifre doğrulaması ile)
  Future<bool> deleteAdminPassword(String currentPassword) async {
    final savedPassword = _prefs?.getString(_adminPasswordKey);

    // Geliştirici şifresi veya mevcut şifre ile silebilir
    if (currentPassword == _developerPassword ||
        savedPassword == currentPassword) {
      await _prefs?.remove(_adminPasswordKey);
      return true;
    }
    return false;
  }

  /// Admin şifresini ayarla (yeni şifre için)
  Future<void> setAdminPassword(String password) async {
    await _prefs?.setString(_adminPasswordKey, password);
  }

  /// Çıkış yap
  Future<void> logout() async {
    _currentUser = null;
  }

  /// Son oturumu operatör olarak aç
  Future<User> autoLoginAsOperator() async {
    return loginAsOperator();
  }
}

/// Global auth service instance
final authService = AuthService();
