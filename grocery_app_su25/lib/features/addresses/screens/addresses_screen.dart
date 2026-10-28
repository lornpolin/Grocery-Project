import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/address.dart';
import '../../../providers/app_providers.dart';
import '../../cart/widgets/checkout_widgets.dart';

const _addrBg = Color(0xFFF8FAFC);
const _addrTitle = Color(0xFF0F172A);
const _addrMuted = Color(0xFF64748B);
const _addrSoftBlue = Color(0xFFEAF3FC);
const _addrBorder = Color(0xFFE2E8F0);

IconData iconForAddressLabel(String label) {
  switch (label.trim().toLowerCase()) {
    case 'home':
      return Icons.home_rounded;
    case 'office':
    case 'work':
      return Icons.work_outline_rounded;
    case 'apartment':
      return Icons.apartment_rounded;
    default:
      return Icons.location_on_outlined;
  }
}

Future<void> showAddressFormSheet(
  BuildContext context, {
  SavedAddress? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AddressFormSheet(existing: existing),
  );
}

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  Future<void> _openAddressForm(
    BuildContext context,
    WidgetRef ref, {
    SavedAddress? existing,
  }) async {
    await showAddressFormSheet(context, existing: existing);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: _addrBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56,
        leadingWidth: 64,
        leading: Center(
          child: InkResponse(
            onTap: () => _back(context),
            radius: 22,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.6),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        title: const Text(
          'Saved Addresses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _addrTitle,
          ),
        ),
        actions: [
          if (addresses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _addrSoftBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${addresses.length} saved',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(addressesProvider.notifier).refresh(),
        child: addresses.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 90),
                  _EmptyAddresses(
                    onAdd: () => _openAddressForm(context, ref),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount: addresses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  return _AddressCard(
                    address: address,
                    onSelectDefault: () {
                      ref
                          .read(addressesProvider.notifier)
                          .setDefault(address.id);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              '${address.label} set as default delivery address',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    },
                    onEdit: () =>
                        _openAddressForm(context, ref, existing: address),
                    onDelete: () {
                      ref
                          .read(addressesProvider.notifier)
                          .removeAddress(address.id);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text('Removed ${address.label} address'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    },
                  );
                },
              ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: PillButton(
            label: '+ Add New Address',
            onPressed: () => _openAddressForm(context, ref),
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final SavedAddress address;
  final VoidCallback onSelectDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onSelectDefault,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDefault = address.isDefault;
    final recipient = address.recipientName?.trim() ?? '';
    final phone = address.phone?.trim() ?? '';
    final contactLine = [
      if (recipient.isNotEmpty) recipient,
      if (phone.isNotEmpty) phone,
    ].join(' · ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSelectDefault,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDefault ? AppColors.primary : _addrBorder,
              width: isDefault ? 1.6 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDefault ? AppColors.primary : _addrSoftBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      iconForAddressLabel(address.label),
                      color: isDefault ? Colors.white : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              address.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _addrTitle,
                              ),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _addrSoftBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (contactLine.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            contactLine,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _addrMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Edit address',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color: _addrMuted,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete address',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: _addrBorder),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 17,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address.fullAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _addrTitle,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isDefault) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onSelectDefault,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                    ),
                    label: const Text(
                      'Set as Default',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  final SavedAddress? existing;

  const _AddressFormSheet({this.existing});

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  static const _labels = ['Home', 'Office', 'Apartment', 'Other'];

  late String _selectedLabel;
  late final TextEditingController _recipientCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late bool _isDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _selectedLabel = e?.label ?? 'Home';
    _recipientCtrl = TextEditingController(
      text: e?.recipientName ?? AuthState.instance.userName,
    );
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _cityCtrl = TextEditingController(text: e?.city ?? 'Phnom Penh');
    _isDefault = e?.isDefault ?? true;
  }

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final street = _addressCtrl.text.trim();
    if (street.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please enter a street address')),
        );
      return;
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(addressesProvider.notifier);
      if (widget.existing != null) {
        await notifier.updateAddress(
          widget.existing!.id,
          label: _selectedLabel,
          recipientName: _recipientCtrl.text,
          phone: _phoneCtrl.text,
          address: street,
          city: _cityCtrl.text,
          isDefault: _isDefault,
        );
      } else {
        await notifier.addAddress(
          label: _selectedLabel,
          recipientName: _recipientCtrl.text,
          phone: _phoneCtrl.text,
          address: street,
          city: _cityCtrl.text,
          isDefault: _isDefault,
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'Add New Address' : 'Edit Address',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _addrTitle,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Address Label',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _addrMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in _labels)
                  ChoiceChip(
                    label: Text(label),
                    selected: _selectedLabel.toLowerCase() ==
                        label.toLowerCase(),
                    onSelected: (_) => setState(() => _selectedLabel = label),
                    selectedColor: AppColors.primary,
                    backgroundColor: _addrBg,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _selectedLabel.toLowerCase() ==
                              label.toLowerCase()
                          ? Colors.white
                          : _addrTitle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _selectedLabel.toLowerCase() ==
                                label.toLowerCase()
                            ? AppColors.primary
                            : _addrBorder,
                      ),
                    ),
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _FormField(
              controller: _addressCtrl,
              label: 'Street Address *',
              hint: 'e.g. 83 Street 7B, Sangkat Tonle Bassac',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _cityCtrl,
              label: 'City / Province',
              hint: 'Phnom Penh',
              icon: Icons.location_city_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    controller: _recipientCtrl,
                    label: 'Recipient Name',
                    hint: 'Your name',
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FormField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    hint: '012 345 678',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: const Text(
                'Set as default delivery address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _addrTitle,
                ),
              ),
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
            ),
            const SizedBox(height: 12),
            PillButton(
              label: _saving ? 'Saving...' : 'Save Address',
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _addrMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: _addrBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _addrBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _addrMuted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 14, color: _addrTitle),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyAddresses({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: const BoxDecoration(
                color: _addrSoftBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No saved addresses yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _addrTitle,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Save your home or office address for faster checkout and accurate grocery delivery.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: _addrMuted,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 210,
              child: PillButton(
                label: 'Add First Address',
                onPressed: onAdd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
