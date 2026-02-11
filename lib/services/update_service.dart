import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class UpdateService {
  static const String _githubApiUrl = 
      'https://api.github.com/repos/s314acar-ui/knitting-eye/releases/latest';
  static const String _githubAllReleasesUrl = 
      'https://api.github.com/repos/s314acar-ui/knitting-eye/releases';
  
  // GitHub Personal Access Token - dart-define veya .env dosyasından okunur
  static const String _githubToken = String.fromEnvironment('GITHUB_TOKEN', defaultValue: '');
  
  static const String _currentVersion = '2.0.23'; // pubspec.yaml'daki versiyon
  static const int _currentBuildNumber = 25;

  /// GitHub API headers (token varsa auth ekle)
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
    };
    if (_githubToken.isNotEmpty) {
      headers['Authorization'] = 'token $_githubToken';
    }
    return headers;
  }

  /// GitHub'dan son sürüm bilgisini kontrol et
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      debugPrint('🔍 Checking for updates...');
      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 checkForUpdates - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final latestVersion = data['tag_name']?.toString().replaceAll('v', '') ?? '';
        final releaseUrl = data['html_url'] ?? '';
        final releaseNotes = data['body'] ?? '';
        
        debugPrint('📦 Latest version from API: v$latestVersion');
        
        // APK dosyasını bul
        String? apkDownloadUrl;
        if (data['assets'] != null && (data['assets'] as List).isNotEmpty) {
          for (var asset in data['assets']) {
            if (asset['name'].toString().endsWith('.apk')) {
              apkDownloadUrl = asset['browser_download_url'];
              debugPrint('✓ APK found: ${asset['name']}');
              break;
            }
          }
        }

        // Versiyon karşılaştırması
        if (_isNewerVersion(latestVersion, _currentVersion)) {
          debugPrint('✅ New version available: v$latestVersion');
          return UpdateInfo(
            version: latestVersion,
            downloadUrl: apkDownloadUrl ?? '',
            releaseUrl: releaseUrl,
            releaseNotes: releaseNotes,
            apkSize: data['assets']?[0]?['size'] ?? 0,
          );
        } else {
          debugPrint('ℹ️ App is up to date (current: v$_currentVersion)');
        }
      } else {
        debugPrint('❌ API Error: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Update check error: $e');
      return null;
    }
  }

  /// Tüm release'leri getir
  Future<List<UpdateInfo>> getAllReleases() async {
    try {
      final response = await http.get(
        Uri.parse(_githubAllReleasesUrl),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 getAllReleases - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> releases = json.decode(response.body);
        debugPrint('📦 Found ${releases.length} releases in API response');
        final List<UpdateInfo> allReleases = [];

        for (var data in releases) {
          final version = data['tag_name']?.toString().replaceAll('v', '') ?? '';
          final releaseUrl = data['html_url'] ?? '';
          final releaseNotes = data['body'] ?? '';
          final publishedAt = data['published_at'] ?? '';
          
          // APK dosyasını bul
          String? apkDownloadUrl;
          int apkSize = 0;
          if (data['assets'] != null && (data['assets'] as List).isNotEmpty) {
            for (var asset in data['assets']) {
              if (asset['name'].toString().endsWith('.apk')) {
                apkDownloadUrl = asset['browser_download_url'];
                apkSize = asset['size'] ?? 0;
                debugPrint('  ✓ v$version - APK found: ${asset['name']}');
                break;
              }
            }
          }

          if (version.isNotEmpty) {
            if (apkDownloadUrl != null) {
              allReleases.add(UpdateInfo(
                version: version,
                downloadUrl: apkDownloadUrl,
                releaseUrl: releaseUrl,
                releaseNotes: releaseNotes,
                apkSize: apkSize,
                publishedAt: publishedAt,
                isCurrent: version == _currentVersion,
              ));
            } else {
              debugPrint('  ⚠️ v$version - No APK found, skipping');
            }
          }
        }

        debugPrint('✅ Returning ${allReleases.length} releases with APK');
        return allReleases;
      } else {
        debugPrint('❌ API Error: ${response.statusCode} - ${response.body}');
      }
      return [];
    } catch (e) {
      debugPrint('❌ Get all releases error: $e');
      return [];
    }
  }

  /// Versiyon karşılaştırması (semantic versioning)
  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();
      
      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// APK dosyasını indir
  Future<File?> downloadApk(
    String url,
    void Function(double progress) onProgress,
  ) async {
    try {
      debugPrint('📥 Starting APK download from: $url');
      
      // İzin kontrolü yapmıyoruz - Android, APK açılınca kendisi izin isteyecek
      debugPrint('✅ Starting HTTP request (permission will be asked on install)...');
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      debugPrint('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        debugPrint('📦 Content length: ${(contentLength / 1024 / 1024).toStringAsFixed(2)} MB');
        int downloadedBytes = 0;

        // App-specific external storage kullan (izin gerektirmez Android 10+)
        final dir = await getExternalStorageDirectory();
        final file = File('${dir!.path}/knitting_eye_update.apk');
        debugPrint('💾 Saving to: ${file.path}');

        // Eski dosya varsa sil
        if (await file.exists()) {
          await file.delete();
          debugPrint('🗑️ Old APK deleted');
        }

        final sink = file.openWrite();
        
        await for (var chunk in response.stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          
          if (contentLength > 0) {
            final progress = downloadedBytes / contentLength;
            onProgress(progress);
          }
        }

        await sink.close();
        client.close();

        final fileSize = await file.length();
        debugPrint('✅ Download complete! File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        
        // APK'yı Downloads klasörüne de kopyala (kullanıcı manuel yükleyebilsin)
        try {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            final fileName = url.split('/').last;
            final publicFile = File('${downloadsDir.path}/$fileName');
            await file.copy(publicFile.path);
            debugPrint('📁 APK copied to Downloads: ${publicFile.path}');
          }
        } catch (e) {
          debugPrint('⚠️ Could not copy to Downloads: $e');
        }
        
        return file;
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        debugPrint('Response: ${await response.stream.bytesToString()}');
      }
      
      client.close();
      return null;
    } catch (e) {
      debugPrint('❌ Download error: $e');
      return null;
    }
  }

  /// APK kurulumunu başlat (Native Android Intent kullanarak)
  Future<String> installApk(File apkFile) async {
    try {
      debugPrint('📲 Installing APK via native channel: ${apkFile.path}');
      const channel = MethodChannel('com.example.ocr_scanner_app/install');
      final result = await channel.invokeMethod('installApk', {
        'filePath': apkFile.path,
      });
      debugPrint('📲 Install result: $result');
      return result?.toString() ?? 'UNKNOWN';
    } catch (e) {
      debugPrint('❌ Install error: $e');
      return 'ERROR: $e';
    }
  }

  /// Paket yükleme izni var mı kontrol et
  Future<bool> canInstallPackages() async {
    try {
      const channel = MethodChannel('com.example.ocr_scanner_app/install');
      final result = await channel.invokeMethod('canInstallPackages');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Paket yükleme iznini iste (ayarlara yönlendir)
  Future<String> requestInstallPermission() async {
    try {
      const channel = MethodChannel('com.example.ocr_scanner_app/install');
      final result = await channel.invokeMethod('requestInstallPermission');
      return result?.toString() ?? 'UNKNOWN';
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
      return 'ERROR: $e';
    }
  }

  String get currentVersion => _currentVersion;
  int get currentBuildNumber => _currentBuildNumber;
}

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseUrl;
  final String releaseNotes;
  final int apkSize;
  final String publishedAt;
  final bool isCurrent;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseUrl,
    required this.releaseNotes,
    required this.apkSize,
    this.publishedAt = '',
    this.isCurrent = false,
  });

  String get formattedSize {
    if (apkSize < 1024) return '$apkSize B';
    if (apkSize < 1024 * 1024) return '${(apkSize / 1024).toStringAsFixed(1)} KB';
    return '${(apkSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    if (publishedAt.isEmpty) return '';
    try {
      final date = DateTime.parse(publishedAt);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return '';
    }
  }

  bool isNewerThan(String currentVersion) {
    try {
      final thisParts = version.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      
      for (int i = 0; i < 3; i++) {
        if (thisParts[i] > currentParts[i]) return true;
        if (thisParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
