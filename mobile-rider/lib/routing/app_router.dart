import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/home/presentation/home_screen.dart';
import 'package:mobile_rider/features/onboarding/presentation/launch_screen.dart';
import 'package:mobile_rider/features/onboarding/presentation/name_screen.dart';
import 'package:mobile_rider/features/onboarding/presentation/onboarding_controller.dart';
import 'package:mobile_rider/features/onboarding/presentation/otp_screen.dart';
import 'package:mobile_rider/features/onboarding/presentation/phone_entry_screen.dart';
import 'package:mobile_rider/features/search/presentation/search_screens.dart';
import 'package:mobile_rider/features/shell/presentation/rider_shell_screen.dart';
import 'package:mobile_rider/features/transfer/active_journey_monitor.dart';
import 'package:mobile_rider/features/transfer/presentation/transfer_screen.dart';
import 'package:mobile_rider/features/pricing/presentation/pricing_sheet_screen.dart';
import 'package:mobile_rider/features/pricing/domain/pricing_route_args.dart';
import 'package:mobile_rider/features/trip_options/presentation/requesting_screen.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_screen.dart';
import 'package:mobile_rider/features/wayfinding/presentation/wayfinding_screen.dart';
import 'package:mobile_rider/routing/routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorKey = GlobalKey<NavigatorState>();

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
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
        path: AppRoutes.name,
        builder: (context, state) => const NameScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RiderShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.trips,
                builder: (context, state) => const TripsStubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (context, state) => const AccountStubScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const DestinationSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.adjustPickup,
        builder: (context, state) => const AdjustPickupScreen(),
      ),
      GoRoute(
        path: AppRoutes.tripOptions,
        builder: (context, state) => const TripOptionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.pricing,
        builder: (context, state) {
          final args = state.extra as PricingRouteArgs;
          return PricingSheetScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.requesting,
        builder: (context, state) {
          final args = state.extra as RequestingRouteArgs;
          return RequestingScreen(
            trip: args.trip,
            roamingSource: args.roamingSource,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.transfer,
        builder: (context, state) {
          final args = state.extra as TransferRouteArgs;
          return TransferScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.wayfinding,
        builder: (context, state) {
          final args = state.extra as WayfindingRouteArgs;
          return WayfindingScreen(args: args);
        },
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == AppRoutes.launch) return null;

      final session = ref.read(authRepositoryProvider).currentUser;
      final onboardingAsync = ref.read(onboardingCompleteProvider);
      final onboardingState = ref.read(onboardingControllerProvider);

      if (session == null &&
          location != AppRoutes.phone &&
          location != AppRoutes.otp &&
          location != AppRoutes.launch) {
        return AppRoutes.phone;
      }

      if (session == null &&
          location == AppRoutes.otp &&
          onboardingState.phoneE164 == null) {
        return AppRoutes.phone;
      }

      final onboardingComplete = onboardingAsync.maybeWhen(
        data: (value) => value,
        orElse: () => false,
      );

      if (session != null &&
          onboardingComplete &&
          (location == AppRoutes.phone ||
              location == AppRoutes.otp ||
              location == AppRoutes.name)) {
        return AppRoutes.home;
      }

      return null;
    },
  );

  ref.listen(activeJourneyMonitorProvider, (previous, next) {
    final args = next.transferNavigation;
    if (args == null) return;
    if (previous?.transferNavigation == args) return;
    if (router.state.matchedLocation == AppRoutes.transfer) return;
    router.push(AppRoutes.transfer, extra: args);
  });

  return router;
});
