import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Starts Firebase (analytics, crash reporting, push). Native builds read
/// their config from google-services.json / GoogleService-Info.plist; the web
/// build has no such file, so its options are here.
abstract final class FirebaseInitializer {
  static const _webOptions = FirebaseOptions(
    apiKey: 'AIzaSyDcrL4bIRIXIBkGcx2mO4XcL-BlWSA4i78',
    authDomain: 'mob-mobile-app.firebaseapp.com',
    projectId: 'mob-mobile-app',
    storageBucket: 'mob-mobile-app.appspot.com',
    messagingSenderId: '535354268820',
    appId: '1:535354268820:web:3016911ac3330412722881',
    measurementId: 'G-LGD2MP6CV3',
  );

  /// Never throws: the app runs without Firebase, just unmeasured.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(options: kIsWeb ? _webOptions : null);
    } catch (e) {
      if (kDebugMode) debugPrint('Firebase did not start: $e');
    }
  }
}
