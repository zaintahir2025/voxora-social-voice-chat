import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/common_widgets.dart';
import 'feed_view.dart';

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
  bool _uploadingAvatar = false;
  bool _uploadingCover = false;

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
    final profileFriends = app.friendsForProfile(person.id);
    final wide = MediaQuery.of(context).size.width >= 920;
    final summary = _profileSummary(
      app,
      person,
      mine,
      posts.length,
      profileFriends.length,
    );
    final editor = mine ? _editor(app) : _profileActions(app, person);
    final friendsCard = _friendsPreview(app, person, profileFriends);
    final sidePanel = Column(
      children: [editor, const SizedBox(height: 14), friendsCard],
    );

    final header = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: summary),
              const SizedBox(width: 14),
              SizedBox(width: 380, child: sidePanel),
            ],
          )
        : Column(
            children: [
              summary,
              const SizedBox(height: 14),
              editor,
              const SizedBox(height: 14),
              friendsCard,
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 24),
        if (posts.isEmpty)
          const EmptyState(
            icon: Icons.photo_library_outlined,
            title: 'No posts yet',
            body: 'This user hasn\'t posted anything.',
          )
        else
          ...posts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PostCard(key: ValueKey(post.id), post: post),
            ),
          ),
      ],
    );
  }

  Widget _profileSummary(
    AppProvider app,
    Profile person,
    bool mine,
    int postCount,
    int friendCount,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final showStatus =
        mine || app.friendshipWith(person.id)?.status == 'accepted';
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 210,
            width: double.infinity,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (person.coverUrl == null || person.coverUrl!.isEmpty)
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Icon(
                        Icons.auto_awesome_outlined,
                        color: scheme.primary,
                        size: 34,
                      ),
                    ),
                  )
                else
                  Image.network(person.coverUrl!, fit: BoxFit.cover),
                if (mine)
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: FilledButton.icon(
                      onPressed: _uploadingCover
                          ? null
                          : () => _upload(app, avatar: false),
                      icon: _uploadingCover
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(_uploadingCover ? 'Uploading' : 'Edit cover'),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -42),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      UserAvatar(
                        url: person.avatarUrl,
                        size: 92,
                        online: app.isProfileOnline(person),
                        seed: person.handle,
                      ),
                      if (mine)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: IconButton.filled(
                            tooltip: 'Edit profile picture',
                            onPressed: _uploadingAvatar
                                ? null
                                : () => _upload(app, avatar: true),
                            icon: _uploadingAvatar
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.photo_camera_outlined),
                          ),
                        ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          CountChip(
                            icon: Icons.photo_library_outlined,
                            label: '$postCount posts',
                          ),
                          CountChip(
                            icon: Icons.people_alt_outlined,
                            label: '$friendCount friends',
                          ),
                          if (showStatus)
                            UserStatusChip(status: app.statusFor(person)),
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

  Widget _friendsPreview(
    AppProvider app,
    Profile person,
    List<Profile> friends,
  ) {
    final mine = person.id == app.profile?.id;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.people_alt_outlined,
            title: 'Friends',
            subtitle: friends.isEmpty
                ? 'No friends to show yet'
                : '${friends.length} people',
            trailing: mine
                ? TextButton.icon(
                    onPressed: () => app.setView(AppView.friends),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Manage'),
                  )
                : null,
          ),
          if (friends.isEmpty)
            Text(
              mine
                  ? 'Your accepted friends will show here.'
                  : 'No visible friends yet.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 330 ? 3 : 2;
                final width =
                    (constraints.maxWidth - (columns - 1) * 10) / columns;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: friends.take(9).map((friend) {
                    return SizedBox(
                      width: width,
                      child: InkWell(
                        onTap: () => app.viewProfile(friend.id),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            children: [
                              UserAvatar(
                                url: friend.avatarUrl,
                                size: 56,
                                online: app.isProfileOnline(friend),
                                seed: friend.handle,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                friend.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '@${friend.handle}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
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
                onPressed: _uploadingAvatar
                    ? null
                    : () => _upload(app, avatar: true),
                icon: _uploadingAvatar
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_circle_outlined),
                label: const Text('Change profile photo'),
              ),
              OutlinedButton.icon(
                onPressed: _uploadingCover
                    ? null
                    : () => _upload(app, avatar: false),
                icon: _uploadingCover
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.panorama_outlined),
                label: const Text('Change cover photo'),
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
    setState(() {
      if (avatar) {
        _uploadingAvatar = true;
      } else {
        _uploadingCover = true;
      }
    });
    try {
      final bytes = await file.readAsBytes();
      if (avatar) {
        await app.uploadAvatar(bytes, file.name);
      } else {
        await app.uploadCover(bytes, file.name);
      }
    } finally {
      if (mounted) {
        setState(() {
          if (avatar) {
            _uploadingAvatar = false;
          } else {
            _uploadingCover = false;
          }
        });
      }
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
