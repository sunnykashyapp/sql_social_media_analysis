# Social Media Usage, Dopamine & Productivity Analysis (MySQL)

A SQL project that checks the quality of a social media behaviour dataset, remodels it into a star schema, and analyses how daily social media use relates to dopamine dysregulation, productivity, sleep and addiction risk.

**Tools:** MySQL, MySQL Workbench

## Questions this project answers

1. Do people who use social media more have higher dopamine dysregulation and lower productivity?
2. How strong is the relationship between daily usage hours and dysregulation?
3. Which platforms, age groups and employment groups show the highest risk?
4. How many participants fall into each addiction risk level?

## Dataset

- **Source:** [dataset name and link]
- **Size:** [N] rows and about 60 columns, one row per participant
- **Note:** [This is a synthetic / survey-style dataset. Write the truth here.]
- The raw CSV is not included in this repo. [Download it from the link above and import it into a table named `social_media_dopamine_productivity`.]

## What I did

### 1. Data quality checks (`01_data_quality_checks.sql`)
Checked the raw table for nulls, duplicate participant IDs, extra spaces, inconsistent text case, out-of-range values and distinct values. Instead of typing about 60 columns by hand, I wrote queries on `information_schema.columns` that generate each check for every column.

**Result:** [Write what you found, for example "No nulls or duplicates found" or "X rows had problems, and I fixed them by ..."]

### 2. Star schema (`02_star_schema.sql`)
Split the single flat table into three tables and loaded them with `INSERT ... SELECT` and joins:

- `dim_participant`: age, gender, education level, employment status
- `dim_platform`: primary platform
- `fact_social_media_behavior`: usage, sleep, focus, productivity and risk measures

![ER diagram](screenshots/er_diagram.png)

### 3. Analysis (`03_analysis.sql`)
Twelve queries using CTEs, `NTILE`, `RANK`, `DENSE_RANK`, `ROW_NUMBER`, subqueries, `GROUP BY` with `HAVING`, `CASE` bucketing, joins, and a correlation calculated directly in SQL.

## Key findings

1. [Quartile result, for example "The highest-usage quartile averaged X dysregulation vs Y for the lowest."]
2. [Correlation result, for example "Correlation between daily hours and dysregulation was X."]
3. [Third result, for example risk level counts, or the platform with the highest average dysregulation.]

![Usage quartiles output](screenshots/usage_quartiles.png)

## SQL skills used

Joins, CTEs, window functions (`NTILE`, `RANK`, `DENSE_RANK`, `ROW_NUMBER`), subqueries, `GROUP BY` / `HAVING`, `CASE`, conditional aggregation, `information_schema`, star schema design.

## How to run

1. Import the raw CSV into MySQL as `social_media_dopamine_productivity` (database `social_media_analytics`).
2. Run `01_data_quality_checks.sql`.
3. Run `02_star_schema.sql`.
4. Run `03_analysis.sql`.

## Limitations

- The data is [synthetic / self-reported], so the findings show patterns in this dataset and do not prove cause and effect.
- Correlation does not mean usage causes dysregulation.

## About me

Sunny Kashyap | Data analyst fresher, Delhi | [LinkedIn link] | [GitHub link]
