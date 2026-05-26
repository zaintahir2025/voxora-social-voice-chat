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
      body: Row(
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
                      online: true,
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
                            '@${app.profile?.handle ?? ''}',
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
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool active;

  const _NavButton({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final scheme = Theme.of(context).colorScheme;
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
              Icon(
                item.icon,
                color: active ? scheme.primary : scheme.onSurfaceVariant,
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
            (item) =>
                NavigationDestination(icon: Icon(item.icon), label: item.label),
          )
          .toList(),
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
            ActionIconButton(
              icon: app.darkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
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
