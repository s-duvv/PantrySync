import 'package:flutter_test/flutter_test.dart';
import 'package:pantrysync/models/consumption_log.dart';
import 'package:pantrysync/services/prediction_service.dart';

void main() {
  group('PredictionService Unit Tests', () {
    test('calculateNextDepletion returns +7 days default for empty logs', () {
      final logs = <ConsumptionLog>[];
      final predicted = PredictionService.calculateNextDepletion(logs);
      final now = DateTime.now();

      expect(predicted.isAfter(now), isTrue);
      expect(predicted.difference(now).inDays, closeTo(7, 1));
    });

    test('calculateNextDepletion correctly averages interval durations', () {
      final now = DateTime.now();
      final logs = [
        ConsumptionLog(
          id: '1',
          itemId: 'item-1',
          action: LogAction.RESTOCKED,
          createdAt: now.subtract(const Duration(days: 20)),
        ),
        ConsumptionLog(
          id: '2',
          itemId: 'item-1',
          action: LogAction.EMPTIED,
          createdAt: now.subtract(const Duration(days: 15)), // 5 days interval
        ),
        ConsumptionLog(
          id: '3',
          itemId: 'item-1',
          action: LogAction.RESTOCKED,
          createdAt: now.subtract(const Duration(days: 10)),
        ),
        ConsumptionLog(
          id: '4',
          itemId: 'item-1',
          action: LogAction.EMPTIED,
          createdAt: now.subtract(const Duration(days: 5)), // 5 days interval
        ),
        ConsumptionLog(
          id: '5',
          itemId: 'item-1',
          action: LogAction.RESTOCKED,
          createdAt: now.subtract(const Duration(days: 1)), // Latest restock
        ),
      ];

      final predicted = PredictionService.calculateNextDepletion(logs);
      // Latest restock (now-1) + 5 days avg = now + 4 days
      final daysFromNow = predicted.difference(now).inDays;
      expect(daysFromNow, closeTo(4, 1));
    });

    test('isRestockSuggested returns true when <= 2 days remaining', () {
      final soonDate = DateTime.now().add(const Duration(days: 1));
      final farDate = DateTime.now().add(const Duration(days: 10));

      expect(PredictionService.isRestockSuggested(soonDate), isTrue);
      expect(PredictionService.isRestockSuggested(farDate), isFalse);
    });
  });
}
