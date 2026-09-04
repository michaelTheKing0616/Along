import 'package:along_core/along_core.dart';
import 'package:along_data/src/contracts/api_contracts.g.dart' as dto;
import 'package:supabase_flutter/supabase_flutter.dart';

AlongException mapSupabaseError(Object error, {String? requestId}) {
  if (error is AlongException) return error;

  if (error is PostgrestException) {
    final code = _parseCode(error.message) ?? AlongErrorCode.validation;
    return AlongException(
      code: code,
      message: error.message,
      details: error.details,
      requestId: requestId,
    );
  }

  if (error is AuthException) {
    return AlongException(
      code: AlongErrorCode.unauthenticated,
      message: error.message,
      requestId: requestId,
    );
  }

  if (error is FunctionException) {
    final envelope = _tryParseEnvelope(error.details);
    if (envelope != null) {
      return AlongException(
        code: AlongErrorCode.parse(envelope.error.code),
        message: envelope.error.message,
        details: envelope.error.details,
        requestId: envelope.meta.request_id,
      );
    }
    return AlongException(
      code: AlongErrorCode.degradedUpstream,
      message: error.reasonPhrase ?? 'Edge function error',
      details: error.details,
      requestId: requestId,
    );
  }

  return AlongException(
    code: AlongErrorCode.unknown,
    message: error.toString(),
    requestId: requestId,
  );
}

AlongErrorCode? _parseCode(String message) {
  for (final code in AlongErrorCode.values) {
    if (code == AlongErrorCode.unknown) continue;
    if (message.contains(code.apiValue)) return code;
  }
  return null;
}

dto.ErrorEnvelope? _tryParseEnvelope(Object? details) {
  if (details is! Map<String, dynamic>) return null;
  try {
    return dto.ErrorEnvelope.fromJson(details);
  } catch (_) {
    return null;
  }
}
