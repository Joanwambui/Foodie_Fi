SELECT *
FROM plans;

SELECT * 
FROM subscriptions	

SELECT s.customer_id,p.plan_id,s.start_date,p.plan_name
FROM subscriptions s
INNER JOIN plans p 
ON s.plan_id=p.plan_id
WHERE customer_id = 1



SELECT customer_id,plan_id,start_date
FROM subscriptions
WHERE customer_id = 2

SELECT customer_id,plan_id,start_date
FROM subscriptions
WHERE customer_id = 3

SELECT customer_id,plan_id,start_date
FROM subscriptions
WHERE customer_id = 4

#How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id)
FROM subscriptions

#What is the monthly distribution of trial plan start_date values for our dataset — 
#use the start of the month as the group by value.

SELECT
  MONTH(start_date) AS month_date, -- Extract month as integer
  DATE_FORMAT(start_date, '%M') AS month_name, -- Extract month as string
  COUNT(*) AS trial_subscriptions
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p
  ON s.plan_id = p.plan_id
WHERE s.plan_id = 0
GROUP BY MONTH(start_date), 
  DATE_FORMAT(start_date, '%M')
ORDER BY month_date ASC;

#What plan start_date values occur after the year 2020 for our dataset? 
#Show the breakdown by count of events for each plan_name
SELECT 
  p.plan_id,
  p.plan_name,
  COUNT(*) AS events
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p
  ON s.plan_id = p.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id;

#What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT COUNT(s.customer_id),ROUND(100*COUNT(*)::NUMERIC/(SELECT COUNT(customer_id)
FROM foodie_fi.subscriptions),1) AS churn_percentage
p.plan_name
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p
  ON s.plan_id = p.plan_id
WHERE plan_name="churn"

SELECT
  COUNT(s.customer_id) AS count_customer_id,
  ROUND(100 * COUNT(s.customer_id) / (SELECT COUNT(customer_id) FROM foodie_fi.subscriptions), 1) AS churn_percentage,
  p.plan_name
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE p.plan_name = 'churn'
GROUP BY p.plan_name;

SELECT COUNT(customer_id)
FROM foodie_fi.subscriptions s

#How many customers have churned straight after their initial free trial — 
#what percentage is this rounded to the nearest whole number?
SELECT *
FROM subscriptions
WHERE plan_id = 0

-- Find ranking of plans by customer and plan type
WITH ranking AS (
SELECT 
  s.customer_id, 
  s.plan_id, 
  p.plan_name,
  #Run a ROW_NUMBER() to rank plans from 0 to 4
  ROW_NUMBER() OVER (
    PARTITION BY s.customer_id 
    ORDER BY s.plan_id) AS plan_rank 
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p
  ON s.plan_id = p.plan_id)
  
SELECT 
  COUNT(*) AS churn_count,
  ROUND(100 * COUNT(*) / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.subscriptions),0) AS churn_percentage
FROM ranking
WHERE plan_id = 4 -- Filter to churn plan
  AND plan_rank = 2 -- Filter to rank 2 as customers who churned immediately after trial have churn plan ranked as 2

 #What is the number and percentage of customer plans after their initial free trial?
WITH next_plan_cte AS (
SELECT 
  customer_id, 
  plan_id, 
  LEAD(plan_id, 1) OVER( -- Offset by 1 to retrieve the immediate row's value below 
    PARTITION BY customer_id 
    ORDER BY plan_id) as next_plan
FROM foodie_fi.subscriptions)

SELECT 
  next_plan, 
  COUNT(*) AS conversions,
  ROUND(100 * COUNT(*) / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.subscriptions),1) AS conversion_percentage
FROM next_plan_cte
WHERE next_plan IS NOT NULL 
  AND plan_id = 0
GROUP BY next_plan
ORDER BY next_plan;

#What is the customer count and percentage breakdown of all 5 plan_name values at 2020–12–31?

WITH next_plan AS(
SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(start_date, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as next_date
FROM foodie_fi.subscriptions
WHERE start_date <= '2020-12-31'
),
-- Find customer breakdown with existing plans on or after 31 Dec 2020
customer_breakdown AS (
  SELECT 
    plan_id, 
    COUNT(DISTINCT customer_id) AS customers
  FROM next_plan
  WHERE 
    (next_date IS NOT NULL AND (start_date < '2020-12-31' 
      AND next_date > '2020-12-31'))
    OR (next_date IS NULL AND start_date < '2020-12-31')
  GROUP BY plan_id)

SELECT plan_id, customers, 
  ROUND(100 * customers/ (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.subscriptions),1) AS percentage
FROM customer_breakdown
GROUP BY plan_id, customers
ORDER BY plan_id;

#How many customers have upgraded to an annual plan in 2020?
SELECT 
  COUNT(DISTINCT customer_id) AS unique_customer
FROM foodie_fi.subscriptions
WHERE plan_id = 3
  AND start_date <= '2020-12-31';
  
#How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- Filter results to customers at trial plan = 0
WITH trial_plan AS 
  (SELECT 
    customer_id, 
    start_date AS trial_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 0
),
-- Filter results to customers at pro annual plan = 3
annual_plan AS
  (SELECT 
    customer_id, 
    start_date AS annual_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 3
)

SELECT 
  ROUND(AVG(annual_date - trial_date),0) AS avg_days_to_upgrade
FROM trial_plan tp
JOIN annual_plan ap
  ON tp.customer_id = ap.customer_id; 
  
# Can you further breakdown this average value into 30 day periods (i.e. 0–30 days, 31–60 days etc)
-- Filter results to customers at trial plan = 0
WITH trial_plan AS 
  (SELECT 
    customer_id, 
    start_date AS trial_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 0
),
-- Filter results to customers at pro annual plan = 3
annual_plan AS
  (SELECT 
    customer_id, 
    start_date AS annual_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 3
),
-- Sort values above in buckets of 12 with range of 30 days each
bins AS 
  (SELECT 
    WIDTH_BUCKET(ap.annual_date - tp.trial_date, 0, 360, 12) AS     avg_days_to_upgrade
  FROM trial_plan tp
  JOIN annual_plan ap
    ON tp.customer_id = ap.customer_id)
  
SELECT 
  ((avg_days_to_upgrade - 1) * 30 || ' - ' ||   (avg_days_to_upgrade) * 30) || ' days' AS breakdown, 
  COUNT(*) AS customers
FROM bins
GROUP BY avg_days_to_upgrade
ORDER BY avg_days_to_upgrade;

-- Create a temporary table for trial_plan
CREATE TEMPORARY TABLE trial_plan AS 
SELECT 
  customer_id, 
  start_date AS trial_date
FROM foodie_fi.subscriptions
WHERE plan_id = 0;

-- Create a temporary table for annual_plan
CREATE TEMPORARY TABLE annual_plan AS
SELECT 
  customer_id, 
  start_date AS annual_date
FROM foodie_fi.subscriptions
WHERE plan_id = 3;

-- Create a temporary table for bins
CREATE TEMPORARY TABLE bins AS 
SELECT 
  FLOOR(DATEDIFF(ap.annual_date, tp.trial_date) / 30) + 1 AS avg_days_to_upgrade
FROM trial_plan tp
JOIN annual_plan ap
  ON tp.customer_id = ap.customer_id;

-- Query to calculate breakdown and count of customers
SELECT 
  CONCAT(((avg_days_to_upgrade - 1) * 30), ' - ', (avg_days_to_upgrade * 30), ' days') AS breakdown, 
  COUNT(*) AS customers
FROM bins
GROUP BY avg_days_to_upgrade
ORDER BY avg_days_to_upgrade;

#How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- Filter results to customers at trial plan = 0
WITH trial_plan AS 
  (SELECT 
    customer_id, 
    start_date AS trial_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 0
),
-- Filter results to customers at pro annual plan = 3
annual_plan AS
  (SELECT 
    customer_id, 
    start_date AS annual_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 3
)

SELECT 
  ROUND(AVG(annual_date - trial_date),0) AS avg_days_to_upgrade
FROM trial_plan tp
JOIN annual_plan ap
  ON tp.customer_id = ap.customer_id;
  
#Can you further breakdown this average value into 30 day periods (i.e. 0–30 days, 31–60 days etc)
-- Filter results to customers at trial plan = 0
WITH trial_plan AS 
  (SELECT 
    customer_id, 
    start_date AS trial_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 0
),
-- Filter results to customers at pro annual plan = 3
annual_plan AS
  (SELECT 
    customer_id, 
    start_date AS annual_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 3
),
-- Sort values above in buckets of 12 with range of 30 days each
bins AS 
  (SELECT 
    WIDTH_BUCKET(ap.annual_date - tp.trial_date, 0, 360, 12) AS avg_days_to_upgrade
  FROM trial_plan tp
  JOIN annual_plan ap
    ON tp.customer_id = ap.customer_id)
  
SELECT 
  ((avg_days_to_upgrade - 1) * 30 || ' - ' ||   (avg_days_to_upgrade) * 30) || ' days' AS breakdown, 
  COUNT(*) AS customers
FROM bins
GROUP BY avg_days_to_upgrade
ORDER BY avg_days_to_upgrade;
