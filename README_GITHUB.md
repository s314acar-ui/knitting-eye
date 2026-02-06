# ELiAR OCR Scanner

**ELiAR OCR Scanner**, barkod tarama ve OCR (Optik Karakter Tanıma) özelliklerine sahip bir Flutter tabanlı Android uygulamasıdır. Kiosk modunu destekler ve rol tabanlı kullanıcı yönetimi sunar.

## 📱 Özellikler

### 🔍 Tarama Özellikleri
- **Barkod Tarama**: Google ML Kit ile hızlı ve doğru barkod okuma
- **OCR (Metin Tanıma)**: Kamera ile metin okuma ve tanıma
- **Gerçek Zamanlı Tarama**: Anlık sonuçlar

### 🌐 Web Entegrasyonu
- **Ana Sayfa WebView**: Özelleştirilebilir ana sayfa URL'si
- **HTTP Desteği**: Yerel sunuculara bağlanma
- **API Entegrasyonu**: REST API ile veri gönderimi

### 👥 Kullanıcı Rolleri
- **Operatör**: Temel tarama işlemleri
- **Yönetici**: Yapılandırma ve ayarlar
- **Developer**: Gizli geliştirici modu (Şifre: `el1984`)

### 🔒 Kiosk Modu
- Tablet cihazları kiosk moduna çevirme
- Geri tuşunu devre dışı bırakma
- Ekran kapatmayı engelleme
- **Sadece Developer erişimi** (Developer şifresi ile giriş yapınca görünür)

### ⚙️ Diğer Özellikler
- **Karanlık Tema**: Gri-siyah renk şeması
- **Offline Çalışma**: İnternet bağlantısı gerektirmez
- **Özelleştirilebilir Ayarlar**: URL, timeout, vb.
- **Paylaşma**: Sonuçları paylaşma

## 📥 Kurulum

### APK İndirme
1. [Releases](../../releases) sayfasından en son APK dosyasını indirin
2. APK dosyasını Android cihazınıza aktarın
3. "Bilinmeyen kaynaklardan yükleme" iznini verin
4. APK'yı yükleyin

### Kaynak Koddan Derleme
```bash
# Repoyu klonlayın
git clone https://github.com/KULLANICI_ADINIZ/ocr_scanner_app.git
cd ocr_scanner_app

# Bağımlılıkları yükleyin
flutter pub get

# Debug APK oluşturun
flutter build apk --debug

# Release APK oluşturun (opsiyonel)
flutter build apk --release
```

## 🚀 Kullanım

### İlk Kurulum
1. Uygulamayı açın
2. Operatör veya Yönetici olarak giriş yapın
3. Ayarlar bölümünden **Anasayfa URL**'sini girin (ör: `http://192.168.1.100:8080`)
4. API endpoint ayarlarını yapılandırın

### Developer Modu
1. Giriş ekranında şifre: **`el1984`** girin
2. Ana ekranda **Kiosk** butonu (Amber renk) görünür
3. Kiosk modunu aç/kapat yapabilirsiniz

### Kiosk Modu Kullanımı
1. Developer olarak giriş yapın
2. Ana ekrandaki **Kiosk** butonuna tıklayın
3. Kiosk modunu açın (Geri tuşu, ekran kapatma devre dışı)
4. Çıkmak için aynı ekrandan kapatın (şifre gerekmiyor)

## 🔧 Yapılandırma

### Ayarlar (Yönetici/Developer)
- **Anasayfa URL**: WebView'da gösterilecek URL
- **API Base URL**: API sunucusu adresi
- **Timeout**: İstek zaman aşımı süresi
- **Otomatik Gönderim**: Tarama sonuçlarını otomatik API'ye gönder

## 🛠️ Teknik Detaylar

### Kullanılan Teknolojiler
- **Flutter**: ^3.5.4
- **Dart**: ^3.5.4
- **Google ML Kit**: Barkod ve OCR için
- **WebView Flutter**: Web sayfası gösterimi
- **Shared Preferences**: Yerel veri saklama

### Paketler
- `camera`: ^0.10.6
- `google_mlkit_barcode_scanning`: ^0.10.0
- `google_mlkit_text_recognition`: ^0.11.0
- `webview_flutter`: ^4.11.0
- `http`: ^1.2.2
- `shared_preferences`: ^2.3.3
- `wakelock_plus`: ^1.3.3
- `screen_protector`: ^1.5.1

### Minimum Gereksinimler
- **Android**: 5.0 (API 21) veya üzeri
- **Depolama**: 200 MB boş alan
- **Kamera**: Barkod ve OCR için gerekli
- **İzinler**: Kamera, Depolama, İnternet

## 🔐 Güvenlik

- **Developer Şifresi**: `el1984` (kodda sabit, kullanıcılara gösterilmez)
- **Kiosk Modu**: Sadece developer erişimi
- **HTTP Desteği**: Cleartext traffic etkin (yerel ağ için)

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır.

## 👨‍💻 Geliştirici

- **GitHub**: [KULLANICI_ADINIZ]
- **Proje**: ELiAR OCR Scanner App

## 🤝 Katkıda Bulunma

1. Bu repository'yi fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'feat: Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📝 Notlar

- **APK Boyutu**: ~188 MB (Debug build, ML Kit modelleri dahil)
- **Release APK**: ProGuard sorunu nedeniyle debug APK yayınlanmıştır
- **Kiosk Modu**: Device Owner/Admin izinleri gerekebilir

## ⚠️ Bilinen Sorunlar

- Release build'de ProGuard/R8 ile ML Kit uyumluluk sorunu
- Android 14+ cihazlarda kiosk modu için ek izinler gerekebilir

## 🆘 Destek

Sorun yaşarsanız [Issues](../../issues) bölümünde yeni bir issue açın.

---

**Son Güncelleme**: Şubat 2026  
**Versiyon**: 1.0.0+1
