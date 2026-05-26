import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../views/feed_view.dart';
import '../views/friends_view.dart';
import '../views/games_view.dart';
import '../views/messages_view.dart';
import '../views/profile_view.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _items = [
    _NavItem(AppView.feed, Icons.dynamic_feed_outlined, 'Feed'),
    _NavItem(AppView.friends, Icons.people_outline, 'Friends'),
    _NavItem(AppView.messages, Icons.chat_bubble_outline, 'Chat'),
    _NavItem(AppView.games, Icons.sports_esports_outlined, 'Games'),
    _NavItem(AppView.profile, Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;
    final app = context.watch<AppProvider>();
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              if (isWide) const _Sidebar(),
              Expanded(
                child: Column(
                  children: [
                    const _Topbar(),
                    if (app.notice.isNotEmpty) const _NoticeBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          isWide ? 28 : 14,
                          0,
                          isWide ? 28 : 14,
                          24,
                        ),
                        child: const _ViewContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const _IncomingCallOverlay(),
        ],
      ),
      floatingActionButton: app.view == AppView.feed
          ? FloatingActionButton.small(
              tooltip: 'Post',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CreatePostPage()),
              ),
              child: const Icon(Icons.post_add_outlined),
            )
          : null,
      bottomNavigationBar: isWide ? null : const _BottomNav(),
    );
  }
}

class _NavItem {
  final AppView view;
  final IconData icon;
  final String label;

  const _NavItem(this.view, this.icon, this.label);
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 18),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/voxora-mark.svg',
                      width: 34,
                      height: 34,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Voxora',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              ...HomeScreen._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _NavButton(item: item, active: app.view == item.view),
                ),
              ),
              const Spacer(),
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    UserAvatar(
                      url: app.profile?.avatarUrl,
                      size: 38,
                      online: app.profile?.status == 'online',
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.profile?.fullName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '@${app.profile?.handle ?? ''} - ${_statusLabel(app.profile?.status)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: app.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String? status) {
    return switch (status) {
      'online' => 'Online',
      'away' => 'Away',
      _ => 'Offline',
    };
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool active;

  const _NavButton({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final scheme = Theme.of(context).colorScheme;
    final unread = item.view == AppView.messages ? app.unreadMessageCount : 0;
    return Tooltip(
      message: item.label,
      child: InkWell(
        onTap: () => app.setView(item.view),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active
                ? scheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _UnreadBadge(
                count: unread,
                child: Icon(
                  item.icon,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  color: active ? scheme.primary : scheme.onSurface,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return NavigationBar(
      selectedIndex: HomeScreen._items.indexWhere(
        (item) => item.view == app.view,
      ),
      onDestinationSelected: (index) =>
          app.setView(HomeScreen._items[index].view),
      destinations: HomeScreen._items
          .map(
            (item) => NavigationDestination(
              icon: _UnreadBadge(
                count: item.view == AppView.messages
                    ? app.unreadMessageCount
                    : 0,
                child: Icon(item.icon),
              ),
              selectedIcon: _UnreadBadge(
                count: item.view == AppView.messages
                    ? app.unreadMessageCount
                    : 0,
                child: Icon(item.icon),
              ),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const _UnreadBadge({required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -8,
          top: -7,
          child: Container(
            constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.error,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.surface, width: 1.5),
            ),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: TextStyle(
                color: scheme.onError,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Topbar extends StatelessWidget {
  const _Topbar();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final titles = {
      AppView.feed: 'Feed',
      AppView.friends: 'Friends',
      AppView.messages: 'Chat',
      AppView.games: 'Games',
      AppView.profile: 'Profile',
    };
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titles[app.view] ?? '',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Signed in as @${app.profile?.handle ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const _NotificationBell(),
            const SizedBox(width: 6),
            ActionIconButton(
              icon: app.darkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              tooltip: app.darkMode
                  ? 'Switch to light theme'
                  : 'Switch to dark theme',
              onPressed: app.toggleTheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final unread = app.unreadNotificationCount;
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Notifications',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => const _NotificationsPanel(),
            ),
            icon: const Icon(Icons.notifications_none_outlined),
          ),
          if (unread > 0)
            Positioned(
              right: 3,
              top: 3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.error,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scheme.surface, width: 2),
                ),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: TextStyle(
                    color: scheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IncomingCallOverlay extends StatelessWidget {
  const _IncomingCallOverlay();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final call = app.incomingCall;
    if (call == null) return const SizedBox.shrink();

    final caller = app.profileById(call.callerId);
    final scheme = Theme.of(context).colorScheme;
    final isVideo = call.callType == 'video';

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Material(
                elevation: 18,
                color: scheme.surface,
                shadowColor: Colors.black.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      UserAvatar(
                        url: caller?.avatarUrl,
                        size: 48,
                        online: caller?.status == 'online',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              caller?.fullName ?? 'Incoming call',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              isVideo
                                  ? 'Incoming video call'
                                  : 'Incoming voice call',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Decline',
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                        ),
                        onPressed: () => app.declineCall(call),
                        icon: const Icon(Icons.call_end),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Answer',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          app.selectConversation(call.conversationId);
                          showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => CallDialog(call: call),
                          );
                        },
                        icon: Icon(isVideo ? Icons.videocam : Icons.call),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsPanel extends StatelessWidget {
  const _NotificationsPanel();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final notifications = app.notifications;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: app.unreadNotificationCount == 0
                        ? null
                        : app.markNotificationsRead,
                    child: const Text('Mark read'),
                  ),
                  TextButton(
                    onPressed: notifications.isEmpty
                        ? null
                        : app.clearNotifications,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (notifications.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No notifications yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item.read
                              ? scheme.surfaceContainerHighest
                              : scheme.primary.withValues(alpha: 0.14),
                          foregroundColor: item.read
                              ? scheme.onSurfaceVariant
                              : scheme.primary,
                          child: Icon(item.icon, size: 20),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: item.read
                                ? FontWeight.w700
                                : FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          '${item.body}\n${_notificationTime(item.createdAt)}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor: item.read
                            ? null
                            : scheme.primary.withValues(alpha: 0.06),
                        onTap: () {
                          app.openNotification(item);
                          Navigator.pop(context);
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemCount: notifications.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _notificationTime(DateTime createdAt) {
    final local = createdAt.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${local.month}/${local.day}/${local.year}';
  }
}

class _NoticeBar extends StatelessWidget {
  const _NoticeBar();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: InkWell(
        onTap: app.clearNotice,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: scheme.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(app.notice)),
              const Icon(Icons.close, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewContent extends StatelessWidget {
  const _ViewContent();

  @override
  Widget build(BuildContext context) {
    switch (context.watch<AppProvider>().view) {
      case AppView.feed:
        return const FeedView();
      case AppView.friends:
        return const FriendsView();
      case AppView.messages:
        return const MessagesView();
      case AppView.games:
        return const GamesView();
      case AppView.profile:
        return const ProfileView();
    }
  }
}
