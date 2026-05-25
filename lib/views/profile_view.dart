import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../widgets/common_widgets.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late TextEditingController _nameC, _handleC, _bioC, _interestsC;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>().profile;
    _nameC = TextEditingController(text: p?.fullName ?? '');
    _handleC = TextEditingController(text: p?.handle ?? '');
    _bioC = TextEditingController(text: p?.bio ?? '');
    _interestsC = TextEditingController(text: p?.interests.join(', ') ?? '');
  }

  @override
  void dispose() {
    _nameC.dispose();
    _handleC.dispose();
    _bioC.dispose();
    _interestsC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final p = app.profile!;
    final isWide = MediaQuery.of(context).size.width > 900;

    final preview = VPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              gradient: LinearGradient(
                colors: [
                  VoxoraColors.primary.withValues(alpha: 0.2),
                  VoxoraColors.cyan.withValues(alpha: 0.15),
                ],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: p.coverUrl != null && p.coverUrl!.isNotEmpty
                ? Image.network(
                    p.coverUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  )
                : Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: VoxoraColors.muted.withValues(alpha: 0.3),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -42),
                  child: VAvatar(
                    url: p.avatarUrl,
                    size: 88,
                    border: true,
                    showOnline: true,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.fullName,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: VoxoraColors.cyan.withValues(alpha: 0.15),
                              border: Border.all(
                                color: VoxoraColors.cyan.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Level ${p.level}',
                              style: const TextStyle(
                                color: VoxoraColors.cyan,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '@${p.handle}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (p.email != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: VoxoraColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              p.email!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: VoxoraColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        p.bio.isEmpty
                            ? 'No bio yet. Tell the world about yourself!'
                            : p.bio,
                        style: const TextStyle(
                          color: VoxoraColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      if (p.interests.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: p.interests
                              .map(
                                (i) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: VoxoraColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    border: Border.all(
                                      color: VoxoraColors.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    i,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: VoxoraColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _statsItem('Joined', _formatDate(p.createdAt)),
                          const SizedBox(width: 20),
                          if (p.isAdmin)
                            const VStatusBadge(
                              label: 'Admin',
                              color: VoxoraColors.lime,
                              icon: Icons.shield,
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
    );

    final form = VPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VSectionTitle(icon: Icons.edit_outlined, title: 'Edit Profile'),
          TextField(
            controller: _nameC,
            style: const TextStyle(color: VoxoraColors.text),
            decoration: const InputDecoration(
              labelText: 'Display name',
              prefixIcon: Icon(
                Icons.person_outline,
                size: 18,
                color: VoxoraColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _handleC,
            style: const TextStyle(color: VoxoraColors.text),
            decoration: const InputDecoration(
              labelText: 'Handle',
              prefixIcon: Icon(
                Icons.alternate_email,
                size: 18,
                color: VoxoraColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bioC,
            maxLines: 4,
            style: const TextStyle(color: VoxoraColors.text),
            decoration: const InputDecoration(
              labelText: 'Bio',
              prefixIcon: Icon(
                Icons.info_outline,
                size: 18,
                color: VoxoraColors.muted,
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _interestsC,
            style: const TextStyle(color: VoxoraColors.text),
            decoration: const InputDecoration(
              labelText: 'Interests (comma-separated)',
              prefixIcon: Icon(
                Icons.interests_outlined,
                size: 18,
                color: VoxoraColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Upload buttons
          Text('MEDIA', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _uploadButton(
                label: _uploading ? 'Uploading...' : 'Upload Avatar',
                icon: Icons.account_circle_outlined,
                onTap: _uploading
                    ? null
                    : () => _pickProfileImage(app, isAvatar: true),
              ),
              _uploadButton(
                label: _uploading ? 'Uploading...' : 'Upload Cover',
                icon: Icons.image_outlined,
                onTap: _uploading
                    ? null
                    : () => _pickProfileImage(app, isAvatar: false),
              ),
            ],
          ),
          const SizedBox(height: 24),
          VGradientButton(
            label: 'Save Changes',
            icon: Icons.check,
            fullWidth: true,
            onTap: () {
              app.updateProfile(
                fullName: _nameC.text,
                handle: _handleC.text,
                bio: _bioC.text,
                interests: _interestsC.text
                    .split(',')
                    .map((i) => i.trim())
                    .where((i) => i.isNotEmpty)
                    .toList(),
              );
            },
          ),
        ],
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: preview),
          const SizedBox(width: 18),
          Expanded(child: form),
        ],
      );
    }
    return Column(children: [preview, const SizedBox(height: 18), form]);
  }

  Widget _uploadButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: VoxoraColors.surfaceLight,
          border: Border.all(color: VoxoraColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: VoxoraColors.cyan),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: VoxoraColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: VoxoraColors.muted,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: VoxoraColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return 'Member';
    }
  }

  Future<void> _pickProfileImage(
    AppProvider app, {
    required bool isAvatar,
  }) async {
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['png', 'jpg', 'jpeg', 'webp'],
      mimeTypes: ['image/png', 'image/jpeg', 'image/webp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      if (isAvatar) {
        await app.uploadAvatar(bytes, file.name);
      } else {
        await app.uploadCover(bytes, file.name);
      }
      if (app.profile != null) {
        await app.loadAppData(app.profile!.id, showLoader: false);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}
