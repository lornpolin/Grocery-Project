import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/auth/auth_state.dart';
import '../widgets/brand_widgets.dart';

const String kOnboardingSeenKey = 'onboarding_seen';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.4, 1, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    await AuthState.instance.load();
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    final seen = prefs.getBool(kOnboardingSeenKey) ?? false;
    if (!seen) {
      context.go('/onboarding');
      return;
    }
    if (AuthState.instance.isSignedIn || AuthState.instance.isGuestBrowsing) {
      context.go('/home');
    } else {
      context.go('/sign-in');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 5),
              ScaleTransition(scale: _scale, child: const BrandLogo()),
              const SizedBox(height: 36),
              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: const [
                    BrandTitle(),
                    SizedBox(height: 14),
                    SizedBox(height: 28),
                  ],
                ),
              ),
              const Spacer(flex: 5),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}
