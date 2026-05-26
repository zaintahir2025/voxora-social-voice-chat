import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/common_widgets.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _name = TextEditingController();
  final _handle = TextEditingController();
  final _bio = TextEditingController();
  final _interests = TextEditingController();
  String? _loadedProfileId;
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _bio.dispose();
    _interests.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final person = app.viewedProfile ?? app.profile!;
    final mine = person.id == app.profile?.id;
    if (_loadedProfileId != person.id) {
      _loadedProfileId = person.id;
      _name.text = person.fullName;
      _handle.text = person.handle;
      _bio.text = person.bio;
      _interests.text = person.interests.join(', ');
    }
    final posts = app.posts
        .where((post) => post.authorId == person.id)
        .toList();
    final wide = MediaQuery.of(context).size.width >= 920;
    final summary = _profileSummary(app, person, mine, posts.length);
    final editor = mine ? _editor(app) : _profileActions(app, person);

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: summary),
          const SizedBox(width: 14),
          SizedBox(width: 380, child: editor),
        ],
      );
    }
    return Column(children: [summary, const SizedBox(height: 14), editor]);
  }

  Widget _profileSummary(
    AppProvider app,
    Profile person,
    bool mine,
    int postCount,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 210,
            width: double.infinity,
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
            clipBehavior: Clip.antiAlias,
            child: person.coverUrl == null || person.coverUrl!.isEmpty
                ? Center(
                    child: Icon(
                      Icons.landscape_outlined,
                      color: scheme.primary,
                      size: 42,
                    ),
                  )
                : Image.network(person.coverUrl!, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -42),
                  child: UserAvatar(
                    url: person.avatarUrl,
                    size: 92,
                    online: person.status == 'online',
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              person.fullName,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          CountChip(
                            icon: Icons.photo_library_outlined,
                            label: '$postCount posts',
                          ),
                        ],
                      ),
                      Text(
                        '@${person.handle}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(person.bio.isEmpty ? 'No bio yet.' : person.bio),
                      if (person.interests.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: person.interests
                              .map((interest) => Chip(label: Text(interest)))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Joined ${_formatDate(person.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileActions(AppProvider app, Profile person) {
    final friendship = app.friendshipWith(person.id);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            icon: Icons.person_outline,
            title: 'Profile actions',
            subtitle: 'Connect with ${person.fullName}.',
          ),
          FilledButton.icon(
            onPressed: () => app.startConversation(person),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Message'),
          ),
          const SizedBox(height: 10),
          if (friendship?.status == 'accepted')
            OutlinedButton.icon(
              onPressed: () => app.removeFriend(friendship!),
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text('Remove friend'),
            )
          else
            OutlinedButton.icon(
              onPressed: friendship == null
                  ? () => app.requestFriend(person)
                  : null,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(
                friendship == null ? 'Add friend' : 'Request pending',
              ),
            ),
        ],
      ),
    );
  }

  Widget _editor(AppProvider app) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            icon: Icons.tune_outlined,
            title: 'Customize profile',
            subtitle: 'Update your public profile.',
          ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Display name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _handle,
            decoration: const InputDecoration(
              labelText: 'Handle',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bio,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Bio',
              prefixIcon: Icon(Icons.info_outline),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _interests,
            decoration: const InputDecoration(
              labelText: 'Interests',
              prefixIcon: Icon(Icons.interests_outlined),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _uploading ? null : () => _upload(app, avatar: true),
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('Avatar'),
              ),
              OutlinedButton.icon(
                onPressed: _uploading
                    ? null
                    : () => _upload(app, avatar: false),
                icon: const Icon(Icons.panorama_outlined),
                label: const Text('Cover'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => app.updateProfile(
              fullName: _name.text,
              handle: _handle.text,
              bio: _bio.text,
              interests: _interests.text
                  .split(',')
                  .map((interest) => interest.trim())
                  .where((interest) => interest.isNotEmpty)
                  .toList(),
            ),
            icon: const Icon(Icons.check),
            label: const Text('Save changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _upload(AppProvider app, {required bool avatar}) async {
    const group = XTypeGroup(
      label: 'Images',
      extensions: ['png', 'jpg', 'jpeg', 'webp'],
      mimeTypes: ['image/png', 'image/jpeg', 'image/webp'],
    );
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      if (avatar) {
        await app.uploadAvatar(bytes, file.name);
      } else {
        await app.uploadCover(bytes, file.name);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return 'recently';
    }
  }
}
