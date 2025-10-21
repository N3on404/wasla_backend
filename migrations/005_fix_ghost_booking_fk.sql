-- Migration 005: Fix ghost booking foreign key constraint
-- Drop the existing foreign key constraint and create a new one referencing routes table

-- Drop the existing foreign key constraint
ALTER TABLE bookings 
DROP CONSTRAINT IF EXISTS fk_bookings_destination;

-- Add new foreign key constraint referencing routes table
ALTER TABLE bookings 
ADD CONSTRAINT fk_bookings_destination 
FOREIGN KEY (destination_id) REFERENCES routes(station_id);
