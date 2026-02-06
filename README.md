# Knitting Eye - Endüstriyel Okuma Sistemi

**Knitting Eye**, barkod tarama, OCR (Optik Karakter Tanıma) ve WebView entegrasyonu ile donatılmış profesyonel bir Flutter Android uygulamasıdır. ELiAR kurumsal kimliği ile tasarlanmıştır.

## 🎯 Özellikler

### 📱 Temel Özellikler
- ✅ **Barkod Tarama**: Google ML Kit ile hızlı ve doğru barkod okuma
- ✅ **OCR (Metin Tanıma)**: Belgelerden otomatik metin çıkarma
- ✅ **In-App Kamera**: Ön/arka kamera değiştirme, zoom (0.5×-2×), tap-to-focus
- ✅ **WebView Ana Sayfa**: Özelleştirilebilir web içerik görüntüleme
- ✅ **HTTP Desteği**: Yerel sunucular için cleartext traffic
- ✅ **Offline/Online Modlar**: İnternet bağlantısı olmadan çalışabilir
- ✅ **Otomatik Güncelleme**: GitHub Releases üzerinden uygulama güncellemeleri

### 🔐 Güvenlik & Yönetim
- ✅ **Rol Tabanlı Erişim**: Operatör / Yönetici / Developer rolleri
- ✅ **Kiosk Modu**: Cihaz kilitleme (sadece Developer)
- ✅ **Ekran Koruma**: Ekran görüntüsü engelleme
- ✅ **Wakelock**: Ekranın uykuya geçmesini engelleme

### 🎨 Kullanıcı Arayüzü
- ✅ **ELiAR Kurumsal Kimlik**: Logo ve renk paleti entegrasyonu
- ✅ **Karanlık Tema**: Modern gri tonlarda tasarım
- ✅ **Basitleştirilmiş Operatör Modu**: Minimum buton, maksimum verimlilik
- ✅ **Gelişmiş Admin/Developer Modu**: Tam kontrol ve yapılandırma

## 📥 Kurulum

### APK İndirme
1. [Releases](https://github.com/s314acar-ui/knitting-eye/releases) sayfasından en son APK dosyasını indirin
2. APK dosyasını Android cihazınıza aktarın
3. "Bilinmeyen kaynaklardan yükleme" iznini verin
4. APK'yı yükleyin

### Kaynak Koddan Derleme
```bash
# Repoyu klonlayın
git clone https://github.com/s314acar-ui/knitting-eye.git
cd knitting-eye

# Bağımlılıkları yükleyin
flutter pub get

# Debug APK oluşturun
flutter build apk --debug

# Release APK oluşturun (imzalama gerekir)
flutter build apk --release
```

## 🚀 Kullanım

### Operatör Modu (Varsayılan)
1. Uygulamayı açın
2. Ana sayfa WebView ile yüklenir
3. **Barkod** butonu: Barkod tarama
4. **İş Emri** butonu: Basitleştirilmiş OCR (ön kamera, hızlı işlem)

### Yönetici Modu
1. Logo'ya tıklayın
2. Yönetici şifresi ile giriş yapın
3. Ek özellikler:
   - **Config**: Yapılandırma ayarları
   - **Güncelle**: Uygulama güncellemelerini kontrol et
   - Detaylı OCR sonuçları

### Developer Modu
1. Logo'ya tıklayın
2. `el1984` şifresi ile giriş yapın
3. Tüm özelliklere erişim:
   - **Ayarlar**: Ana sayfa URL değiştirme
   - **Kiosk**: Cihaz kilitleme modu
   - **Güncelle**: Otomatik güncelleme sistemi
   - Versiyon bilgisi ve detaylı loglama

## 🔧 Yapılandırma

### Ana Sayfa URL Değiştirme (Developer)
1. Developer olarak giriş yapın
2. **Ayarlar** > Ana Sayfa URL
3. Yeni URL girin ve kaydedin

### Kiosk Modu (Developer)
1. **Kiosk** butonuna tıklayın
2. "Kiosk Modunu Başlat" ile cihazı kilitleyin
3. Çıkmak için: PIN girin veya "Kiosk Modunu Durdur"

### Güncelleme Kontrolü (Admin/Developer)
1. **Güncelle** butonuna tıklayın
2. Yeni versiyon varsa indir ve yükle
3. APK otomatik olarak kurulum için açılır

## 🛠️ Teknik Detaylar

### Gereksinimler
- **Android**: 5.0 (API 21) ve üzeri
- **Flutter**: 3.5.4
- **Dart**: 3.5.4
- **Kamera İzni**: Barkod ve OCR için gerekli
- **Depolama İzni**: APK güncelleme için gerekli
- **Internet**: OCR ve güncelleme için gerekli

### Kullanılan Paketler
```yaml
dependencies:
  camera: ^0.10.5+9              # Kamera kontrolü
  google_mlkit_barcode_scanning   # Barkod tarama
  google_mlkit_text_recognition   # OCR
  webview_flutter: ^4.4.2         # WebView
  http: ^1.1.0                    # API istekleri
  shared_preferences: ^2.2.2      # Yerel veri saklama
  permission_handler: ^11.0.1     # İzin yönetimi
  wakelock_plus: ^1.2.4           # Ekran açık tutma
  screen_protector: ^1.5.1        # Ekran koruması
  open_file: ^3.3.2               # APK kurulumu
```

### Proje Yapısı
```
lib/
├── main.dart                    # Uygulama giriş noktası
├── models/                      # Veri modelleri
│   ├── line_type.dart
│   └── scan_result.dart
├── screens/                     # Ekranlar
│   ├── main_screen.dart         # Operatör ana ekran
│   ├── admin_main_screen.dart   # Admin/Developer ana ekran
│   ├── simple_ocr_screen.dart   # Basit OCR (operatör)
│   ├── ocr_screen.dart          # Detaylı OCR (admin)
│   ├── barcode_screen.dart      # Barkod tarama
│   ├── update_screen.dart       # Güncelleme ekranı
│   ├── config_screen.dart       # Yapılandırma
│   ├── settings_screen.dart     # Ayarlar (developer)
│   └── kiosk_admin_screen.dart  # Kiosk yönetimi
└── services/                    # Servisler
    ├── auth_service.dart        # Kimlik doğrulama
    ├── document_ai_service.dart # OCR işleme
    ├── api_server.dart          # API entegrasyonu
    ├── settings_service.dart    # Ayarlar yönetimi
    └── update_service.dart      # Güncelleme servisi
```

## 🔐 Güvenlik

- **Ekran Görüntüsü Engelleme**: Hassas veri koruması
- **Şifre Korumalı Modlar**: Rol tabanlı erişim kontrolü
- **Kiosk Modu**: Cihaz yetkisiz kullanım koruması
- **HTTPS Desteği**: Güvenli veri iletimi

## 📱 Ekran Görüntüleri

### Operatör Modu
- Basit, büyük butonlar
- Ana sayfa, Barkod, İş Emri

### Yönetici Modu
- Ek yapılandırma seçenekleri
- Güncelleme kontrolü
- Detaylı OCR sonuçları

### Developer Modu
- Tüm özellikler
- Kiosk modu
- Ayarlar ve versiyon bilgisi

## 🐛 Bilinen Sorunlar

1. **Release APK ProGuard Hatası**: Release build'ler ML Kit ile çakışıyor. Şimdilik debug APK kullanılıyor.
2. **Ön Kamera Çözünürlük**: Bazı cihazlarda ön kamera çözünürlüğü düşük olabilir.

## 🔄 Güncelleme Geçmişi

### v2.0.0 (Şubat 2026)
- ✨ Dual OCR sistemi (basit/detaylı)
- ✨ In-app kamera kontrolü
- ✨ Otomatik güncelleme sistemi
- ✨ ELiAR kurumsal kimlik entegrasyonu
- 🐛 Kamera çift tıklama hatası düzeltildi
- 🎨 Operatör modu UI iyileştirmeleri

## 📄 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 👨‍💻 Geliştirici

Flutter & Dart ile geliştirilmiştir.

**GitHub**: [s314acar-ui/knitting-eye](https://github.com/s314acar-ui/knitting-eye)

## 🤝 Katkıda Bulunma

1. Bu repoyu fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'feat: Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 🆘 Destek

Sorun yaşıyorsanız veya önerileriniz varsa [Issues](https://github.com/s314acar-ui/knitting-eye/issues) sayfasından bildirebilirsiniz.

---

**Not**: Bu uygulama private repository olarak geliştirilmektedir. Erişim için yetki gereklidir.
