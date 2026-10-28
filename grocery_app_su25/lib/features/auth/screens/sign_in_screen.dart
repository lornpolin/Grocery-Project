import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_state.dart';
import '../../../providers/app_providers.dart';
import '../../../services/api_client.dart';
import '../widgets/auth_widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await ApiClient.instance.login(
        email: _email.text,
        password: _password.text,
      );
      await ref.read(addressesProvider.notifier).clear();
      ref.read(categoriesProvider.notifier).refresh();
      ref.read(productsProvider.notifier).refresh();
      ref.read(cartProvider.notifier).refresh();
      ref.read(favoriteProvider.notifier).refresh();
      ref.read(ordersProvider.notifier).refresh();
      ref.read(addressesProvider.notifier).refresh();
      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        // Offline fallback so local testing still works when backend isn't running.
        await AuthState.instance.setSignedIn(
          true,
          email: _email.text.trim(),
        );
        if (!mounted) return;
        context.go('/home');
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      title: 'Sign In',
      subtitle: 'Welcome back! Please enter your details.',
      children: [
        const SocialButtons(),
        Form(
          key: _formKey,
          child: Column(
            children: [
              AuthField(
                label: 'Email Address',
                hint: 'name@company.com',
                icon: Icons.mail_outline_rounded,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 20),
              AuthField(
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_rounded,
                isPassword: true,
                controller: _password,
                trailingLabel: AuthLink(text: 'Forgot Password?', onTap: () {}),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your password' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AuthCheckbox(
          value: _remember,
          onChanged: (v) => setState(() => _remember = v),
          label: const Text(
            'Remember me for 30 days',
            style: TextStyle(color: AuthColors.muted, fontSize: 15),
          ),
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: _loading ? 'Signing In...' : 'Sign In',
          onPressed: _submit,
        ),
        const SizedBox(height: 24),
        AuthFooter(
          prompt: "Don't have an account?",
          action: 'Sign Up',
          onTap: () => context.go('/sign-up'),
        ),
      ],
    );
  }
}
