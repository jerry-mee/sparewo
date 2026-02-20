import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/auth/presentation/widgets/auth_guard_modal.dart';
import 'package:sparewo_client/features/notifications/application/notification_provider.dart';

enum _NotificationFilter { all, unread }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _selected = <String>{};
  bool _isSubmitting = false;
  _NotificationFilter _filter = _NotificationFilter.all;

  bool get _selectionMode => _selected.isNotEmpty;

  Future<void> _runAction(Future<void> Function() action) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openNotification(UserNotification notification) async {
    final actions = ref.read(notificationActionsProvider);
    if (!notification.read) {
      await _runAction(() => actions.markRead([notification.id]));
    }

    if (!mounted) return;
    final target = _resolveTarget(notification);
    if (target != null && target.isNotEmpty) {
      context.push(target);
    }
  }

  String? _resolveTarget(UserNotification notification) {
    final link = notification.link;
    if (link != null && link.isNotEmpty && link.startsWith('/')) {
      return link;
    }

    final type = notification.type?.toLowerCase();
    final itemId = notification.itemId;

    if (type == 'order' && itemId != null && itemId.isNotEmpty) {
      return '/order/$itemId';
    }
    if (type == 'booking' && itemId != null && itemId.isNotEmpty) {
      return '/booking/$itemId';
    }
    if (type == 'add_car_nudge') {
      return '/add-car?nudge=true';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateChangesProvider).asData?.value;
    final userId = authUser?.uid;
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return ResponsiveScreen(
      mobile: Scaffold(
        appBar: _buildAppBar(context, userId),
        body: _buildBody(context, notificationsAsync, userId),
      ),
      desktop: DesktopScaffold(
        widthTier: DesktopWidthTier.standard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DesktopSection(
              title: 'Notifications',
              subtitle: 'Updates, orders, and booking alerts',
              child: _buildDesktopActions(context, notificationsAsync, userId),
            ),
            Expanded(child: _buildBody(context, notificationsAsync, userId)),
            const SiteFooter(),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String? userId) {
    final canGoBack = context.canPop();

    return AppBar(
      title: const Text('Notifications'),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () {
          if (canGoBack) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      actions: [
        if (_selectionMode)
          IconButton(
            tooltip: 'Clear selection',
            onPressed: _isSubmitting
                ? null
                : () => setState(() {
                    _selected.clear();
                  }),
            icon: const Icon(Icons.close),
          ),
        PopupMenuButton<String>(
          enabled: !_isSubmitting,
          onSelected: (value) {
            if (userId == null || userId.isEmpty) return;
            final actions = ref.read(notificationActionsProvider);
            if (value == 'mark_all') {
              _runAction(() => actions.markAllRead(userId));
            }
            if (value == 'delete_all') {
              _runAction(() async {
                await actions.deleteAll(userId);
                if (mounted) {
                  setState(() => _selected.clear());
                }
              });
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'mark_all', child: Text('Mark all as read')),
            PopupMenuItem(value: 'delete_all', child: Text('Delete all')),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopActions(
    BuildContext context,
    AsyncValue<List<UserNotification>> notificationsAsync,
    String? userId,
  ) {
    final notifications = notificationsAsync.asData?.value ?? const [];
    final unread = notifications.where((n) => !n.read).length;

    return Row(
      children: [
        Text(
          unread > 0 ? '$unread unread' : 'All caught up',
          style: AppTextStyles.bodyMedium,
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: (_isSubmitting || userId == null || userId.isEmpty)
              ? null
              : () {
                  _runAction(
                    () => ref
                        .read(notificationActionsProvider)
                        .markAllRead(userId),
                  );
                },
          icon: const Icon(Icons.done_all),
          label: const Text('Mark all read'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: (_isSubmitting || userId == null || userId.isEmpty)
              ? null
              : () {
                  _runAction(() async {
                    await ref
                        .read(notificationActionsProvider)
                        .deleteAll(userId);
                    if (mounted) {
                      setState(() => _selected.clear());
                    }
                  });
                },
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('Delete all'),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<UserNotification>> notificationsAsync,
    String? userId,
  ) {
    if (userId == null || userId.isEmpty) {
      return _buildGuestState(context);
    }

    return notificationsAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading your notifications...'),
          ],
        ),
      ),
      error: (error, _) =>
          Center(child: Text('Failed to load notifications: $error')),
      data: (notifications) {
        final filtered = _filter == _NotificationFilter.unread
            ? notifications.where((n) => !n.read).toList(growable: false)
            : notifications;

        return Column(
          children: [
            _buildFilterBar(),
            if (filtered.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 46),
                      SizedBox(height: 12),
                      Text('No notifications found'),
                    ],
                  ),
                ),
              )
            else ...[
              if (_selectionMode)
                _SelectionActionBar(
                  selectedCount: _selected.length,
                  isSubmitting: _isSubmitting,
                  onMarkRead: () {
                    _runAction(() async {
                      await ref
                          .read(notificationActionsProvider)
                          .markRead(_selected.toList(growable: false));
                      if (mounted) {
                        setState(() => _selected.clear());
                      }
                    });
                  },
                  onDelete: () {
                    _runAction(() async {
                      await ref
                          .read(notificationActionsProvider)
                          .delete(_selected.toList(growable: false));
                      if (mounted) {
                        setState(() => _selected.clear());
                      }
                    });
                  },
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(userNotificationsProvider);
                    await ref.read(userNotificationsProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notification = filtered[index];
                      final selected = _selected.contains(notification.id);

                      return _NotificationTile(
                        notification: notification,
                        selected: selected,
                        selectionMode: _selectionMode,
                        isSubmitting: _isSubmitting,
                        onTap: () {
                          if (_selectionMode) {
                            setState(() {
                              if (selected) {
                                _selected.remove(notification.id);
                              } else {
                                _selected.add(notification.id);
                              }
                            });
                            return;
                          }
                          _openNotification(notification);
                        },
                        onLongPress: () {
                          if (_isSubmitting) return;
                          setState(() {
                            if (selected) {
                              _selected.remove(notification.id);
                            } else {
                              _selected.add(notification.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFilterBar() {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _filter == _NotificationFilter.all,
            onSelected: (_) {
              setState(() {
                _filter = _NotificationFilter.all;
                _selected.clear();
              });
            },
          ),
          const SizedBox(width: 10),
          ChoiceChip(
            label: Text(unreadCount > 0 ? 'Unread ($unreadCount)' : 'Unread'),
            selected: _filter == _NotificationFilter.unread,
            onSelected: (_) {
              setState(() {
                _filter = _NotificationFilter.unread;
                _selected.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuestState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 10),
            Text(
              'Sign in to view notifications',
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.6),
                  builder: (context) => const AuthGuardModal(
                    title: 'Sign in required',
                    message: 'Sign in to see orders, bookings, and updates.',
                  ),
                );
              },
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionActionBar extends StatelessWidget {
  final int selectedCount;
  final bool isSubmitting;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _SelectionActionBar({
    required this.selectedCount,
    required this.isSubmitting,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text('$selectedCount selected', style: AppTextStyles.labelLarge),
          const Spacer(),
          TextButton.icon(
            onPressed: isSubmitting ? null : onMarkRead,
            icon: const Icon(Icons.done_all),
            label: const Text('Mark read'),
          ),
          TextButton.icon(
            onPressed: isSubmitting ? null : onDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final UserNotification notification;
  final bool selectionMode;
  final bool selected;
  final bool isSubmitting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NotificationTile({
    required this.notification,
    required this.selectionMode,
    required this.selected,
    required this.isSubmitting,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.read;
    final createdAt = notification.createdAt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSubmitting ? null : onTap,
        onLongPress: isSubmitting ? null : onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.08)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : theme.dividerColor.withValues(alpha: 0.6),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Checkbox(value: selected, onChanged: (_) => onTap()),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 2),
                  child: Icon(
                    isUnread
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    color: isUnread ? AppColors.primary : theme.hintColor,
                    size: 20,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: isUnread
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(createdAt),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: theme.hintColor),
            ],
          ),
        ),
      ),
    );
  }
}
