\set ON_ERROR_STOP on
SET search_path TO blinkit;

SELECT 'cities' AS table_name, count(*) AS rows FROM cities
UNION ALL SELECT 'dark_stores', count(*) FROM dark_stores
UNION ALL SELECT 'categories', count(*) FROM categories
UNION ALL SELECT 'products', count(*) FROM products
UNION ALL SELECT 'store_inventory', count(*) FROM store_inventory
UNION ALL SELECT 'customers', count(*) FROM customers
UNION ALL SELECT 'riders', count(*) FROM riders
UNION ALL SELECT 'orders', count(*) FROM orders
UNION ALL SELECT 'order_items', count(*) FROM order_items
UNION ALL SELECT 'inventory_movements', count(*) FROM inventory_movements;

SELECT count(*) AS ordered_products_not_stocked
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
LEFT JOIN store_inventory si ON si.store_id = o.store_id AND si.product_id = oi.product_id
WHERE si.product_id IS NULL;

SELECT count(*) AS riders_from_wrong_store
FROM orders o JOIN riders r ON r.rider_id = o.rider_id
WHERE o.store_id <> r.store_id;

SELECT count(*) AS substitutes_not_stocked
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
LEFT JOIN store_inventory si ON si.store_id = o.store_id AND si.product_id = oi.substitute_product_id
WHERE oi.substitute_product_id IS NOT NULL AND si.product_id IS NULL;

SELECT count(*) AS subtotal_mismatches
FROM orders o
JOIN (
    SELECT order_id, sum(quantity_delivered * unit_price) AS item_subtotal
    FROM order_items GROUP BY order_id
) items ON items.order_id = o.order_id
WHERE o.subtotal <> items.item_subtotal;

SELECT count(*) AS inventory_price_above_mrp
FROM store_inventory si JOIN products p ON p.product_id = si.product_id
WHERE si.selling_price > p.mrp;

SELECT count(*) AS perishable_shelf_life_mismatches
FROM products p JOIN categories c ON c.category_id = p.category_id
WHERE (c.is_perishable AND p.shelf_life_days IS NULL)
   OR (NOT c.is_perishable AND p.shelf_life_days IS NOT NULL);

SELECT tablename, indexname, indexdef
FROM pg_indexes WHERE schemaname = 'blinkit'
ORDER BY tablename, indexname;
