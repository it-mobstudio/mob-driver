import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';

// ─── Public Models ────────────────────────────────────────────────────────────

enum AiState { listening, afterSpeaking, suggestionsReady }

class AiChatMessage {
  const AiChatMessage(this.text, {required this.isUser});
  final String text;
  final bool isUser;
}

class AiProductSuggestion {
  const AiProductSuggestion({
    required this.index,
    required this.name,
    required this.price,
    this.imageUrl,
  });
  final int index;
  final String name;
  final String price;
  final String? imageUrl;
}

// ─── Design tokens ────────────────────────────────────────────────────────────

const _kBlue = Color(0xFF2973F0);
const _kDark = Color(0xFF0A243F);
const _kGreen = Color(0xFF4FB589);
const _kLightTeal = Color(0xFFC1EBD9);
const _kWaveTop = Color(0xFF8A3CFF);
const _kWaveBot = Color(0xFF6F79FF);
const _kBetaBg = Color(0xFFE8F0FF);
const _kUserBubble = Color(0xFFF2F2F2);
const _kHandle = Color(0xFFD0D4DC);
const _kGray = Color(0xFF718096);

// ─── AiSheet scaffold ─────────────────────────────────────────────────────────

class AiSheet extends StatelessWidget {
  const AiSheet({
    super.key,
    required this.aiState,
    required this.messages,
    required this.suggestions,
    required this.waveController,
    required this.onCollapse,
    required this.onPause,
    required this.onClose,
    required this.onClearChat,
    required this.onMicTap,
    required this.onShowDifferent,
  });

  final AiState aiState;
  final List<AiChatMessage> messages;
  final List<AiProductSuggestion> suggestions;
  final AnimationController waveController;
  final VoidCallback onCollapse;
  final VoidCallback onPause;
  final VoidCallback onClose;
  final VoidCallback onClearChat;
  final VoidCallback onMicTap;
  final VoidCallback onShowDifferent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AiDragHandle(),
          AiHeader(onCollapse: onCollapse),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (aiState) {
      case AiState.listening:
        return ListeningBody(
          waveController: waveController,
          onPause: onPause,
          onClose: onClose,
        );
      case AiState.afterSpeaking:
        return ChatBody(
          messages: messages,
          onClearChat: onClearChat,
          onMicTap: onMicTap,
        );
      case AiState.suggestionsReady:
        return SuggestionsBody(
          suggestions: suggestions,
          waveController: waveController,
          onShowDifferent: onShowDifferent,
          onPause: onPause,
          onClose: onClose,
        );
    }
  }
}

// ─── Drag handle ──────────────────────────────────────────────────────────────

class AiDragHandle extends StatelessWidget {
  const AiDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: _kHandle,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class AiHeader extends StatelessWidget {
  const AiHeader({super.key, required this.onCollapse});
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          // Three-dot vertical menu
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (_) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: const BoxDecoration(
                  color: _kDark,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Logo + label
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 26,
                  errorBuilder: (_, __, ___) => const MobDotIcon(size: 26),
                ),
                const SizedBox(width: 8),
                Text(
                  'Conversational AI',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kBetaBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'beta',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _kBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Collapse button
          GestureDetector(
            onTap: onCollapse,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: _kGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MOB dot-matrix icon ──────────────────────────────────────────────────────

class MobDotIcon extends StatelessWidget {
  const MobDotIcon({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFECF9F2),
        shape: BoxShape.circle,
      ),
      child: CustomPaint(painter: _DotGridPainter()),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _kGreen;
    const cols = 4, rows = 4;
    final cellW = size.width / (cols + 1);
    final cellH = size.height / (rows + 1);
    final r = math.min(cellW, cellH) * 0.22;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        canvas.drawCircle(
          Offset((col + 1) * cellW, (row + 1) * cellH),
          r,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Animated waveform ────────────────────────────────────────────────────────

class AiWaveform extends StatelessWidget {
  const AiWaveform({super.key, required this.controller});
  final AnimationController controller;

  static const _bars = 7;
  static const _minH = 5.0;
  static const _maxH = 34.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_bars, (i) {
            final phase = i / _bars;
            final h = _minH +
                (_maxH - _minH) *
                    ((math.sin((t + phase) * 2 * math.pi) + 1) / 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Container(
                width: 5,
                height: h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_kWaveTop, _kWaveBot],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Shared listen controls (bottom bar) ──────────────────────────────────────

class ListenControls extends StatelessWidget {
  const ListenControls({
    super.key,
    required this.waveController,
    required this.onPause,
    required this.onClose,
  });
  final AnimationController waveController;
  final VoidCallback onPause;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onPause,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.pause, color: _kDark, size: 26),
            ),
          ),
          AiWaveform(controller: waveController),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── State 1 — Listening body ─────────────────────────────────────────────────

class ListeningBody extends StatelessWidget {
  const ListeningBody({
    super.key,
    required this.waveController,
    required this.onPause,
    required this.onClose,
  });
  final AnimationController waveController;
  final VoidCallback onPause;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, _kLightTeal],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
            child: Row(
              children: [
                const MobDotIcon(size: 48),
                const SizedBox(width: 14),
                Text(
                  'Listening',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'You can speak now',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _kGray,
            ),
          ),
          const SizedBox(height: 24),
          ListenControls(
            waveController: waveController,
            onPause: onPause,
            onClose: onClose,
          ),
        ],
      ),
    );
  }
}

// ─── State 2 — After speaking body ───────────────────────────────────────────

class ChatBody extends StatelessWidget {
  const ChatBody({
    super.key,
    required this.messages,
    required this.onClearChat,
    required this.onMicTap,
  });
  final List<AiChatMessage> messages;
  final VoidCallback onClearChat;
  final VoidCallback onMicTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clear chat pill
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: GestureDetector(
            onTap: onClearChat,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: _kDark.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, size: 14, color: _kDark),
                  const SizedBox(width: 5),
                  Text(
                    'Clear chat',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _kDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Messages
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: messages.length,
            itemBuilder: (_, i) => MessageBubble(message: messages[i]),
          ),
        ),
        // Mic / AI button
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: GestureDetector(
              onTap: onMicTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kWaveTop, _kBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _kBlue.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'AI',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _kUserBubble,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            style: GoogleFonts.inter(fontSize: 14, color: _kDark),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MobDotIcon(size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                message.text,
                style: GoogleFonts.inter(fontSize: 14, color: _kDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── State 3 — Suggestions body ───────────────────────────────────────────────

class SuggestionsBody extends StatelessWidget {
  const SuggestionsBody({
    super.key,
    required this.suggestions,
    required this.waveController,
    required this.onShowDifferent,
    required this.onPause,
    required this.onClose,
  });
  final List<AiProductSuggestion> suggestions;
  final AnimationController waveController;
  final VoidCallback onShowDifferent;
  final VoidCallback onPause;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Product list card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _kBlue, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (int i = 0; i < suggestions.length; i++)
                  SuggestionRow(
                    suggestion: suggestions[i],
                    isLast: i == suggestions.length - 1,
                  ),
              ],
            ),
          ),
        ),
        // "Show different suggestion" pill
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: onShowDifferent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: _kBlue),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Show me different suggestion',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kBlue,
                ),
              ),
            ),
          ),
        ),
        Text(
          'You can speak now',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _kGray,
          ),
        ),
        const SizedBox(height: 12),
        ListenControls(
          waveController: waveController,
          onPause: onPause,
          onClose: onClose,
        ),
      ],
    );
  }
}

class SuggestionRow extends StatelessWidget {
  const SuggestionRow({
    super.key,
    required this.suggestion,
    this.isLast = false,
  });
  final AiProductSuggestion suggestion;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: _kBlue.withOpacity(0.18)),
              ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '${suggestion.index}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kGray,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: suggestion.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      suggestion.imageUrl!,
                      fit: BoxFit.contain,
                    ),
                  )
                : const Icon(
                    Icons.image_outlined,
                    color: Color(0xFFB0B8C1),
                    size: 26,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  suggestion.price,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kGreen,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _kGray, size: 20),
        ],
      ),
    );
  }
}
