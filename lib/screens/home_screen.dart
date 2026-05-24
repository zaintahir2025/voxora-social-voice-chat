import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../views/rooms_view.dart';
import '../views/messages_view.dart';
import '../views/people_view.dart';
import '../views/games_view.dart';
import '../views/profile_view.dart';
import '../views/admin_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _navItems = [
    _NavItem(AppView.rooms, Icons.radio, 'Rooms'),
    _NavItem(AppView.messages, Icons.chat_bubble_outline, 'Messages'),
    _NavItem(AppView.people, Icons.people_outline, 'People'),
    _NavItem(AppView.games, Icons.sports_esports_outlined, 'Games'),
    _NavItem(AppView.profile, Icons.edit_outlined, 'Profile'),
    _NavItem(AppView.admin, Icons.shield_outlined, 'Admin'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isWide = MediaQuery.of(context).size.width > 1080;

    final visibleNav = _navItems.where((n) => n.view != AppView.admin || (app.profile?.isAdmin ?? false)).toList();

    return Scaffold(
      body: isWide
          ? Row(
              children: [
                _DesktopSidebar(items: visibleNav, current: app.view, profile: app.profile!),
                Expanded(child: _MainContent()),
              ],
            )
          : _MainContent(),
      bottomNavigationBar: isWide
          ? null
          : _MobileBottomNav(items: visibleNav, current: app.view),
    );
  }
}

class _NavItem {
  final AppView view;
  final IconData icon;
  final String label;
  const _NavItem(this.view, this.icon, this.label);
}

class _DesktopSidebar extends StatelessWidget {
  final List<_NavItem> items;
  final AppView current;
  final dynamic profile;

  const _DesktopSidebar({required this.items, required this.current, required this.profile});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    return Container(
      width: 264,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFA10131F), Color(0xFA1A123A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(children: [
              SvgPicture.asset('assets/voxora-mark.svg', width: 46, height: 46),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Voxora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                Text('Talk. Play. Build.', style: TextStyle(color: Colors.white.withValues(alpha: 0.68), fontSize: 12)),
              ]),
            ]),
          ),
          // Nav buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: items.map((item) {
                final isActive = current == item.view;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => app.setView(item.view),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: isActive
                              ? const LinearGradient(colors: [VoxoraColors.lime, Colors.white])
                              : null,
                        ),
                        child: Row(children: [
                          Icon(item.icon, size: 18,
                            color: isActive ? VoxoraColors.surfaceStrong : Colors.white.withValues(alpha: 0.68),
                          ),
                          const SizedBox(width: 10),
                          Text(item.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isActive ? VoxoraColors.surfaceStrong : Colors.white.withValues(alpha: 0.68),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Spacer(),
          // Sign out
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => app.signOut(),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    Icon(Icons.logout, size: 18, color: Colors.white.withValues(alpha: 0.68)),
                    const SizedBox(width: 10),
                    Text('Sign out', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.68))),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final AppView current;
  const _MobileBottomNav({required this.items, required this.current});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    return BottomNavigationBar(
      currentIndex: items.indexWhere((i) => i.view == current).clamp(0, items.length - 1),
      onTap: (i) => app.setView(items[i].view),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: VoxoraColors.primary,
      unselectedItemColor: VoxoraColors.muted,
      backgroundColor: Colors.white,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: items.map((n) => BottomNavigationBarItem(icon: Icon(n.icon), label: n.label)).toList(),
    );
  }
}

class _MainContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return Container(
      color: VoxoraColors.bg,
      child: Column(
        children: [
          // Pulse strip + topbar
          _PulseStrip(),
          _Topbar(),
          // Notice
          if (app.notice.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: () => app.clearNotice(),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF5),
                    border: Border.all(color: const Color(0xFFFEDF89)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.notifications_outlined, size: 18, color: Color(0xFF7A2E0E)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(app.notice, style: const TextStyle(color: Color(0xFF7A2E0E)))),
                  ]),
                ),
              ),
            ),
          // View content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: _viewContent(app.view),
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewContent(AppView view) {
    switch (view) {
      case AppView.rooms:
        return const RoomsView();
      case AppView.messages:
        return const MessagesView();
      case AppView.people:
        return const PeopleView();
      case AppView.games:
        return const GamesView();
      case AppView.profile:
        return const ProfileView();
      case AppView.admin:
        return const AdminView();
    }
  }
}

class _PulseStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final items = [
      ('Rooms', app.liveRooms.length.toString()),
      ('Members', app.profiles.length.toString()),
      ('Friends', app.friendships.where((f) => f.status == 'accepted').length.toString()),
      ('Games', app.gameSessions.where((g) => g.isActive).length.toString()),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 18),
      child: LayoutBuilder(builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            final w = constraints.maxWidth > 600 ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;
            return SizedBox(
              width: w,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: VoxoraTheme.pulseCardDecoration,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.$1.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(item.$2, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                ]),
              ),
            );
          }).toList(),
        );
      }),
    );
  }
}

class _Topbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final titles = {
      AppView.rooms: 'Live rooms',
      AppView.messages: 'Messages',
      AppView.people: 'People',
      AppView.games: 'Game lounge',
      AppView.profile: 'Profile settings',
      AppView.admin: 'Admin operations',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Signed in as @${app.profile?.handle ?? ""}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
            ),
            const SizedBox(height: 4),
            Text(titles[app.view] ?? '', style: Theme.of(context).textTheme.headlineMedium),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: VoxoraTheme.limeButtonDecoration.copyWith(borderRadius: BorderRadius.circular(999)),
            child: Text(
              app.profile?.isAdmin == true ? 'Admin' : 'Free for everyone',
              style: const TextStyle(fontWeight: FontWeight.w800, color: VoxoraColors.surfaceStrong),
            ),
          ),
        ],
      ),
    );
  }
}
