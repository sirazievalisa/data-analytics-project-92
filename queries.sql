/*
Данный запрос:
1. Обращается к таблице customers
2. Считает количество строк
3. Возвращает результат в колонке customers_count
*/

SELECT 
count (*) AS customers_count
from customers;


-- Отчет 3: с данными по выручке по каждому продавцу и дню недели
SELECT
    seller,
    day_of_week,
    income
FROM (
    SELECT
        CONCAT(e.first_name, ' ', e.last_name) AS seller,
        LOWER(TRIM(TO_CHAR(s.sale_date, 'FMDay'))) AS day_of_week,
        EXTRACT(ISODOW FROM s.sale_date) AS day_number,
        FLOOR(SUM(p.price * s.quantity)) AS income
    FROM sales s
    JOIN employees e
        ON e.employee_id = s.sales_person_id
    JOIN products p
        ON p.product_id = s.product_id
    GROUP BY seller, day_of_week, day_number
) t
ORDER BY day_number, seller;

-- Таблица с разбивкой на возрастные группы покупателей
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
                ELSE '40+'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers
GROUP BY age_category
ORDER BY age_category;


-- Таблица с количеством покупателей и выручкой по месяцам
SELECT
  TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
  COUNT(DISTINCT s.customer_id) AS total_customers,
  FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales s
JOIN products p ON p.product_id = s.product_id
GROUP BY selling_month
ORDER BY selling_month;


-- Таблица с покупателями первая покупка которых пришлась на время проведения специальных акций
WITH promo_sales AS (
    SELECT
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        s.product_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.sale_date, s.sales_id
        ) AS rn
    FROM sales s
)
SELECT
    c.first_name || ' ' || c.last_name AS customer,
    ps.sale_date,
    e.first_name || ' ' || e.last_name AS seller
FROM promo_sales ps
JOIN products p   ON p.product_id = ps.product_id
JOIN employees e  ON e.employee_id = ps.sales_person_id
JOIN customers c  ON c.customer_id = ps.customer_id
WHERE ps.rn = 1
  AND p.price = 0
ORDER BY c.customer_id;