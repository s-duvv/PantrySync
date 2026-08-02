import 'package:flutter_test/flutter_test.dart';
import 'package:pantrysync/models/grocery_item.dart';
import 'package:pantrysync/models/consumption_log.dart';
import 'package:pantrysync/models/household.dart';

void main() {
  group('Data Models Serialization & Logic Tests', () {
    test('GroceryItem fromJson and toJson roundtrip', () {
      final json = {
        'id': 'item-101',
        'household_id': 'house-1',
        'name': 'Organic Eggs',
        'category': 'Dairy',
        'status': 'IN_STOCK',
        'unit': 'boxes',
        'quantity': 2.0,
        'predicted_out_date': '2026-08-10',
        'last_restocked_at': '2026-08-01T12:00:00.000Z',
        'created_at': '2026-07-01T10:00:00.000Z',
        'updated_at': '2026-08-01T12:00:00.000Z',
      };

      final item = GroceryItem.fromJson(json);
      expect(item.id, equals('item-101'));
      expect(item.name, equals('Organic Eggs'));
      expect(item.status, equals(ItemStatus.IN_STOCK));
      expect(item.unit, equals('boxes'));
      expect(item.quantity, equals(2.0));

      final serialized = item.toJson();
      expect(serialized['household_id'], equals('house-1'));
      expect(serialized['status'], equals('IN_STOCK'));
      expect(serialized['predicted_out_date'], equals('2026-08-10'));
    });

    test('ConsumptionLog serialization', () {
      final json = {
        'id': 'log-1',
        'item_id': 'item-101',
        'action': 'RESTOCKED',
        'created_at': '2026-08-01T12:00:00.000Z',
      };

      final log = ConsumptionLog.fromJson(json);
      expect(log.action, equals(LogAction.RESTOCKED));
      expect(log.itemId, equals('item-101'));

      final res = log.toJson();
      expect(res['action'], equals('RESTOCKED'));
    });

    test('UserProfile & Household models', () {
      final houseJson = {
        'id': 'h1',
        'name': 'Smith Household',
        'created_at': '2026-01-01T00:00:00.000Z',
      };
      final house = Household.fromJson(houseJson);
      expect(house.name, equals('Smith Household'));

      final profileJson = {
        'id': 'u1',
        'household_id': 'h1',
        'display_name': 'Mom',
        'role': 'admin',
        'updated_at': '2026-01-01T00:00:00.000Z',
      };
      final profile = UserProfile.fromJson(profileJson);
      expect(profile.displayName, equals('Mom'));
      expect(profile.role, equals('admin'));
    });
  });
}
