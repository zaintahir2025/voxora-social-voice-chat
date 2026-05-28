import 'package:flutter/material.dart';

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
    _NavItem(AppView.feed, Icons.home_rounded, 'Home'),
    _NavItem(AppView.friends, Icons.people_alt_rounded, 'Friends'),
    _NavItem(AppView.messages, Icons.chat_bubble_rounded, 'Chat'),
    _NavItem(AppView.games, Icons.videogame_asset_rounded, 'Play'),
    _NavItem(AppView.profile, Icons.face_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;
    final app = context.watch<AppProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          Row(
            children: [
              if (isWide) const _Sidebar(),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const _Topbar(),
                                    if (app.notice.isNotEmpty)
                                      const _NoticeBar(),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        isWide ? 12 : 6,
                                        4,
                                        isWide ? 12 : 6,
                                        32,
                                      ),
                                      child: const _ViewContent(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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
          ? SizedBox(
              width: 44,
              height: 44,
              child: FloatingActionButton(
                tooltip: 'New Post',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CreatePostPage()),
                ),
                child: const Icon(Icons.add_rounded, size: 24),
              ),
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
      width: 240,
      color: scheme.surface,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Image.asset(
                      app.darkMode
                          ? 'assets/logo_dark.png'
                          : 'assets/logo_light.png',
                      width: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    ...HomeScreen._items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 0),
                        child: _NavButton(
                          item: item,
                          active: app.view == item.view,
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        if (app.profile != null) {
                          app.viewProfile(app.profile!.id);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            UserAvatar(
                              url: app.profile?.avatarUrl,
                              size: 32,
                              online: app.profile?.status == 'online',
                              seed: app.profile?.handle,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    app.profile?.fullName ?? 'Friend',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '@${app.profile?.handle ?? ''}',
                                    style: TextStyle(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: app.signOut,
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Log out', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

    return InkWell(
      onTap: () => app.setView(item.view),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            _UnreadBadge(
              count: unread,
              child: Icon(
                item.icon,
                size: 20,
                color: active
                    ? scheme.onSurface
                    : scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                color: active
                    ? scheme.onSurface
                    : scheme.onSurface.withValues(alpha: 0.6),
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: HomeScreen._items.map((item) {
              final active = app.view == item.view;
              final unread = item.view == AppView.messages
                  ? app.unreadMessageCount
                  : 0;
              return InkWell(
                onTap: () => app.setView(item.view),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? scheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _UnreadBadge(
                    count: unread,
                    child: Icon(
                      item.icon,
                      size: 28,
                      color: active
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
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
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: scheme.error,
              shape: BoxShape.circle,
            ),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
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
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 980;

    final titles = {
      AppView.feed: 'Home',
      AppView.friends: 'Friends',
      AppView.messages: 'Chats',
      AppView.games: 'Games',
      AppView.profile: 'Profile',
    };

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(isWide ? 32 : 16, 20, isWide ? 32 : 16, 20),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: (!isWide && app.view == AppView.feed)
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        app.darkMode
                            ? 'assets/logo_dark.png'
                            : 'assets/logo_light.png',
                        height: 38,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Text(
                      app.view == AppView.feed ? '' : (titles[app.view] ?? ''),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
            ),
            const _NotificationBell(),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                app.darkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                size: 20,
              ),
              tooltip: 'Toggle Theme',
              onPressed: app.toggleTheme,
              color: scheme.onSurface,
            ),
            if (!isWide) ...[
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  if (app.profile != null) {
                    app.viewProfile(app.profile!.id);
                  }
                },
                customBorder: const CircleBorder(),
                child: UserAvatar(
                  url: app.profile?.avatarUrl,
                  size: 44,
                  online: app.profile?.status == 'online',
                  seed: app.profile?.handle,
                ),
              ),
            ],
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
    final scheme = Theme.of(context).colorScheme;
    final unread = app.unreadNotificationCount;
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_rounded, size: 20),
          tooltip: 'Notifications',
          color: scheme.onSurface,
          onPressed: () {
            final isMobile = MediaQuery.of(context).size.width < 600;
            if (isMobile) {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: const _NotificationsPanel(),
                ),
              );
            } else {
              showGeneralDialog<void>(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Dismiss',
                barrierColor: Colors.transparent,
                pageBuilder: (context, _, __) {
                  return Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 70, right: 20),
                      child: Material(
                        type: MaterialType.transparency,
                        child: Container(
                          width: 380,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: const _NotificationsPanel(),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
        if (unread > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: scheme.error,
                shape: BoxShape.circle,
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
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

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 560),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (notifications.isNotEmpty) ...[
                  TextButton(
                    onPressed: app.unreadNotificationCount == 0
                        ? null
                        : app.markNotificationsRead,
                    child: const Text('Mark Read'),
                  ),
                  TextButton(
                    onPressed: app.clearNotifications,
                    child: const Text('Clear All'),
                  ),
                ],
              ],
            ),
            const Divider(),
            if (notifications.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No new notifications 🌟',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 18,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: item.read
                            ? scheme.surfaceContainerHighest
                            : scheme.primary.withValues(alpha: 0.1),
                        foregroundColor: item.read
                            ? scheme.onSurface
                            : scheme.primary,
                        child: Icon(item.icon),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.read
                              ? FontWeight.normal
                              : FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        app.openNotification(item);
                        Navigator.pop(context);
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: notifications.length,
                ),
              ),
          ],
        ),
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

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      url: caller?.avatarUrl,
                      size: 56,
                      seed: caller?.handle,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            caller?.fullName ?? 'Someone',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'is calling you!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () => app.declineCall(call),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () {
                        app.selectConversation(call.conversationId);
                        showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => CallDialog(call: call),
                        );
                      },
                      icon: Icon(
                        Icons.phone_in_talk_rounded,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeBar extends StatelessWidget {
  const _NoticeBar();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.error,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              app.notice,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          InkWell(
            onTap: app.clearNotice,
            child: const Icon(
              Icons.close_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
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
