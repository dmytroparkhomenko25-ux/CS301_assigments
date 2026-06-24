import uuid
import random
from datetime import datetime, timedelta

import psycopg2
from psycopg2.extras import execute_values
from faker import Faker


HOST = 'localhost'
USER = 'postgres'
PASSWORD = '1'
DATABASE = 'gh_opt_db'
PORT = '5432'

USERS_COUNT = 50_000
REPOS_COUNT = 100_000
ISSUES_COUNT = 500_000
PRS_COUNT = 300_000
CHUNK_SIZE = 10_000

fake = Faker()

LANGUAGES = [
    'Python', 'JavaScript', 'TypeScript', 'Java', 'Go',
    'Rust', 'C++', 'Ruby', 'PHP', 'C#', 'Swift', 'Kotlin',
    'Dart', 'Scala', 'R', 'Lua', 'Shell', 'HTML', 'CSS'
]

LABELS = ['bug', 'feature', 'enhancement', 'documentation', 'question',
          'help wanted', 'good first issue', 'wontfix', 'duplicate', 'invalid']

PLANS = ['free', 'free', 'free', 'free', 'pro', 'pro', 'enterprise']


def insert_users(cursor):
    print("Inserting into gh_users...")

    query = """
        INSERT INTO gh_users
            (user_id, username, email, created_at, bio, location, plan)
        VALUES %s
    """

    user_ids = []
    used_usernames = set()

    for start in range(0, USERS_COUNT, CHUNK_SIZE):
        current_chunk_size = min(CHUNK_SIZE, USERS_COUNT - start)
        data = []

        for _ in range(current_chunk_size):
            uid = str(uuid.uuid4())
            user_ids.append(uid)

            username = fake.user_name()
            while username in used_usernames:
                username = fake.user_name() + str(random.randint(0, 999))
            used_usernames.add(username)

            data.append((
                uid,
                username,
                fake.email(),
                fake.date_time_between(start_date='-5y', end_date='now'),
                fake.text(max_nb_chars=200) if random.random() > 0.4 else None,
                fake.city() if random.random() > 0.5 else None,
                random.choice(PLANS),
            ))

        execute_values(cursor, query, data)
        print(f"  {start + current_chunk_size}/{USERS_COUNT}")

    print("Done: gh_users")
    return user_ids


def insert_repos(cursor, user_ids):
    print("Inserting into gh_repos...")

    query = """
        INSERT INTO gh_repos
            (owner_id, repo_name, description, language, is_private,
             stars_count, forks_count, created_at)
        VALUES %s
        RETURNING repo_id
    """

    repo_ids = []

    for start in range(0, REPOS_COUNT, CHUNK_SIZE):
        current_chunk_size = min(CHUNK_SIZE, REPOS_COUNT - start)
        data = []

        for _ in range(current_chunk_size):
            data.append((
                random.choice(user_ids),
                fake.word() + '-' + fake.word() + str(random.randint(0, 9999)),
                fake.text(max_nb_chars=200) if random.random() > 0.3 else None,
                random.choice(LANGUAGES),
                random.random() < 0.15,
                random.randint(0, 10000),
                random.randint(0, 1000),
                fake.date_time_between(start_date='-5y', end_date='now'),
            ))

        execute_values(cursor, query, data)
        ids = [row[0] for row in cursor.fetchall()]
        repo_ids.extend(ids)
        print(f"  {start + current_chunk_size}/{REPOS_COUNT}")

    print("Done: gh_repos")
    return repo_ids


def insert_issues(cursor, user_ids, repo_ids):
    print("Inserting into gh_issues...")

    query = """
        INSERT INTO gh_issues
            (repo_id, author_id, title, body, state, label, created_at, closed_at)
        VALUES %s
    """

    for start in range(0, ISSUES_COUNT, CHUNK_SIZE):
        current_chunk_size = min(CHUNK_SIZE, ISSUES_COUNT - start)
        data = []

        for _ in range(current_chunk_size):
            created = fake.date_time_between(start_date='-3y', end_date='now')
            state = random.choice(['open', 'closed', 'closed'])
            closed_at = created + timedelta(
                hours=random.randint(1, 720)
            ) if state == 'closed' else None

            data.append((
                random.choice(repo_ids),
                random.choice(user_ids),
                fake.sentence(nb_words=6),
                fake.text(max_nb_chars=500) if random.random() > 0.3 else None,
                state,
                random.choice(LABELS) if random.random() > 0.3 else None,
                created,
                closed_at,
            ))

        execute_values(cursor, query, data)
        print(f"  {start + current_chunk_size}/{ISSUES_COUNT}")

    print("Done: gh_issues")


def insert_prs(cursor, user_ids, repo_ids):
    print("Inserting into gh_pull_requests...")

    query = """
        INSERT INTO gh_pull_requests
            (repo_id, author_id, title, body, state, created_at, closed_at, merged_at)
        VALUES %s
    """

    for start in range(0, PRS_COUNT, CHUNK_SIZE):
        current_chunk_size = min(CHUNK_SIZE, PRS_COUNT - start)
        data = []

        for _ in range(current_chunk_size):
            created = fake.date_time_between(start_date='-3y', end_date='now')
            state = random.choice(['open', 'closed', 'merged', 'merged'])
            closed_at = created + timedelta(
                hours=random.randint(1, 360)
            ) if state in ('closed', 'merged') else None
            merged_at = (
                created + timedelta(hours=random.randint(1, 200))
                if state == 'merged' else None
            )

            data.append((
                random.choice(repo_ids),
                random.choice(user_ids),
                fake.sentence(nb_words=5),
                fake.text(max_nb_chars=500) if random.random() > 0.4 else None,
                state,
                created,
                closed_at,
                merged_at,
            ))

        execute_values(cursor, query, data)
        print(f"  {start + current_chunk_size}/{PRS_COUNT}")

    print("Done: gh_pull_requests")


def main():
    connection = psycopg2.connect(
        host=HOST, user=USER, password=PASSWORD,
        dbname=DATABASE, port=PORT,
    )

    try:
        with connection:
            with connection.cursor() as cursor:
                user_ids = insert_users(cursor)
                repo_ids = insert_repos(cursor, user_ids)
                insert_issues(cursor, user_ids, repo_ids)
                insert_prs(cursor, user_ids, repo_ids)
    finally:
        connection.close()


if __name__ == "__main__":
    main()
