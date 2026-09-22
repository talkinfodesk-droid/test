import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_models.dart';
import 'mock_data.dart';

/// Persists finished sessions on-device (SharedPreferences as JSON).
///
/// Seeds the demo history on first launch so the charts are never empty.
/// Swap the storage calls for a Supabase/REST client to sync across devices.
class WorkoutRepository extends ChangeNotifier {
  WorkoutRepository({SharedPreferences? prefs}) : _prefs = prefs;

  static const _sessionsKey = 'sessions.v1';

  SharedPreferences? _prefs;
  List<TrainingSession> _sessions = const [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Sessions sorted oldest -> newest.
  List<TrainingSession> get sessions => List.unmodifiable(_sessions);

  TrainingSession? get latest => _sessions.isEmpty ? null : _sessions.last;

  Future<void> load() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint(
          'WorkoutRepository: storage unavailable, using in-memory ($e)');
      _sessions = MockData.sessions();
      _loaded = true;
      notifyListeners();
      return;
    }
    final raw = _prefs!.getString(_sessionsKey);
    List<TrainingSession>? stored;
    if (raw != null) {
      try {
        stored = (jsonDecode(raw) as List<dynamic>)
            .map((e) => TrainingSession.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
      } catch (e) {
        debugPrint('WorkoutRepository: discarding unreadable sessions ($e)');
      }
    }
    if (stored == null) {
      _sessions = MockData.sessions();
      await _persist();
    } else {
      _sessions = stored;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> addSession(TrainingSession session) async {
    _sessions = [..._sessions, session]
      ..sort((a, b) => a.date.compareTo(b.date));
    await _persist();
    notifyListeners();
  }

  /// Summarise and store a finished exercise. Returns null when nothing was
  /// logged (no completed sets).
  Future<TrainingSession?> saveExercise(Exercise exercise) async {
    final session = TrainingSession.fromExercise(exercise);
    if (session == null) return null;
    await addSession(session);
    return session;
  }

  Future<void> clear() async {
    _sessions = const [];
    await _prefs?.remove(_sessionsKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return; // in-memory fallback
    await prefs.setString(
      _sessionsKey,
      jsonEncode(_sessions.map((s) => s.toJson()).toList()),
    );
  }
}
