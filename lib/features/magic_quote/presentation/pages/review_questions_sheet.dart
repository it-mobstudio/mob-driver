import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/bloc/magic_quote_bloc.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_widgets.dart';

/// "Submit for review" bottom sheet: fetches the dynamic questionnaire via
/// [MagicQuoteQuestionsRequested] and submits answers + a free-text note via
/// [MagicQuoteReviewSubmitRequested]. Mirrors the web app's
/// MagicQuote/ReviewQuestionsModal.jsx.
class ReviewQuestionsSheet extends StatefulWidget {
  const ReviewQuestionsSheet({
    super.key,
    required this.magicQuoteBloc,
    required this.quoteId,
    required this.onSubmitted,
  });

  final MagicQuoteBloc magicQuoteBloc;
  final String quoteId;
  final VoidCallback onSubmitted;

  @override
  State<ReviewQuestionsSheet> createState() => _ReviewQuestionsSheetState();
}

class _ReviewQuestionsSheetState extends State<ReviewQuestionsSheet> {
  static const _noteQuestionId = 'specific_preferences_note';

  final _noteController = TextEditingController();
  final Map<String, String> _answers = {};

  List<Map<String, dynamic>> _questions = const [];
  bool _isLoadingQuestions = true;
  bool _isSubmitting = false;
  String _fetchError = '';

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _fetchQuestions() {
    setState(() {
      _isLoadingQuestions = true;
      _fetchError = '';
    });
    widget.magicQuoteBloc.add(MagicQuoteQuestionsRequested());
  }

  List<Map<String, dynamic>> get _visibleQuestions =>
      _questions.where((q) => q['id'] != _noteQuestionId).toList();

  Map<String, dynamic>? get _noteQuestion {
    for (final question in _questions) {
      if (question['id'] == _noteQuestionId) return question;
    }
    return null;
  }

  bool get _hasUnansweredRequired => _visibleQuestions.any(
        (q) =>
            q['required'] == true &&
            (_answers[q['id']?.toString() ?? ''] ?? '').isEmpty,
      );

  bool get _isSubmitDisabled =>
      _isSubmitting ||
      _isLoadingQuestions ||
      _visibleQuestions.isEmpty ||
      _hasUnansweredRequired;

  void _onBlocState(BuildContext context, MagicQuoteState state) {
    if (state is MagicQuoteQuestionsLoaded) {
      setState(() {
        _questions = state.questions;
        _isLoadingQuestions = false;
      });
    } else if (state is MagicQuoteQuestionsError) {
      setState(() {
        _isLoadingQuestions = false;
        _fetchError = state.message;
      });
    } else if (state is MagicQuoteReviewSubmitting) {
      setState(() => _isSubmitting = true);
    } else if (state is MagicQuoteReviewSubmitted) {
      setState(() => _isSubmitting = false);
      widget.onSubmitted();
    } else if (state is MagicQuoteReviewError) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.message)));
    }
  }

  void _submit() {
    if (_isSubmitDisabled) return;
    final note = _noteController.text.trim();
    final answers = Map<String, String>.from(_answers);
    answers[_noteQuestionId] = note;
    widget.magicQuoteBloc.add(
      MagicQuoteReviewSubmitRequested(
        quoteId: widget.quoteId,
        questionnaireAnswers: answers,
        additionalInstructions: note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notePlaceholder = (_noteQuestion?['placeholder']?.toString() ?? '')
        .trim();
    final noteSubtitle = (_noteQuestion?['question']?.toString() ?? '').trim();

    return BlocListener<MagicQuoteBloc, MagicQuoteState>(
      bloc: widget.magicQuoteBloc,
      listener: _onBlocState,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: MagicQuoteColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            text: 'Additional instructions ',
                            style: GoogleFonts.inter(
                              color: MagicQuoteColors.navy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            children: [
                              TextSpan(
                                text: '(optional)',
                                style: GoogleFonts.inter(
                                  color: MagicQuoteColors.muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          noteSubtitle.isNotEmpty
                              ? noteSubtitle
                              : 'Have any specific preferences or noticed something '
                                  'missing? Drop us a note!',
                          style: GoogleFonts.inter(
                            color: MagicQuoteColors.muted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _noteController,
                          minLines: 3,
                          maxLines: 4,
                          style: GoogleFonts.inter(color: MagicQuoteColors.navy, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: notePlaceholder.isNotEmpty
                                ? notePlaceholder
                                : 'e.g. need a specific brand, flagged a missing '
                                    'item, delivery preferences...',
                            hintStyle:
                                GoogleFonts.inter(color: MagicQuoteColors.muted, fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF7F9FC),
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: MagicQuoteColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: MagicQuoteColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: MagicQuoteColors.blue, width: 1.6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _questionsBody(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: MagicQuoteColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: TextButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: MagicQuoteColors.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitDisabled ? null : _submit,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: MagicQuoteColors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: MagicQuoteColors.blue.withValues(alpha: 0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Submit for review',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionsBody() {
    if (_isLoadingQuestions) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_fetchError.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fetchError,
            style: GoogleFonts.inter(color: const Color(0xFFE14040)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _fetchQuestions, child: const Text('Retry')),
        ],
      );
    }
    if (_visibleQuestions.isEmpty) {
      return Text(
        'No questions are available right now.',
        style: GoogleFonts.inter(color: MagicQuoteColors.muted, fontSize: 13),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _visibleQuestions.map(_questionTile).toList(),
    );
  }

  Widget _questionTile(Map<String, dynamic> question) {
    final id = question['id']?.toString() ?? '';
    final label = question['question']?.toString() ?? '';
    final isRequired = question['required'] == true;
    final options = (question['options'] as List? ?? const [])
        .whereType<Map>()
        .map((o) => Map<String, dynamic>.from(o))
        .toList();
    final selected = _answers[id];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              style: GoogleFonts.inter(
                color: MagicQuoteColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: GoogleFonts.inter(color: const Color(0xFFE14040)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (options.length <= 3)
            Row(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _optionButtonFor(id, options[i], selected),
                  ),
                ],
              ],
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options
                  .map((opt) => _optionButtonFor(id, opt, selected))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _optionButtonFor(
    String questionId,
    Map<String, dynamic> option,
    String? selected,
  ) {
    final value = option['value']?.toString() ?? option['label']?.toString() ?? '';
    final label = option['label']?.toString() ?? value;
    return _OptionButton(
      label: label,
      isSelected: selected == value,
      onTap: () => setState(() => _answers[questionId] = value),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minWidth: 100),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? MagicQuoteColors.blue : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? MagicQuoteColors.blue : MagicQuoteColors.border),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : MagicQuoteColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
