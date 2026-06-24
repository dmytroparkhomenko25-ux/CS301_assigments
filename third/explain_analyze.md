### План виконання

```text
 Hash Join  (cost=27.09..41.32 rows=7 width=274) (actual time=0.048..0.052 rows=2 loops=1)
   Hash Cond: (p.product_id = oi.product_id)
   ->  Seq Scan on products p  (cost=0.00..13.00 rows=300 width=222) (actual time=0.008..0.009 rows=5 loops=1)
   ->  Hash  (cost=27.00..27.00 rows=7 width=28) (actual time=0.019..0.019 rows=2 loops=1)
         Buckets: 1024  Batches: 1  Memory Usage: 9kB
         ->  Seq Scan on order_items oi  (cost=0.00..27.00 rows=7 width=28) (actual time=0.006..0.008 rows=2 loops=1)
               Filter: (order_id = 1)
               Rows Removed by Filter: 3
 Planning Time: 0.956 ms
 Execution Time: 0.110 ms
```

### Пояснення виконання

PostgreSQL виконує цей запит за допомогою Hash Join для об'єднання рядків з таблиць order_items та products на основі відповідних product_id.
Спочатку виконується послідовне сканування таблиці order_items (oi) для вибірки записів з order_id = 1.
Потім у пам'яті будується хеш-таблиця з цих відфільтрованих рядків.
Далі PostgreSQL виконує послідовне сканування (Seq Scan) таблиці products (p) та шукає відповідні ключі з'єднання в хеш-таблиці.
Послідовне сканування обрано для обох таблиць замість сканування за індексом через те, що бази даних містять мінімальну кількість рядків (5 продуктів та 5 позицій замовлень), тому зчитати їх повністю швидше, ніж шукати за індексом.
