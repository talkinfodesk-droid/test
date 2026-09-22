import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Set 1 / Set 2 / Set 3" chips; the active one is outlined in green with a
/// small live dot.
class SetTabs extends StatelessWidget {
  const SetTabs({
    super.key,
    required this.count,
    required this.selected,
    required this.onSelected,
    this.completed = const <int>{},
  });

  final int count;
  final int selected;
  final Set<int> completed;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final active = i == selected;
          final done = completed.contains(i);
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active ? AppColors.greenDim : AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? AppColors.green : Colors.transparent,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  if (active) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'Set ${i + 1}',
                    style: TextStyle(
                      fontSize: 15,
                      color: active
                          ? AppColors.textPrimary
                          : done
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
