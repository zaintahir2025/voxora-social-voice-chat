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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          children: [
            _composer(app),
            const SizedBox(height: 16),
            if (app.posts.isEmpty)
              const EmptyState(
                icon: Icons.photo_library_outlined,
                title: 'No posts yet',
                body:
                    'Add the first picture post and your friends will see it here.',
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

  Widget _composer(AppProvider app) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.add_photo_alternate_outlined,
            title: 'Add post',
            subtitle: 'Upload a picture and caption.',
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
                  border: Border.all(color: scheme.outlineVariant),
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
                        await app.createPost(
                          caption: _caption.text,
                          imageBytes: _imageBytes!,
                          filename: _imageName ?? 'post.jpg',
                        );
                        if (!mounted) return;
                        setState(() {
                          _posting = false;
                          _imageBytes = null;
                          _imageName = null;
                          _caption.clear();
                        });
                      },
                icon: _posting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish_outlined),
                label: const Text('Publish'),
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
    final shared = app.postById(post.sharedPostId);
    final isMine = post.authorId == app.profile?.id;
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
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
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '@${author?.handle ?? 'member'}',
                          style: Theme.of(context).textTheme.bodySmall,
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
              child: Text(post.caption),
            ),
          if (post.imageUrl != null)
            Container(
              width: double.infinity,
              color: scheme.surfaceContainerHighest,
              constraints: const BoxConstraints(maxHeight: 620),
              child: Image.network(
                post.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(height: 180),
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
                children: comments
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
}

class _CommentRow extends StatelessWidget {
  final PostComment comment;
  final SocialPost post;

  const _CommentRow({required this.comment, required this.post});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final author = app.profileById(comment.authorId);
    final canDelete =
        comment.authorId == app.profile?.id || post.authorId == app.profile?.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(url: author?.avatarUrl, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author?.fullName ?? 'Member',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  Text(comment.body),
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
