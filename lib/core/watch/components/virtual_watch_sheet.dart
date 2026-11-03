import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/ds_colors.dart';
import '../watch_models.dart';
import '../watch_sync_service.dart';

class VirtualWatchSheet extends StatefulWidget {
  final WatchWorkoutSnapshot snapshot;
  final WatchRestPayload? rest;

  const VirtualWatchSheet({
    super.key,
    required this.snapshot,
    this.rest,
  });

  static Future<void> show(BuildContext context) {
    final service = WatchSyncService.shared;
    final snapshot = service.latestSnapshot;
    if (snapshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active workout session found to mirror.')),
      );
      return Future.value();
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VirtualWatchSheet(
        snapshot: snapshot,
        rest: service.latestRest,
      ),
    );
  }

  @override
  State<VirtualWatchSheet> createState() => _VirtualWatchSheetState();
}

class _VirtualWatchSheetState extends State<VirtualWatchSheet> {
  final _service = WatchSyncService.shared;
  late WatchWorkoutSnapshot _snapshot;
  WatchRestPayload? _rest;
  StreamSubscription? _syncSub;

  int _selectedTab = 0; // 0: Workout, 1: Exercise List, 2: Heart Rate / Telemetry
  double _mockHeartRate = 138.0;
  final double _mockCalories = 184.0;
  int _crownRepsDelta = 0;
  double _crownWeightDelta = 0.0;
  Timer? _restTimer;
  int _restRemaining = 0;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.snapshot;
    _rest = widget.rest;
    _initRestCountdown();

    _service.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    setState(() {
      if (_service.latestSnapshot != null) {
        _snapshot = _service.latestSnapshot!;
      }
      _rest = _service.latestRest;
      _initRestCountdown();
    });
  }

  void _initRestCountdown() {
    _restTimer?.cancel();
    if (_rest != null && _rest!.isActive && !_rest!.isPaused) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = ((_rest!.endTimeEpochMs - now) / 1000).ceil();
      _restRemaining = remaining > 0 ? remaining : 0;

      _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_restRemaining > 0) {
            _restRemaining--;
          } else {
            timer.cancel();
          }
        });
      });
    } else {
      _restRemaining = 0;
    }
  }

  void _dispatchBiometrics() {
    final hr = _mockHeartRate.round();
    final zone = hr < 110
        ? 1
        : hr < 135
            ? 2
            : hr < 155
                ? 3
                : hr < 172
                    ? 4
                    : 5;

    _service.dispatchVirtualAction(
      WatchBiometricUpdateAction(
        biometrics: WatchBiometrics(
          heartRate: hr,
          hrZone: zone,
          activeCalories: _mockCalories,
          elapsedSeconds: 1200,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _restTimer?.cancel();
    _syncSub?.cancel();
    super.dispose();
  }

  WatchExerciseItem? get _currentExercise {
    if (_snapshot.items.isEmpty) return null;
    final index = _snapshot.activeItemIndex.clamp(0, _snapshot.items.length - 1);
    return _snapshot.items[index];
  }

  int get _nextSetNumber {
    final current = _currentExercise;
    if (current == null) return 1;
    final logged = current.loggedSets.map((e) => e.setNumber).toSet();
    for (int i = 1; i <= current.targetSets; i++) {
      if (!logged.contains(i)) return i;
    }
    return current.targetSets + 1;
  }

  void _logCurrentSet() {
    final item = _currentExercise;
    if (item == null) return;
    HapticFeedback.heavyImpact();

    final targetWeight = (item.targetWeight + _crownWeightDelta).clamp(0.0, 500.0);
    final targetRepsNum = int.tryParse(item.targetReps) ??
        int.tryParse(item.targetReps.split('-').first) ??
        10;
    final finalReps = (targetRepsNum + _crownRepsDelta).clamp(1, 100);

    _service.dispatchVirtualAction(
      WatchLogSetAction(
        itemId: item.id,
        setNumber: _nextSetNumber,
        weight: targetWeight,
        reps: finalReps,
      ),
    );

    setState(() {
      _crownRepsDelta = 0;
      _crownWeightDelta = 0.0;
    });
  }

  void _selectExercise(String itemId) {
    HapticFeedback.selectionClick();
    _service.dispatchVirtualAction(WatchSelectExerciseAction(itemId: itemId));
    setState(() => _selectedTab = 0);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF14171A),
            borderRadius: BorderRadius.circular(48),
            border: Border.all(color: const Color(0xFF4A4E54), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 36,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Digital Crown Mock (Right side)
              Positioned(
                right: -13,
                top: 50,
                child: Container(
                  width: 10,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E9297),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFF5A5E64)),
                  ),
                ),
              ),
              // Side button Mock
              Positioned(
                right: -10,
                top: 114,
                child: Container(
                  width: 7,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A5E64),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Apple Watch OLED Canvas
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildWatchHeader(),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 340,
                      child: _buildWatchBody(),
                    ),
                    const SizedBox(height: 8),
                    _buildBottomNavigationPill(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWatchHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Watch Time
        const Text(
          '9:41',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        // Live Heart Rate Indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.heart_fill, color: DSColors.heat, size: 12),
            const SizedBox(width: 3),
            Text(
              '${_mockHeartRate.round()}',
              style: const TextStyle(
                color: DSColors.heat,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Paired indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: DSColors.accentLime.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'MOCK WATCH',
            style: TextStyle(
              color: DSColors.accentLime,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWatchBody() {
    // If rest is currently active, prioritize Rest View
    if (_restRemaining > 0 && _selectedTab == 0) {
      return _buildRestTimerView();
    }

    return switch (_selectedTab) {
      0 => _buildActiveExerciseView(),
      1 => _buildExerciseListView(),
      2 => _buildTelemetrySimulatorView(),
      _ => _buildActiveExerciseView(),
    };
  }

  Widget _buildActiveExerciseView() {
    final item = _currentExercise;
    if (item == null) {
      return const Center(
        child: Text('Workout Finished', style: TextStyle(color: Colors.white70)),
      );
    }

    final targetWeight = (item.targetWeight + _crownWeightDelta).clamp(0.0, 500.0);
    final targetRepsNum = int.tryParse(item.targetReps) ??
        int.tryParse(item.targetReps.split('-').first) ??
        10;
    final finalReps = (targetRepsNum + _crownRepsDelta).clamp(1, 100);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Exercise Name & Order Index
          Text(
            '${_snapshot.activeItemIndex + 1}/${_snapshot.items.length} ${item.exerciseName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'SET $_nextSetNumber OF ${item.targetSets}',
            style: const TextStyle(
              color: DSColors.silver,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Reps & Weight Tuning Cards
          Row(
            children: [
              // Reps
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262A30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'REPS',
                        style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _crownRepsDelta--),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.remove, size: 14, color: Colors.white70),
                            ),
                          ),
                          Text(
                            '$finalReps',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _crownRepsDelta++),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.add, size: 14, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Weight
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262A30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'KG',
                        style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _crownWeightDelta -= 2.5),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.remove, size: 14, color: Colors.white70),
                            ),
                          ),
                          Text(
                            targetWeight.toStringAsFixed(targetWeight % 1 == 0 ? 0 : 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _crownWeightDelta += 2.5),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.add, size: 14, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Primary Big Button: LOG SET
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: DSColors.accentLime,
            borderRadius: BorderRadius.circular(20),
            onPressed: _logCurrentSet,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.checkmark_alt, color: Colors.black, size: 18),
                const SizedBox(width: 6),
                Text(
                  'LOG SET $_nextSetNumber',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Quick Skip / Complete Exercise
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 4,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _service.dispatchVirtualAction(WatchSkipExerciseAction(itemId: item.id));
                },
                child: const Text(
                  'Skip Exercise',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: const Text(
                  'Switch Exercise ›',
                  style: TextStyle(color: DSColors.blue, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerView() {
    final minutes = _restRemaining ~/ 60;
    final seconds = _restRemaining % 60;
    final formatted = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'REST INTERVAL',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        // Countdown Circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DSColors.ice, width: 4),
          ),
          child: Center(
            child: Text(
              formatted,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Controls: +30s and Skip
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFF262A30),
              borderRadius: BorderRadius.circular(16),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _restRemaining += 30);
                _service.dispatchVirtualAction(const WatchRestControlAction(operation: 'EXTEND'));
              },
              child: const Text('+30s', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: DSColors.accentLime,
              borderRadius: BorderRadius.circular(16),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _restRemaining = 0);
                _service.dispatchVirtualAction(const WatchRestControlAction(operation: 'SKIP'));
              },
              child: const Text('Skip', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExerciseListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'TAP TO SWITCH EXERCISE',
          style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: _snapshot.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (_, index) {
              final item = _snapshot.items[index];
              final isCurrent = index == _snapshot.activeItemIndex;
              final isDone = item.isCompleted;

              return InkWell(
                onTap: () => _selectExercise(item.id),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? DSColors.accentLime.withValues(alpha: 0.15)
                        : const Color(0xFF1F2328),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent ? DSColors.accentLime : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDone
                            ? CupertinoIcons.checkmark_circle_fill
                            : isCurrent
                                ? CupertinoIcons.play_circle_fill
                                : CupertinoIcons.circle,
                        size: 14,
                        color: isDone
                            ? DSColors.accentLime
                            : isCurrent
                                ? DSColors.ice
                                : Colors.white38,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.exerciseName,
                          style: TextStyle(
                            color: isDone ? Colors.white54 : Colors.white,
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.targetSets} sets',
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetrySimulatorView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'BIOMETRICS TELEMETRY SIMULATOR',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.heart_fill, color: DSColors.heat, size: 24),
            const SizedBox(width: 8),
            Text(
              '${_mockHeartRate.round()} BPM',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: DSColors.heat,
            thumbColor: Colors.white,
            trackHeight: 4,
          ),
          child: Slider(
            value: _mockHeartRate,
            min: 60,
            max: 190,
            onChanged: (val) {
              setState(() => _mockHeartRate = val);
              _dispatchBiometrics();
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Active Energy: ${_mockCalories.toStringAsFixed(1)} kcal',
            style: const TextStyle(color: DSColors.gold, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationPill() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTabIcon(0, CupertinoIcons.sportscourt_fill),
        const SizedBox(width: 14),
        _buildTabIcon(1, CupertinoIcons.list_bullet),
        const SizedBox(width: 14),
        _buildTabIcon(2, CupertinoIcons.waveform_path_ecg),
      ],
    );
  }

  Widget _buildTabIcon(int index, IconData icon) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTab = index);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? Colors.white24 : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? Colors.white : Colors.white38,
        ),
      ),
    );
  }
}

