-- =====================================================================
-- 02_star_schema.sql
-- Purpose : Split the flat raw table into a star schema:
--           dim_participant, dim_platform and fact_social_media_behavior.
-- Run after 01_data_quality_checks.sql. Safe to re-run (drops the 3 tables first).
-- =====================================================================

USE social_media_analytics;

DROP TABLE IF EXISTS fact_social_media_behavior;
DROP TABLE IF EXISTS dim_participant;
DROP TABLE IF EXISTS dim_platform;

-- ---------- Dimension tables ----------
CREATE TABLE dim_participant (
    participant_key   INT AUTO_INCREMENT PRIMARY KEY,
    participant_id    VARCHAR(10),
    age               INT,
    gender            VARCHAR(20),
    education_level   VARCHAR(30),
    employment_status VARCHAR(30)
);

CREATE TABLE dim_platform (
    platform_key     INT AUTO_INCREMENT PRIMARY KEY,
    primary_platform VARCHAR(30)
);

-- ---------- Fact table ----------
CREATE TABLE fact_social_media_behavior (
    fact_key        INT AUTO_INCREMENT PRIMARY KEY,
    participant_key INT,
    platform_key    INT,

    avg_daily_sm_hours    DOUBLE,
    daily_check_frequency VARCHAR(30),
    late_night_scrolling  VARCHAR(20),

    avg_sleep_hours DOUBLE,
    sleep_quality   VARCHAR(20),

    dopamine_rush_feel_score DOUBLE,
    fomo_score               DOUBLE,

    attention_span_minutes     INT,
    deep_work_duration_minutes INT,

    productivity_self_rating DOUBLE,
    tasks_completed_per_day  INT,

    decision_fatigue_score DOUBLE,

    withdrawal_attempt_count INT,
    longest_detox_days       INT,

    severity_stage               VARCHAR(50),
    productivity_decline_score   VARCHAR(20),
    dopamine_dysregulation_index DOUBLE,
    digital_wellbeing_score      DOUBLE,
    sm_addiction_risk_score      DOUBLE,

    FOREIGN KEY (participant_key) REFERENCES dim_participant(participant_key),
    FOREIGN KEY (platform_key)    REFERENCES dim_platform(platform_key)
);

-- ---------- Load the dimensions ----------
INSERT INTO dim_participant (participant_id, age, gender, education_level, employment_status)
SELECT DISTINCT participant_id, age, gender, education_level, employment_status
FROM social_media_dopamine_productivity;

INSERT INTO dim_platform (primary_platform)
SELECT DISTINCT primary_platform
FROM social_media_dopamine_productivity;

-- ---------- Load the fact table (joins turn names into keys) ----------
INSERT INTO fact_social_media_behavior (
    participant_key, platform_key,
    avg_daily_sm_hours, daily_check_frequency, late_night_scrolling,
    avg_sleep_hours, sleep_quality,
    dopamine_rush_feel_score, fomo_score,
    attention_span_minutes, deep_work_duration_minutes,
    productivity_self_rating, tasks_completed_per_day,
    decision_fatigue_score,
    withdrawal_attempt_count, longest_detox_days,
    severity_stage, productivity_decline_score, dopamine_dysregulation_index,
    digital_wellbeing_score, sm_addiction_risk_score
)
SELECT
    dp.participant_key, dpl.platform_key,
    s.avg_daily_sm_hours, s.daily_check_frequency, s.late_night_scrolling,
    s.avg_sleep_hours, s.sleep_quality,
    s.dopamine_rush_feel_score, s.fomo_score,
    s.attention_span_minutes, s.deep_work_duration_minutes,
    s.productivity_self_rating, s.tasks_completed_per_day,
    s.decision_fatigue_score,
    s.withdrawal_attempt_count, s.longest_detox_days,
    s.severity_stage, s.productivity_decline_score, s.dopamine_dysregulation_index,
    s.digital_wellbeing_score, s.sm_addiction_risk_score
FROM social_media_dopamine_productivity s
JOIN dim_participant dp  ON s.participant_id   = dp.participant_id
JOIN dim_platform    dpl ON s.primary_platform = dpl.primary_platform;

-- ---------- Check the load ----------
-- All three counts below should match (raw rows = fact rows). If the fact
-- table has MORE rows, a participant_id is duplicated in the raw data.
SELECT COUNT(*) AS raw_rows  FROM social_media_dopamine_productivity;
SELECT COUNT(*) AS fact_rows FROM fact_social_media_behavior;
SELECT COUNT(*) AS participants FROM dim_participant;
SELECT COUNT(*) AS platforms    FROM dim_platform;
