import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/common_widgets.dart';

enum _FriendsTab { friends, add, requests }

class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  _FriendsTab _tab = _FriendsTab.friends;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final pending = app.incomingRequests;
    final sentRequests = app.friendships
        .where(
          (item) =>
              item.status == 'pending' && item.requesterId == app.profile?.id,
        )
        .toList();
    final onlineFriends = app.friends.where(app.isProfileOnline).length;

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
              SegmentedButton<_FriendsTab>(
                segments: [
                  const ButtonSegment(
                    value: _FriendsTab.friends,
                    icon: Icon(Icons.people_alt_outlined),
                    label: Text('Friends'),
                  ),
                  const ButtonSegment(
                    value: _FriendsTab.add,
                    icon: Icon(Icons.person_add_alt_1_outlined),
                    label: Text('Add'),
                  ),
                  ButtonSegment(
                    value: _FriendsTab.requests,
                    icon: pending.isEmpty
                        ? const Icon(Icons.inbox_outlined)
                        : Badge.count(
                            count: pending.length,
                            child: const Icon(Icons.inbox_outlined),
                          ),
                    label: const Text('Requests'),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (value) {
                  setState(() {
                    _tab = value.first;
                    _query = '';
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: switch (_tab) {
                    _FriendsTab.friends => 'Search your friends',
                    _FriendsTab.add => 'Search people to add',
                    _FriendsTab.requests => 'Search requests',
                  },
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey(_tab),
            child: switch (_tab) {
              _FriendsTab.friends => _peopleGrid(
                app,
                _filter(app.friends),
                empty: const EmptyState(
                  icon: Icons.people_outline,
                  title: 'No friends yet',
                  body: 'Use Add Friends to build your circle.',
                ),
              ),
              _FriendsTab.add => _peopleGrid(
                app,
                _discoverablePeople(app),
                empty: const EmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'No people found',
                  body: 'Try another name or handle.',
                ),
              ),
              _FriendsTab.requests => _requestsList(app, pending, sentRequests),
            },
          ),
        ),
      ],
    );
  }

  List<Profile> _filter(List<Profile> people) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return people;
    return people
        .where(
          (person) => '${person.fullName} ${person.handle}'
              .toLowerCase()
              .contains(query),
        )
        .toList();
  }

  List<Profile> _discoverablePeople(AppProvider app) {
    final myId = app.profile?.id;
    return _filter(
      app.profiles
          .where((person) => person.id != myId)
          .where(
            (person) => app.friendshipWith(person.id)?.status != 'accepted',
          )
          .toList(),
    );
  }

  Widget _peopleGrid(
    AppProvider app,
    List<Profile> people, {
    required Widget empty,
  }) {
    if (people.isEmpty) return empty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 680
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
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
    );
  }

  Widget _requestsList(
    AppProvider app,
    List<Friendship> incoming,
    List<Friendship> outgoing,
  ) {
    final query = _query.trim().toLowerCase();
    final incomingPeople = incoming
        .map((request) => (request, app.profileById(request.requesterId)))
        .where((item) => item.$2 != null)
        .where(
          (item) =>
              query.isEmpty ||
              '${item.$2!.fullName} ${item.$2!.handle}'.toLowerCase().contains(
                query,
              ),
        )
        .toList();
    final outgoingPeople = outgoing
        .map((request) => (request, app.profileById(request.addresseeId)))
        .where((item) => item.$2 != null)
        .where(
          (item) =>
              query.isEmpty ||
              '${item.$2!.fullName} ${item.$2!.handle}'.toLowerCase().contains(
                query,
              ),
        )
        .toList();

    if (incomingPeople.isEmpty && outgoingPeople.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No requests',
        body: 'Friend requests will appear here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (incomingPeople.isNotEmpty) ...[
          Text('Incoming', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...incomingPeople.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PersonTile(
                person: item.$2!,
                friendship: item.$1,
                requestMode: true,
              ),
            ),
          ),
        ],
        if (outgoingPeople.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Sent', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...outgoingPeople.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PersonTile(person: item.$2!, friendship: item.$1),
            ),
          ),
        ],
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
    final status = app.statusFor(person);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => app.viewProfile(person.id),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                UserAvatar(
                  url: person.avatarUrl,
                  size: 58,
                  online: accepted && app.isProfileOnline(person),
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
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '@${person.handle}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (accepted) UserStatusChip(status: status),
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
                  icon: const Icon(Icons.check_rounded),
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
