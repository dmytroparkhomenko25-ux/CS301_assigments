CREATE OR REPLACE PROCEDURE request_and_assign_ride(
    p_ride_id VARCHAR(36),
    p_rider_id VARCHAR(36),
    p_driver_id VARCHAR(36),
    p_start_lat NUMERIC(9,6),
    p_start_lon NUMERIC(9,6),
    p_end_lat NUMERIC(9,6),
    p_end_lon NUMERIC(9,6),
    p_fare NUMERIC(10,2)
)
AS $$
DECLARE
    v_driver_active BOOLEAN;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM riders WHERE rider_id = p_rider_id) THEN
        RAISE EXCEPTION 'Rider with ID % does not exist', p_rider_id;
    END IF;

    SELECT active INTO v_driver_active FROM drivers WHERE driver_id = p_driver_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Driver with ID % does not exist', p_driver_id;
    END IF;
    
    IF NOT v_driver_active THEN
        RAISE EXCEPTION 'Driver with ID % is not active/available', p_driver_id;
    END IF;

    INSERT INTO rides (ride_id, rider_id, driver_id, start_latitude, start_longitude, end_latitude, end_longitude, fare, status)
    VALUES (p_ride_id, p_rider_id, p_driver_id, p_start_lat, p_start_lon, p_end_lat, p_end_lon, p_fare, 'accepted');

    UPDATE drivers SET active = FALSE WHERE driver_id = p_driver_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_log_driver_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.active IS DISTINCT FROM NEW.active THEN
        INSERT INTO driver_status_logs (driver_id, status_change, changed_at)
        VALUES (
            NEW.driver_id,
            CASE WHEN NEW.active THEN 'driver_active' ELSE 'driver_inactive' END,
            CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_log_driver_status_change ON drivers;
CREATE TRIGGER trg_log_driver_status_change
AFTER UPDATE OF active ON drivers
FOR EACH ROW
EXECUTE FUNCTION fn_log_driver_status_change();
