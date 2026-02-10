# Release Notes - v2.0.14

## Yayın Tarihi
[Tarih otomatik eklenecek]

## Yeni Özellikler

### Yönetici Downgrade Engeli
- **Yönetici Koruması**: Yönetici kullanıcılar artık sadece yeni versiyonlara yükseltme yapabilir
- **Developer Esnekliği**: Developer kullanıcılar istediği herhangi bir versiyona geçebilir (upgrade/downgrade)
- **Görsel Geri Bildirim**: Eski versiyonlar için "Engelli" ikonu ve tooltip mesajı gösterilir

### Kiosk Mode İyileştirmeleri
- **Otomatik Yeniden Aktifleştirme**: Güncelleme ekranından çıkıldığında kiosk mode otomatik olarak tekrar aktif olur
- **İptal Koruması**: Güncelleme iptal edildiğinde de kiosk mode güvence altında
- **Ekran Döngüsü Güvenliği**: Güncelleme ekranına girip çıkıldığında kiosk mode durumu korunur

## Güvenlik İyileştirmeleri
- Rol bazlı erişim kontrolü güçlendirildi
- Yönetici yetkilerinde kısıtlamalar uygulandı
- Sistem bütünlüğü koruması artırıldı

## Teknik Detaylar
- Version: 2.0.14
- Build Number: 16
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)

## Önceki Versiyondan Farklar
**v2.0.13 → v2.0.14:**
- ✨ Yönetici için downgrade engellendi
- ✨ Güncelleme ekranı kiosk mode entegrasyonu tamamlandı
- 🔒 Rol bazlı versiyon kontrol sistemi eklendi
- 🎯 Kullanıcı deneyimi iyileştirmeleri

## Yükseltme Notları
- Yönetici kullanıcılar: Sadece v2.0.14 ve üzeri versiyonlara güncelleyebilirsiniz
- Developer kullanıcılar: Tüm versiyonlara erişim devam ediyor
- Otomatik kiosk mode: Güncelleme sonrası tekrar aktif olacak

## Bilinen Sınırlamalar
- Yok

## Destek
Sorun bildirimi için GitHub Issues kullanabilirsiniz.
