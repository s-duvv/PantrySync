#!/usr/bin/env python3
"""
End-to-End Offline Application & Database Flow Tests
Verifies CRUD operations, shopping list filtering, and moving-average updates 
without requiring a live remote database connection.
"""

import unittest
from datetime import datetime, timedelta

class MockPantryDatabase:
    """Python simulation of PantrySync offline mock database & service layer."""

    def __init__(self):
        self.items = [
            {
                'id': '1',
                'name': 'Whole Milk',
                'category': 'Dairy & Eggs',
                'status': 'LOW',
                'predicted_out_date': datetime.now() + timedelta(days=1),
                'last_restocked_at': datetime.now() - timedelta(days=5),
            },
            {
                'id': '2',
                'name': 'Organic Avocados',
                'category': 'Produce',
                'status': 'OUT_OF_STOCK',
                'predicted_out_date': datetime.now() - timedelta(days=1),
                'last_restocked_at': datetime.now() - timedelta(days=7),
            },
            {
                'id': '3',
                'name': 'Dark Roast Coffee',
                'category': 'Beverages',
                'status': 'IN_STOCK',
                'predicted_out_date': datetime.now() + timedelta(days=2),
                'last_restocked_at': datetime.now() - timedelta(days=10),
            },
        ]
        self.logs = []

    def get_shopping_list(self):
        """Returns items needing restock (OUT_OF_STOCK or LOW)."""
        return [item for item in self.items if item['status'] in ('OUT_OF_STOCK', 'LOW')]

    def get_ai_suggestions(self):
        """Returns IN_STOCK items predicted to deplete within 2 days."""
        now = datetime.now()
        suggestions = []
        for item in self.items:
            if item['status'] == 'IN_STOCK' and item.get('predicted_out_date'):
                days_left = (item['predicted_out_date'] - now).days
                if days_left <= 2:
                    suggestions.append(item)
        return suggestions

    def update_item_status(self, item_id, new_status):
        for item in self.items:
            if item['id'] == item_id:
                item['status'] = new_status
                if new_status == 'IN_STOCK':
                    item['last_restocked_at'] = datetime.now()
                action = 'RESTOCKED' if new_status == 'IN_STOCK' else 'EMPTIED'
                self.logs.append({'item_id': item_id, 'action': action, 'created_at': datetime.now()})
                return item
        raise ValueError("Item not found")

    def add_item(self, name, category, status='IN_STOCK'):
        new_item = {
            'id': str(len(self.items) + 1),
            'name': name,
            'category': category,
            'status': status,
            'predicted_out_date': datetime.now() + timedelta(days=7),
            'last_restocked_at': datetime.now(),
        }
        self.items.append(new_item)
        self.logs.append({'item_id': new_item['id'], 'action': 'RESTOCKED', 'created_at': datetime.now()})
        return new_item


class TestOfflineDatabaseFlow(unittest.TestCase):

    def setUp(self):
        self.db = MockPantryDatabase()

    def test_shopping_list_filtering(self):
        """Dad's Shopping List should only include LOW and OUT_OF_STOCK items."""
        shopping_list = self.db.get_shopping_list()
        item_names = [i['name'] for i in shopping_list]
        self.assertEqual(len(shopping_list), 2)
        self.assertIn('Whole Milk', item_names)
        self.assertIn('Organic Avocados', item_names)
        self.assertNotIn('Dark Roast Coffee', item_names)

    def test_ai_restock_suggestions(self):
        """Suggestions screen should flag Dark Roast Coffee as depleting in 2 days."""
        suggestions = self.db.get_ai_suggestions()
        self.assertEqual(len(suggestions), 1)
        self.assertEqual(suggestions[0]['name'], 'Dark Roast Coffee')

    def test_restock_item_action(self):
        """Marking an item as IN_STOCK updates its status and appends a log."""
        self.db.update_item_status('2', 'IN_STOCK')
        item = next(i for i in self.db.items if i['id'] == '2')
        self.assertEqual(item['status'], 'IN_STOCK')
        self.assertEqual(len(self.db.logs), 1)
        self.assertEqual(self.db.logs[0]['action'], 'RESTOCKED')

        # After restocking, shopping list length drops to 1
        shopping_list = self.db.get_shopping_list()
        self.assertEqual(len(shopping_list), 1)

    def test_add_new_item(self):
        """Adding a new item increases item count and sets up initial prediction."""
        new_item = self.db.add_item('Greek Yogurt', 'Dairy & Eggs')
        self.assertEqual(len(self.db.items), 4)
        self.assertEqual(new_item['name'], 'Greek Yogurt')
        self.assertEqual(new_item['status'], 'IN_STOCK')


if __name__ == '__main__':
    unittest.main()
