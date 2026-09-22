import 'package:flutter/material.dart';

import '../models/workout_models.dart';
import '../theme/app_theme.dart';

/// Header row above the set list: "kg  reps  GPE".
class SetTableHeader extends StatelessWidget {
  const SetTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13, color: AppColors.textSecondary);
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          SizedBox(width: 56),
          Expanded(child: Center(child: Text('kg', style: style))),
          SizedBox(width: 20),
          Expanded(child: Center(child: Text('reps', style: style))),
          SizedBox(width: 20),
          Expanded(
            child: Center(
              child: Text(
                'GPE',
                style: TextStyle(fontSize: 13, color: AppColors.purple),
              ),
            ),
          ),
          SizedBox(width: 52),
        ],
      ),
    );
  }
}

/// One "60 × 8 × 1.1 ✓" row. Completed rows glow green, the active row is
/// outlined, and pending rows are dimmed.
class SetRow extends StatelessWidget {
  const SetRow({
    super.key,
    required this.set,
    required this.isActive,
    this.onTap,
  });

  final WorkoutSet set;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done = set.completed;
    final fg = done ? AppColors.textPrimary : AppColors.textSecondary;
    final bg = done
        ? AppColors.greenRow
        : isActive
            ? AppColors.card
            : AppColors.surface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive && !done
                    ? AppColors.textMuted
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                _NumberBadge(number: set.index, done: done),
                const SizedBox(width: 14),
                Expanded(
                  child: Center(
                    child: Text(
                      _fmtWeight(set.weightKg),
                      style: TextStyle(fontSize: 16, color: fg),
                    ),
                  ),
                ),
                _Times(done: done),
                Expanded(
                  child: Center(
                    child: Text(
                      '${done ? set.reps : set.targetReps}',
                      style: TextStyle(fontSize: 16, color: fg),
                    ),
                  ),
                ),
                _Times(done: done),
                Expanded(
                  child: Center(
                    child: done
                        ? Text(
                            set.gpe?.toStringAsFixed(1) ?? '-',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : Container(
                            width: 22,
                            height: 10,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                _CheckBadge(done: done),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _fmtWeight(double kg) =>
      kg == kg.roundToDouble() ? kg.toInt().toString() : kg.toStringAsFixed(1);
}

class _Times extends StatelessWidget {
  const _Times({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.close,
      size: 14,
      color: done ? AppColors.green : AppColors.textMuted,
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number, required this.done});

  final int number;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.green : AppColors.cardRaised,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: done ? Colors.black : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.green : Colors.transparent,
        border: Border.all(
          color: done ? AppColors.green : AppColors.textMuted,
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.check,
        size: 18,
        color: done ? Colors.black : AppColors.textMuted,
      ),
    );
  }
}
