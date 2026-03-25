import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

class AzureConversationalAI extends StatefulWidget {
  final String azureKey;
  final String azureRegion;
  final String locale;
  const AzureConversationalAI({
    super.key,
    required this.azureKey,
    required this.azureRegion,
    this.locale = 'en-US',
  });

  @override
  State<AzureConversationalAI> createState() => _AzureConversationalAIState();
}

class _AzureConversationalAIState extends State<AzureConversationalAI> {
  bool _isRecording = false;
  String _transcription = '';
  String _error = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Record _recorder = Record();
  String? _audioFilePath;

  Future<void> _requestMicPermission() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() => _error = 'Microphone permission denied');
      throw Exception('Microphone permission denied');
    }
  }

  Future<void> _startRecording() async {
    try {
      await _requestMicPermission();
      Directory tempDir = await getTemporaryDirectory();
      String filePath = '${tempDir.path}/azure_record.wav';
      await _recorder.start(
        path: filePath,
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        samplingRate: 16000,
      );
      setState(() {
        _isRecording = true;
        _audioFilePath = filePath;
        _transcription = '';
        _error = '';
      });
    } catch (e) {
      setState(() => _error = 'Recording error: $e');
    }
  }

  Future<void> _stopRecordingAndTranscribe() async {
    try {
      await _recorder.stop();
      setState(() {
        _isRecording = false;
      });
      if (_audioFilePath != null) {
        await _sendToAzureSTT(_audioFilePath!);
      }
    } catch (e) {
      setState(() => _error = 'Stop recording error: $e');
    }
  }

  Future<void> _sendToAzureSTT(String filePath) async {
    setState(() => _transcription = 'Transcribing...');
    final url =
        'https://${widget.azureRegion}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=${widget.locale}';
    final audioBytes = await File(filePath).readAsBytes();
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Ocp-Apim-Subscription-Key': widget.azureKey,
        'Content-Type': 'audio/wav',
      },
      body: audioBytes,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _transcription = data is Map && data['DisplayText'] != null
            ? data['DisplayText'].toString()
            : 'No transcription.';
      });
    } else {
      setState(() =>
          _error = 'Azure STT error: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> _sendToAzureTTS(String text) async {
    setState(() => _error = '');
    final url =
        'https://${widget.azureRegion}.tts.speech.microsoft.com/cognitiveservices/v1';
    final ssml = '''
<speak version="1.0" xml:lang="${widget.locale}">
	<voice xml:lang="${widget.locale}" xml:gender="Female" name="${widget.locale}-JennyNeural">
		$text
	</voice>
</speak>
''';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Ocp-Apim-Subscription-Key': widget.azureKey,
        'Content-Type': 'application/ssml+xml',
        'X-Microsoft-OutputFormat': 'riff-24khz-16bit-mono-pcm',
      },
      body: ssml,
    );
    if (response.statusCode == 200) {
      Directory tempDir = await getTemporaryDirectory();
      String ttsPath = '${tempDir.path}/azure_tts.wav';
      await File(ttsPath).writeAsBytes(response.bodyBytes);
      await _audioPlayer.setFilePath(ttsPath);
      await _audioPlayer.play();
    } else {
      setState(() =>
          _error = 'Azure TTS error: ${response.statusCode} ${response.body}');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error.isNotEmpty)
            Text(_error, style: const TextStyle(color: Colors.red)),
          if (_transcription.isNotEmpty)
            Text(_transcription, style: const TextStyle(fontSize: 18)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isRecording ? null : _startRecording,
                child: Text(_isRecording ? 'Recording...' : 'Start Recording'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isRecording ? _stopRecordingAndTranscribe : null,
                child: const Text('Stop & Transcribe'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_transcription.isNotEmpty && !_isRecording)
            ElevatedButton(
              onPressed: () => _sendToAzureTTS(_transcription),
              child: const Text('Play AI Response'),
            ),
        ],
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;

// enum AIState { idle, listening, replying, suggestions }

// class AIBottomSheet extends StatefulWidget {
//   const AIBottomSheet({
//     super.key,
//     this.onTranscription,
//     this.defaultLocale = 'en_IN', // or hi_IN, ta_IN, etc.
//   });

//   final void Function(String text)? onTranscription;
//   final String defaultLocale;

//   @override
//   State<AIBottomSheet> createState() => _AIBottomSheetState();
// }

// class _AIBottomSheetState extends State<AIBottomSheet>
//     with SingleTickerProviderStateMixin {
//   AIState state = AIState.idle;

//   late final AnimationController _bars = AnimationController(
//     vsync: this,
//     duration: const Duration(milliseconds: 900),
//   )..repeat(reverse: true);

//   // STT
//   final stt.SpeechToText _speech = stt.SpeechToText();
//   bool _speechReady = false;

//   // TTS
//   final FlutterTts _flutterTts = FlutterTts();

//   String _lastUserUtterance = '';
//   String _agentReply = '';

//   @override
//   void initState() {
//     super.initState();
//     _initSpeech();
//     _initTTS();
//   }

//   Future<void> _initSpeech() async {
//     final available = await _speech.initialize(
//       onStatus: (s) => debugPrint("STT status: $s"),
//       onError: (e) => debugPrint("STT error: $e"),
//     );
//     if (mounted) setState(() => _speechReady = available);
//   }

//   Future<void> _initTTS() async {
//     await _flutterTts.setLanguage(widget.defaultLocale.replaceAll('_', '-'));
//     await _flutterTts.setSpeechRate(0.9);
//     await _flutterTts.setPitch(1.0);
//   }

//   Future<void> _speak(String text) async {
//     if (text.isEmpty) return;
//     await _flutterTts.stop();
//     await _flutterTts.speak(text);
//   }

//   @override
//   void dispose() {
//     _bars.dispose();
//     _flutterTts.stop();
//     super.dispose();
//   }

//   Future<void> requestMicPermission() async {
//     var status = await Permission.microphone.request();
//     if (!status.isGranted) {
//       throw Exception('Microphone permission denied');
//     }
//   }

//   Future<void> _startListening() async {
//     try {
//       await requestMicPermission();
//     } catch (_) {
//       return;
//     }

//     if (!_speechReady) {
//       await _initSpeech();
//       if (!_speechReady) return;
//     }

//     setState(() {
//       state = AIState.listening;
//       _lastUserUtterance = '';
//       _agentReply = '';
//     });

//     _speech.listen(
//       localeId: widget.defaultLocale,
//       onResult: (result) async {
//         if (result.finalResult) {
//           final text = result.recognizedWords;
//           debugPrint("🎤 User: $text");
//           if (text.isNotEmpty) {
//             _lastUserUtterance = text;
//             widget.onTranscription?.call(text);
//             await _fetchAIReply(text);
//           } else {
//             setState(() => state = AIState.idle);
//           }
//         }
//       },
//     );
//   }

//   Future<void> _fetchAIReply(String userText) async {
//     setState(() => state = AIState.replying);

//     // Replace this dummy text with a real backend call
//     final reply =
//         "I found some great options for '$userText'. Would you like to see them?";

//     _agentReply = reply;
//     await _speak(reply);

//     if (!mounted) return;
//     setState(() {});
//   }

//   void _stopOrContinueFlow() {
//     _speech.stop();
//     setState(() => state = AIState.suggestions);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.55,
//       minChildSize: 0.36,
//       maxChildSize: 0.95,
//       builder: (ctx, controller) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//             boxShadow: [
//               BoxShadow(
//                 color: Color(0x33000000),
//                 blurRadius: 16,
//                 offset: Offset(0, -4),
//               )
//             ],
//           ),
//           child: Column(
//             children: [
//               // Pull handle
//               Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Container(
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.black12,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),

//               // Header card
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
//                 child: _HeaderCard(
//                   onCollapse: () => Navigator.pop(context),
//                   onMenu: () {},
//                 ),
//               ),

//               // Body
//               Expanded(
//                 child: ListView(
//                   controller: controller,
//                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//                   children: [
//                     // if (state == AIState.idle) _idleBody(),
//                     if (state == AIState.listening) _listeningBody(),
//                     if (state == AIState.replying) _replyingBody(),
//                     if (state == AIState.suggestions) _suggestionsBody(),
//                   ],
//                 ),
//               ),

//               // Footer
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
//                 child: _footerControls(),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ======= States =======

//   Widget _idleBody() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         const SizedBox(height: 8),
//         Text('Tap to start', style: GoogleFonts.inter(color: Colors.black54)),
//         const SizedBox(height: 12),
//         _BigRoundButton(
//           icon: Icons.mic,
//           label: 'AI',
//           onTap: _startListening,
//         ),
//       ],
//     );
//   }

//   Widget _listeningBody() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const _AgentGlyph(status: 'Listening'),
//         const SizedBox(height: 24),
//         Center(child: _WaveBars(controller: _bars)),
//         const SizedBox(height: 24),
//         const Center(child: Text('You can speak now')),
//       ],
//     );
//   }

//   Widget _replyingBody() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const _AgentGlyph(status: 'Responding…'),
//         const SizedBox(height: 16),
//         if (_lastUserUtterance.isNotEmpty) _bubbleFromUser(_lastUserUtterance),
//         const SizedBox(height: 12),
//         _bubbleFromAgent(_agentReply),
//       ],
//     );
//   }

//   Widget _suggestionsBody() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const _AgentGlyph(status: ''),
//         const SizedBox(height: 8),
//         Text('₹3539  /unit',
//             style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
//         const SizedBox(height: 12),
//         _suggestionList(),
//         const SizedBox(height: 12),
//         OutlinedButton(
//           onPressed: () {
//             setState(() => state = AIState.listening);
//             _startListening();
//           },
//           style: OutlinedButton.styleFrom(
//             minimumSize: const Size.fromHeight(44),
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//           child: const Text('Show me a different suggestion'),
//         ),
//       ],
//     );
//   }

//   // ======= Footer =======

//   Widget _footerControls() {
//     switch (state) {
//       case AIState.idle:
//         return _micFooterButton(onTap: _startListening);
//       case AIState.listening:
//         return Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             _circleIcon(Icons.pause,
//                 onTap: () => setState(() => state = AIState.replying)),
//             _WaveBars(controller: _bars),
//             _circleIcon(Icons.close, onTap: () => Navigator.pop(context)),
//           ],
//         );
//       case AIState.replying:
//         return Center(child: _squareStop(onTap: _stopOrContinueFlow));
//       case AIState.suggestions:
//         return _micFooterButton(onTap: _startListening);
//     }
//   }

//   // ======= Pieces =======

//   Widget _bubbleFromUser(String text) => Align(
//         alignment: Alignment.centerRight,
//         child: Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: const Color(0xFFF1F4F8),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Text(text),
//         ),
//       );

//   Widget _bubbleFromAgent(String text) => Padding(
//         padding: const EdgeInsets.only(right: 32),
//         child: Text(text, style: GoogleFonts.inter(fontSize: 15)),
//       );

//   Widget _suggestionList() {
//     return Container(
//       decoration: BoxDecoration(
//         border: Border.all(color: const Color(0xFF2B7FFF)),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Column(
//         children: List.generate(4, (i) {
//           return Column(
//             children: [
//               ListTile(
//                 leading: CircleAvatar(
//                   backgroundColor: const Color(0xFFF2F6F9),
//                   child: Text('${i + 1}'),
//                 ),
//                 title: const Text(
//                   'Century Ply Sainik MR CenturyPly\n7 ft x 4 ft Plywood – 12 mm',
//                 ),
//                 subtitle: const Text('₹1660  /sheet'),
//                 trailing: const CircleAvatar(
//                   radius: 16,
//                   backgroundColor: Color(0xFFF1F4F8),
//                   child: Icon(Icons.chevron_right,
//                       size: 18, color: Colors.black87),
//                 ),
//               ),
//               if (i != 3) const Divider(height: 1),
//             ],
//           );
//         }),
//       ),
//     );
//   }

//   Widget _micFooterButton({required VoidCallback onTap}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         const SizedBox(height: 8),
//         Text('Tap to start', style: GoogleFonts.inter(color: Colors.black54)),
//         const SizedBox(height: 12),
//         _BigRoundButton(icon: Icons.mic, label: 'AI', onTap: onTap),
//       ],
//     );
//   }

//   Widget _circleIcon(IconData icon, {required VoidCallback onTap}) {
//     return InkResponse(
//       onTap: onTap,
//       radius: 28,
//       child: Container(
//         height: 48,
//         width: 48,
//         decoration: const BoxDecoration(
//           shape: BoxShape.circle,
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
//           ],
//         ),
//         child: Icon(icon, size: 24),
//       ),
//     );
//   }

//   Widget _squareStop({required VoidCallback onTap}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: 52,
//         width: 52,
//         decoration:
//             const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
//         child: const Icon(Icons.stop, color: Colors.white),
//       ),
//     );
//   }
// }

// // ========== Small widgets ==========

// class _HeaderCard extends StatelessWidget {
//   const _HeaderCard({required this.onCollapse, required this.onMenu});
//   final VoidCallback onCollapse;
//   final VoidCallback onMenu;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFF7F9FC),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       padding: const EdgeInsets.all(12),
//       child: Row(
//         children: [
//           _dotMenu(onMenu),
//           const SizedBox(width: 10),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('mob···  ',
//                   style: GoogleFonts.inter(
//                       fontSize: 18, fontWeight: FontWeight.w800)),
//               Text('Conversational AI',
//                   style:
//                       GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
//             ],
//           ),
//           const SizedBox(width: 6),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//             decoration: BoxDecoration(
//               color: const Color(0xFFEFF3FF),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: const Text('beta', style: TextStyle(fontSize: 11)),
//           ),
//           const Spacer(),
//           InkWell(
//             onTap: onCollapse,
//             borderRadius: BorderRadius.circular(20),
//             child: const CircleAvatar(
//               radius: 16,
//               backgroundColor: Color(0xFFEAF7EE),
//               child: Icon(Icons.keyboard_arrow_down, color: Colors.black87),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _dotMenu(VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         padding: const EdgeInsets.all(6),
//         decoration:
//             const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
//         child: const Icon(Icons.more_horiz, size: 20),
//       ),
//     );
//   }
// }

// class _AgentGlyph extends StatelessWidget {
//   const _AgentGlyph({required this.status});
//   final String status;
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           height: 28,
//           width: 28,
//           decoration: const BoxDecoration(
//             shape: BoxShape.circle,
//             color: Color(0xFFE8F1FF),
//           ),
//           child: const Icon(Icons.blur_circular, size: 18, color: Colors.teal),
//         ),
//         const SizedBox(width: 10),
//         Text(status, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
//       ],
//     );
//   }
// }

// class _WaveBars extends StatelessWidget {
//   const _WaveBars({required this.controller});
//   final AnimationController controller;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 36,
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: List.generate(20, (i) {
//           final t = (i % 5) / 5.0;
//           return AnimatedBuilder(
//             animation: controller,
//             builder: (_, __) {
//               final h = 8 +
//                   24 * (0.5 + 0.5 * (controller.value - t).abs() * -1 + 0.5);
//               return Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 2),
//                 child: Container(
//                   width: 3,
//                   height: h.clamp(8, 32),
//                   decoration: BoxDecoration(
//                     color: Colors.indigo,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               );
//             },
//           );
//         }),
//       ),
//     );
//   }
// }

// class _BigRoundButton extends StatelessWidget {
//   const _BigRoundButton(
//       {required this.icon, required this.label, required this.onTap});
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             width: 68,
//             height: 68,
//             decoration: const BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: LinearGradient(
//                 colors: [Color(0xFF6F79FF), Color(0xFF8A3CFF)],
//               ),
//             ),
//             child: Icon(icon, color: Colors.white, size: 28),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
//       ],
//     );
//   }
// }
