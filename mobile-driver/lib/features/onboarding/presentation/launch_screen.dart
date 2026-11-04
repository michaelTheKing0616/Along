import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/features/onboarding/data/driver_onboarding_preferences.dart';
import 'package:mobile_driver/features/onboarding/presentation/auth_controller.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-01 Launch — brand splash, then route by session (doc 06 D-01).
class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({super.key});

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends ConsumerState<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _routeAfterSplash());
  }

  Future<void> _routeAfterSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final step = await ref
        .read(authControllerProvider.notifier)
        .resolveLaunchStep();

    if (!mounted) return;
    await _fadeOut();
    if (!mounted) return;
    context.go(_routeForStep(step));
  }

  String _routeForStep(DriverOnboardingStep step) {
    return switch (step) {
      DriverOnboardingStep.auth => AppRoutes.phone,
      DriverOnboardingStep.profile => AppRoutes.profile,
      DriverOnboardingStep.vehicle => AppRoutes.vehicle,
      DriverOnboardingStep.documents => AppRoutes.documents,
      DriverOnboardingStep.pending => AppRoutes.pending,
      DriverOnboardingStep.complete => AppRoutes.home,
    };
  }

  /// The splash is always white with the black mark. Before handing off,
  /// ease the white into the app's surface so a dark-mode home never
  /// arrives as a hard flash. Skipped under reduce-motion.
  bool _leaving = false;

  static const _handoff = Duration(milliseconds: 220);

  Future<void> _fadeOut() async {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    setState(() => _leaving = true);
    await Future<void>.delayed(_handoff);
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = still ? Duration.zero : _handoff;

    // Launch follows the theme: pure white + black ink in light, matte black
    // + off-white ink in dark. Logo is the one mark; the taxi art sits below.
    final palette = AlongPalette.of(context);
    final dark = palette.brightness == Brightness.dark;
    final launchBg = dark ? palette.bg : const Color(0xFFFFFFFF);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: launchBg,
        body: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          color: _leaving ? palette.bg : launchBg,
          alignment: Alignment.center,
          child: AnimatedOpacity(
            opacity: _leaving ? 0 : 1,
            duration: duration,
            curve: Curves.easeOut,
            child: const AlongLaunchArt(illustration: alongTaxiMapFront),
          ),
        ),
      ),
    );
  }
}
