import 'package:flutter/material.dart';

class ProfileAvatar extends StatefulWidget {
  final String name;
  final double size;
  final VoidCallback? onTap;
  final String label;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.size = 34,
    this.onTap,
    this.label = 'Settings',
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final initials = widget.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();

    return Semantics(
      button: widget.onTap != null,
      label: widget.label,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: SizedBox(
            width: widget.onTap == null
                ? widget.size
                : widget.size.clamp(44, double.infinity),
            height: widget.onTap == null
                ? widget.size
                : widget.size.clamp(44, double.infinity),
            child: Center(
                child: AnimatedScale(
              scale: _pressed ? .94 : 1,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: ClipOval(
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .6), width: .8),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF2F3F3),
                          Color(0xFFCDD1D3),
                          Color(0xFF979FA3)
                        ],
                        stops: [0, .52, 1],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials.isEmpty ? 'F' : initials,
                        style: TextStyle(
                          color: const Color(0xFF171A1C),
                          fontWeight: FontWeight.w600,
                          fontSize: widget.size * .29,
                          letterSpacing: -.3,
                        ),
                        textScaler: TextScaler.noScaling,
                      ),
                    ),
                  ),
                ),
              ),
            ))),
      ),
    );
  }
}
