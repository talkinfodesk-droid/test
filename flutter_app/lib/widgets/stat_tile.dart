import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "1200 kg / Total Volume" style stat. [big] renders the value at the large
/// size used for the rep counter in the middle of the row.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.unit,
    this.big = false,
    this.leading,
    this.trailing,
  });

  final String value;
  final String label;
  final String? unit;
  final bool big;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final valueStyle = big
        ? Theme.of(context).textTheme.headlineLarge
        : Theme.of(context).textTheme.headlineMedium;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) leading! else const SizedBox(height: 18),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: valueStyle),
            if (unit != null) ...[
              const SizedBox(width: 6),
              Text(
                unit!,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
          ],
        ),
      ],
    );
  }
}
