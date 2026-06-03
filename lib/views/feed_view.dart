import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

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
            _StoryRail(app: app),
            const SizedBox(height: 14),
            _ComposerPrompt(app: app),
            const SizedBox(height: 14),
            if (app.posts.isEmpty)
              const EmptyState(
                icon: Icons.photo_library_outlined,
                title: 'No posts yet',
                body:
                    'Picture posts from you and your friends will appear here.',
              )
            else
              ...app.posts.asMap().entries.map(
                (entry) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(
                    milliseconds: 260 + min(entry.key, 5) * 45,
                  ),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PostCard(post: entry.value),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: scheme.primary.withValues(alpha: 0.10),
      child: Row(
        children: [
          UserAvatar(
            url: app.profile?.avatarUrl,
            size: 42,
            online: app.isProfileOnline(app.profile),
            seed: app.profile?.handle,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CreatePostPage()),
              ),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: scheme.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drop a moment...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.56),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Post Image',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CreatePostPage()),
            ),
            style: IconButton.styleFrom(
              backgroundColor: scheme.primary.withValues(alpha: 0.10),
              foregroundColor: scheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.image_outlined, size: 24),
            color: scheme.primary,
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
    final myId = app.profile?.id;
    final friendsWithStories = app.friends
        .where((person) => app.hasActiveStory(person.id))
        .where((person) => person.id != myId)
        .toList();
    final people = <Profile>[
      if (app.profile != null) app.profile!,
      ...friendsWithStories,
    ].take(12).toList();
    if (people.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final person = people[index];
          final stories = app.activeStoriesForProfile(person.id);
          final mine = person.id == myId;
          return _StoryBubble(
            person: person,
            mine: mine,
            hasStories: stories.isNotEmpty,
            storyCount: stories.length,
            onTap: () {
              if (stories.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StoryViewerPage(authorId: person.id),
                  ),
                );
              } else if (mine) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateStoryPage(),
                  ),
                );
              }
            },
            onAdd: mine
                ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CreateStoryPage(),
                    ),
                  )
                : null,
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
  final bool hasStories;
  final int storyCount;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  const _StoryBubble({
    required this.person,
    required this.mine,
    required this.hasStories,
    required this.storyCount,
    required this.onTap,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(42),
      child: SizedBox(
        width: 86,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 66,
              height: 66,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _StoryRing(
                    active: hasStories,
                    child: UserAvatar(
                      url: person.avatarUrl,
                      size: 56,
                      online: context.read<AppProvider>().isProfileOnline(
                        person,
                      ),
                      seed: person.handle,
                    ),
                  ),
                  if (onAdd != null)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: InkWell(
                        onTap: onAdd,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              mine && !hasStories
                  ? 'Add story'
                  : mine
                  ? 'Your story'
                  : person.fullName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            Text(
              hasStories ? '$storyCount active' : '@${person.handle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryRing extends StatelessWidget {
  final bool active;
  final Widget child;

  const _StoryRing({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 66,
      height: 66,
      padding: EdgeInsets.all(active ? 3 : 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, VoxoraColors.accentPop],
              )
            : null,
        border: active
            ? null
            : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Center(child: child),
    );
  }
}

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
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
      appBar: AppBar(title: const Text('Add story')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
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
      color: scheme.primary.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            icon: Icons.auto_stories_outlined,
            title: 'New story',
            subtitle: 'Share a profile moment.',
          ),
          TextField(
            controller: _caption,
            maxLines: 2,
            maxLength: 280,
            decoration: const InputDecoration(
              hintText: 'Add a caption...',
              prefixIcon: Icon(Icons.short_text),
            ),
          ),
          const SizedBox(height: 12),
          if (_imageBytes != null)
            AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
              ),
            )
          else
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: scheme.primary,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose picture',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _posting ? null : _pickImage,
                icon: const Icon(Icons.image_search_outlined),
                label: Text(_imageBytes != null ? 'Change' : 'Picture'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _posting || _imageBytes == null
                    ? null
                    : () async {
                        setState(() => _posting = true);
                        try {
                          await app.createStory(
                            caption: _caption.text,
                            imageBytes: _imageBytes!,
                            filename: _imageName ?? 'story.jpg',
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
                label: const Text('Share'),
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

class StoryViewerPage extends StatefulWidget {
  final String authorId;
  final int initialIndex;

  const StoryViewerPage({
    super.key,
    required this.authorId,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> {
  static const _storyDuration = Duration(seconds: 5);

  late int _index;
  late DateTime _startedAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      if (_progress >= 1) {
        _next();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progress {
    return DateTime.now().difference(_startedAt).inMilliseconds /
        _storyDuration.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final stories = app.activeStoriesForProfile(widget.authorId);
    final author = app.profileById(widget.authorId);
    final mine = widget.authorId == app.profile?.id;

    if (stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              const Center(
                child: Text(
                  'No active stories',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final visibleIndex = _index.clamp(0, stories.length - 1).toInt();
    final story = stories[visibleIndex];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          if (details.localPosition.dx < size.width / 2) {
            _previous();
          } else {
            _next(stories.length);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              story.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white70,
                  size: 48,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black87,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black87,
                  ],
                  stops: [0, 0.18, 0.68, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: Column(
                  children: [
                    _StoryProgressBars(
                      count: stories.length,
                      activeIndex: visibleIndex,
                      progress: visibleIndex == _index
                          ? _progress.clamp(0.0, 1.0).toDouble()
                          : 1.0,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        UserAvatar(
                          url: author?.avatarUrl,
                          size: 34,
                          seed: author?.handle,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                author?.fullName ?? 'Story',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                _storyTimeAgo(story.createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (mine)
                          IconButton(
                            tooltip: 'Delete story',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                            onPressed: () => _deleteStory(app, story),
                          ),
                        IconButton(
                          tooltip: 'Close',
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (story.caption.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 540),
                        child: Text(
                          story.caption,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previous() {
    setState(() {
      if (_index <= 0) {
        _startedAt = DateTime.now();
      } else {
        _index--;
        _startedAt = DateTime.now();
      }
    });
  }

  void _next([int? storyCount]) {
    final count =
        storyCount ??
        context
            .read<AppProvider>()
            .activeStoriesForProfile(widget.authorId)
            .length;
    if (_index + 1 >= count) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _index++;
      _startedAt = DateTime.now();
    });
  }

  Future<void> _deleteStory(AppProvider app, Story story) async {
    await app.deleteStory(story);
    if (!mounted) return;
    final remaining = app.activeStoriesForProfile(widget.authorId).length;
    if (remaining == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _index = min(_index, remaining - 1);
      _startedAt = DateTime.now();
    });
  }
}

class _StoryProgressBars extends StatelessWidget {
  final int count;
  final int activeIndex;
  final double progress;

  const _StoryProgressBars({
    required this.count,
    required this.activeIndex,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final value = index < activeIndex
            ? 1.0
            : index == activeIndex
            ? progress
            : 0.0;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 3,
                color: Colors.white30,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0).toDouble(),
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

String _storyTimeAgo(String raw) {
  try {
    final created = DateTime.parse(raw).toLocal();
    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${created.month}/${created.day}';
  } catch (_) {
    return '';
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
              constraints: const BoxConstraints(maxWidth: 600),
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
      color: scheme.primary.withValues(alpha: 0.1),
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, color: scheme.primary, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'Choose picture',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
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
                label: Text(_imageBytes != null ? 'Change' : 'Picture'),
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

class PostCard extends StatefulWidget {
  final SocialPost post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => PostCardState();
}

class PostCardState extends State<PostCard> {
  final _comment = TextEditingController();
  final _commentFocus = FocusNode();

  @override
  void dispose() {
    _comment.dispose();
    _commentFocus.dispose();
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
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;

    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: scheme.outlineVariant.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            _mediaFrame(app, post, author, isMine)
          else
            _authorHeader(app, post, author, isMine),
          if (post.caption.isNotEmpty || shared != null)
            Padding(
              padding: EdgeInsets.fromLTRB(14, hasImage ? 12 : 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.caption.isNotEmpty)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: author?.handle == null
                                ? ''
                                : '@${author!.handle}  ',
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(text: post.caption),
                        ],
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.42,
                      ),
                    ),
                  if (shared != null) ...[
                    if (post.caption.isNotEmpty) const SizedBox(height: 12),
                    _SharedPostPreview(post: shared),
                  ],
                ],
              ),
            ),
          _actionRow(app, post, comments.length),
          if (comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
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
                    focusNode: _commentFocus,
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

  Widget _mediaFrame(
    AppProvider app,
    SocialPost post,
    Profile? author,
    bool isMine,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 280, maxHeight: 620),
          color: scheme.surfaceContainerHighest,
          child: Image.network(
            post.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
              height: 280,
              child: Center(child: Icon(Icons.broken_image_outlined, size: 42)),
            ),
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          top: 10,
          child: _AuthorOverlay(
            author: author,
            timestamp: _timeAgo(post.createdAt),
            onTap: author == null ? null : () => app.viewProfile(author.id),
            trailing: isMine ? _postMenu(app, post, light: true) : null,
          ),
        ),
      ],
    );
  }

  Widget _authorHeader(
    AppProvider app,
    SocialPost post,
    Profile? author,
    bool isMine,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
      child: Row(
        children: [
          InkWell(
            onTap: author == null ? null : () => app.viewProfile(author.id),
            customBorder: const CircleBorder(),
            child: UserAvatar(
              url: author?.avatarUrl,
              online: app.isProfileOnline(author),
              seed: author?.handle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: author == null ? null : () => app.viewProfile(author.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author?.fullName ?? 'Member',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '@${author?.handle ?? 'member'}  ${_timeAgo(post.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (isMine) _postMenu(app, post),
        ],
      ),
    );
  }

  Widget _postMenu(AppProvider app, SocialPost post, {bool light = false}) {
    return PopupMenuButton<String>(
      tooltip: 'Post actions',
      iconColor: light ? Colors.white : null,
      onSelected: (value) {
        if (value == 'edit') _editPost(app, post);
        if (value == 'delete') app.deletePost(post);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Widget _actionRow(AppProvider app, SocialPost post, int commentCount) {
    final scheme = Theme.of(context).colorScheme;
    final liked = app.likedPost(post.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () => app.toggleLike(post),
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? VoxoraColors.rose : scheme.onSurface,
            ),
            label: Text('${app.likeCount(post.id)}'),
          ),
          TextButton.icon(
            onPressed: () => app.sharePost(post),
            icon: const Icon(Icons.ios_share_outlined),
            label: Text('${app.shareCount(post.id)}'),
          ),
          TextButton.icon(
            onPressed: () => _commentFocus.requestFocus(),
            icon: const Icon(Icons.mode_comment_outlined),
            label: Text('$commentCount'),
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

class _AuthorOverlay extends StatelessWidget {
  final Profile? author;
  final String timestamp;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _AuthorOverlay({
    required this.author,
    required this.timestamp,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: UserAvatar(
                  url: author?.avatarUrl,
                  size: 34,
                  seed: author?.handle,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author?.fullName ?? 'Member',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '@${author?.handle ?? 'member'}  $timestamp',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
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
              UserAvatar(
                url: author?.avatarUrl,
                size: 28,
                seed: author?.handle,
              ),
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
