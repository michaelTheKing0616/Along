import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/day/presentation/build_my_day_screen.dart';
import 'package:mobile_driver/features/day/presentation/conductor_screen.dart';
import 'package:mobile_driver/features/day/presentation/seat_board_screen.dart';
import 'package:mobile_driver/features/documents/presentation/document_capture_screen.dart';
import 'package:mobile_driver/features/documents/presentation/documents_screen.dart';
import 'package:mobile_driver/features/home/presentation/home_screen.dart';
import 'package:mobile_driver/features/onboarding/presentation/auth_controller.dart';
import 'package:mobile_driver/features/onboarding/presentation/launch_screen.dart';
import 'package:mobile_driver/features/onboarding/presentation/otp_screen.dart';
import 'package:mobile_driver/features/onboarding/presentation/permissions_screen.dart';
import 'package:mobile_driver/features/onboarding/presentation/phone_entry_screen.dart';
import 'package:mobile_driver/features/profile/presentation/profile_screen.dart';
import 'package:mobile_driver/features/routes/presentation/draw_route_controller.dart';
import 'package:mobile_driver/features/routes/presentation/draw_route_screen.dart';
import 'package:mobile_driver/features/routes/presentation/fast_route_setup_screen.dart';
import 'package:mobile_driver/features/routes/presentation/routes_list_screen.dart';
import 'package:mobile_driver/features/account/presentation/account_screen.dart';
import 'package:mobile_driver/features/payments/presentation/my_qr_screen.dart';
import 'package:mobile_driver/features/marketplace/presentation/marketplace_screen.dart';
import 'package:mobile_driver/features/safety/presentation/rest_screen.dart';
import 'package:mobile_driver/features/safety/presentation/report_incident_screen.dart';
import 'package:mobile_driver/features/safety/presentation/sos_active_screen.dart';
import 'package:mobile_driver/features/shell/presentation/driver_shell_screen.dart';
import 'package:mobile_driver/features/ledger/presentation/earnings_screen.dart';
import 'package:mobile_driver/features/ledger/presentation/guarantor_screen.dart';
import 'package:mobile_driver/features/ledger/presentation/settle_screen.dart';
import 'package:mobile_driver/features/ledger/presentation/standing_screen.dart';
import 'package:mobile_driver/features/trip/presentation/active_trip_controller.dart';
import 'package:mobile_driver/features/trip/presentation/active_trip_screen.dart';
import 'package:mobile_driver/features/trip/presentation/manifest_screen.dart';
import 'package:mobile_driver/features/trip/presentation/na_me_screen.dart';
import 'package:mobile_driver/features/vehicle/presentation/vehicle_screen.dart';
import 'package:mobile_driver/features/verification/presentation/verification_pending_screen.dart';
import 'package:mobile_driver/routing/routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.launch,
    routes: [
      GoRoute(
        path: AppRoutes.launch,
        builder: (context, state) => const LaunchScreen(),
      ),
      GoRoute(
        path: AppRoutes.phone,
        builder: (context, state) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.permissions,
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.vehicle,
        builder: (context, state) => const VehicleScreen(),
      ),
      GoRoute(
        path: AppRoutes.buildMyDay,
        builder: (context, state) => const BuildMyDayScreen(),
      ),
      GoRoute(
        path: AppRoutes.seatBoard,
        builder: (context, state) => const SeatBoardScreen(),
      ),
      GoRoute(
        path: AppRoutes.conductor,
        builder: (context, state) => const ConductorScreen(),
      ),
      GoRoute(
        path: AppRoutes.rest,
        builder: (context, state) => const RestScreen(),
      ),
      GoRoute(
        path: AppRoutes.marketplace,
        builder: (context, state) => const MarketplaceScreen(),
      ),
      GoRoute(
        path: AppRoutes.documents,
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.documentCapture,
        builder: (context, state) {
          final args = state.extra! as DocumentCaptureRouteArgs;
          return DocumentCaptureScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.pending,
        builder: (context, state) => const VerificationPendingScreen(),
      ),
      GoRoute(
        path: AppRoutes.routeFastSetup,
        builder: (context, state) {
          final suggestion = state.extra! as SuggestedKnownRoute;
          return FastRouteSetupScreen(suggestion: suggestion);
        },
      ),
      GoRoute(
        path: AppRoutes.routeDraw,
        builder: (context, state) {
          final args = state.extra as DrawRouteArgs? ?? const DrawRouteArgs();
          return DrawRouteScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.manifest,
        builder: (context, state) => const ManifestScreen(),
      ),
      GoRoute(
        path: AppRoutes.activeTrip,
        builder: (context, state) {
          final args = state.extra! as ActiveTripArgs;
          return ActiveTripScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.naMe,
        builder: (context, state) {
          final args = state.extra! as NaMeRouteArgs;
          return NaMeScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.sosActive,
        builder: (context, state) {
          final args = state.extra! as SosActiveRouteArgs;
          return SosActiveScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.reportIncident,
        builder: (context, state) {
          final tripId = state.extra as String?;
          return ReportIncidentScreen(tripId: tripId);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            DriverShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const DriverHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.routesTab,
                builder: (context, state) => const RoutesListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.earnings,
                builder: (context, state) => const EarningsScreen(),
                routes: [
                  GoRoute(
                    path: 'settle',
                    builder: (context, state) => const SettleScreen(),
                  ),
                  GoRoute(
                    path: 'standing',
                    builder: (context, state) => const StandingScreen(),
                  ),
                  GoRoute(
                    path: 'guarantor',
                    builder: (context, state) => const GuarantorScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (context, state) => const AccountScreen(),
                routes: [
                  GoRoute(
                    path: 'my-qr',
                    builder: (context, state) => const MyQrScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == AppRoutes.launch) return null;

      final session = ref.read(authRepositoryProvider).currentUser;
      if (session == null &&
          location != AppRoutes.phone &&
          location != AppRoutes.otp) {
        return AppRoutes.phone;
      }

      if (session == null &&
          location == AppRoutes.otp &&
          ref.read(authControllerProvider).phoneE164 == null) {
        return AppRoutes.phone;
      }

      return null;
    },
  );
});
