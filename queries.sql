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

