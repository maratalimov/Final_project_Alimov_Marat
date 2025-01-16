-- Выбираем клиентов, у которых есть транзакции в каждом месяце за год
SELECT Id_client
FROM transactions_info
GROUP BY Id_client
HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 12;

-- Вычисляем среднюю сумму платежа за весь период
SELECT AVG(Sum_payment) AS avg_check
FROM transactions_info;

-- Вычисляем среднюю сумму покупок за месяц для каждого клиента
SELECT Id_client, AVG(monthly_sum) AS avg_monthly_sum
FROM (
    SELECT Id_client, DATE_FORMAT(date_new, '%Y-%m') AS month, SUM(Sum_payment) AS monthly_sum
    FROM transactions_info
    GROUP BY Id_client, month
) AS monthly_totals
GROUP BY Id_client;

-- Считаем количество операций для каждого клиента за весь период
SELECT Id_client, COUNT(*) AS total_operations
FROM transactions_info
GROUP BY Id_client;

-- Вычисляем среднюю сумму чека для каждого месяца
SELECT DATE_FORMAT(date_new, '%Y-%m') AS month, AVG(Sum_payment) AS avg_check
FROM transactions_info
GROUP BY month;

-- Вычисляем среднее количество операций в месяц
SELECT DATE_FORMAT(date_new, '%Y-%m') AS month, COUNT(*) / COUNT(DISTINCT Id_client) AS avg_operations
FROM transactions_info
GROUP BY month;

-- Вычисляем среднее количество клиентов, совершавших операции в каждом месяце
SELECT DATE_FORMAT(date_new, '%Y-%m') AS month, COUNT(DISTINCT Id_client) AS avg_clients
FROM transactions_info
GROUP BY month;

-- Вычисляем долю операций и сумму операций по месяцам относительно общего количества за год
WITH yearly_totals AS (
    -- Считаем общее количество операций и сумму за год
    SELECT COUNT(*) AS total_operations, SUM(Sum_payment) AS total_sum
    FROM transactions_info
)
SELECT DATE_FORMAT(date_new, '%Y-%m') AS month, 
       COUNT(*) * 100.0 / (SELECT total_operations FROM yearly_totals) AS operations_share,
       SUM(Sum_payment) * 100.0 / (SELECT total_sum FROM yearly_totals) AS sum_share
FROM transactions_info
GROUP BY month;

-- Вычисляем процентное соотношение по полу и долю затрат в каждом месяце
SELECT month, 
       Gender, 
       COUNT(*) * 100.0 / total_operations AS gender_ratio,
       SUM(Sum_payment) * 100.0 / total_sum AS spending_share
FROM (
    SELECT DATE_FORMAT(t.date_new, '%Y-%m') AS month, 
           c.Gender, 
           t.Sum_payment,
           COUNT(*) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS total_operations,
           SUM(t.Sum_payment) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS total_sum
    FROM transactions_info t
    JOIN customer_info c ON t.Id_client = c.Id_client
) AS subquery
GROUP BY month, Gender, total_operations, total_sum;

-- Группируем клиентов по возрастным группам с шагом 10 лет и отдельно клиентов без информации о возрасте
WITH age_groups AS (
    SELECT Id_client, 
           CASE 
               WHEN Age IS NULL THEN 'Unknown'
               WHEN Age BETWEEN 0 AND 9 THEN '0-9'
               WHEN Age BETWEEN 10 AND 19 THEN '10-19'
               WHEN Age BETWEEN 20 AND 29 THEN '20-29'
               WHEN Age BETWEEN 30 AND 39 THEN '30-39'
               WHEN Age BETWEEN 40 AND 49 THEN '40-49'
               WHEN Age BETWEEN 50 AND 59 THEN '50-59'
               WHEN Age BETWEEN 60 AND 69 THEN '60-69'
               WHEN Age BETWEEN 70 AND 79 THEN '70-79'
               WHEN Age BETWEEN 80 AND 89 THEN '80-89'
               WHEN Age BETWEEN 90 AND 99 THEN '90-99'
               ELSE '100+'
           END AS age_group
    FROM customer_info
)
-- Вычисляем сумму и количество операций по возрастным группам, а также средние показатели и процентное соотношение поквартально
SELECT age_group, 
       SUM(t.Sum_payment) AS total_sum, 
       COUNT(*) AS total_operations,
       AVG(t.Sum_payment) AS avg_sum_per_quarter,
       COUNT(*) * 100.0 / (SELECT COUNT(*) FROM transactions_info) AS percentage
FROM transactions_info t
JOIN age_groups a ON t.Id_client = a.Id_client
GROUP BY age_group;

