import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/documents/presentation/document_capture_screen.dart';
import 'package:mobile_driver/features/documents/presentation/documents_screen.dart';
import 'package:mobile_driver/features/home/presentation/home_screen.dart';
import 'package:mobile_driver/features/onboarding/presentation/auth_controller.dart';
import 'package:mobile_driver/features/onboarding/presentation/launch_screen.dart';
import 'package:mobile_driver/features/onboarding/presentation/otp_screen.dart';
import 'package:mobile_driver/features/onboarding/presentation/phone_entry_screen.dart';
import 'package:mobile_driver/features/profile/presentation/profile_screen.dart';
import 'package:mobile_driver/features/shell/presentation/driver_shell_screen.dart';
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
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.vehicle,
        builder: (context, state) => const VehicleScreen(),
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
        path: AppRoutes.routesStub,
        builder: (context, state) => const RoutesStubScreen(),
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
                path: '/routes',
                builder: (context, state) => const RoutesTabStubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/earnings',
                builder: (context, state) => const EarningsStubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const AccountStubScreen(),
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
