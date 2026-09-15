SELECT * 
FROM dirty_shipments;

CREATE TABLE shipments
LIKE dirty_shipments;

SELECT * 
FROM shipments
LIMIT 500;

INSERT shipments
SELECT * 
FROM dirty_shipments;
--
-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or blank values
-- 4. Remove any columns
WITH duplicate_cte AS
(
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY shipment_id, origin_warehouse, destination_city, destination_state, carrier, ship_date, delivery_date, weight_kg, freight_cost, shipment_status, items_count, damage_reported) AS row_num
FROM shipments
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- There isn`t any duplicates
-- 2. Standardize the Data

SELECT shipment_id,
TRIM(origin_warehouse), TRIM(destination_city), TRIM(destination_state), TRIM(carrier)
FROM shipments;
UPDATE shipments
SET shipment_id = TRIM(shipment_id),
origin_warehouse = TRIM(origin_warehouse),
destination_city = TRIM(destination_city),
destination_state = TRIM(destination_state),
carrier = TRIM(carrier);

-- in Google BigQuery we could use INICAP() for making all first letters uppercase
SELECT shipment_id,
UPPER(destination_state)
FROM shipments;
UPDATE shipments
SET destination_state = UPPER(destination_state);

SELECT CONCAT(
    UPPER(SUBSTRING(SUBSTRING_INDEX(origin_warehouse, ' ', 1), 1, 1)),
    LOWER(SUBSTRING(SUBSTRING_INDEX(origin_warehouse, ' ', 1), 2)),
    ' ',
    UPPER(SUBSTRING(SUBSTRING_INDEX(origin_warehouse, ' ', -1), 1, 1)),
    LOWER(SUBSTRING(SUBSTRING_INDEX(origin_warehouse, ' ', -1), 2))
) AS origin_warehouse
FROM shipments;
UPDATE shipments
SET origin_warehouse = CONCAT(
    UPPER(SUBSTRING(SUBSTRING_INDEX(origin_warehouse, ' ', 1), 1, 1)),
    LOWER(SUBSTRING(SUBSTRING_INDEX(origin_warehouse, ' ', 1), 2)),
    ' ',
    UPPER(SUBSTRING(SUBSTRING_INDEX(origin_warehouse, ' ', -1), 1, 1)),
    LOWER(SUBSTRING(SUBSTRING_INDEX(origin_warehouse, ' ', -1), 2))
);

SELECT 
    destination_city AS original_text,
    CONCAT(UPPER(SUBSTRING(destination_city, 1, 1)), REGEXP_REPLACE(SUBSTRING(destination_city, 2), '([[:space:]]_---,.)([[:alnum:]])', '$1')) AS formatted_text
FROM shipments;
UPDATE shipments
SET destination_city = CONCAT(
	UPPER(SUBSTRING(destination_city, 1, 1)),
        REGEXP_REPLACE(SUBSTRING(destination_city, 2),
            '([[:space:]]_---,.)([[:alnum:]])',
            '$1')
);

SELECT 
    carrier AS original_text,
    CONCAT(UPPER(SUBSTRING(carrier, 1, 1)), LOWER(SUBSTRING(carrier, 2))) AS formatted_text
FROM shipments;
UPDATE shipments
SET carrier = CONCAT(UPPER(SUBSTRING(carrier, 1, 1)), LOWER(SUBSTRING(carrier, 2)));

SELECT 
    shipment_status AS original_text,
    CONCAT(UPPER(SUBSTRING(shipment_status, 1, 1)), LOWER(SUBSTRING(shipment_status, 2))) AS formatted_text1
   -- CONCAT(UPPER(SUBSTRING(shipment_status, 1, 1)), REGEXP_REPLACE(SUBSTRING(shipment_status, 2), '([[:space:]]_---,.)([[:alnum:]])', '$1')) AS formatted_text2
FROM shipments;
UPDATE shipments
SET shipment_status = CONCAT(UPPER(SUBSTRING(shipment_status, 1, 1)), LOWER(SUBSTRING(shipment_status, 2)));

-- 3. Null Values or blank values

SELECT shipment_id,
CASE
	WHEN damage_reported = 'NULL' OR damage_reported IS NULL OR damage_reported = '' THEN NULL
    ELSE CONCAT(UPPER(SUBSTRING(damage_reported, 1, 1)), LOWER(SUBSTRING(damage_reported, 2)))
END AS damage_reported,
COALESCE(NULLIF(destination_city, ''), 'Unknown') AS destination_city,
COALESCE(NULLIF(delivery_date, ''), 'Not Yet Delivered') AS delivery_date
FROM shipments;
----
UPDATE shipments
SET destination_city = COALESCE(NULLIF(destination_city, ''), 'Unknown'), 
delivery_date = COALESCE(NULLIF(delivery_date, ''), 'Not Yet Delivered'),
damage_reported = CONCAT(UPPER(SUBSTRING(damage_reported, 1, 1)), LOWER(SUBSTRING(damage_reported, 2)));
----
-- Fix Negative & Suspicius Numeric Value

SELECT shipment_id,
CASE
	WHEN weight_kg < 0 THEN ABS(weight_kg)
    WHEN weight_kg = 0 THEN NULL
    ELSE weight_kg
END AS weight_kg_cleaned,
CASE
	WHEN freight_cost < 0 THEN ABS(freight_cost)
    WHEN freight_cost = 0 THEN NULL
    ELSE freight_cost
END AS freight_cost_cleaned,
CASE
	WHEN items_count < 0 THEN ABS(items_count)
    WHEN items_count = 0 THEN NULL
    ELSE items_count
END AS items_count_cleaned
FROM shipments;
-----
UPDATE shipments
SET 
    weight_kg = CASE
        WHEN weight_kg < 0 THEN ABS(weight_kg)
        WHEN weight_kg = 0 THEN NULL
        ELSE weight_kg
    END,
    
    freight_cost = CASE
        WHEN freight_cost < 0 THEN ABS(freight_cost)
        WHEN freight_cost = 0 THEN NULL
        ELSE freight_cost
    END,
    
    items_count = CASE
        WHEN items_count < 0 THEN ABS(items_count)
        WHEN items_count = 0 THEN NULL
        ELSE items_count
    END;
-----
-- ================== Validate Date Logic ============================
-- for google bigQuery: DATEDIFF(SAFE.PARSE_DATE('%Y-%m-%d', delivery_date), SAFE.PARSE_DATE('%Y-%m-%d', ship_date), DAY)
 
SELECT shipment_id, ship_date, delivery_date,
DATEDIFF(
	STR_TO_DATE(NULLIF(delivery_date, ''), '%Y-%m-%d'),
	STR_TO_DATE(NULLIF(ship_date, ''), '%Y-%m-%d')
    )
AS transit_days,

CASE
	WHEN STR_TO_DATE(NULLIF(delivery_date, ''), '%Y-%m-%d') < STR_TO_DATE(NULLIF(ship_date, ''), '%Y-%m-%d') THEN 'INVALID'
    WHEN STR_TO_DATE(NULLIF(delivery_date, ''), '%Y-%m-%d') = STR_TO_DATE(NULLIF(ship_date, ''), '%Y-%m-%d') THEN 'SAME DAY DELIVERY'
    ELSE 'VALID'
END AS date_quality_flag
FROM shipments; 

-- Detect & Cap outliers using percentiles (IQR Method)

-- ======================== for google BigQuery =========================
With stats AS (
	SELECT
		APPROX.QUANTILES(freight_cost, 100)[OFFSET(25)] AS q1,
        APPROX.QUANTILES(freight_cost, 100)[OFFSET(75)] AS q3
	FROM shipments
    WHERE freight_cost > 0
),

bounds AS (
	SELECT
		q1 - 1.5 * (q3 - q1) AS lower_bound,
        q3 + 1.5 * (q3 - q1) AS upper_bound
	FROM stats
)
SELECT
shipment_id, freight_cost AS original_cost,
CASE
	WHEN freight_cost > (SELECT upper_bount from bounds) then (SELECT upper_bound from bounds)
    WHEN freight_cost < (SELECT lower_bount from bounds) then (SELECT lower_bound from bounds)
    ELSE freight_cost
END AS cleaned_cost

CASE
	WHEN freight_cost > (SELECT upper_bount from bounds) OR freight_cost < (SELECT lower_bounds from bounds) then TRUE
    ELSE FALSE
END AS was_outlier
FROM shipments;
-- ======================== for google BigQuery =========================
WITH ranked_data AS (
    SELECT 
        freight_cost,
        PERCENT_RANK() OVER (ORDER BY freight_cost) AS pct
    FROM shipments
    WHERE freight_cost > 0
),
stat AS (
    SELECT 
        MAX(CASE WHEN pct <= 0.25 THEN freight_cost END) AS q1,
        MIN(CASE WHEN pct >= 0.75 THEN freight_cost END) AS q3
    FROM ranked_data
),
bounds AS (
    SELECT 
        q1,
        q3,
        (q1 - 1.5 * (q3 - q1)) AS lower_bound,
        (q3 + 1.5 * (q3 - q1)) AS upper_bound
    FROM stat
)
SELECT 
    s.shipment_id,
    s.freight_cost AS original_cost,
    CASE 
        WHEN s.freight_cost > b.upper_bound THEN b.upper_bound
        WHEN s.freight_cost < b.lower_bound THEN b.lower_bound
        ELSE s.freight_cost
    END AS cleaned_cost,

    CASE 
        WHEN s.freight_cost > b.upper_bound OR s.freight_cost < b.lower_bound THEN TRUE
        ELSE FALSE
    END AS was_outlier

FROM shipments s
CROSS JOIN bounds b;
