// lib/features/addresses/presentation/addresses_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';
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

    final addressesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .collection('addresses')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return ResponsiveScreen(
      mobile: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Delivery Addresses'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddAddressSheet(context, user.id),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: _buildAddressStream(context, user.id, addressesStream, false),
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
                    onPressed: () => _showAddAddressSheet(context, user.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Address'),
                  ),
                ),
              ),
              _buildAddressStream(context, user.id, addressesStream, true),
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
              'Save delivery locations for faster checkout.',
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

  Widget _buildAddressStream(
    BuildContext context,
    String userId,
    Stream<QuerySnapshot> stream,
    bool embedded,
  ) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

        final docs = snapshot.data!.docs;

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
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _AddressCard(
              data: data,
              docId: docs[index].id,
              userId: userId,
            ).animate().fadeIn(delay: (50 * index).ms).slideX();
          },
        );
      },
    );
  }

  Future<void> _showAddAddressSheet(BuildContext context, String userId) async {
    final line1Controller = TextEditingController();
    final cityController = TextEditingController();
    final labelController = TextEditingController(text: 'Home');
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
                const SizedBox(height: 16),
                TextField(
                  controller: line1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address Line',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'City / Area',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () async {
                      if (line1Controller.text.isEmpty ||
                          cityController.text.isEmpty) {
                        return;
                      }

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('addresses')
                          .add({
                            'label': labelController.text.trim(),
                            'line1': line1Controller.text.trim(),
                            'city': cityController.text.trim(),
                            'createdAt': FieldValue.serverTimestamp(),
                          });
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

class _AddressCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String userId;

  const _AddressCard({
    required this.data,
    required this.docId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final label = (data['label'] as String?)?.trim();
    final line1 = (data['line1'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';

    return Dismissible(
      key: Key(docId),
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
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .doc(docId)
            .delete();
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
                    'Delivery Address',
                    style: AppTextStyles.h4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (label != null && label.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 90),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              line1,
              style: AppTextStyles.bodyLarge.copyWith(
                color: theme.textTheme.bodyLarge?.color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (city.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 14, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      city,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: theme.hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
