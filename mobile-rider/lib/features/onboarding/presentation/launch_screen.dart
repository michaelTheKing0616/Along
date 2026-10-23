import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/onboarding/presentation/onboarding_controller.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-01 Launch — brand splash, then route by session (doc 06 R-01).
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

    final destination =
        await ref.read(onboardingControllerProvider.notifier).resolveLaunchDestination();

    if (!mounted) return;
    switch (destination) {
      case LaunchDestination.phoneEntry:
        context.go(AppRoutes.phone);
      case LaunchDestination.nameEntry:
        context.go(AppRoutes.name);
      case LaunchDestination.home:
        context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.6;

    return Scaffold(
      backgroundColor: AlongPalette.of(context).bg,
      body: Center(
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 300),
          child: Semantics(
            label: 'along_logo',
            child: SvgPicture.asset(
              alongLogoBlackSvg,
              package: 'along_design',
              width: width,
            ),
          ),
        ),
      ),
    );
  }
}
