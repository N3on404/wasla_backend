-- Migration 004: Add ghost booking support
-- Add fields to bookings table for ghost bookings

-- Add ghost booking fields to bookings table
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS destination_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS is_ghost_booking BOOLEAN DEFAULT FALSE;

-- Add index for ghost booking queries
CREATE INDEX IF NOT EXISTS idx_bookings_ghost_destination 
ON bookings(destination_id, is_ghost_booking, booking_status) 
WHERE is_ghost_booking = true;

-- Add foreign key constraint for destination_id (check if constraint doesn't exist first)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_bookings_destination' 
        AND table_name = 'bookings'
    ) THEN
        ALTER TABLE bookings 
        ADD CONSTRAINT fk_bookings_destination 
        FOREIGN KEY (destination_id) REFERENCES stations(station_id);
    END IF;
END $$;
