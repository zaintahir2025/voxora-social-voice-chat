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
  void dispose() { _nameC.dispose(); _handleC.dispose(); _bioC.dispose(); _interestsC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final p = app.profile!;
    final isWide = MediaQuery.of(context).size.width > 900;

    final preview = VPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        height: 180, width: double.infinity,
        decoration: BoxDecoration(color: VoxoraColors.primary.withValues(alpha: 0.15), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
        clipBehavior: Clip.antiAlias,
        child: p.coverUrl != null && p.coverUrl!.isNotEmpty
            ? Image.network(p.coverUrl!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => const SizedBox())
            : null,
      ),
      Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Transform.translate(offset: const Offset(0, -46), child: VAvatar(url: p.avatarUrl, size: 96, border: true)),
        Transform.translate(offset: const Offset(0, -20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.fullName, style: Theme.of(context).textTheme.headlineMedium),
          Text('@${p.handle}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(p.bio.isEmpty ? 'No bio yet.' : p.bio, style: TextStyle(color: VoxoraColors.muted, height: 1.55)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: p.interests.map((i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFEEF4FF)),
            child: Text(i, style: const TextStyle(fontSize: 12)),
          )).toList()),
        ])),
      ])),
    ]));

    final form = VPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const VSectionTitle(icon: Icons.edit_outlined, title: 'Customize profile'),
      TextField(controller: _nameC, decoration: const InputDecoration(labelText: 'Display name')),
      const SizedBox(height: 14),
      TextField(controller: _handleC, decoration: const InputDecoration(labelText: 'Handle')),
      const SizedBox(height: 14),
      TextField(controller: _bioC, maxLines: 4, decoration: const InputDecoration(labelText: 'Bio')),
      const SizedBox(height: 14),
      TextField(controller: _interestsC, decoration: const InputDecoration(labelText: 'Interests (comma-separated)')),
      const SizedBox(height: 18),
      Wrap(spacing: 10, runSpacing: 10, children: [
        VSecondaryButton(
          label: _uploading ? 'Uploading...' : 'Upload avatar',
          icon: Icons.account_circle_outlined,
          onTap: _uploading ? null : () => _pickProfileImage(app, isAvatar: true),
        ),
        VSecondaryButton(
          label: _uploading ? 'Uploading...' : 'Upload cover',
          icon: Icons.image_outlined,
          onTap: _uploading ? null : () => _pickProfileImage(app, isAvatar: false),
        ),
      ]),
      const SizedBox(height: 18),
      VGradientButton(label: 'Save changes', icon: Icons.check, onTap: () {
        app.updateProfile(
          fullName: _nameC.text, handle: _handleC.text, bio: _bioC.text,
          interests: _interestsC.text.split(',').map((i) => i.trim()).where((i) => i.isNotEmpty).toList(),
        );
      }),
    ]));

    if (isWide) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: preview), const SizedBox(width: 18), Expanded(child: form)]);
    return Column(children: [preview, const SizedBox(height: 18), form]);
  }

  Future<void> _pickProfileImage(AppProvider app, {required bool isAvatar}) async {
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
