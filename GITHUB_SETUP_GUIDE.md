# 🚀 GitHub Kurulum ve Release Oluşturma Rehberi

Bu rehber Knitting Eye uygulamasını GitHub'a yüklemek ve ilk release'i oluşturmak için adım adım talimatlar içerir.

## 📋 Ön Hazırlık

### 1. GitHub Personal Access Token Oluşturun

Private repository için push yapabilmek için Personal Access Token gerekir:

1. GitHub'da sağ üst köşedeki profil fotoğrafınıza tıklayın
2. **Settings** > **Developer settings** > **Personal access tokens** > **Tokens (classic)**
3. **Generate new token** > **Generate new token (classic)**
4. Token adı: `knitting-eye-token`
5. Gerekli izinler:
   - ✅ `repo` (tüm alt seçenekler)
   - ✅ `workflow`
6. **Generate token** butonuna tıklayın
7. ⚠️ **Token'ı kopyalayın ve güvenli bir yere kaydedin!** (Bir daha göremezsiniz)

### 2. Git Yapılandırması

Terminal'de şu komutları çalıştırın:

```bash
# Git kullanıcı bilgilerinizi ayarlayın (henüz ayarlamadıysanız)
git config --global user.name "s314acar-ui"
git config --global user.email "your-email@example.com"

# Ayarları kontrol edin
git config --global user.name
git config --global user.email
```

## 🎯 Otomatik Kurulum (Önerilen)

Terminal'de proje klasörüne gidin ve setup scriptini çalıştırın:

```bash
cd /Users/sa/ocr_scanner_app
./setup_github.sh
```

Script şunları yapacak:
1. ✅ Git repository oluştur (veya mevcut olanı kullan)
2. ✅ README'yi güncelle
3. ✅ Dosyaları commit et
4. ✅ GitHub remote ekle
5. ✅ Push yap
6. ✅ v2.0.0 tag'i oluştur
7. ✅ APK'yı kopyala (`Knitting_Eye_v2.0.0.apk`)

Push işlemi sırasında:
- **Username**: `s314acar-ui`
- **Password**: *Oluşturduğunuz Personal Access Token'ı yapıştırın*

## 📱 Manuel Kurulum (Alternatif)

Otomatik script çalışmazsa manuel olarak yapın:

### Adım 1: Git Repository Oluştur

```bash
cd /Users/sa/ocr_scanner_app

# Git repository başlat
git init

# README'yi güncelle
cp README_RELEASE.md README.md

# Dosyaları ekle
git add .

# İlk commit
git commit -m "feat: Initial release - Knitting Eye v2.0.0"

# Ana branch'i main yap
git branch -M main
```

### Adım 2: GitHub Repository Oluştur

1. https://github.com/new adresine gidin
2. Repository bilgileri:
   - **Owner**: s314acar-ui
   - **Repository name**: `knitting-eye`
   - **Description**: `Knitting Eye - Endüstriyel Okuma Sistemi (OCR, Barkod Tarama, Kiosk Modu)`
   - **Visibility**: ⚫ **Private** (seçili olmalı)
   - ❌ **Initialize this repository with a README** (işaretlemeyin)
3. **Create repository** butonuna tıklayın

### Adım 3: Push Yapın

```bash
# Remote ekle
git remote add origin https://github.com/s314acar-ui/knitting-eye.git

# Push yap
git push -u origin main
```

Kullanıcı adı ve şifre isteyecek:
- **Username**: `s314acar-ui`
- **Password**: *Personal Access Token'ınızı yapıştırın*

### Adım 4: Tag Oluştur

```bash
# Version tag oluştur
git tag -a v2.0.0 -m "Release v2.0.0 - Knitting Eye İlk Yayın"

# Tag'i push et
git push origin v2.0.0
```

### Adım 5: APK'yı Hazırla

```bash
# APK'yı kopyala
cp build/app/outputs/flutter-apk/app-debug.apk Knitting_Eye_v2.0.0.apk

# APK boyutunu kontrol et
ls -lh Knitting_Eye_v2.0.0.apk
```

## 🎉 GitHub Release Oluşturma

### Web Arayüzü ile (Önerilen)

1. **Repository sayfasına gidin**:
   https://github.com/s314acar-ui/knitting-eye

2. **Releases** bölümüne tıklayın (sağ tarafta)

3. **Create a new release** veya **Draft a new release** butonuna tıklayın

4. **Release bilgilerini doldurun**:

   **Choose a tag**: `v2.0.0` (listeden seçin veya yazın)

   **Release title**: 
   ```
   Knitting Eye v2.0.0 - İlk Yayın 🎉
   ```

   **Description**: 
   `RELEASE_NOTES_v2.0.0.md` dosyasının içeriğini kopyalayıp yapıştırın.
   
   Veya kısa versiyon:
   ```markdown
   # 🎉 Knitting Eye v2.0.0 - İlk Yayın

   **Yayın Tarihi**: 6 Şubat 2026

   ## ✨ Özellikler

   - ✅ Dual OCR Sistemi (Basit/Detaylı)
   - ✅ In-App Kamera Kontrolü (Flip, Zoom, Focus)
   - ✅ Barkod Tarama (Google ML Kit)
   - ✅ Otomatik Güncelleme Sistemi
   - ✅ Kiosk Modu (Developer)
   - ✅ ELiAR Kurumsal Kimlik
   - ✅ Rol Tabanlı Erişim

   ## 📥 Kurulum

   1. **Knitting_Eye_v2.0.0.apk** dosyasını indirin
   2. "Bilinmeyen kaynaklardan yükleme" iznini verin
   3. APK'yı yükleyin

   ## 🚀 Kullanım

   ### Operatör (Varsayılan)
   - Ana sayfa, Barkod, İş Emri

   ### Yönetici
   - Logo > Yönetici şifresi
   - Config + Güncelleme

   ### Developer
   - Logo > `el1984` şifresi
   - Tüm özellikler + Kiosk + Ayarlar

   ## 🔄 Güncelleme

   Uygulama içinden **Güncelle** butonuna tıklayın!

   ## 📋 Gereksinimler

   - Android 5.0+
   - 200 MB depolama
   - Kamera izni

   ---

   **Not**: Developer şifresi: `el1984`
   ```

5. **APK Dosyasını Ekleyin**:
   - Sayfanın alt kısmında **"Attach binaries by dropping them here or selecting them"** yazısını görün
   - `Knitting_Eye_v2.0.0.apk` dosyasını sürükleyin veya seçin
   - Yükleme tamamlanana kadar bekleyin (~188 MB)

6. **Release Ayarları**:
   - ☑️ **Set as the latest release** (işaretli olmalı)
   - ⚠️ **This is a pre-release** (işaretlemeyin)

7. **Publish release** butonuna tıklayın

### GitHub CLI ile (Alternatif)

```bash
# GitHub CLI kurulu değilse (macOS)
brew install gh

# GitHub'a login olun
gh auth login

# Release oluştur
gh release create v2.0.0 \
  Knitting_Eye_v2.0.0.apk \
  --title "Knitting Eye v2.0.0 - İlk Yayın 🎉" \
  --notes-file RELEASE_NOTES_v2.0.0.md \
  --repo s314acar-ui/knitting-eye
```

## ✅ Doğrulama

Release başarılı olduktan sonra kontrol edin:

1. **Release Sayfası**:
   https://github.com/s314acar-ui/knitting-eye/releases

2. **APK İndirme Linki**:
   ```
   https://github.com/s314acar-ui/knitting-eye/releases/download/v2.0.0/Knitting_Eye_v2.0.0.apk
   ```

3. **Otomatik Güncelleme API**:
   ```
   https://api.github.com/repos/s314acar-ui/knitting-eye/releases/latest
   ```

## 🔄 Gelecekteki Güncellemeler

Yeni versiyon yayınlamak için:

### 1. Versiyon Numarasını Güncelleyin

```yaml
# pubspec.yaml
version: 2.0.1+3  # 2.0.1 versiyon, 3 build number
```

```dart
// lib/services/update_service.dart
static const String _currentVersion = '2.0.1';
static const int _currentBuildNumber = 3;
```

### 2. Değişiklikleri Commit Edin

```bash
# Değişiklikleri ekle
git add .

# Commit et
git commit -m "feat: Add new feature"

# Push yap
git push
```

### 3. Tag Oluştur ve Push Et

```bash
# Tag oluştur
git tag -a v2.0.1 -m "Release v2.0.1 - Bug fixes and improvements"

# Tag'i push et
git push origin v2.0.1
```

### 4. APK Build Et

```bash
flutter build apk --debug
cp build/app/outputs/flutter-apk/app-debug.apk Knitting_Eye_v2.0.1.apk
```

### 5. GitHub Release Oluştur

- GitHub web arayüzünden veya CLI ile yeni release oluşturun
- APK'yı ekleyin
- Release notlarını yazın

### 6. Otomatik Güncelleme Test Edin

- Eski APK'yı tablete yükleyin
- **Güncelle** butonuna tıklayın
- Yeni versiyon görünmeli ve indirilmelidir

## 🐛 Sorun Giderme

### Push Hatası: Authentication Failed

**Çözüm**: Personal Access Token kullanın
```bash
# Token ile push
git remote set-url origin https://YOUR_TOKEN@github.com/s314acar-ui/knitting-eye.git
git push
```

### Private Repository Erişim Hatası

**Çözüm**: Token'da `repo` izni olduğundan emin olun

### APK Yükleme Hatası

**Çözüm**: GitHub Assets limitini kontrol edin (2 GB max)

### Güncelleme API 404 Hatası

**Çözüm**: 
- Repository private ise, API çağrısında authentication gerekir
- `update_service.dart` içinde token ekleyin:
  ```dart
  headers: {
    'Accept': 'application/vnd.github.v3+json',
    'Authorization': 'token YOUR_GITHUB_TOKEN', // Opsiyonel, private repo için
  },
  ```

## 📝 Önemli Notlar

1. **Private Repository**: Bu repo private olduğu için sadece siz erişebilirsiniz
2. **Personal Access Token**: Token'ı asla paylaşmayın ve git'e commit etmeyin
3. **APK Boyutu**: Debug APK ~188 MB, release APK daha küçük olur
4. **Güncelleme Kontrolü**: Uygulama her açılışta otomatik kontrol etmez, manuel kontrol gerekir
5. **Developer Şifresi**: `el1984` - Güvenli saklayın

## 🎯 Sonraki Adımlar

✅ GitHub repository oluşturuldu  
✅ İlk commit yapıldı  
✅ Tag oluşturuldu  
✅ Release yayınlandı  
✅ APK yüklendi  
✅ Otomatik güncelleme sistemi aktif  

Şimdi tablete APK'yı yükleyin ve test edin! 🚀

---

**Repository**: https://github.com/s314acar-ui/knitting-eye (Private)  
**Releases**: https://github.com/s314acar-ui/knitting-eye/releases
