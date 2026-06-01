import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/preferences_helper.dart';
import '../models/progress_log.dart';
import '../models/challenge.dart';

class ProgressProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PreferencesHelper _prefsHelper = PreferencesHelper();

  int? _currentUserId;
  List<ProgressLog> _logs = [];
  List<Challenge> _challenges = [];
  bool _isLoading = false;

  double _fontSize = 14.0;
  String _viewMode = 'List';

  int? get currentUserId => _currentUserId;
  List<ProgressLog> get logs => _logs;
  List<Challenge> get challenges => _challenges;
  bool get isLoading => _isLoading;
  double get fontSize => _fontSize;
  String get viewMode => _viewMode;

  double get progressLogProgress {
    double progress = 0.3;
    if (_challenges.isNotEmpty) {
      final completed = _challenges.where((c) => c.isCompleted == 1).length;
      progress += (completed / _challenges.length) * 0.65;
    } else if (_logs.isNotEmpty) {
      progress += (_logs.length * 0.05);
    }
    return progress.clamp(0.15, 0.95);
  }

  Future<void> setUserId(int? userId) async {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

    if (userId == null) {
      _logs = [];
      _challenges = [];
      notifyListeners();
    } else {
      _setLoading(true);
      try {
        await refreshData();
      } catch (e) {
        debugPrint('Error memuat data progress user: $e');
      } finally {
        _setLoading(false);
      }
    }
  }

  Future<void> loadInitialData() async {
    _setLoading(true);
    try {
      _fontSize = await _prefsHelper.getFontSize();
      _viewMode = await _prefsHelper.getViewMode();
      await refreshData();
    } catch (e) {
      debugPrint('Error saat memuat data awal progress: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> refreshData() async {
    if (_currentUserId == null) return;
    _logs = await _dbHelper.getAllProgressLogs(_currentUserId);
    _challenges = await _dbHelper.getAllChallenges(_currentUserId);
    notifyListeners();
  }

  // ==========================================
  // PROGRESS LOGS CRUD
  // ==========================================
  Future<void> addProgressLog({
    int? skillId,
    required String title,
    String note = '',
    int durationMinutes = 0,
    required DateTime date,
  }) async {
    final newLog = ProgressLog(
      userId: _currentUserId,
      skillId: skillId,
      title: title,
      note: note,
      durationMinutes: durationMinutes,
      date: date,
    );
    await _dbHelper.insertProgressLog(newLog);
    await refreshData();
  }

  Future<void> updateProgressLog(ProgressLog log) async {
    await _dbHelper.updateProgressLog(log);
    await refreshData();
  }

  Future<void> deleteProgressLog(int id) async {
    await _dbHelper.deleteProgressLog(id);
    await refreshData();
  }

  // ==========================================
  // CHALLENGES CRUD
  // ==========================================
  Future<void> addChallenge({
    int? skillId,
    required String title,
    String description = '',
    required DateTime targetDate,
  }) async {
    final newChallenge = Challenge(
      userId: _currentUserId,
      skillId: skillId,
      title: title,
      description: description,
      targetDate: targetDate,
    );
    await _dbHelper.insertChallenge(newChallenge);
    await refreshData();
  }

  Future<void> updateChallenge(Challenge challenge) async {
    await _dbHelper.updateChallenge(challenge);
    await refreshData();
  }

  Future<void> deleteChallenge(int id) async {
    await _dbHelper.deleteChallenge(id);
    await refreshData();
  }

  // ==========================================
  // PREFERENCES
  // ==========================================
  Future<void> updateFontSize(double size) async {
    _fontSize = size;
    notifyListeners();
    await _prefsHelper.setFontSize(size);
  }

  Future<void> updateViewMode(String mode) async {
    _viewMode = mode;
    notifyListeners();
    await _prefsHelper.setViewMode(mode);
  }
}
