import 'package:along_core/src/errors/along_error_code.dart';

/// Domain exception with a stable machine-readable [code].
class AlongException implements Exception {
  const AlongException({
    required this.code,
    required this.message,
    this.details,
    this.requestId,
  });

  final AlongErrorCode code;
  final String message;
  final Object? details;
  final String? requestId;

  @override
  String toString() =>
      'AlongException(${code.apiValue}): $message${requestId != null ? ' [request_id=$requestId]' : ''}';
}
