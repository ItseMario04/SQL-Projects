SELECT *
FROM user_events
LIMIT 20;

WITH funnel_stages AS (
	SELECT 
		COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage_1_views,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage_2_cart,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
        COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage_4_payment,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage_5_purchase
	FROM user_events
    -- WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)) 
)
SELECT * 
FROM funnel_stages;

-- conversion rates through the funnel

WITH funnel_stages AS (
	SELECT 
		COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage_1_views,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage_2_cart,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
        COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage_4_payment,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage_5_purchase
	FROM user_events
    -- WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)) 
)
SELECT  
	stage_1_views,
    stage_2_cart,
    ROUND(stage_2_cart * 100 / stage_1_views, 1) AS cart_to_views_ratio,
    
    stage_3_checkout,
	ROUND(stage_3_checkout * 100 / stage_2_cart, 1) AS checkout_to_cart_ratio,
    
    stage_4_payment,
	ROUND(stage_4_payment * 100 / stage_3_checkout, 1) AS payment_to_checkout_ratio,
    
    stage_5_purchase,
	ROUND(stage_5_purchase * 100 / stage_4_payment, 1) AS purchase_to_payment_ratio,
	ROUND(stage_5_purchase * 100 / stage_1_views, 1) AS purchase_to_view_ratio

FROM funnel_stages;

-- funnel by source

WITH source_funnel AS(
	SELECT
	traffic_source,
	COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS views,
	COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS carts,
	COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchases
FROM user_events
GROUP BY traffic_source
)
SELECT traffic_source, views, carts, purchases,
ROUND(carts * 100 / views, 1) AS carts_to_views_ratio,
ROUND(purchases * 100 / views, 1) AS purchases_to_views_ratio,
ROUND(purchases * 100 / carts, 1) AS purchases_to_carts_ratio

FROM source_funnel
ORDER BY purchases DESC;


-- time to conversion analysis

WITH user_journey AS(
	SELECT
	user_id,
	MIN(CASE WHEN event_type = 'page_view' THEN event_date END) AS views_time,
	MIN(CASE WHEN event_type = 'add_to_cart' THEN event_date END) AS carts_time,
	MIN(CASE WHEN event_type = 'purchase' THEN event_date END) AS purchases_time
FROM user_events
GROUP BY user_id
HAVING MIN(CASE WHEN event_type = 'purchase' THEN event_date END) IS NOT NULL
)
SELECT 
	COUNT(*) AS converted_users,
	ROUND(AVG(TIMESTAMPDIFF(MINUTE, views_time, carts_time)),2) AS avg_view_to_cart_minutes,
	ROUND(AVG(TIMESTAMPDIFF(MINUTE, carts_time, purchases_time)),2) AS avg_cart_to_purchases_minutes,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, views_time, purchases_time)),2) AS avg_purchases_to_views_minutes
FROM user_journey;

-- revenue funnel analysis

WITH funnel_revenue AS(
	SELECT
	COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_visitors,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS total_buyers,
    SUM(CASE WHEN event_type = 'purchase' THEN amount END) AS total_revenue,
	COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS total_orders
FROM user_events
)
SELECT total_visitors, total_buyers, ROUND(total_revenue,2), total_orders,
ROUND(total_revenue / total_orders,2) AS avg_order_value,
ROUND(total_revenue / total_buyers,2) AS revenue_per_buyer,
ROUND(total_revenue / total_visitors,2) AS revenue_per_visitor
FROM funnel_revenue