import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';
import 'package:m_o_b_demand_side/features/magic_quote/domain/repositories/magic_quote_repository.dart';
import 'package:m_o_b_demand_side/features/magic_quote/domain/utils/magic_quote_status.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class MagicQuoteEvent {}

final class MagicQuoteSubmitRequested extends MagicQuoteEvent {
  MagicQuoteSubmitRequested({
    required this.payload,
    required this.images,
  });

  final Map<String, dynamic> payload;
  final List<FFUploadedFile> images;
}

final class MagicQuoteQuestionsRequested extends MagicQuoteEvent {}

final class MagicQuoteReviewSubmitRequested extends MagicQuoteEvent {
  MagicQuoteReviewSubmitRequested({
    required this.quoteId,
    required this.questionnaireAnswers,
    required this.additionalInstructions,
  });

  final String quoteId;
  final Map<String, dynamic> questionnaireAnswers;
  final String additionalInstructions;
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class MagicQuoteState {}

final class MagicQuoteInitial extends MagicQuoteState {}

final class MagicQuoteSubmitting extends MagicQuoteState {}

final class MagicQuoteProgress extends MagicQuoteState {
  MagicQuoteProgress({required this.status, required this.steps});
  final String status;
  final List<String> steps;
}

final class MagicQuoteSubmitted extends MagicQuoteState {
  MagicQuoteSubmitted(this.response);
  final Map<String, dynamic> response;
}

final class MagicQuoteError extends MagicQuoteState {
  MagicQuoteError(this.message);
  final String message;
}

final class MagicQuoteQuestionsLoading extends MagicQuoteState {}

final class MagicQuoteQuestionsLoaded extends MagicQuoteState {
  MagicQuoteQuestionsLoaded(this.questions);
  final List<Map<String, dynamic>> questions;
}

final class MagicQuoteQuestionsError extends MagicQuoteState {
  MagicQuoteQuestionsError(this.message);
  final String message;
}

final class MagicQuoteReviewSubmitting extends MagicQuoteState {}

final class MagicQuoteReviewSubmitted extends MagicQuoteState {}

final class MagicQuoteReviewError extends MagicQuoteState {
  MagicQuoteReviewError(this.message);
  final String message;
}

// ── BLoC (factory) ───────────────────────────────────────────────────────────

class MagicQuoteBloc extends Bloc<MagicQuoteEvent, MagicQuoteState> {
  MagicQuoteBloc(this._repository) : super(MagicQuoteInitial()) {
    on<MagicQuoteSubmitRequested>(_onMagicQuoteSubmit);
    on<MagicQuoteQuestionsRequested>(_onMagicQuoteQuestions);
    on<MagicQuoteReviewSubmitRequested>(_onMagicQuoteReviewSubmit);
  }

  final MagicQuoteRepository _repository;

  Future<void> _onMagicQuoteSubmit(
    MagicQuoteSubmitRequested event,
    Emitter<MagicQuoteState> emit,
  ) async {
    emit(MagicQuoteSubmitting());
    final (response, failure) = await _repository.submitMagicQuote(
      payload: event.payload,
      images: event.images,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(MagicQuoteError(failure.message));
      return;
    }

    final accepted = response ?? const <String, dynamic>{};
    if (magicQuoteHasGeneratedItems(accepted) ||
        magicQuoteUploadedFileCountOf(accepted) == 0) {
      emit(MagicQuoteSubmitted(accepted));
      return;
    }

    final steps = <String>[];
    final initialStatus = magicQuoteStatusOf(accepted);
    if (initialStatus.isNotEmpty) steps.add(initialStatus);
    emit(MagicQuoteProgress(
      status: initialStatus.isEmpty ? 'Uploaded' : initialStatus,
      steps: List.of(steps),
    ));

    await emit.forEach<Map<String, dynamic>>(
      _repository.watchMagicQuoteStatus(
        acceptedResponse: accepted,
        phoneNumber: event.payload['phone']?.toString() ?? '',
      ),
      onData: (message) {
        final status = magicQuoteStatusOf(message);
        if (status.isNotEmpty && !steps.contains(status)) steps.add(status);
        if (magicQuoteIsProcessingOf(message) == false ||
            magicQuoteIsTerminalStatus(status)) {
          return MagicQuoteSubmitted(message);
        }
        return MagicQuoteProgress(
          status: status.isEmpty
              ? (steps.isEmpty ? 'Processing' : steps.last)
              : status,
          steps: List.of(steps),
        );
      },
      onError: (error, _) {
        AppHaptics.error();
        return MagicQuoteError(
          error is StateError
              ? error.message
              : 'Magic Quote updates failed.',
        );
      },
    );
  }

  Future<void> _onMagicQuoteQuestions(
    MagicQuoteQuestionsRequested event,
    Emitter<MagicQuoteState> emit,
  ) async {
    emit(MagicQuoteQuestionsLoading());
    final (questions, failure) = await _repository.getMagicQuoteQuestions();
    if (failure != null) {
      emit(MagicQuoteQuestionsError(failure.message));
    } else {
      emit(MagicQuoteQuestionsLoaded(questions ?? const []));
    }
  }

  Future<void> _onMagicQuoteReviewSubmit(
    MagicQuoteReviewSubmitRequested event,
    Emitter<MagicQuoteState> emit,
  ) async {
    emit(MagicQuoteReviewSubmitting());
    final (success, failure) = await _repository.saveMagicQuoteReview(
      quoteId: event.quoteId,
      questionnaireAnswers: event.questionnaireAnswers,
      additionalInstructions: event.additionalInstructions,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(MagicQuoteReviewError(failure.message));
    } else if (success) {
      emit(MagicQuoteReviewSubmitted());
    } else {
      AppHaptics.error();
      emit(MagicQuoteReviewError('Failed to submit quote for review.'));
    }
  }
}
