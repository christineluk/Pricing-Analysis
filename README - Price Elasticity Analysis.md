# Price Elasticity Analysis


## Overview

This SQL script calculates the price elasticity of demand for different products based on historical sales data. The analysis is conducted in three main steps:

Calculate the average price and quantity sold per product

Determine the price elasticity of demand (PED) per product

Calculate the overall average price elasticity



## SQL Steps Explained


### Step 1: Calculate Average Price and Quantity Sold per Product

This query computes the average unit price and average quantity sold for each product:

SELECT 
    product_id, 
    AVG(unit_price) AS avg_price, 
    AVG(qty) AS avg_qty
FROM retail_data
GROUP BY product_id;

Purpose: Provides a baseline understanding of the typical price and demand per product

### Step 2: Calculate Price Elasticity per Product

This step measures the price elasticity of demand for each product over time:

WITH PriceChange AS (
    SELECT 
        product_id, 
        unit_price AS current_price,
        LAG(unit_price) OVER (PARTITION BY product_id ORDER BY month_year) AS prev_price,
        qty AS current_qty,
        LAG(qty) OVER (PARTITION BY product_id ORDER BY month_year) AS prev_qty
    FROM retail_data
)
SELECT 
    product_id,
    AVG(
        CASE 
            WHEN (current_price - prev_price) = 0 THEN NULL
            ELSE 
                ( (current_qty - prev_qty) / NULLIF(prev_qty, 0) ) /
                ( (current_price - prev_price) / NULLIF(prev_price, 0) )
        END
    ) AS avg_price_elasticity
FROM PriceChange
WHERE prev_price IS NOT NULL 
AND prev_qty IS NOT NULL 
AND (current_price - prev_price) IS DISTINCT FROM 0
GROUP BY product_id;

Purpose:

Uses LAG() to retrieve previous price and quantity values.

Computes the percentage change in price and quantity.

Calculates price elasticity as the ratio of percentage changes.

Filters out zero-price changes to prevent division errors.


### Step 3: Calculate Aggregate Price Elasticity

This query calculates the overall average price elasticity across all products:

SELECT 
    AVG(price_elasticity) AS avg_price_elasticity
FROM (
    WITH PriceChange AS (
        SELECT 
            product_id, 
            unit_price AS current_price,
            LAG(unit_price) OVER (PARTITION BY product_id ORDER BY month_year) AS prev_price,
            qty AS current_qty,
            LAG(qty) OVER (PARTITION BY product_id ORDER BY month_year) AS prev_qty
        FROM retail_data
    )
    SELECT 
        product_id,
        (current_qty - prev_qty) / NULLIF(prev_qty, 0) AS percentage_change_qty,
        (current_price - prev_price) / NULLIF(prev_price, 0) AS percentage_change_price,
        CASE 
            WHEN (current_price - prev_price) = 0 THEN NULL
            ELSE 
                ( (current_qty - prev_qty) / NULLIF(prev_qty, 0) ) /
                ( (current_price - prev_price) / NULLIF(prev_price, 0) )
        END AS price_elasticity
    FROM PriceChange
    WHERE prev_price IS NOT NULL 
    AND prev_qty IS NOT NULL 
    AND (current_price - prev_price) IS DISTINCT FROM 0
) AS elasticity_data
WHERE price_elasticity IS NOT NULL;

Purpose:

Builds on Step 2 to calculate an aggregate measure of price elasticity.

Uses a subquery to handle individual product calculations first.

Filters out invalid values before averaging.



## How to Save and Run This Script


### Saving as a .sql File

Open a text editor (Notepad++, VS Code, or any SQL IDE).

Copy and paste the SQL queries into a new file.

Save the file with a .sql extension (e.g., price_elasticity_analysis.sql).


### Running in pgAdmin 4

Open pgAdmin 4 and connect to your database.

Open the Query Tool.

Load the .sql file or copy-paste the script.

Click Execute (▶) to run the script.



## Results & Analysis
The price elasticity values ranged from **-1,500 to 2,000** for some products, which is significantly outside the typical range (-10 to 10).  
Possible reasons for these extreme values include:
- **Outliers:** Unusual pricing changes may have caused extreme elasticity values.
- **Small dataset:** Limited historical sales data may not provide a reliable measure of price elasticity.
- **Data quality issues:** Errors in price or quantity values could impact calculations.

**Next Steps:**
- Implement outlier detection (e.g., remove extreme percent changes).
- Expand the dataset for better accuracy.
