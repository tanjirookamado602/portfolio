import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class LocalContentService {
  static const _prefix = 'content_';

  Future<String?> loadRaw(String section) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$section';
    final cached = prefs.getString(key);
    if (cached != null) return cached;

    // Try to load from assets/data/<section>.json if present
    try {
      final raw = await rootBundle.loadString('assets/data/$section.json');
      return raw;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRaw(String section, String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$section';
    await prefs.setString(key, jsonStr);
  }
}
