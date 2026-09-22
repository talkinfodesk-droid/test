import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tall bar per rep: grey gradient for past reps, green for the latest one,
/// and an empty dark column for reps still to come.
class VelocityBarChart extends StatelessWidget {
  const VelocityBarChart({
    super.key,
    required this.velocities,
    required this.slots,
    this.maxVelocity = 0.8,
    this.height = 180,
  });

  final List<double> velocities;
  final int slots;
  final double maxVelocity;
  final double height;

  @override
  Widget build(BuildContext context) {
    final count = slots < velocities.length ? velocities.length : slots;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < count; i++) ...[
            Expanded(
              child: _Bar(
                fraction: i < velocities.length
                    ? (velocities[i] / maxVelocity).clamp(0.05, 1.0)
                    : 0,
                isLatest: i == velocities.length - 1,
                height: height,
              ),
            ),
            if (i != count - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.isLatest,
    required this.height,
  });

  final double fraction;
  final bool isLatest;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: height,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          height: height * fraction,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLatest
                  ? const [AppColors.green, Color(0xFF0E4D22)]
                  : const [Color(0xFFE6E8EB), Color(0xFF3A3F46)],
            ),
          ),
          child: fraction > 0
              ? Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isLatest ? AppColors.green : Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
