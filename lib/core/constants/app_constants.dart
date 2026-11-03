import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const appName = 'السيارات المشتركة بالمشروع';
  static const adminEmails = <String>[
    'm01151661324@gmail.com',
    // Add each additional admin email here and in firestore.rules.
  ];

  static bool isAdminEmail(String? email) {
    final candidate = email?.trim().toLowerCase();
    return candidate != null &&
        adminEmails.any((admin) => admin.trim().toLowerCase() == candidate);
  }

  static const carsAsset = 'assets/data/cars.json';
  static const companiesAsset = 'assets/data/companies.json';
  static const cacheKey = 'cars_catalog_cache_v1';
  static const lastSyncKey = 'cars_catalog_last_sync_v1';
  static const debounceDuration = Duration(milliseconds: 250);
  static const background = Color(0xFFF5F7F6);
  static const primary = Color(0xFF286C71);
  static const ink = Color(0xFF183238);
}
