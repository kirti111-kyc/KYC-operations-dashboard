-- KYC DASHBOARD: SQL PRACTICE PACK
-- Database: kyc_dashboard.db (SQLite). All data is synthetic. "As of" date is 2026-09-30.
-- Tables: customers, kyc_cases, screening_alerts, analysts
-- Tip: run each query, then say out loud what business question it answers.

-- Q1. How many cases are in each status? (basic GROUP BY)
SELECT status, COUNT(*) AS cases
FROM kyc_cases
GROUP BY status
ORDER BY cases DESC;

-- Q2. Average turnaround time (TAT) and SLA breach rate by risk rating, closed cases only
SELECT risk_rating,
       COUNT(*)                                   AS closed_cases,
       ROUND(AVG(tat_days), 1)                    AS avg_tat_days,
       ROUND(100.0 * AVG(sla_breached), 1)        AS sla_breach_pct
FROM kyc_cases
WHERE status = 'Closed'
GROUP BY risk_rating
ORDER BY CASE risk_rating WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END;

-- Q3. False-positive rate by alert type (resolved alerts only)
SELECT alert_type,
       COUNT(*)                                                        AS resolved_alerts,
       SUM(CASE WHEN outcome = 'False Positive' THEN 1 ELSE 0 END)     AS false_positives,
       ROUND(100.0 * SUM(CASE WHEN outcome = 'False Positive' THEN 1 ELSE 0 END) / COUNT(*), 1) AS fp_rate_pct
FROM screening_alerts
WHERE outcome <> 'Open'
GROUP BY alert_type;

-- Q4. Customers by country risk tier and risk rating (JOIN-free pivot with CASE)
SELECT country_risk_tier,
       SUM(CASE WHEN risk_rating = 'Low'    THEN 1 ELSE 0 END) AS low,
       SUM(CASE WHEN risk_rating = 'Medium' THEN 1 ELSE 0 END) AS medium,
       SUM(CASE WHEN risk_rating = 'High'   THEN 1 ELSE 0 END) AS high
FROM customers
GROUP BY country_risk_tier;

-- Q5. EDD backlog: open EDD cases with their age, oldest first (JOIN)
SELECT k.case_id, c.customer_name, c.country, k.risk_rating, k.status, k.age_days, k.sla_days
FROM kyc_cases k
JOIN customers c ON c.customer_id = k.customer_id
WHERE k.edd_required = 1 AND k.status <> 'Closed'
ORDER BY k.age_days DESC
LIMIT 15;

-- Q6. Monthly case volume opened (date functions)
SELECT SUBSTR(opened_date, 1, 7) AS month, COUNT(*) AS cases_opened
FROM kyc_cases
GROUP BY month
ORDER BY month;

-- Q7. Monthly volume with a 3-month moving average (window function)
WITH monthly AS (
  SELECT SUBSTR(opened_date, 1, 7) AS month, COUNT(*) AS cases_opened
  FROM kyc_cases
  GROUP BY month
)
SELECT month,
       cases_opened,
       ROUND(AVG(cases_opened) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 1) AS moving_avg_3m
FROM monthly
ORDER BY month;

-- Q8. Analyst productivity and quality: cases closed, avg TAT, QC pass rate (JOIN + aggregates)
SELECT a.analyst_id, a.analyst_name, a.employment,
       COUNT(*)                                                                    AS closed_cases,
       ROUND(AVG(k.tat_days), 1)                                                   AS avg_tat,
       ROUND(100.0 * SUM(CASE WHEN k.qc_result = 'Pass' THEN 1 ELSE 0 END) / COUNT(*), 1) AS qc_pass_pct
FROM kyc_cases k
JOIN analysts a ON a.analyst_id = k.analyst_id
WHERE k.status = 'Closed'
GROUP BY a.analyst_id, a.analyst_name, a.employment
ORDER BY closed_cases DESC;

-- Q9. Rank analysts by QC pass rate within their team (RANK window function)
WITH perf AS (
  SELECT a.team, a.analyst_id, a.analyst_name,
         COUNT(*) AS closed_cases,
         100.0 * SUM(CASE WHEN k.qc_result = 'Pass' THEN 1 ELSE 0 END) / COUNT(*) AS qc_pass_pct
  FROM kyc_cases k JOIN analysts a ON a.analyst_id = k.analyst_id
  WHERE k.status = 'Closed'
  GROUP BY a.team, a.analyst_id, a.analyst_name
)
SELECT team, analyst_name, closed_cases, ROUND(qc_pass_pct, 1) AS qc_pass_pct,
       RANK() OVER (PARTITION BY team ORDER BY qc_pass_pct DESC) AS rank_in_team
FROM perf
ORDER BY team, rank_in_team;

-- Q10. Customers with 2 or more true-match alerts (subquery / HAVING)
SELECT c.customer_id, c.customer_name, c.country, c.risk_rating, COUNT(*) AS true_matches
FROM screening_alerts s
JOIN customers c ON c.customer_id = s.customer_id
WHERE s.outcome = 'True Match'
GROUP BY c.customer_id, c.customer_name, c.country, c.risk_rating
HAVING COUNT(*) >= 2
ORDER BY true_matches DESC;

-- Q11. Top 5 countries by number of high-risk customers (and share of that country's customers)
SELECT country,
       SUM(CASE WHEN risk_rating = 'High' THEN 1 ELSE 0 END)                         AS high_risk_customers,
       COUNT(*)                                                                       AS all_customers,
       ROUND(100.0 * SUM(CASE WHEN risk_rating = 'High' THEN 1 ELSE 0 END) / COUNT(*), 1) AS high_risk_pct
FROM customers
GROUP BY country
ORDER BY high_risk_customers DESC
LIMIT 5;

-- Q12. Cases that breached SLA, with how many days late (CTE, closed cases)
WITH late AS (
  SELECT case_id, risk_rating, case_type, tat_days, sla_days, tat_days - sla_days AS days_late
  FROM kyc_cases
  WHERE status = 'Closed' AND sla_breached = 1
)
SELECT risk_rating, case_type, COUNT(*) AS late_cases, ROUND(AVG(days_late), 1) AS avg_days_late, MAX(days_late) AS worst
FROM late
GROUP BY risk_rating, case_type
ORDER BY late_cases DESC;

-- Q13. Data-quality check: alerts without a matching case (should return 0 rows)
SELECT s.alert_id
FROM screening_alerts s
LEFT JOIN kyc_cases k ON k.case_id = s.case_id
WHERE k.case_id IS NULL;

-- Q14. Cumulative closed cases by month (running total window function)
WITH closed_m AS (
  SELECT SUBSTR(closed_date, 1, 7) AS month, COUNT(*) AS closed
  FROM kyc_cases
  WHERE status = 'Closed'
  GROUP BY month
)
SELECT month, closed, SUM(closed) OVER (ORDER BY month) AS cumulative_closed
FROM closed_m
ORDER BY month;
