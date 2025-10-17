-- Create staff table for authentication
CREATE TABLE IF NOT EXISTS staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cin VARCHAR(20) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('WORKER', 'SUPERVISOR')),
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create index for faster CIN lookups
CREATE INDEX IF NOT EXISTS idx_staff_cin ON staff(cin);
CREATE INDEX IF NOT EXISTS idx_staff_active ON staff(is_active);

-- Insert sample staff data for testing
INSERT INTO staff (cin, phone_number, first_name, last_name, role) VALUES
('12345678', '+21612345678', 'Ahmed', 'Ben Ali', 'SUPERVISOR'),
('87654321', '+21687654321', 'Fatma', 'Ben Salem', 'WORKER'),
('11223344', '+21611223344', 'Mohamed', 'Trabelsi', 'WORKER')
ON CONFLICT (cin) DO NOTHING;

-- Create vehicles table for queue management
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    capacity INTEGER NOT NULL DEFAULT 8,
    phone_number VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    is_available BOOLEAN DEFAULT true,
    is_banned BOOLEAN DEFAULT false,
    current_station_id UUID,
    queue_position INTEGER,
    status VARCHAR(20) DEFAULT 'WAITING' CHECK (status IN ('WAITING', 'LOADING', 'READY', 'DEPARTED')),
    available_seats INTEGER NOT NULL DEFAULT 8,
    total_seats INTEGER NOT NULL DEFAULT 8,
    base_price DECIMAL(10,2) DEFAULT 2.00,
    destination_id VARCHAR(100),
    destination_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for vehicles
CREATE INDEX IF NOT EXISTS idx_vehicles_station ON vehicles(current_station_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_position ON vehicles(queue_position);
CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status);

-- Create bookings table
CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id),
    seats_booked INTEGER NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    booking_source VARCHAR(50) DEFAULT 'CASH_STATION',
    booking_type VARCHAR(20) DEFAULT 'CASH',
    booking_status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (booking_status IN ('ACTIVE', 'CANCELLED', 'COMPLETED', 'REFUNDED')),
    payment_status VARCHAR(20) DEFAULT 'PAID',
    payment_method VARCHAR(20) DEFAULT 'CASH',
    verification_code VARCHAR(10) UNIQUE NOT NULL,
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP,
    verified_by_id UUID REFERENCES staff(id),
    created_by UUID NOT NULL REFERENCES staff(id),
    cancelled_at TIMESTAMP,
    cancelled_by UUID REFERENCES staff(id),
    cancellation_reason TEXT,
    refund_amount DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for bookings
CREATE INDEX IF NOT EXISTS idx_bookings_vehicle ON bookings(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_bookings_verification ON bookings(verification_code);
CREATE INDEX IF NOT EXISTS idx_bookings_created_by ON bookings(created_by);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(booking_status);

-- Create stations table
CREATE TABLE IF NOT EXISTS stations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    station_id VARCHAR(50) UNIQUE NOT NULL,
    station_name VARCHAR(100) NOT NULL,
    governorate VARCHAR(100),
    delegation VARCHAR(100),
    address TEXT,
    opening_time VARCHAR(10) DEFAULT '06:00',
    closing_time VARCHAR(10) DEFAULT '22:00',
    is_operational BOOLEAN DEFAULT true,
    service_fee DECIMAL(10,3) DEFAULT 0.200,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample station data
INSERT INTO stations (station_id, station_name, governorate, delegation) VALUES
('STN001', 'Station Tunis', 'Tunis', 'Tunis Centre'),
('STN002', 'Station Sfax', 'Sfax', 'Sfax Ville'),
('STN003', 'Station Sousse', 'Sousse', 'Sousse Médina')
ON CONFLICT (station_id) DO NOTHING;
