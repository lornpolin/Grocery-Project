import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AuthColors {
  static const Color accent = AppColors.primary;
  static const Color bg = Color(0xFFF8FAFC);
  static const Color title = Color(0xFF0F172A);
  static const Color label = Color(0xFF334155);
  static const Color muted = Color(0xFF64748B);
  static const Color hint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
}

/// Scaffold with a centered rounded white card, shared by sign in / sign up.
class AuthCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  const AuthCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AuthColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 30,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: AuthColors.title)),
                  const SizedBox(height: 10),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, height: 1.4, color: AuthColors.muted)),
                  const SizedBox(height: 28),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SocialButtons extends StatelessWidget {
  const SocialButtons({super.key});

  Widget _btn(Widget icon, String label) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AuthColors.border),
          foregroundColor: AuthColors.title,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _btn(
                const Text('G',
                    style: TextStyle(
                        color: Color(0xFFEA4335),
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                'Google'),
            const SizedBox(width: 12),
            _btn(const Icon(Icons.apple, size: 24), 'Apple'),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: const [
            Expanded(child: Divider(color: AuthColors.border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Or continue with email',
                  style: TextStyle(color: AuthColors.hint, fontSize: 14)),
            ),
            Expanded(child: Divider(color: AuthColors.border)),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class AuthField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Widget? trailingLabel;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.trailingLabel,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscure = true;

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AuthColors.label)),
            if (widget.trailingLabel != null) widget.trailingLabel!,
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          style: const TextStyle(fontSize: 16, color: AuthColors.title),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AuthColors.hint),
            prefixIcon: Icon(widget.icon, color: AuthColors.hint),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AuthColors.hint),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            enabledBorder: _border(AuthColors.border),
            focusedBorder: _border(AuthColors.accent),
            errorBorder: _border(Colors.redAccent),
            focusedErrorBorder: _border(Colors.redAccent),
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const AuthPrimaryButton(
      {super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AuthColors.accent.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class AuthLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const AuthLink({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(text,
          style: const TextStyle(
              color: AuthColors.accent,
              fontWeight: FontWeight.w700,
              fontSize: 14)),
    );
  }
}

class AuthFooter extends StatelessWidget {
  final String prompt;
  final String action;
  final VoidCallback onTap;
  const AuthFooter(
      {super.key,
      required this.prompt,
      required this.action,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$prompt ',
            style: const TextStyle(color: AuthColors.muted, fontSize: 15)),
        GestureDetector(
          onTap: onTap,
          child: Text(action,
              style: const TextStyle(
                  color: AuthColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ),
      ],
    );
  }
}

class AuthCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;
  const AuthCheckbox(
      {super.key,
      required this.value,
      required this.onChanged,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: value
                  ? AuthColors.accent.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: value ? AuthColors.accent : AuthColors.muted,
                  width: 1.5),
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: AuthColors.accent)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: label),
      ],
    );
  }
}
