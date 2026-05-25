import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../widgets/common_widgets.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  String _userSearch = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isWide = MediaQuery.of(context).size.width > 900;

    final filteredUsers = _userSearch.isEmpty
        ? app.profiles
        : app.profiles
              .where(
                (p) => '${p.fullName} ${p.handle} ${p.email ?? ""}'
                    .toLowerCase()
                    .contains(_userSearch.toLowerCase()),
              )
              .toList();

    final blockedCount = app.profiles.where((p) => p.isBlocked).length;
    final liveCount = app.rooms.where((r) => r.isLive).length;

    final usersPanel = VPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VSectionTitle(
            icon: Icons.people_outline,
            title: 'User Management',
          ),
          // Stats
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _adminStat(
                'Total Users',
                '${app.profiles.length}',
                VoxoraColors.cyan,
              ),
              _adminStat('Blocked', '$blockedCount', VoxoraColors.danger),
            ],
          ),
          const SizedBox(height: 14),
          // Search
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: VoxoraColors.surfaceLight,
              border: Border.all(color: VoxoraColors.line),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: Icon(
                    Icons.search,
                    size: 18,
                    color: VoxoraColors.muted,
                  ),
                ),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _userSearch = v),
                    style: const TextStyle(
                      color: VoxoraColors.text,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...filteredUsers.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: p.isBlocked
                        ? VoxoraColors.danger.withValues(alpha: 0.3)
                        : VoxoraColors.line,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: p.isBlocked
                      ? VoxoraColors.danger.withValues(alpha: 0.05)
                      : VoxoraColors.surface,
                ),
                child: Row(
                  children: [
                    VAvatar(url: p.avatarUrl, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                p.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: VoxoraColors.text,
                                ),
                              ),
                              if (p.isAdmin) ...[
                                const SizedBox(width: 8),
                                const VStatusBadge(
                                  label: 'Admin',
                                  color: VoxoraColors.lime,
                                ),
                              ],
                              if (p.isBlocked) ...[
                                const SizedBox(width: 8),
                                const VStatusBadge(
                                  label: 'Blocked',
                                  color: VoxoraColors.danger,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '@${p.handle}${p.email != null ? " · ${p.email}" : ""}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    VDangerButton(
                      label: p.isBlocked ? 'Unblock' : 'Block',
                      icon: p.isBlocked ? Icons.lock_open : Icons.block,
                      onTap: () => app.toggleBlockUser(p),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final roomsPanel = VPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VSectionTitle(icon: Icons.radio, title: 'Room Management'),
          _adminStat('Live Rooms', '$liveCount', VoxoraColors.success),
          const SizedBox(height: 14),
          ...app.rooms.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: VoxoraColors.line),
                  borderRadius: BorderRadius.circular(12),
                  color: VoxoraColors.surface,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: r.isLive
                            ? VoxoraColors.online
                            : VoxoraColors.muted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: VoxoraColors.text,
                            ),
                          ),
                          Row(
                            children: [
                              VStatusBadge(
                                label: r.isLive ? 'Live' : 'Ended',
                                color: r.isLive
                                    ? VoxoraColors.online
                                    : VoxoraColors.muted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${r.topic} · ${app.participants.where((p) => p.roomId == r.id).length} users',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (r.isLive)
                      VDangerButton(
                        label: 'End',
                        icon: Icons.stop,
                        onTap: () => app.endRoom(r),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: usersPanel),
          const SizedBox(width: 18),
          Expanded(child: roomsPanel),
        ],
      );
    }
    return Column(
      children: [usersPanel, const SizedBox(height: 18), roomsPanel],
    );
  }

  Widget _adminStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
