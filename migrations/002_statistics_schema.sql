-- Statistics database schema for staff income and station statistics
-- This migration adds tables to track staff income and station statistics

-- Create staff_daily_statistics table to track daily income for each staff member
CREATE TABLE IF NOT EXISTS staff_daily_statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID NOT NULL REFERENCES staff(id),
    date DATE NOT NULL,
    total_seats_booked INTEGER DEFAULT 0,
    total_seat_income DECIMAL(10,2) DEFAULT 0.00, -- 0.2 TND per seat
    total_day_passes_sold INTEGER DEFAULT 0,
    total_day_pass_income DECIMAL(10,2) DEFAULT 0.00, -- 2 TND per day pass
    total_income DECIMAL(10,2) DEFAULT 0.00, -- total_seat_income + total_day_pass_income
    total_transactions INTEGER DEFAULT 0, -- total bookings + day passes created
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(staff_id, date)
);

-- Create indexes for staff_daily_statistics
CREATE INDEX IF NOT EXISTS idx_staff_daily_stats_staff_id ON staff_daily_statistics(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_daily_stats_date ON staff_daily_statistics(date);
CREATE INDEX IF NOT EXISTS idx_staff_daily_stats_staff_date ON staff_daily_statistics(staff_id, date);

-- Create station_daily_statistics table to track daily station-wide statistics
CREATE TABLE IF NOT EXISTS station_daily_statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id UUID NOT NULL REFERENCES stations(id),
    date DATE NOT NULL,
    total_seats_booked INTEGER DEFAULT 0,
    total_seat_income DECIMAL(10,2) DEFAULT 0.00,
    total_day_passes_sold INTEGER DEFAULT 0,
    total_day_pass_income DECIMAL(10,2) DEFAULT 0.00,
    total_income DECIMAL(10,2) DEFAULT 0.00,
    total_transactions INTEGER DEFAULT 0,
    active_staff_count INTEGER DEFAULT 0, -- number of staff who made transactions
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(station_id, date)
);

-- Create indexes for station_daily_statistics
CREATE INDEX IF NOT EXISTS idx_station_daily_stats_station_id ON station_daily_statistics(station_id);
CREATE INDEX IF NOT EXISTS idx_station_daily_stats_date ON station_daily_statistics(date);
CREATE INDEX IF NOT EXISTS idx_station_daily_stats_station_date ON station_daily_statistics(station_id, date);

-- Create staff_transaction_log table to track individual transactions
CREATE TABLE IF NOT EXISTS staff_transaction_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID NOT NULL REFERENCES staff(id),
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('SEAT_BOOKING', 'DAY_PASS_SALE')),
    transaction_id UUID NOT NULL, -- references booking.id or day_pass.id
    amount DECIMAL(10,2) NOT NULL,
    quantity INTEGER DEFAULT 1, -- number of seats or day passes
    station_id UUID NOT NULL REFERENCES stations(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for staff_transaction_log
CREATE INDEX IF NOT EXISTS idx_staff_transaction_log_staff_id ON staff_transaction_log(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_transaction_log_type ON staff_transaction_log(transaction_type);
CREATE INDEX IF NOT EXISTS idx_staff_transaction_log_date ON staff_transaction_log(created_at);
CREATE INDEX IF NOT EXISTS idx_staff_transaction_log_station ON staff_transaction_log(station_id);

-- Create function to update staff daily statistics
CREATE OR REPLACE FUNCTION update_staff_daily_stats(
    p_staff_id UUID,
    p_transaction_type VARCHAR(20),
    p_amount DECIMAL(10,2),
    p_quantity INTEGER DEFAULT 1
) RETURNS VOID AS $$
DECLARE
    current_date DATE := CURRENT_DATE;
    seat_income DECIMAL(10,2) := 0.00;
    day_pass_income DECIMAL(10,2) := 0.00;
    seat_count INTEGER := 0;
    day_pass_count INTEGER := 0;
BEGIN
    -- Calculate income based on transaction type
    IF p_transaction_type = 'SEAT_BOOKING' THEN
        seat_income := p_amount;
        seat_count := p_quantity;
    ELSIF p_transaction_type = 'DAY_PASS_SALE' THEN
        day_pass_income := p_amount;
        day_pass_count := p_quantity;
    END IF;

    -- Insert or update staff daily statistics
    INSERT INTO staff_daily_statistics (
        staff_id, date, total_seats_booked, total_seat_income,
        total_day_passes_sold, total_day_pass_income, total_income, total_transactions
    ) VALUES (
        p_staff_id, current_date, seat_count, seat_income,
        day_pass_count, day_pass_income, seat_income + day_pass_income, 1
    )
    ON CONFLICT (staff_id, date) DO UPDATE SET
        total_seats_booked = staff_daily_statistics.total_seats_booked + seat_count,
        total_seat_income = staff_daily_statistics.total_seat_income + seat_income,
        total_day_passes_sold = staff_daily_statistics.total_day_passes_sold + day_pass_count,
        total_day_pass_income = staff_daily_statistics.total_day_pass_income + day_pass_income,
        total_income = staff_daily_statistics.total_income + seat_income + day_pass_income,
        total_transactions = staff_daily_statistics.total_transactions + 1,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Create function to update station daily statistics
CREATE OR REPLACE FUNCTION update_station_daily_stats(
    p_station_id UUID,
    p_transaction_type VARCHAR(20),
    p_amount DECIMAL(10,2),
    p_quantity INTEGER DEFAULT 1
) RETURNS VOID AS $$
DECLARE
    current_date DATE := CURRENT_DATE;
    seat_income DECIMAL(10,2) := 0.00;
    day_pass_income DECIMAL(10,2) := 0.00;
    seat_count INTEGER := 0;
    day_pass_count INTEGER := 0;
BEGIN
    -- Calculate income based on transaction type
    IF p_transaction_type = 'SEAT_BOOKING' THEN
        seat_income := p_amount;
        seat_count := p_quantity;
    ELSIF p_transaction_type = 'DAY_PASS_SALE' THEN
        day_pass_income := p_amount;
        day_pass_count := p_quantity;
    END IF;

    -- Insert or update station daily statistics
    INSERT INTO station_daily_statistics (
        station_id, date, total_seats_booked, total_seat_income,
        total_day_passes_sold, total_day_pass_income, total_income, total_transactions
    ) VALUES (
        p_station_id, current_date, seat_count, seat_income,
        day_pass_count, day_pass_income, seat_income + day_pass_income, 1
    )
    ON CONFLICT (station_id, date) DO UPDATE SET
        total_seats_booked = station_daily_statistics.total_seats_booked + seat_count,
        total_seat_income = station_daily_statistics.total_seat_income + seat_income,
        total_day_passes_sold = station_daily_statistics.total_day_passes_sold + day_pass_count,
        total_day_pass_income = station_daily_statistics.total_day_pass_income + day_pass_income,
        total_income = station_daily_statistics.total_income + seat_income + day_pass_income,
        total_transactions = station_daily_statistics.total_transactions + 1,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Create function to log staff transaction
CREATE OR REPLACE FUNCTION log_staff_transaction(
    p_staff_id UUID,
    p_transaction_type VARCHAR(20),
    p_transaction_id UUID,
    p_amount DECIMAL(10,2),
    p_quantity INTEGER DEFAULT 1,
    p_station_id UUID
) RETURNS VOID AS $$
BEGIN
    -- Insert transaction log
    INSERT INTO staff_transaction_log (
        staff_id, transaction_type, transaction_id, amount, quantity, station_id
    ) VALUES (
        p_staff_id, p_transaction_type, p_transaction_id, p_amount, p_quantity, p_station_id
    );
    
    -- Update staff daily statistics
    PERFORM update_staff_daily_stats(p_staff_id, p_transaction_type, p_amount, p_quantity);
    
    -- Update station daily statistics
    PERFORM update_station_daily_stats(p_station_id, p_transaction_type, p_amount, p_quantity);
END;
$$ LANGUAGE plpgsql;
