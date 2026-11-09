-- schema.sql
-- CREATE TABLE statements for the retail_analytics database (copied from 02_create_tables.sql).

-- Note: uncomment these two lines only to start again from scratch.
-- Orders is dropped first because it points to customers.
-- DROP TABLE IF EXISTS orders;
-- DROP TABLE IF EXISTS customers;

-- Note: customers table, one row per customer.
-- IF NOT EXISTS means running this twice does no harm.
CREATE TABLE IF NOT EXISTS customers (
    customer_id        INTEGER      PRIMARY KEY,   -- Note: primary key, every id is unique
    customer_name      VARCHAR(100) NOT NULL,      -- Note: a name must always be given
    gender             VARCHAR(10)  CHECK (gender IN ('Male', 'Female')),   -- Note: CHECK only allows these values
    city               VARCHAR(50),
    registration_date  DATE,
    customer_segment   VARCHAR(20)  CHECK (customer_segment IN ('Retail', 'Corporate', 'VIP'))
);

-- Note: orders table, one row per order.
CREATE TABLE IF NOT EXISTS orders (
    order_id          INTEGER       PRIMARY KEY,
    customer_id       INTEGER       NOT NULL REFERENCES customers (customer_id),   -- Note: foreign key, every order must belong to an existing customer
    order_date        DATE          NOT NULL,
    product_name      VARCHAR(100),
    product_category  VARCHAR(50),
    quantity          INTEGER       CHECK (quantity > 0),                -- Note: at least one unit per order
    unit_price        NUMERIC(12,2) CHECK (unit_price >= 0),             -- Note: price before discount, KSh
    cost_price        NUMERIC(12,2) CHECK (cost_price >= 0),             -- Note: what one unit cost the company, KSh
    discount          NUMERIC(5,2)  DEFAULT 0 CHECK (discount BETWEEN 0 AND 100),   -- Note: a percentage, 10 = 10% off
    payment_method    VARCHAR(30)   CHECK (payment_method IN ('M-Pesa', 'Cash', 'Card', 'Bank Transfer')),
    order_status      VARCHAR(20)   CHECK (order_status IN ('Completed', 'Pending', 'Cancelled'))
);

-- Joins and date filters are the bread and butter of this project; these keep them quick.
-- Note: an index works like a book index, so PostgreSQL finds rows without reading the whole table.
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_date ON orders (order_date);
