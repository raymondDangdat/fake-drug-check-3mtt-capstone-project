import 'package:shared_preferences/shared_preferences.dart';
import '../models/drug_check_result.dart';

/// Service for persisting drug check history locally using SharedPreferences.
class HistoryService {
  static const String _historyKey = 'drug_check_history';
  static const int _maxHistory = 50;

  /// Save a new drug check result to history.
  Future<void> saveResult(DrugCheckResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.insert(0, result); // Newest first

    // Trim to max size
    final trimmed = history.length > _maxHistory
        ? history.sublist(0, _maxHistory)
        : history;

    final jsonList = trimmed.map((r) => r.toJsonString()).toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  /// Retrieve all saved drug check results, newest first.
  Future<List<DrugCheckResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_historyKey) ?? [];

    return jsonList.map((json) {
      try {
        return DrugCheckResult.fromJsonString(json);
      } catch (_) {
        return null;
      }
    }).whereType<DrugCheckResult>().toList();
  }

  /// Query history by search string and prediction status filter.
  Future<List<DrugCheckResult>> queryHistory({
    String query = '',
    String? statusFilter, // 'All', 'Genuine', 'Suspicious'
  }) async {
    final all = await getHistory();
    return all.where((item) {
      final matchesQuery = query.isEmpty ||
          item.drugName.toLowerCase().contains(query.toLowerCase()) ||
          item.manufacturer.toLowerCase().contains(query.toLowerCase()) ||
          item.nafdacNumber.toLowerCase().contains(query.toLowerCase());

      final matchesStatus = statusFilter == null ||
          statusFilter == 'All' ||
          item.prediction == statusFilter;

      return matchesQuery && matchesStatus;
    }).toList();
  }

  /// Clear all history.
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Get the count of saved results.
  Future<int> getCount() async {
    final history = await getHistory();
    return history.length;
  }
}
