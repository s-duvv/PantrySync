import '../models/consumption_log.dart';

class PredictionService {
  /// Calculates the predicted next depletion date based on consumption log history.
  /// Matches the Python moving average algorithm:
  /// - Iterates through log entries sorted ascending by date
  /// - Measures interval (in days) between RESTOCKED and EMPTIED events
  /// - Computes average interval duration
  /// - Adds average interval duration to latest RESTOCKED date
  /// - Defaults to 7 days if insufficient log history exists
  static DateTime calculateNextDepletion(List<ConsumptionLog> historyLogs) {
    if (historyLogs.isEmpty) {
      return DateTime.now().add(const Duration(days: 7));
    }

    // Sort logs ascending by timestamp
    final sortedLogs = List<ConsumptionLog>.from(historyLogs)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final List<double> intervalsInDays = [];
    DateTime? lastRestock;

    for (final log in sortedLogs) {
      if (log.action == LogAction.RESTOCKED) {
        lastRestock = log.createdAt;
      } else if (log.action == LogAction.EMPTIED && lastRestock != null) {
        final daysTaken = log.createdAt.difference(lastRestock).inHours / 24.0;
        if (daysTaken > 0) {
          intervalsInDays.add(daysTaken);
        }
        lastRestock = null;
      }
    }

    if (intervalsInDays.isEmpty) {
      return DateTime.now().add(const Duration(days: 7));
    }

    final double avgDays =
        intervalsInDays.reduce((a, b) => a + b) / intervalsInDays.length;

    // Find latest restock date
    final restockLogs = sortedLogs.where((l) => l.action == LogAction.RESTOCKED);
    final latestRestockDate = restockLogs.isNotEmpty
        ? restockLogs.last.createdAt
        : DateTime.now();

    final int daysToAdd = avgDays.round();
    return latestRestockDate.add(Duration(days: daysToAdd > 0 ? daysToAdd : 7));
  }

  /// Calculates remaining days until predicted depletion from today
  static int getDaysRemaining(DateTime? predictedDate) {
    if (predictedDate == null) return 7;
    final difference = predictedDate.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }

  /// Evaluates whether an item should be suggested for restock
  static bool isRestockSuggested(DateTime? predictedDate) {
    if (predictedDate == null) return false;
    final remainingDays = getDaysRemaining(predictedDate);
    return remainingDays <= 2;
  }
}
