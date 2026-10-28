import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/api_client.dart';

const _profileBg = Color(0xFFF8F9FA);
const _textDark = Color(0xFF1E293B);
const _textMuted = Color(0xFF757575);
const _iconCircleBg = Color(0xFFEEF5FC);
const _logoutRed = Color(0xFFBA1A1A);
const _logoutBorder = Color(0xFFEBCCCD);

class _SettingItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.onTap,
  });
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await ApiClient.instance.logout();
    if (context.mounted) {
      context.go('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <_SettingItem>[
      _SettingItem(
        icon: Icons.shopping_basket_outlined,
        title: 'My Orders',
        onTap: () => context.go('/orders'),
      ),
      _SettingItem(
        icon: Icons.favorite_border_rounded,
        title: 'Favorites',
        onTap: () => context.push('/favorites'),
      ),
      const _SettingItem(
        icon: Icons.location_on_outlined,
        title: 'Saved Addresses',
      ),
      const _SettingItem(
        icon: Icons.credit_card_outlined,
        title: 'Payment Methods',
      ),
      const _SettingItem(
        icon: Icons.help_outline_rounded,
        title: 'Help Center',
      ),
    ];

    return Scaffold(
      backgroundColor: _profileBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            const _ProfileHeaderCard(),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
            ),
            for (int i = 0; i < items.length; i++) ...[
              _SettingTileCard(item: items[i]),
              if (i < items.length - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 24),
            _LogoutButton(onTap: () => _handleLogout(context)),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Version 2.4.0',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthState.instance,
      builder: (context, _, _) {
        final name = AuthState.instance.userName;
        final email = AuthState.instance.userEmail;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.8),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/profile_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.person,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingTileCard extends StatelessWidget {
  final _SettingItem item;

  const _SettingTileCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: item.onTap ?? () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: _iconCircleBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF64748B),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _logoutBorder, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: _logoutRed,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _logoutRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
