-- Migration to add trips and exit_passes tables
-- These tables are referenced in the booking service but were missing from the schema

-- Create trips table to track completed vehicle journeys
CREATE TABLE IF NOT EXISTS trips (
    id VARCHAR(50) PRIMARY KEY,
    vehicle_id UUID NOT NULL REFERENCES vehicles(id),
    license_plate VARCHAR(20) NOT NULL,
    destination_id VARCHAR(100) NOT NULL,
    destination_name VARCHAR(100) NOT NULL,
    queue_id UUID NOT NULL,
    seats_booked INTEGER NOT NULL DEFAULT 0,
    start_time TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for trips table
CREATE INDEX IF NOT EXISTS idx_trips_vehicle_id ON trips(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_trips_license_plate ON trips(license_plate);
CREATE INDEX IF NOT EXISTS idx_trips_destination_id ON trips(destination_id);
CREATE INDEX IF NOT EXISTS idx_trips_queue_id ON trips(queue_id);
CREATE INDEX IF NOT EXISTS idx_trips_start_time ON trips(start_time);
CREATE INDEX IF NOT EXISTS idx_trips_date ON trips(DATE(start_time));

-- Create exit_passes table to track exit passes for fully booked vehicles
CREATE TABLE IF NOT EXISTS exit_passes (
    id VARCHAR(50) PRIMARY KEY,
    queue_id UUID NOT NULL,
    vehicle_id UUID NOT NULL REFERENCES vehicles(id),
    license_plate VARCHAR(20) NOT NULL,
    destination_id VARCHAR(100) NOT NULL,
    destination_name VARCHAR(100) NOT NULL,
    current_exit_time TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by UUID NOT NULL REFERENCES staff(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for exit_passes table
CREATE INDEX IF NOT EXISTS idx_exit_passes_queue_id ON exit_passes(queue_id);
CREATE INDEX IF NOT EXISTS idx_exit_passes_vehicle_id ON exit_passes(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_exit_passes_license_plate ON exit_passes(license_plate);
CREATE INDEX IF NOT EXISTS idx_exit_passes_destination_id ON exit_passes(destination_id);
CREATE INDEX IF NOT EXISTS idx_exit_passes_created_by ON exit_passes(created_by);
CREATE INDEX IF NOT EXISTS idx_exit_passes_exit_time ON exit_passes(current_exit_time);

-- Create day_passes table to track day pass sales
CREATE TABLE IF NOT EXISTS day_passes (
    id VARCHAR(50) PRIMARY KEY,
    vehicle_id UUID NOT NULL REFERENCES vehicles(id),
    license_plate VARCHAR(20) NOT NULL,
    destination_id VARCHAR(100) NOT NULL,
    destination_name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    purchase_date TIMESTAMP NOT NULL DEFAULT NOW(),
    valid_from TIMESTAMP NOT NULL,
    valid_until TIMESTAMP NOT NULL,
    created_by UUID NOT NULL REFERENCES staff(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for day_passes table
CREATE INDEX IF NOT EXISTS idx_day_passes_vehicle_id ON day_passes(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_day_passes_license_plate ON day_passes(license_plate);
CREATE INDEX IF NOT EXISTS idx_day_passes_destination_id ON day_passes(destination_id);
CREATE INDEX IF NOT EXISTS idx_day_passes_created_by ON day_passes(created_by);
CREATE INDEX IF NOT EXISTS idx_day_passes_purchase_date ON day_passes(purchase_date);
CREATE INDEX IF NOT EXISTS idx_day_passes_valid_period ON day_passes(valid_from, valid_until);

-- Add missing columns to existing tables if they don't exist
DO $$ 
BEGIN
    -- Add seat_number column to bookings table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'seat_number') THEN
        ALTER TABLE bookings ADD COLUMN seat_number INTEGER DEFAULT 1;
    END IF;
    
    -- Add queue_id column to bookings table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'queue_id') THEN
        ALTER TABLE bookings ADD COLUMN queue_id UUID;
    END IF;
    
    -- Add created_by_name column to bookings table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bookings' AND column_name = 'created_by_name') THEN
        ALTER TABLE bookings ADD COLUMN created_by_name VARCHAR(200);
    END IF;
END $$;
