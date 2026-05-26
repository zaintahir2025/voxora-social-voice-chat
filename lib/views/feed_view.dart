import 'dart:math';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/common_widgets.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          children: [
            _ComposerPrompt(app: app),
            const SizedBox(height: 14),
            _StoryRail(app: app),
            const SizedBox(height: 14),
            if (app.posts.isEmpty)
              const EmptyState(
                icon: Icons.photo_library_outlined,
                title: 'No posts yet',
                body:
                    'Picture posts from you and your friends will appear here.',
              )
            else
              ...app.posts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PostCard(post: post),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ComposerPrompt extends StatelessWidget {
  final AppProvider app;

  const _ComposerPrompt({required this.app});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      gradient: LinearGradient(
        colors: [
          scheme.primary.withValues(alpha: 0.14),
          VoxoraColors.teal.withValues(alpha: 0.10),
          scheme.surface.withValues(alpha: 0.94),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(
            url: app.profile?.avatarUrl,
            size: 48,
            online: app.profile?.status == 'online',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CreatePostPage()),
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  'Drop a moment...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'Post',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CreatePostPage()),
            ),
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
        ],
      ),
    );
  }
}

class _StoryRail extends StatelessWidget {
  final AppProvider app;

  const _StoryRail({required this.app});

  @override
  Widget build(BuildContext context) {
    final people = <Profile>[
      if (app.profile != null) app.profile!,
      ...app.friends,
      ...app.profiles.where(
        (person) =>
            person.id != app.profile?.id &&
            !app.friends.any((friend) => friend.id == person.id),
      ),
    ].take(12).toList();
    if (people.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final person = people[index];
          return _StoryBubble(
            person: person,
            mine: person.id == app.profile?.id,
            onTap: () => app.viewProfile(person.id),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: people.length,
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  final Profile person;
  final bool mine;
  final VoidCallback onTap;

  const _StoryBubble({
    required this.person,
    required this.mine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 92,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: mine
                ? scheme.primary.withValues(alpha: 0.32)
                : scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UserAvatar(
              url: person.avatarUrl,
              size: 52,
              online: person.status == 'online',
            ),
            const SizedBox(height: 7),
            Text(
              mine ? 'You' : person.fullName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            Text(
              '@${person.handle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _caption = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _posting = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create post')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: _composer(app),
            ),
          ),
        ),
      ),
    );
  }

  Widget _composer(AppProvider app) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      gradient: LinearGradient(
        colors: [
          scheme.surface,
          scheme.primary.withValues(alpha: 0.07),
          VoxoraColors.teal.withValues(alpha: 0.06),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.add_photo_alternate_outlined,
            title: 'New drop',
            subtitle: 'Share a photo with your circle.',
          ),
          TextField(
            controller: _caption,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Write a caption...',
              prefixIcon: Icon(Icons.short_text),
            ),
          ),
          const SizedBox(height: 12),
          if (_imageBytes != null)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 360),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(_imageBytes!, fit: BoxFit.contain),
            )
          else
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.08),
                      VoxoraColors.teal.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.14),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, color: scheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      'Choose picture',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _posting ? null : _pickImage,
                icon: const Icon(Icons.image_search_outlined),
                label: Text(_imageName ?? 'Picture'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _posting || _imageBytes == null
                    ? null
                    : () async {
                        setState(() => _posting = true);
                        try {
                          await app.createPost(
                            caption: _caption.text,
                            imageBytes: _imageBytes!,
                            filename: _imageName ?? 'post.jpg',
                          );
                          if (!mounted) return;
                          Navigator.of(context).pop();
                        } finally {
                          if (mounted) setState(() => _posting = false);
                        }
                      },
                icon: _posting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: const Text('Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['png', 'jpg', 'jpeg', 'webp'],
      mimeTypes: ['image/png', 'image/jpeg', 'image/webp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = file.name;
    });
  }
}

class _PostCard extends StatefulWidget {
  final SocialPost post;

  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final post = widget.post;
    final author = app.profileById(post.authorId);
    final comments = app.commentsForPost(post.id);
    final topLevelComments = app.topLevelCommentsForPost(post.id);
    final shared = app.postById(post.sharedPostId);
    final isMine = post.authorId == app.profile?.id;
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: scheme.primary.withValues(alpha: 0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, VoxoraColors.teal, VoxoraColors.amber],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                InkWell(
                  onTap: author == null
                      ? null
                      : () => app.viewProfile(author.id),
                  customBorder: const CircleBorder(),
                  child: UserAvatar(
                    url: author?.avatarUrl,
                    online: author?.status == 'online',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: author == null
                        ? null
                        : () => app.viewProfile(author.id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author?.fullName ?? 'Member',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '@${author?.handle ?? 'member'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _timeAgo(post.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (isMine)
                  PopupMenuButton<String>(
                    tooltip: 'Post actions',
                    onSelected: (value) {
                      if (value == 'edit') _editPost(app, post);
                      if (value == 'delete') app.deletePost(post);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
          ),
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                post.caption,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.42),
              ),
            ),
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                constraints: const BoxConstraints(maxHeight: 620),
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 180),
                ),
              ),
            ),
          if (shared != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _SharedPostPreview(post: shared),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => app.toggleLike(post),
                  icon: Icon(
                    app.likedPost(post.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  label: Text('${app.likeCount(post.id)}'),
                ),
                OutlinedButton.icon(
                  onPressed: () => app.sharePost(post),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text('${app.shareCount(post.id)}'),
                ),
                CountChip(
                  icon: Icons.mode_comment_outlined,
                  label: '${comments.length}',
                  color: VoxoraColors.teal,
                ),
              ],
            ),
          ),
          if (comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Column(
                children: topLevelComments
                    .map((comment) => _CommentRow(comment: comment, post: post))
                    .toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _comment,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      prefixIcon: Icon(Icons.mode_comment_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Send comment',
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final body = _comment.text;
                    _comment.clear();
                    app.addComment(post, body);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editPost(AppProvider app, SocialPost post) async {
    final controller = TextEditingController(text: post.caption);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit post'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Caption'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) await app.editPost(post, result);
  }

  String _timeAgo(String raw) {
    try {
      final created = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(created);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${created.month}/${created.day}';
    } catch (_) {
      return '';
    }
  }
}

class _CommentRow extends StatefulWidget {
  final PostComment comment;
  final SocialPost post;
  final int depth;

  const _CommentRow({
    required this.comment,
    required this.post,
    this.depth = 0,
  });

  @override
  State<_CommentRow> createState() => _CommentRowState();
}

class _CommentRowState extends State<_CommentRow> {
  final _reply = TextEditingController();
  bool _replying = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final comment = widget.comment;
    final post = widget.post;
    final author = app.profileById(comment.authorId);
    final replies = app.repliesForComment(comment.id);
    final canDelete =
        comment.authorId == app.profile?.id || post.authorId == app.profile?.id;

    return Padding(
      padding: EdgeInsets.only(
        left: widget.depth == 0 ? 0 : min(widget.depth * 22.0, 44),
        bottom: 8,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(url: author?.avatarUrl, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: widget.depth > 0
                        ? Border(
                            left: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              author?.fullName ?? 'Member',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (widget.depth > 0)
                            Text(
                              'Reply',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                      Text(comment.body),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _replying = !_replying),
                            icon: const Icon(Icons.reply, size: 16),
                            label: Text(_replying ? 'Cancel' : 'Reply'),
                          ),
                          if (replies.isNotEmpty)
                            CountChip(
                              icon: Icons.forum_outlined,
                              label:
                                  '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                              color: VoxoraColors.teal,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (canDelete)
                IconButton(
                  tooltip: 'Delete comment',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => app.deleteComment(comment),
                ),
            ],
          ),
          if (_replying)
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 8, 0, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reply,
                      minLines: 1,
                      maxLines: 3,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText:
                            'Reply to ${author?.fullName ?? 'comment'}...',
                        prefixIcon: const Icon(Icons.reply_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send reply',
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final body = _reply.text;
                      _reply.clear();
                      setState(() => _replying = false);
                      app.addComment(post, body, parentComment: comment);
                    },
                  ),
                ],
              ),
            ),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                children: replies
                    .map(
                      (reply) => _CommentRow(
                        comment: reply,
                        post: post,
                        depth: widget.depth + 1,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SharedPostPreview extends StatelessWidget {
  final SocialPost post;

  const _SharedPostPreview({required this.post});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final author = app.profileById(post.authorId);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              '${author?.fullName ?? 'Member'} shared a post',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (post.imageUrl != null)
            Image.network(
              post.imageUrl!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(post.caption),
            ),
        ],
      ),
    );
  }
}
