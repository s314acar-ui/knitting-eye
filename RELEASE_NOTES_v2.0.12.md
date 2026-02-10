# Release Notes - v2.0.12

## 🆕 Yeni Özellikler

### Kiosk Mode ile Güncelleme Desteği
- **Yönetici kiosk modda güncelleme yapabilir**: Artık kiosk mode'dan çıkmadan güncelleme indirip yüklenebilir
- **Otomatik geçici gevşetme**: Güncelleme işlemi sırasında kiosk mode otomatik olarak geçici devre dışı bırakılır
- **Akıllı yeniden kilitleme**: İndirme başarısız olursa veya hata oluşursa kiosk mode otomatik olarak tekrar etkinleşir
- **Yönetici kiosk mode**: Admin kullanıcıları artık operatör gibi kiosk modda çalışır (sadece developer muaf)

## 🔧 Teknik Detaylar

### Değişen Dosyalar
- `admin_main_screen.dart`: Yönetici girişinde otomatik kiosk mode başlatma
- `update_screen.dart`: Güncelleme sırasında geçici kiosk mode gevşetme
- Akıllı kiosk mode yönetimi (try-catch-finally yapısı)

### Kiosk Mode Akışı
1. **Operatör/Yönetici girişi** → Kiosk mode otomatik aktif
2. **Güncelleme başlatıldığında** → Kiosk mode geçici devre dışı
3. **APK indirme/yükleme** → Kurulum ekranına erişim sağlanır
4. **Hata durumunda** → Kiosk mode otomatik tekrar etkinleşir
5. **Başarılı yükleme** → Uygulama yeniden başlar (kiosk mode otomatik aktif)

## 🔒 Güvenlik

### Kiosk Mode Kapsamı
- ✅ **Operatör**: Her zaman kiosk modda
- ✅ **Yönetici (Admin)**: Her zaman kiosk modda (güncelleme sırasında geçici gevşeme)
- ❌ **Developer**: Kiosk mode devredışı (tam erişim)

### Güncelleme İzinleri
- Yönetici güncelleme yapabilir
- Kurulum ekranına geçici erişim sağlanır
- APK yükleme izni otomatik istenir
- İşlem sonrası güvenlik tekrar sağlanır

## 📋 Kullanım

### Yönetici Güncelleme Akışı
1. Yönetici şifresi ile giriş yap
2. "Güncelle" butonuna bas
3. Versiyonu seç ve "İndir" butonuna tıkla
4. Kiosk mode otomatik gevşer
5. APK indirilir ve kurulum ekranı açılır
6. Kurulumu tamamla
7. Uygulama yeniden başlar (kiosk mode aktif)

### Hata Durumunda
- İndirme hatası → Kiosk mode otomatik geri gelir
- İptal → Kiosk mode otomatik geri gelir
- Ağ hatası → Kiosk mode otomatik geri gelir

## ⚠️ Önemli Notlar

- Başarılı güncelleme sonrası uygulama kapanır ve yeniden açılır
- Developer kullanıcıları hariç tüm roller kiosk modda çalışır
- Güncelleme sırasında geçici gevşeme sadece yönetici için geçerlidir
- Operatör güncelleme yapamaz (butonu görmez)

## 🎯 İyileştirmeler

- Güvenli güncelleme ortamı
- Otomatik izin yönetimi
- Akıllı hata yönetimi
- Kullanıcı deneyimi iyileştirmesi

---

**Yayın Tarihi**: 10 Şubat 2026
**Build Number**: 14
**Min Android**: 21 (5.0 Lollipop)
**Target Android**: 34 (14.0)
