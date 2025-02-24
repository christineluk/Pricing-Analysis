-- Step 1: Calculate Average Price and Quantity Sold per Product
SELECT 
    product_id, 
    AVG(unit_price) AS avg_price, 
    AVG(qty) AS avg_qty
FROM retail_data
GROUP BY product_id;

-- Step 2: Calculate Price Elasticity per Product
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

-- Step 3: Calculate Price Elasticity in Aggregate	
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
