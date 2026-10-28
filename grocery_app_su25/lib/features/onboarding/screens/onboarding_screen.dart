import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/brand_widgets.dart';
import 'splash_screen.dart' show kOnboardingSeenKey;

class _Page {
  final IconData icon;
  final String text;
  const _Page(this.icon, this.text);
}

const _pages = [
  _Page(Icons.eco_rounded, 'Fresh groceries at your\ndoorstep'),
  _Page(Icons.touch_app_rounded, 'Browse, pick and order\nin just a few taps'),
  _Page(Icons.delivery_dining_rounded, 'Fast delivery right to your\ndoor.'),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingSeenKey, true);
    if (mounted) context.go('/sign-in');
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
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
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: _isLast ? null : _finish,
                    child: const Text('Skip',
                        style: TextStyle(
                            color: BrandColors.slate,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _PageContent(page: _pages[i]),
                ),
              ),
              DotsIndicator(count: _pages.length, index: _index),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: BrandColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _isLast ? 'Get Started' : 'Next',
                        key: ValueKey(_isLast),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'VERSION 1.0.0',
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _Page page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const BrandLogo(),
        const SizedBox(height: 36),
        const BrandTitle(),
        const SizedBox(height: 14),
        Text(
          page.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 18,
              height: 1.4,
              color: BrandColors.slate,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        Icon(page.icon, color: BrandColors.primary, size: 30),
      ],
    );
  }
}
