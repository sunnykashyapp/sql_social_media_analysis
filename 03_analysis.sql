-- =====================================================================
-- 03_analysis.sql
-- Purpose : Analyse how social media use relates to dopamine dysregulation,
--           productivity, sleep and addiction risk.
-- Run after 02_star_schema.sql.
-- Tip: before running, check the real value ranges and category names
--      from 01_data_quality_checks.sql (min/max and distinct values).
-- =====================================================================

USE social_media_analytics;

-- ---------- 1. Usage quartiles (CTE + NTILE) ----------
-- Splits participants into 4 equal groups by daily social media hours,
-- then compares dysregulation and productivity across the groups.
WITH usage_quartiles AS (
    SELECT
        avg_daily_sm_hours,
        dopamine_dysregulation_index,
        productivity_self_rating,
        NTILE(4) OVER (ORDER BY avg_daily_sm_hours) AS usage_quartile
    FROM fact_social_media_behavior
)
SELECT
    usage_quartile,
    ROUND(AVG(avg_daily_sm_hours), 2)           AS avg_usage_hours,
    ROUND(AVG(dopamine_dysregulation_index), 2) AS avg_dysregulation,
    ROUND(AVG(productivity_self_rating), 2)     AS avg_productivity,
    COUNT(*)                                    AS num_participants
FROM usage_quartiles
GROUP BY usage_quartile
ORDER BY usage_quartile;

-- ---------- 2. Correlation: usage vs dysregulation ----------
-- Pearson correlation = (avg(x*y) - avg(x)*avg(y)) / (stddev(x) * stddev(y))
-- Result is between -1 and 1. Close to 0 means little linear relationship.
SELECT
    (AVG(avg_daily_sm_hours * dopamine_dysregulation_index)
        - AVG(avg_daily_sm_hours) * AVG(dopamine_dysregulation_index))
    / (STDDEV_POP(avg_daily_sm_hours) * STDDEV_POP(dopamine_dysregulation_index))
    AS correlation_usage_vs_dysregulation
FROM fact_social_media_behavior;

-- ---------- 3. Usage level buckets (CASE) ----------
SELECT
    CASE
        WHEN avg_daily_sm_hours < 3 THEN 'Low usage (under 3h)'
        WHEN avg_daily_sm_hours < 6 THEN 'Medium usage (3 to under 6h)'
        ELSE 'High usage (6h or more)'
    END AS usage_bucket,
    ROUND(AVG(fomo_score), 2)                   AS avg_fomo,
    ROUND(AVG(dopamine_rush_feel_score), 2)     AS avg_dopamine_rush,
    ROUND(AVG(dopamine_dysregulation_index), 2) AS avg_dysregulation,
    COUNT(*)                                    AS num_participants
FROM fact_social_media_behavior
GROUP BY usage_bucket;

-- ---------- 4. Platforms above the overall average dysregulation (HAVING) ----------
SELECT
    dpl.primary_platform,
    ROUND(AVG(f.dopamine_dysregulation_index), 2) AS avg_dysregulation,
    COUNT(*) AS num_participants
FROM fact_social_media_behavior f
JOIN dim_platform dpl ON f.platform_key = dpl.platform_key
GROUP BY dpl.primary_platform
HAVING AVG(f.dopamine_dysregulation_index) >
       (SELECT AVG(dopamine_dysregulation_index) FROM fact_social_media_behavior)
ORDER BY avg_dysregulation DESC;

-- ---------- 5. Highest-risk participants (window function RANK) ----------
-- Higher sm_addiction_risk_score = higher risk (same direction as query 7).
SELECT
    dp.participant_id,
    f.avg_daily_sm_hours,
    f.sm_addiction_risk_score,
    RANK() OVER (ORDER BY f.sm_addiction_risk_score DESC) AS risk_rank
FROM fact_social_media_behavior f
JOIN dim_participant dp ON f.participant_key = dp.participant_key
ORDER BY risk_rank
LIMIT 10;

-- ---------- 6. ROW_NUMBER vs RANK vs DENSE_RANK ----------
-- ROW_NUMBER: always unique (1,2,3,4)
-- RANK: ties share a rank, then skips   (1,2,2,4)
-- DENSE_RANK: ties share a rank, no skip (1,2,2,3)
SELECT
    participant_key,
    dopamine_dysregulation_index,
    ROW_NUMBER() OVER (ORDER BY dopamine_dysregulation_index DESC) AS row_num,
    RANK()       OVER (ORDER BY dopamine_dysregulation_index DESC) AS rank_with_gaps,
    DENSE_RANK() OVER (ORDER BY dopamine_dysregulation_index DESC) AS dense_rank_no_gaps
FROM fact_social_media_behavior
ORDER BY row_num
LIMIT 20;

-- ---------- 7. Addiction risk levels (CASE + GROUP BY) ----------
SELECT
    CASE
        WHEN sm_addiction_risk_score < 4 THEN '1 Low'
        WHEN sm_addiction_risk_score < 6 THEN '2 Moderate'
        WHEN sm_addiction_risk_score < 8 THEN '3 High'
        ELSE '4 Very high'
    END AS risk_level,
    COUNT(*) AS num_participants
FROM fact_social_media_behavior
GROUP BY risk_level
ORDER BY risk_level;

-- ---------- 8. Sleep groups (CASE) ----------
SELECT
    CASE
        WHEN avg_sleep_hours < 6 THEN 'Sleep deprived (under 6h)'
        WHEN avg_sleep_hours < 8 THEN 'Adequate (6 to under 8h)'
        ELSE 'Well rested (8h or more)'
    END AS sleep_group,
    ROUND(AVG(productivity_self_rating), 2) AS avg_productivity,
    COUNT(*) AS num_participants
FROM fact_social_media_behavior
GROUP BY sleep_group;

-- ---------- 9. Age groups (CASE, join) ----------
SELECT
    CASE
        WHEN dp.age < 25  THEN 'Under 25'
        WHEN dp.age <= 40 THEN '25 to 40'
        WHEN dp.age <= 50 THEN '41 to 50'
        ELSE 'Over 50'
    END AS age_group,
    ROUND(AVG(f.avg_daily_sm_hours), 2)      AS avg_usage_hours,
    ROUND(AVG(f.sm_addiction_risk_score), 2) AS avg_risk_score,
    COUNT(*) AS num_participants
FROM fact_social_media_behavior f
JOIN dim_participant dp ON f.participant_key = dp.participant_key
GROUP BY age_group;

-- ---------- 10. Burnout flag (CASE with AND / IN) ----------
-- Check the real sleep_quality values first:  SELECT DISTINCT sleep_quality FROM fact_social_media_behavior;
SELECT
    CASE
        WHEN sleep_quality IN ('Poor', 'Very poor') AND dopamine_rush_feel_score > 7
        THEN 'Yes'
        ELSE 'No'
    END AS burnout_risk,
    COUNT(*) AS num_participants
FROM fact_social_media_behavior
GROUP BY burnout_risk;

-- ---------- 11. Daily late-night scrollers by employment status ----------
-- Conditional aggregation: count and average only the 'Daily' rows.
SELECT
    p.employment_status,
    SUM(CASE WHEN q.late_night_scrolling = 'Daily' THEN 1 ELSE 0 END) AS daily_late_night_scrollers,
    ROUND(AVG(CASE WHEN q.late_night_scrolling = 'Daily' THEN q.sm_addiction_risk_score END), 2) AS avg_risk_of_those
FROM dim_participant p
JOIN fact_social_media_behavior q ON p.participant_key = q.participant_key
GROUP BY p.employment_status;

-- ---------- 12. Compare each person with the overall average (subquery) ----------
SELECT
    dp.participant_id,
    f.productivity_self_rating,
    ROUND((SELECT AVG(productivity_self_rating) FROM fact_social_media_behavior), 2) AS overall_avg,
    ROUND(f.productivity_self_rating
          - (SELECT AVG(productivity_self_rating) FROM fact_social_media_behavior), 2) AS diff_from_avg
FROM fact_social_media_behavior f
JOIN dim_participant dp ON f.participant_key = dp.participant_key
ORDER BY diff_from_avg ASC
LIMIT 10;
