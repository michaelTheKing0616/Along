import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
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
import 'package:mobile_rider/features/account/presentation/account_settings_screen.dart';
import 'package:mobile_rider/features/safety/presentation/report_incident_screen.dart';
import 'package:mobile_rider/features/safety/presentation/sos_active_screen.dart';
import 'package:mobile_rider/features/transfer/active_journey_monitor.dart';
import 'package:mobile_rider/features/transfer/presentation/transfer_screen.dart';
import 'package:mobile_rider/features/pricing/presentation/pricing_sheet_screen.dart';
import 'package:mobile_rider/features/pricing/domain/pricing_route_args.dart';
import 'package:mobile_rider/features/live_trip/presentation/active_trip_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/meet_vehicle_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/na_me_screen.dart';
import 'package:mobile_rider/features/trip_options/presentation/requesting_screen.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_screen.dart';
import 'package:mobile_rider/features/wayfinding/presentation/wayfinding_screen.dart';
import 'package:mobile_rider/features/trips/presentation/trip_detail_screen.dart';
import 'package:mobile_rider/features/trips/presentation/trips_history_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/pay_driver_sheet.dart';
import 'package:mobile_rider/features/payments/presentation/payment_deep_link_listener.dart';
import 'package:mobile_rider/features/payments/presentation/payment_methods_screen.dart';
import 'package:mobile_rider/features/payments/presentation/scan_to_pay_screen.dart';
import 'package:mobile_rider/features/day_planner/presentation/day_planner_screen.dart';
import 'package:mobile_rider/features/day_planner/presentation/itinerary_entry_screen.dart';
import 'package:mobile_rider/features/shell/presentation/rider_shell_screen.dart';
import 'package:mobile_rider/features/vehicles/presentation/vehicle_cards_screen.dart';
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
                builder: (context, state) => const TripsHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (context, state) => const AccountSettingsScreen(),
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
        path: AppRoutes.vehicles,
        builder: (context, state) => const VehicleCardsScreen(),
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
      GoRoute(
        path: AppRoutes.meetVehicle,
        builder: (context, state) {
          final trip = state.extra as TripSummary;
          return MeetVehicleScreen(trip: trip);
        },
      ),
      GoRoute(
        path: AppRoutes.naMe,
        builder: (context, state) {
          final args = state.extra as NaMeRouteArgs;
          return NaMeScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.tripDetail,
        builder: (context, state) {
          final tripId = state.extra as String;
          return TripDetailScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.payDriver,
        builder: (context, state) {
          final args = state.extra;
          if (args is PayDriverRouteArgs) {
            return Scaffold(
              body: SafeArea(
                child: PayDriverSheet(
                  trip: args.trip as TripSummary?,
                  driverCode: args.driverCode,
                  dynamicToken: args.dynamicToken,
                  preloadedResolve: args.preloadedResolve as QrResolveResult?,
                ),
              ),
            );
          }
          final trip = args as TripSummary?;
          return Scaffold(
            body: SafeArea(child: PayDriverSheet(trip: trip)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.scanToPay,
        builder: (context, state) => const ScanToPayScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentMethods,
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: AppRoutes.activeTrip,
        builder: (context, state) {
          final trip = state.extra as TripSummary;
          return ActiveTripScreen(trip: trip);
        },
      ),
      GoRoute(
        path: AppRoutes.sosActive,
        builder: (context, state) {
          final args = state.extra as SosActiveRouteArgs;
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
      GoRoute(
        path: AppRoutes.dayPlanner,
        builder: (context, state) {
          final itineraryId = state.extra as String? ?? '';
          return DayPlannerScreen(itineraryId: itineraryId);
        },
      ),
      GoRoute(
        path: AppRoutes.itineraryEntry,
        builder: (context, state) {
          final existingId = state.extra as String?;
          return ItineraryEntryScreen(existingItineraryId: existingId);
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
