import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/tailscale_service.dart';

/// Tailscale VPN Ayarları Ekranı
class TailscaleSettingsScreen extends StatefulWidget {
  const TailscaleSettingsScreen({super.key});

  @override
  State<TailscaleSettingsScreen> createState() =>
      _TailscaleSettingsScreenState();
}

class _TailscaleSettingsScreenState extends State<TailscaleSettingsScreen> {
  final _authKeyController = TextEditingController();
  bool _isConnected = false;
  bool _isLoading = false;
  String? _localIP;
  String? _hostname;
  List<Map<String, dynamic>> _peers = [];
  Map<String, dynamic>? _status;

  @override
  void initState() {
    super.initState();
    _loadTailscaleInfo();
  }

  @override
  void dispose() {
    _authKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadTailscaleInfo() async {
    setState(() => _isLoading = true);

    try {
      await tailscaleService.init();
      _isConnected = tailscaleService.isTailscaleConnected;

      if (_isConnected) {
        _localIP = await tailscaleService.getLocalIP();
        _hostname = await tailscaleService.getHostname();
        _peers = await tailscaleService.getPeers();
        _status = await tailscaleService.getStatus();
      }

      // Kayıtlı auth key varsa göster
      final savedKey = tailscaleService.getSavedAuthKey();
      if (savedKey != null) {
        _authKeyController.text = savedKey;
      }
    } catch (e) {
      _showSnackBar('❌ Bilgi yüklenirken hata: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectTailscale() async {
    if (_authKeyController.text.isEmpty) {
      _showSnackBar('⚠️ Lütfen auth key girin', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await tailscaleService.startTailscale(
        _authKeyController.text,
      );

      if (success) {
        _showSnackBar('✅ Tailscale bağlandı!', Colors.green);
        await _loadTailscaleInfo();
      } else {
        _showSnackBar(
          '❌ Tailscale bağlanamadı. Uygulamanın yüklü olduğundan emin olun.',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('❌ Bağlantı hatası: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnectTailscale() async {
    setState(() => _isLoading = true);

    try {
      final success = await tailscaleService.stopTailscale();

      if (success) {
        _showSnackBar('✅ Tailscale bağlantısı kesildi', Colors.orange);
        setState(() {
          _isConnected = false;
          _localIP = null;
          _hostname = null;
          _peers = [];
          _status = null;
        });
      } else {
        _showSnackBar('❌ Bağlantı kesilemedi', Colors.red);
      }
    } catch (e) {
      _showSnackBar('❌ Hata: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('📋 Kopyalandı: $text', Colors.blue);
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
        title: const Text('Tailscale VPN Ayarları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTailscaleInfo,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bağlantı Durumu Kartı
                  _buildConnectionStatusCard(),
                  const SizedBox(height: 24),

                  // Auth Key Girişi (sadece bağlı değilse)
                  if (!_isConnected) ...[
                    _buildAuthKeyCard(),
                    const SizedBox(height: 24),
                  ],

                  // Bağlantı Bilgileri (sadece bağlıysa)
                  if (_isConnected) ...[
                    _buildConnectionInfoCard(),
                    const SizedBox(height: 24),
                    _buildPeersCard(),
                    const SizedBox(height: 24),
                  ],

                  // Bilgi Kartı
                  _buildInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isConnected
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isConnected ? Icons.vpn_lock : Icons.vpn_lock_outlined,
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
                      _isConnected ? 'Tailscale Bağlı' : 'Tailscale Bağlı Değil',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isConnected
                          ? 'VPN bağlantısı aktif'
                          : 'Bağlanmak için auth key girin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : _isConnected
                      ? _disconnectTailscale
                      : _connectTailscale,
              icon: Icon(_isConnected ? Icons.logout : Icons.login),
              label: Text(_isConnected ? 'Bağlantıyı Kes' : 'Bağlan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _isConnected ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthKeyCard() {
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
          const Row(
            children: [
              Icon(Icons.key, color: Color(0xFF424242)),
              SizedBox(width: 8),
              Text(
                'Tailscale Auth Key',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _authKeyController,
            decoration: InputDecoration(
              labelText: 'Auth Key',
              hintText: 'tskey-auth-xxxxxx-xxxxxxxxxx',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.vpn_key),
              suffixIcon: IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: _showAuthKeyHelp,
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📌 Auth Key Nasıl Alınır?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. login.tailscale.com adresine gidin\n'
                  '2. Settings > Keys bölümüne tıklayın\n'
                  '3. "Generate auth key" butonuna tıklayın\n'
                  '4. Key\'i kopyalayıp buraya yapıştırın',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionInfoCard() {
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
          const Row(
            children: [
              Icon(Icons.info, color: Color(0xFF424242)),
              SizedBox(width: 8),
              Text(
                'Bağlantı Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Tailscale IP',
            _localIP ?? 'Alınamadı',
            Icons.location_on,
            onTap: _localIP != null ? () => _copyToClipboard(_localIP!) : null,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Hostname',
            _hostname ?? 'Alınamadı',
            Icons.computer,
            onTap:
                _hostname != null ? () => _copyToClipboard(_hostname!) : null,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'API Base URL',
            _localIP != null ? 'http://$_localIP:8080' : 'Alınamadı',
            Icons.api,
            onTap: _localIP != null
                ? () => _copyToClipboard('http://$_localIP:8080')
                : null,
          ),
          if (_status != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              'Durum',
              _status!['isConnected'] == true ? 'Bağlı ✓' : 'Bağlı Değil',
              Icons.signal_wifi_4_bar,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.copy, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPeersCard() {
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
              const Icon(Icons.devices, color: Color(0xFF424242)),
              const SizedBox(width: 8),
              const Text(
                'Ağdaki Cihazlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_peers.length} cihaz',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_peers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Henüz başka cihaz bulunamadı',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else
            ..._peers.map((peer) => _buildPeerItem(peer)),
        ],
      ),
    );
  }

  Widget _buildPeerItem(Map<String, dynamic> peer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.computer, color: Colors.blue[700], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  peer['ip'] ?? 'No IP',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () => _copyToClipboard(peer['ip'] ?? ''),
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
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
              Icon(Icons.lightbulb, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Tailscale Hakkında',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('• Tailscale, güvenli VPN bağlantısı sağlar'),
          _buildInfoItem('• Cihazlar arasında mesh ağ oluşturur'),
          _buildInfoItem('• API erişimi için kullanılabilir'),
          _buildInfoItem('• Tailscale uygulamasının kurulu olması gerekir'),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              // Tailscale web sitesine yönlendir
              _showSnackBar('🌐 Tailscale.com', Colors.blue);
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Tailscale İndir'),
          ),
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

  void _showAuthKeyHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF424242)),
            SizedBox(width: 8),
            Text('Auth Key Nedir?'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tailscale Auth Key, cihazınızı Tailscale ağına otomatik olarak eklemek için kullanılır.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('Auth Key Alma Adımları:'),
              SizedBox(height: 8),
              Text('1. https://login.tailscale.com adresine gidin'),
              Text('2. Hesabınıza giriş yapın'),
              Text('3. Settings > Keys bölümüne tıklayın'),
              Text('4. "Generate auth key" butonuna tıklayın'),
              Text('5. "Reusable" ve "Ephemeral" seçeneklerini işaretleyin'),
              Text('6. Key\'i kopyalayıp uygulamaya yapıştırın'),
              SizedBox(height: 12),
              Text(
                '⚠️ Auth key\'i güvenli bir yerde saklayın!',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Colors.red,
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF424242)),
            SizedBox(width: 8),
            Text('Tailscale Nedir?'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tailscale, Zero-config VPN hizmetidir.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('Özellikler:'),
              SizedBox(height: 8),
              Text('✓ Güvenli peer-to-peer bağlantı'),
              Text('✓ Kolay kurulum'),
              Text('✓ NAT geçişi'),
              Text('✓ Mesh ağ yapısı'),
              Text('✓ WireGuard protokolü'),
              SizedBox(height: 12),
              Text(
                'Kullanım: Uzaktan erişim, API bağlantıları ve güvenli veri transferi için idealdir.',
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
