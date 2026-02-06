# ✨ Knitting Eye v2.0.2 - Versiyon Yönetimi

**Yayın Tarihi**: 6 Şubat 2026

## ✨ Yeni Özellikler

- ✨ **Tüm Versiyonlar Görüntüleme**: Güncelleme ekranında tüm yayınlanmış versiyonlar listeleniyor
- 📥 **İstediğin Versiyonu Yükle**: Yeni veya eski herhangi bir versiyonu indirebilirsiniz
- 🏷️ **Versiyon Etiketleri**: 
  - **KURULU**: Şu anda yüklü olan versiyon
  - **YENİ**: Daha yeni versiyonlar
- 📅 **Yayın Tarihi**: Her versiyonun yayınlanma tarihi gösteriliyor
- 📦 **APK Boyutu**: Her versiyonun boyutu görüntüleniyor
- 📝 **Genişletilebilir Notlar**: Release notları genişletilip okunabilir
- 🎨 **Renkli Arayüz**: 
  - Yeşil: Kurulu versiyon
  - Mavi: Yeni versiyonlar
  - Gri: Eski versiyonlar

## 🐛 Düzeltmeler (v2.0.1'den kalan)

- 🐛 Barkod kamera başlatma sorunu düzeltilmiş durumda
- 🔧 Tekrar dene butonu çalışıyor

## 🚀 Kullanım

### Güncelleme Ekranı

1. **Yönetici** veya **Developer** olarak giriş yapın
2. **"Güncelle"** butonuna tıklayın
3. **Tüm versiyonları görün**:
   - En üstte yeni sürüm uyarısı (varsa)
   - Altında tüm versiyonların listesi
   - Her versiyon için:
     - Versiyon numarası (v2.0.2, v2.0.1, v2.0.0)
     - Etiket (KURULU / YENİ)
     - Yayın tarihi
     - APK boyutu
     - İndir butonu
     - Yenilikler (genişletilebilir)

### Versiyon İndirme

1. İstediğiniz versiyonun **"İndir"** butonuna tıklayın
2. APK indirilecek (progress bar gösterilir)
3. İndirme tamamlanınca kurulum ekranı açılır
4. **Yükle** → Seçtiğiniz versiyon kurulur

### Eski Versiyona Geçiş

- Yeni bir versiyon sorunluysa
- **Güncelle** ekranına gidin
- Eski bir versiyonu bulun
- **İndir** → Eski versiyona geri dönün

## 📋 Önceki Özelliklere Ek

Tüm önceki özelliklere ek olarak:
- ✅ Dual OCR Sistemi (v2.0.0)
- ✅ Barkod Kamera Düzeltmesi (v2.0.1)
- ✅ Otomatik Güncelleme Sistemi (v2.0.0)
- ✅ Kiosk Modu
- ✅ In-App Kamera (Flip, Zoom, Focus)

## 🛠️ Teknik Detaylar

- **Version**: 2.0.2+4
- **Build Type**: Debug APK
- **APK Boyutu**: ~188 MB
- **Yeni API**: `/repos/s314acar-ui/knitting-eye/releases` (tüm versiyonlar)
- **Değişiklikler**:
  - `lib/services/update_service.dart`: `getAllReleases()` metodu eklendi
  - `lib/screens/update_screen.dart`: Tüm versiyonlar görünümü
  - `UpdateInfo` sınıfı: `publishedAt`, `isCurrent`, `isNewerThan()` eklendi

## 🔄 Güncelleme Yolu

- **v2.0.0 → v2.0.2**: Direkt güncellenebilir
- **v2.0.1 → v2.0.2**: Direkt güncellenebilir
- **v2.0.2 → v2.0.1**: Eski versiyona geçiş yapılabilir (downgrade)

## 📝 Notlar

- Tüm versiyonlar GitHub Releases'den çekiliyor
- İnternet bağlantısı gerekli
- Private repository olduğu için sadece yetkili kullanıcılar güncelleyebilir
- APK boyutları değişiklik gösterebilir (build tipine göre)

---

**Önceki Versiyon**: v2.0.1  
**Bir Sonraki Planlanan**: v2.0.3 (performans iyileştirmeleri)
