/// Server error codes from `shared/contracts/schemas/common.json`.
enum AlongErrorCode {
  unauthenticated('UNAUTHENTICATED'),
  forbidden('FORBIDDEN'),
  notFound('NOT_FOUND'),
  validation('VALIDATION'),
  conflict('CONFLICT'),
  rateLimited('RATE_LIMITED'),
  stateInvalid('STATE_INVALID'),
  driverNotMatchable('DRIVER_NOT_MATCHABLE'),
  ledgerBlocked('LEDGER_BLOCKED'),
  candidateExpired('CANDIDATE_EXPIRED'),
  negotiationClosed('NEGOTIATION_CLOSED'),
  fareUnresolved('FARE_UNRESOLVED'),
  coverageGap('COVERAGE_GAP'),
  degradedUpstream('DEGRADED_UPSTREAM'),
  idempotentReplay('IDEMPOTENT_REPLAY'),
  unknown('UNKNOWN');

  const AlongErrorCode(this.apiValue);

  final String apiValue;

  static AlongErrorCode parse(String? raw) {
    if (raw == null || raw.isEmpty) return AlongErrorCode.unknown;
    for (final code in AlongErrorCode.values) {
      if (code.apiValue == raw) return code;
    }
    return AlongErrorCode.unknown;
  }
}
