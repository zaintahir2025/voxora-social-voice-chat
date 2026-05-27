import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/common_widgets.dart';

class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final people = app.profiles
        .where((person) => person.id != app.profile?.id)
        .where(
          (person) => '${person.fullName} ${person.handle}'
              .toLowerCase()
              .contains(_query.toLowerCase()),
        )
        .toList();
    final pending = app.incomingRequests;
    final onlineFriends = app.friends
        .where((person) => person.status == 'online')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                icon: Icons.people_outline,
                title: 'Friends',
                subtitle:
                    '${app.friends.length} friends, $onlineFriends online, ${pending.length} requests',
              ),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search people...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (pending.isNotEmpty) ...[
          Text('Requests', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...pending.map((request) {
            final person = app.profileById(request.requesterId);
            if (person == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PersonTile(
                person: person,
                friendship: request,
                requestMode: true,
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
        if (people.isEmpty)
          const EmptyState(
            icon: Icons.person_search_outlined,
            title: 'No people found',
            body: 'Invite real users to sign up, then add them as friends.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 3
                  : constraints.maxWidth >= 680
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: people.map((person) {
                  return SizedBox(
                    width: width,
                    child: _PersonTile(
                      person: person,
                      friendship: app.friendshipWith(person.id),
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}

class _PersonTile extends StatelessWidget {
  final Profile person;
  final Friendship? friendship;
  final bool requestMode;

  const _PersonTile({
    required this.person,
    this.friendship,
    this.requestMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final accepted = friendship?.status == 'accepted';
    final pending = friendship?.status == 'pending';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => app.viewProfile(person.id),
            child: Row(
              children: [
                UserAvatar(
                  url: person.avatarUrl,
                  size: 54,
                  online: accepted && person.status == 'online',
                  seed: person.handle,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '@${person.handle}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (accepted) UserStatusChip(status: person.status),
              ],
            ),
          ),
          if (person.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(person.bio, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          if (person.interests.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: person.interests
                  .take(4)
                  .map((interest) => Chip(label: Text(interest)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => app.startConversation(person),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat'),
              ),
              if (requestMode && friendship != null)
                FilledButton.icon(
                  onPressed: () => app.acceptFriend(friendship!),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Accept'),
                )
              else if (accepted && friendship != null)
                OutlinedButton.icon(
                  onPressed: () => app.removeFriend(friendship!),
                  icon: const Icon(Icons.person_remove_outlined),
                  label: const Text('Remove'),
                )
              else
                FilledButton.icon(
                  onPressed: pending ? null : () => app.requestFriend(person),
                  icon: Icon(
                    pending ? Icons.hourglass_top : Icons.person_add_alt_1,
                  ),
                  label: Text(pending ? 'Pending' : 'Add'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
