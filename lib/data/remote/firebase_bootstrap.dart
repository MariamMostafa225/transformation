import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class FirebaseBootstrap {
  static bool initialized = false;
  static String? initializationError;

  static Future<void> initialize() async {
    initializationError = null;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
      initialized = true;
    } on FirebaseException catch (error) {
      initialized = false;
      initializationError = error.message ?? error.code;
    } catch (error) {
      initialized = false;
      initializationError = error.toString();
    }
  }
}
