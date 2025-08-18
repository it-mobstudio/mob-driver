// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_azure_speech/flutter_azure_speech.dart';
// // import 'package:azure_speech_recognition_null_safety/azure_speech_recognition_null_safety.dart';

// typedef TranscriptionHandler = void Function(String text);

// class AzureSttService with ChangeNotifier {
//   AzureSttService({
//     required this.subscriptionKey,
//     required this.region,
//     this.defaultLocale = 'en-IN',
//     this.onTranscription,
//   });

//   final String subscriptionKey;
//   final String region;
//   final String defaultLocale;
//   final TranscriptionHandler? onTranscription;

//   final _plugin = FlutterAzureSpeech();
//   bool _initialized = false;
//   bool _isListening = false;
//   bool get isListening => _isListening;

//   Future<void> initialize() async {
//     if (_initialized) return;
//     await _plugin.initialize(subscriptionKey, region);
//     _initialized = true;
//   }

//   /// Single-shot recognition: records until user stops speaking, returns final text.
//   Future<String?> listenOnce({String? locale}) async {
//     await initialize();
//     if (_isListening) return null;

//     _isListening = true;
//     notifyListeners();

//     try {
//       final result = await _plugin.getSpeechToText(locale ?? defaultLocale);
//       if (result != null && result.trim().isNotEmpty) {
//         onTranscription?.call(result.trim());
//       }
//       return result;
//     } finally {
//       _isListening = false;
//       notifyListeners();
//     }
//   }
// }
