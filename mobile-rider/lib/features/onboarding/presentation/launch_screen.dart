import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final destination = await ref
        .read(onboardingControllerProvider.notifier)
        .resolveLaunchDestination();

    if (!mounted) return;
    await _fadeOut();
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
    final width = MediaQuery.sizeOf(context).width * 0.5;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = still ? Duration.zero : _handoff;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          color: _leaving
              ? AlongPalette.of(context).bg
              : const Color(0xFFFFFFFF),
          alignment: Alignment.center,
          child: AnimatedOpacity(
            opacity: _leaving ? 0 : 1,
            duration: duration,
            curve: Curves.easeOut,
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
      ),
    );
  }
}
