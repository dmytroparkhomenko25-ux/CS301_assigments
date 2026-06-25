DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ride_admin') THEN
        CREATE ROLE ride_admin LOGIN PASSWORD 'RideAdminSecretPass123';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ride_analyst') THEN
        CREATE ROLE ride_analyst LOGIN PASSWORD 'RideAnalystPass456';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ride_service_app') THEN
        CREATE ROLE ride_service_app LOGIN PASSWORD 'RideServiceAppPass789';
    END IF;
END
$$;

GRANT ALL PRIVILEGES ON DATABASE rideshare TO ride_admin;

GRANT CONNECT ON DATABASE rideshare TO ride_analyst;
GRANT USAGE ON SCHEMA public TO ride_analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ride_analyst;
GRANT SELECT ON driver_performance_summary TO ride_analyst;

GRANT CONNECT ON DATABASE rideshare TO ride_service_app;
GRANT USAGE ON SCHEMA public TO ride_service_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE rides, payments, driver_status_logs TO ride_service_app;
GRANT SELECT, UPDATE ON TABLE drivers, riders TO ride_service_app;
