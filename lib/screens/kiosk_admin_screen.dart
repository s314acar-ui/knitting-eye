import 'package:flutter/material.dart';
import '../services/kiosk_service.dart';

/// Kiosk Modu Yönetim Ekranı
class KioskAdminScreen extends StatefulWidget {
  const KioskAdminScreen({super.key});

  @override
  State<KioskAdminScreen> createState() => _KioskAdminScreenState();
}

class _KioskAdminScreenState extends State<KioskAdminScreen> {
  bool _isKioskModeEnabled = false;
  bool _isFullscreen = false;
  bool _isSystemUIHidden = false;
  bool _isLockTaskMode = false;
  bool _isScreenCaptureBlocked = false;

  @override
  void initState() {
    super.initState();
    _loadKioskStatus();
  }

  void _loadKioskStatus() {
    setState(() {
      _isKioskModeEnabled = kioskService.isKioskMode;
    });
  }

  Future<void> _toggleKioskMode(bool enabled) async {
    if (enabled) {
      // Kiosk modunu aktifleştir
      final success = await kioskService.setKioskMode(true);
      if (success) {
        setState(() {
          _isKioskModeEnabled = true;
          _isFullscreen = true;
          _isSystemUIHidden = true;
          _isLockTaskMode = true;
          _isScreenCaptureBlocked = true;
        });
        _showSnackBar('✅ Kiosk Modu Aktif', Colors.green);
      } else {
        _showSnackBar('❌ Kiosk Modu Etkinleştirilemedi', Colors.red);
      }
    } else {
      // Kiosk modundan çık - sayfa kapanmasın
      final success = await kioskService.exitKioskMode('el1984');
      if (success) {
        setState(() {
          _isKioskModeEnabled = false;
          _isFullscreen = false;
          _isSystemUIHidden = false;
          _isLockTaskMode = false;
          _isScreenCaptureBlocked = false;
        });
        _showSnackBar('✅ Kiosk Modu Kapatıldı', Colors.orange);
      } else {
        _showSnackBar('❌ Kiosk Modu Kapatılamadı', Colors.red);
      }
    }
  }

  Future<void> _toggleFullscreen(bool enabled) async {
    await kioskService.setFullscreen(enabled);
    setState(() => _isFullscreen = enabled);
    _showSnackBar(
      enabled ? '✅ Tam Ekran Modu Açık' : '❌ Tam Ekran Modu Kapalı',
      enabled ? Colors.green : Colors.orange,
    );
  }

  Future<void> _toggleSystemUI(bool hide) async {
    await kioskService.hideSystemUI(hide);
    setState(() => _isSystemUIHidden = hide);
    _showSnackBar(
      hide ? '✅ Sistem UI Gizlendi' : '✅ Sistem UI Gösteriliyor',
      hide ? Colors.green : Colors.orange,
    );
  }

  Future<void> _toggleLockTask(bool enabled) async {
    final success = await kioskService.lockTaskMode(enabled);
    if (success) {
      setState(() => _isLockTaskMode = enabled);
      _showSnackBar(
        enabled ? '✅ Lock Task Modu Aktif' : '❌ Lock Task Modu Kapalı',
        enabled ? Colors.green : Colors.orange,
      );
    } else {
      _showSnackBar('❌ Lock Task Modu Ayarlanamadı', Colors.red);
    }
  }

  Future<void> _toggleScreenCapture(bool prevent) async {
    await kioskService.preventScreenCapture(prevent);
    setState(() => _isScreenCaptureBlocked = prevent);
    _showSnackBar(
      prevent ? '✅ Ekran Yakalama Engellendi' : '❌ Ekran Yakalama İzinli',
      prevent ? Colors.green : Colors.orange,
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiosk Modu Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ana Kiosk Modu Switch
            _buildMainKioskCard(),
            const SizedBox(height: 24),

            // Detaylı Ayarlar
            if (_isKioskModeEnabled) ...[
              const Text(
                'Kiosk Modu Özellikleri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                title: 'Tam Ekran Modu',
                subtitle: 'Durum çubuğu ve navigasyon çubuğunu gizler',
                icon: Icons.fullscreen,
                value: _isFullscreen,
                onChanged: _toggleFullscreen,
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                title: 'Sistem UI Gizleme',
                subtitle: 'Tüm sistem arayüzünü gizler',
                icon: Icons.visibility_off,
                value: _isSystemUIHidden,
                onChanged: _toggleSystemUI,
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                title: 'Lock Task Modu',
                subtitle: 'Uygulamayı kilitleme',
                icon: Icons.lock,
                value: _isLockTaskMode,
                onChanged: _toggleLockTask,
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                title: 'Ekran Yakalama Koruması',
                subtitle: 'Ekran görüntüsü ve kaydı engellenir',
                icon: Icons.screenshot_monitor,
                value: _isScreenCaptureBlocked,
                onChanged: _toggleScreenCapture,
              ),
            ],

            const SizedBox(height: 24),

            // Bilgi Kartı
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainKioskCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isKioskModeEnabled
              ? [Colors.green[400]!, Colors.green[600]!]
              : [Colors.grey[300]!, Colors.grey[400]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isKioskModeEnabled ? Icons.lock : Icons.lock_open,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isKioskModeEnabled ? 'Kiosk Modu Aktif' : 'Kiosk Modu Kapalı',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isKioskModeEnabled
                      ? 'Uygulama tam kiosk modunda çalışıyor'
                      : 'Kiosk modunu etkinleştirmek için açın',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isKioskModeEnabled,
            onChanged: _toggleKioskMode,
            activeColor: Colors.white,
            activeTrackColor: Colors.green[800],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: value ? Colors.green[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? Colors.green[700] : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF424242),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Kiosk Modu Hakkında',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('• Kiosk modu aktifken uygulama tam ekran çalışır'),
          _buildInfoItem('• Geri ve Home tuşları devre dışı bırakılır'),
          _buildInfoItem('• Ekran görüntüsü alınamaz'),
          _buildInfoItem('• Developer zaten yetkili, direkt çıkış yapabilir'),
          _buildInfoItem('• Tam koruma için Device Owner modu önerilir'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF424242)),
            SizedBox(width: 8),
            Text('Kiosk Modu Nedir?'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Kiosk modu, cihazın sadece bu uygulamayı çalıştırmasını sağlar.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('Özellikler:'),
              SizedBox(height: 8),
              Text('✓ Tam ekran modu'),
              Text('✓ Geri/Home tuşları devre dışı'),
              Text('✓ Bildirimler gizlenir'),
              Text('✓ Ekran yakalama engellenir'),
              Text('✓ Developer yetkisiyle direkt çıkış'),
              SizedBox(height: 12),
              Text(
                'Önemli: Tam koruma için cihazın Device Owner moduna alınması önerilir.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
