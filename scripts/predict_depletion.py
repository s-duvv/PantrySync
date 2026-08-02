#!/usr/bin/env python3
"""
PantrySync - Moving Average Depletion Calculation Script
Calculates predicted next depletion date based on historical consumption logs.
"""

from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional

def calculate_next_depletion(history_logs: List[Dict[str, Any]]) -> datetime:
    """
    Calculates the predicted next depletion date for a grocery item.
    
    Args:
        history_logs: List of dicts containing 'action' ('RESTOCKED' | 'EMPTIED') 
                      and 'created_at' (datetime object), sorted chronologically.
    
    Returns:
        Predicted datetime of item depletion.
    """
    intervals = []
    last_restock = None

    for log in history_logs:
        action = log.get('action')
        created_at = log.get('created_at')

        if action == 'RESTOCKED':
            last_restock = created_at
        elif action == 'EMPTIED' and last_restock is not None:
            days_taken = (created_at - last_restock).days
            if days_taken > 0:
                intervals.append(days_taken)
            last_restock = None

    if not intervals:
        # Default fallback estimate: 7 days from now
        return datetime.now() + timedelta(days=7)

    avg_days = sum(intervals) / len(intervals)
    restock_dates = [l['created_at'] for l in history_logs if l.get('action') == 'RESTOCKED']
    latest_restock_date = max(restock_dates, default=datetime.now())

    return latest_restock_date + timedelta(days=avg_days)


if __name__ == '__main__':
    # Self-test demonstration
    now = datetime.now()
    sample_logs = [
        {'action': 'RESTOCKED', 'created_at': now - timedelta(days=28)},
        {'action': 'EMPTIED', 'created_at': now - timedelta(days=21)},
        {'action': 'RESTOCKED', 'created_at': now - timedelta(days=14)},
        {'action': 'EMPTIED', 'created_at': now - timedelta(days=7)},
        {'action': 'RESTOCKED', 'created_at': now - timedelta(days=1)},
    ]

    predicted_depletion = calculate_next_depletion(sample_logs)
    print("=" * 60)
    print("PantrySync Predictive Algorithm Test")
    print("=" * 60)
    print(f"Sample History Logs: {len(sample_logs)} entries")
    print(f"Latest Restock: {sample_logs[-1]['created_at'].strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Predicted Depletion Date: {predicted_depletion.strftime('%Y-%m-%d %H:%M:%S')}")
    days_left = (predicted_depletion - now).days
    print(f"Days Remaining: ~{days_left} days")
    print("=" * 60)
