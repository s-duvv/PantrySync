-- PostgreSQL Stored Procedure & Trigger for Server-Side Moving Average Depletion Prediction
-- Calculates predicted_out_date for a given item based on historical RESTOCKED/EMPTIED logs

CREATE OR REPLACE FUNCTION public.calculate_item_prediction(target_item_id UUID)
RETURNS DATE AS $$
DECLARE
    rec RECORD;
    last_restock_time TIMESTAMPTZ := NULL;
    interval_days NUMERIC[];
    days_diff NUMERIC;
    avg_days NUMERIC := 7.0; -- Default fallback
    latest_restock TIMESTAMPTZ := NULL;
    predicted_date DATE;
BEGIN
    -- Iterate through logs sorted chronologically
    FOR rec IN 
        SELECT action, created_at 
        FROM public.consumption_logs 
        WHERE item_id = target_item_id 
        ORDER BY created_at ASC
    LOOP
        IF rec.action = 'RESTOCKED' THEN
            last_restock_time := rec.created_at;
            latest_restock := rec.created_at;
        ELSIF rec.action = 'EMPTIED' AND last_restock_time IS NOT NULL THEN
            days_diff := EXTRACT(EPOCH FROM (rec.created_at - last_restock_time)) / 86400.0;
            IF days_diff > 0 THEN
                interval_days := array_append(interval_days, days_diff);
            END IF;
            last_restock_time := NULL;
        END IF;
    END LOOP;

    -- Calculate average interval
    IF array_length(interval_days, 1) > 0 THEN
        SELECT AVG(val) INTO avg_days FROM unnest(interval_days) AS val;
    END IF;

    IF latest_restock IS NULL THEN
        latest_restock := NOW();
    END IF;

    predicted_date := (latest_restock + (avg_days || ' days')::INTERVAL)::DATE;

    -- Update the grocery item record
    UPDATE public.grocery_items 
    SET predicted_out_date = predicted_date 
    WHERE id = target_item_id;

    RETURN predicted_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger Function on consumption_logs Insert
CREATE OR REPLACE FUNCTION public.trg_recalculate_prediction()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM public.calculate_item_prediction(NEW.item_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach Trigger to consumption_logs Table
DROP TRIGGER IF EXISTS trigger_recalculate_prediction ON public.consumption_logs;
CREATE TRIGGER trigger_recalculate_prediction
AFTER INSERT ON public.consumption_logs
FOR EACH ROW
EXECUTE FUNCTION public.trg_recalculate_prediction();
