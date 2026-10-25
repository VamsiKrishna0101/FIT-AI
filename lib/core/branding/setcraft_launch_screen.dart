import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'setcraft_brand.dart';

/// The same stationary, complete mark through native and account startup.
/// Each gate replaces this screen as soon as its existing checks finish.
class SetcraftLaunchScreen extends StatelessWidget {
  final Widget? footer;
  const SetcraftLaunchScreen({super.key, this.footer});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: false,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const Center(child: SetcraftLockup(showName: false)),
              if (footer != null) footer!,
            ],
          ),
        ),
      );
}
