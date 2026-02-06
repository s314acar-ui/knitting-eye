import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  static const String _githubApiUrl = 
      'https://api.github.com/repos/s314acar-ui/knitting-eye/releases/latest';
  static const String _githubAllReleasesUrl = 
      'https://api.github.com/repos/s314acar-ui/knitting-eye/releases';
  
  static const String _currentVersion = '2.0.2'; // pubspec.yaml'daki versiyon
  static const int _currentBuildNumber = 4;

  /// GitHub'dan son sürüm bilgisini kontrol et
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final latestVersion = data['tag_name']?.toString().replaceAll('v', '') ?? '';
        final releaseUrl = data['html_url'] ?? '';
        final releaseNotes = data['body'] ?? '';
        
        // APK dosyasını bul
        String? apkDownloadUrl;
        if (data['assets'] != null && (data['assets'] as List).isNotEmpty) {
          for (var asset in data['assets']) {
            if (asset['name'].toString().endsWith('.apk')) {
              apkDownloadUrl = asset['browser_download_url'];
              break;
            }
          }
        }

        // Versiyon karşılaştırması
        if (_isNewerVersion(latestVersion, _currentVersion)) {
          return UpdateInfo(
            version: latestVersion,
            downloadUrl: apkDownloadUrl ?? '',
            releaseUrl: releaseUrl,
            releaseNotes: releaseNotes,
            apkSize: data['assets']?[0]?['size'] ?? 0,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Update check error: $e');
      return null;
    }
  }

  /// Tüm release'leri getir
  Future<List<UpdateInfo>> getAllReleases() async {
    try {
      final response = await http.get(
        Uri.parse(_githubAllReleasesUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> releases = json.decode(response.body);
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
                break;
              }
            }
          }

          if (version.isNotEmpty && apkDownloadUrl != null) {
            allReleases.add(UpdateInfo(
              version: version,
              downloadUrl: apkDownloadUrl,
              releaseUrl: releaseUrl,
              releaseNotes: releaseNotes,
              apkSize: apkSize,
              publishedAt: publishedAt,
              isCurrent: version == _currentVersion,
            ));
          }
        }

        return allReleases;
      }
      return [];
    } catch (e) {
      debugPrint('Get all releases error: $e');
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
      // Storage izni kontrolü
      if (await Permission.storage.isDenied) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          return null;
        }
      }

      // Install packages izni (Android 8+)
      if (await Permission.requestInstallPackages.isDenied) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          return null;
        }
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        int downloadedBytes = 0;

        // Download klasörüne kaydet
        final dir = await getExternalStorageDirectory();
        final file = File('${dir!.path}/knitting_eye_update.apk');

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

        return file;
      }
      
      client.close();
      return null;
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  /// APK kurulumunu başlat (Android Intent kullanarak)
  Future<bool> installApk(File apkFile) async {
    try {
      // Android'de APK kurulumu için native kod gerekiyor
      // Şimdilik dosya yolunu döndürelim
      debugPrint('APK ready to install: ${apkFile.path}');
      
      // Kullanıcıya dosya yöneticisi veya install ekranı gösterilecek
      return true;
    } catch (e) {
      debugPrint('Install error: $e');
      return false;
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
