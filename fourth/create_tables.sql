DROP TABLE IF EXISTS driver_status_logs CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS rides CASCADE;
DROP TABLE IF EXISTS vehicles CASCADE;
DROP TABLE IF EXISTS drivers CASCADE;
DROP TABLE IF EXISTS riders CASCADE;

CREATE TABLE riders (
    rider_id VARCHAR(36) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    membership_tier VARCHAR(20) DEFAULT 'free' CHECK (membership_tier IN ('free', 'premium')),
    balance NUMERIC(10,2) DEFAULT 0.00 CHECK (balance >= 0.00),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE drivers (
    driver_id VARCHAR(36) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    rating NUMERIC(3,2) DEFAULT 5.00 CHECK (rating >= 1.00 AND rating <= 5.00),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vehicles (
    vehicle_id VARCHAR(36) PRIMARY KEY,
    driver_id VARCHAR(36) UNIQUE NOT NULL REFERENCES drivers(driver_id) ON DELETE CASCADE,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    license_plate VARCHAR(20) NOT NULL UNIQUE,
    color VARCHAR(30) NOT NULL
);

CREATE TABLE rides (
    ride_id VARCHAR(36) PRIMARY KEY,
    rider_id VARCHAR(36) NOT NULL REFERENCES riders(rider_id) ON DELETE RESTRICT,
    driver_id VARCHAR(36) NOT NULL REFERENCES drivers(driver_id) ON DELETE RESTRICT,
    start_latitude NUMERIC(9,6) NOT NULL CHECK (start_latitude BETWEEN -90 AND 90),
    start_longitude NUMERIC(9,6) NOT NULL CHECK (start_longitude BETWEEN -180 AND 180),
    end_latitude NUMERIC(9,6) NOT NULL CHECK (end_latitude BETWEEN -90 AND 90),
    end_longitude NUMERIC(9,6) NOT NULL CHECK (end_longitude BETWEEN -180 AND 180),
    fare NUMERIC(10,2) NOT NULL CHECK (fare >= 0.00),
    status VARCHAR(20) DEFAULT 'requested' CHECK (status IN ('requested', 'accepted', 'ongoing', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    ride_id VARCHAR(36) UNIQUE NOT NULL REFERENCES rides(ride_id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0.00),
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('card', 'cash', 'wallet')),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed')),
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE driver_status_logs (
    log_id SERIAL PRIMARY KEY,
    driver_id VARCHAR(36) NOT NULL REFERENCES drivers(driver_id) ON DELETE CASCADE,
    status_change VARCHAR(50) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_driver_status_logs_status_change_changed_at 
ON driver_status_logs(status_change, changed_at DESC);
