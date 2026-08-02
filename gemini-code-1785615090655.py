from datetime import datetime, timedelta

def calculate_next_depletion(history_logs):
    # history_logs: List of dicts sorted by timestamp ASC
    intervals = []
    last_restock = None

    for log in history_logs:
        if log['action'] == 'RESTOCKED':
            last_restock = log['created_at']
        elif log['action'] == 'EMPTIED' and last_restock is not None:
            days_taken = (log['created_at'] - last_restock).days
            if days_taken > 0:
                intervals.append(days_taken)
            last_restock = None

    if not intervals:
        # Default fallback estimate (7 days)
        return datetime.now() + timedelta(days=7)

    avg_days = sum(intervals) / len(intervals)
    latest_restock_date = max([l['created_at'] for l in history_logs if l['action'] == 'RESTOCKED'], default=datetime.now())
    
    return latest_restock_date + timedelta(days=avg_days)