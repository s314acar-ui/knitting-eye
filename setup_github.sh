#!/bin/bash

# Knitting Eye - GitHub Kurulum Scripti
# Bu script uygulamayı GitHub'a yükler ve ilk release'i oluşturur

echo "🚀 Knitting Eye GitHub Kurulumu Başlıyor..."
echo ""

# 1. Git Repository Kontrolü
if [ -d ".git" ]; then
    echo "⚠️  Git repository zaten mevcut. Devam etmek istediğinize emin misiniz? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "❌ İşlem iptal edildi."
        exit 1
    fi
else
    echo "📁 Git repository oluşturuluyor..."
    git init
fi

# 2. README'yi güncelle
echo ""
echo "📝 README güncelleniyor..."
if [ -f "README_RELEASE.md" ]; then
    cp README_RELEASE.md README.md
    echo "✅ README.md güncellendi"
else
    echo "⚠️  README_RELEASE.md bulunamadı, README.md değiştirilmedi"
fi

# 3. Git kullanıcı bilgilerini kontrol et
echo ""
echo "👤 Git kullanıcı bilgileri kontrol ediliyor..."
GIT_NAME=$(git config user.name)
GIT_EMAIL=$(git config user.email)

if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
    echo "⚠️  Git kullanıcı bilgileri eksik!"
    echo "Aşağıdaki komutları çalıştırın:"
    echo "  git config --global user.name 'Adınız Soyadınız'"
    echo "  git config --global user.email 'email@example.com'"
    exit 1
else
    echo "✅ Git kullanıcı: $GIT_NAME <$GIT_EMAIL>"
fi

# 4. Dosyaları stage'e ekle
echo ""
echo "📦 Dosyalar stage'e ekleniyor..."
git add .

# 5. İlk commit
echo ""
echo "💾 İlk commit oluşturuluyor..."
git commit -m "feat: Initial release - Knitting Eye v2.0.0

✨ Özellikler:
- Dual OCR sistemi (basit/detaylı)
- In-app kamera kontrolü (flip, zoom, focus)
- Barkod tarama (Google ML Kit)
- WebView ana sayfa
- Rol tabanlı erişim (Operatör/Yönetici/Developer)
- Kiosk modu (Developer)
- Otomatik güncelleme sistemi
- ELiAR kurumsal kimlik entegrasyonu

🎨 Tasarım:
- Karanlık tema (gri tonları)
- Basitleştirilmiş operatör arayüzü
- Büyük, kolay kullanımlı butonlar

🔐 Güvenlik:
- Ekran görüntüsü engelleme
- Şifre korumalı modlar
- HTTP/HTTPS desteği"

echo "✅ Commit oluşturuldu"

# 6. Ana branch'i main olarak ayarla
echo ""
echo "🌿 Ana branch 'main' olarak ayarlanıyor..."
git branch -M main

# 7. Remote ekle
echo ""
echo "🔗 GitHub remote ekleniyor..."
REPO_URL="https://github.com/s314acar-ui/knitting-eye.git"

# Eğer remote zaten varsa kaldır
git remote remove origin 2>/dev/null

git remote add origin "$REPO_URL"
echo "✅ Remote eklendi: $REPO_URL"

# 8. Push
echo ""
echo "⬆️  GitHub'a push ediliyor..."
echo "⚠️  GitHub kullanıcı adı ve personal access token isteyecek!"
echo ""
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Kod başarıyla GitHub'a yüklendi!"
else
    echo ""
    echo "❌ Push başarısız! Manuel olarak kontrol edin:"
    echo "   git push -u origin main"
    exit 1
fi

# 9. Tag oluştur
echo ""
echo "🏷️  Versiyon tag'i oluşturuluyor..."
git tag -a v2.0.0 -m "Release v2.0.0

🎉 İlk Yayın - Knitting Eye v2.0.0

✨ Özellikler:
- Dual OCR sistemi
- In-app kamera kontrolü
- Otomatik güncelleme sistemi
- ELiAR kurumsal kimlik
- Kiosk modu

📥 Kurulum:
APK dosyasını indirip Android cihazınıza yükleyin.

🔐 Developer Erişimi:
Şifre: el1984

📋 Gereksinimler:
- Android 5.0+
- Kamera izni
- 200 MB depolama"

git push origin v2.0.0

if [ $? -eq 0 ]; then
    echo "✅ Tag başarıyla oluşturuldu!"
else
    echo "⚠️  Tag push edilemedi, manuel olarak push edin:"
    echo "   git push origin v2.0.0"
fi

# 10. APK kopyala
echo ""
echo "📱 APK dosyası hazırlanıyor..."
APK_SOURCE="build/app/outputs/flutter-apk/app-debug.apk"
APK_DEST="Knitting_Eye_v2.0.0.apk"

if [ -f "$APK_SOURCE" ]; then
    cp "$APK_SOURCE" "$APK_DEST"
    echo "✅ APK kopyalandı: $APK_DEST"
    
    # APK boyutunu göster
    APK_SIZE=$(ls -lh "$APK_DEST" | awk '{print $5}')
    echo "📦 APK Boyutu: $APK_SIZE"
else
    echo "⚠️  APK bulunamadı: $APK_SOURCE"
    echo "   flutter build apk --debug komutunu çalıştırın"
fi

# Tamamlandı
echo ""
echo "=========================================="
echo "✅ KURULUM TAMAMLANDI!"
echo "=========================================="
echo ""
echo "📍 Repository URL:"
echo "   https://github.com/s314acar-ui/knitting-eye"
echo ""
echo "📱 APK Dosyası:"
echo "   $APK_DEST"
echo ""
echo "🎯 Sıradaki Adımlar:"
echo ""
echo "1. GitHub web sayfasına gidin:"
echo "   https://github.com/s314acar-ui/knitting-eye/releases/new"
echo ""
echo "2. Release oluşturun:"
echo "   - Tag: v2.0.0"
echo "   - Title: Knitting Eye v2.0.0"
echo "   - Description: Release notlarını kopyalayın"
echo "   - APK: $APK_DEST dosyasını yükleyin"
echo ""
echo "3. 'Publish release' butonuna tıklayın"
echo ""
echo "🔄 Otomatik güncelleme sistemi çalışacak!"
echo ""
