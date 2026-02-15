// lib/screens/products/product_drafts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product_draft.dart';
import '../../providers/product_draft_provider.dart';
import '../../widgets/custom_shimmer.dart';
import '../../widgets/empty_state_widget.dart';
import 'add_edit_product_screen.dart';
import '../../routes/app_router.dart';

class ProductDraftsScreen extends ConsumerWidget {
  const ProductDraftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(vendorDraftsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Drafts'),
      ),
      body: draftsAsync.when(
        data: (drafts) {
          if (drafts.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                icon: Icons.drafts_outlined,
                message: 'No saved drafts',
                actionLabel: 'Create Product',
                route: AppRouter.addEditProduct,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return _DraftCard(draft: draft);
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) => const _DraftShimmer(),
        ),
        error: (error, _) => Center(
          child: Text('Error loading drafts: $error'),
        ),
      ),
    );
  }
}

class _DraftCard extends ConsumerWidget {
  final ProductDraft draft;

  const _DraftCard({required this.draft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lastModified = draft.lastModified;
    final timeAgo = _getTimeAgo(lastModified);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          // Navigate to add/edit screen with draft
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditProductScreen(
                draftId: draft.id,
              ),
            ),
          );

          if (result == true) {
            // Refresh drafts if product was created/updated
            ref.invalidate(vendorDraftsProvider);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image preview
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.surface,
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: draft.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          draft.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported,
                            size: 32,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.image_outlined,
                        size: 32,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
              ),
              const SizedBox(width: 16),
              // Draft details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.partName.isEmpty
                          ? 'Untitled Draft'
                          : draft.partName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (draft.brand.isNotEmpty) ...[
                      Text(
                        draft.brand,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: draft.isComplete
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            draft.isComplete ? 'Complete' : 'Incomplete',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: draft.isComplete
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Draft?'),
                      content: const Text(
                        'This will permanently delete this draft. This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref
                        .read(productDraftServiceProvider)
                        .deleteDraft(draft.id);
                    ref.invalidate(vendorDraftsProvider);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class _DraftShimmer extends StatelessWidget {
  const _DraftShimmer();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CustomShimmer(
              width: 80,
              height: 80,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomShimmer(width: 150, height: 16),
                  const SizedBox(height: 8),
                  const CustomShimmer(width: 100, height: 14),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      CustomShimmer(width: 80, height: 12),
                      SizedBox(width: 16),
                      CustomShimmer(width: 60, height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
