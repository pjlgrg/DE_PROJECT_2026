# Blinkit: schema design

Pranjal Garg | T0133 | PostgreSQL 17.12

## Design choices

The schema is named `blinkit`. Table and column names match the ten CSVs.
IDs are integers supplied by the export. Text codes and phone numbers are
strings. Money uses `numeric(10,2)` and event times use `timestamptz` because
the CSVs include +05:30 offsets. The connection timezone is Asia/Kolkata.

There are ten primary keys. `store_inventory` uses `(store_id, product_id)`
because stock depends on both. `order_items` uses `(order_id, product_id)`
because an order has one line per requested product. A repeated product in
an order is represented by its quantity, not another line.

All foreign keys use `ON DELETE RESTRICT`. These are linked stock and order
records, so deleting a parent should not silently delete history. An optional
reference allows NULL at insertion, but still blocks deleting a referenced
parent. Retire products/stores with `is_active`, and riders with their status.
W05 deletes movement rows directly; it does not delete their inventory parent.

## Data dictionary

PK means primary key, FK means foreign key and UNIQUE prevents duplicates.
Where two columns have PK in the same table, they form one composite key.
The check rules are listed after the dictionary.

### cities

| Column | Type | Key / NULL rule | Why |
|---|---|---|---|
| city_id | integer | PK, NOT NULL | Links the row to its city. |
| city_name | varchar(80) | UNIQUE, NOT NULL | Readable city name; unique within this export. |
| state | varchar(80) | NOT NULL | State name belongs to the city. |

### dark_stores

| Column | Type | Key / NULL rule | Why |
|---|---|---|---|
| store_id | integer | PK, NOT NULL | Identifies the dark store. |
| store_code | varchar(12) | UNIQUE, NOT NULL | Unique human-readable store code. |
| city_id | integer | FK, NOT NULL | Links the row to its city. |
| latitude | numeric(9,6) | NOT NULL | Six decimal places keep the supplied location precision. |
| longitude | numeric(9,6) | NOT NULL | Six decimal places keep the supplied location precision. |
| opened_on | date | NOT NULL | A calendar date, without a time of day. |
| is_active | boolean | NOT NULL | True/false flag, not a text status. |
| max_daily_orders | integer | NOT NULL | Whole-number store capacity. |

### categories

| Column | Type | Key / NULL rule | Why |
|---|---|---|---|
| category_id | integer | PK, NOT NULL | Links the row to its category. |
| category_name | varchar(80) | UNIQUE, NOT NULL | Unique category name used in the queries. |
| is_perishable | boolean | NOT NULL | Whether the category contains perishable goods. |

### products

| Column | Type | Key / NULL rule | Why |
|---|---|---|---|
| product_id | integer | PK, NOT NULL | Identifies a catalogue product. |
| sku | varchar(10) | UNIQUE, NOT NULL | Unique scanner code; stored as text. |
| product_name | varchar(150) | NOT NULL | Product display name. |
| brand | varchar(80) | NOT NULL | Brand text from the export. |
| category_id | integer | FK, NOT NULL | Links the row to its category. |
| pack_size | varchar(40) | NOT NULL | Includes units, for example 1 kg. |
| mrp | numeric(10,2) | NOT NULL | Exact decimal money, avoiding floating-point rounding. |
| shelf_life_days | integer | NULL allowed | Positive whole days; NULL for non-perishable products. |
| is_active | boolean | NOT NULL | True/false flag, not a text status. |

### store_inventory

| Column | Type | Key / NULL rule | Why |
|---|---|---|---|
| store_id | integer | PK, FK, NOT NULL | Identifies the dark store. |
| product_id | integer | PK, FK, NOT NULL | Identifies a catalogue product. |
| quantity_on_hand | integer | NOT NULL | Current whole units at this store. |
| reorder_level | integer | NOT NULL | Minimum stock threshold for this store-product pair. |
| selling_price | numeric(10,2) | NOT NULL | Exact store-specific selling price. |
| updated_at | timestamptz | NOT NULL | Stock update time, preserving the timezone offset. |

### customers

| Column | Type | Key / NULL rule | Why |
|---|---|---|---|
| customer_id | integer | PK, NOT NULL | Identifies the customer. |
| full_name | varchar(100) | NOT NULL | Person name; it need not be unique. |
| phone | varchar(10) | UNIQUE, NOT NULL | Ten-digit identifier, not a number to calculate with. |
| email | varchar(254) | UNIQUE, NULL allowed | Unique when supplied; NULL means no email was given. |
| city_id | integer | FK, NOT NULL | Links the row to its city. |
| created_at | timestamptz | NOT NULL | Customer creation time, with timezone. |

### riders

| Column | Type | Key / NULL rule | Why |
|---|---|---|---|
| rider_id | integer | PK, NOT NULL | Identifies the rider; optional on an unassigned order. |
| full_name | varchar(100) | NOT NULL | Person name; it need not be unique. |
| phone | varchar(10) | UNIQUE, NOT NULL | Ten-digit identifier, not a number to calculate with. |
| store_id | integer | FK, NOT NULL | Identifies the dark store. |
| joined_on | date | NOT NULL | Rider joining date. |
| status | varchar(10) | NOT NULL | Allowed rider states only. |

### orders

| Column | Type | Key / NULL rule | Why |
|---|---|---|---|
| order_id | integer | PK, NOT NULL | Identifies the order. |
| customer_id | integer | FK, NOT NULL | Identifies the customer. |
| store_id | integer | FK, NOT NULL | Identifies the dark store. |
| rider_id | integer | FK, NULL allowed | Identifies the rider; optional on an unassigned order. |
| placed_at | timestamptz | NOT NULL | Order creation time; always present. |
| packed_at | timestamptz | NULL allowed | NULL until packing is recorded. |
| picked_up_at | timestamptz | NULL allowed | NULL until pickup is recorded. |
| delivered_at | timestamptz | NULL allowed | NULL until delivery is recorded. |
| promised_minutes | integer | NOT NULL | Positive delivery promise; default 10 for W01. |
| subtotal | numeric(10,2) | NOT NULL | Stored billed item total; exact decimal money. |
| delivery_fee | numeric(10,2) | NOT NULL | Stored delivery charge; follows the export fee rule. |
| handling_fee | numeric(10,2) | NOT NULL | Stored handling charge; follows the export fee rule. |
| small_cart_fee | numeric(10,2) | NOT NULL | Non-negative fee; all supplied rows contain zero. |
| total_amount | numeric(10,2) | NOT NULL | Subtotal plus all three fees. |
| payment_method | varchar(10) | NOT NULL | One of UPI, COD, CARD and WALLET. |
| status | varchar(20) | NOT NULL | Allowed order states only. |

### order_items

| Column | Type | Key / NULL rule | Why |
|---|---|---|---|
| order_id | integer | PK, FK, NOT NULL | Identifies the order. |
| product_id | integer | PK, FK, NOT NULL | Identifies a catalogue product. |
| quantity_ordered | integer | NOT NULL | Positive whole units requested. |
| quantity_delivered | integer | NOT NULL | Whole units supplied, from zero to quantity_ordered. |
| unit_price | numeric(10,2) | NOT NULL | Price snapshot on this order line, not the current catalogue price. |
| substitute_product_id | integer | FK, NULL allowed | Optional replacement product; points to products again. |

### inventory_movements

| Column | Type | Key / NULL rule | Why |
|---|---|---|---|
| movement_id | integer | PK, NOT NULL | Identifies one inventory event. |
| store_id | integer | FK, NOT NULL | Identifies the dark store. |
| product_id | integer | FK, NOT NULL | Identifies a catalogue product. |
| movement_type | varchar(10) | NOT NULL | RESTOCK, DAMAGE, EXPIRY or ADJUSTMENT. |
| quantity | integer | NOT NULL | Signed whole units: gains positive, losses negative. |
| moved_at | timestamptz | NOT NULL | Inventory event time, with timezone. |

## Foreign keys and cardinalities

| Parent -> child | Child foreign key | Relationship |
|---|---|---|
| cities -> dark_stores | city_id | One city, zero or many stores |
| cities -> customers | city_id | One city, zero or many customers |
| categories -> products | category_id | One category, zero or many products |
| dark_stores -> store_inventory | store_id | One store, many stocked products |
| products -> store_inventory | product_id | One product, stock at many stores |
| dark_stores -> riders | store_id | One store, many riders |
| customers -> orders | customer_id | One customer, many orders |
| dark_stores -> orders | store_id | One serving store per order |
| riders -> orders | rider_id | An order has zero or one rider; a rider has many orders |
| orders -> order_items | order_id | One order, many lines |
| products -> order_items | product_id | One requested product per line |
| products -> order_items | substitute_product_id | A line has zero or one substitute |
| store_inventory -> inventory_movements | (store_id, product_id) | One inventory pair, many events |

The last foreign key is a single composite FK. A movement must name a product
that is actually stocked at that store, not just any valid store and product.
The store-product and order-product links turn many-to-many relationships
into two one-to-many relationships.

The [PNG diagram](../diagrams/er_diagram.png) includes the columns, keys and
cardinalities. We kept the [Mermaid source](../diagrams/er_diagram.mmd) with it.

## CHECK rules

There are 33 CHECK constraints in [01_schema.sql](../sql/01_schema.sql):

| Table | Rules |
|---|---|
| dark_stores | Store code matches AAA-AAA-00; latitude is -90 to 90; longitude is -180 to 180; daily capacity is positive (4 checks) |
| products | SKU is BK followed by eight digits; MRP is positive; shelf life is either NULL or positive (3) |
| store_inventory | Stock and reorder level are non-negative; selling price is positive (3) |
| customers | Phone is ten digits starting 6-9; a supplied email has a basic email shape (2) |
| riders | Same phone rule; status is ACTIVE, ON_LEAVE or EXITED (2) |
| orders | Positive promise; non-negative subtotal and fees; total equals subtotal plus fees; delivery-fee rule; handling-fee rule; allowed payment and status; packed >= placed; pickup requires packing and follows it; delivery requires pickup and follows it; delivered orders have rider and delivery time; dispatched orders have rider and pickup time (13) |
| order_items | Ordered quantity is positive; delivered quantity is between zero and ordered; price is positive; a substitute differs from the requested product (4) |
| inventory_movements | Allowed movement types; RESTOCK is positive, DAMAGE/EXPIRY negative and ADJUSTMENT nonzero (2) |

The export's delivery fee is 25 below subtotal 199, otherwise zero. Handling
is 6 below 500, otherwise 2. All 150,000 rows obey these rules. They are the
fee policy assumed for this exercise, not a claim about Blinkit's current
commercial pricing. Small-cart fee is always zero in this data, so there is
no evidence for a nonzero threshold or amount. Its constraint only requires
a non-negative value. W01's supplied subtotal/fees also satisfy these rules.

Cross-table business checks, such as a rider belonging to the order's store,
are checked by SQL below. A CHECK constraint on one table does not enforce
those relationships by itself.

## NULL values in the seed data

| Column | NULL rows | Meaning / observation |
|---|---:|---|
| customers.email | 18,023 | Optional email; PostgreSQL UNIQUE allows multiple NULLs |
| products.shelf_life_days | 875 | Exactly the products in non-perishable categories |
| orders.rider_id | 5,822 | Cancelled orders and the PLACED/PACKING orders have no rider |
| orders.packed_at | 2,885 | 35 PLACED orders and 2,850 cancellations have no packing time |
| orders.picked_up_at | 5,822 | No pickup for cancelled or not-yet-dispatched orders |
| orders.delivered_at | 5,857 | Only DELIVERED orders have a delivery time |
| order_items.substitute_product_id | 660,000 | No replacement product recorded on these lines |

There are 2,902 cancelled orders with a packing time, so it would be wrong to
require all cancelled orders to have an entirely empty timeline. Other CSV
columns have no empty cells and are NOT NULL in the schema.

## Functional dependencies and normal forms

An arrow means "determines". The normal-form decisions use the meaning of
the fields, not just patterns that happen to repeat in this dataset.

| Table | Main functional dependencies | Normal form / decision |
|---|---|---|
| cities | city_id -> city_name, state; city_name -> city_id, state | BCNF: ID and the unique name are candidate keys here |
| dark_stores | store_id -> all other columns; store_code -> all other columns | BCNF under these store rules |
| categories | category_id -> category_name, is_perishable; category_name -> category_id, is_perishable | BCNF |
| products | product_id -> all other columns; sku -> all other columns | BCNF under the product rules. A category need not give every product the same shelf life, even though this export uses repeated values |
| store_inventory | (store_id, product_id) -> quantity_on_hand, reorder_level, selling_price, updated_at | BCNF for the current inventory snapshot |
| customers | customer_id -> all other columns; phone -> all other columns | BCNF under the unique-phone assumption. Nullable email is UNIQUE when present, not a required candidate key |
| riders | rider_id -> all other columns; phone -> all other columns | BCNF under the unique-phone assumption |
| orders | order_id -> all other columns; subtotal -> delivery_fee, handling_fee under this fixed policy; (subtotal, delivery_fee, handling_fee, small_cart_fee) -> total_amount | Deliberate 3NF/BCNF exception for stored bill values; see below |
| order_items | (order_id, product_id) -> quantity_ordered, quantity_delivered, unit_price, substitute_product_id | BCNF for order-line facts. Product ID alone does not determine the historical unit price |
| inventory_movements | movement_id -> store_id, product_id, movement_type, quantity, moved_at | BCNF for inventory events |

The order bill is deliberately not claimed to be fully 3NF. `total_amount`
is derived, fees follow a subtotal policy, and subtotal can be calculated
from lines. The assignment requires those columns and the workload reads
them. Keeping a historical bill snapshot also avoids recalculating an old
bill using a later price policy. The total check prevents the stored bill
fields from disagreeing; an integrity query checks subtotal against lines.

Current stock is another stored balance. Restocks and sales affect it, but
the export is a snapshot and does not give an opening balance from which to
rebuild all stock history. Keeping `quantity_on_hand` is useful for checkout.
In an application, updating stock and recording its event should happen in
the same transaction. This schema alone does not implement that workflow.

## Loading and validation

Run from the repository root on a new empty database:

```sh
unzip -n seed_data.zip
createdb blinkit_t0133
psql -X -v ON_ERROR_STOP=1 -d blinkit_t0133 -f sql/01_schema.sql
psql -X -v ON_ERROR_STOP=1 -d blinkit_t0133 -f sql/02_load_data.sql
psql -X -v ON_ERROR_STOP=1 -d blinkit_t0133 -f sql/03_integrity_checks.sql
```

The load uses `\copy` in parent-before-child order inside a transaction,
then runs ANALYZE. All original rows loaded without disabling constraints,
editing CSVs, or dropping data. Results from PostgreSQL on 17 November 2026:

| Table | Expected rows | Loaded rows |
|---|---:|---:|
| cities | 10 | 10 |
| dark_stores | 120 | 120 |
| categories | 12 | 12 |
| products | 1,500 | 1,500 |
| store_inventory | 126,000 | 126,000 |
| customers | 40,000 | 40,000 |
| riders | 1,800 | 1,800 |
| orders | 150,000 | 150,000 |
| order_items | 675,000 | 675,000 |
| inventory_movements | 90,000 | 90,000 |

The six integrity queries in [03_integrity_checks.sql](../sql/03_integrity_checks.sql)
returned these results:

| Check | Problem rows |
|---|---:|
| Ordered product is not stocked at the order's store | 0 |
| Assigned rider belongs to a different store | 0 |
| Substitute is not stocked at the order's store | 0 |
| Subtotal differs from sum(quantity_delivered * unit_price) | 0 |
| Store selling price is above MRP | 0 |
| Shelf-life NULL rule disagrees with the category's perishable flag | 0 |

Using `quantity_ordered` instead would give 27,000 subtotal mismatches, due to
short delivery lines. For example, order 5 has ordered value 941 but delivered
value 889, which matches its exported subtotal 889. The export also retains
line quantities and bills on cancelled orders. These are kept as supplied;
they are not evidence of a completed delivery or a refund. No CSV rows were
repaired. No orphan key or invalid CHECK value was found during the load.

## Baseline indexes

Only the 17 indexes automatically created by PRIMARY KEY or UNIQUE exist:

| Table | Indexed keys |
|---|---|
| cities | city_id; city_name |
| dark_stores | store_id; store_code |
| categories | category_id; category_name |
| products | product_id; sku |
| store_inventory | (store_id, product_id) |
| customers | customer_id; phone; email |
| riders | rider_id; phone |
| orders | order_id |
| order_items | (order_id, product_id) |
| inventory_movements | movement_id |

PostgreSQL does not automatically add a separate index for every foreign key.
There are no tuning indexes in this CP1/CP2 baseline. The integrity script
also prints the actual index definitions from `pg_indexes`.
