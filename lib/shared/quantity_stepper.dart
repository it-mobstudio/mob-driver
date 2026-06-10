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
  });

  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<String>? onInputChanged;
  final bool isBusy;
  final double width;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final newText = '${widget.value}';
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: widget.width,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE1E6ED)),
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecrementButton(
            isDisabled: widget.isBusy,
            onTap: widget.onDecrement,
          ),
          SizedBox(
            width: 36,
            child: TextField(
              controller: _controller,
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
              onChanged: widget.onInputChanged,
            ),
          ),
          IncrementButton(
            isDisabled: widget.isBusy,
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
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: isDisabled ? Colors.grey : null,
        ),
      ),
    );
  }
}
