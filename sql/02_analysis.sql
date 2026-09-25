-- Q1: Median price and number of sales per year
SELECT sale_year,
       COUNT(*) AS sales,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)::int AS median_price
FROM sales_clean
GROUP BY sale_year
ORDER BY sale_year;

-- Q2: Median price by property type and year
SELECT sale_year,
       property_type_label,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)::int AS median_price
FROM sales_clean
GROUP BY sale_year, property_type_label
ORDER BY property_type_label, sale_year;

-- Q3: New build premium each year
SELECT sale_year,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)
           FILTER (WHERE new_build = 'Y')::int AS median_new_build,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)
           FILTER (WHERE new_build = 'N')::int AS median_existing
FROM sales_clean
GROUP BY sale_year
ORDER BY sale_year;

-- Q4: Top 10 most expensive postcode districts in 2025 (min 100 sales)
SELECT postcode_district,
       COUNT(*) AS sales,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)::int AS median_price
FROM sales_clean
WHERE sale_year = 2025
GROUP BY postcode_district
HAVING COUNT(*) >= 100
ORDER BY median_price DESC
LIMIT 10;

-- Q4.2: Top 10 most expensive postcode districts in 2025 (min 100 sales)
SELECT postcode_district,
       COUNT(*) AS sales,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)::int AS median_price
FROM sales_clean
WHERE sale_year = 2025
GROUP BY postcode_district
HAVING COUNT(*) >= 100
ORDER BY median_price ASC
LIMIT 10;

-- Q5: Year-on-year median price growth by county, 2025 vs 2024
WITH yearly AS (
    SELECT county,
           sale_year,
           COUNT(*) AS sales,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median_price
    FROM sales_clean
    GROUP BY county, sale_year
),
growth AS (
    SELECT county,
           sale_year,
           sales,
           median_price::int AS median_price,
           LAG(median_price) OVER (PARTITION BY county ORDER BY sale_year)::int AS prev_year_median,
           ROUND((100 * (median_price - LAG(median_price) OVER (PARTITION BY county ORDER BY sale_year))
                  / LAG(median_price) OVER (PARTITION BY county ORDER BY sale_year))::numeric, 1) AS yoy_growth_pct
    FROM yearly
)
SELECT *
FROM growth
WHERE sale_year = 2025 AND sales >= 500
ORDER BY yoy_growth_pct DESC;

-- Q6: Share of sales by month (2022-2025, excluding 2021 stamp duty distortion)
SELECT sale_month,
       COUNT(*) AS sales,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_sales
FROM sales_clean
WHERE sale_year BETWEEN 2022 AND 2025
GROUP BY sale_month
ORDER BY sale_month;