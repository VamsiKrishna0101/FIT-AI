import 'package:flutter/material.dart';

// MARK: - FitAI Design System — Pure Black OLED & Premium Obsidian Glass
class DSColors {
  // ── Canvas ────────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF000000);
  static const Color dashboardBg = bg;
  static const Color bgElevated = Color(0xFF0D0D0D);
  static const Color bgDark = bg;
  static const Color bgCard = Color(0xFF202020);
  static const Color bgChip = bgRaised;
  static const Color bgInset = Color(0xFF080808);
  static const Color bgRaised = Color(0xFF2A2A2A);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color border = Color(0x1CFFFFFF);
  static const Color borderHi = Color(0x2AFFFFFF);
  static Color stroke = border;
  static Color strokeBright = borderHi;

  // Shared dashboard colours.
  static const Color silver = Color(0xFFE2E2E2);
  static const Color muted = Color(0xFF969696);
  static const Color blue = Color(0xFF689FFF);
  static const Color violet = Color(0xFFA28BFA);
  static const Color coral = Color(0xFFED927F);

  // ── Typography ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xA6FFFFFF);
  static const Color textTertiary = Color(0x59FFFFFF);

  // ── Brand Accent ──────────────────────────────────────────────────────────
  static const Color accentLime = Color(0xFF67D7B0);
  static const Color accent = Color(0xFF67D7B0);
  static const Color onAccent = Color(0xFF000000);

  // ── Semantic Colors ───────────────────────────────────────────────────────
  static const Color heat = Color(0xFFFF5252);
  static const Color gold = Color(0xFFFFB84D);
  static const Color ice = Color(0xFF5AC8FA);
  static const Color sage = Color(0xFF37D69A);
  static const Color pulse = Color(0xFF8B7BFF);

  // ── Whoop 4.0 Athletic Biometric Tokens ────────────────────────────────────
  static const Color whoopRecoveryGreen = Color(0xFF00E676);
  static const Color whoopRecoveryAmber = Color(0xFFFFD600);
  static const Color whoopRecoveryRed = Color(0xFFFF3B30);
  static const Color whoopStrainCyan = Color(0xFF00E5FF);
  static const Color whoopStrainBlue = Color(0xFF2979FF);
  static const Color whoopSleepPurple = Color(0xFF7C4DFF);
  static const Color whoopCard = bgCard;
  static const Color whoopCardBorder = border;
  static const Color whoopSubCard = bgRaised;

  // ── Glass Sheen ───────────────────────────────────────────────────────────
  static final LinearGradient glassSheen = LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.035),
      Colors.white.withValues(alpha: 0.0),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Navigation ────────────────────────────────────────────────────────────
  static const Color navInactive = Color(0x7AFFFFFF);
  static const Color navActiveBg = Color(0x2BFFFFFF);
  static const Color navBarBg = Color(0x99111418);
  static const Color navGlassText = Color(0xFFF3F3F5);

  static const LinearGradient navGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xB8181818), Color(0xA6101010), Color(0xB8151515)],
    stops: [0, .52, 1],
  );

  static const LinearGradient navGlassLensGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x12FFFFFF), Color(0x07FFFFFF), Color(0x0DFFFFFF)],
    stops: [0, .6, 1],
  );

  // ── Glass Card Gradient ───────────────────────────────────────────────────
  static const LinearGradient glassCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgCard, bgCard, bgCard],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient canvasGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bg, bg],
  );

  static const LinearGradient titaniumSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF262B30), Color(0xFF191E22), Color(0xFF101316)],
    stops: [0.0, 0.42, 1.0],
  );

  static const LinearGradient liquidActivePill = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E2128), Color(0xFF14161B)],
  );

  static const LinearGradient glassControlGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF343A40), Color(0xFF22272C), Color(0xFF171B1F)],
    stops: [0, 0.38, 1],
  );

  static const LinearGradient actionGlassGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF60686E), Color(0xFF373D42), Color(0xFF22272B)],
    stops: [0, 0.4, 1],
  );

  static final LinearGradient specularBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      const Color(0xFFB8C1C8).withValues(alpha: 0.18),
      const Color(0xFF87919A).withValues(alpha: 0.085),
      const Color(0xFF87919A).withValues(alpha: 0.03),
    ],
    stops: const [0.0, 0.4, 1.0],
  );
}

// Lightweight shared dark card for screens that need an InkWell surface.
class FastGlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accentTint; // Optional subtle color tint for the card

  const FastGlassCard({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.accentTint,
  });

  @override
  Widget build(BuildContext context) {
    final tint = accentTint;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: DSColors.bgCard,
            border: Border.all(
              color: tint == null
                  ? DSColors.border
                  : Color.lerp(DSColors.border, tint, .2)!,
              width: .7,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 20,
                right: 20,
                child: Container(
                  height: 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.035),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(radius),
                  child: Padding(
                    padding: padding,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Backward-compatible GlassCard
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.all(20),
    this.blur = 24,
  });

  @override
  Widget build(BuildContext context) {
    return FastGlassCard(
      radius: radius,
      padding: padding,
      child: child,
    );
  }
}
