\set ON_ERROR_STOP on

BEGIN;
SET LOCAL search_path TO blinkit;

CREATE TABLE order_items_by_order (
    LIKE order_items INCLUDING CONSTRAINTS,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE RESTRICT,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
    FOREIGN KEY (substitute_product_id) REFERENCES products(product_id) ON DELETE RESTRICT
) PARTITION BY HASH (order_id);

CREATE TABLE order_items_p0 PARTITION OF order_items_by_order FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE order_items_p1 PARTITION OF order_items_by_order FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE order_items_p2 PARTITION OF order_items_by_order FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE order_items_p3 PARTITION OF order_items_by_order FOR VALUES WITH (MODULUS 4, REMAINDER 3);

INSERT INTO order_items_by_order
SELECT * FROM order_items WHERE order_id BETWEEN 1 AND 6000;

ANALYZE order_items_by_order;
SELECT tableoid::regclass AS partition, count(*) AS row_count
FROM order_items_by_order GROUP BY tableoid ORDER BY partition;

EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, quantity_ordered
FROM order_items_by_order WHERE order_id = 1027;

EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM order_items_by_order WHERE quantity_ordered > 1;

ROLLBACK;
