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

  late final Animation<double> _scale =
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  late final Animation<double> _fade = CurvedAnimation(
      parent: _controller, curve: const Interval(0.4, 1, curve: Curves.easeIn));

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
    context.go(seen ? '/home' : '/onboarding');
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
                    Text(
                      'Fresh groceries at your\ndoorstep',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          height: 1.4,
                          color: BrandColors.slate,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 28),
                    DotsIndicator(count: 3, index: 0),
                  ],
                ),
              ),
              const Spacer(flex: 5),
              const Text(
                'VERSION 1.0.0',
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}
