EXPLAIN ANALYZE
SELECT
    (
        SELECT CONCAT(repo_name, ': ', cnt)
        FROM (
            SELECT sub1.repo_name, COUNT(*) AS cnt
            FROM (
                SELECT
                    i.issue_id,
                    i.repo_id,
                    r.repo_name,
                    r.language,
                    u.user_id,
                    u.plan
                FROM gh_issues AS i
                JOIN gh_repos AS r
                    ON i.repo_id = r.repo_id
                JOIN gh_users AS u
                    ON r.owner_id = u.user_id
                WHERE r.created_at > TIMESTAMP '2023-01-01'
                  AND u.plan IN ('pro', 'enterprise')
                  AND i.state = 'open'
            ) AS sub1
            GROUP BY sub1.repo_name
        ) AS sub2
        WHERE cnt = (
            SELECT MIN(cnt)
            FROM (
                SELECT COUNT(*) AS cnt
                FROM (
                    SELECT
                        i.issue_id,
                        i.repo_id,
                        r.repo_name,
                        r.language,
                        u.user_id,
                        u.plan
                    FROM gh_issues AS i
                    JOIN gh_repos AS r
                        ON i.repo_id = r.repo_id
                    JOIN gh_users AS u
                        ON r.owner_id = u.user_id
                    WHERE r.created_at > TIMESTAMP '2023-01-01'
                      AND u.plan IN ('pro', 'enterprise')
                      AND i.state = 'open'
                ) AS sub3
                GROUP BY sub3.repo_name
            ) AS sub4
        )
        LIMIT 1
    ) AS min_open_issues,

    (
        SELECT CONCAT(repo_name, ': ', cnt)
        FROM (
            SELECT sub1.repo_name, COUNT(*) AS cnt
            FROM (
                SELECT
                    i.issue_id,
                    i.repo_id,
                    r.repo_name,
                    r.language,
                    u.user_id,
                    u.plan
                FROM gh_issues AS i
                JOIN gh_repos AS r
                    ON i.repo_id = r.repo_id
                JOIN gh_users AS u
                    ON r.owner_id = u.user_id
                WHERE r.created_at > TIMESTAMP '2023-01-01'
                  AND u.plan IN ('pro', 'enterprise')
                  AND i.state = 'open'
            ) AS sub1
            GROUP BY sub1.repo_name
        ) AS sub2
        WHERE cnt = (
            SELECT MAX(cnt)
            FROM (
                SELECT COUNT(*) AS cnt
                FROM (
                    SELECT
                        i.issue_id,
                        i.repo_id,
                        r.repo_name,
                        r.language,
                        u.user_id,
                        u.plan
                    FROM gh_issues AS i
                    JOIN gh_repos AS r
                        ON i.repo_id = r.repo_id
                    JOIN gh_users AS u
                        ON r.owner_id = u.user_id
                    WHERE r.created_at > TIMESTAMP '2023-01-01'
                      AND u.plan IN ('pro', 'enterprise')
                      AND i.state = 'open'
                ) AS sub3
                GROUP BY sub3.repo_name
            ) AS sub4
        )
        LIMIT 1
    ) AS max_open_issues;




CREATE INDEX IF NOT EXISTS idx_gh_repos_created_at
    ON gh_repos(created_at);

CREATE INDEX IF NOT EXISTS idx_gh_repos_owner_id
    ON gh_repos(owner_id);

CREATE INDEX IF NOT EXISTS idx_gh_issues_repo_id
    ON gh_issues(repo_id);

CREATE INDEX IF NOT EXISTS idx_gh_issues_state
    ON gh_issues(state);

CREATE INDEX IF NOT EXISTS idx_gh_users_plan
    ON gh_users(plan);

CREATE INDEX IF NOT EXISTS idx_gh_repos_owner_created
    ON gh_repos(owner_id, created_at);

-- Оптимізована

EXPLAIN ANALYZE
WITH filtered_issues AS (
    SELECT
        i.issue_id,
        i.repo_id,
        r.repo_name,
        r.language,
        u.user_id,
        u.plan
    FROM gh_issues AS i
    JOIN gh_repos AS r
        ON i.repo_id = r.repo_id
    JOIN gh_users AS u
        ON r.owner_id = u.user_id
    WHERE r.created_at > TIMESTAMP '2023-01-01'
      AND u.plan IN ('pro', 'enterprise')
      AND i.state = 'open'
),
repo_issue_counts AS (
    SELECT
        repo_name,
        COUNT(*) AS cnt
    FROM filtered_issues
    GROUP BY repo_name
),
ranked_repos AS (
    SELECT
        repo_name,
        cnt,
        ROW_NUMBER() OVER (ORDER BY cnt ASC, repo_name ASC) AS min_rn,
        ROW_NUMBER() OVER (ORDER BY cnt DESC, repo_name ASC) AS max_rn
    FROM repo_issue_counts
)
SELECT
    MAX(CONCAT(repo_name, ': ', cnt)) FILTER (WHERE min_rn = 1) AS min_open_issues,
    MAX(CONCAT(repo_name, ': ', cnt)) FILTER (WHERE max_rn = 1) AS max_open_issues
FROM ranked_repos;


SET enable_seqscan = off;

EXPLAIN ANALYZE
WITH filtered_issues AS (
    SELECT
        i.issue_id,
        i.repo_id,
        r.repo_name,
        r.language,
        u.user_id,
        u.plan
    FROM gh_issues AS i
    JOIN gh_repos AS r
        ON i.repo_id = r.repo_id
    JOIN gh_users AS u
        ON r.owner_id = u.user_id
    WHERE r.created_at > TIMESTAMP '2023-01-01'
      AND u.plan IN ('pro', 'enterprise')
      AND i.state = 'open'
),
repo_issue_counts AS (
    SELECT
        repo_name,
        COUNT(*) AS cnt
    FROM filtered_issues
    GROUP BY repo_name
),
ranked_repos AS (
    SELECT
        repo_name,
        cnt,
        ROW_NUMBER() OVER (ORDER BY cnt ASC, repo_name ASC) AS min_rn,
        ROW_NUMBER() OVER (ORDER BY cnt DESC, repo_name ASC) AS max_rn
    FROM repo_issue_counts
)
SELECT
    MAX(CONCAT(repo_name, ': ', cnt)) FILTER (WHERE min_rn = 1) AS min_open_issues,
    MAX(CONCAT(repo_name, ': ', cnt)) FILTER (WHERE max_rn = 1) AS max_open_issues
FROM ranked_repos;

SET enable_seqscan = on;

-- Доп

SET enable_seqscan = on;

EXPLAIN
WITH filtered_issues AS (
    SELECT
        i.issue_id,
        i.repo_id,
        r.repo_name,
        r.language,
        u.user_id,
        u.plan
    FROM gh_issues AS i
    JOIN gh_repos AS r
        ON i.repo_id = r.repo_id
    JOIN gh_users AS u
        ON r.owner_id = u.user_id
    WHERE r.created_at > TIMESTAMP '2023-01-01'
      AND u.plan IN ('pro', 'enterprise')
      AND i.state = 'open'
),
repo_issue_counts AS (
    SELECT
        repo_name,
        COUNT(*) AS cnt
    FROM filtered_issues
    GROUP BY repo_name
),
ranked_repos AS (
    SELECT
        repo_name,
        cnt,
        ROW_NUMBER() OVER (ORDER BY cnt ASC, repo_name ASC) AS min_rn,
        ROW_NUMBER() OVER (ORDER BY cnt DESC, repo_name ASC) AS max_rn
    FROM repo_issue_counts
)
SELECT
    MAX(CONCAT(repo_name, ': ', cnt)) FILTER (WHERE min_rn = 1) AS min_open_issues,
    MAX(CONCAT(repo_name, ': ', cnt)) FILTER (WHERE max_rn = 1) AS max_open_issues
FROM ranked_repos;
