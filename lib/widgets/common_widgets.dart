import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/models.dart';

class VSpaceBackground extends StatelessWidget {
  final Widget child;
  final bool dense;
  const VSpaceBackground({super.key, required this.child, this.dense = false});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: VoxoraColors.bg,
            gradient: RadialGradient(
              center: const Alignment(-0.72, -0.88),
              radius: 1.25,
              colors: [
                VoxoraColors.primary.withValues(alpha: dense ? 0.24 : 0.18),
                VoxoraColors.bg,
              ],
            ),
          ),
        ),
      ),
      Positioned.fill(child: CustomPaint(painter: _StarTexturePainter(dense))),
      Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.10),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.28),
                ],
              ),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class _StarTexturePainter extends CustomPainter {
  final bool dense;
  const _StarTexturePainter(this.dense);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final count = dense ? 180 : 110;
    for (var i = 0; i < count; i++) {
      final x = (math.sin(i * 12.9898) * 43758.5453).abs() % 1;
      final y = (math.sin(i * 78.233) * 24634.6345).abs() % 1;
      final radius = 0.55 + ((i * 17) % 9) / 12;
      final opacity = 0.12 + ((i * 31) % 10) / 55;
      paint.color = VoxoraColors.cream.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x * size.width, y * size.height), radius, paint);
    }

    paint.color = VoxoraColors.neon.withValues(alpha: 0.055);
    for (var i = 0; i < 7; i++) {
      final cx = ((i * 211) % 997) / 997 * size.width;
      final cy = ((i * 367) % 997) / 997 * size.height;
      canvas.drawCircle(Offset(cx, cy), 90 + i * 18, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarTexturePainter oldDelegate) =>
      oldDelegate.dense != dense;
}

class VLiquidGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry borderRadius;

  const VLiquidGlass({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        padding: padding,
        decoration: VoxoraTheme.glassPanelDecoration.copyWith(
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    ),
  );
}

// ── Panel ──
class VPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const VPanel({super.key, required this.child, this.padding});
  @override
  Widget build(BuildContext context) => VLiquidGlass(
    padding: padding ?? const EdgeInsets.all(20),
    borderRadius: BorderRadius.circular(28),
    child: child,
  );
}

// ── Glass Panel ──
class VGlassPanel extends StatelessWidget {
  final Widget child;
  const VGlassPanel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => VLiquidGlass(
    padding: const EdgeInsets.all(20),
    borderRadius: BorderRadius.circular(28),
    child: child,
  );
}

// ── Section Title ──
class VSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  const VSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [
                VoxoraColors.primary.withValues(alpha: 0.2),
                VoxoraColors.cyan.withValues(alpha: 0.15),
              ],
            ),
          ),
          child: Icon(icon, size: 18, color: VoxoraColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

// ── Empty State ──
class VEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const VEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 300,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  VoxoraColors.primary.withValues(alpha: 0.15),
                  VoxoraColors.cyan.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(icon, size: 36, color: VoxoraColors.primary),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// ── List Row ──
class VListRow extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onTap;
  final Widget child;
  const VListRow({
    super.key,
    this.isActive = false,
    this.onTap,
    required this.child,
  });
  @override
  State<VListRow> createState() => _VListRowState();
}

class _VListRowState extends State<VListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isActive
                ? VoxoraColors.primary.withValues(alpha: 0.5)
                : _hovered
                ? VoxoraColors.line
                : VoxoraColors.lineLight,
          ),
          borderRadius: BorderRadius.circular(12),
          gradient: widget.isActive
              ? LinearGradient(
                  colors: [
                    VoxoraColors.primary.withValues(alpha: 0.15),
                    VoxoraColors.cyan.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: widget.isActive
              ? null
              : (_hovered ? VoxoraColors.surfaceLight : VoxoraColors.surface),
        ),
        child: widget.child,
      ),
    ),
  );
}

// ── Person Row ──
class VPersonRow extends StatelessWidget {
  final Profile person;
  final String action;
  final VoidCallback? onAction;
  final bool blocked;
  const VPersonRow({
    super.key,
    required this.person,
    required this.action,
    this.onAction,
    this.blocked = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(
        color: blocked
            ? VoxoraColors.danger.withValues(alpha: 0.3)
            : VoxoraColors.line,
      ),
      borderRadius: BorderRadius.circular(12),
      color: blocked
          ? VoxoraColors.danger.withValues(alpha: 0.08)
          : VoxoraColors.surface,
    ),
    child: Row(
      children: [
        VAvatar(url: person.avatarUrl, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: VoxoraColors.text,
                ),
              ),
              Text(
                '@${person.handle}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        VSecondaryButton(
          label: action,
          icon: blocked ? Icons.block : Icons.person_add_outlined,
          onTap: onAction,
        ),
      ],
    ),
  );
}

// ── Avatar ──
class VAvatar extends StatelessWidget {
  final String? url;
  final double size;
  final bool border;
  final bool showOnline;
  const VAvatar({
    super.key,
    this.url,
    this.size = 42,
    this.border = false,
    this.showOnline = false,
  });
  @override
  Widget build(BuildContext context) {
    Widget img;
    if (url != null && url!.isNotEmpty) {
      img = ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    } else {
      img = _fallback();
    }
    Widget result;
    if (border) {
      result = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: VoxoraColors.surface, width: 3),
          boxShadow: [
            BoxShadow(
              color: VoxoraColors.primary.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: img,
      );
    } else {
      result = img;
    }
    if (showOnline) {
      return Stack(
        children: [
          result,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VoxoraColors.online,
                border: Border.all(color: VoxoraColors.surface, width: 2),
              ),
            ),
          ),
        ],
      );
    }
    return result;
  }

  Widget _fallback() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [
          VoxoraColors.primary.withValues(alpha: 0.25),
          VoxoraColors.cyan.withValues(alpha: 0.2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Icon(Icons.person, size: size * 0.5, color: VoxoraColors.primary),
  );
}

// ── Avatar Stack ──
class VAvatarStack extends StatelessWidget {
  final List<Profile> members;
  const VAvatarStack({super.key, required this.members});
  @override
  Widget build(BuildContext context) {
    final visible = members.take(3).toList();
    if (visible.isEmpty) return const VAvatar(size: 42);
    return SizedBox(
      width: 42.0 + (visible.length - 1) * 24.0,
      height: 42,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * 24.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: VoxoraColors.surface, width: 2),
                ),
                child: VAvatar(url: visible[i].avatarUrl, size: 38),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Message Bubble ──
class VMessageBubble extends StatelessWidget {
  final String? name;
  final String body;
  final String time;
  final bool isMine;
  const VMessageBubble({
    super.key,
    this.name,
    required this.body,
    required this.time,
    this.isMine = false,
  });
  @override
  Widget build(BuildContext context) {
    String fmtTime;
    try {
      final d = DateTime.parse(time);
      fmtTime =
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      fmtTime = '';
    }
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          gradient: isMine
              ? const LinearGradient(
                  colors: [VoxoraColors.primary, Color(0xFFE91E63)],
                )
              : null,
          color: isMine ? null : VoxoraColors.surfaceLight,
          border: isMine ? null : Border.all(color: VoxoraColors.line),
          boxShadow: isMine
              ? [
                  BoxShadow(
                    color: VoxoraColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  name!,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: isMine ? Colors.white : VoxoraColors.cyan,
                  ),
                ),
              ),
            Text(
              body,
              style: TextStyle(
                color: isMine ? Colors.white : VoxoraColors.text,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fmtTime,
              style: TextStyle(
                fontSize: 11,
                color: isMine ? Colors.white60 : VoxoraColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Buttons ──
class VGradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool fullWidth;
  const VGradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.fullWidth = false,
  });
  @override
  State<VGradientButton> createState() => _VGradientButtonState();
}

class _VGradientButtonState extends State<VGradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.onTap != null
        ? (_) => setState(() => _pressed = true)
        : null,
    onTapUp: widget.onTap != null
        ? (_) => setState(() => _pressed = false)
        : null,
    onTapCancel: () => setState(() => _pressed = false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: widget.fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: widget.onTap != null
              ? const LinearGradient(
                  colors: [VoxoraColors.neon, Color(0xFFD7FF7A)],
                )
              : null,
          color: widget.onTap == null ? VoxoraColors.line : null,
          boxShadow: widget.onTap != null
              ? [
                  BoxShadow(
                    color: VoxoraColors.neon.withValues(alpha: 0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon!,
                size: 18,
                color: widget.onTap != null
                    ? VoxoraColors.bg
                    : VoxoraColors.muted,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: TextStyle(
                color: widget.onTap != null
                    ? VoxoraColors.bg
                    : VoxoraColors.muted,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class VSecondaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const VSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  });
  @override
  State<VSecondaryButton> createState() => _VSecondaryButtonState();
}

class _VSecondaryButtonState extends State<VSecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _hovered
                ? VoxoraColors.neon.withValues(alpha: 0.5)
                : VoxoraColors.line,
          ),
          color: _hovered
              ? VoxoraColors.neon.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon!,
                size: 16,
                color: _hovered ? VoxoraColors.neon : VoxoraColors.muted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _hovered
                    ? VoxoraColors.neon
                    : VoxoraColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class VDangerButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const VDangerButton({super.key, required this.label, this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [
            VoxoraColors.danger,
            VoxoraColors.danger.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: VoxoraColors.danger.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon!, size: 16, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

class VGradientIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const VGradientIconButton({super.key, required this.icon, this.onTap});
  @override
  State<VGradientIconButton> createState() => _VGradientIconButtonState();
}

class _VGradientIconButtonState extends State<VGradientIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.onTap != null
        ? (_) => setState(() => _pressed = true)
        : null,
    onTapUp: widget.onTap != null
        ? (_) => setState(() => _pressed = false)
        : null,
    onTapCancel: () => setState(() => _pressed = false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: _pressed ? 0.9 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: widget.onTap != null
              ? const LinearGradient(
                  colors: [VoxoraColors.primary, VoxoraColors.coral],
                )
              : null,
          color: widget.onTap == null ? VoxoraColors.line : null,
          boxShadow: widget.onTap != null
              ? [
                  BoxShadow(
                    color: VoxoraColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Icon(widget.icon, color: Colors.white, size: 18),
      ),
    ),
  );
}

// ── Status badge ──
class VStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const VStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: color.withValues(alpha: 0.15),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon!, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

// ── Animated Pulse Dot ──
class VPulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const VPulseDot({
    super.key,
    this.color = VoxoraColors.online,
    this.size = 10,
  });
  @override
  State<VPulseDot> createState() => _VPulseDotState();
}

class _VPulseDotState extends State<VPulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (context, child) => Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color,
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.4 + _ctrl.value * 0.3),
            blurRadius: 4 + _ctrl.value * 6,
          ),
        ],
      ),
    ),
  );
}

class VVoiceChatBubble extends StatefulWidget {
  final List<RoomParticipant> participants;
  final bool joined;
  final VoidCallback? onJoin;

  const VVoiceChatBubble({
    super.key,
    required this.participants,
    required this.joined,
    this.onJoin,
  });

  @override
  State<VVoiceChatBubble> createState() => _VVoiceChatBubbleState();
}

class _VVoiceChatBubbleState extends State<VVoiceChatBubble> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final visible = widget.participants.take(4).toList();
    final hidden = math.max(0, widget.participants.length - visible.length);
    final speaking = widget.participants.any((p) => p.speaking || !p.muted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: VLiquidGlass(
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
            borderRadius: BorderRadius.circular(999),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VoxoraColors.neon.withValues(alpha: 0.10),
                        border: Border.all(
                          color: VoxoraColors.neon.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        speaking ? Icons.graphic_eq : Icons.mic,
                        color: speaking
                            ? VoxoraColors.neon
                            : VoxoraColors.muted,
                        size: 20,
                      ),
                    ),
                    if (speaking)
                      const Positioned(
                        left: -2,
                        top: -2,
                        child: _SpeakingGlyph(),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: math.max(42.0, 30.0 + visible.length * 24),
                  height: 42,
                  child: Stack(
                    children: [
                      for (var i = 0; i < visible.length; i++)
                        Positioned(
                          left: i * 23.0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: VoxoraColors.bg,
                                width: 2,
                              ),
                            ),
                            child: VAvatar(
                              url: visible[i].profile?.avatarUrl,
                              size: 40,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (hidden > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '+$hidden',
                    style: const TextStyle(
                      color: VoxoraColors.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _open ? 0.25 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.chevron_right,
                    color: VoxoraColors.muted,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: VLiquidGlass(
                    padding: const EdgeInsets.all(18),
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.spatial_audio_off_outlined,
                              color: VoxoraColors.neon,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'VOICE CHAT',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: VoxoraColors.text),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: widget.participants.map((p) {
                            final isLive = p.speaking || !p.muted;
                            return SizedBox(
                              width: 76,
                              child: Column(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      VAvatar(
                                        url: p.profile?.avatarUrl,
                                        size: 54,
                                        showOnline: isLive,
                                      ),
                                      if (isLive)
                                        const Positioned(
                                          left: -4,
                                          top: -4,
                                          child: _SpeakingGlyph(),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    p.profile?.fullName ?? 'Member',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: VoxoraColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        VGradientButton(
                          label: widget.joined ? 'Joined' : 'Join Now',
                          icon: widget.joined ? Icons.check : Icons.call,
                          fullWidth: true,
                          onTap: widget.joined ? null : widget.onJoin,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mic starts muted. Open the channel when you are ready.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SpeakingGlyph extends StatefulWidget {
  const _SpeakingGlyph();

  @override
  State<_SpeakingGlyph> createState() => _SpeakingGlyphState();
}

class _SpeakingGlyphState extends State<_SpeakingGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final v = _controller.value;
      return Container(
        width: 24,
        height: 24,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: VoxoraColors.bg,
          border: Border.all(color: VoxoraColors.neon.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _bar(5 + v * 7),
            const SizedBox(width: 2),
            _bar(11 - v * 5),
            const SizedBox(width: 2),
            _bar(7 + v * 4),
          ],
        ),
      );
    },
  );

  Widget _bar(double height) => Container(
    width: 3,
    height: height,
    decoration: BoxDecoration(
      color: VoxoraColors.neon,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
