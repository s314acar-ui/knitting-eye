import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_result.dart';

class StorageService {
  static const String _historyKey = 'scan_history';

  Future<List<ScanResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((j) => ScanResult.fromJson(j)).toList();
  }

  Future<void> saveResult(ScanResult result) async {
    final history = await getHistory();
    history.insert(0, result);
    
    // En fazla 50 kayıt tut
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(history.map((r) => r.toJson()).toList());
    await prefs.setString(_historyKey, jsonString);
  }

  Future<void> deleteResult(String id) async {
    final history = await getHistory();
    history.removeWhere((r) => r.id == id);

    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(history.map((r) => r.toJson()).toList());
    await prefs.setString(_historyKey, jsonString);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
