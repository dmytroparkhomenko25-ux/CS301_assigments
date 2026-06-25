import uuid
import random
import psycopg2
from psycopg2.extras import execute_values
from faker import Faker

DB_CONFIG = {
    "host": "localhost",
    "port": "5432",
    "dbname": "rideshare",
    "user": "postgres",
    "password": "1"
}

fake = Faker()

def get_connection():
    return psycopg2.connect(**DB_CONFIG)

def seed_data():
    conn = get_connection()
    cursor = conn.cursor()
    
    riders = []
    rider_ids = [str(uuid.uuid4()) for _ in range(2000)]
    for rid in rider_ids:
        riders.append((
            rid,
            fake.name(),
            fake.unique.email(),
            fake.phone_number()[:20],
            random.choice(['free', 'premium']),
            round(random.uniform(10, 1000), 2)
        ))
        
    drivers = []
    vehicles = []
    driver_ids = [str(uuid.uuid4()) for _ in range(1000)]
    for did in driver_ids:
        drivers.append((
            did,
            fake.name(),
            fake.unique.email(),
            fake.phone_number()[:20],
            random.choice([True, False]),
            round(random.uniform(3.5, 5.0), 2)
        ))
        vehicles.append((
            str(uuid.uuid4()),
            did,
            fake.company(),
            fake.word().capitalize(),
            fake.unique.license_plate()[:20],
            fake.color_name()
        ))
        
    rides = []
    payments = []
    statuses = ['requested', 'accepted', 'ongoing', 'completed', 'cancelled']
    methods = ['card', 'cash', 'wallet']
    p_statuses = ['pending', 'completed', 'failed']
    
    for _ in range(20000):
        ride_id = str(uuid.uuid4())
        status = random.choice(statuses)
        fare = round(random.uniform(5.00, 150.00), 2)
        rides.append((
            ride_id,
            random.choice(rider_ids),
            random.choice(driver_ids),
            round(random.uniform(-90.0, 90.0), 6),
            round(random.uniform(-180.0, 180.0), 6),
            round(random.uniform(-90.0, 90.0), 6),
            round(random.uniform(-180.0, 180.0), 6),
            fare,
            status
        ))
        if status in ['completed', 'ongoing']:
            payments.append((
                ride_id,
                fare,
                random.choice(methods),
                'completed' if status == 'completed' else random.choice(p_statuses)
            ))
            
    logs = []
    status_options = ['driver_active', 'driver_inactive', 'on_ride', 'break']
    for _ in range(500000):
        logs.append((
            random.choice(driver_ids),
            random.choice(status_options),
            fake.date_time_between(start_date='-1y', end_date='now')
        ))
        
    execute_values(cursor, """
        INSERT INTO riders (rider_id, full_name, email, phone, membership_tier, balance)
        VALUES %s ON CONFLICT DO NOTHING
    """, riders)
    
    execute_values(cursor, """
        INSERT INTO drivers (driver_id, full_name, email, phone, active, rating)
        VALUES %s ON CONFLICT DO NOTHING
    """, drivers)
    
    execute_values(cursor, """
        INSERT INTO vehicles (vehicle_id, driver_id, make, model, license_plate, color)
        VALUES %s ON CONFLICT DO NOTHING
    """, vehicles)
    
    execute_values(cursor, """
        INSERT INTO rides (ride_id, rider_id, driver_id, start_latitude, start_longitude, end_latitude, end_longitude, fare, status)
        VALUES %s ON CONFLICT DO NOTHING
    """, rides)
    
    execute_values(cursor, """
        INSERT INTO payments (ride_id, amount, payment_method, payment_status)
        VALUES %s ON CONFLICT DO NOTHING
    """, payments)
    
    chunk_size = 50000
    for i in range(0, len(logs), chunk_size):
        chunk = logs[i:i+chunk_size]
        execute_values(cursor, """
            INSERT INTO driver_status_logs (driver_id, status_change, changed_at)
            VALUES %s
        """, chunk)
        
    conn.commit()
    cursor.close()
    conn.close()
    print("Completed!")

if __name__ == "__main__":
    seed_data()
