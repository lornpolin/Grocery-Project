import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_state.dart';
import '../../../providers/app_providers.dart';
import '../../../services/api_client.dart';
import '../widgets/auth_widgets.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _agree = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms of Service')),
      );
      return;
    }
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await ApiClient.instance.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
      await ref.read(addressesProvider.notifier).clear();
      ref.read(shouldPromptAddAddressProvider.notifier).state = true;
      ref.read(categoriesProvider.notifier).refresh();
      ref.read(productsProvider.notifier).refresh();
      ref.read(cartProvider.notifier).refresh();
      ref.read(favoriteProvider.notifier).refresh();
      ref.read(ordersProvider.notifier).refresh();
      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        await AuthState.instance.setSignedIn(
          true,
          name: _name.text.trim(),
          email: _email.text.trim(),
        );
        await ref.read(addressesProvider.notifier).clear();
        ref.read(shouldPromptAddAddressProvider.notifier).state = true;
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
    const body = TextStyle(color: AuthColors.muted, fontSize: 14, height: 1.4);
    const link = TextStyle(
      color: AuthColors.accent,
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w700,
    );

    return AuthCard(
      title: 'Create your account',
      subtitle: 'Join over 25,000+ shoppers',
      children: [
        const SocialButtons(),
        Form(
          key: _formKey,
          child: Column(
            children: [
              AuthField(
                label: 'Full Name',
                hint: 'John Doe',
                icon: Icons.person_rounded,
                controller: _name,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter your name'
                    : null,
              ),
              const SizedBox(height: 20),
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
                hint: 'Min. 6 characters',
                icon: Icons.lock_rounded,
                isPassword: true,
                controller: _password,
                validator: (v) => (v == null || v.length < 6)
                    ? 'Use at least 6 characters'
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AuthCheckbox(
          value: _agree,
          onChanged: (v) => setState(() => _agree = v),
          label: const Text.rich(
            TextSpan(
              style: body,
              children: [
                TextSpan(text: 'I agree to the '),
                TextSpan(text: 'Terms of Service', style: link),
                TextSpan(text: ' and '),
                TextSpan(text: 'Privacy Policy', style: link),
                TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: _loading ? 'Creating Account...' : 'Create Account',
          onPressed: _submit,
        ),
        const SizedBox(height: 24),
        AuthFooter(
          prompt: 'Already have an account?',
          action: 'Sign In',
          onTap: () => context.go('/sign-in'),
        ),
      ],
    );
  }
}
