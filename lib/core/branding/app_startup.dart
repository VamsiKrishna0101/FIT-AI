import 'package:flutter/material.dart';
import '../localization/fitness_text.dart';
import 'setcraft_launch_screen.dart';

/// Renders before loading preferences/session. Never adds a marketing delay.
class AppStartup extends StatefulWidget {
  final Future<Widget> Function() initialize;
  final VoidCallback? onReady;
  const AppStartup({super.key, required this.initialize, this.onReady});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  Widget? _home;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Let the first branded frame paint before any plugin initialization.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final home = await widget.initialize();
      if (!mounted) return;
      setState(() => _home = home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onReady?.call();
      });
    } catch (_) {
      // Keep stored credentials intact and allow recovery from plugin errors.
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_home != null) return _home!;
    return SetcraftLaunchScreen(
      footer: _failed
          ? SafeArea(
              child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FitnessText('Unable to open the app. Try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFB0B0B0))),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _load,
                      child: const FitnessText('Try again'),
                    ),
                  ],
                ),
              ),
            ))
          : null,
    );
  }
}
