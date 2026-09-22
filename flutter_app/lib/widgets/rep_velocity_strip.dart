import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The per-rep readout under the stats: a segmented progress bar (one segment
/// per target rep, green once the rep is in) and the velocity value of every
/// rep. The most recent rep gets a green dot.
class RepVelocityStrip extends StatelessWidget {
  const RepVelocityStrip({
    super.key,
    required this.velocities,
    required this.slots,
  });

  final List<double> velocities;
  final int slots;

  @override
  Widget build(BuildContext context) {
    final count = slots < velocities.length ? velocities.length : slots;
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < count; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < velocities.length
                        ? AppColors.green
                        : AppColors.cardRaised,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (i != count - 1) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < count; i++)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == velocities.length - 1
                            ? AppColors.green
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        i < velocities.length
                            ? velocities[i].toStringAsFixed(2)
                            : '0.0',
                        style: TextStyle(
                          fontSize: 13,
                          color: i < velocities.length
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
