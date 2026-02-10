# Release Notes - v2.0.10

## 🆕 Yeni Özellikler

### Uygulama Yükleme İzin Yönetimi
- **Developer ilk girişinde otomatik izin kontrolü**: Developer ile ilk giriş yapıldığında, "Bilinmeyen kaynaklardan uygulama yükleme" izni otomatik olarak kontrol edilir
- **İzin dialog'u**: İzin verilmemişse bilgilendirme dialog'u ile kullanıcı Android ayarlarına yönlendirilir
- **Developer Ayarlar panelinde izin yönetimi**:
  - İzin durumu göstergesi (Verildi ✅ / Verilmedi ❌)
  - "İzin Ver" butonu ile Android ayarlarını tetikleme
  - "Durumu Güncelle" butonu ile manuel kontrol
  - Otomatik durum güncelleme (ayarlardan geri dönüldüğünde)
- **Kiosk mode uyumluluğu**: Kiosk modunda güncelleme yapabilmek için gerekli izinler developer ayarlarından yönetilebilir

### Native Android İyileştirmeleri
- Yeni `requestInstallPermission` MethodChannel metodu
- APK dosyası olmadan sadece izin ayarlarını açma özelliği
- Uygulama lifecycle'ı ile entegre izin kontrolü

## 🔧 Teknik Detaylar

### Değişen Dosyalar
- `MainActivity.kt`: `requestInstallPermission` metodu eklendi
- `update_service.dart`: İzin isteme metodu eklendi
- `admin_main_screen.dart`: Developer girişinde otomatik izin kontrolü
- `settings_screen.dart`: İzin yönetim paneli eklendi

### İzin Akışı
1. Developer girişi → Otomatik izin kontrolü
2. İzin yoksa → Bilgilendirme dialog'u
3. "İzin Ver" → Android ayarları açılır
4. İzin etkinleştirilir → Geri dönüldüğünde otomatik tespit
5. Developer Ayarlar'dan istediği zaman kontrol edebilir

## 📋 Kullanım

### İlk Kurulum
1. Developer şifresi ile giriş yapın (`el1984`)
2. İzin dialog'u açılırsa "İzin Ver" butonuna basın
3. Android ayarlarında izni etkinleştirin
4. Geri dönün - izin otomatik tespit edilir

### İzin Yönetimi
1. Developer ekranında "Ayarlar" sekmesine gidin
2. "Uygulama İzinleri" bölümünde durum görüntülenir
3. İzin yoksa "İzin Ver" ile ayarlara gidin
4. "Durumu Güncelle" ile manuel kontrol yapın

## ⚠️ Önemli Notlar

- Bu izin, kiosk modunda APK güncellemeleri için kritiktir
- İzin sadece developer ekranından yönetilir
- Operatör kullanıcıları bu ayarlara erişemez
- Android 8.0+ için gereklidir (eski Android sürümlerinde otomatik verilir)

## 🎨 UI/UX İyileştirmeleri

- İzin durumuna göre renkli gösterge (yeşil/kırmızı)
- Açıklayıcı bilgilendirme mesajları
- Kiosk mode özel uyarı notu
- Lifecycle-aware otomatik güncelleme

---

**Yayın Tarihi**: 10 Şubat 2026
**Build Number**: 12
**Min Android**: 21 (5.0 Lollipop)
**Target Android**: 34 (14.0)
