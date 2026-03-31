import 'dart:async';
import 'package:flutter/material.dart';
import 'ai_sheet_ui.dart';

class AzureConversationalAI extends StatefulWidget {
  const AzureConversationalAI({
    super.key,
    required this.azureKey,
    required this.azureRegion,
    this.locale = 'en-US',
  });

  final String azureKey;
  final String azureRegion;
  final String locale;

  @override
  State<AzureConversationalAI> createState() =>
      _AzureConversationalAIWebState();
}

class _AzureConversationalAIWebState extends State<AzureConversationalAI>
    with SingleTickerProviderStateMixin {
  AiState _aiState = AiState.listening;
  final List<AiChatMessage> _messages = [];
  final List<AiProductSuggestion> _suggestions = [];
  late final AnimationController _waveController;
  Timer? _demoTimer;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _startDemoListening();
  }

  void _startDemoListening() {
    _demoTimer?.cancel();
    _demoTimer = Timer(const Duration(seconds: 3), _onDemoSpeechComplete);
  }

  void _onDemoSpeechComplete() {
    if (!mounted) return;
    setState(() {
      _messages.add(
        const AiChatMessage('I want a premium showerhead', isUser: true),
      );
      _aiState = AiState.afterSpeaking;
    });
    _demoTimer = Timer(
      const Duration(milliseconds: 900),
      _onDemoResponseReady,
    );
  }

  void _onDemoResponseReady() {
    if (!mounted) return;
    setState(() {
      _messages.add(const AiChatMessage(
        'Sure! There are a lot of options from Hindware. Choose to add to your cart?',
        isUser: false,
      ));
      _suggestions
        ..clear()
        ..addAll(const [
          AiProductSuggestion(
            index: 1,
            name: 'Hindware Overhead Round Shower',
            price: '₹2,499/unit',
          ),
          AiProductSuggestion(
            index: 2,
            name: 'Cera Rain Shower Kit Pro',
            price: '₹3,199/unit',
          ),
          AiProductSuggestion(
            index: 3,
            name: 'Grohe Euphoria Panel System',
            price: '₹8,999/unit',
          ),
          AiProductSuggestion(
            index: 4,
            name: 'Jaquar ABS Overhead Showerhead',
            price: '₹1,899/unit',
          ),
        ]);
      _aiState = AiState.suggestionsReady;
    });
  }

  void _clearChat() {
    _demoTimer?.cancel();
    setState(() {
      _messages.clear();
      _suggestions.clear();
      _aiState = AiState.listening;
    });
    _startDemoListening();
  }

  void _restartListening() {
    _demoTimer?.cancel();
    setState(() {
      _suggestions.clear();
      _aiState = AiState.listening;
    });
    _startDemoListening();
  }

  void _close() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AiSheet(
      aiState: _aiState,
      messages: _messages,
      suggestions: _suggestions,
      waveController: _waveController,
      onCollapse: _close,
      onPause: _close,
      onClose: _close,
      onClearChat: _clearChat,
      onMicTap: _restartListening,
      onShowDifferent: _restartListening,
    );
  }
}
