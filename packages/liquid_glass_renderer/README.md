# Liquid Glass Renderer compatibility patch

Vendored from liquid_glass_renderer 0.2.0-dev.4 by whynotmake.it, under the included MIT license. Only the runtime library is included.

Upstream: https://pub.dev/packages/liquid_glass_renderer/versions/0.2.0-dev.4

Local change: guard legacy OpenGL ES Y flips with IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED in the shader sources. Flutter 3.47 stores render textures top-down; unconditional flips sample an upside-down copy of the opposite side of the screen. The guard preserves older Flutter behavior and leaves Vulkan/Metal unchanged.

Migration: https://docs.flutter.dev/release/breaking-changes/opengles-render-to-texture-top-down

Keep this package in the repository so Android and CI builds use the same correction. Replace it with a published upstream release once the fix is included and verified.
