import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/plate_search.dart';
import '../local/car_cache.dart';
import '../models/car.dart';
import '../models/company.dart';
import '../remote/firebase_bootstrap.dart';

bool _isCatalogCar(Map<String, dynamic> data, Set<String> companyIds) {
  final companyId = (data['companyId'] ?? '').toString();
  final letters = (data['letters'] ?? '').toString();
  return companyIds.contains(companyId) && !RegExp(r'[-–—/]').hasMatch(letters);
}

class CatalogSnapshot {
  const CatalogSnapshot({
    required this.cars,
    required this.fromCache,
    required this.hasPendingWrites,
  });

  final List<Car> cars;
  final bool fromCache;
  final bool hasPendingWrites;
}

class CatalogSeedResult {
  const CatalogSeedResult({
    required this.companiesAdded,
    required this.carsAdded,
    required this.carsAlreadyPresent,
  });

  final int companiesAdded;
  final int carsAdded;
  final int carsAlreadyPresent;
}

class CarsRepository {
  CarsRepository({
    required this.companies,
    required this.initialCars,
    List<Car>? seedCars,
    CarCache? cache,
  }) : seedCars = List<Car>.unmodifiable(seedCars ?? initialCars),
       _cache = cache ?? CarCache();

  final List<Company> companies;
  final List<Car> initialCars;
  final List<Car> seedCars;
  final CarCache _cache;
  final _writeErrors = StreamController<String>.broadcast();

  Stream<String> get writeErrors => _writeErrors.stream;

  static Future<CarsRepository> create() async {
    final companyRows = jsonDecode(
      await rootBundle.loadString(AppConstants.companiesAsset),
    ) as List<dynamic>;
    final companies = companyRows
        .whereType<Map<String, dynamic>>()
        .map((row) => Company.fromMap(row['id'].toString(), row))
        .toList(growable: false);
    final companyNames = {
      for (final company in companies) company.id: company.name,
    };
    final companyIds = companyNames.keys.toSet();
    final bundledRows = jsonDecode(
      await rootBundle.loadString(AppConstants.carsAsset),
    ) as List<dynamic>;
    final seedCars = bundledRows
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => Car.fromMap(
            row['id'].toString(),
            row,
            companyName: companyNames[row['companyId']] ?? 'شركة غير معروفة',
          ),
        )
        .toList(growable: false);
    final cache = CarCache();
    final cachedRows = await cache.readCars();
    // The bundled catalog is the dependable first-run/offline baseline. Merge
    // cached Firestore rows over it so a previously cached empty/older catalog
    // cannot hide cars added to the app assets.
    final rowsById = <String, Map<String, dynamic>>{
      for (final row in bundledRows.cast<Map<String, dynamic>>())
        row['id'].toString(): row,
    };
    for (final row in cachedRows ?? const <Map<String, dynamic>>[]) {
      if (!_isCatalogCar(row, companyIds)) continue;
      rowsById[row['id'].toString()] = row;
    }
    final rows = rowsById.values;
    final initialCars = rows
        .map(
          (row) => Car.fromMap(
            row['id'].toString(),
            row,
            companyName: companyNames[row['companyId']] ?? 'شركة غير معروفة',
          ),
        )
        .toList(growable: false);
    return CarsRepository(
      companies: companies,
      initialCars: initialCars,
      seedCars: seedCars,
      cache: cache,
    );
  }

  bool get canUseFirebase => FirebaseBootstrap.initialized;

  Future<DateTime?> lastSync() => _cache.lastSync();

  /// Add missing bundled records to Firestore without overwriting or deleting
  /// documents already there. This is intended for the signed-in admin.
  Future<CatalogSeedResult> uploadMissingCatalog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !AppConstants.isAdminEmail(user.email)) {
      throw StateError('يجب تسجيل الدخول بحساب الأدمن لرفع سجل السيارات.');
    }

    final firestore = FirebaseFirestore.instance;
    final companiesCollection = firestore.collection('companies');
    final carsCollection = firestore.collection('cars');
    final companiesSnapshot = await companiesCollection.get(
      const GetOptions(source: Source.server),
    );
    final carsSnapshot = await carsCollection.get(
      const GetOptions(source: Source.server),
    );

    final existingCompanyIds = companiesSnapshot.docs
        .map((document) => document.id)
        .toSet();
    final existingCarsById = {
      for (final document in carsSnapshot.docs) document.id: document.data(),
    };
    final existingPlateKeys = <String>{
      for (final document in carsSnapshot.docs) _plateOwnerKey(document.data()),
    };
    final missingCompanies = companies
        .where((company) => !existingCompanyIds.contains(company.id))
        .toList(growable: false);

    for (var start = 0; start < missingCompanies.length; start += 450) {
      final batch = firestore.batch();
      for (final company in missingCompanies.skip(start).take(450)) {
        batch.set(companiesCollection.doc(company.id), {
          ...company.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    final missingCars = <Car>[];
    for (final car in seedCars) {
      final key = _plateOwnerKey({
        'carNumber': car.carNumber,
        'letters': car.letters,
        'companyId': car.companyId,
      });
      if (existingCarsById.containsKey(car.id) || !existingPlateKeys.add(key)) {
        continue;
      }
      missingCars.add(car);
    }

    for (var start = 0; start < missingCars.length; start += 450) {
      final batch = firestore.batch();
      for (final car in missingCars.skip(start).take(450)) {
        batch.set(carsCollection.doc(car.id), {
          ...car.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    return CatalogSeedResult(
      companiesAdded: missingCompanies.length,
      carsAdded: missingCars.length,
      carsAlreadyPresent: seedCars.length - missingCars.length,
    );
  }

  String _plateOwnerKey(Map<String, dynamic> data) =>
      '${normalizeArabic((data['carNumber'] ?? '').toString())}|'
      '${compactArabic((data['letters'] ?? '').toString())}|'
      '${(data['companyId'] ?? '').toString().trim()}';

  Stream<CatalogSnapshot> watchCars() {
    if (!canUseFirebase) return const Stream<CatalogSnapshot>.empty();
    final companyNames = {
      for (final company in companies) company.id: company.name,
    };
    final companyIds = companyNames.keys.toSet();
    return FirebaseFirestore.instance.collection('cars').snapshots().map((
      snapshot,
    ) {
      final cars = snapshot.docs
          .where((document) => _isCatalogCar(document.data(), companyIds))
          .map((document) {
            final raw = document.data();
            final timestamp = raw['updatedAt'];
            if (timestamp is Timestamp) raw['updatedAt'] = timestamp.toDate();
            return Car.fromMap(
              document.id,
              raw,
              companyName: companyNames[raw['companyId']] ?? 'شركة غير معروفة',
            );
          })
          .toList(growable: false);
      unawaited(
        _cache.saveCars(
          cars
              .map((car) => {'id': car.id, ...car.toMap()})
              .toList(growable: false),
        ),
      );
      return CatalogSnapshot(
        cars: cars,
        fromCache: snapshot.metadata.isFromCache,
        hasPendingWrites: snapshot.metadata.hasPendingWrites,
      );
    });
  }

  String addCar({
    required String carNumber,
    required String letters,
    required String companyId,
  }) {
    final document = FirebaseFirestore.instance.collection('cars').doc();
    _submit(
      document.set({
        'carNumber': carNumber.trim(),
        'letters': letters.trim(),
        'companyId': companyId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
      action: 'إضافة السيارة',
    );
    return document.id;
  }

  void updateCar({
    required String carId,
    required String carNumber,
    required String letters,
    required String companyId,
  }) {
    _submit(
      FirebaseFirestore.instance.collection('cars').doc(carId).update({
        'carNumber': carNumber.trim(),
        'letters': letters.trim(),
        'companyId': companyId,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
      action: 'تعديل السيارة',
    );
  }

  void deleteCar(String carId) {
    _submit(
      FirebaseFirestore.instance.collection('cars').doc(carId).delete(),
      action: 'حذف السيارة',
    );
  }

  void _submit(Future<void> write, {required String action}) {
    unawaited(
      write.catchError((Object error) {
        final code = error is FirebaseException ? error.code : '';
        final detail = error is FirebaseException
            ? error.message?.trim()
            : error.toString();
        final message = switch (code) {
          'permission-denied' =>
            'رفضت قواعد Firestore $action (permission-denied). تحقق من نشر القواعد وبريد الأدمن.',
          'unavailable' || 'deadline-exceeded' =>
            'تعذر اتصال Firestore أثناء $action ($code). سيحاول التطبيق المزامنة عند عودة الشبكة.',
          'not-found' =>
            'تعذر $action: المستند غير موجود في Firestore (not-found).',
          _ =>
            'فشل $action في Firestore${code.isEmpty ? '' : ' ($code)'}${detail == null || detail.isEmpty ? '.' : ': $detail'}',
        };
        _writeErrors.add(message);
      }),
    );
  }
}
