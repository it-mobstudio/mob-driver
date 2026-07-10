import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.controller,
    this.initialValue,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.suffixIcon,
    this.prefixIcon,
    this.prefixText,
    this.showClearButton = true,
    this.focusNode,
    this.autofillHints,
    this.floatingLabelBehavior,
  }) : assert(
          controller == null || initialValue == null,
          'Provide either controller or initialValue, not both.',
        );

  final String? label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? prefixText;
  final bool showClearButton;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final FloatingLabelBehavior? floatingLabelBehavior;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late bool _ownsController;
  late bool _ownsFocusNode;
  late bool _showClearButton;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _showClearButton = _shouldShowClearButton;
    _controller.addListener(_refreshClearButton);
    _focusNode.addListener(_refreshClearButton);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_refreshClearButton);
      if (_ownsController) _controller.dispose();
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_refreshClearButton);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_refreshClearButton);
      if (_ownsFocusNode) _focusNode.dispose();
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_refreshClearButton);
    }
    final nextShowClearButton = _shouldShowClearButton;
    if (_showClearButton != nextShowClearButton) {
      _showClearButton = nextShowClearButton;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_refreshClearButton);
    _focusNode.removeListener(_refreshClearButton);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  bool get _shouldShowClearButton =>
      widget.showClearButton &&
      widget.enabled &&
      !widget.readOnly &&
      _focusNode.hasFocus &&
      _controller.text.isNotEmpty;

  void _refreshClearButton() {
    final nextShowClearButton = _shouldShowClearButton;
    if (_showClearButton == nextShowClearButton) return;
    if (mounted) {
      setState(() => _showClearButton = nextShowClearButton);
    } else {
      _showClearButton = nextShowClearButton;
    }
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        textCapitalization: widget.textCapitalization,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onFieldSubmitted,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        obscureText: widget.obscureText,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        minLines: widget.minLines,
        autofillHints: widget.autofillHints,
        cursorColor: AppTextFieldColors.primaryText,
        cursorErrorColor: AppTextFieldColors.error,
        style: AppTextFieldStyles.inputText,
        decoration: appTextFieldDecoration(
          label: widget.label,
          hintText: widget.hintText,
          suffixIcon: _showClearButton
              ? _ClearTextButton(onPressed: _clear)
              : widget.suffixIcon,
          prefixIcon: widget.prefixIcon,
          prefixText: widget.prefixText,
          floatingLabelBehavior: widget.floatingLabelBehavior,
        ),
      ),
    );
  }
}

InputDecoration appTextFieldDecoration({
  String? label,
  String? hintText,
  Widget? suffixIcon,
  Widget? prefixIcon,
  String? prefixText,
  FloatingLabelBehavior? floatingLabelBehavior,
}) {
  return InputDecoration(
    labelText: (label == null || label.isEmpty) ? null : label,
    hintText: hintText,
    floatingLabelBehavior: floatingLabelBehavior,
    labelStyle: AppTextFieldStyles.label,
    floatingLabelStyle: AppTextFieldStyles.stateLabel,
    hintStyle: AppTextFieldStyles.hint,
    errorStyle: AppTextFieldStyles.error,
    prefixText: prefixText,
    prefixStyle: AppTextFieldStyles.inputText,
    contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    // constraints: const BoxConstraints(minHeight: 48),
    suffixIcon: suffixIcon,
    prefixIcon: prefixIcon,
    suffixIconConstraints: const BoxConstraints(minHeight: 48, minWidth: 48),
    prefixIconConstraints: const BoxConstraints(minHeight: 48, minWidth: 48),
    border: _inputBorder(),
    enabledBorder: _inputBorder(),
    focusedBorder: _inputBorder(
      color: AppTextFieldColors.primaryText,
      width: 1.5,
    ),
    errorBorder: _inputBorder(color: AppTextFieldColors.error, width: 1.5),
    focusedErrorBorder: _inputBorder(
      color: AppTextFieldColors.error,
      width: 1.5,
    ),
    disabledBorder: _inputBorder(color: AppTextFieldColors.disabledBorder),
  );
}

abstract final class AppTextFieldColors {
  static const Color surface = Colors.white;
  static const Color primaryText = Color(0xFF0A243F);
  static const Color inputBorder = Color(0xFFDFE4EC);
  static const Color inputLabel = Color(0xFF767C8F);
  static const Color inputHint = Color(0xFFAFB4C0);
  static const Color clearBackground = Color(0xFFB5B5B5);
  static const Color error = Color(0xFFC13615);
  static const Color disabledBorder = Color(0xFFE8ECF2);
}

abstract final class AppTextFieldStyles {
  static TextStyle get inputText => GoogleFonts.inter(
        color: AppTextFieldColors.primaryText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
      );

  static TextStyle get label => GoogleFonts.inter(
        color: AppTextFieldColors.inputLabel,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 14 / 11,
      );

  static TextStyle get stateLabel => WidgetStateTextStyle.resolveWith(
        (states) {
          final color = states.contains(WidgetState.error)
              ? AppTextFieldColors.error
              : states.contains(WidgetState.focused)
                  ? AppTextFieldColors.primaryText
                  : AppTextFieldColors.inputLabel;
          return label.copyWith(color: color);
        },
      );

  static TextStyle get hint => GoogleFonts.inter(
        color: AppTextFieldColors.inputHint,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
      );

  static TextStyle get error => GoogleFonts.inter(
        color: AppTextFieldColors.error,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 14 / 11,
      );
}

class _ClearTextButton extends StatelessWidget {
  const _ClearTextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Clear text',
      child: IconButton(
        onPressed: onPressed,
        splashRadius: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
        icon: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: AppTextFieldColors.clearBackground,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close_rounded,
            color: AppTextFieldColors.surface,
            size: 12,
          ),
        ),
      ),
    );
  }
}

OutlineInputBorder _inputBorder({
  Color color = AppTextFieldColors.inputBorder,
  double width = 1,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: width),
  );
}
