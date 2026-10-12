import 'package:flutter/material.dart';

import 'liquid_button.dart';

/// Backwards-compatible name for the shared liquid action button.
@Deprecated('Use LiquidButton directly.')
class PrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final double height;
  final bool isAccent;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.height = 56,
    this.isAccent = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => LiquidButton(
        title: title,
        onPressed: onPressed,
        height: height,
        isAccent: isAccent,
        isLoading: isLoading,
        showArrow: false,
      );
}
