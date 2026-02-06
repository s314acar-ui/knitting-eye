import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _homeUrlKey = 'home_url';
  static const String _barcodeApiUrlKey = 'barcode_api_url';
  static const String _apiPortKey = 'api_port';
  
  SharedPreferences? _prefs;
  String? _deviceIp;
  
  // Singleton
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _deviceIp = await _getDeviceIp();
  }
  
  // Anasayfa URL
  String get homeUrl => _prefs?.getString(_homeUrlKey) ?? '';
  Future<void> setHomeUrl(String url) async {
    await _prefs?.setString(_homeUrlKey, url);
  }
  
  // Barkod API URL
  String get barcodeApiUrl => _prefs?.getString(_barcodeApiUrlKey) ?? '';
  Future<void> setBarcodeApiUrl(String url) async {
    await _prefs?.setString(_barcodeApiUrlKey, url);
  }
  
  // API Port
  int get apiPort => _prefs?.getInt(_apiPortKey) ?? 8080;
  Future<void> setApiPort(int port) async {
    await _prefs?.setInt(_apiPortKey, port);
  }
  
  // Cihaz IP
  String get deviceIp => _deviceIp ?? '127.0.0.1';
  
  String get apiAddress => 'http://$deviceIp:$apiPort';
  
  Future<String> _getDeviceIp() async {
    String ipAddress = '127.0.0.1';
    
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      for (var interface in interfaces) {
        if (interface.name.toLowerCase().contains('wlan') ||
            interface.name.toLowerCase().contains('wifi') ||
            interface.name.toLowerCase().contains('en') ||
            interface.name.toLowerCase().contains('eth')) {
          for (var addr in interface.addresses) {
            if (!addr.address.startsWith('127.')) {
              ipAddress = addr.address;
              break;
            }
          }
        }
      }
      
      if (ipAddress == '127.0.0.1') {
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (!addr.address.startsWith('127.')) {
              ipAddress = addr.address;
              break;
            }
          }
          if (ipAddress != '127.0.0.1') break;
        }
      }
    } catch (e) {
      print('IP adresi alınamadı: $e');
    }
    
    return ipAddress;
  }
  
  Future<void> refreshIp() async {
    _deviceIp = await _getDeviceIp();
  }
}

final settingsService = SettingsService();
