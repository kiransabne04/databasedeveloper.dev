### Introduction to Locking in PostgreSQL

Locking in PostgreSQL is essential for ensuring data consistency and isolation across concurrent transactions. PostgreSQL uses multi-version concurrency control (MVCC) to allow multiple transactions to access data simultaneously, but certain operations still require explicit locking to prevent conflicts.

Understanding the types of locks, their use cases, and potential performance implications is critical for optimizing database performance and avoiding deadlocks.

---

### Types of Locks in PostgreSQL

PostgreSQL provides a variety of locks to handle different levels of data protection. These locks can be broadly categorized as:

* **Row-Level Locks**
    
* **Table-Level Locks**
    
* **Page-Level Locks**
    
* **Advisory Locks**
    
* **Deadlocks and Prevention**
    

Let's dive into each lock type with detailed explanations, real-world examples, and performance implications.

---

### 1\. Row-Level Locks

Row-level locks allow fine-grained control over individual rows, ensuring minimal impact on other parts of the table.

#### Types of Row-Level Locks:

* **FOR UPDATE:** Prevents other transactions from modifying or locking the same row until the current transaction completes.
    
* **FOR NO KEY UPDATE:** Similar to `FOR UPDATE`, but weaker: it still blocks other transactions' `UPDATE`, `DELETE`, `FOR UPDATE` and `FOR SHARE` on the row, while allowing `FOR KEY SHARE`. Ordinary `UPDATE`s that do not change a key column take this lock, so they do not block foreign-key checks from referencing tables.
    
* **FOR SHARE:** Prevents modifications but allows other transactions to acquire a shared lock.
    
* **FOR KEY SHARE:** The weakest row lock, taken by foreign-key checks. Other transactions can still update non-key columns, but cannot delete the row or change its key.
    

#### Real-World Application:

* **Order Management Systems:** When updating the status of an order, acquiring a `FOR UPDATE` lock ensures no other transaction modifies or deletes the order concurrently.
    

```sql
BEGIN;
SELECT * FROM orders WHERE order_id = 101 FOR UPDATE;
-- Another transaction trying to update the same row will wait until the lock is released.
```

#### Edge Case:

* **Deadlocks:** Occurs when two transactions hold locks that the other needs, leading to a stalemate.
    
* **Performance Implication:** Row-level locks scale well, but frequent locking can lead to increased contention and deadlocks.
    

---

### 2\. Table-Level Locks

Table-level locks apply to entire tables, preventing or allowing certain operations to be performed concurrently.

#### Types of Table-Level Locks:

* **ACCESS SHARE:** Acquired by `SELECT` statements.
    
* **ROW SHARE:** Acquired by `SELECT ... FOR UPDATE` or `SELECT ... FOR SHARE`.
    
* **ROW EXCLUSIVE:** Acquired by `INSERT`, `UPDATE`, and `DELETE`.
    
* **SHARE UPDATE EXCLUSIVE:** Used by `VACUUM` operations.
    
* **SHARE:** Allows multiple transactions to read but not write.
    
* **EXCLUSIVE:** Blocks writes and row locks; only plain `SELECT` (`ACCESS SHARE`) can run alongside it.
    
* **ACCESS EXCLUSIVE:** Blocks all operations, including `SELECT`. Taken by most `ALTER TABLE` forms, `DROP`, `TRUNCATE`, `VACUUM FULL` and `CLUSTER`.
    

#### Real-World Application:

* **Schema Migrations:** Most `ALTER TABLE` operations take an `ACCESS EXCLUSIVE` lock, which blocks reads and writes during the schema change. A waiting `ACCESS EXCLUSIVE` request also queues new readers behind it, so set `lock_timeout` on migrations.
    
* **Bulk Corrections:** `EXCLUSIVE` mode blocks concurrent writes while still allowing plain reads.
    

```sql
BEGIN;
LOCK TABLE orders IN EXCLUSIVE MODE;
-- Blocks writes and row locks until the transaction ends; plain SELECTs still run.
```

#### Edge Case:

* **Performance Implication:** Table locks can lead to high contention in multi-user environments.
    
* **Deadlocks:** High risk when combined with row locks.
    

---

### 3\. Page-Level Locks

Page-level locks are used internally by PostgreSQL during index and table access operations.

* **Page Locks:** Implicitly managed by PostgreSQL and not directly accessible to users.
    
* **Use Case:** Prevents data corruption during index writes.
    

#### Real-World Application:

* **Index Maintenance:** During large data insertions, page locks ensure index consistency.
    

---

### 4\. Advisory Locks

Advisory locks provide application-level locking mechanisms that are independent of the standard SQL locks.

* **Session-level:** Locks held until explicitly released with `pg_advisory_unlock()` or the session ends. They survive `COMMIT` and `ROLLBACK`, which matters with connection pools.
    
* **Transaction-level:** Locks taken with `pg_advisory_xact_lock()` are held until the transaction commits or rolls back.
    

#### Real-World Application:

* **Distributed Systems Coordination:** Advisory locks help coordinate processes accessing shared resources.
    

```sql
SELECT pg_advisory_xact_lock(12345);
-- Released when the transaction ends.

SELECT pg_advisory_lock(12345);
-- Session-level: held until pg_advisory_unlock(12345) or disconnect.
SELECT pg_advisory_unlock(12345);
```

#### Performance Implication:

* **Lightweight but requires careful management to avoid deadlocks.**
    

---

### Optimistic vs. Pessimistic Locking

#### Optimistic Locking:

* Assumes minimal conflicts and only checks for conflicts at the time of commit.
    
* **Implementation:** Use versioning or timestamps.
    

```sql
UPDATE products
SET price = 200, updated_at = now()
WHERE product_id = 1 AND updated_at = '2025-01-01 10:00:00';
-- 0 rows updated means another transaction changed the row first: reload and retry.
```

#### Real-World Application:

* **E-commerce:** Prevents overwriting of product information by checking for updates before committing changes.
    

#### Pessimistic Locking:

* Acquires locks at the beginning of a transaction to prevent other transactions from modifying the data.
    
* **Implementation:**
    

```sql
BEGIN;
SELECT * FROM products WHERE product_id = 1 FOR UPDATE;
```

#### Real-World Application:

* **Banking Systems:** Ensures account balances are not modified by multiple transactions simultaneously.
    

---

### Deadlocks and Prevention

#### Detecting Deadlocks:

PostgreSQL detects deadlocks itself: after `deadlock_timeout` (1 second by default) it cancels one of the transactions with `ERROR: deadlock detected`, so the application must retry it. Sessions that are blocked but not deadlocked show up as lock waits, together with the sessions blocking them:

```sql
SELECT pid, pg_blocking_pids(pid) AS blocked_by,
       now() - xact_start AS xact_age, left(query, 80) AS query
FROM pg_stat_activity
WHERE wait_event_type = 'Lock';
```

#### Log Monitoring:

* Deadlocks are logged in the PostgreSQL log.
    
* **Location:** `pg_log` or `log_directory`.
    
* **Command:**
    

```bash
cat /var/log/postgresql/postgresql.log | grep 'deadlock'
```

#### Real-World Application:

* **High-Transaction Systems:** Continuously monitor and resolve deadlocks to prevent transaction failures.
    

#### Preventing Deadlocks:

* **Order Transactions Consistently:** Always access tables and rows in the same order.
    
* **Keep Transactions Short:** Minimize the duration of locks.
    
* **Use NOWAIT/ SKIP LOCKED:**
    

```sql
SELECT * FROM orders FOR UPDATE NOWAIT;
```

---

### Comparison of Lock Types

| Lock Type | Scope | Blocks Read | Blocks Write | Use Case |
| --- | --- | --- | --- | --- |
| Row-Level (FOR UPDATE) | Row | No | Yes | Row updates and deletions |
| Table-Level (EXCLUSIVE) | Table | No | Yes | Blocking writes while allowing reads |
| Advisory Locks | Application | No | No (blocks only the same advisory key) | Application-level coordination |
| Access Share | Table | No | No | `SELECT` statements |
| Row Exclusive | Table | No | Yes | `INSERT`, `UPDATE`, `DELETE` |
| Access Exclusive | Table | Yes | Yes | Schema changes, `DROP`, `TRUNCATE`, `VACUUM FULL`, `CLUSTER` |

---

### Conclusion

Locking in PostgreSQL is a powerful mechanism that, when used correctly, can ensure data integrity and consistency. By understanding the various types of locks, their appropriate use cases, and how to manage deadlocks, developers can design efficient and resilient database applications. Optimistic and pessimistic locking strategies provide additional tools to handle concurrency effectively.