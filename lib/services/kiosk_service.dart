import 'package:flutter/services.dart';

/// Kiosk modu yönetimi servisi
class KioskService {
  static const platform = MethodChannel('com.example.ocr_scanner_app/kiosk');

  bool _isKioskMode = false;
  bool get isKioskMode => _isKioskMode;

  /// Kiosk modunu aç/kapat
  Future<bool> setKioskMode(bool enabled) async {
    try {
      final result = await platform.invokeMethod<bool>(
        'setKioskMode',
        {'enabled': enabled},
      );
      _isKioskMode = enabled;

      if (enabled) {
        // Ekranı her zaman açık tut (uygun olduğunda eklenecek)
        // await WakelockPlus.enable();
      }

      return result ?? false;
    } catch (e) {
      print('Kiosk modu hatası: $e');
      return false;
    }
  }

  /// Tam ekran modunu aç/kapat
  Future<void> setFullscreen(bool enabled) async {
    try {
      await platform.invokeMethod('setFullscreen', {'enabled': enabled});
    } catch (e) {
      print('Tam ekran modu hatası: $e');
    }
  }

  /// Sistem UI'ı gizle/göster (navigation bar, status bar)
  Future<void> hideSystemUI(bool hide) async {
    try {
      await platform.invokeMethod('hideSystemUI', {'hide': hide});
    } catch (e) {
      print('Sistem UI gizleme hatası: $e');
    }
  }

  /// Uygulamayı ekrana sabitle (LockTask)
  Future<bool> lockTaskMode(bool enabled) async {
    try {
      final result = await platform.invokeMethod<bool>(
        'lockTaskMode',
        {'enabled': enabled},
      );
      return result ?? false;
    } catch (e) {
      print('LockTask modu hatası: $e');
      return false;
    }
  }

  /// Geri tuşunu devre dışı bırak
  Future<void> disableBackButton() async {
    try {
      await platform.invokeMethod('disableBackButton');
    } catch (e) {
      print('Geri tuşu devre dışı bırakma hatası: $e');
    }
  }

  /// Ana ekrana dönüşü engelle
  Future<void> preventHomeButton() async {
    try {
      await platform.invokeMethod('preventHomeButton');
    } catch (e) {
      print('Ana ekran tuşu engelleme hatası: $e');
    }
  }

  /// Ekran yakalamayı engelle
  Future<void> preventScreenCapture(bool prevent) async {
    try {
      await platform.invokeMethod(
        'preventScreenCapture',
        {'prevent': prevent},
      );
    } catch (e) {
      print('Ekran yakalama engelleme hatası: $e');
    }
  }

  /// Kiosk modundan çık (admin şifresi gereklidir)
  Future<bool> exitKioskMode(String adminPassword) async {
    try {
      final result = await platform.invokeMethod<bool>(
        'exitKioskMode',
        {'password': adminPassword},
      );
      return result ?? false;
    } catch (e) {
      print('Kiosk moddan çıkma hatası: $e');
      return false;
    }
  }
}

/// Global kiosk service instance
final kioskService = KioskService();
