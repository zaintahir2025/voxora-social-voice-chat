import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../widgets/common_widgets.dart';

class PeopleView extends StatelessWidget {
  const PeopleView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final others = app.profiles.where((p) => p.id != app.profile?.id).toList();

    return VPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const VSectionTitle(icon: Icons.people_outline, title: 'Members'),
      LayoutBuilder(builder: (context, constraints) {
        final cols = (constraints.maxWidth / 260).floor().clamp(1, 4);
        return Wrap(spacing: 14, runSpacing: 14, children: others.map((person) {
          final friendship = app.findFriendship(person.id);
          final incoming = friendship?.status == 'pending' && friendship?.addresseeId == app.profile?.id;
          final accepted = friendship?.status == 'accepted';
          return SizedBox(
            width: (constraints.maxWidth - (cols - 1) * 14) / cols,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: VoxoraColors.line),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withValues(alpha: 0.88),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 100, width: double.infinity, color: VoxoraColors.primary.withValues(alpha: 0.15),
                  child: person.coverUrl != null && person.coverUrl!.isNotEmpty
                      ? Image.network(person.coverUrl!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => const SizedBox())
                      : null),
                Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Transform.translate(offset: const Offset(0, -28), child: VAvatar(url: person.avatarUrl, size: 56, border: true)),
                  Transform.translate(offset: const Offset(0, -14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(person.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('@${person.handle}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text(person.bio.isEmpty ? 'No bio yet.' : person.bio, style: TextStyle(color: VoxoraColors.muted, height: 1.55), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, children: [
                      VSecondaryButton(label: 'Message', icon: Icons.chat_bubble_outline, onTap: () => app.startConversation(person)),
                      if (incoming && friendship != null)
                        _gradientSmall('Accept', Icons.check, () => app.acceptFriend(friendship))
                      else
                        VSecondaryButton(
                          label: accepted ? 'Friends' : (friendship != null ? 'Requested' : 'Add'),
                          icon: Icons.person_add_outlined,
                          onTap: friendship != null ? null : () => app.requestFriend(person),
                        ),
                    ]),
                  ])),
                ])),
              ]),
            ),
          );
        }).toList());
      }),
    ]));
  }

  Widget _gradientSmall(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(colors: [VoxoraColors.primary, VoxoraColors.cyan]),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white), const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
      ]),
    ));
  }
}
