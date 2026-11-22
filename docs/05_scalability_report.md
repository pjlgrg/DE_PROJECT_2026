# Blinkit on the large dataset

## Dataset and setup

We loaded the [faculty large-data release](https://github.com/edusatyaki/DBMS-Blinkit-Grocery-Delivery/releases/tag/large-data)
into a separate PostgreSQL database. The SHA-256 matched the release digest.
We used the same schema and changed the load path from `seed_data/` to
`large_data/`. All six integrity checks reported zero mismatches.

| Table | Seed rows | Large rows |
|---|---:|---:|
| cities | 10 | 10 |
| dark_stores | 120 | 2,400 |
| categories | 12 | 12 |
| products | 1,500 | 30,000 |
| store_inventory | 126,000 | 2,998,800 |
| customers | 40,000 | 800,000 |
| riders | 1,800 | 36,000 |
| orders | 150,000 | 3,000,000 |
| order_items | 675,000 | 10,994,856 |
| inventory_movements | 90,000 | 1,465,297 |
| **Total** | **1,084,442** | **19,327,375** |

Orders grew 20× and order items grew about 16.3×. We ran the optimized SQL
three times per query on both datasets on 23 November 2026. The environment
was PostgreSQL 17.12 on a MacBook Pro M4 with 16 GB RAM. We used the same
Asia/Kolkata timezone, 4 MB work_mem and 128 MB shared buffers on both.
W01–W05 rolled back. The contents of the three affected tables matched
before and after on both databases.

## Results

Each query ID links to its large-data plan. The times are means in ms.
The optimized seed times come from the [seed run](../benchmarks/results/optimized/summary.csv).
The [large summary](../benchmarks/results/large/summary.csv) has all 30 results.
We met **30 of 30** large-data targets.

| Query | Optimized seed (ms) | Optimized large (ms) | Growth | Target (ms) | Meets target |
|---|---:|---:|---:|---:|---|
| [R01](../benchmarks/results/large/R01.txt) | 0.062 | 0.408 | 6.58× | < 5 | Yes |
| [R02](../benchmarks/results/large/R02.txt) | 0.204 | 1.747 | 8.56× | < 5 | Yes |
| [R03](../benchmarks/results/large/R03.txt) | 0.244 | 0.916 | 3.75× | < 5 | Yes |
| [R04](../benchmarks/results/large/R04.txt) | 0.127 | 0.892 | 7.02× | < 5 | Yes |
| [R05](../benchmarks/results/large/R05.txt) | 0.083 | 0.039 | 0.47× | < 5 | Yes |
| [R06](../benchmarks/results/large/R06.txt) | 0.154 | 0.131 | 0.85× | < 5 | Yes |
| [R07](../benchmarks/results/large/R07.txt) | 0.092 | 0.081 | 0.88× | < 5 | Yes |
| [R08](../benchmarks/results/large/R08.txt) | 1.851 | 19.355 | 10.46× | < 5,000 | Yes |
| [R09](../benchmarks/results/large/R09.txt) | 0.333 | 2.102 | 6.31× | < 5 | Yes |
| [R10](../benchmarks/results/large/R10.txt) | 5.903 | 48.768 | 8.26× | < 5,000 | Yes |
| [R11](../benchmarks/results/large/R11.txt) | 0.206 | 0.310 | 1.50× | < 250 | Yes |
| [R12](../benchmarks/results/large/R12.txt) | 31.234 | 34.343 | 1.10× | < 250 | Yes |
| [R13](../benchmarks/results/large/R13.txt) | 2.949 | 27.544 | 9.34× | < 250 | Yes |
| [R14](../benchmarks/results/large/R14.txt) | 22.203 | 394.176 | 17.75× | < 5,000 | Yes |
| [R15](../benchmarks/results/large/R15.txt) | 0.173 | 0.991 | 5.73× | < 250 | Yes |
| [R16](../benchmarks/results/large/R16.txt) | 34.715 | 395.326 | 11.39× | < 5,000 | Yes |
| [R17](../benchmarks/results/large/R17.txt) | 18.367 | 441.884 | 24.06× | < 5,000 | Yes |
| [R18](../benchmarks/results/large/R18.txt) | 1.750 | 5.440 | 3.11× | < 250 | Yes |
| [R19](../benchmarks/results/large/R19.txt) | 21.674 | 340.705 | 15.72× | < 5,000 | Yes |
| [R20](../benchmarks/results/large/R20.txt) | 2.080 | 49.143 | 23.63× | < 5,000 | Yes |
| [R21](../benchmarks/results/large/R21.txt) | 0.435 | 1.216 | 2.80× | < 5 | Yes |
| [R22](../benchmarks/results/large/R22.txt) | 12.803 | 13.295 | 1.04× | < 250 | Yes |
| [R23](../benchmarks/results/large/R23.txt) | 0.126 | 0.148 | 1.17× | < 5 | Yes |
| [R24](../benchmarks/results/large/R24.txt) | 0.199 | 0.231 | 1.16× | < 250 | Yes |
| [R25](../benchmarks/results/large/R25.txt) | 13.629 | 252.206 | 18.51× | < 5,000 | Yes |
| [W01](../benchmarks/results/large/W01.txt) | 0.891 | 1.437 | 1.61× | < 5 | Yes |
| [W02](../benchmarks/results/large/W02.txt) | 0.477 | 0.521 | 1.09× | < 5 | Yes |
| [W03](../benchmarks/results/large/W03.txt) | 0.649 | 0.745 | 1.15× | < 5 | Yes |
| [W04](../benchmarks/results/large/W04.txt) | 0.672 | 0.836 | 1.24× | < 5 | Yes |
| [W05](../benchmarks/results/large/W05.txt) | 11.906 | 644.641 | 54.14× | < 1,000 | Yes |
| **Total** | **186.191** | **2679.577** | **14.39×** | | |

## What grew and why

| Growth band | Queries | What we saw |
|---|---|---|
| Up to 2× | R05, R06, R07, R11, R12, R22, R23, R24, W01, W02, W03, W04 | Mostly key lookups and small updates. R22 still skips 100,000 entries in the time index, so the amount of index work stays close. |
| 2× to 10× | R01, R02, R03, R04, R09, R10, R13, R15, R18, R21 | Larger catalogues and bigger local working sets. Index lookups still limit the number of matching rows. |
| 10× to 20× | R08, R14, R16, R19, R25 | Reports, joins or grouping over a large share of the input. R19 has more June order lines to add up. |
| More than 20× | R17, R20, W05 | More data to read or group in R17 and R20. W05 visits and marks 979,471 movement rows for deletion and dirties many buffers. |

R22 keeps OFFSET so the request can jump directly to page 4,001. The time
index removes the big sort. For next-page browsing, I would keep the last
seen `(placed_at, order_id)` in a cursor and continue from that pair with a
matching index. A cursor needs the previous page's last row. We retained
the supplied query's order and offset for this comparison.

## What changed at scale

R13 initially missed the 250 ms target. The first NULL-safe version averaged
598.544 ms on large data. It returned 26,601 rows, but it chose a Merge Anti
Join and did an order ID lookup for each non-NULL substitution:

```text
Merge Anti Join
  Gather Merge
    Nested Loop
      Parallel Index Only Scan on order_items_substitute_order_idx
      Index Scan on orders_pkey (loops=244439)
Execution Time: 678.422 ms (first run)
```

We changed it to build distinct June substitute IDs once. It used a date
range scan and a Hash Anti Join against that small set:

```text
Hash Anti Join
  CTE used_products
    HashAggregate (rows=2803)
      ... Parallel Hash Join, using the order-date range
  Seq Scan on products
  Hash on used_products
Execution Time: 29.435 ms (first run)
```

The final three-run average was 27.544 ms. The corrected reference
and final query matched in both directions on 26,601 products.
[Full final plan](../benchmarks/results/large/R13.txt)

W05 passed in the final run at 644.641 ms, but it varies most with
cache and writes. Its first run before the R13 change took 1,536.446 ms,
and the other two took about 647 and 656 ms. There was no change to W05.
Deleting about two-thirds of the table row by row is still a risk under
load. We would change how we store old movements at higher scale.

## Storage

Table and index totals below cover the ten Blinkit tables. Database size
also includes PostgreSQL catalogues and other database objects. All sizes
are MiB (1 MiB = 1,048,576 bytes).

| Table | Seed table | Seed indexes | Large table | Large indexes |
|---|---:|---:|---:|---:|
| categories | 0.01 | 0.03 | 0.01 | 0.03 |
| cities | 0.01 | 0.03 | 0.01 | 0.03 |
| customers | 3.30 | 3.50 | 66.67 | 77.38 |
| dark_stores | 0.04 | 0.03 | 0.23 | 0.16 |
| inventory_movements | 5.53 | 4.13 | 85.55 | 66.70 |
| order_items | 33.91 | 29.36 | 551.05 | 476.48 |
| orders | 17.28 | 19.94 | 341.37 | 395.84 |
| products | 0.19 | 0.26 | 3.08 | 3.73 |
| riders | 0.16 | 0.18 | 2.66 | 2.55 |
| store_inventory | 7.53 | 2.73 | 172.57 | 64.30 |
| **Total** | **67.96** | **60.20** | **1,223.20** | **1,087.20** |

Full database size was **136.30 MiB** for seed and **2,318.45 MiB**
for large. At 100× the seed, we would have about 15 million orders and
67.5 million order lines. Using the measured large order_items heap and
index size of 1,027.53 MiB for 10.99 million rows,
that table alone could use roughly 6.2 GiB
before extra growth, overhead or replication.

## How we would handle 100×

- **Partitioning.** I would start with hash partitions on order ID for
  order_items, since lookup and checkout already use that key. It keeps the
  lines for an order together. The primary key includes order_id, as
  PostgreSQL requires every partition key column to be in the primary key.
  Our [SQL demonstration](../sql/08_partitioning.sql) loaded 27,000 sample
  rows into four partitions inside a rollback. The order_id=1027 plan used
  only p0 and returned three rows. Filtering only by quantity scanned all
  four partitions. Hash partitioning helps lookups. It gives no shortcut to
  wide date reports without an order ID filter.
- **Sharding.** We would route store inventory, orders and riders by the
  store's city. Checkout and dispatch can stay in one city when the store
  is known. R01 routes by location. R16 cohorts need the earliest order
  per customer across cities, and R17/R20 finance roll up across cities.
  We would merge city-level aggregates and keep shared catalogue IDs the
  same between cities.
- **Primary and replicas.** We would keep R01–R07, R09, R21, R23 and all
  writes on the primary for current stock, dispatch and customer screens.
  A replica can run R08, R10–R20, R22, R24 and R25 if it is current enough.
  If support needs a just-placed order, we would use the primary for R22.
  R12 recommendations and settled R19 category totals can be cached for
  short periods. The benchmark used PostgreSQL only.
- **Maintenance.** At 100×, I would try a lower per-table autovacuum scale
  factor on order_items. At 67.5 million rows, 2% is about 1.35 million
  changed rows and 1% is 675,000. We would check dead rows and planner
  statistics before adjusting the thresholds. For W05, range-partition
  movement history by month, archive old months, then remove expired
  partitions after the retention cutoff. Daily summaries for completed
  periods could refresh after closing time.

The partitioning run gave these plan lines:

```text
Index Scan using order_items_p0_pkey on order_items_p0
  Index Cond: (order_id = 1027)
  Execution Time: 0.006 ms

Append  (filter: quantity_ordered > 1)
  Seq Scan on order_items_p0
  Seq Scan on order_items_p1
  Seq Scan on order_items_p2
  Seq Scan on order_items_p3
  Execution Time: 1.892 ms
```

## Where we stand

We reached all published latency targets for the supplied data in this
single-laptop run. R17 and R19 show where analytics reads grow with the
data. W05 is still heavy, and we have not measured simultaneous orders
or a 100× workload. Those tests would be needed before using this design
for a production store network.
