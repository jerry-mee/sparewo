// lib/features/addresses/presentation/addresses_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/core/router/navigation_extensions.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';
import 'package:sparewo_client/features/addresses/application/saved_address_provider.dart';
import 'package:sparewo_client/features/addresses/domain/saved_address.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/auth/presentation/widgets/auth_guard_modal.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final theme = Theme.of(context);

    if (user == null) {
      return ResponsiveScreen(
        mobile: Scaffold(
          appBar: AppBar(title: const Text('Addresses')),
          body: _buildGuestState(context, ref),
        ),
        desktop: DesktopScaffold(
          widthTier: DesktopWidthTier.standard,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildGuestState(context, ref),
                const SiteFooter(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      );
    }

    final addressesAsync = ref.watch(savedAddressesStreamProvider);

    return ResponsiveScreen(
      mobile: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Delivery Addresses'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.goBackOr('/profile'),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddAddressSheet(context, ref, user.id),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: _buildAddressList(context, ref, user.id, addressesAsync, false),
      ),
      desktop: DesktopScaffold(
        widthTier: DesktopWidthTier.standard,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DesktopSection(
                title: 'Delivery Addresses',
                subtitle: 'Manage your saved delivery locations',
                padding: const EdgeInsets.only(top: 28, bottom: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () =>
                        _showAddAddressSheet(context, ref, user.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Address'),
                  ),
                ),
              ),
              _buildAddressList(context, ref, user.id, addressesAsync, true),
              const SiteFooter(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 64, color: theme.hintColor),
            const SizedBox(height: 16),
            Text(
              'Sign in to manage addresses',
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Save delivery locations for faster checkout and AutoHub pickup.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.6),
                  builder: (context) => AuthGuardModal(
                    title: 'Sign in to save addresses',
                    message:
                        'Create an account to manage your delivery locations.',
                    returnTo: GoRouterState.of(context).uri.toString(),
                  ),
                );
              },
              child: const Text('Sign In / Register'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AsyncValue<List<SavedAddress>> addressesAsync,
    bool embedded,
  ) {
    final theme = Theme.of(context);
    return addressesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load addresses: $error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (addresses) {
        if (addresses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: theme.hintColor,
                    ),
                  ).animate().scale(),
                  const SizedBox(height: 24),
                  Text('No addresses found', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Text(
                    'Add a delivery location to speed up checkout',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
            embedded ? AppSpacing.screenPadding : 108,
          ),
          shrinkWrap: embedded,
          physics: embedded
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          itemCount: addresses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final address = addresses[index];
            return _AddressCard(
              address: address,
              userId: userId,
            ).animate().fadeIn(delay: (50 * index).ms).slideX();
          },
        );
      },
    );
  }

  Future<void> _showAddAddressSheet(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final currentUser = ref.read(currentUserProvider).asData?.value;
    final labelController = TextEditingController(text: 'Home');
    final line1Controller = TextEditingController();
    final line2Controller = TextEditingController();
    final cityController = TextEditingController();
    final landmarkController = TextEditingController();
    final phoneController = TextEditingController(
      text: currentUser?.phone ?? '',
    );
    final recipientController = TextEditingController(
      text: currentUser?.name ?? '',
    );
    final isDefault = ValueNotifier<bool>(true);
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('New Address', style: AppTextStyles.h3),
                const SizedBox(height: 24),
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label (e.g. Home, Work)',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: recipientController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: line1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 1',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: line2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 2 (Optional)',
                    prefixIcon: Icon(Icons.home_work_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'City / Area',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: landmarkController,
                  decoration: const InputDecoration(
                    labelText: 'Landmark (Optional)',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: isDefault,
                  builder: (context, value, _) {
                    return SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Set as default address'),
                      value: value,
                      onChanged: (next) => isDefault.value = next,
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () async {
                      if (line1Controller.text.trim().isEmpty) return;

                      final repo = ref.read(savedAddressRepositoryProvider);
                      await repo.saveAddress(
                        userId: userId,
                        makeDefault: isDefault.value,
                        address: SavedAddress(
                          id: '',
                          label: labelController.text.trim(),
                          line1: line1Controller.text.trim(),
                          line2: line2Controller.text.trim(),
                          city: cityController.text.trim(),
                          landmark: landmarkController.text.trim(),
                          phone: phoneController.text.trim(),
                          recipientName: recipientController.text.trim(),
                          isDefault: isDefault.value,
                        ),
                      );

                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save Address'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddressCard extends ConsumerWidget {
  const _AddressCard({required this.address, required this.userId});

  final SavedAddress address;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(address.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref
            .read(savedAddressRepositoryProvider)
            .deleteAddress(userId: userId, addressId: address.id);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.cardShadow,
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    address.shortTitle,
                    style: AppTextStyles.h4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Default',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              address.subtitle,
              style: AppTextStyles.bodyLarge.copyWith(
                color: theme.textTheme.bodyLarge?.color,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if ((address.recipientName ?? '').trim().isNotEmpty ||
                (address.phone ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                [
                  (address.recipientName ?? '').trim(),
                  (address.phone ?? '').trim(),
                ].where((item) => item.isNotEmpty).join(' • '),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
            if (!address.isDefault) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    ref
                        .read(savedAddressRepositoryProvider)
                        .setDefaultAddress(
                          userId: userId,
                          addressId: address.id,
                        );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Set as default'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
