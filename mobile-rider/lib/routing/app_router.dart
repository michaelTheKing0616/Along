import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/onboarding/presentation/launch_screen.dart';
import 'package:mobile_rider/features/onboarding/presentation/name_screen.dart';
import 'package:mobile_rider/features/onboarding/presentation/onboarding_complete_screen.dart';
import 'package:mobile_rider/features/onboarding/presentation/onboarding_controller.dart';
import 'package:mobile_rider/features/onboarding/presentation/otp_screen.dart';
import 'package:mobile_rider/features/onboarding/presentation/phone_entry_screen.dart';
import 'package:mobile_rider/routing/routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
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
      GoRoute(
        path: AppRoutes.onboardingComplete,
        builder: (context, state) => const OnboardingCompleteScreen(),
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
        return AppRoutes.onboardingComplete;
      }

      return null;
    },
  );
});
