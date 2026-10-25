import 'dart:math' as math;
import '../../../core/theme/fitness_accents.dart';
import '../../../core/theme/ds_motion.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/components/motion.dart';
import '../../progress/components/exercise_progress_content.dart';
import '../../progress/components/progress_surface.dart';
import '../../progress/models/progress_models.dart';
import '../../progress/repositories/progress_repository.dart';

// Shared by Progress and Rank; the repository scopes its cache to the account.
typedef ExerciseProgressLoader = Future<ProgressJson> Function(
    {String? cursor, bool refresh});

class ExerciseInsights extends StatefulWidget {
  final String exerciseId;
  final bool rank;
  final ExerciseProgressLoader? loader;
  const ExerciseInsights(
      {super.key, required this.exerciseId, this.rank = false, this.loader});

  @override
  State<ExerciseInsights> createState() => _ExerciseInsightsState();
}

class _ExerciseInsightsState extends State<ExerciseInsights> {
  ProgressJson? _data;
  bool _loading = true, _more = false, _failed = false;
  int _request = 0;
  StreamSubscription<String>? _updates;
  String get _path => '/exercises/${Uri.encodeComponent(widget.exerciseId)}';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    LanguageManager.shared.addListener(_languageChanged);
    _updates = ProgressRepository.shared.updates.stream.listen((key) {
      if (key == 'invalidated') {
        unawaited(_load(refresh: true));
      } else if (!_loading &&
          !_more &&
          key.contains(_path) &&
          widget.loader == null) {
        unawaited(_readCache());
      }
    });
  }

  @override
  void didUpdateWidget(ExerciseInsights oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseId != widget.exerciseId ||
        oldWidget.loader != widget.loader) {
      _data = null;
      unawaited(_load());
    }
  }

  void _languageChanged() {
    _data = null;
    unawaited(_load());
  }

  Future<void> _readCache() async {
    final request = _request;
    final data = await ProgressRepository.shared
        .cached(_path, 'all', query: const {'limit': 8});
    if (mounted && request == _request && data != null) {
      setState(() =>
          _data = {...data, if (data['rank'] == null) 'rank': _data?['rank']});
    }
  }

  Future<void> _load({bool refresh = false, bool more = false}) async {
    if (more && (_loading || _more || _data?['nextCursor'] == null)) return;
    final request = ++_request;
    final cursor = more ? _data!['nextCursor'] as String? : null;
    setState(() {
      _loading = !more;
      _more = more;
      _failed = false;
    });
    try {
      var data = widget.loader != null
          ? await widget.loader!(cursor: cursor, refresh: refresh)
          : await ProgressRepository.shared.load(_path, 'all',
              refresh: refresh,
              query: {'limit': 8, if (cursor != null) 'cursor': cursor});
      if (data['rank'] == null && widget.loader == null) {
        final rank = await ProgressRepository.shared
            .load('$_path/rank', 'all', refresh: refresh);
        data = {...data, 'rank': rank};
      }
      if (!mounted || request != _request) return;
      setState(() {
        if (more) {
          final history = {
            for (final day in [
              ...progressRows(_data?['history']),
              ...progressRows(data['history'])
            ])
              day['date']: day,
          };
          _data = {...data, 'history': history.values.toList()};
        } else {
          _data = data;
        }
      });
    } on DioException catch (error) {
      if (!mounted || request != _request) return;
      // This endpoint returns 404 when this exercise has never been logged.
      final body = error.response?.data;
      final message = body is Map ? (body['message'] ?? body['error']) : null;
      if (error.response?.statusCode == 404 &&
          message == 'Exercise history not found') {
        ProgressJson? rank;
        if (widget.loader == null) {
          try {
            rank = await ProgressRepository.shared
                .load('$_path/rank', 'all', refresh: refresh);
          } catch (_) {
            if (mounted && request == _request) setState(() => _failed = true);
          }
        }
        if (!mounted || request != _request) return;
        setState(() => _data = {
              'series': [],
              'history': [],
              'records': {},
              'exercise': {},
              'rank': rank
            });
      } else {
        setState(() => _failed = true);
      }
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _more = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _updates?.cancel();
    LanguageManager.shared.removeListener(_languageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final series = progressRows(data?['series']);
    return MotionEntrance(
      key: ValueKey(widget.rank),
      child: RefreshIndicator(
        color: DSColors.silver,
        onRefresh: () => _load(refresh: true),
        child: ListView(
          key: PageStorageKey(
              'exercise-${widget.exerciseId}-${widget.rank ? 'rank' : 'progress'}'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          children: [
            if (_loading && data == null)
              const Padding(
                  padding: EdgeInsets.all(48),
                  child: CupertinoActivityIndicator())
            else if (_failed && data == null)
              ProgressSurface(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const ProgressEmpty('Could not load exercise history.'),
                    TextButton(
                        onPressed: () => _load(refresh: true),
                        child: Text(fitnessText(context, 'Retry'))),
                  ]))
            else if (data != null) ...[
              if (_loading)
                const LinearProgressIndicator(
                    minHeight: 2, color: DSColors.silver),
              if (widget.rank)
                ExerciseRankContent(data: data)
              else if (series.isEmpty)
                ProgressSurface(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Icon(CupertinoIcons.chart_bar_alt_fill,
                          color: DSColors.muted, size: 28),
                      const SizedBox(height: 16),
                      Text(fitnessText(context, 'Your progress starts here'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const ProgressEmpty(
                          'Log your first set to see charts, records and history here.'),
                    ]))
              else ...[
                Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(fitnessText(context, 'All time'),
                        style: const TextStyle(
                            color: DSColors.muted, fontSize: 12))),
                ExerciseProgressContent(
                    data: data,
                    onMore: !_more && data['nextCursor'] != null
                        ? () => _load(more: true)
                        : null),
                if (_more)
                  const Padding(
                      padding: EdgeInsets.all(16),
                      child: CupertinoActivityIndicator()),
              ],
              if (_failed)
                TextButton.icon(
                  onPressed: () => _load(refresh: true),
                  icon: const Icon(CupertinoIcons.arrow_clockwise, size: 14),
                  label: Text(
                      fitnessText(context, 'Could not refresh. Tap to retry.')),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Strength estimates and badges share the backend calculation used by Body.
class ExerciseRankContent extends StatelessWidget {
  final ProgressJson data;
  const ExerciseRankContent({super.key, required this.data});

  void _badgeDetails(BuildContext context, ProgressJson badge) {
    String copy(String text) => fitnessText(context, text);
    final earned = badge['earned'] == true;
    final tier = (badge['tier'] as num? ?? 1).toInt();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DSColors.bgCard,
      showDragHandle: true,
      useSafeArea: true,
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      builder: (_) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ExerciseRankBadge(tier: tier, earned: earned, size: 100),
            const SizedBox(height: 16),
            Text(copy(badge['title'] as String? ?? ''),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Text(copy(badge['description'] as String? ?? ''),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, height: 1.5, color: DSColors.muted)),
            const SizedBox(height: 16),
            Text(copy(earned ? 'Earned' : 'Locked'),
                style: TextStyle(
                    fontSize: 12,
                    color:
                        earned ? FitnessAccents.rank(tier) : DSColors.muted)),
            if (badge['current'] is num && badge['target'] is num) ...[
              const SizedBox(height: 8),
              Text('${badge['current']} / ${badge['target']}',
                  style: const TextStyle(fontSize: 12, color: DSColors.muted)),
            ],
          ])),
    );
  }

  void _about(BuildContext context, Map<String, dynamic> strength) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      backgroundColor: DSColors.bgCard,
      showDragHandle: true,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(fitnessText(context, 'How ranks work'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Text(
                  fitnessText(context,
                      'Your first qualifying training day gives a provisional estimate. A second day confirms it using the lower of your two strongest recent sessions. Load units must be specified. Reps above 10 are capped. References account for body weight and reference category, without age adjustment.'),
                  style: const TextStyle(fontSize: 13, height: 1.5)),
              const SizedBox(height: 14),
              Text(
                  fitnessText(context,
                      'A reference level, not a workout target. Follow the sets and loads in your plan.'),
                  style: const TextStyle(
                      fontSize: 12, height: 1.4, color: DSColors.muted)),
              if (strength['bodyWeightKg'] is num) ...[
                const SizedBox(height: 14),
                Text(
                    '${fitnessText(context, 'Body weight')}: ${progressValue(context, strength['bodyWeightKg'])} kg',
                    style: const TextStyle(fontSize: 12)),
              ],
              if (strength['sourceUrl'] is String) ...[
                const SizedBox(height: 16),
                const Text('Strength Level',
                    style: TextStyle(fontSize: 12, color: DSColors.muted)),
                const SizedBox(height: 6),
                SelectableText(strength['sourceUrl'] as String,
                    style:
                        const TextStyle(fontSize: 11, color: DSColors.muted)),
              ],
            ]),
      ),
    );
  }

  Widget _badge(BuildContext context, ProgressJson badge, double width) {
    final earned = badge['earned'] == true;
    final tier = (badge['tier'] as num? ?? 1).toInt();
    final accent = FitnessAccents.rank(tier);
    return SizedBox(
      width: width,
      child: MotionPress(
        child: InkWell(
          key: ValueKey('exercise-badge-${badge['id'] ?? badge['title']}'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => _badgeDetails(context, badge),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Column(children: [
              ExerciseRankBadge(tier: tier, size: 64, earned: earned),
              const SizedBox(height: 8),
              Text(fitnessText(context, badge['title'] as String? ?? ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, height: 1.4)),
              const SizedBox(height: 4),
              Text(fitnessText(context, earned ? 'Earned' : 'Locked'),
                  style: TextStyle(
                      fontSize: 10, color: earned ? accent : DSColors.muted)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _estimate(BuildContext context, Map<String, dynamic> strength) {
    final load = Text(
        '${progressValue(context, strength['estimatedMaxKg'])} kg',
        style: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.w500, letterSpacing: -.6));
    final caption = Text(fitnessText(context, 'Conservative 1RM estimate'),
        style: const TextStyle(fontSize: 11, color: DSColors.muted));
    final unit = Text(
        fitnessText(
            context,
            strength['weightUnit'] == 'per_hand'
                ? 'Per dumbbell'
                : 'Total load including bar'),
        style: const TextStyle(fontSize: 11, color: DSColors.muted));

    return LayoutBuilder(builder: (context, bounds) {
      if (MediaQuery.textScalerOf(context).scale(11) > 14) {
        return Column(children: [
          load,
          const SizedBox(height: 8),
          caption,
          const SizedBox(height: 3),
          unit
        ]);
      }
      return Row(children: [
        Expanded(flex: 2, child: load),
        const SizedBox(width: 16),
        Flexible(
            flex: 3,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [caption, const SizedBox(height: 3), unit])),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    String copy(String text) => fitnessText(context, text);
    final rank = data['rank'] as Map?;
    if (rank == null) {
      return const ProgressSurface(
          child: ProgressEmpty('Rank unavailable. Pull down to retry.'));
    }
    final strength =
        Map<String, dynamic>.from(rank['strengthRank'] as Map? ?? const {});
    final tier = (strength['tier'] as num? ?? 0).toInt().clamp(0, 5);
    final title = strength['title'] as String? ?? 'Not ranked yet';
    final progress =
        (strength['progress'] as num? ?? 0).toDouble().clamp(0.0, 1.0);
    final next = strength['nextLevel'] as Map?;
    final badges = progressRows(rank['strengthBadges']);
    final shownBadges = badges.isNotEmpty
        ? badges
        : [
            for (var index = 0; index < 5; index++)
              <String, dynamic>{
                'id': 'STRENGTH_${index + 1}',
                'title': const [
                  'Beginner',
                  'Novice',
                  'Intermediate',
                  'Advanced',
                  'Elite'
                ][index],
                'tier': index + 1,
                'earned': false,
                'description':
                    'An estimated exercise level from repeated logged performance and a matching bodyweight reference.'
              },
          ];
    final accent = FitnessAccents.rank(tier);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        key: const ValueKey('exercise-rank-hero'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
        decoration: BoxDecoration(
          color: DSColors.bgCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: DSColors.border, width: .7),
          gradient: RadialGradient(
              center: const Alignment(0, -.5),
              radius: .9,
              colors: [
                Color.alphaBlend(
                    accent.withValues(alpha: .12), DSColors.bgCard),
                DSColors.bgCard
              ]),
        ),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: Text(copy('Exercise strength'),
                    style:
                        const TextStyle(fontSize: 11, color: DSColors.muted))),
            IconButton(
                tooltip: copy('How ranks work'),
                onPressed: () => _about(context, strength),
                icon: const Icon(CupertinoIcons.info_circle,
                    color: DSColors.muted, size: 18)),
          ]),
          ExerciseRankBadge(tier: tier, size: 104, earned: tier > 0),
          const SizedBox(height: 10),
          Text(copy(title),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.6)),
          const SizedBox(height: 8),
          Text(copy('Exercise-based estimate · last 90 days'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: DSColors.muted)),
          if (strength['provisional'] == true) ...[
            const SizedBox(height: 10),
            Text(copy('Provisional · another training day confirms your level'),
                key: const ValueKey('exercise-strength-provisional'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, height: 1.4, color: DSColors.silver)),
          ],
          if (tier == 0) ...[
            const SizedBox(height: 18),
            Text(
                copy(strength['reason'] as String? ??
                    'No matching strength reference for this exercise yet.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, height: 1.5, color: DSColors.muted)),
          ],
          if (tier > 0 && strength['estimatedMaxKg'] is num) ...[
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: DSColors.border)),
            _estimate(context, strength),
          ],
          if (tier > 0) ...[
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                  child: Text(copy(next?['title'] as String? ?? 'Elite'),
                      style: const TextStyle(fontSize: 12))),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(
                      next == null
                          ? copy('Highest reference level')
                          : '${progressValue(context, next['estimatedMaxKg'])} kg',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontSize: 12, color: DSColors.muted))),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    color: accent,
                    backgroundColor: DSColors.bgRaised)),
          ],
        ]),
      ),
      const SizedBox(height: 24),
      Text(copy('Strength badges'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      ProgressSurface(
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(builder: (context, constraints) {
          final columns = MediaQuery.textScalerOf(context).scale(12) > 16
              ? 1
              : constraints.maxWidth < 260
                  ? 2
                  : 3;
          final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
          return Wrap(spacing: 8, runSpacing: 4, children: [
            for (final badge in shownBadges) _badge(context, badge, width),
          ]);
        }),
      ),
      const SizedBox(height: 16),
      Text(
          copy(
              'A reference level, not a workout target. Follow the sets and loads in your plan.'),
          style: const TextStyle(
              fontSize: 12, color: DSColors.muted, height: 1.5)),
    ]);
  }
}

class ExerciseRankBadge extends StatelessWidget {
  final int tier;
  final double size;
  final bool earned;
  const ExerciseRankBadge(
      {super.key,
      required this.tier,
      required this.size,
      required this.earned});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
          child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _BadgePainter(tier, earned)),
      ));
}

class _BadgePainter extends CustomPainter {
  final int tier;
  final bool earned;
  const _BadgePainter(this.tier, this.earned);

  Path _polygon(double x, double y, double radius) {
    final path = Path();
    for (var index = 0; index < 6; index++) {
      final angle = -math.pi / 2 + index * math.pi / 3;
      final point =
          Offset(x + math.cos(angle) * radius, y + math.sin(angle) * radius);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final accent = earned
        ? FitnessAccents.rank(tier)
        : Color.lerp(FitnessAccents.rank(tier), const Color(0xFF62666D), .65)!;
    final light = Color.lerp(accent, Colors.white, .55)!;
    final dark = Color.lerp(accent, Colors.black, .65)!;
    if (earned) {
      canvas.drawCircle(
          const Offset(50, 47),
          31,
          Paint()
            ..color = accent.withValues(alpha: .16)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11));
    }
    for (final left in [true, false]) {
      canvas.save();
      if (!left) {
        canvas.translate(100, 0);
        canvas.scale(-1, 1);
      }
      final ribbon = Path()
        ..moveTo(35, 65)
        ..lineTo(22, 86)
        ..lineTo(34, 83)
        ..lineTo(38, 94)
        ..lineTo(49, 72)
        ..close();
      canvas.drawPath(ribbon, Paint()..color = dark);
      canvas.drawLine(
          const Offset(35, 76),
          const Offset(31, 84),
          Paint()
            ..color = accent
            ..strokeWidth = 1.2);
      if (tier >= 2) {
        final wing = Path()
          ..moveTo(32, 35)
          ..lineTo(5, 30)
          ..lineTo(13, 44)
          ..lineTo(27, 51)
          ..lineTo(13, 48)
          ..lineTo(21, 61)
          ..lineTo(35, 63)
          ..close();
        canvas.drawPath(
            wing,
            Paint()
              ..shader = LinearGradient(colors: [dark, accent])
                  .createShader(const Rect.fromLTWH(5, 30, 30, 34)));
        canvas.drawLine(
            const Offset(12, 36),
            const Offset(30, 43),
            Paint()
              ..color = light.withValues(alpha: .35)
              ..strokeWidth = .8);
      }
      canvas.restore();
    }
    final shield = _polygon(50, 45, 37);
    canvas.drawPath(
        shield,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [light, accent, dark, accent])
              .createShader(const Rect.fromLTWH(15, 8, 70, 74)));
    canvas.drawPath(
        shield,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = light);
    final inset = _polygon(50, 45, 31);
    canvas.drawPath(
        inset,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [dark, Color.lerp(accent, Colors.black, .15)!, dark])
              .createShader(const Rect.fromLTWH(20, 14, 60, 64)));
    canvas.drawPath(
        inset,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..color = light.withValues(alpha: .7));
    final crystal = _polygon(50, 42, 21);
    canvas.drawPath(
        crystal,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [light, accent, dark])
              .createShader(const Rect.fromLTWH(29, 21, 42, 42)));
    canvas.drawPath(
        crystal,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..color = light);
    canvas.drawPath(
        Path()
          ..moveTo(50, 21)
          ..lineTo(50, 62)
          ..lineTo(32, 51)
          ..lineTo(32, 32)
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: earned ? .09 : .035));
    final mark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = light;
    for (var index = 0; index < tier.clamp(1, 5); index++) {
      final y = 62.0 + index * 4;
      canvas.drawPath(
          Path()
            ..moveTo(44, y + 3)
            ..lineTo(50, y)
            ..lineTo(56, y + 3),
          mark);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BadgePainter old) =>
      old.tier != tier || old.earned != earned;
}
