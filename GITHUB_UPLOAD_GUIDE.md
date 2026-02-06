# GitHub'a Yükleme Adımları

Bu uygulamayı GitHub'a yüklemek için aşağıdaki adımları izleyin:

## 1. Git Repository Oluştur

```bash
cd /Users/sa/ocr_scanner_app
git init
git add .
git commit -m "feat: Initial commit - ELiAR OCR Scanner App with kiosk mode"
```

## 2. GitHub'da Yeni Repository Oluştur

1. https://github.com/new adresine gidin
2. Repository adı: **ocr_scanner_app** veya **eliar-ocr-scanner**
3. Description: **ELiAR OCR Scanner - Barkod ve OCR tarama uygulaması (Kiosk modu destekli)**
4. **Public** veya **Private** seçin
5. **"Create repository"** butonuna tıklayın

## 3. Remote Ekle ve Push Et

```bash
# GitHub kullanıcı adınızı değiştirin
git remote add origin https://github.com/KULLANICI_ADINIZ/ocr_scanner_app.git
git branch -M main
git push -u origin main
```

## 4. Release Oluştur (APK Yükle)

### GitHub Web Üzerinden:
1. GitHub repository sayfasında **"Releases"** bölümüne gidin
2. **"Create a new release"** tıklayın
3. Tag version: **v1.0.0**
4. Release title: **ELiAR OCR Scanner v1.0.0**
5. Description:
```markdown
## 🎉 İlk Yayın - v1.0.0

### ✨ Özellikler
- ✅ Barkod tarama (Google ML Kit)
- ✅ OCR (Metin tanıma)
- ✅ WebView ana sayfa
- ✅ HTTP desteği (yerel sunucu)
- ✅ Kiosk modu (Developer özelliği)
- ✅ Rol tabanlı kullanıcı yönetimi
- ✅ Karanlık tema

### 📥 Kurulum
**ELiAR_OCR_Scanner.apk** dosyasını indirip Android cihazınıza yükleyin.

### 🔐 Developer Erişimi
Kiosk moduna erişmek için:
- Şifre: `el1984`

### 📋 Gereksinimler
- Android 5.0+
- Kamera izni
- 200 MB depolama

### 🐛 Bilinen Sorunlar
- Release build ProGuard hatası nedeniyle debug APK yayınlandı
```
6. **"Attach binaries"** bölümüne **ELiAR_OCR_Scanner.apk** dosyasını sürükleyin
7. **"Publish release"** butonuna tıklayın

### Veya Komut Satırından (GitHub CLI):
```bash
# GitHub CLI kurulu değilse: brew install gh
gh release create v1.0.0 \
  ELiAR_OCR_Scanner.apk \
  --title "ELiAR OCR Scanner v1.0.0" \
  --notes "İlk yayın: Barkod tarama, OCR, Kiosk modu"
```

## 5. README'yi Güncelle

```bash
# README_GITHUB.md'yi README.md olarak kopyala
mv README_GITHUB.md README.md

# Kullanıcı adınızı güncelleyin
# README.md içindeki KULLANICI_ADINIZ yerlerini değiştirin

git add README.md
git commit -m "docs: Update README with installation and usage info"
git push
```

## 6. Topics Ekle (GitHub Web)

Repository ayarlarından şu topics'leri ekleyin:
- `flutter`
- `android`
- `ocr`
- `barcode-scanner`
- `kiosk-mode`
- `ml-kit`
- `webview`
- `dart`

## ✅ Tamamlandı!

Artık uygulamanız GitHub'da! 🎉

**Repository URL**: https://github.com/KULLANICI_ADINIZ/ocr_scanner_app  
**APK Download**: https://github.com/KULLANICI_ADINIZ/ocr_scanner_app/releases/latest

## 🔄 Gelecekteki Güncellemeler

Yeni versiyon yayınlamak için:

```bash
# Değişiklikleri commit et
git add .
git commit -m "feat: Add new feature"
git push

# Yeni release oluştur
git tag v1.0.1
git push origin v1.0.1

# APK'yı yeniden build et ve release'e ekle
flutter build apk --debug
cp build/app/outputs/flutter-apk/app-debug.apk ./ELiAR_OCR_Scanner_v1.0.1.apk
# GitHub Releases'den yeni release oluştur ve APK'yı ekle
```

## 📝 Önemli Notlar

1. **`.gitignore`**: Build klasörü ve APK dosyaları git'e eklenmez
2. **APK Boyutu**: ~188 MB (debug build)
3. **Developer Şifresi**: `el1984` - README'de gösterilmez, sadece gerektiğinde söyleyebilirsiniz
4. **License**: MIT lisansı eklemek isterseniz LICENSE dosyası oluşturun
