import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tailscale VPN entegrasyonu servisi
class TailscaleService {
  static const platform = MethodChannel('com.example.ocr_scanner_app/tailscale');
  static const String _tailscaleEnabledKey = 'tailscale_enabled';
  static const String _tailscaleAuthKeyKey = 'tailscale_auth_key';

  SharedPreferences? _prefs;
  bool _isTailscaleConnected = false;

  bool get isTailscaleConnected => _isTailscaleConnected;

  /// Servisi başlat
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _checkTailscaleStatus();
  }

  /// Tailscale bağlantı durumunu kontrol et
  Future<void> _checkTailscaleStatus() async {
    try {
      final result = await platform.invokeMethod<bool>('checkTailscaleStatus');
      _isTailscaleConnected = result ?? false;
    } catch (e) {
      print('Tailscale durum kontrolü hatası: $e');
      _isTailscaleConnected = false;
    }
  }

  /// Tailscale VPN'ini başlat (auth key ile)
  Future<bool> startTailscale(String authKey) async {
    try {
      final result = await platform.invokeMethod<bool>(
        'startTailscale',
        {'authKey': authKey},
      );

      if (result ?? false) {
        await _prefs?.setBool(_tailscaleEnabledKey, true);
        await _prefs?.setString(_tailscaleAuthKeyKey, authKey);
        _isTailscaleConnected = true;
        return true;
      }
      return false;
    } catch (e) {
      print('Tailscale başlatma hatası: $e');
      return false;
    }
  }

  /// Tailscale VPN'ini durdur
  Future<bool> stopTailscale() async {
    try {
      final result = await platform.invokeMethod<bool>('stopTailscale');

      if (result ?? false) {
        await _prefs?.setBool(_tailscaleEnabledKey, false);
        _isTailscaleConnected = false;
        return true;
      }
      return false;
    } catch (e) {
      print('Tailscale durdurma hatası: $e');
      return false;
    }
  }

  /// Tailscale ağında bu cihazın IP'sini al
  Future<String?> getLocalIP() async {
    try {
      final result = await platform.invokeMethod<String>('getLocalIP');
      return result;
    } catch (e) {
      print('Yerel IP alma hatası: $e');
      return null;
    }
  }

  /// Tailscale ağında bu cihazın adını al
  Future<String?> getHostname() async {
    try {
      final result = await platform.invokeMethod<String>('getHostname');
      return result;
    } catch (e) {
      print('Hostname alma hatası: $e');
      return null;
    }
  }

  /// Tailscale ağındaki diğer cihazları listele
  Future<List<Map<String, dynamic>>> getPeers() async {
    try {
      final result = await platform.invokeMethod<List>('getPeers');
      return (result ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Peer listesi alma hatası: $e');
      return [];
    }
  }

  /// Tailscale durum bilgisini al
  Future<Map<String, dynamic>?> getStatus() async {
    try {
      final result = await platform.invokeMethod<Map>('getStatus');
      return result?.cast<String, dynamic>();
    } catch (e) {
      print('Tailscale durum bilgisi alma hatası: $e');
      return null;
    }
  }

  /// API Server'a Tailscale IP'si ile erişim
  Future<String> getApiBaseUrl() async {
    try {
      final localIP = await getLocalIP();
      if (localIP != null && localIP.isNotEmpty) {
        return 'http://$localIP:8080';
      }
      return 'http://localhost:8080';
    } catch (e) {
      print('API base URL oluşturma hatası: $e');
      return 'http://localhost:8080';
    }
  }

  /// Kayıtlı auth key'i al
  String? getSavedAuthKey() {
    return _prefs?.getString(_tailscaleAuthKeyKey);
  }

  /// Tailscale otomatik başlama ayarı
  bool getAutoStartEnabled() {
    return _prefs?.getBool(_tailscaleEnabledKey) ?? false;
  }
}

/// Global tailscale service instance
final tailscaleService = TailscaleService();
