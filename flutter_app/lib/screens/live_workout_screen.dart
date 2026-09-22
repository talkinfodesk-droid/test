import 'package:flutter/material.dart';

import '../models/workout_models.dart';
import '../state/app_scope.dart';
import '../state/live_workout_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/device_ring.dart';
import '../widgets/rep_velocity_strip.dart';
import '../widgets/set_editor_sheet.dart';
import '../widgets/set_row.dart';
import '../widgets/set_tabs.dart';
import '../widgets/stat_tile.dart';
import '../widgets/velocity_bar_chart.dart';

/// The live tracking screen from the recording: session clock and sensor
/// badge on top, the set table, then a draggable sheet with the live set
/// (tabs, volume / reps / mean velocity, per-rep velocities and bars).
class LiveWorkoutScreen extends StatefulWidget {
  const LiveWorkoutScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  late final LiveWorkoutController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LiveWorkoutController(exercise: widget.exercise);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _editSet(int index) async {
    final c = _controller;
    final edit = await showSetEditorSheet(
      context,
      set: c.exercise.sets[index],
      canDelete: c.canRemoveSet(index),
    );
    if (edit == null) return;
    if (edit.delete) {
      c.removeSet(index);
    } else {
      c.updateSet(index, weightKg: edit.weightKg, targetReps: edit.targetReps);
    }
  }

  /// Persist the session and leave the screen.
  Future<void> _finishWorkout() async {
    final c = _controller;
    final repo = AppScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (c.completedSets == 0) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Nothing logged yet'),
          content: const Text('Leave without saving this workout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (leave == true) navigator.pop();
      return;
    }

    final session = await repo.saveExercise(c.exercise);
    if (!mounted) return;
    if (session != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Saved: ${c.completedSets} sets, GPE ${session.gpeMean.toStringAsFixed(1)}, '
            '${session.powerMean.round()} W',
          ),
        ),
      );
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final c = _controller;
            final exercise = c.exercise;
            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(controller: c, onFinish: _finishWorkout),
                    _ExerciseHeader(
                      exercise: exercise,
                      onEdit: () => _editSet(c.currentSetIndex),
                    ),
                    const SetTableHeader(),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          for (var i = 0; i < exercise.sets.length; i++)
                            SetRow(
                              set: exercise.sets[i],
                              isActive: i == c.currentSetIndex,
                              onTap: () => c.selectSet(i),
                              onLongPress: () => _editSet(i),
                            ),
                          _AddSetButton(onTap: c.addSet),
                          // Keep the last rows reachable above the sheet.
                          const SizedBox(height: 420),
                        ],
                      ),
                    ),
                  ],
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.58,
                  minChildSize: 0.38,
                  maxChildSize: 0.92,
                  builder: (context, scrollController) {
                    return _LiveSheet(
                      controller: c,
                      scrollController: scrollController,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, required this.onFinish});

  final LiveWorkoutController controller;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _Pill(
            child: Row(
              children: [
                const Icon(Icons.schedule,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  formatClock(controller.elapsed),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.keyboard_arrow_up,
                color: AppColors.textSecondary),
          ),
          GestureDetector(
            onTap: controller.toggleSensor,
            child: DeviceRing(connected: controller.sensorConnected),
          ),
          const SizedBox(width: 8),
          _Pill(
            padding: const EdgeInsets.all(10),
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              color: AppColors.card,
              icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
              onSelected: (v) {
                if (v == 'finish') onFinish();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'finish', child: Text('Finish workout')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({required this.exercise, required this.onEdit});

  final Exercise exercise;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.accessibility_new,
                color: AppColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  '${exercise.setCount} sets',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.visibility_outlined, color: AppColors.textPrimary),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Edit current set',
            onPressed: onEdit,
            icon: const Icon(Icons.tune, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _LiveSheet extends StatelessWidget {
  const _LiveSheet({required this.controller, required this.scrollController});

  final LiveWorkoutController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final set = c.currentSet;
    final velocities = set.repVelocities;
    final slots = set.targetReps < 8 ? 8 : set.targetReps;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Colors.black54, blurRadius: 24, offset: Offset(0, -6))
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            value: c.isCapturing ? null : 0.75,
                            strokeWidth: 3,
                            color: AppColors.green,
                            backgroundColor: AppColors.cardRaised,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            c.exercise.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Set ${set.index}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        '${set.reps}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.repeat,
                          size: 18, color: AppColors.textPrimary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatClock(c.setElapsed, hours: false),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(width: 14),
              _CompleteButton(controller: c),
            ],
          ),
          const SizedBox(height: 18),
          SetTabs(
            count: c.exercise.sets.length,
            selected: c.currentSetIndex,
            completed: {
              for (var i = 0; i < c.exercise.sets.length; i++)
                if (c.exercise.sets[i].completed) i,
            },
            onSelected: c.selectSet,
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: StatTile(
                  value: _fmtKg(c.totalVolumeKg),
                  unit: 'kg',
                  label: 'Total Volume',
                ),
              ),
              Expanded(
                child: StatTile(
                  value: '${set.reps}',
                  label: 'Reps',
                  big: true,
                  trailing: const Icon(Icons.expand_more,
                      size: 18, color: AppColors.red),
                ),
              ),
              Expanded(
                child: StatTile(
                  value: set.meanVelocity.toStringAsFixed(2),
                  unit: 'm/s',
                  label: 'Mean V',
                  leading: const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.repeat,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          RepVelocityStrip(velocities: velocities, slots: slots),
          const SizedBox(height: 18),
          VelocityBarChart(velocities: velocities, slots: slots),
          const SizedBox(height: 20),
          _CaptureControls(controller: c),
        ],
      ),
    );
  }

  static String _fmtKg(double kg) =>
      kg == kg.roundToDouble() ? kg.toInt().toString() : kg.toStringAsFixed(1);
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({required this.controller});

  final LiveWorkoutController controller;

  @override
  Widget build(BuildContext context) {
    final set = controller.currentSet;
    final enabled = !set.completed && set.reps > 0;
    return Material(
      color: set.completed ? AppColors.green : AppColors.card,
      shape: CircleBorder(
        side: BorderSide(
            color: set.completed ? AppColors.green : AppColors.divider,
            width: 2),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? controller.completeCurrentSet : null,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Icon(
            Icons.check,
            size: 28,
            color: set.completed
                ? Colors.black
                : enabled
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Demo-only controls: the real product gets reps from the bar sensor, so
/// here you can either stream simulated reps or tap them in one by one.
class _CaptureControls extends StatelessWidget {
  const _CaptureControls({required this.controller});

  final LiveWorkoutController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final set = c.currentSet;
    if (set.completed) {
      return Center(
        child: Text(
          c.allSetsDone
              ? 'All sets done. Great work!'
              : 'Set ${set.index} logged',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: c.isCapturing ? AppColors.card : AppColors.green,
              foregroundColor:
                  c.isCapturing ? AppColors.textPrimary : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed:
                c.sensorConnected && !c.isCapturing ? c.startCapture : null,
            icon: Icon(c.isCapturing ? Icons.sensors : Icons.play_arrow),
            label: Text(c.isCapturing ? 'Listening to sensor…' : 'Start set'),
          ),
        ),
        const SizedBox(width: 10),
        _RoundIcon(icon: Icons.add, onTap: c.addRep, tooltip: 'Log rep'),
        const SizedBox(width: 10),
        _RoundIcon(icon: Icons.undo, onTap: c.undoRep, tooltip: 'Undo rep'),
      ],
    );
  }
}

class _AddSetButton extends StatelessWidget {
  const _AddSetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.divider),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        icon: const Icon(Icons.add),
        label: const Text('Add set'),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon(
      {required this.icon, required this.onTap, required this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}
