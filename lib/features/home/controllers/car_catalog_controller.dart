import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/plate_search.dart';
import '../../../data/models/car.dart';
import '../../../data/models/company.dart';
import '../../../data/repositories/cars_repository.dart';

class CarCatalogController extends ChangeNotifier {
  CarCatalogController(this.repository)
    : cars = List<Car>.unmodifiable(repository.initialCars),
      companies = List<Company>.unmodifiable(repository.companies) {
    _initializeLastSync();
    _subscription = repository.watchCars().listen(
      _onSnapshot,
      onError: (Object _) {
        hasRemoteError = true;
        notifyListeners();
      },
    );
    _writeErrorSubscription = repository.writeErrors.listen((message) {
      lastWriteError = message;
      writeErrorSerial++;
      notifyListeners();
    });
  }

  final CarsRepository repository;
  final List<Company> companies;
  List<Car> cars;
  Timer? _debounce;
  StreamSubscription<CatalogSnapshot>? _subscription;
  StreamSubscription<String>? _writeErrorSubscription;
  String query = '';
  String? selectedCompanyId;
  bool isSynced = false;
  bool hasPendingWrites = false;
  bool hasRemoteError = false;
  bool remoteCatalogEmpty = false;
  String? lastWriteError;
  int writeErrorSerial = 0;
  DateTime? lastSyncAt;

  List<Car> get visibleCars => cars
      .where((car) {
        final matchesCompany =
            selectedCompanyId == null || car.companyId == selectedCompanyId;
        return matchesCompany &&
            containsPlateQuery(
              query: query,
              carNumber: car.carNumber,
              letters: car.letters,
              companyName: car.companyName,
            );
      })
      .toList(growable: false);

  int countForCompany(String companyId) =>
      cars.where((car) => car.companyId == companyId).length;

  void setQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.debounceDuration, () {
      query = value;
      notifyListeners();
    });
  }

  void clearQuery() {
    _debounce?.cancel();
    query = '';
    notifyListeners();
  }

  void selectCompany(String? companyId) {
    selectedCompanyId = companyId;
    notifyListeners();
  }

  void _onSnapshot(CatalogSnapshot snapshot) {
    if (snapshot.cars.isEmpty) {
      // Firestore may be connected before its catalog has been imported.
      // Keep the bundled data visible instead of replacing it with zero cars.
      remoteCatalogEmpty = !snapshot.fromCache;
    } else {
      remoteCatalogEmpty = false;
      if (snapshot.fromCache) {
        final merged = {for (final car in repository.initialCars) car.id: car};
        for (final car in snapshot.cars) {
          merged[car.id] = car;
        }
        cars = List<Car>.unmodifiable(merged.values);
      } else {
        cars = List<Car>.unmodifiable(snapshot.cars);
      }
    }
    isSynced = !snapshot.fromCache;
    hasPendingWrites = snapshot.hasPendingWrites;
    hasRemoteError = false;
    if (!snapshot.fromCache) lastSyncAt = DateTime.now();
    notifyListeners();
  }

  Future<void> _initializeLastSync() async {
    try {
      lastSyncAt = await repository.lastSync();
      notifyListeners();
    } catch (_) {
      // The local catalog remains usable when the platform cache is unavailable.
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _subscription?.cancel();
    _writeErrorSubscription?.cancel();
    super.dispose();
  }
}
