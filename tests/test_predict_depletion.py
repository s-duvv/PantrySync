#!/usr/bin/env python3
"""
Unit Test Suite for PantrySync Moving Average Prediction Algorithm
Tests Python calculation logic against various historical log scenarios.
"""

import unittest
from datetime import datetime, timedelta
import os
import sys

# Add project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from scripts.predict_depletion import calculate_next_depletion


class TestPredictionAlgorithm(unittest.TestCase):

    def setUp(self):
        self.now = datetime.now()

    def test_empty_logs_returns_default_7_days(self):
        """When history logs are empty, return default 7 days from now."""
        logs = []
        result = calculate_next_depletion(logs)
        expected_min = self.now + timedelta(days=6, hours=23)
        expected_max = self.now + timedelta(days=7, hours=1)
        self.assertTrue(expected_min <= result <= expected_max)

    def test_regular_interval_calculation(self):
        """Test calculation with consistent 5-day intervals between restock & empty."""
        logs = [
            {'action': 'RESTOCKED', 'created_at': self.now - timedelta(days=20)},
            {'action': 'EMPTIED', 'created_at': self.now - timedelta(days=15)}, # 5 days
            {'action': 'RESTOCKED', 'created_at': self.now - timedelta(days=10)},
            {'action': 'EMPTIED', 'created_at': self.now - timedelta(days=5)},  # 5 days
            {'action': 'RESTOCKED', 'created_at': self.now - timedelta(days=1)}, # Latest restock
        ]
        result = calculate_next_depletion(logs)
        expected_date = (self.now - timedelta(days=1)) + timedelta(days=5) # 4 days from now
        self.assertEqual(result.date(), expected_date.date())

    def test_varying_interval_average(self):
        """Test calculation with varying interval lengths (4 days and 8 days -> avg 6 days)."""
        logs = [
            {'action': 'RESTOCKED', 'created_at': self.now - timedelta(days=30)},
            {'action': 'EMPTIED', 'created_at': self.now - timedelta(days=26)}, # 4 days
            {'action': 'RESTOCKED', 'created_at': self.now - timedelta(days=20)},
            {'action': 'EMPTIED', 'created_at': self.now - timedelta(days=12)}, # 8 days
            {'action': 'RESTOCKED', 'created_at': self.now - timedelta(days=2)}, # Latest restock
        ]
        result = calculate_next_depletion(logs)
        # Average interval = (4 + 8) / 2 = 6 days.
        # Latest restock = now - 2 days. Predicted = now + 4 days.
        expected_date = (self.now - timedelta(days=2)) + timedelta(days=6)
        self.assertEqual(result.date(), expected_date.date())

    def test_unpaired_restocks(self):
        """Test handling of multiple RESTOCKED entries without intermediate EMPTIED."""
        logs = [
            {'action': 'RESTOCKED', 'created_at': self.now - timedelta(days=15)},
            {'action': 'RESTOCKED', 'created_at': self.now - timedelta(days=10)}, # Overwrites last_restock
            {'action': 'EMPTIED', 'created_at': self.now - timedelta(days=6)},   # 4 days interval
            {'action': 'RESTOCKED', 'created_at': self.now - timedelta(days=1)},
        ]
        result = calculate_next_depletion(logs)
        # Interval = 4 days. Latest restock = now - 1. Predicted = now + 3 days.
        expected_date = (self.now - timedelta(days=1)) + timedelta(days=4)
        self.assertEqual(result.date(), expected_date.date())

    def test_zero_or_negative_days_ignored(self):
        """Same-day RESTOCKED and EMPTIED (0 days taken) should be filtered out."""
        logs = [
            {'action': 'RESTOCKED', 'created_at': self.now - timedelta(days=10)},
            {'action': 'EMPTIED', 'created_at': self.now - timedelta(days=10)}, # 0 days -> ignored
            {'action': 'RESTOCKED', 'created_at': self.now - timedelta(days=2)},
        ]
        result = calculate_next_depletion(logs)
        # No valid intervals -> default 7 days fallback from latest restock / now
        self.assertTrue(result >= self.now)


if __name__ == '__main__':
    unittest.main()
