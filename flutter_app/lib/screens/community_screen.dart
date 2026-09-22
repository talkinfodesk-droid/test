import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Community tab placeholder: a short feed of recent lifts from other users.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  static const _posts = [
    ('alex_k', 'Bench press', '100 kg × 5 · mean 0.42 m/s'),
    ('muscles', 'Machine pulldown', '60 kg × 8 · GPE 1.1'),
    ('jin.lift', 'Back squat', '140 kg × 3 · mean 0.35 m/s'),
    ('sara.p', 'Dumbbell row', '32 kg × 10 · GPE 0.9'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (user, exercise, detail) = _posts[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.cardRaised,
                  child: Text(
                    user[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text('$exercise · $detail',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.favorite_border,
                    color: AppColors.textSecondary),
              ],
            ),
          );
        },
      ),
    );
  }
}
