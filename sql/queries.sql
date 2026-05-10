-- =============================================================
-- ETL Pipeline — Validation & Analysis Queries
-- Dataset: Chicago Food Inspections
-- =============================================================

USE etl_pipeline;


-- 1. Total row count — should match your DataFrame row count
SELECT COUNT(*) AS total_rows
FROM food_inspections;

-- 2. Check for duplicate inspection IDs — should return 0
SELECT inspection_id, COUNT(*) AS count
FROM food_inspections
GROUP BY inspection_id
HAVING COUNT(*) > 1
LIMIT 10;

-- 3. Null check on critical columns — all should be 0
SELECT
    SUM(CASE WHEN business_name   IS NULL THEN 1 ELSE 0 END) AS null_business_name,
    SUM(CASE WHEN inspection_date IS NULL THEN 1 ELSE 0 END) AS null_inspection_date,
    SUM(CASE WHEN results         IS NULL THEN 1 ELSE 0 END) AS null_results,
    SUM(CASE WHEN risk_level      IS NULL THEN 1 ELSE 0 END) AS null_risk_level
FROM food_inspections;

-- 4. Distinct results values — validate no unexpected categories slipped in
SELECT results, COUNT(*) AS count
FROM food_inspections
GROUP BY results
ORDER BY count DESC;

-- 5. Date range check — inspect earliest and latest inspection dates
SELECT
    MIN(inspection_date) AS earliest_inspection,
    MAX(inspection_date) AS latest_inspection
FROM food_inspections;


-- 6. Pass vs Fail rate overall
SELECT
    results,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM food_inspections
GROUP BY results
ORDER BY total DESC;

-- 7. Inspections by risk level
SELECT
    risk_level,
    COUNT(*)  AS total_inspections,
    SUM(is_fail) AS total_fails,
    ROUND(SUM(is_fail) * 100.0 / COUNT(*), 2) AS fail_rate_pct
FROM food_inspections
GROUP BY risk_level
ORDER BY fail_rate_pct DESC;

-- 8. Top 10 facility types by inspection volume
SELECT
    facility_type,
    COUNT(*) AS total_inspections
FROM food_inspections
GROUP BY facility_type
ORDER BY total_inspections DESC
LIMIT 10;

-- 9. Yearly inspection trend
SELECT
    inspection_year,
    COUNT(*) AS total_inspections,
    SUM(is_pass) AS total_pass,
    SUM(is_fail) AS total_fail
FROM food_inspections
WHERE inspection_year IS NOT NULL
GROUP BY inspection_year
ORDER BY inspection_year;

-- 10. Average violations per inspection by risk level
SELECT
    risk_level,
    ROUND(AVG(violation_count), 2) AS avg_violations
FROM food_inspections
GROUP BY risk_level
ORDER BY avg_violations DESC;

-- 11. Top 10 most inspected businesses
SELECT
    business_name,
    COUNT(*) AS inspection_count,
    SUM(is_fail) AS total_fails
FROM food_inspections
GROUP BY business_name
ORDER BY inspection_count DESC
LIMIT 10;

-- 12. Monthly inspection volume (seasonality check)
SELECT
    inspection_month,
    COUNT(*) AS total_inspections
FROM food_inspections
WHERE inspection_month IS NOT NULL
GROUP BY inspection_month
ORDER BY inspection_month;