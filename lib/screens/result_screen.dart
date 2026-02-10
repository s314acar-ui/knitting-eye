import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_result.dart';
import '../services/api_server.dart';

class ResultScreen extends StatefulWidget {
  final ScanResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isServerRunning = false;
  String? _serverAddress;

  @override
  void initState() {
    super.initState();
    _isServerRunning = apiServer.isRunning;
    _serverAddress = apiServer.address;
    // Veriyi API sunucusuna gönder
    apiServer.updateWorkOrder(widget.result);
  }

  ScanResult get result => widget.result;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: result.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Metin kopyalandı'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareText() {
    Share.share(result.text, subject: 'OCR Tarama Sonucu');
  }

  Future<void> _toggleServer() async {
    if (_isServerRunning) {
      await apiServer.stop();
      setState(() {
        _isServerRunning = false;
        _serverAddress = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Sunucusu durduruldu'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      try {
        final address = await apiServer.start();
        setState(() {
          _isServerRunning = true;
          _serverAddress = address;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('API Sunucusu başlatıldı: $address'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sunucu başlatılamadı: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showApiInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.api, color: Color(0xFF2196F3)),
            SizedBox(width: 8),
            Text('API Bilgisi'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Durum', _isServerRunning ? 'Çalışıyor' : 'Durduruldu'),
              if (_serverAddress != null) ...[
                const SizedBox(height: 12),
                const Text('Adres:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    _serverAddress!,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Endpoints:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildEndpoint('GET', '/api/work-order', 'İş emri JSON'),
                _buildEndpoint('GET', '/api/raw', 'Ham OCR verisi'),
                _buildEndpoint('GET', '/api/status', 'Sunucu durumu'),
              ],
            ],
          ),
        ),
        actions: [
          if (_serverAddress != null)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '$_serverAddress/api/work-order'));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API adresi kopyalandı')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Adresi Kopyala'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _isServerRunning ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: _isServerRunning ? Colors.green[800] : Colors.red[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndpoint(String method, String path, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(path, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareJson() {
    final workOrder = apiServer.currentWorkOrder;
    if (workOrder != null) {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(workOrder.toJson());
      Share.share(jsonStr, subject: 'İş Emri JSON');
    }
  }

  void _showFullImage(BuildContext context) {
    if (result.imagePath == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Orijinal Görsel'),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(result.imagePath!),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(LineType type) {
    switch (type) {
      case LineType.header:
        return const Color(0xFF1565C0); // Koyu mavi
      case LineType.section:
        return const Color(0xFF2E7D32); // Yeşil
      case LineType.keyValue:
        return const Color(0xFFF5F5F5); // Açık gri
      case LineType.tableHeader:
        return const Color(0xFFE3F2FD); // Açık mavi
      case LineType.tableRow:
        return const Color(0xFFFFFDE7); // Açık sarı
      case LineType.normal:
        return Colors.white;
    }
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF424242),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarama Sonucu'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // API Server butonu
          IconButton(
            icon: Icon(
              _isServerRunning ? Icons.cloud_done : Icons.cloud_off,
              color: _isServerRunning ? Colors.greenAccent : Colors.white,
            ),
            onPressed: _toggleServer,
            tooltip: _isServerRunning ? 'API Durdur' : 'API Başlat',
          ),
          // API Bilgi butonu
          if (_isServerRunning)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showApiInfo,
              tooltip: 'API Bilgisi',
            ),
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: _shareJson,
            tooltip: 'JSON Paylaş',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyToClipboard(context),
            tooltip: 'Kopyala',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareText,
            tooltip: 'Paylaş',
          ),
        ],
      ),
      body: Column(
        children: [
          // API Server durumu
          if (_isServerRunning && _serverAddress != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.green[50],
              child: Row(
                children: [
                  Icon(Icons.cloud_done, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API: $_serverAddress/api/work-order',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 18, color: Colors.green[700]),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '$_serverAddress/api/work-order'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API adresi kopyalandı')),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          
          // Resim önizleme - tıklanabilir
          if (result.imagePath != null)
            GestureDetector(
              onTap: () => _showFullImage(context),
              child: Container(
                height: 120,
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(result.imagePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    // Tam ekran ikonu
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Satır sayısı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFE3F2FD),
            child: Row(
              children: [
                const Icon(Icons.format_list_numbered, size: 20, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Text(
                  '${result.parsedLines.length} satır okundu',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
          ),
          
          // Ana içerik
          Expanded(
            child: result.parsedLines.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.text_snippet_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Metin bulunamadı',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: result.parsedLines.length,
                    itemBuilder: (context, index) {
                      final line = result.parsedLines[index];
                      return _buildLineItem(index, line);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(int index, ParsedLine line) {
    // Başlık stili
    if (line.type == LineType.header) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            line.key,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Bölüm başlığı (İPLİKLER gibi)
    if (line.type == LineType.section) {
      return Container(
        margin: const EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          line.key,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Tablo başlığı
    if (line.type == LineType.tableHeader) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF90CAF9)),
        ),
        child: Text(
          line.key,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1565C0),
          ),
        ),
      );
    }

    // Tablo satırı - İplik bilgisi
    if (line.type == LineType.tableRow) {
      // İplik satırını parse et
      final parts = line.key.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      
      // İplik verilerini ayıkla
      String siraNo = '';
      String stokKodu = '';
      String tanim = '';
      String miktar = '';
      String lotNo = '';
      String depoNo = '';
      
      if (parts.isNotEmpty) {
        // İlk eleman sıra numarası olabilir
        if (parts[0].length <= 2 && RegExp(r'^\d+$').hasMatch(parts[0])) {
          siraNo = parts[0];
          parts.removeAt(0);
        }
        
        // Stok kodu (IP ile başlayan)
        for (int i = 0; i < parts.length; i++) {
          if (parts[i].toUpperCase().startsWith('IP')) {
            stokKodu = parts[i];
            parts.removeAt(i);
            break;
          }
        }
        
        // Tanım (en uzun parça genellikle tanımdır)
        if (parts.isNotEmpty) {
          int maxLen = 0;
          int maxIdx = 0;
          for (int i = 0; i < parts.length; i++) {
            if (parts[i].length > maxLen && (parts[i].contains('PENYE') || 
                parts[i].contains('POLYESTER') || parts[i].contains('İPLİK') ||
                parts[i].contains('IPLIK') || parts[i].contains('PAMUK') ||
                parts[i].contains('GIPE') || parts[i].contains('TEKSTURE') ||
                parts[i].contains('Ne ') || parts[i].contains('DN'))) {
              maxLen = parts[i].length;
              maxIdx = i;
            }
          }
          if (maxLen > 0) {
            tanim = parts[maxIdx];
            parts.removeAt(maxIdx);
          }
        }
        
        // Kalan parçalardan sayısal olanları al
        for (final part in parts) {
          if (part.contains(',') && RegExp(r'^\d').hasMatch(part)) {
            // Miktar (79,000 gibi)
            if (miktar.isEmpty) miktar = part;
          } else if (RegExp(r'^\d+[A-Z\-/]+').hasMatch(part) || part.startsWith('DS') || part.startsWith('ES')) {
            // Lot No veya Depo No
            if (part.startsWith('DS') || part.startsWith('ES')) {
              depoNo = part;
            } else {
              lotNo = part;
            }
          }
        }
      }
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kısım - Sıra No ve Stok Kodu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFF8F00),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
              ),
              child: Row(
                children: [
                  if (siraNo.isNotEmpty) ...[
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        siraNo,
                        style: const TextStyle(
                          color: Color(0xFFFF8F00),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (stokKodu.isNotEmpty)
                    Expanded(
                      child: Text(
                        stokKodu,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Alt kısım - Detaylar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tanim.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        tanim,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  // Detay satırı
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (miktar.isNotEmpty)
                        _buildDetailChip('Miktar', miktar),
                      if (lotNo.isNotEmpty)
                        _buildDetailChip('Lot', lotNo),
                      if (depoNo.isNotEmpty)
                        _buildDetailChip('Depo', depoNo),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Anahtar: Değer satırı
    if (line.type == LineType.keyValue) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Numara
            Container(
              width: 36,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            // Anahtar
            Container(
              width: 130,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                border: Border(
                  right: BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
              child: Text(
                line.key,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF424242),
                ),
              ),
            ),
            // Değer
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Text(
                  line.value ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Normal satır
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(7),
                bottomLeft: Radius.circular(7),
              ),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                line.key,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
