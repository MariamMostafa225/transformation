import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'data/remote/firebase_bootstrap.dart';
import 'data/repositories/cars_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  final repository = await CarsRepository.create();
  runApp(CarsApp(repository: repository));
}
