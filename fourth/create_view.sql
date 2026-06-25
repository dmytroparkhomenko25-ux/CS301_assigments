DROP VIEW IF EXISTS driver_performance_summary;

CREATE VIEW driver_performance_summary AS
SELECT 
    d.driver_id,
    d.full_name AS driver_name,
    d.rating AS driver_rating,
    v.make || ' ' || v.model AS vehicle_details,
    v.license_plate,
    COUNT(r.ride_id) AS total_rides_completed,
    COALESCE(SUM(r.fare), 0.00) AS total_earnings
FROM drivers d
JOIN vehicles v ON d.driver_id = v.driver_id
LEFT JOIN rides r ON d.driver_id = r.driver_id AND r.status = 'completed'
GROUP BY d.driver_id, d.full_name, d.rating, v.make, v.model, v.license_plate;
