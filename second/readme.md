# 1 - 40 рядки
Створюємо 4 таблиці: gh_users, gh_repos, gh_issues, gh_pull_requests. DROP TABLE щоб не було конфліктів. UUID як PRIMARY KEY у users, SERIAL у repos/issues/prs. FOREIGN KEY на owner_id та repo_id щоб зв'язати таблиці між собою. CHECK обмеження на status (open/closed/merged) та plan (free/pro/enterprise)

# 42 - 143 рядки
main.py генерує фейкові дані за допомогою Faker. 50к юзерів, 100к репозиторіїв, 500к issues, 300к PRs. CHUNK_SIZE = 10000 шоб не тримати все в пам'яті. Використовуємо execute_values для швидкої вставки порціями

# 145 - 220 рядки
Неоптимізований запит. Тут та сама 3-таблична JOIN (issues -> repos -> users) повторюється 8 разів у вкладених підзапитах для знаходження min/max кількості open issues по репозиторіях. Кожен підзапит сканує таблиці заново

# 222 - 240 рядки
Індекси. 6 штук: на created_at, owner_id, repo_id, state, plan + composite (owner_id, created_at). Це дозволяє планеру використовувати Index Scan замість Seq Scan

# 242 - 290 рядки
Оптимізований запит. CTE filtered_issues робить JOIN один раз. repo_issue_counts рахує GROUP BY. ranked_repos використовує ROW_NUMBER() для ранжування. FILTER (WHERE ...) витягує min/max за один прохід

# 292 - end
Bonus: SET enable_seqscan = off показує як планер реагує на обмеження. ржачне те, що планер знайшов гірший план з Parallel Hash Join замість індексу :v

# Аналіз

Неоптимізований запит (240ms):
Таблиця gh_issues має 500к рядків. Без індексу на стовпчик state планер робить паралельне сканування - проглядає всі 500к рядків і фільтрує тільки "open" вручну
Та сама 3-таблична JOIN (issues -> repos -> users) виконується 4 рази окремо (для кожного підзапиту). Кожен раз сканує таблиці заново, будує хеш таблицю, робить вкладений цикл. 4 * (Seq Scan + Join) = багато роботи
- Результуючі підзапити для MIN/MAX теж повторюють ту саму роботу ще 2 рази

Оптимізований запит (125ms):
Індекс idx_gh_issues_state дозволяє робити Bitmap Index Scan замість Seq Scan. PostgreSQL знає де рядки state мають значення open і бере тільки їх
filtered_issues (він і є ж CTE) - робить JOIN один раз. Всі інші CTE теж читають вже готовий результат
ROW_NUMBER() замість вкладених підзапитів з MIN/MAX - один прохід по даних замість чотирьох
FILTER (WHERE ...) витягує min/max результат з одного запиту замість двох окремих
