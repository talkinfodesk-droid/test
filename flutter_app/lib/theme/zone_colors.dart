import 'package:flutter/material.dart';

import '../models/workout_models.dart';
import 'app_theme.dart';

/// One colour per effort zone, shared by the chart and the session list.
extension GpeZoneColor on GpeZone {
  Color get color => switch (this) {
        GpeZone.tooEasy || GpeZone.overdo => AppColors.red,
        GpeZone.light => AppColors.yellow,
        GpeZone.optimal => AppColors.green,
        GpeZone.heavy => AppColors.orange,
      };
}
