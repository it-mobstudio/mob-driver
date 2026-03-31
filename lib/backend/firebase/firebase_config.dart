import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDcrL4bIRIXIBkGcx2mO4XcL-BlWSA4i78",
          authDomain: "mob-mobile-app.firebaseapp.com",
          projectId: "mob-mobile-app",
          storageBucket: "mob-mobile-app.appspot.com",
          messagingSenderId: "535354268820",
          appId: "1:535354268820:web:3016911ac3330412722881",
          measurementId: "G-LGD2MP6CV3",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } on FirebaseException catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase init warning: ${e.code} ${e.message ?? ''}');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase init warning: $e');
    }
  }
}
