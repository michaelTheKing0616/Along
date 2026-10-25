import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/documents/domain/ocr_confirm_policy.dart';
import 'package:mobile_driver/features/onboarding/data/driver_onboarding_preferences.dart';

enum DocumentUiStatus { notStarted, pending, approved, rejected }

class DocumentChecklistItem {
  const DocumentChecklistItem({
    required this.type,
    required this.label,
    required this.pattern,
    required this.status,
    this.rejectionReason,
  });

  final String type;
  final String label;
  final String pattern;
  final DocumentUiStatus status;
  final String? rejectionReason;
}

class DocumentsState {
  const DocumentsState({
    this.items = const [],
    this.isLoading = true,
    this.errorMessage,
    this.allSubmitted = false,
  });

  final List<DocumentChecklistItem> items;
  final bool isLoading;
  final String? errorMessage;
  final bool allSubmitted;

  DocumentsState copyWith({
    List<DocumentChecklistItem>? items,
    bool? isLoading,
    String? errorMessage,
    bool? allSubmitted,
  }) {
    return DocumentsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      allSubmitted: allSubmitted ?? this.allSubmitted,
    );
  }
}

class DocumentCaptureState {
  const DocumentCaptureState({
    required this.documentType,
    required this.label,
    this.ocrSuggestions = const {},
    this.confirmedFields = const {},
    this.appliedSuggestionKeys = const {},
    this.storagePath,
    this.isSubmitting = false,
    this.errorMessage,
    this.imageBytes,
  });

  final String documentType;
  final String label;
  final Map<String, String> ocrSuggestions;
  final Map<String, String> confirmedFields;
  final Set<String> appliedSuggestionKeys;
  final String? storagePath;
  final bool isSubmitting;
  final String? errorMessage;
  final List<int>? imageBytes;

  DocumentCaptureState copyWith({
    Map<String, String>? ocrSuggestions,
    Map<String, String>? confirmedFields,
    Set<String>? appliedSuggestionKeys,
    String? storagePath,
    bool? isSubmitting,
    String? errorMessage,
    List<int>? imageBytes,
    bool clearError = false,
  }) {
    return DocumentCaptureState(
      documentType: documentType,
      label: label,
      ocrSuggestions: ocrSuggestions ?? this.ocrSuggestions,
      confirmedFields: confirmedFields ?? this.confirmedFields,
      appliedSuggestionKeys:
          appliedSuggestionKeys ?? this.appliedSuggestionKeys,
      storagePath: storagePath ?? this.storagePath,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
}

final documentsControllerProvider =
    AsyncNotifierProvider<DocumentsController, DocumentsState>(
  DocumentsController.new,
);

class DocumentsController extends AsyncNotifier<DocumentsState> {
  VerificationRepository get _verification =>
      ref.read(verificationRepositoryProvider);
  CatalogRepository get _catalog => ref.read(catalogRepositoryProvider);
  DriverOnboardingPreferences get _prefs =>
      ref.read(driverOnboardingPreferencesProvider);
  ConfigRepository get _config => ref.read(configRepositoryProvider);

  @override
  Future<DocumentsState> build() async {
    return _loadChecklist();
  }

  Future<DocumentsState> _loadChecklist() async {
    try {
      final countryCode = await _prefs.countryCode() ?? 'NG';
      final country = await _catalog.countryConfig(countryCode);
      final statuses = await _verification.myVerifications();
      final statusByType = {
        for (final row in statuses) row.documentType: row,
      };

      final items = country.verificationSchema.map((doc) {
        final statusRow = statusByType[doc.type];
        return DocumentChecklistItem(
          type: doc.type,
          label: doc.label,
          pattern: doc.pattern,
          status: _mapStatus(statusRow?.status),
          rejectionReason: statusRow?.rejectionReason,
        );
      }).toList(growable: false);

      final allSubmitted = items.isNotEmpty &&
          items.every(
            (item) =>
                item.status == DocumentUiStatus.pending ||
                item.status == DocumentUiStatus.approved,
          );

      if (allSubmitted) {
        await _prefs.setStep(DriverOnboardingStep.pending);
        ref.invalidate(driverOnboardingStepProvider);
      }

      return DocumentsState(
        items: items,
        isLoading: false,
        allSubmitted: allSubmitted,
      );
    } catch (_) {
      return const DocumentsState(
        isLoading: false,
        errorMessage: 'generic',
      );
    }
  }

  DocumentUiStatus _mapStatus(String? status) {
    return switch (status) {
      'pending' => DocumentUiStatus.pending,
      'approved' => DocumentUiStatus.approved,
      'rejected' => DocumentUiStatus.rejected,
      _ => DocumentUiStatus.notStarted,
    };
  }

  Future<DocumentsState> refreshAndGetState() async {
    state = const AsyncLoading();
    final next = await _loadChecklist();
    state = AsyncData(next);
    return next;
  }

  Future<void> refresh() async {
    await refreshAndGetState();
  }

  Future<int?> expectedReviewHours() async {
    try {
      return (await _config.configNum('verification.expected_review_hours'))
          .round();
    } catch (_) {
      return null;
    }
  }
}

final documentCaptureControllerProvider = NotifierProvider.family<
    DocumentCaptureController, DocumentCaptureState, DocumentCaptureArgs>(
  DocumentCaptureController.new,
);

class DocumentCaptureArgs {
  const DocumentCaptureArgs({
    required this.documentType,
    required this.label,
  });

  final String documentType;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is DocumentCaptureArgs &&
      other.documentType == documentType &&
      other.label == label;

  @override
  int get hashCode => Object.hash(documentType, label);
}

class DocumentCaptureController
    extends FamilyNotifier<DocumentCaptureState, DocumentCaptureArgs> {
  VerificationRepository get _verification =>
      ref.read(verificationRepositoryProvider);
  DriverOnboardingPreferences get _prefs =>
      ref.read(driverOnboardingPreferencesProvider);
  AuthRepository get _auth => ref.read(authRepositoryProvider);

  @override
  DocumentCaptureState build(DocumentCaptureArgs arg) {
    return DocumentCaptureState(
      documentType: arg.documentType,
      label: arg.label,
    );
  }

  Future<void> attachImage(List<int> bytes, {Map<String, String>? ocrHints}) async {
    state = state.copyWith(
      imageBytes: bytes,
      ocrSuggestions: ocrHints ?? const {},
      confirmedFields: const {},
      appliedSuggestionKeys: const {},
      clearError: true,
    );
  }

  void resetCapture() {
    state = DocumentCaptureState(
      documentType: state.documentType,
      label: state.label,
    );
  }

  /// Explicit confirm — required for every OCR suggestion (especially IDs).
  void confirmSuggestion(String key) {
    final suggestion = state.ocrSuggestions[key];
    if (suggestion == null) return;

    state = state.copyWith(
      confirmedFields: OcrConfirmPolicy.applyConfirmed(
        current: state.confirmedFields,
        key: key,
        value: suggestion,
      ),
      appliedSuggestionKeys: {...state.appliedSuggestionKeys, key},
    );
  }

  void setManualField(String key, String value) {
    state = state.copyWith(
      confirmedFields: OcrConfirmPolicy.applyConfirmed(
        current: state.confirmedFields,
        key: key,
        value: value,
      ),
    );
  }

  Future<bool> submit() async {
    final bytes = state.imageBytes;
    final userId = _auth.currentUser?.id;
    if (bytes == null || bytes.isEmpty || userId == null) {
      state = state.copyWith(errorMessage: 'validation');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final storagePath = await _verification.uploadCapture(
        driverId: userId,
        documentType: state.documentType,
        jpegBytes: bytes,
      );

      final vehicleId = state.documentType == 'vehicle_particulars'
          ? await _prefs.vehicleId()
          : null;

      await _verification.submitVerification(
        documentType: state.documentType,
        storagePath: storagePath,
        vehicleId: vehicleId,
        redactedOcrHints: OcrConfirmPolicy.redactForSubmit(state.confirmedFields),
      );

      state = state.copyWith(
        isSubmitting: false,
        storagePath: storagePath,
        clearError: true,
      );
      return true;
    } on AlongException catch (_) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'generic');
      return false;
    } catch (_) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'generic');
      return false;
    }
  }
}
