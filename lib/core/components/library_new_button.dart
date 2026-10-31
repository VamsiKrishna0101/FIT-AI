import 'package:flutter/material.dart';
import '../theme/fitness_theme.dart';

class LibraryNewButton extends StatelessWidget {
  const LibraryNewButton({super.key, required this.label, this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 18, 8),
      child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
              backgroundColor: FitnessTheme.silver,
              foregroundColor: FitnessTheme.canvas,
              disabledBackgroundColor: FitnessTheme.line,
              minimumSize: const Size(60, 40),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: TextStyle(
                  fontFamily: Theme.of(context).platform == TargetPlatform.iOS
                      ? 'CupertinoSystemText'
                      : 'Inter',
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w600)),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)));
}
