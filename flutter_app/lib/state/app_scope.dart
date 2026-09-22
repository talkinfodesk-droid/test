import 'package:flutter/widgets.dart';

import '../data/workout_repository.dart';

/// Makes the app-wide repository available to every screen.
class AppScope extends InheritedNotifier<WorkoutRepository> {
  const AppScope({
    super.key,
    required WorkoutRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static WorkoutRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!.notifier!;
  }
}
