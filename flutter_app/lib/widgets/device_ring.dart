import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The small circular sensor badge in the top bar: a green ring while the bar
/// sensor is connected, grey when it is not.
class DeviceRing extends StatelessWidget {
  const DeviceRing({super.key, required this.connected, this.size = 40});

  final bool connected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.green : AppColors.textMuted;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: connected ? 0.8 : 1,
              strokeWidth: 3,
              color: color,
              backgroundColor: AppColors.cardRaised,
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: size * 0.42,
            height: size * 0.56,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Center(
              child:
                  Icon(Icons.fitness_center, size: size * 0.28, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
