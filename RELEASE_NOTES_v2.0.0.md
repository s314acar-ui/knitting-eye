# 🎉 Knitting Eye v2.0.0 - İlk Yayın

**Yayın Tarihi**: 6 Şubat 2026

## ✨ Özellikler

### 📱 Temel Özellikler
- ✅ **Barkod Tarama**: Google ML Kit ile hızlı ve doğru barkod okuma
- ✅ **Dual OCR Sistemi**: 
  - **Basit OCR** (Operatör): In-app kamera, hızlı işlem, otomatik dönüş
  - **Detaylı OCR** (Admin/Developer): Native kamera, detaylı sonuç görüntüleme
- ✅ **In-App Kamera Kontrolü**:
  - Ön/arka kamera değiştirme
  - Zoom kontrolü (0.5×, 1×, 2×)
  - Tap-to-focus
  - Fotoğraf çektikten sonra otomatik kapanma
- ✅ **WebView Ana Sayfa**: Özelleştirilebilir web içerik
- ✅ **HTTP/HTTPS Desteği**: Yerel sunucu bağlantıları
- ✅ **Offline Mod**: İnternet olmadan çalışabilir

### 🔐 Güvenlik & Yönetim
- ✅ **Rol Tabanlı Erişim**:
  - **Operatör**: Basit arayüz, temel özellikler
  - **Yönetici**: Yapılandırma + Güncelleme
  - **Developer** (el1984): Tüm özellikler + Kiosk modu
- ✅ **Kiosk Modu**: Cihaz kilitleme (sadece Developer)
- ✅ **Ekran Koruma**: Screenshot engelleme
- ✅ **Wakelock**: Ekranın uykuya geçmesini engelleme

### 🔄 Otomatik Güncelleme Sistemi
- ✅ **GitHub Releases Entegrasyonu**: Otomatik güncelleme kontrolü
- ✅ **İndirme Progress Bar**: Gerçek zamanlı indirme durumu
- ✅ **Versiyon Karşılaştırma**: Semantic versioning desteği
- ✅ **Güncelleme Bildirimi**: Yeni sürüm mevcut olduğunda bildirim
- ✅ **Tek Tıkla Güncelleme**: APK indir ve yükle

### 🎨 Kullanıcı Arayüzü
- ✅ **ELiAR Kurumsal Kimlik**: Logo ve renk paleti entegrasyonu
- ✅ **Karanlık Tema**: Modern gri tonlarda tasarım
- ✅ **Basitleştirilmiş Operatör Modu**: 
  - Büyük butonlar (28px ikon, 17px metin)
  - Sadece gerekli özellikler
  - Kamerada X butonu ile anasayfaya dönüş
- ✅ **Gelişmiş Admin/Developer Modu**: Tam kontrol ve yapılandırma

## 🐛 Düzeltmeler

- 🐛 **Kamera Çift Tıklama Hatası**: Hızlı hızlı butona basınca oluşan kırmızı error ve kiosk moddan çıkma sorunu düzeltildi
- 🐛 **CameraController Dispose**: Kamera kontrolcüsü düzgün dispose edilmeyen durumlarda oluşan hatalar giderildi
- 🐛 **Ön Kamera Siyah Ekran**: Kamera değiştirilirken oluşan siyah ekran sorunu çözüldü
- 🐛 **Operatör Erişim Kontrolü**: Operatör kullanıcıların ayarlar ve admin paneline erişimi engellendi

## 📥 Kurulum

1. **APK İndirin**: `Knitting_Eye_v2.0.0.apk` dosyasını indirin
2. **Bilinmeyen Kaynak İzni**: Android ayarlarından "Bilinmeyen kaynaklardan yükleme" iznini verin
3. **Yükleyin**: APK dosyasına tıklayın ve yükleyin
4. **İzinler**: Kamera ve depolama izinlerini verin

## 🚀 Kullanım

### Operatör Modu (Varsayılan)
- Ana sayfa otomatik yüklenir
- **Barkod** butonu ile barkod tarayın
- **İş Emri** butonu ile hızlı OCR yapın
  - Ön kamera varsayılan olarak açılır
  - Kamera değiştirme, zoom ve focus kullanabilirsiniz
  - Fotoğraf çektikten sonra işleme ekranı gösterilir
  - Başarı ekranından sonra otomatik olarak anasayfaya döner
  - X butonuyla istediğiniz zaman anasayfaya dönebilirsiniz

### Yönetici Modu
- Logo'ya tıklayıp yönetici şifresi ile giriş yapın
- **Config**: Yapılandırma ayarları
- **Güncelle**: Uygulama güncellemelerini kontrol edin
- **İş Emri**: Detaylı OCR sonuçları

### Developer Modu
- Logo'ya tıklayıp `el1984` şifresi ile giriş yapın
- **Ayarlar**: Ana sayfa URL'sini değiştirin
- **Kiosk**: Cihazı kiosk moduna alın
- **Güncelle**: Otomatik güncelleme sistemini kullanın
- Versiyon bilgisi ve tüm özelliklere erişim

## 🔄 Otomatik Güncelleme Nasıl Çalışır?

1. **Yönetici veya Developer** olarak giriş yapın
2. **"Güncelle"** butonuna tıklayın
3. Sistem GitHub Releases'i kontrol eder
4. Yeni versiyon varsa:
   - Güncelleme notları gösterilir
   - **"İndir ve Yükle"** butonuna tıklayın
   - APK otomatik olarak indirilir
   - İndirme tamamlanınca kurulum ekranı açılır
5. APK'yı yükleyin ve yeni özelliklerin keyfini çıkarın!

## 📋 Gereksinimler

- **Android**: 5.0 (API 21) ve üzeri
- **RAM**: Minimum 2 GB
- **Depolama**: 200 MB boş alan
- **Kamera**: Ön ve/veya arka kamera
- **İnternet**: OCR ve güncelleme için gerekli (opsiyonel)

## 🛠️ Teknik Bilgiler

- **Flutter**: 3.5.4
- **Dart**: 3.5.4
- **Build Type**: Debug APK (~188 MB)
- **Package**: com.example.ocr_scanner_app
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 36
- **Version Code**: 2

## 🐛 Bilinen Sorunlar

1. **Release APK**: ProGuard ML Kit ile çakışıyor, şimdilik debug APK kullanılıyor
2. **Ön Kamera Çözünürlük**: Bazı cihazlarda ön kamera çözünürlüğü düşük olabilir
3. **APK Boyutu**: Debug build olduğu için APK boyutu büyük (~188 MB)

## 📝 Notlar

- Bu uygulama **private repository** olarak geliştirilmektedir
- Developer şifresi: `el1984` (güvenli saklayın)
- Güncelleme sistemi GitHub Releases kullanır
- Kiosk modu sadece **Developer** hesabında aktiftir

## 🔗 Bağlantılar

- **Repository**: https://github.com/s314acar-ui/knitting-eye (Private)
- **Releases**: https://github.com/s314acar-ui/knitting-eye/releases
- **Issues**: https://github.com/s314acar-ui/knitting-eye/issues

## 👨‍💻 Geliştirici

Flutter & Dart ile geliştirilmiştir.

---

**Not**: Uygulama kurulduktan sonra otomatik güncelleme sistemi aktif olacaktır. Yeni versiyonlar yayınlandığında uygulama içinden güncelleyebilirsiniz.
