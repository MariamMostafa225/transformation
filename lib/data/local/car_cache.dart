import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

class CarCache {
  Future<List<Map<String, dynamic>>?> readCars() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final json = preferences.getString(AppConstants.cacheKey);
      if (json == null) return null;
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCars(List<Map<String, dynamic>> cars) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(AppConstants.cacheKey, jsonEncode(cars));
      await preferences.setInt(
        AppConstants.lastSyncKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Firestore's own persistent cache remains available if preferences fail.
    }
  }

  Future<DateTime?> lastSync() async {
    final preferences = await SharedPreferences.getInstance();
    final milliseconds = preferences.getInt(AppConstants.lastSyncKey);
    return milliseconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
}
