# Blinkit: baseline query timings

Pranjal Garg | T0133 | Measured 17 November 2026

## Setup and method

- PostgreSQL 17.12 (Homebrew), database `blinkit_t0133`, schema `blinkit`.
- MacBook Pro, Apple M4 (10 CPU cores), 16 GB memory, macOS 27.3.
- All ten supplied CSVs were loaded, including 150,000 orders and 675,000
  order items. ANALYZE ran after loading.
- Only the 17 PRIMARY KEY/UNIQUE indexes exist. No tuning index or query
  rewrite was added. The supplied workload and benchmark script are unchanged.
- Timezone: Asia/Kolkata. `work_mem` = 4 MB, `shared_buffers` = 128 MB,
  `enable_seqscan` = on. No planner/memory setting was changed to improve times.

Command from the repository root:

```sh
./benchmarks/run_benchmark.sh blinkit_t0133 baseline 3
```

The script measures each query three times with `EXPLAIN (ANALYZE, BUFFERS)`.
Numbers below are the `Execution Time` values in milliseconds, not planner
costs or command wall time. Average = (Run 1 + Run 2 + Run 3) / 3, rounded to
three decimals. W01-W05 run inside BEGIN/ROLLBACK, so their changes are not
kept. Content fingerprints of all ten tables matched before and after the
benchmark. Data pages had already been read for loading/integrity checks, so
this is a warm-cache laptop baseline, not a cold start or concurrent load test.

## All 30 queries

| Query and purpose | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---:|---:|---:|---:|
| [R01](../benchmarks/results/baseline/R01.txt): Store assignment: the nearest active dark store within ~3 km of a customer at (12.93, 77.62) | READ | 0.066 | 0.064 | 0.059 | 0.063 |
| [R02](../benchmarks/results/baseline/R02.txt): Category page: Dairy products in stock at store 43, cheapest first | READ | 0.243 | 0.244 | 0.224 | 0.237 |
| [R03](../benchmarks/results/baseline/R03.txt): Search: products with "milk" in the name that are in stock at store 43 | READ | 0.387 | 0.419 | 0.396 | 0.401 |
| [R04](../benchmarks/results/baseline/R04.txt): Product page: stock of product 1236 in every Bengaluru dark store | READ | 0.096 | 0.088 | 0.094 | 0.093 |
| [R05](../benchmarks/results/baseline/R05.txt): Cart check: current stock and price of 4 cart items at store 43 | READ | 0.266 | 0.026 | 0.025 | 0.106 |
| [R06](../benchmarks/results/baseline/R06.txt): Order tracking: customer 1027's latest order with its timeline | READ | 5.387 | 4.723 | 4.443 | 4.851 |
| [R07](../benchmarks/results/baseline/R07.txt): Store screen: open orders at store 43 (not yet delivered or cancelled) | READ | 5.966 | 6.081 | 5.741 | 5.929 |
| [R08](../benchmarks/results/baseline/R08.txt): SLA report: share of June 2026 deliveries that took longer than promised, per store | READ | 6.875 | 6.454 | 9.395 | 7.575 |
| [R09](../benchmarks/results/baseline/R09.txt): Replenishment: products at store 43 at or below their reorder level | READ | 0.363 | 0.253 | 0.262 | 0.293 |
| [R10](../benchmarks/results/baseline/R10.txt): Wastage: units lost to expiry or damage per category in June 2026 | READ | 5.603 | 5.028 | 5.115 | 5.249 |
| [R11](../benchmarks/results/baseline/R11.txt): Rider performance: average minutes from pickup to delivery per rider at store 43 (June 2026) | READ | 5.908 | 6.332 | 6.050 | 6.097 |
| [R12](../benchmarks/results/baseline/R12.txt): Recommendations: products most often bought together with product 1236 | READ | 7.869 | 7.862 | 8.242 | 7.991 |
| [R13](../benchmarks/results/baseline/R13.txt): Category team: active products that were never given as a substitute in June 2026 | READ | 19.360 | 19.777 | 21.547 | 20.228 |
| [R14](../benchmarks/results/baseline/R14.txt): Fill rate: share of order lines delivered short, per store, June 2026 | READ | 19.246 | 19.477 | 19.141 | 19.288 |
| [R15](../benchmarks/results/baseline/R15.txt): Staffing: orders per hour at Bengaluru stores on 29 June 2026 | READ | 8.636 | 8.769 | 8.385 | 8.597 |
| [R16](../benchmarks/results/baseline/R16.txt): Growth: monthly cohorts—customers by month of first order, and how many ordered again in June 2026 | READ | 31.298 | 34.185 | 31.426 | 32.303 |
| [R17](../benchmarks/results/baseline/R17.txt): Finance: small-cart fee collected per city per month in 2026 | READ | 31.337 | 30.922 | 32.514 | 31.591 |
| [R18](../benchmarks/results/baseline/R18.txt): Dead stock: products in stock at store 43 that did not sell there in June 2026 | READ | 5.731 | 5.586 | 5.346 | 5.554 |
| [R19](../benchmarks/results/baseline/R19.txt): Category report: June 2026 units sold of every Fruits & Vegetables product | READ | 1992.923 | 1953.459 | 1962.505 | 1969.629 |
| [R20](../benchmarks/results/baseline/R20.txt): Finance: daily GMV and running total for June 2026 | READ | 10.815 | 9.626 | 10.022 | 10.154 |
| [R21](../benchmarks/results/baseline/R21.txt): Store manager: active riders of store 43 with no delivery on 30 June 2026 | READ | 4.962 | 4.959 | 5.171 | 5.031 |
| [R22](../benchmarks/results/baseline/R22.txt): Support console: all orders, newest first, page 4,001 (25 per page) | READ | 45.929 | 48.038 | 50.278 | 48.082 |
| [R23](../benchmarks/results/baseline/R23.txt): Warehouse scanner: look up a product by SKU | READ | 0.026 | 0.022 | 0.021 | 0.023 |
| [R24](../benchmarks/results/baseline/R24.txt): Supply chain: units restocked per product at store 43 in the last 7 days of June 2026 | READ | 2.655 | 2.878 | 2.884 | 2.806 |
| [R25](../benchmarks/results/baseline/R25.txt): Loyalty: 20 Mumbai customers with the most delivered orders in 2026 | READ | 15.358 | 15.522 | 15.504 | 15.461 |
| [W01](../benchmarks/results/baseline/W01.txt): Checkout: place a new order at store 43 | WRITE | 0.656 | 0.597 | 0.579 | 0.611 |
| [W02](../benchmarks/results/baseline/W02.txt): Packing done: reduce store 43's stock for every line of its most recent PLACED or PACKING order | WRITE | 11.900 | 11.839 | 11.514 | 11.751 |
| [W03](../benchmarks/results/baseline/W03.txt): Dispatch: give the oldest PACKING order (anywhere) to its store's first active rider | WRITE | 13.097 | 12.820 | 13.191 | 13.036 |
| [W04](../benchmarks/results/baseline/W04.txt): Nightly replenishment at store 43: top up everything at or below reorder level | WRITE | 0.913 | 0.707 | 0.499 | 0.706 |
| [W05](../benchmarks/results/baseline/W05.txt): Data retention: delete inventory movements older than 1 January 2026 | WRITE | 10.706 | 11.355 | 11.350 | 11.137 |
| **Total (sum of all 30)** | | **2264.577** | **2228.112** | **2241.923** | **2244.873** |

The total is the sum of query times, not the elapsed time of the shell script.

## Scan types and observations

| Query | Scan types in run 3 | What the plan shows |
|---|---|---|
| R01 | Seq Scan | Only 120 stores need a location check, so the sequential scan is cheap. |
| R02 | Seq Scan / Index Scan | Reads the small product/category tables and uses the inventory pair key for matching stock. |
| R03 | Seq Scan / Index Scan | The name search reads products; matching stock is found by the inventory pair key. |
| R04 | Seq Scan / Index Scan | Reads stores to find Bengaluru, then uses each store-product key for the requested product. |
| R05 | Index Scan | The composite inventory key finds the four cart products directly. Run 1 was slower than the next two. |
| R06 | Seq Scan | There is no customer/date index on orders, so it reads orders and sorts the customer matches. |
| R07 | Parallel Seq Scan | Reads orders to filter store and open status, then sorts the small result. |
| R08 | Parallel Seq Scan | Reads orders to keep June deliveries and aggregates them by store. |
| R09 | Seq Scan / Bitmap Heap Scan / Bitmap Index Scan | The inventory key narrows to the store; a bitmap scan then checks the stock threshold. |
| R10 | Seq Scan / Index Scan | Reads movements, filters the time/type and joins to the small product/category tables. |
| R11 | Parallel Seq Scan | Reads orders to find deliveries for one store and month before grouping by rider. |
| R12 | Parallel Seq Scan / Index Only Scan | Reads order_items for the chosen product, then the order-first key finds the other products in each order. |
| R13 | Seq Scan / Parallel Seq Scan | Builds a hashed subquery from June lines. It returns zero rows because NOT IN sees NULL substitutes; this is a correctness problem. |
| R14 | Parallel Seq Scan | Reads order items and June orders in parallel and joins them before calculating shortage percentages. |
| R15 | Seq Scan / Index Scan | Reads orders and applies DATE(placed_at); store keys then check Bengaluru. |
| R16 | Seq Scan | Scans orders for first-order cohorts and June activity; the planner hashes the EXISTS subplan instead of rescanning for every customer. |
| R17 | Seq Scan / Index Scan | Reads orders and evaluates EXTRACT(YEAR), joins stores and groups by city/month. |
| R18 | Seq Scan / Index Only Scan / Bitmap Heap Scan / Bitmap Index Scan | Filters June orders, finds their lines by order_id and excludes sold products from store inventory. |
| R19 | Seq Scan / Index Scan | The correlated aggregate runs 125 times. Each pass scans 675,000 order_items rows, making it the slowest query. |
| R20 | Parallel Seq Scan | Scans delivered orders for June, groups daily totals and then calculates the running sum. |
| R21 | Seq Scan | Reads orders and riders to exclude riders with activity on the specified day. |
| R22 | Seq Scan | Sorts all orders by time, uses an external merge sort on disk, then skips 100,000 rows. |
| R23 | Index Scan | The unique SKU index finds one product directly; this is the fastest query here. |
| R24 | Seq Scan | Reads movements because no store/type/date index exists yet. |
| R25 | Seq Scan | Reads orders and customers before grouping the Mumbai customers and choosing the top 20. |
| W01 | No scan (VALUES insert) | A direct VALUES insert has no table scan node. Its execution time includes key/constraint checks. |
| W02 | Seq Scan / Index Scan | Scans orders for the recent open order, then uses keys for its lines and inventory updates. |
| W03 | Index Scan | Uses the order key to search for the first PACKING order, but removes 149,895 rows by its status filter in run 1. |
| W04 | Bitmap Heap Scan / Bitmap Index Scan | The inventory key narrows to store 43, and a bitmap scan checks rows needing replenishment. |
| W05 | Seq Scan | Reads movements and deletes the old ones inside a transaction that is rolled back. |

## Main findings

R19 averaged 1,969.629 ms, about 87.7% of the total baseline time.
Its raw plan shows `loops=125` on the correlated aggregate. The inner
order-items scan reads the table once for every Fruits & Vegetables product.
This is the main place to investigate for CP3.

R22 averaged 48.082 ms. The sort used `external merge`, with 7,352 kB of
disk space in each run. It still processes 100,025 sorted rows to return 25.
R23 needs only the SKU index lookup and averaged 0.023 ms.

R13 returned zero rows in all three plans. There are 36,262 NULL substitute
IDs in the June subquery. `NOT IN` with NULL makes nonmatching comparisons
unknown, and WHERE does not keep those rows. A separate read-only check with
NOT EXISTS found 1,250 active products not used as substitutes. The baseline
keeps the assigned query exactly as given; this result must be corrected and
explained in the later optimization work, rather than called a correct empty
answer just because it ran quickly.

These are baseline measurements only. No speed-up percentage is claimed yet.
Very short queries vary between runs (for example R05), so the individual
times and all raw plans are kept instead of selecting only the best run.

## Saved evidence

- [summary.csv](../benchmarks/results/baseline/summary.csv): 30 rows with average,
  median, minimum, maximum and scan nodes from the supplied script.
- [baseline folder](../benchmarks/results/baseline/): 30 plan files, with three
  labelled runs in each file (90 Execution Time entries altogether).
- [Schema and data checks](02_schema_design.md) and
  [the checks SQL](../sql/03_integrity_checks.sql).

All table contents were unchanged after W01-W05 rolled back. Planning time,
shell startup and the check queries are not included in this timing table.
