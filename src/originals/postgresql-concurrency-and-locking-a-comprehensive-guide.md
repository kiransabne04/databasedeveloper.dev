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
    
* **FOR NO KEY UPDATE:** Similar to `FOR UPDATE`, but allows non-key columns to be updated by other transactions.
    
* **FOR SHARE:** Prevents modifications but allows other transactions to acquire a shared lock.
    
* **FOR KEY SHARE:** Allows transactions to modify non-key columns but prevents deletion or key updates.


<aside class="correction"><strong>Correction (October 2026):</strong> <code>FOR NO KEY UPDATE</code> does not let other transactions update the row. It blocks their <code>UPDATE</code>, <code>DELETE</code>, <code>FOR UPDATE</code> and <code>FOR SHARE</code>, and allows only <code>FOR KEY SHARE</code>, which foreign-key checks take. That is why ordinary non-key updates use it and do not block inserts into referencing tables. Tested on PostgreSQL 17.</aside>

    

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
    
* **EXCLUSIVE:** Blocks all other operations except `SELECT`.
    
* **ACCESS EXCLUSIVE:** Blocks all operations, including `SELECT`.
    

#### Real-World Application:

* **Schema Migrations:** When altering table structure, acquiring an `ACCESS EXCLUSIVE` lock prevents data modifications during the schema update.
    

```sql
BEGIN;
LOCK TABLE orders IN EXCLUSIVE MODE;
-- Blocks other operations until the lock is released.
```


<aside class="correction"><strong>Correction (October 2026):</strong> <code>EXCLUSIVE</code> still allows plain <code>SELECT</code> (<code>ACCESS SHARE</code>); it blocks writes and row locks. Most <code>ALTER TABLE</code> forms, <code>DROP</code>, <code>TRUNCATE</code>, <code>VACUUM FULL</code> and <code>CLUSTER</code> take <code>ACCESS EXCLUSIVE</code>, which blocks reads too. A queued <code>ACCESS EXCLUSIVE</code> request also blocks new readers behind it: see the <a href="/case-studies/lab-lock-queue">lock-queue lab</a>. Set <code>lock_timeout</code> on migrations.</aside>


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

* **Session-level:** Locks held until the session ends.
    
* **Transaction-level:** Locks held until the transaction commits or rolls back.
    

#### Real-World Application:

* **Distributed Systems Coordination:** Advisory locks help coordinate processes accessing shared resources.
    

```sql
SELECT pg_advisory_lock(12345);
-- Released when the transaction ends.
```


<aside class="correction"><strong>Correction (October 2026):</strong> <code>pg_advisory_lock()</code> takes a session-level lock. It stays held after <code>COMMIT</code> or <code>ROLLBACK</code> until <code>pg_advisory_unlock()</code> or the session ends, which matters with connection pools. Use <code>pg_advisory_xact_lock()</code> for a lock released at transaction end.</aside>


#### Performance Implication:

* **Lightweight but requires careful management to avoid deadlocks.**
    

---

### Optimistic vs. Pessimistic Locking

#### Optimistic Locking:

* Assumes minimal conflicts and only checks for conflicts at the time of commit.
    
* **Implementation:** Use versioning or timestamps.
    

```sql
UPDATE products SET price = 200 WHERE product_id = 1 AND updated_at = '2025-01-01 10:00:00';
```


<aside class="correction"><strong>Correction (October 2026):</strong> The application must check the affected row count: zero rows means another writer changed the row first. The statement should also set <code>updated_at</code> (or increment a version column), otherwise the next writer cannot detect this change.</aside>


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

```sql
SELECT * FROM pg_stat_activity WHERE wait_event_type = 'Lock';
```


<aside class="correction"><strong>Correction (October 2026):</strong> This query finds sessions waiting on heavyweight locks, which is usually blocking, not deadlock. PostgreSQL detects deadlocks itself after <code>deadlock_timeout</code> and cancels one transaction with <code>ERROR: deadlock detected</code>. Use <code>pg_blocking_pids(pid)</code> to find the blocker; the production notes below show a query.</aside>


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
| Table-Level (EXCLUSIVE) | Table | Yes | Yes | Schema modifications, migrations |
| Advisory Locks | Application | No | No | Application-level coordination |
| Access Share | Table | No | No | `SELECT` statements |
| Row Exclusive | Table | No | Yes | `INSERT`, `UPDATE`, `DELETE` |
| Access Exclusive | Table | Yes | Yes | Full table modifications |


<aside class="correction"><strong>Correction (October 2026):</strong> The table-level <code>EXCLUSIVE</code> row is wrong: it does not block plain reads. Schema migrations usually take <code>ACCESS EXCLUSIVE</code>, which does. Advisory locks block other sessions requesting the same advisory key. Tested on PostgreSQL 17.</aside>


---

### Conclusion

Locking in PostgreSQL is a powerful mechanism that, when used correctly, can ensure data integrity and consistency. By understanding the various types of locks, their appropriate use cases, and how to manage deadlocks, developers can design efficient and resilient database applications. Optimistic and pessimistic locking strategies provide additional tools to handle concurrency effectively.