-- =====================================================
-- E-COMMERCE DATABASE PROJECT (MySQL 8.0+)
-- Contents: schema, sample data, queries, view,
--           index, trigger, stored procedure
-- =====================================================

DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db;
USE ecommerce_db;

-- =====================================================
-- 1. TABLES
-- =====================================================

CREATE TABLE users (
    user_id     INT AUTO_INCREMENT PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    phone       VARCHAR(15),
    city        VARCHAR(50),
    created_at  DATE NOT NULL
);

CREATE TABLE categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id   INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(120) NOT NULL,
    category_id  INT NOT NULL,
    price        DECIMAL(10,2) NOT NULL CHECK (price > 0),
    stock        INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE orders (
    order_id     INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    order_date   DATE NOT NULL,
    status       ENUM('Pending','Shipped','Delivered','Cancelled') NOT NULL DEFAULT 'Pending',
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE order_items (
    item_id    INT AUTO_INCREMENT PRIMARY KEY,
    order_id   INT NOT NULL,
    product_id INT NOT NULL,
    quantity   INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id)   REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id   INT NOT NULL,
    method     ENUM('UPI','Card','COD','NetBanking') NOT NULL,
    amount     DECIMAL(10,2) NOT NULL,
    status     ENUM('Paid','Failed','Refunded') NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

CREATE TABLE reviews (
    review_id  INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT NOT NULL,
    product_id INT NOT NULL,
    rating     INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment    VARCHAR(255),
    FOREIGN KEY (user_id)    REFERENCES users(user_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- =====================================================
-- 2. SAMPLE DATA
-- =====================================================

INSERT INTO users (full_name, email, phone, city, created_at) VALUES
('Aarav Sharma', 'aarav@example.com', '9876500001', 'Varanasi', '2026-01-02'),
('Priya Singh',  'priya@example.com', '9876500002', 'Lucknow',  '2026-01-05'),
('Rohan Verma',  'rohan@example.com', '9876500003', 'Delhi',    '2026-01-12'),
('Sneha Gupta',  'sneha@example.com', '9876500004', 'Mumbai',   '2026-02-01'),
('Karan Mehta',  'karan@example.com', '9876500005', 'Pune',     '2026-02-10');

INSERT INTO categories (category_name) VALUES
('Electronics'), ('Clothing'), ('Books'), ('Home & Kitchen');

INSERT INTO products (product_name, category_id, price, stock) VALUES
('Wireless Earbuds',       1, 1999.00, 50),
('Phone Stand',            1,  499.00, 120),
('Bluetooth Speaker',      1, 2499.00, 30),
('Cotton T-Shirt',         2,  599.00, 200),
('Women''s Kurti',         2,  899.00, 150),
('SQL Made Easy',          3,  450.00, 80),
('Python Programming',     3,  650.00, 60),
('Non-stick Pan',          4, 1299.00, 40);

INSERT INTO orders (user_id, order_date, status, total_amount) VALUES
(1, '2026-01-10', 'Delivered', 3197.00),
(2, '2026-01-22', 'Delivered', 1349.00),
(1, '2026-02-05', 'Delivered', 2499.00),
(3, '2026-02-18', 'Shipped',   1799.00),
(4, '2026-03-02', 'Pending',   1299.00),
(2, '2026-03-15', 'Cancelled', 1999.00);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1999.00),
(1, 4, 2,  599.00),
(2, 5, 1,  899.00),
(2, 6, 1,  450.00),
(3, 3, 1, 2499.00),
(4, 7, 2,  650.00),
(4, 2, 1,  499.00),
(5, 8, 1, 1299.00),
(6, 1, 1, 1999.00);

INSERT INTO payments (order_id, method, amount, status) VALUES
(1, 'UPI',  3197.00, 'Paid'),
(2, 'Card', 1349.00, 'Paid'),
(3, 'COD',  2499.00, 'Paid'),
(4, 'UPI',  1799.00, 'Paid'),
(6, 'Card', 1999.00, 'Refunded');

INSERT INTO reviews (user_id, product_id, rating, comment) VALUES
(1, 1, 5, 'Great sound quality'),
(1, 3, 4, 'Good bass, bit bulky'),
(1, 4, 4, 'Comfortable fabric'),
(2, 5, 4, 'Nice fit'),
(2, 6, 5, 'Very helpful for beginners'),
(3, 7, 3, 'Decent book');

-- =====================================================
-- 3. QUERIES
-- =====================================================

-- Q1. All orders with customer name (INNER JOIN)
SELECT o.order_id, u.full_name, o.order_date, o.status, o.total_amount
FROM orders o
JOIN users u ON u.user_id = o.user_id
ORDER BY o.order_date;

-- Q2. Order details: products in each order (multi-table JOIN)
SELECT o.order_id, u.full_name, p.product_name, oi.quantity,
       oi.unit_price, (oi.quantity * oi.unit_price) AS line_total
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN users u    ON u.user_id = o.user_id
JOIN products p ON p.product_id = oi.product_id
ORDER BY o.order_id;

-- Q3. Monthly revenue (excluding cancelled orders)
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month,
       COUNT(*)           AS total_orders,
       SUM(total_amount)  AS revenue
FROM orders
WHERE status <> 'Cancelled'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;

-- Q4. Top-selling products by quantity (valid orders only)
SELECT p.product_name, SUM(oi.quantity) AS units_sold
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id = oi.order_id
WHERE o.status <> 'Cancelled'
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC
LIMIT 5;

-- Q5. Revenue by category
SELECT c.category_name, SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p   ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
JOIN orders o     ON o.order_id = oi.order_id
WHERE o.status <> 'Cancelled'
GROUP BY c.category_name
ORDER BY revenue DESC;

-- Q6. Customers who never placed an order (LEFT JOIN)
SELECT u.user_id, u.full_name
FROM users u
LEFT JOIN orders o ON o.user_id = u.user_id
WHERE o.order_id IS NULL;

-- Q7. Average rating per product (HAVING)
SELECT p.product_name, ROUND(AVG(r.rating),2) AS avg_rating, COUNT(*) AS reviews
FROM reviews r
JOIN products p ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name
HAVING AVG(r.rating) >= 4
ORDER BY avg_rating DESC;

-- Q8. Products priced above the average price (subquery)
SELECT product_name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products)
ORDER BY price DESC;

-- Q9. Customers who spent more than 2000 in total (subquery + GROUP BY)
SELECT u.full_name, SUM(o.total_amount) AS total_spent
FROM users u
JOIN orders o ON o.user_id = u.user_id
WHERE o.status <> 'Cancelled'
GROUP BY u.user_id, u.full_name
HAVING SUM(o.total_amount) > 2000;

-- Q10. Low stock alert
SELECT product_name, stock FROM products WHERE stock < 50 ORDER BY stock;

-- Q11. Payment method usage
SELECT method, COUNT(*) AS times_used, SUM(amount) AS total_amount
FROM payments
WHERE status = 'Paid'
GROUP BY method;

-- =====================================================
-- 4. VIEW
-- =====================================================

CREATE VIEW order_summary AS
SELECT o.order_id, u.full_name AS customer, u.city,
       o.order_date, o.status, o.total_amount,
       COALESCE(pm.status, 'Not Paid') AS payment_status
FROM orders o
JOIN users u ON u.user_id = o.user_id
LEFT JOIN payments pm ON pm.order_id = o.order_id;

SELECT * FROM order_summary;

-- =====================================================
-- 5. INDEXES
-- =====================================================

CREATE INDEX idx_orders_user    ON orders(user_id);
CREATE INDEX idx_items_order    ON order_items(order_id);
CREATE INDEX idx_products_cat   ON products(category_id);

-- =====================================================
-- 6. TRIGGER: reduce stock when an item is ordered
-- =====================================================

DELIMITER //
CREATE TRIGGER trg_reduce_stock
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET stock = stock - NEW.quantity
    WHERE product_id = NEW.product_id;
END //
DELIMITER ;

-- Test the trigger
SELECT product_name, stock FROM products WHERE product_id = 2;   -- before
INSERT INTO orders (user_id, order_date, status, total_amount)
VALUES (5, '2026-03-20', 'Pending', 998.00);
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (LAST_INSERT_ID(), 2, 2, 499.00);
SELECT product_name, stock FROM products WHERE product_id = 2;   -- after (reduced by 2)

-- =====================================================
-- 7. STORED PROCEDURE: order history of a customer
-- =====================================================

DELIMITER //
CREATE PROCEDURE get_customer_orders(IN p_user_id INT)
BEGIN
    SELECT o.order_id, o.order_date, o.status, o.total_amount
    FROM orders o
    WHERE o.user_id = p_user_id
    ORDER BY o.order_date DESC;
END //
DELIMITER ;

CALL get_customer_orders(1);

-- =====================================================
-- 8. TRANSACTION EXAMPLE
-- =====================================================

START TRANSACTION;
UPDATE orders SET status = 'Shipped' WHERE order_id = 5;
COMMIT;
