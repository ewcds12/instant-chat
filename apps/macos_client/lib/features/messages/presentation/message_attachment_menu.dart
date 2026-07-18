import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class MessageAttachmentMenu extends StatelessWidget {
  const MessageAttachmentMenu({
    required this.animation,
    required this.onPhoto,
    required this.onFile,
    super.key,
  });

  final Animation<double> animation;
  final VoidCallback onPhoto;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    final opacity = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final scale = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    final slide = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: opacity,
      child: ScaleTransition(
        alignment: Alignment.bottomLeft,
        scale: scale.drive(Tween(begin: 0.96, end: 1.0)),
        child: SlideTransition(
          position: slide.drive(
            Tween(begin: const Offset(0, 0.05), end: Offset.zero),
          ),
          child: _MenuPanel(
            children: [
              _MenuItem(
                icon: Icons.photo_outlined,
                label: 'Photo…',
                onTap: onPhoto,
              ),
              _MenuItem(
                icon: Icons.insert_drive_file_outlined,
                label: 'File…',
                onTap: onFile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      child: GlassPanel(
        tint: RetroColors.glassStrong,
        radius: 16,
        padding: const EdgeInsets.all(6),
        child: Material(
          color: Colors.transparent,
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
