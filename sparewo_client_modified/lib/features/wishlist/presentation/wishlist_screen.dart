// lib/features/wishlist/presentation/wishlist_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/auth/presentation/widgets/auth_guard_modal.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;

    if (user == null) {
      return ResponsiveScreen(
        mobile: Scaffold(
          appBar: AppBar(title: const Text('Wishlist')),
          body: _buildGuestState(context),
        ),
        desktop: DesktopScaffold(
          widthTier: DesktopWidthTier.standard,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildGuestState(context),
                const SiteFooter(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      );
    }

    final wishlistStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .collection('wishlist')
        .snapshots();

    return ResponsiveScreen(
      mobile: Scaffold(
        appBar: AppBar(title: const Text('Wishlist')),
        body: _buildWishlistStream(context, wishlistStream, user.id, false),
      ),
      desktop: DesktopScaffold(
        widthTier: DesktopWidthTier.standard,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DesktopSection(
                title: 'Wishlist',
                subtitle: 'Save parts you want to purchase later',
                padding: EdgeInsets.only(top: 28, bottom: 8),
                child: SizedBox.shrink(),
              ),
              _buildWishlistStream(context, wishlistStream, user.id, true),
              const SiteFooter(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 64, color: theme.hintColor),
            const SizedBox(height: 16),
            Text(
              'Sign in to view your wishlist',
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Save items you want to buy later.',
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
                    title: 'Sign in to access wishlist',
                    message: 'Create an account to save your favourite parts.',
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

  Widget _buildWishlistStream(
    BuildContext context,
    Stream<QuerySnapshot> stream,
    String userId,
    bool isDesktop,
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
                  Icon(Icons.favorite_border, size: 64, color: theme.hintColor),
                  const SizedBox(height: 16),
                  Text('Your wishlist is empty.', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Text(
                    'Save items you want to buy later.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        if (isDesktop) {
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.9,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _WishlistCard(
                data: docs[index].data() as Map<String, dynamic>,
                docId: docs[index].id,
                userId: userId,
              );
            },
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            return _WishlistCard(
              data: docs[index].data() as Map<String, dynamic>,
              docId: docs[index].id,
              userId: userId,
            );
          },
        );
      },
    );
  }

  // Uses shared helper below.
}

class _WishlistCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String userId;

  const _WishlistCard({
    required this.data,
    required this.docId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] as String?) ?? 'Product Name';
    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
    final image = (data['image'] as String?) ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            image: image.isNotEmpty
                ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
                : null,
          ),
          child: image.isEmpty
              ? const Icon(Icons.image_not_supported, size: 20)
              : null,
        ),
        title: Text(name, style: AppTextStyles.h4.copyWith(fontSize: 16)),
        subtitle: Text(
          'UGX ${_formatCurrency(price)}',
          style: AppTextStyles.price.copyWith(fontSize: 14),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('wishlist')
                .doc(docId)
                .delete();
          },
        ),
      ),
    );
  }
}

String _formatCurrency(double amount) {
  return amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}
