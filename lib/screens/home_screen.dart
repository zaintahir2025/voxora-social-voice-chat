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
import '../widgets/common_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _navItems = [
    _NavItem(AppView.rooms, Icons.radio, 'Rooms'),
    _NavItem(AppView.messages, Icons.chat_bubble_outline, 'Messages'),
    _NavItem(AppView.people, Icons.people_outline, 'People'),
    _NavItem(AppView.games, Icons.sports_esports_outlined, 'Games'),
    _NavItem(AppView.profile, Icons.person_outline, 'Profile'),
    _NavItem(AppView.admin, Icons.shield_outlined, 'Admin'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isWide = MediaQuery.of(context).size.width > 1080;

    final visibleNav = _navItems
        .where((n) =>
            n.view != AppView.admin || (app.profile?.isAdmin ?? false))
        .toList();

    return Scaffold(
      backgroundColor: VoxoraColors.bg,
      body: isWide
          ? Row(
              children: [
                _DesktopSidebar(
                    items: visibleNav,
                    current: app.view,
                    profile: app.profile!),
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

  const _DesktopSidebar(
      {required this.items, required this.current, required this.profile});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: VoxoraColors.surface,
        border: const Border(
          right: BorderSide(color: VoxoraColors.line),
        ),
      ),
      child: Column(
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      VoxoraColors.primary.withValues(alpha: 0.2),
                      VoxoraColors.cyan.withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: SvgPicture.asset('assets/voxora-mark.svg',
                    width: 28, height: 28),
              ),
              const SizedBox(width: 12),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Voxora',
                    style: TextStyle(
                        color: VoxoraColors.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 17)),
                Text('Talk. Play. Build.',
                    style: TextStyle(
                        color: VoxoraColors.muted, fontSize: 11)),
              ]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(height: 1, color: VoxoraColors.line),
          ),
          // Nav buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: items.map((item) {
                final isActive = current == item.view;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _SidebarButton(
                    icon: item.icon,
                    label: item.label,
                    isActive: isActive,
                    onTap: () => app.setView(item.view),
                  ),
                );
              }).toList(),
            ),
          ),
          const Spacer(),
          // User info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: VoxoraColors.surfaceLight,
                border: Border.all(color: VoxoraColors.line),
              ),
              child: Row(children: [
                VAvatar(
                    url: (profile as dynamic)?.avatarUrl as String?,
                    size: 36,
                    showOnline: true),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          (profile as dynamic)?.fullName as String? ??
                              'Member',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: VoxoraColors.text)),
                      Text(
                          '@${(profile as dynamic)?.handle as String? ?? ""}',
                          style: const TextStyle(
                              fontSize: 11, color: VoxoraColors.muted)),
                    ])),
              ]),
            ),
          ),
          // Sign out
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: _SidebarButton(
              icon: Icons.logout,
              label: 'Sign out',
              isActive: false,
              isDanger: true,
              onTap: () => app.signOut(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDanger;
  final VoidCallback? onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.isDanger = false,
    this.onTap,
  });

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: widget.isActive
                ? LinearGradient(colors: [
                    VoxoraColors.primary.withValues(alpha: 0.2),
                    VoxoraColors.primary.withValues(alpha: 0.1),
                  ])
                : null,
            color: !widget.isActive && _hovered
                ? VoxoraColors.surfaceLight
                : null,
            border: widget.isActive
                ? Border.all(
                    color: VoxoraColors.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(children: [
            Icon(widget.icon,
                size: 18,
                color: widget.isActive
                    ? VoxoraColors.primary
                    : widget.isDanger
                        ? VoxoraColors.danger
                        : _hovered
                            ? VoxoraColors.text
                            : VoxoraColors.muted),
            const SizedBox(width: 12),
            Text(widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: widget.isActive
                      ? VoxoraColors.primary
                      : widget.isDanger
                          ? VoxoraColors.danger
                          : _hovered
                              ? VoxoraColors.text
                              : VoxoraColors.muted,
                )),
            if (widget.isActive) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: VoxoraColors.primary),
              ),
            ],
          ]),
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: VoxoraColors.surface,
        border: const Border(top: BorderSide(color: VoxoraColors.line)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((n) {
              final isActive = n.view == current;
              return GestureDetector(
                onTap: () => app.setView(n.view),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isActive
                        ? VoxoraColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(n.icon,
                        size: 22,
                        color: isActive
                            ? VoxoraColors.primary
                            : VoxoraColors.muted),
                    const SizedBox(height: 3),
                    Text(n.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w800 : FontWeight.w500,
                          color: isActive
                              ? VoxoraColors.primary
                              : VoxoraColors.muted,
                        )),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
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
          // Topbar
          _Topbar(),
          // Pulse strip
          _PulseStrip(),
          // Notice
          if (app.notice.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: () => app.clearNotice(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: VoxoraColors.lime.withValues(alpha: 0.1),
                    border: Border.all(
                        color: VoxoraColors.lime.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.notifications_outlined,
                        size: 18, color: VoxoraColors.lime),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(app.notice,
                            style: TextStyle(
                                color: VoxoraColors.lime, fontSize: 13))),
                    Icon(Icons.close,
                        size: 16, color: VoxoraColors.lime.withValues(alpha: 0.6)),
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
      ('Live Rooms', app.liveRooms.length.toString(), Icons.radio,
          VoxoraColors.primary),
      ('Members', app.profiles.length.toString(), Icons.people,
          VoxoraColors.cyan),
      (
        'Friends',
        app.friendships.where((f) => f.status == 'accepted').length.toString(),
        Icons.person_add,
        VoxoraColors.success
      ),
      (
        'Games',
        app.gameSessions.where((g) => g.isActive).length.toString(),
        Icons.sports_esports,
        VoxoraColors.lime
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
      child: LayoutBuilder(builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            final w = constraints.maxWidth > 600
                ? (constraints.maxWidth - 36) / 4
                : (constraints.maxWidth - 12) / 2;
            return SizedBox(
              width: w,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: VoxoraColors.surface,
                  border: Border.all(color: VoxoraColors.line),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: item.$4.withValues(alpha: 0.12),
                    ),
                    child: Icon(item.$3, size: 18, color: item.$4),
                  ),
                  const SizedBox(width: 14),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item.$1,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(item.$2,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: VoxoraColors.text)),
                  ]),
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
      AppView.rooms: 'Live Rooms',
      AppView.messages: 'Messages',
      AppView.people: 'People',
      AppView.games: 'Game Lounge',
      AppView.profile: 'Profile Settings',
      AppView.admin: 'Admin Panel',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(titles[app.view] ?? '',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Signed in as @${app.profile?.handle ?? ""}',
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  VoxoraColors.primary.withValues(alpha: 0.15),
                  VoxoraColors.cyan.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                  color: VoxoraColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              VPulseDot(
                  color: VoxoraColors.online, size: 8),
              const SizedBox(width: 8),
              Text(
                app.profile?.isAdmin == true ? 'Admin' : 'Online',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: VoxoraColors.text,
                    fontSize: 13),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
