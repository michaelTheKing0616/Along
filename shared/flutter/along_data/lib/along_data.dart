/// Supabase repositories, Drift offline cache, and pending-action queue.
library;

export 'src/auth/auth_repository.dart';
export 'src/catalog/catalog_repository.dart';
export 'src/config/config_repository.dart';
export 'src/contracts/api_contracts.g.dart';
export 'src/database/along_database.dart';
export 'src/database/pending_action_queue.dart';
export 'src/driver/driver_repository.dart';
export 'src/mappers/domain_mappers.dart';
export 'src/negotiation/negotiation_repository.dart';
export 'src/negotiation/negotiation_view.dart';
export 'src/journeys/journey_repository.dart';
export 'src/ledger/ledger_repository.dart';
export 'src/places/places_repository.dart';
export 'src/planner/planner_repository.dart';
export 'src/presence/presence_repository.dart';
export 'src/routes/routes_repository.dart';
export 'src/supabase/along_supabase.dart';
export 'src/supabase/error_mapper.dart';
export 'src/trips/trips_repository.dart';
export 'src/verification/verification_repository.dart';
export 'src/wayfinding/walking_directions_repository.dart';

const String alongDataVersion = '0.0.1';
