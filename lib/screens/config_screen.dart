import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../services/document_ai_service.dart';
import '../models/scan_result.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// Config yönetim ekranı - Sadece admin için
class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  bool _isScanning = false;
  List<String> _learnedFields = [];
  // Yeni yapı: jsonKey -> ocrField (aynı ocrField birden fazla jsonKey'e atanabilir)
  Map<String, String> _currentMappings = {};
  final ImagePicker _picker = ImagePicker();
  final DocumentAIService _documentAI = DocumentAIService();

  @override
  void initState() {
    super.initState();
    _loadCurrentMappings();
  }

  void _loadCurrentMappings() {
    setState(() {
      _currentMappings = Map.from(configService.fieldMappings);
      // Duplicate'ları kaldır
      _learnedFields = configService.learnedOcrFields.toSet().toList();
      _learnedFields.sort();
    });
  }

  Future<void> _startLearningMode() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
      );

      if (image != null) {
        await _scanDocument(File(image.path));
      }
    } catch (e) {
      _showError('Kamera hatası: \$e');
    }
  }

  Future<void> _scanDocument(File imageFile) async {
    setState(() => _isScanning = true);

    try {
      final result = await _documentAI.processImage(imageFile.path);

      final fields = <String>[];
      for (final line in result.parsedLines) {
        if (line.type == LineType.keyValue && line.key.isNotEmpty) {
          fields.add(line.key);
        }
      }

      setState(() {
        _learnedFields = fields.toSet().toList();
        _learnedFields.sort();
        _isScanning = false;
      });

      configService.learnOcrFields(_learnedFields);
    } catch (e) {
      setState(() => _isScanning = false);
      _showError('Belge işlenemedi: \$e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveMappings() async {
    for (final entry in _currentMappings.entries) {
      configService.setFieldMapping(entry.key, entry.value);
    }
    await configService.saveConfig();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ayarlar kaydedildi'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _clearAllMappings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content: const Text('Tüm alan eşleştirmeleri silinecek.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await configService.clearAllMappings();
      setState(() => _currentMappings = {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1a1a2e),
      child: _isScanning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.tealAccent),
                  SizedBox(height: 16),
                  Text('Belge taranıyor...',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          : Row(
              children: [
                // Sol panel - Kontroller
                Container(
                  width: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16213e),
                    border: Border(
                        right: BorderSide(color: Color(0xFF0f3460), width: 1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alan Eşleştirme',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('OCR alanlarını JSON formatına eşleştirin',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 12)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _startLearningMode,
                          icon: const Icon(Icons.add_a_photo, size: 18),
                          label: const Text('Belge Tara'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveMappings,
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Kaydet'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent,
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_currentMappings.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _clearAllMappings,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Tümünü Sil'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12)),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.blue.withOpacity(0.3))),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    'Config cihazda kalıcı olarak saklanır',
                                    style: TextStyle(
                                        color: Colors.blue[200],
                                        fontSize: 10))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Sağ panel - Gruplanmış eşleştirme alanları
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: ConfigService.groupedJsonKeys.entries
                          .map((group) =>
                              _buildGroupCard(group.key, group.value))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGroupCard(String groupName, List<Map<String, String>> fields) {
    Color groupColor;
    IconData groupIcon;
    switch (groupName) {
      case 'Sipariş Bilgileri':
        groupColor = Colors.pinkAccent;
        groupIcon = Icons.shopping_cart;
        break;
      case 'Kumaş Bilgileri':
        groupColor = Colors.tealAccent;
        groupIcon = Icons.texture;
        break;
      case 'Makine Bilgileri':
        groupColor = Colors.tealAccent;
        groupIcon = Icons.precision_manufacturing;
        break;
      case 'İplik Bilgileri':
        groupColor = Colors.orangeAccent;
        groupIcon = Icons.linear_scale;
        break;
      default:
        groupColor = Colors.grey;
        groupIcon = Icons.more_horiz;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: const Color(0xFF16213e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0f3460))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: groupColor.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12))),
            child: Row(
              children: [
                Icon(groupIcon, color: groupColor, size: 20),
                const SizedBox(width: 8),
                Text(groupName,
                    style: TextStyle(
                        color: groupColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: fields
                  .map((field) => _buildFieldRow(field['key']!, field['label']!,
                      field['hint']!, groupColor))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(
      String jsonKey, String label, String hint, Color accentColor) {
    // Yeni yapı: jsonKey -> ocrField
    final currentOcrField = _currentMappings[jsonKey];
    final isRequired = label.contains('*');
    final hasMapping = currentOcrField != null && currentOcrField.isNotEmpty;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: hasMapping
                ? Colors.green.withOpacity(0.5)
                : (isRequired
                    ? accentColor.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label.replaceAll(' *', ''),
                      style: TextStyle(
                          color: isRequired ? accentColor : Colors.grey[400],
                          fontWeight: FontWeight.w600,
                          fontSize: 11))),
              if (isRequired)
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: hasMapping ? Colors.green : accentColor,
                        shape: BoxShape.circle)),
              if (hasMapping)
                const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.check_circle,
                        color: Colors.green, size: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFF0f3460),
                borderRadius: BorderRadius.circular(6)),
            child: DropdownButtonFormField<String>(
              value: (currentOcrField != null &&
                      _learnedFields.contains(currentOcrField))
                  ? currentOcrField
                  : null,
              decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12)),
              dropdownColor: const Color(0xFF16213e),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                    value: null,
                    child: Text('-- Seçin --',
                        style: TextStyle(color: Colors.grey))),
                ..._learnedFields.toSet().map((ocrField) {
                  // Aynı OCR alanı birden fazla JSON key'e atanabilir
                  // Şimdi _currentMappings jsonKey -> ocrField formatında
                  final usedInOtherFields = _currentMappings.entries
                      .where((e) => e.value == ocrField && e.key != jsonKey)
                      .length;
                  return DropdownMenuItem<String>(
                      value: ocrField,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(ocrField,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                          if (usedInOtherFields > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '+$usedInOtherFields',
                                style: const TextStyle(
                                    color: Colors.blue, fontSize: 10),
                              ),
                            ),
                        ],
                      ));
                }),
              ],
              onChanged: (value) {
                setState(() {
                  // jsonKey -> ocrField formatında
                  if (value != null) {
                    _currentMappings[jsonKey] = value;
                  } else {
                    _currentMappings.remove(jsonKey);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
