import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';
import '../services/api_server.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onUrlSaved;

  const SettingsScreen({super.key, this.onUrlSaved});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final _homeUrlController = TextEditingController();
  String _deviceIp = '';
  bool _canInstallPackages = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _startApiServer();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final updateService = UpdateService();
      final canInstall = await updateService.canInstallPackages();
      if (mounted) {
        setState(() {
          _canInstallPackages = canInstall;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Permission check error: $e');
    }
  }

  void _loadSettings() {
    _homeUrlController.text = settingsService.homeUrl;
    _deviceIp = settingsService.deviceIp;
    setState(() {});
  }

  Future<void> _startApiServer() async {
    if (!apiServer.isRunning) {
      await apiServer.start(port: settingsService.apiPort);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeUrlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama geri geldiğinde izin durumunu güncelle
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _saveHomeUrl() async {
    await settingsService.setHomeUrl(_homeUrlController.text);
    _showSnackBar('Anasayfa URL kaydedildi');
    // Anasayfaya dön
    widget.onUrlSaved?.call();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Kopyalandı: $text');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sol - Cihaz ve API Bilgileri
          Expanded(
            child: _buildSection(
              title: 'Cihaz & API Bilgileri',
              icon: Icons.info_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cihaz IP
                  _buildReadOnlyInfo(
                    title: 'Cihaz IP Adresi',
                    value: _deviceIp,
                    icon: Icons.wifi,
                    onCopy: () => _copyToClipboard(_deviceIp),
                  ),
                  const SizedBox(height: 16),

                  // Otomatik API URL
                  _buildReadOnlyInfo(
                    title: 'API Base URL',
                    value: 'http://$_deviceIp:${settingsService.apiPort}',
                    icon: Icons.link,
                    onCopy: () => _copyToClipboard(
                        'http://$_deviceIp:${settingsService.apiPort}'),
                  ),
                  const SizedBox(height: 16),

                  // API Endpoints (Read-only)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.api, color: Color(0xFF424242)),
                            const SizedBox(width: 8),
                            const Text(
                              'API Endpoints',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF424242),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.lock, size: 16, color: Colors.grey[500]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildEndpointReadOnly(
                          'İş Emri',
                          'http://$_deviceIp:${settingsService.apiPort}/api/work-order',
                        ),
                        _buildEndpointReadOnly(
                          'Durum',
                          'http://$_deviceIp:${settingsService.apiPort}/api/status',
                        ),
                        _buildEndpointReadOnly(
                          'Ham Veri',
                          'http://$_deviceIp:${settingsService.apiPort}/api/raw',
                        ),
                        _buildEndpointReadOnly(
                          'Görsel',
                          'http://$_deviceIp:${settingsService.apiPort}/api/image',
                        ),
                        _buildEndpointReadOnly(
                          'Barkod',
                          'http://$_deviceIp:${settingsService.apiPort}/api/barcode',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Sağ - Web Ayarları
          Expanded(
            child: _buildSection(
              title: 'Web Tarayıcı Ayarları',
              icon: Icons.language,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _homeUrlController,
                    label: 'Anasayfa URL',
                    hint: 'https://www.example.com',
                    icon: Icons.home,
                    onSave: _saveHomeUrl,
                  ),

                  const SizedBox(height: 32),

                  // Admin Şifre Yönetimi (sadece admin için)
                  if (authService.isAdmin) ...[
                    _buildAdminPasswordSection(),
                    const SizedBox(height: 24),
                  ],

                  // Uygulama İzinleri Yönetimi
                  _buildPermissionsSection(),
                  const SizedBox(height: 24),

                  // API Endpoints bilgisi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.api, color: Color(0xFF424242)),
                            SizedBox(width: 8),
                            Text(
                              'API Endpoints',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF424242),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildEndpointInfo(
                            'GET', '/api/work-order', 'OCR iş emri verisi'),
                        _buildEndpointInfo(
                            'GET', '/api/status', 'Sunucu durumu'),
                        _buildEndpointInfo('GET', '/api/raw', 'Ham OCR verisi'),
                        _buildEndpointInfo('GET', '/api/image', 'Son görsel'),
                        _buildEndpointInfo('GET', '/api/barcode', 'Son barkod'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF424242)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildReadOnlyInfo({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF424242)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.lock, size: 12, color: Colors.grey[500]),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: onCopy,
              tooltip: 'Kopyala',
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onSave,
    TextInputType keyboardType = TextInputType.url,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: Icon(icon),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF424242),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEndpointInfo(String method, String path, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              method,
              style: TextStyle(
                color: Colors.green[800],
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            path,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointReadOnly(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                url,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _copyToClipboard(url),
            child: const Icon(Icons.copy, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _canInstallPackages ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _canInstallPackages ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: Color(0xFF424242)),
              SizedBox(width: 8),
              Text(
                'Uygulama İzinleri',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Uygulama Yükleme İzni
          Row(
            children: [
              Icon(
                _canInstallPackages ? Icons.check_circle : Icons.cancel,
                size: 20,
                color: _canInstallPackages ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bilinmeyen Kaynaklardan Yükleme',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _canInstallPackages
                          ? 'İzin verildi - Güncelleme sistemi çalışır durumda'
                          : 'İzin verilmedi - Güncelleme yüklenemez',
                      style: TextStyle(
                        fontSize: 11,
                        color: _canInstallPackages
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!_canInstallPackages)
                ElevatedButton.icon(
                  onPressed: _requestInstallPermission,
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('İzin Ver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _checkPermissions,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Durumu Güncelle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF424242),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          if (!_canInstallPackages) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kiosk modundayken güncelleme yapabilmek için bu iznin verilmesi gerekir. '
                      'Açılacak ayarlar ekranında izni etkinleştirin ve geri dönün.',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _requestInstallPermission() async {
    try {
      final updateService = UpdateService();
      final result = await updateService.requestInstallPermission();
      if (result == 'ALREADY_GRANTED') {
        _showSnackBar('İzin zaten verilmiş');
      } else if (result == 'PERMISSION_REQUESTED') {
        _showSnackBar('Ayarlar açıldı - izni etkinleştirin ve geri dönün');
      }
      // Geri döndüğünde durumu güncelle
      await Future.delayed(const Duration(seconds: 2));
      await _checkPermissions();
    } catch (e) {
      _showSnackBar('İzin istenemedi: $e');
    }
  }

  Widget _buildAdminPasswordSection() {
    final hasPassword = authService.currentAdminPassword != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Color(0xFF424242)),
              SizedBox(width: 8),
              Text(
                'Yönetici Şifre Yönetimi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                hasPassword ? Icons.lock : Icons.lock_open,
                size: 16,
                color: hasPassword ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                hasPassword ? 'Şifre tanımlı' : 'Şifre tanımlı değil',
                style: TextStyle(
                  color: hasPassword ? Colors.green[700] : Colors.orange[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.edit, size: 16),
                label: Text(hasPassword ? 'Şifre Değiştir' : 'Şifre Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF424242),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              if (hasPassword)
                OutlinedButton.icon(
                  onPressed: _showDeletePasswordDialog,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Şifre Sil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final hasPassword = authService.currentAdminPassword != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasPassword ? 'Şifre Değiştir' : 'Yeni Şifre Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasPassword)
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mevcut Şifre',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              if (hasPassword) const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPwd = currentPasswordController.text;
              final newPwd = newPasswordController.text;
              final confirmPwd = confirmPasswordController.text;

              if (newPwd.isEmpty) {
                _showSnackBar('Yeni şifre boş olamaz');
                return;
              }

              if (newPwd != confirmPwd) {
                _showSnackBar('Şifreler eşleşmiyor');
                return;
              }

              if (newPwd.length < 4) {
                _showSnackBar('Şifre en az 4 karakter olmalı');
                return;
              }

              final success = await authService.changeAdminPassword(
                hasPassword ? currentPwd : '',
                newPwd,
              );

              if (success) {
                Navigator.pop(context);
                _showSnackBar(
                    hasPassword ? 'Şifre değiştirildi' : 'Şifre eklendi');
                setState(() {});
              } else {
                _showSnackBar('Mevcut şifre yanlış');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF424242),
              foregroundColor: Colors.white,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showDeletePasswordDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Sil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Yönetici şifresini silmek için mevcut şifrenizi girin.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mevcut Şifre',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Şifre silindikten sonra yönetici girişi şifresiz olacak!',
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pwd = passwordController.text;

              if (pwd.isEmpty) {
                _showSnackBar('Şifre girin');
                return;
              }

              final success = await authService.deleteAdminPassword(pwd);

              if (success) {
                Navigator.pop(context);
                _showSnackBar('Şifre silindi');
                setState(() {});
              } else {
                _showSnackBar('Şifre yanlış');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
