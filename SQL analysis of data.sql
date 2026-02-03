-- QUERY 1: Top 10 Worst Trading Days Across All Markets
SELECT 
    date,
    index_name,
    country,
    daily_change_percent,
    close,
    volume
FROM market_index_data
ORDER BY daily_change_percent ASC
LIMIT 10;

--QUERY 2: Markets with Highest Volatility
SELECT 
    index_name,
    region,
    COUNT(*) as total_days,
    ROUND(STDDEV(daily_change_percent), 2) as volatility,
    ROUND(AVG(daily_change_percent), 2) as avg_return
FROM market_index_data
GROUP BY index_name, region
HAVING STDDEV(daily_change_percent) > 2.0  -- Only high volatility markets
ORDER BY volatility DESC;


-- QUERY 3: Monthly Performance Patterns
SELECT 
    month,
    month_name,
    COUNT(DISTINCT index_name) as markets_analyzed,
    ROUND(AVG(daily_change_percent), 3) as avg_return,
    ROUND(STDDEV(daily_change_percent), 2) as volatility,
    SUM(CASE WHEN daily_change_percent > 0 THEN 1 ELSE 0 END) as positive_days,
    SUM(CASE WHEN daily_change_percent < 0 THEN 1 ELSE 0 END) as negative_days
FROM market_index_data
GROUP BY month, month_name
ORDER BY month;


-- QUERY 4: Developed vs Emerging Markets Performance
SELECT 
    market_type,
    COUNT(DISTINCT index_name) as num_markets,
    COUNT(*) as total_observations,
    ROUND(AVG(daily_change_percent), 3) as avg_daily_return,
    ROUND(STDDEV(daily_change_percent), 2) as volatility,
    ROUND(MIN(daily_change_percent), 2) as worst_day,
    ROUND(MAX(daily_change_percent), 2) as best_day,
    ROUND(AVG(volume), 0) as avg_volume
FROM market_index_data
GROUP BY market_type
ORDER BY avg_daily_return DESC;


-- QUERY 5: Quarterly Performance Trends
SELECT 
    quarter,
    region,
    COUNT(DISTINCT year) as years_analyzed,
    ROUND(AVG(daily_change_percent), 3) as avg_return,
    ROUND(STDDEV(daily_change_percent), 2) as volatility,
    COUNT(*) as total_days,
    ROUND(SUM(CASE WHEN daily_change_percent > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) as win_rate
FROM market_index_data
GROUP BY quarter, region
ORDER BY quarter, region;


-- QUERY 6- High Risk Period Detection
SELECT 
    Date,
    ROUND(STDDEV(Daily_Change_Percent), 2) AS Daily_Market_Volatility
FROM market_index_data
GROUP BY Date
ORDER BY Daily_Market_Volatility DESC
LIMIT 10;

-- QUERY 7- Day of Week Performance Pattern
SELECT 
    Day_of_Week,
    ROUND(AVG(Daily_Change_Percent), 2) AS Avg_Return
FROM market_index_data
GROUP BY Day_of_Week
ORDER BY Avg_Return DESC;


--QUERY 8 - Year-over-Year Performance Change (Advanced)
WITH yearly_returns AS (
    SELECT 
        Index_Name,
        Year,
        ROUND(AVG(Daily_Change_Percent), 2) AS Avg_Return
    FROM market_index_data
    GROUP BY Index_Name, Year
)

SELECT 
    Index_Name,
    Year,
    Avg_Return,
    Avg_Return - LAG(Avg_Return) OVER (PARTITION BY Index_Name ORDER BY Year) AS YoY_Change
FROM yearly_returns
ORDER BY Index_Name, Year;


--QUERY 9
-- Market Drawdown Detection (Biggest Loss Streaks)
-- This finds periods where returns stayed negative consecutively.
WITH negative_days AS (
    SELECT
        Date,
        Index_Name,
        Daily_Change_Percent,
        CASE 
            WHEN Daily_Change_Percent < 0 THEN 1 
            ELSE 0 
        END AS Is_Negative
    FROM market_index_data
),

grouped_streaks AS (
    SELECT
        Date,
        Index_Name,
        Is_Negative,
        ROW_NUMBER() OVER (PARTITION BY Index_Name ORDER BY Date)
        - ROW_NUMBER() OVER (PARTITION BY Index_Name, Is_Negative ORDER BY Date) AS Streak_Group
    FROM negative_days
),

negative_streaks AS (
    SELECT
        Index_Name,
        COUNT(*) AS Negative_Days_Streak
    FROM grouped_streaks
    WHERE Is_Negative = 1
    GROUP BY Index_Name, Streak_Group
)

SELECT
    Index_Name,
    MAX(Negative_Days_Streak) AS Worst_Drawdown_Streak
FROM negative_streaks
GROUP BY Index_Name
ORDER BY Worst_Drawdown_Streak DESC;


-- QUERY 10 - Identifying Consistently High Performing Markets (Stability + Performance)
WITH yearly_perf AS (
    SELECT
        Index_Name,
        Year,
        AVG(Daily_Change_Percent) AS Avg_Return
    FROM market_index_data
    GROUP BY Index_Name, Year
),

ranked_yearly_perf AS (
    SELECT
        Index_Name,
        Year,
        Avg_Return,
        DENSE_RANK() OVER (
            PARTITION BY Year
            ORDER BY Avg_Return DESC
        ) AS Year_Rank
    FROM yearly_perf
)

SELECT
    Index_Name,
    COUNT(*) AS Times_in_Top_3
FROM ranked_yearly_perf
WHERE Year_Rank <= 3
GROUP BY Index_Name
ORDER BY Times_in_Top_3 DESC;
