import 'dart:convert';

import 'package:along_data/src/contracts/api_contracts.g.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Verification document status row from `my_verifications`.
class VerificationStatusRow {
  const VerificationStatusRow({
    required this.documentType,
    required this.status,
    this.rejectionReason,
    this.submittedAt,
  });

  final String documentType;
  final String status;
  final String? rejectionReason;
  final DateTime? submittedAt;

  factory VerificationStatusRow.fromJson(Map<String, dynamic> json) {
    return VerificationStatusRow(
      documentType: json['document_type'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt: json['submitted_at'] == null
          ? null
          : DateTime.tryParse(json['submitted_at'] as String),
    );
  }
}

/// Redacted OCR hints returned by the verification-ocr Edge function.
class OcrAssistHints {
  const OcrAssistHints({required this.fields});

  final Map<String, String> fields;

  factory OcrAssistHints.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final hints = data['hints'] as Map<String, dynamic>? ?? const {};
    return OcrAssistHints(
      fields: hints.map((key, value) => MapEntry(key, value.toString())),
    );
  }
}

/// Driver verification uploads and status (doc 03 §1, §11).
class VerificationRepository {
  VerificationRepository(this._gateway);

  final AlongSupabase _gateway;

  static const verificationBucket = 'verification';

  Future<List<VerificationStatusRow>> myVerifications() async {
    try {
      final result = await _gateway.rpc('my_verifications');
      final rows = _coerceJsonList(result);
      return rows
          .map(VerificationStatusRow.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<String> uploadCapture({
    required String driverId,
    required String documentType,
    required List<int> jpegBytes,
  }) async {
    final path = '$driverId/$documentType/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await _gateway.uploadStorageObject(
        bucket: verificationBucket,
        path: path,
        bytes: jpegBytes,
      );
      return path;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<OcrAssistHints> requestOcrAssist({
    required String verificationId,
  }) async {
    try {
      final result = await _gateway.invokeFunction(
        'verification-ocr',
        body: {'verification_id': verificationId},
      );
      return OcrAssistHints.fromJson(result);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> submitVerification({
    required String documentType,
    required String storagePath,
    String? vehicleId,
    Map<String, String>? redactedOcrHints,
  }) async {
    try {
      await _gateway.rpc(
        'submit_verification',
        params: SubmitVerificationRequest(
          document_type: documentType,
          storage_path: storagePath,
          vehicle_id: vehicleId,
          client_ocr_hint: redactedOcrHints == null || redactedOcrHints.isEmpty
              ? null
              : jsonEncode(redactedOcrHints),
        ).toJson(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  List<Map<String, dynamic>> _coerceJsonList(Object? result) {
    if (result is List) {
      return result.cast<Map<String, dynamic>>();
    }
    if (result is String) {
      final decoded = jsonDecode(result);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    }
    return const [];
  }
}
