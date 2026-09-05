/// Pure Dart domain models, formatting, and helpers for Along.
library;

export 'src/enums/fare_tier.dart';
export 'src/enums/sort_criterion.dart';
export 'src/enums/transport_mode.dart';
export 'src/enums/trip_status.dart';
export 'src/errors/along_error_code.dart';
export 'src/errors/along_exception.dart';
export 'src/formatting/duration_format.dart';
export 'src/formatting/money_format.dart';
export 'src/geo/bearing.dart';
export 'src/geo/distance.dart';
export 'src/models/candidate.dart';
export 'src/models/coverage_gap.dart';
export 'src/models/fare_quote.dart';
export 'src/models/geo_point.dart';
export 'src/models/load_warning.dart';
export 'src/models/itinerary.dart';
export 'src/models/journey.dart';
export 'src/models/na_me_pairing.dart';
export 'src/models/plan_result.dart';
export 'src/models/presence_state.dart';
export 'src/models/trip_summary.dart';
export 'src/time/clock.dart';
export 'src/value/money.dart';

const String alongCoreVersion = '0.0.1';
