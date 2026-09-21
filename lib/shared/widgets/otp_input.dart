import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A row of digit boxes backed by ONE hidden text field.
///
/// A single field (instead of a controller per box) means pasting a whole
/// code, backspacing, and the OS's SMS autofill (`oneTimeCode`) all behave
/// like a normal text input, and there's no focus juggling between boxes.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.enabled = true,
    this.autofocus = true,
  });

  final int length;

  /// Called once each time the box row becomes full.
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autofocus;

  @override
  State<OtpInput> createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> {
  static const _ink = Color(0xFF0A243F);
  static const _idleBorder = Color(0xFFDFE4EC);

  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _lastCompleted = '';

  String get code => _controller.text;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    setState(() {});
    widget.onChanged?.call(text);
    if (text.length == widget.length) {
      if (text != _lastCompleted) {
        _lastCompleted = text;
        widget.onCompleted(text);
      }
    } else {
      _lastCompleted = '';
    }
  }

  /// Empties the boxes and refocuses (e.g. after a wrong code).
  void clear() {
    _controller.clear();
    _lastCompleted = '';
    if (widget.enabled) _focus.requestFocus();
  }

  /// Fills the boxes programmatically (e.g. the dev-mode OTP hint).
  void setCode(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final clipped =
        digits.length > widget.length ? digits.substring(0, widget.length) : digits;
    _controller.value = TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final activeIndex = text.length.clamp(0, widget.length - 1);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? () => _focus.requestFocus() : null,
      child: Stack(children: [
        // The real input. Painted invisible but still focusable; the boxes
        // below just reflect its text.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              showCursor: false,
              enableInteractiveSelection: false,
              decoration: const InputDecoration(
                  border: InputBorder.none, counterText: ''),
            ),
          ),
        ),
        IgnorePointer(
          child: Row(children: [
            for (var i = 0; i < widget.length; i++) ...[
              Expanded(
                child: _Box(
                  digit: i < text.length ? text[i] : '',
                  active: _focus.hasFocus && widget.enabled && i == activeIndex,
                  enabled: widget.enabled,
                ),
              ),
              if (i < widget.length - 1) const SizedBox(width: 10),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.digit, required this.active, required this.enabled});
  final String digit;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? OtpInputState._ink : OtpInputState._idleBorder,
            width: active ? 1.6 : 1,
          ),
        ),
        child: Text(digit,
            style: const TextStyle(
                color: OtpInputState._ink,
                fontFamily: 'Inter',
                fontSize: 21,
                fontWeight: FontWeight.w700)),
      );
}
