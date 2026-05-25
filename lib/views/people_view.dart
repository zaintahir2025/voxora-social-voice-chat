import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../widgets/common_widgets.dart';

class PeopleView extends StatefulWidget {
  const PeopleView({super.key});

  @override
  State<PeopleView> createState() => _PeopleViewState();
}

class _PeopleViewState extends State<PeopleView> {
  String _search = '';
  String _filter = 'all'; // all, friends, pending

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final others = app.profiles.where((p) => p.id != app.profile?.id).toList();

    List<dynamic> filteredPeople;
    if (_filter == 'friends') {
      filteredPeople = others.where((p) {
        final f = app.findFriendship(p.id);
        return f?.status == 'accepted';
      }).toList();
    } else if (_filter == 'pending') {
      filteredPeople = others.where((p) {
        final f = app.findFriendship(p.id);
        return f?.status == 'pending';
      }).toList();
    } else {
      filteredPeople = others;
    }

    if (_search.isNotEmpty) {
      filteredPeople = filteredPeople
          .where(
            (p) => '${p.fullName} ${p.handle}'.toLowerCase().contains(
              _search.toLowerCase(),
            ),
          )
          .toList();
    }

    final friendCount = others
        .where((p) => app.findFriendship(p.id)?.status == 'accepted')
        .length;
    final pendingCount = others.where((p) {
      final f = app.findFriendship(p.id);
      return f?.status == 'pending' && f?.addresseeId == app.profile?.id;
    }).length;

    return VPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VSectionTitle(icon: Icons.people_outline, title: 'People'),
          // Stats
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statChip(
                'All',
                '${others.length}',
                VoxoraColors.cyan,
                _filter == 'all',
                () => setState(() => _filter = 'all'),
              ),
              _statChip(
                'Friends',
                '$friendCount',
                VoxoraColors.success,
                _filter == 'friends',
                () => setState(() => _filter = 'friends'),
              ),
              if (pendingCount > 0)
                _statChip(
                  'Requests',
                  '$pendingCount',
                  VoxoraColors.lime,
                  _filter == 'pending',
                  () => setState(() => _filter = 'pending'),
                ),
            ],
          ),
          const SizedBox(height: 16),
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
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(
                      color: VoxoraColors.text,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search people...',
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
          const SizedBox(height: 18),
          if (filteredPeople.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No people found.',
                  style: TextStyle(color: VoxoraColors.muted),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = (constraints.maxWidth / 280).floor().clamp(1, 4);
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: filteredPeople.map((person) {
                    final friendship = app.findFriendship(person.id);
                    final incoming =
                        friendship?.status == 'pending' &&
                        friendship?.addresseeId == app.profile?.id;
                    final accepted = friendship?.status == 'accepted';
                    return SizedBox(
                      width: (constraints.maxWidth - (cols - 1) * 14) / cols,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: VoxoraColors.line),
                          borderRadius: BorderRadius.circular(14),
                          color: VoxoraColors.surface,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cover
                            Container(
                              height: 90,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    VoxoraColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    VoxoraColors.cyan.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                              child:
                                  person.coverUrl != null &&
                                      person.coverUrl!.isNotEmpty
                                  ? Image.network(
                                      person.coverUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox(),
                                    )
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Transform.translate(
                                    offset: const Offset(0, -26),
                                    child: VAvatar(
                                      url: person.avatarUrl,
                                      size: 52,
                                      border: true,
                                      showOnline: accepted,
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: const Offset(0, -12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                person.fullName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: VoxoraColors.text,
                                                ),
                                              ),
                                            ),
                                            if (accepted)
                                              const VStatusBadge(
                                                label: 'Friend',
                                                color: VoxoraColors.success,
                                              ),
                                          ],
                                        ),
                                        Text(
                                          '@${person.handle}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          person.bio.isEmpty
                                              ? 'No bio yet.'
                                              : person.bio,
                                          style: const TextStyle(
                                            color: VoxoraColors.muted,
                                            height: 1.55,
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (person.interests.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: person.interests
                                                .take(3)
                                                .map(
                                                  (i) => Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      color: VoxoraColors.cyan
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      border: Border.all(
                                                        color: VoxoraColors.cyan
                                                            .withValues(
                                                              alpha: 0.2,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      i,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            VoxoraColors.cyan,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            VSecondaryButton(
                                              label: 'Message',
                                              icon: Icons.chat_bubble_outline,
                                              onTap: () =>
                                                  app.startConversation(person),
                                            ),
                                            if (incoming && friendship != null)
                                              _gradientSmall(
                                                'Accept',
                                                Icons.check,
                                                () => app.acceptFriend(
                                                  friendship,
                                                ),
                                              )
                                            else
                                              VSecondaryButton(
                                                label: accepted
                                                    ? 'Friends'
                                                    : (friendship != null
                                                          ? 'Pending'
                                                          : 'Add'),
                                                icon: accepted
                                                    ? Icons.check_circle
                                                    : Icons.person_add_outlined,
                                                onTap: friendship != null
                                                    ? null
                                                    : () => app.requestFriend(
                                                        person,
                                                      ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _statChip(
    String label,
    String count,
    Color color,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active
              ? color.withValues(alpha: 0.15)
              : VoxoraColors.surfaceLight,
          border: Border.all(
            color: active ? color.withValues(alpha: 0.4) : VoxoraColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: active ? color : VoxoraColors.muted,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: color.withValues(alpha: active ? 0.25 : 0.1),
              ),
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientSmall(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [VoxoraColors.primary, VoxoraColors.cyan],
          ),
          boxShadow: [
            BoxShadow(
              color: VoxoraColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
