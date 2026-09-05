import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

/// Scrub phone numbers and plates from Sentry events (doc 07 §11).
FutureOr<SentryEvent?> scrubPii(SentryEvent event, Hint hint) {
  final scrubbedExceptions = event.exceptions
      ?.map(
        (exception) => SentryException(
          type: exception.type,
          value: exception.value == null
              ? null
              : _scrubText(exception.value!),
          module: exception.module,
          stackTrace: exception.stackTrace,
          mechanism: exception.mechanism,
          threadId: exception.threadId,
        ),
      )
      .toList();

  return SentryEvent(
    throwable: event.throwable,
    level: event.level,
    message: event.message == null
        ? null
        : SentryMessage(_scrubText(event.message!.formatted)),
    exceptions: scrubbedExceptions,
    breadcrumbs: event.breadcrumbs,
    contexts: event.contexts,
    tags: event.tags,
    fingerprint: event.fingerprint,
    platform: event.platform,
    logger: event.logger,
    serverName: event.serverName,
    release: event.release,
    environment: event.environment,
    transaction: event.transaction,
  );
}

String _scrubText(String input) {
  var output = input.replaceAllMapped(
    RegExp(r'\+?\d{10,15}'),
    (_) => '[REDACTED_PHONE]',
  );
  output = output.replaceAllMapped(
    RegExp(r'[A-Z]{3}[-\s]?\d{3}[A-Z]{2}', caseSensitive: false),
    (_) => '[REDACTED_PLATE]',
  );
  return output;
}
