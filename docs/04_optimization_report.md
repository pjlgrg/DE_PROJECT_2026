# Blinkit optimization

## How we measured

We used the original CP2 baseline from 17 November and ran the optimized
queries on a separate copy of the seed database on 23 November. Both runs
used the same MacBook Pro M4, PostgreSQL 17.12 and the Asia/Kolkata timezone.
We took the average of three `EXPLAIN (ANALYZE, BUFFERS)` runs per query,
following the tracker. The write queries rolled back. We checked the row
contents of orders, store inventory and inventory movements afterwards.

We added the indexes in [05_indexes.sql](../sql/05_indexes.sql) and rewrote
six reads in [06_optimized_queries.sql](../sql/06_optimized_queries.sql).
The [CP2 baseline](03_baseline_timings.md) and the supplied SQL are available
for comparison. Timings can vary when index pages first come into memory.

## Before and after

Each query ID links to its optimized plan. A negative percentage means the
measured average went up. We measured only SQL execution.

| Query | Before (ms) | What cost time | Change | After (ms) | Improvement | Result check |
|---|---:|---|---|---:|---:|---|
| [R01](../benchmarks/results/optimized/R01.txt) | 0.063 | Store location filter | Kept the scan on a small table | 0.062 | +1.6% | Same SQL |
| [R02](../benchmarks/results/optimized/R02.txt) | 0.237 | Finds dairy and joins store stock | Added an index on product category | 0.204 | +13.9% | Same SQL |
| [R03](../benchmarks/results/optimized/R03.txt) | 0.401 | Product names scanned for a substring | GIN trigram index for the name search | 0.244 | +39.2% | Same SQL |
| [R04](../benchmarks/results/optimized/R04.txt) | 0.093 | Checks the product in the city's stores | Kept the inventory key lookup | 0.127 | -36.6% | Same SQL |
| [R05](../benchmarks/results/optimized/R05.txt) | 0.106 | Four targeted stock lookups | Kept the inventory primary key | 0.083 | +21.7% | Same SQL |
| [R06](../benchmarks/results/optimized/R06.txt) | 4.851 | Reads orders and sorts matches | Customer and time index gives the latest order | 0.154 | +96.8% | Same SQL |
| [R07](../benchmarks/results/optimized/R07.txt) | 5.929 | Reads orders to find the open ones | Partial index stores the open rows by store and time | 0.092 | +98.4% | Same SQL |
| [R08](../benchmarks/results/optimized/R08.txt) | 7.575 | Scans orders for June deliveries | Time index finds the month | 1.851 | +75.6% | Same SQL |
| [R09](../benchmarks/results/optimized/R09.txt) | 0.293 | Reads stock and filters its quantity | Kept the inventory key by store | 0.333 | -13.7% | Same SQL |
| [R10](../benchmarks/results/optimized/R10.txt) | 5.249 | Reads movements and joins product/category | Kept the scan for the monthly report | 5.903 | -12.5% | Same SQL |
| [R11](../benchmarks/results/optimized/R11.txt) | 6.097 | Scans orders for one store | Store and time index finds the store's June orders | 0.206 | +96.6% | Same SQL |
| [R12](../benchmarks/results/optimized/R12.txt) | 7.991 | Reads order items to find one product | Product and order index for the first side of the join | 31.234 | -290.9% | Same SQL |
| [R13](../benchmarks/results/optimized/R13.txt) | 20.228 | NOT IN sees NULL and returns zero | Builds the set of June substitutes, then uses NOT EXISTS | 2.949 | +85.4% | Corrected (details below) |
| [R14](../benchmarks/results/optimized/R14.txt) | 19.288 | Joins order items to June orders | Time index narrows orders, with a wider item scan still in the plan | 22.203 | -15.1% | Same SQL |
| [R15](../benchmarks/results/optimized/R15.txt) | 8.597 | DATE(placed_at) is applied to every row | Half-open date range can use the time index | 0.173 | +98.0% | Same rows |
| [R16](../benchmarks/results/optimized/R16.txt) | 32.303 | Second orders scan for June activity | Finds the first order and any June activity in one grouping | 34.715 | -7.5% | Same rows |
| [R17](../benchmarks/results/optimized/R17.txt) | 31.591 | EXTRACT(YEAR) scans order dates | Half-open range for 2026 | 18.367 | +41.9% | Same rows |
| [R18](../benchmarks/results/optimized/R18.txt) | 5.554 | Finds recent orders and items in a store | Store and time range index | 1.750 | +68.5% | Same SQL |
| [R19](../benchmarks/results/optimized/R19.txt) | 1969.629 | Scans order items once per category product | Aggregates June lines once, then joins to the category | 21.674 | +98.9% | Same rows |
| [R20](../benchmarks/results/optimized/R20.txt) | 10.154 | DATE cast in the filter scans orders | Time range narrows June before daily grouping | 2.080 | +79.5% | Same rows |
| [R21](../benchmarks/results/optimized/R21.txt) | 5.031 | Scans riders and orders for activity | Partial active-rider index and rider/date index | 0.435 | +91.4% | Same SQL |
| [R22](../benchmarks/results/optimized/R22.txt) | 48.082 | Sort spills to disk before skipping 100,000 rows | Walks the time index backward and keeps the same page | 12.803 | +73.4% | Same SQL |
| [R23](../benchmarks/results/optimized/R23.txt) | 0.023 | Unique SKU lookup already works | Kept the SKU index | 0.126 | -447.8% | Same SQL |
| [R24](../benchmarks/results/optimized/R24.txt) | 2.806 | Scans movements for restocks | Partial restock index by store and time | 0.199 | +92.9% | Same SQL |
| [R25](../benchmarks/results/optimized/R25.txt) | 15.461 | Reads orders/customers and ranks the result | Time index narrows the order date range | 13.629 | +11.8% | Same SQL |
| [W01](../benchmarks/results/optimized/W01.txt) | 0.611 | One insert with foreign-key checks | Kept the insert. It now maintains added order indexes | 0.891 | -45.8% | Same SQL |
| [W02](../benchmarks/results/optimized/W02.txt) | 11.751 | Scans orders for the latest open order | Partial store/order ID index finds the newest candidate | 0.477 | +95.9% | Same SQL |
| [W03](../benchmarks/results/optimized/W03.txt) | 13.036 | Scans a long stretch of the order key for PACKING | Partial packing and active-rider indexes find the first matches | 0.649 | +95.0% | Same SQL |
| [W04](../benchmarks/results/optimized/W04.txt) | 0.706 | Finds low stock within one store | Kept the inventory key by store | 0.672 | +4.8% | Same SQL |
| [W05](../benchmarks/results/optimized/W05.txt) | 11.137 | Deletes a large share of older movements | Kept a sequential scan for the batch | 11.906 | -6.9% | Same SQL |
| **Total** | **2244.873** | | | **186.191** | **+91.7%** | |

## Checking the rewritten reads

We compared row counts and ran `EXCEPT ALL` each way. That also catches
duplicate rows. R15, R16, R17 and R20 kept the same row order. R19 kept the
same descending sort by units sold, with free ordering between equal totals.
We also compared all 25 reads on the two seed databases. The only change
to which rows came back was the R13 fix.

| Query | Original or reference rows | Optimized rows | Only on the left | Only on the right |
|---|---:|---:|---:|---:|
| R13 | 1,250 | 1,250 | 0 | 0 |
| R15 | 36 | 36 | 0 | 0 |
| R16 | 18 | 18 | 0 | 0 |
| R17 | 60 | 60 | 0 | 0 |
| R19 | 125 | 125 | 0 | 0 |
| R20 | 30 | 30 | 0 | 0 |

R13 is a bug fix. The original used `NOT IN` and got zero rows. If a value
is absent from the list but the list includes NULL, SQL cannot prove the
value differs from every entry. The condition becomes unknown. The corrected
reference filters NULL out of the original subquery. Our version builds a
list of distinct June substitute IDs and uses `NOT EXISTS`. Both corrected
versions return 1,250 rows in the seed data and 26,601 in the large data.

## Five biggest time savings

The linked raw plans contain all three runs. These are the main changes in
the plans, ordered by milliseconds saved.

| Query | Before plan | After plan |
|---|---|---|
| R19 | [1969.629 ms](../benchmarks/results/baseline/R19.txt). The correlated aggregate ran 125 times. It scanned order_items for each product. | [21.674 ms](../benchmarks/results/optimized/R19.txt). The June orders join and product totals run once. A left join keeps products with zero sales. |
| R22 | [48.082 ms](../benchmarks/results/baseline/R22.txt). Seq Scan on orders, then external merge sort, then limit and offset. | [12.803 ms](../benchmarks/results/optimized/R22.txt). Backward Index Scan on orders_time_idx feeds the limit directly. |
| R13 | [20.228 ms](../benchmarks/results/baseline/R13.txt). Seq Scan on products with a hashed NOT IN subplan. The result contained zero rows. | [2.949 ms](../benchmarks/results/optimized/R13.txt). Builds the June substitute set first, then a Hash Anti Join removes just the matching products. |
| R17 | [31.591 ms](../benchmarks/results/baseline/R17.txt). Seq Scan on orders and an EXTRACT filter. | [18.367 ms](../benchmarks/results/optimized/R17.txt). Date range and hash/group operations over the filtered orders. |
| W03 | [13.036 ms](../benchmarks/results/baseline/W03.txt). orders_pkey filters past 149,895 rows before the first PACKING order in run 1. | [0.649 ms](../benchmarks/results/optimized/W03.txt). Index Only Scan on orders_packing_id_idx starts at the first eligible row. A partial rider index handles the rider lookup. |

## Write costs and slower queries

- W01 went from 0.611 to 0.891 ms. A new order also needs entries
  in the added order indexes it matches. The increase is small on this data.
- W02 and W03 spent less time finding the rows to update. W04 used the
  existing inventory key and stayed close to the old time.
- W05 went from 11.137 to 11.906 ms. The plan still scans and
  touches many rows. Run-to-run variation prevents assigning the difference
  to one index. A committed deletion also leaves index cleanup for VACUUM.
- R12 had a slow first run (89.397 ms, with 368 shared pages read).
  The next two took 1.831 and 2.475 ms. The indexed plan helps when those
  pages are already cached, but its three-run average was worse here.
- R14 still reads many order items. R10 and R16 still group a lot of data.
  R23 already had a unique index and remains a small lookup.

## Added index sizes on the seed database

Table size includes the heap, visibility map and any TOAST data.
Index size comes from `pg_relation_size`. The CP2 key indexes are separate.

| Index | Used for | Index (KiB) | Its table (KiB) |
|---|---|---:|---:|
| movements_restock_store_time_idx | R24 | 2,248 | 5,664 |
| order_items_product_order_idx | R12 | 14,832 | 34,728 |
| order_items_substitute_order_idx | R13 | 344 | 34,728 |
| orders_customer_time_idx | R06 | 4,640 | 17,696 |
| orders_open_store_time_idx | R07 | 16 | 17,696 |
| orders_packing_id_idx | W03 | 16 | 17,696 |
| orders_rider_time_idx | R21 | 4,464 | 17,696 |
| orders_store_time_idx | R11 / R18 | 4,640 | 17,696 |
| orders_time_idx | R08 / R14 / R15 / R17 / R19 / R20 / R22 | 3,312 | 17,696 |
| orders_unpack_store_id_idx | W02 | 16 | 17,696 |
| products_category_idx | R02 | 32 | 192 |
| products_name_trgm_idx | R03 | 120 | 192 |
| riders_active_store_id_idx | R21 / W03 | 56 | 168 |

See the [optimized summary](../benchmarks/results/optimized/summary.csv) for
every average, median, minimum and maximum.
