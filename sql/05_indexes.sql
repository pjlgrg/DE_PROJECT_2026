\set ON_ERROR_STOP on

BEGIN;
SET LOCAL search_path TO blinkit, public;
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;

-- R02: find products in one category.
CREATE INDEX products_category_idx ON products (category_id);

-- R03: the pattern starts with %, so use a trigram index on the name.
CREATE INDEX products_name_trgm_idx ON products USING gin (product_name gin_trgm_ops);

-- R06: look up one customer's orders in newest-first order.
CREATE INDEX orders_customer_time_idx ON orders (customer_id, placed_at DESC);

-- R08, R14, R15, R17, R19, R20, R22: date ranges and newest-first pages.
CREATE INDEX orders_time_idx ON orders (placed_at);

-- R11, R18: choose the store first and then scan its date range.
CREATE INDEX orders_store_time_idx ON orders (store_id, placed_at);

-- R07: the open-order screen only needs these statuses.
CREATE INDEX orders_open_store_time_idx ON orders (store_id, placed_at)
WHERE status IN ('PLACED', 'PACKING', 'OUT_FOR_DELIVERY');

-- W02: find the greatest order ID among this store's unpacked orders.
CREATE INDEX orders_unpack_store_id_idx ON orders (store_id, order_id DESC)
WHERE status IN ('PLACED', 'PACKING');

-- W03: keep packing orders in ID order so MIN can stop at the first one.
CREATE INDEX orders_packing_id_idx ON orders (order_id)
WHERE status = 'PACKING';

-- R21: check one rider for activity from the requested date onward.
CREATE INDEX orders_rider_time_idx ON orders (rider_id, placed_at)
WHERE rider_id IS NOT NULL;

-- R21, W03: find active riders within one store, in ID order.
CREATE INDEX riders_active_store_id_idx ON riders (store_id, rider_id)
WHERE status = 'ACTIVE';

-- R12: find orders containing a product. The primary key starts with order_id.
CREATE INDEX order_items_product_order_idx ON order_items (product_id, order_id);

-- R13: look up a product's substitutions without indexing all the NULLs.
CREATE INDEX order_items_substitute_order_idx ON order_items (substitute_product_id, order_id)
WHERE substitute_product_id IS NOT NULL;

-- R24: cover the store and date filters for restocks.
CREATE INDEX movements_restock_store_time_idx ON inventory_movements (store_id, moved_at)
WHERE movement_type = 'RESTOCK';

COMMIT;
ANALYZE;
