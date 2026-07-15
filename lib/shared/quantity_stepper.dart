import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';

class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.onInputChanged,
    this.isBusy = false,
    this.width = 120,
    this.maxValue,
  });

  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<String>? onInputChanged;
  final bool isBusy;
  final double width;
  final int? maxValue;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late int _lastValue;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.value;
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _lastValue = widget.value;
      final newText = '${widget.value}';
      final oldText = '${oldWidget.value}';
      final isEditingDifferentText =
          _focusNode.hasFocus && _controller.text.isNotEmpty &&
              _controller.text != oldText;
      if (isEditingDifferentText) return;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commitInput();
  }

  void _commitInput() {
    final text = _controller.text.trim();
    final parsed = int.tryParse(text) ?? 0;
    if (parsed == _lastValue) {
      if (text.isEmpty) _controller.text = '$_lastValue';
      return;
    }
    final maxValue = widget.maxValue;
    if (maxValue != null && maxValue > 0 && parsed > maxValue) {
      widget.onInputChanged?.call(text);
      _controller.value = TextEditingValue(
        text: '$_lastValue',
        selection: TextSelection.collapsed(offset: '$_lastValue'.length),
      );
      return;
    }
    _lastValue = parsed;
    widget.onInputChanged?.call(text);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: widget.width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD6DCE8), width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          DecrementButton(
            isDisabled: widget.isBusy,
            onTap: widget.onDecrement,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !widget.isBusy && widget.onInputChanged != null,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _commitInput(),
            ),
          ),
          IncrementButton(
            isDisabled: widget.isBusy ||
                (widget.maxValue != null && widget.value >= widget.maxValue!),
            onTap: widget.onIncrement,
          ),
        ],
      ),
    );
  }
}

class IncrementButton extends StatelessWidget {
  const IncrementButton({
    super.key,
    required this.onTap,
    this.isDisabled = false,
  });

  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return _StepIconButton(
      icon: Icons.add,
      isDisabled: isDisabled,
      onTap: onTap,
    );
  }
}

class DecrementButton extends StatelessWidget {
  const DecrementButton({
    super.key,
    required this.onTap,
    this.isDisabled = false,
  });

  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return _StepIconButton(
      icon: Icons.remove,
      isDisabled: isDisabled,
      onTap: onTap,
    );
  }
}

class _StepIconButton extends StatelessWidget {
  const _StepIconButton({
    required this.icon,
    required this.onTap,
    required this.isDisabled,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(
          icon,
          size: 16,
          color: isDisabled ? Colors.grey.shade400 : const Color(0xFF0A243F),
        ),
      ),
    );
  }
}
