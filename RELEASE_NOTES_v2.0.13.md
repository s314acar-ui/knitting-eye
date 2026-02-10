# Release Notes - v2.0.13

## 🔧 Düzeltme

### Kiosk Mode Optimizasyonu
- **Sadece kurulum sırasında gevşetme**: Kiosk mode artık sadece APK kurulum ekranı açılırken geçici devre dışı bırakılıyor
- **İndirme sırasında kilitli**: APK indirme işlemi sırasında kiosk mode aktif kalıyor
- **Daha güvenli**: Güvenlik sadece gerekli olduğu an gevşetiliyor

## 🔄 Önceki Davranış (v2.0.12)
- ❌ Güncelleme başladığında kiosk mode gevşiyordu
- ❌ İndirme sırasında kiosk mode kapalıydı

## ✅ Yeni Davranış (v2.0.13)
- ✅ APK indirme sırasında kiosk mode **aktif**
- ✅ Kurulum ekranı açılırken kiosk mode **geçici gevşer**
- ✅ Kurulum hatası durumunda kiosk mode **otomatik geri gelir**
- ✅ Başarılı kurulumda uygulama kapanır (yeniden açılışta kiosk mode aktif)

## 📋 Güncelleme Akışı

1. **Güncelle butonuna bas** → Kiosk mode aktif ✅
2. **Versiyon seç ve İndir** → Kiosk mode aktif ✅
3. **APK indiriliyor...** → Kiosk mode aktif ✅
4. **APK indirildi** → Kiosk mode aktif ✅
5. **Kurulum başlatılıyor** → 🔓 Kiosk mode geçici gevşer
6. **Kurulum ekranı açılır** → Kurulum yapılır
7. **Uygulama yeniden başlar** → 🔒 Kiosk mode otomatik aktif

## ⚠️ Hata Durumları

- **Kurulum hatası** → 🔒 Kiosk mode 0.5 saniye sonra otomatik geri gelir
- **İndirme hatası** → Kiosk mode zaten aktif (değişiklik yok)
- **İptal** → Kiosk mode zaten aktif (değişiklik yok)

## 🎯 İyileştirmeler

- Minimum güvenlik gevşetmesi
- Daha kontrollü güncelleme süreci
- Sadece gerekli anda izin verme
- Hızlı hata kurtarma (500ms)

---

**Yayın Tarihi**: 10 Şubat 2026
**Build Number**: 15
**Min Android**: 21 (5.0 Lollipop)
**Target Android**: 34 (14.0)
