import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../views/feed_view.dart';
import '../views/friends_view.dart';
import '../views/games_view.dart';
import '../views/messages_view.dart';
import '../views/profile_view.dart';
import '../widgets/common_widgets.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _items = [
    _NavItem(AppView.feed, Icons.radar_outlined, 'FEED'),
    _NavItem(AppView.friends, Icons.group_work_outlined, 'SQUAD'),
    _NavItem(AppView.messages, Icons.chat_outlined, 'COMMS'),
    _NavItem(AppView.games, Icons.gamepad_outlined, 'ARCADE'),
    _NavItem(AppView.profile, Icons.account_circle_outlined, 'SYSTEM'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;
    final app = context.watch<AppProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          // Futuristic Background Gradients
          Positioned.fill(
            child: Container(color: scheme.surface),
          ),
          Positioned(
            top: -150,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [VoxoraColors.neonPurple.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [VoxoraColors.neonCyan.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
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
                        padding: EdgeInsets.fromLTRB(isWide ? 28 : 14, 0, isWide ? 28 : 14, 24),
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
          ? FloatingActionButton(
              tooltip: 'NEW TRANSMISSION',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CreatePostPage())),
              child: const Icon(Icons.add),
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
      width: 280,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.6),
        border: Border(right: BorderSide(color: scheme.primary.withValues(alpha: 0.2), width: 2)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      SvgPicture.asset('assets/voxora-mark.svg', width: 40, height: 40, colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VOXORA', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3, color: scheme.onSurface)),
                            Text('NEURAL NETWORK', style: GoogleFonts.spaceGrotesk(fontSize: 10, letterSpacing: 2, color: scheme.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ...HomeScreen._items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _NavButton(item: item, active: app.view == item.view))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        UserAvatar(url: app.profile?.avatarUrl, size: 40, online: app.profile?.status == 'online'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(app.profile?.handle ?? 'UNKNOWN', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                              Text(_statusLabel(app.profile?.status), style: GoogleFonts.spaceGrotesk(fontSize: 10, color: _statusColor(app.profile?.status))),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.power_settings_new), onPressed: app.signOut, color: VoxoraColors.neonPink),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(String? status) {
    return switch (status) { 'online' => 'ONLINE', 'away' => 'STANDBY', _ => 'OFFLINE' };
  }

  Color _statusColor(String? status) {
    return switch (status) { 'online' => VoxoraColors.neonCyan, 'away' => VoxoraColors.neonPurple, _ => VoxoraColors.darkBorder };
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
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? scheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: active ? Border.all(color: scheme.primary.withValues(alpha: 0.5)) : null,
          boxShadow: active ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)] : [],
        ),
        child: Row(
          children: [
            _UnreadBadge(count: unread, child: Icon(item.icon, color: active ? scheme.primary : scheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(width: 16),
            Text(item.label, style: GoogleFonts.spaceGrotesk(color: active ? scheme.primary : scheme.onSurface.withValues(alpha: 0.5), fontWeight: active ? FontWeight.bold : FontWeight.normal, letterSpacing: 2)),
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
        color: scheme.surface.withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: scheme.primary.withValues(alpha: 0.3))),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            indicatorColor: scheme.primary.withValues(alpha: 0.2),
            selectedIndex: HomeScreen._items.indexWhere((item) => item.view == app.view),
            onDestinationSelected: (index) => app.setView(HomeScreen._items[index].view),
            destinations: HomeScreen._items.map((item) => NavigationDestination(
              icon: _UnreadBadge(count: item.view == AppView.messages ? app.unreadMessageCount : 0, child: Icon(item.icon, color: scheme.onSurface.withValues(alpha: 0.5))),
              selectedIcon: _UnreadBadge(count: item.view == AppView.messages ? app.unreadMessageCount : 0, child: Icon(item.icon, color: scheme.primary)),
              label: item.label,
            )).toList(),
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -8,
          top: -8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: VoxoraColors.neonPink, shape: BoxShape.circle, boxShadow: [BoxShadow(color: VoxoraColors.neonPink.withValues(alpha: 0.5), blurRadius: 4)]),
            child: Text(count > 9 ? '9+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
    final titles = {
      AppView.feed: 'GLOBAL FEED',
      AppView.friends: 'SQUADRON',
      AppView.messages: 'COMMUNICATIONS',
      AppView.games: 'VIRTUAL ARCADE',
      AppView.profile: 'SYSTEM PROFILE',
    };
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titles[app.view] ?? '', style: Theme.of(context).textTheme.headlineMedium),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: scheme.primary.withValues(alpha: 0.3))),
                    child: Text('LINK ESTABLISHED', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: scheme.primary, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
            const _NotificationBell(),
            const SizedBox(width: 8),
            ActionIconButton(
              icon: app.darkMode ? Icons.light_mode : Icons.dark_mode,
              tooltip: 'TOGGLE THEME',
              onPressed: app.toggleTheme, // Added back the theme switcher successfully!
            ),
            const SizedBox(width: 8),
            UserAvatar(url: app.profile?.avatarUrl, size: 40, online: app.profile?.status == 'online'),
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
    return Stack(
      children: [
        ActionIconButton(
          icon: Icons.notifications_outlined,
          tooltip: 'ALERTS',
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            builder: (_) => const _NotificationsPanel(),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: VoxoraColors.neonPink, shape: BoxShape.circle),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('SYSTEM ALERTS', style: Theme.of(context).textTheme.titleLarge)),
                  if (notifications.isNotEmpty) ...[
                    TextButton(onPressed: app.unreadNotificationCount == 0 ? null : app.markNotificationsRead, child: const Text('MARK READ')),
                    TextButton(onPressed: app.clearNotifications, child: const Text('PURGE')),
                  ]
                ],
              ),
              const Divider(),
              if (notifications.isEmpty)
                const Expanded(child: Center(child: Text('NO NEW ALERTS')))
              else
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item.read ? scheme.surfaceContainerHighest : scheme.primary.withValues(alpha: 0.2),
                          foregroundColor: item.read ? scheme.onSurface : scheme.primary,
                          child: Icon(item.icon),
                        ),
                        title: Text(item.title, style: TextStyle(fontWeight: item.read ? FontWeight.normal : FontWeight.bold)),
                        subtitle: Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () { app.openNotification(item); Navigator.pop(context); },
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(),
                    itemCount: notifications.length,
                  ),
                ),
            ],
          ),
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
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VoxoraColors.neonCyan, width: 2),
                  boxShadow: [BoxShadow(color: VoxoraColors.neonCyan.withValues(alpha: 0.3), blurRadius: 20)],
                ),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          UserAvatar(url: caller?.avatarUrl, size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(caller?.fullName ?? 'UNKNOWN SIGNAL', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('INCOMING TRANSMISSION', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: VoxoraColors.neonCyan, letterSpacing: 1)),
                              ],
                            ),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: VoxoraColors.neonPink),
                            onPressed: () => app.declineCall(call),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: VoxoraColors.neonCyan),
                            onPressed: () {
                              app.selectConversation(call.conversationId);
                              showDialog<void>(context: context, barrierDismissible: false, builder: (_) => CallDialog(call: call));
                            },
                            icon: const Icon(Icons.phone_in_talk, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
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

class _NoticeBar extends StatelessWidget {
  const _NoticeBar();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Container(
      width: double.infinity,
      color: VoxoraColors.neonPink.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: VoxoraColors.neonPink, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(app.notice, style: const TextStyle(color: VoxoraColors.neonPink))),
          InkWell(onTap: app.clearNotice, child: const Icon(Icons.close, size: 16, color: VoxoraColors.neonPink)),
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
      case AppView.feed: return const FeedView();
      case AppView.friends: return const FriendsView();
      case AppView.messages: return const MessagesView();
      case AppView.games: return const GamesView();
      case AppView.profile: return const ProfileView();
    }
  }
}
