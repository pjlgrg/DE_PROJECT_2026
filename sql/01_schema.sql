\set ON_ERROR_STOP on

BEGIN;
CREATE SCHEMA blinkit;
SET search_path TO blinkit;

CREATE TABLE cities (
    city_id integer PRIMARY KEY,
    city_name varchar(80) NOT NULL UNIQUE,
    state varchar(80) NOT NULL
);

CREATE TABLE dark_stores (
    store_id integer PRIMARY KEY,
    store_code varchar(12) NOT NULL UNIQUE,
    city_id integer NOT NULL REFERENCES cities(city_id) ON DELETE RESTRICT,
    latitude numeric(9,6) NOT NULL,
    longitude numeric(9,6) NOT NULL,
    opened_on date NOT NULL,
    is_active boolean NOT NULL,
    max_daily_orders integer NOT NULL,
    CONSTRAINT store_code_format CHECK (store_code ~ '^[A-Z]{3}-[A-Z]{3}-[0-9]{2}$'),
    CONSTRAINT latitude_range CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT longitude_range CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT store_capacity_positive CHECK (max_daily_orders > 0)
);

CREATE TABLE categories (
    category_id integer PRIMARY KEY,
    category_name varchar(80) NOT NULL UNIQUE,
    is_perishable boolean NOT NULL
);

CREATE TABLE products (
    product_id integer PRIMARY KEY,
    sku varchar(10) NOT NULL UNIQUE,
    product_name varchar(150) NOT NULL,
    brand varchar(80) NOT NULL,
    category_id integer NOT NULL REFERENCES categories(category_id) ON DELETE RESTRICT,
    pack_size varchar(40) NOT NULL,
    mrp numeric(10,2) NOT NULL,
    shelf_life_days integer,
    is_active boolean NOT NULL,
    CONSTRAINT sku_format CHECK (sku ~ '^BK[0-9]{8}$'),
    CONSTRAINT mrp_positive CHECK (mrp > 0),
    CONSTRAINT shelf_life_positive CHECK (shelf_life_days IS NULL OR shelf_life_days > 0)
);

CREATE TABLE store_inventory (
    store_id integer NOT NULL REFERENCES dark_stores(store_id) ON DELETE RESTRICT,
    product_id integer NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity_on_hand integer NOT NULL,
    reorder_level integer NOT NULL,
    selling_price numeric(10,2) NOT NULL,
    updated_at timestamptz NOT NULL,
    PRIMARY KEY (store_id, product_id),
    CONSTRAINT stock_not_negative CHECK (quantity_on_hand >= 0),
    CONSTRAINT reorder_not_negative CHECK (reorder_level >= 0),
    CONSTRAINT selling_price_positive CHECK (selling_price > 0)
);

CREATE TABLE customers (
    customer_id integer PRIMARY KEY,
    full_name varchar(100) NOT NULL,
    phone varchar(10) NOT NULL UNIQUE,
    email varchar(254) UNIQUE,
    city_id integer NOT NULL REFERENCES cities(city_id) ON DELETE RESTRICT,
    created_at timestamptz NOT NULL,
    CONSTRAINT customer_phone_format CHECK (phone ~ '^[6-9][0-9]{9}$'),
    CONSTRAINT customer_email_format CHECK (email IS NULL OR email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$')
);

CREATE TABLE riders (
    rider_id integer PRIMARY KEY,
    full_name varchar(100) NOT NULL,
    phone varchar(10) NOT NULL UNIQUE,
    store_id integer NOT NULL REFERENCES dark_stores(store_id) ON DELETE RESTRICT,
    joined_on date NOT NULL,
    status varchar(10) NOT NULL,
    CONSTRAINT rider_phone_format CHECK (phone ~ '^[6-9][0-9]{9}$'),
    CONSTRAINT rider_status_values CHECK (status IN ('ACTIVE', 'ON_LEAVE', 'EXITED'))
);

CREATE TABLE orders (
    order_id integer PRIMARY KEY,
    customer_id integer NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    store_id integer NOT NULL REFERENCES dark_stores(store_id) ON DELETE RESTRICT,
    rider_id integer REFERENCES riders(rider_id) ON DELETE RESTRICT,
    placed_at timestamptz NOT NULL,
    packed_at timestamptz,
    picked_up_at timestamptz,
    delivered_at timestamptz,
    promised_minutes integer NOT NULL DEFAULT 10,
    subtotal numeric(10,2) NOT NULL,
    delivery_fee numeric(10,2) NOT NULL,
    handling_fee numeric(10,2) NOT NULL,
    small_cart_fee numeric(10,2) NOT NULL,
    total_amount numeric(10,2) NOT NULL,
    payment_method varchar(10) NOT NULL,
    status varchar(20) NOT NULL,
    CONSTRAINT promise_positive CHECK (promised_minutes > 0),
    CONSTRAINT subtotal_not_negative CHECK (subtotal >= 0),
    CONSTRAINT fees_not_negative CHECK (delivery_fee >= 0 AND handling_fee >= 0 AND small_cart_fee >= 0),
    CONSTRAINT total_matches_bill CHECK (total_amount = subtotal + delivery_fee + handling_fee + small_cart_fee),
    CONSTRAINT delivery_fee_rule CHECK (delivery_fee = CASE WHEN subtotal < 199 THEN 25 ELSE 0 END),
    CONSTRAINT handling_fee_rule CHECK (handling_fee = CASE WHEN subtotal < 500 THEN 6 ELSE 2 END),
    CONSTRAINT payment_values CHECK (payment_method IN ('UPI', 'COD', 'CARD', 'WALLET')),
    CONSTRAINT order_status_values CHECK (status IN ('PLACED', 'PACKING', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED')),
    CONSTRAINT packed_after_placed CHECK (packed_at IS NULL OR packed_at >= placed_at),
    CONSTRAINT pickup_after_packing CHECK (picked_up_at IS NULL OR (packed_at IS NOT NULL AND picked_up_at >= packed_at)),
    CONSTRAINT delivery_after_pickup CHECK (delivered_at IS NULL OR (picked_up_at IS NOT NULL AND delivered_at >= picked_up_at)),
    CONSTRAINT delivered_has_timeline CHECK (status <> 'DELIVERED' OR (rider_id IS NOT NULL AND delivered_at IS NOT NULL)),
    CONSTRAINT dispatched_has_rider CHECK (status <> 'OUT_FOR_DELIVERY' OR (rider_id IS NOT NULL AND picked_up_at IS NOT NULL))
);

CREATE TABLE order_items (
    order_id integer NOT NULL REFERENCES orders(order_id) ON DELETE RESTRICT,
    product_id integer NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity_ordered integer NOT NULL,
    quantity_delivered integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    substitute_product_id integer REFERENCES products(product_id) ON DELETE RESTRICT,
    PRIMARY KEY (order_id, product_id),
    CONSTRAINT ordered_quantity_positive CHECK (quantity_ordered > 0),
    CONSTRAINT delivered_quantity_valid CHECK (quantity_delivered BETWEEN 0 AND quantity_ordered),
    CONSTRAINT unit_price_positive CHECK (unit_price > 0),
    CONSTRAINT substitute_is_different CHECK (substitute_product_id IS NULL OR substitute_product_id <> product_id)
);

CREATE TABLE inventory_movements (
    movement_id integer PRIMARY KEY,
    store_id integer NOT NULL,
    product_id integer NOT NULL,
    movement_type varchar(10) NOT NULL,
    quantity integer NOT NULL,
    moved_at timestamptz NOT NULL,
    FOREIGN KEY (store_id, product_id) REFERENCES store_inventory(store_id, product_id) ON DELETE RESTRICT,
    CONSTRAINT movement_type_values CHECK (movement_type IN ('RESTOCK', 'DAMAGE', 'EXPIRY', 'ADJUSTMENT')),
    CONSTRAINT movement_quantity_sign CHECK (
        (movement_type = 'RESTOCK' AND quantity > 0)
        OR (movement_type IN ('DAMAGE', 'EXPIRY') AND quantity < 0)
        OR (movement_type = 'ADJUSTMENT' AND quantity <> 0)
    )
);

COMMIT;
