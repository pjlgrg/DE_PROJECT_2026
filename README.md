# Blinkit grocery delivery database

Blinkit needs fast stock checks and order screens because a nearby store
has to pick, pack and dispatch each order in a short time. It also needs
reports that show delays and shortages. We started with the course CSVs,
built the database and timed the same 30 queries as the data grew.

## Team

| Role | Name | Enrollment No. | GitHub |
|---|---|---|---|
| Group lead | Pranjal Garg | 2501010342 | pjlgrg |

Team T0133 · Section C. Our [team details](team.json) are in JSON.
PlateScore is in our [separate AP repo](https://github.com/pjlgrg/PlateScore_AP_2026).

## What we found

- The seed data loaded into ten tables with the keys and checks in place.
- The sum of the 30 seed query averages fell from 2,244.873 ms to 186.191 ms.
  The biggest improvement was R19, the category sales report.
- The official large dataset has 3 million orders and 19,327,375 rows in total.
  All 30 queries met their targets in our large run.
- R13 originally showed no products because its `NOT IN` list contained
  NULLs. We fixed that in the optimized query file and checked the result.
- We ran each query three times on PostgreSQL 17.12 on a MacBook Pro M4.

## Repository structure

- [Course checkpoints](CHECKPOINTS.md) and the
  [original project brief](https://github.com/edusatyaki/DBMS-Blinkit-Grocery-Delivery#readme)
- [Problems](docs/01_problem_understanding.md), [schema design](docs/02_schema_design.md)
  and [ER diagram](diagrams/er_diagram.png)
- [Baseline report](docs/03_baseline_timings.md) and [baseline plans](benchmarks/results/baseline/)
- [Optimization report](docs/04_optimization_report.md) and [optimized plans](benchmarks/results/optimized/)
- [Scalability report](docs/05_scalability_report.md), [large plans](benchmarks/results/large/)
  and [partitioning SQL](sql/08_partitioning.sql)

## How we run it

We start PostgreSQL 15 or newer and run these commands from this repo.
The baseline keeps only the indexes that PostgreSQL creates for keys.

```sh
export PGOPTIONS="-c timezone=Asia/Kolkata"
unzip -n seed_data.zip
createdb blinkit_seed
psql -X -d blinkit_seed -f sql/01_schema.sql -f sql/02_load_data.sql
psql -X -d blinkit_seed -f sql/03_integrity_checks.sql
./benchmarks/run_benchmark.sh blinkit_seed baseline 3

psql -X -d blinkit_seed -f sql/05_indexes.sql
./benchmarks/run_benchmark.sh blinkit_seed optimized 3 sql/06_optimized_queries.sql
```

For the large run, we download and unzip
[large_data.zip](https://github.com/edusatyaki/DBMS-Blinkit-Grocery-Delivery/releases/tag/large-data)
in this repo. The load scripts use the same CSV names.

```sh
createdb blinkit_large
psql -X -d blinkit_large -f sql/01_schema.sql
sed 's#seed_data/#large_data/#g' sql/02_load_data.sql | psql -X -d blinkit_large
psql -X -d blinkit_large -f sql/05_indexes.sql
./benchmarks/run_benchmark.sh blinkit_large large 3 sql/06_optimized_queries.sql

psql -X -d blinkit_seed -f sql/08_partitioning.sql
```

We keep the extracted CSVs out of Git. Each benchmark run replaces its
local summary and plans. The partitioning example rolls back after showing
which partitions PostgreSQL reads.
