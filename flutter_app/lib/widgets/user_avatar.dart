import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Purple-on-plum avatar used in the Home and History headers.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.radius = 18});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.avatarBackground,
      child: Icon(Icons.person, size: radius * 1.1, color: AppColors.purple),
    );
  }
}
