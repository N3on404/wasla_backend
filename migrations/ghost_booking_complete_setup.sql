-- Ghost Booking Complete Database Setup
-- This file contains all the database changes needed for the ghost booking feature
-- Apply this to your server database to enable ghost bookings

-- ==============================================
-- 1. Add ghost booking columns to bookings table
-- ==============================================

-- Add ghost booking fields to bookings table
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS destination_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS is_ghost_booking BOOLEAN DEFAULT FALSE;

-- ==============================================
-- 2. Add index for ghost booking queries
-- ==============================================

-- Add index for ghost booking queries
CREATE INDEX IF NOT EXISTS idx_bookings_ghost_destination 
ON bookings(destination_id, is_ghost_booking, booking_status) 
WHERE is_ghost_booking = true;

-- ==============================================
-- 3. Fix foreign key constraint
-- ==============================================

-- Drop any existing foreign key constraint on destination_id
ALTER TABLE bookings 
DROP CONSTRAINT IF EXISTS fk_bookings_destination;

-- Update any existing bookings with invalid destination_id to use a valid route
-- (This updates STN001, STN002, etc. to use actual route IDs)
UPDATE bookings 
SET destination_id = 'station-jemmal' 
WHERE destination_id IN ('STN001', 'STN002', 'STN003') 
   OR destination_id IS NULL;

-- Add new foreign key constraint referencing routes table
ALTER TABLE bookings 
ADD CONSTRAINT fk_bookings_destination 
FOREIGN KEY (destination_id) REFERENCES routes(station_id);

-- ==============================================
-- 4. Verify the setup
-- ==============================================

-- Check that the columns were added
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'bookings' 
  AND column_name IN ('destination_id', 'is_ghost_booking');

-- Check that the index was created
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'bookings' 
  AND indexname = 'idx_bookings_ghost_destination';

-- Check that the foreign key constraint was created
SELECT tc.constraint_name, tc.table_name, kcu.column_name, 
       ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name 
JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name 
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'bookings' 
  AND kcu.column_name = 'destination_id';

-- Check available routes for ghost bookings
SELECT station_id, station_name, base_price, is_active 
FROM routes 
WHERE is_active = true 
ORDER BY station_name;

-- ==============================================
-- 5. Test data (optional - for verification)
-- ==============================================

-- Uncomment the following lines to create a test ghost booking
-- (Make sure you have a valid staff_id first)

/*
INSERT INTO bookings (
    id, destination_id, seats_booked, seat_number, total_amount, 
    booking_source, booking_type, booking_status, payment_status, 
    payment_method, verification_code, is_verified, is_ghost_booking, 
    created_by, created_at
) VALUES (
    'test-ghost-' || extract(epoch from now())::text,
    'station-jemmal',
    1,
    1,
    1.80,
    'CASH_STATION',
    'CASH',
    'ACTIVE',
    'PAID',
    'CASH',
    LPAD(CAST(FLOOR(random()*1000000) AS TEXT), 6, '0'),
    false,
    true,
    (SELECT id FROM staff LIMIT 1),
    NOW()
);
*/

-- ==============================================
-- Summary of Changes Made:
-- ==============================================
-- 1. Added destination_id column to bookings table
-- 2. Added is_ghost_booking column to bookings table  
-- 3. Created index for efficient ghost booking queries
-- 4. Updated existing bookings to use valid route IDs
-- 5. Added foreign key constraint referencing routes table
-- 6. Added verification queries to confirm setup
-- 
-- The ghost booking feature is now ready to use!
-- Backend API endpoints:
-- - POST /api/v1/bookings/ghost
-- - GET /api/v1/bookings/ghost/count
-- - GET /api/v1/destinations
