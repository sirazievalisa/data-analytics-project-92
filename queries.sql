/*
Данный запрос:
1. Обращается к таблице customers
2. Считает количество строк
3. Возвращает результат в колонке customers_count
*/

SELECT count(*) AS customers_count
FROM customers;

-- Отчет 1: топ-10 продавцов по суммарной выручке и количеству сделок
SELECT
    concat(e.first_name, ' ', e.last_name) AS seller,
    count(*) AS operations,
    floor(sum(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    seller
ORDER BY
    income DESC
LIMIT 10;

-- Отчет 2: продавцы, чья средняя выручка за сделку ниже общей средней
WITH sales_by_seller AS (
    SELECT
        concat(e.first_name, ' ', e.last_name) AS seller,
        sum(p.price * s.quantity) AS total_income,
        count(*) AS operations
    FROM sales AS s
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    GROUP BY
        seller
),

global_avg AS (
    SELECT sum(total_income) / sum(operations) AS avg_income_all
    FROM sales_by_seller
)

SELECT
    sbs.seller,
    floor(sbs.total_income / sbs.operations) AS average_income
FROM sales_by_seller AS sbs
CROSS JOIN global_avg AS ga
WHERE (sbs.total_income / sbs.operations) < ga.avg_income_all
ORDER BY
    average_income ASC;

-- Отчет 3: с данными по выручке по каждому продавцу и дню недели
SELECT
    concat(e.first_name, ' ', e.last_name) AS seller,
    lower(trim(to_char(s.sale_date, 'FMDay'))) AS day_of_week,
    floor(sum(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    seller,
    day_of_week
ORDER BY
    extract(ISODOW FROM s.sale_date),
    seller;

-- Таблица с разбивкой на возрастные группы покупателей
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    count(*) AS age_count
FROM customers
GROUP BY age_category
ORDER BY age_category;

-- Таблица с количеством покупателей и выручкой по месяцам
SELECT
    to_char(s.sale_date, 'YYYY-MM') AS selling_month,
    count(DISTINCT s.customer_id) AS total_customers,
    floor(sum(s.quantity * p.price)) AS income
FROM sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY selling_month
ORDER BY selling_month;


-- Таблица с покупателями, 1я покупка которых пришлась на время проведения акций
WITH promo_sales AS (
    SELECT
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        s.product_id,
        row_number() OVER (
            PARTITION BY s.customer_id
            ORDER BY
                s.sale_date,
                s.sales_id
        ) AS rn
    FROM sales AS s
)

SELECT
    ps.sale_date,
    c.first_name || ' ' || c.last_name AS customer,
    e.first_name || ' ' || e.last_name AS seller
FROM promo_sales AS ps
INNER JOIN products AS p
    ON ps.product_id = p.product_id
INNER JOIN employees AS e
    ON ps.sales_person_id = e.employee_id
INNER JOIN customers AS c
    ON ps.customer_id = c.customer_id
WHERE
    ps.rn = 1
    AND p.price = 0
ORDER BY c.customer_id;
