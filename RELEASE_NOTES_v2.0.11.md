# Release Notes - v2.0.11

## 🆕 Yeni Özellikler

### Otomatik Kiosk Mode
- **Operatör ekranında otomatik kiosk mode**: Operatör olarak giriş yapıldığında (otomatik giriş) uygulama otomatik olarak kiosk moduna geçer
- **500ms gecikme**: Ekranın tam yüklenmesini bekledikten sonra kiosk mode etkinleşir
- **Debug logları**: Kiosk mode başarı/hata durumları loglanır
- **Sorunsuz geçiş**: Kullanıcı müdahalesi gerektirmeden otomatik başlatma

### Kiosk Mode Davranışı
- **Tam ekran modu**: Uygulama tam ekran olarak çalışır
- **Sistem UI gizleme**: Navigation bar ve status bar gizlenir
- **Lock task mode**: Uygulama ekrana sabitlenir
- **Geri tuşu devre dışı**: Operatör geri tuşuna basamaz
- **Ana ekran tuşu engelleme**: Home tuşu ile çıkış engellenir
- **Ekran yakalama engelleme**: Screenshot alınamaz

### Developer Erişimi
- Developer (`el1984`) şifresi ile giriş yapıldığında kiosk mode devredışı kalır
- Developer her zaman kiosk ayarlarını yönetebilir
- Kiosk Admin ekranından manuel olarak çıkış yapılabilir

## 🔧 Teknik Detaylar

### Değişen Dosyalar
- `main_screen.dart`: Otomatik kiosk mode başlatma eklendi
- `kiosk_service.dart` kullanımı: Mevcut servis entegre edildi

### Başlatma Akışı
1. Uygulama açılır → Otomatik operatör girişi (`login_screen.dart`)
2. MainScreen yüklenir → `initState()` çalışır
3. 500ms bekleme → Ekran render edilir
4. `kioskService.setKioskMode(true)` çağrılır
5. Kiosk mode aktif → Operatör kısıtlı modda çalışır

### Native Android İşlevler
- MainActivity.kt'deki kiosk metodları kullanılır:
  - `setKioskMode(enabled)`
  - `setFullscreen(enabled)`
  - `hideSystemUI(hide)`
  - `lockTaskMode(enabled)`
  - `preventScreenCapture(prevent)`

## 📋 Kullanım

### Operatör Kullanımı
1. Uygulamayı aç → Otomatik olarak operatör girişi
2. Kiosk mode otomatik etkinleşir
3. Tam ekran, kısıtlı erişim ile çalış
4. Çıkış yap ile uygulamadan çık

### Developer Kullanımı
1. Logo'ya uzun bas → Admin giriş ekranı
2. `el1984` şifresi ile giriş
3. Developer ekranı açılır (kiosk mode YOK)
4. Tüm yönetim fonksiyonlarına erişim
5. Kiosk Admin ekranından manuel kiosk ayarları

## ⚠️ Önemli Notlar

- Otomatik kiosk mode sadece operatör girişinde çalışır
- Developer girişinde kiosk mode devreye girmez
- Kiosk moddan çıkmak için developer şifresi gerekir
- Android Device Owner mode önerilir (tam kiosk işlevselliği için)
- Bazı kiosk özellikleri (home tuşu engelleme) Device Owner mode gerektirir

## 🎨 Kullanıcı Deneyimi İyileştirmeleri

- Sorunsuz başlangıç: Operatör hiçbir şey farketmez
- Otomatik güvenlik: Ekrana sabitleme otomatik çalışır
- Developer esnekliği: Developer her zaman tam kontrole sahip
- Debug desteği: Konsol logları ile izlenebilir

## 🔒 Güvenlik

- Operatör kullanıcıları uygulamadan çıkamaz
- Sistem ayarlarına erişim engellenir
- Developer şifresi olmadan kiosk moddan çıkış yapılamaz
- Ekran görüntüsü alınamaz

---

**Yayın Tarihi**: 10 Şubat 2026
**Build Number**: 13
**Min Android**: 21 (5.0 Lollipop)
**Target Android**: 34 (14.0)
**Önerilen**: Device Owner Mode (Tam Kiosk)
