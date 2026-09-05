import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final step =
        await ref.read(authControllerProvider.notifier).resolveLaunchStep();

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
      DriverOnboardingStep.complete => AppRoutes.pending,
    };
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.6;

    return Scaffold(
      backgroundColor: AlongColors.surface0,
      body: Center(
        child: SvgPicture.asset(
          alongLogoBlackSvg,
          package: 'along_design',
          width: width,
        ),
      ),
    );
  }
}
