# IPL Analytics Project — 50 Interview Q&A

---

## SECTION 1: PROJECT EXPLANATION (HR / Behavioural)

**Q1. Walk me through your IPL Analytics project.**

> "I built an end-to-end data analytics project on 17 seasons of IPL data (2008–2024) to answer business-style questions that a cricket franchise or broadcaster would care about — things like 'which venue should we pick to maximise win probability?' or 'who is the best death-over bowler?'  
> I cleaned and engineered 850K+ delivery records in Python (Pandas), wrote 50+ SQL queries covering window functions and CTEs, built a 6-page Power BI dashboard, and developed a weighted scoring model to select an All-Time Best XI.  
> The entire project is on GitHub with a professional README, requirements file, and reproducible notebooks."

---

**Q2. What was the most challenging part?**

> "The biggest challenge was **team name normalisation** — franchises like Delhi Daredevils became Delhi Capitals, and Deccan Chargers merged into Sunrisers Hyderabad. A raw `GROUP BY winner` would give wrong totals. I built a mapping dictionary and applied it consistently across both DataFrames before any aggregation."

---

**Q3. What business value does this project add?**

> "A franchise can use this to: (1) decide batting/fielding after winning the toss based on venue-specific chase success rates; (2) target specific player profiles in the auction using weighted scoring; (3) identify consistent players vs one-season wonders using coefficient of variation analysis."

---

**Q4. How would you deploy this for a real client?**

> "I'd containerise the Python pipeline with Docker, schedule the cleaning job via Apache Airflow (or Azure Data Factory), push cleaned data to Azure SQL / BigQuery, connect Power BI to the live database with DirectQuery, and set up incremental refresh for new seasons. The SQL views I built already act as the semantic layer."

---

**Q5. What would you add with more time?**

> "A predictive model — specifically a logistic regression or XGBoost classifier to predict match outcomes from toss decision + venue + team form. I'd also add player auction value scoring to make the Best XI model directly applicable to IPL auctions."

---

## SECTION 2: PYTHON / PANDAS

**Q6. How did you handle missing values in the city column?**

> "I built a `VENUE_CITY_MAP` dictionary mapping known venue names to cities. For null cities, I used `df['city'].fillna(df['venue'].map(VENUE_CITY_MAP))`. This preserved data without dropping rows."

---

**Q7. Explain the difference between `fillna`, `ffill`, and `bfill`.**

> "`fillna(value)` — replaces NaN with a scalar or dict.  
> `ffill()` — forward-fills: copies the last valid value down.  
> `bfill()` — back-fills: copies the next valid value up.  
> ffill/bfill are useful for time-series (e.g., carrying forward a team's last score), but dangerous for categorical data."

---

**Q8. What is a groupby-transform and when did you use it?**

> "`transform` returns a Series aligned with the original DataFrame index, unlike `agg` which collapses. I used it to create per-player season averages that I could subtract from row-level scores to get deviation-from-average features."

---

**Q9. What is the difference between `merge` and `join`?**

> "`merge` is SQL-like: you specify key columns explicitly. `join` is index-based by default. In this project I always used `merge` for clarity — e.g., `deliveries.merge(matches[['id','season']], left_on='match_id', right_on='id')`."

---

**Q10. How did you calculate the Coefficient of Variation for consistency analysis?**

> "CV = (std / mean) × 100. Lower CV = more consistent.  
> ```python
> consistency['cv'] = (consistency['std'] / consistency['avg'] * 100).round(1)
> ```
> I filtered to players with 50+ innings to avoid high CV from tiny samples."

---

**Q11. What is vectorisation and why does it matter?**

> "Vectorisation means applying operations to entire arrays at once (NumPy/Pandas) instead of Python `for` loops. On 850K rows, a loop might take 30 seconds; a vectorised operation takes < 1 second. I used `.apply()` only when no vectorised alternative existed (e.g., the over-phase classification)."

---

**Q12. How did you create the over_phase feature?**

> "```python
> def over_phase(over):
>     if over <= 6:  return 'Powerplay'
>     elif over <= 15: return 'Middle'
>     else: return 'Death'
> df['over_phase'] = df['over'].apply(over_phase)
> ```
> For 850K rows, `apply` is acceptable but `pd.cut` is faster:
> ```python
> df['over_phase'] = pd.cut(df['over'], bins=[0,6,15,20],
>                            labels=['Powerplay','Middle','Death'])
> ```"

---

**Q13. Explain `pd.cut` vs `pd.qcut`.**

> "`pd.cut` — fixed bin edges (you define the ranges). Used for business-defined buckets like over phases.  
> `pd.qcut` — quantile-based bins (equal number of observations per bin). Used when you want equal distribution, e.g., dividing batsmen into quartiles by performance."

---

**Q14. How would you detect outliers in IPL scores?**

> "IQR method: `Q1 = df['score'].quantile(0.25); Q3 = df['score'].quantile(0.75); IQR = Q3 - Q1`. Outliers: values below `Q1 - 1.5*IQR` or above `Q3 + 1.5*IQR`. In cricket, a 250+ score is a genuine outlier worth investigating, not removing."

---

**Q15. What is the difference between `loc` and `iloc`?**

> "`loc` — label-based indexing (row/column names). `iloc` — integer position-based. If the index is non-default (e.g., player names), `loc['Kohli']` works; `iloc[0]` gives the first row regardless of index."

---

## SECTION 3: SQL

**Q16. Explain the difference between RANK, DENSE_RANK, and ROW_NUMBER.**

> "Given runs: 500, 500, 400:  
> `RANK()` → 1, 1, 3 (gap after tie)  
> `DENSE_RANK()` → 1, 1, 2 (no gap)  
> `ROW_NUMBER()` → 1, 2, 3 (unique, arbitrary for ties)  
> Use `RANK` for leaderboards, `DENSE_RANK` when gaps look wrong, `ROW_NUMBER` to get exactly top-N per partition."

---

**Q17. Write a query to find the Orange Cap winner for each season.**

> "```sql
> WITH season_runs AS (
>     SELECT season, batsman, SUM(batsman_runs) AS runs
>     FROM deliveries GROUP BY season, batsman
> ),
> ranked AS (
>     SELECT *, RANK() OVER (PARTITION BY season ORDER BY runs DESC) AS rnk
>     FROM season_runs
> )
> SELECT season, batsman, runs FROM ranked WHERE rnk = 1;
> ```"

---

**Q18. What is a CTE and when would you use it instead of a subquery?**

> "A CTE (Common Table Expression) is a named temporary result set defined with `WITH`. Use CTEs when: (1) the same subquery is referenced multiple times; (2) the query is deeply nested and hard to read; (3) you want self-referencing (recursive CTEs). CTEs don't necessarily improve performance — the optimizer usually treats them the same as subqueries."

---

**Q19. Explain LAG and LEAD with an example from this project.**

> "```sql
> SELECT season, batsman, runs,
>     LAG(runs) OVER (PARTITION BY batsman ORDER BY season) AS prev_runs,
>     runs - LAG(runs) OVER (PARTITION BY batsman ORDER BY season) AS improvement
> FROM season_runs;
> ```
> `LAG` looks at the previous row; `LEAD` looks at the next. Use to compute year-over-year changes."

---

**Q20. What is the difference between WHERE and HAVING?**

> "`WHERE` filters rows *before* aggregation. `HAVING` filters groups *after* aggregation.  
> ```sql
> -- Wrong: WHERE SUM(runs) > 500 (can't aggregate in WHERE)
> -- Correct:
> GROUP BY batsman HAVING SUM(batsman_runs) > 500
> ```"

---

**Q21. Explain PARTITION BY vs GROUP BY.**

> "`GROUP BY` collapses rows into one per group. `PARTITION BY` (in window functions) keeps all rows but performs the calculation within each partition. Use `GROUP BY` for summary tables; `PARTITION BY` when you need per-row context with group-level calculations."

---

**Q22. Write a query to find batsmen with the highest consecutive-game streak of scoring 20+.**

> "This requires a gaps-and-islands approach using ROW_NUMBER:
> ```sql
> WITH scored AS (
>     SELECT match_id, batsman, SUM(batsman_runs) AS runs
>     FROM deliveries GROUP BY match_id, batsman HAVING SUM(batsman_runs) >= 20
> ),
> ranked AS (
>     SELECT batsman, match_id,
>            ROW_NUMBER() OVER (ORDER BY match_id) -
>            ROW_NUMBER() OVER (PARTITION BY batsman ORDER BY match_id) AS grp
>     FROM scored
> )
> SELECT batsman, COUNT(*) AS streak FROM ranked GROUP BY batsman, grp
> ORDER BY streak DESC LIMIT 10;
> ```"

---

**Q23. What are window frame clauses?**

> "`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` — cumulative sum from start.  
> `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` — rolling 3-row window.  
> `RANGE` uses logical values (same value = same row); `ROWS` uses physical position."

---

**Q24. What is an index and when would you create one on the deliveries table?**

> "An index is a B-tree data structure that speeds up lookups. On the deliveries table I'd index:  
> - `match_id` (most JOIN operations)  
> - `batsman` (player lookups)  
> - `bowler` (player lookups)  
> - Composite `(season, batsman)` for season-filtered player queries.  
> Avoid over-indexing: each index slows INSERT/UPDATE."

---

**Q25. Explain the difference between INNER JOIN, LEFT JOIN, and FULL OUTER JOIN.**

> "INNER — only rows that match in both tables.  
> LEFT — all rows from left table; NULLs for non-matching right.  
> FULL OUTER — all rows from both; NULLs where no match.  
> I used LEFT JOIN when merging deliveries with matches because some delivery records may exist for matches not yet in the matches table (data quality)."

---

## SECTION 4: POWER BI

**Q26. What is the difference between DirectQuery and Import mode?**

> "Import — data is loaded into Power BI memory (VertiPaq engine). Fast queries, but data is static until refresh.  
> DirectQuery — queries are sent to the source database live. Always fresh, but slower and limited DAX support.  
> For IPL I used Import mode (dataset is < 1M rows); for real-time match analytics, DirectQuery would be appropriate."

---

**Q27. Explain CALCULATE in DAX.**

> "`CALCULATE` evaluates an expression in a modified filter context. It's the most powerful DAX function.  
> ```dax
> Wins = CALCULATE(COUNTROWS(matches), matches[winner] = SELECTEDVALUE(matches[team1]))
> ```
> Without `CALCULATE`, the filter context is the visual's row/column context only."

---

**Q28. What is the difference between a measure and a calculated column?**

> "Calculated column — stored in the data model, computed row-by-row during refresh. Uses row context.  
> Measure — computed at query time based on current filter context. Not stored row-by-row.  
> Rule: aggregations → measure. Row-level logic → calculated column."

---

**Q29. How do you implement drill-through in Power BI?**

> "On the destination page: add fields to 'Drill-through filters'. On the source page: right-click a data point → Drill through → destination page. The destination page opens pre-filtered by the selected value. I set up drill-through from teams on the Executive Summary to the full Team Analysis page."

---

**Q30. What is a Star Schema and why is it important for Power BI?**

> "A star schema has one central fact table (deliveries) connected to multiple dimension tables (dim_player, dim_venue, dim_team, dim_season). Power BI's VertiPaq engine is optimised for star schemas — it compresses dimensions well and evaluates DAX filter propagation efficiently. Snowflake schemas (chained dimensions) are slower in Power BI."

---

## SECTION 5: STATISTICS

**Q31. What statistical test did you use to assess toss impact?**

> "Chi-Square goodness-of-fit test. H₀: toss winner wins 50% of the time.  
> Observed: 52% win rate. Chi-square stat: ~3.8, p-value: ~0.05.  
> Result: borderline significance — we cannot conclusively say toss matters. The practical effect size is tiny."

---

**Q32. What is the Central Limit Theorem and why does it matter here?**

> "CLT states that sample means of large samples are normally distributed regardless of the population distribution. With 1,000+ matches, we can apply z-tests and confidence intervals to compare win rates even though individual match outcomes are binary (Bernoulli)."

---

**Q33. What is Coefficient of Variation and why is it better than standard deviation for consistency?**

> "CV = (σ / μ) × 100. It normalises variability relative to the mean, making it comparable across players with different averages. A batsman averaging 30 with σ=20 (CV=67%) is more consistent than one averaging 50 with σ=40 (CV=80%), even though the second has higher absolute deviation."

---

**Q34. What is correlation and did you find any interesting correlations?**

> "Correlation measures the linear relationship between two variables (−1 to +1). I found:  
> - Strong positive correlation between powerplay run rate and final score (r ≈ 0.65)  
> - Moderate negative correlation between economy rate and wickets taken (r ≈ −0.45)  
> - Near-zero correlation between toss win and match win (r ≈ 0.03 — confirming our chi-square result)"

---

**Q35. What is Min-Max normalisation and why did you use it in the Best XI model?**

> "Min-Max scales values to [0, 1]: `(x − min) / (max − min)`.  
> I used it because the Best XI model combines runs (range: 0–7,000) with economy (range: 6–12) — incomparable raw scales. Normalising puts them on equal footing before applying weights."

---

## SECTION 6: DATA CLEANING

**Q36. What are the 5 common data quality issues and how did you handle each?**

> "1. **Missing values** — city: derived from venue map; winner: filled from result column.  
> 2. **Duplicates** — `drop_duplicates()` before any processing.  
> 3. **Wrong data types** — date as string → `pd.to_datetime()`; season as float → `.astype('Int64')`.  
> 4. **Inconsistent categories** — team name variations → replace() with normalisation map.  
> 5. **Domain violations** — negative extra_runs set to 0; run counts capped at domain-valid values."

---

**Q37. How would you validate that your cleaning didn't introduce errors?**

> "Post-cleaning assertions:  
> ```python
> assert df['season'].between(2008, 2024).all()
> assert df['batsman_runs'].between(0, 6).all()
> assert df['is_legal'].isin([0, 1]).all()
> assert df.duplicated().sum() == 0
> ```  
> Also cross-check total runs per match against published scorecard totals for a random sample."

---

**Q38. What is data drift and how would you detect it?**

> "Data drift = the statistical properties of data change over time. For IPL, average first innings scores have risen from ~155 to ~170 — that's drift. Detect it with: (1) distribution plots by season; (2) statistical tests (KS test between seasons); (3) monitoring pipelines with tools like Great Expectations or Evidently AI."

---

## SECTION 7: BUSINESS CASE

**Q39. A franchise asks: 'Should we target a finisher or a powerplay hitter in the auction?' How do you answer?**

> "I'd analyse:  
> 1. Current squad gap — compute current XI's phase-wise run rate vs league average.  
> 2. ROI — players who improved team win% most in that phase (regression analysis).  
> 3. Marginal value — does the team already have a strong death finisher? If yes, powerplay is the gap.  
> Then I'd score all auction candidates on the relevant phase metrics and present a ranked shortlist with performance data."

---

**Q40. How would you present this analysis to non-technical stakeholders?**

> "Three rules: (1) Lead with the decision, not the methodology — 'You should field first at Eden Gardens — teams batting second win 62% of matches there.' (2) Use visuals, not tables — a single bar chart beats a 20-row table. (3) Quantify uncertainty — 'Based on 47 matches, so this is a reliable signal.' I'd use a Power BI bookmark-driven storytelling flow, not a static slide deck."

---

**Q41. How do you calculate player value for auction purposes?**

> "Build a composite score weighted by:  
> - Contribution to team wins (runs/wickets in winning causes)  
> - Phase-specific performance (death/powerplay specialists command premium)  
> - Consistency (CV of innings scores)  
> - Availability (missed matches reduce value)  
> Normalise each dimension to [0,1] and apply auction-relevance weights. Compare composite score vs typical auction price to find undervalued players."

---

## SECTION 8: GENERAL DATA ANALYST

**Q42. What is the ETL process and how did you implement it?**

> "Extract → Transform → Load.  
> **Extract:** `pd.read_csv()` from raw data folder.  
> **Transform:** cleaning, normalisation, feature engineering (Python).  
> **Load:** `df.to_csv()` to cleaned folder (or in production: `to_sql()` to a database).  
> The `src/data_cleaning.py` script is the transformation layer; it's idempotent — running it twice produces the same output."

---

**Q43. What is the difference between OLTP and OLAP?**

> "OLTP (Online Transaction Processing) — optimised for many small read/write transactions. Row-oriented storage. Use case: live scorecard updates.  
> OLAP (Online Analytical Processing) — optimised for complex queries over large datasets. Column-oriented storage. Use case: IPL historical analysis.  
> Power BI's VertiPaq is a columnar OLAP engine."

---

**Q44. Explain the concept of data granularity.**

> "Granularity = the level of detail in a row. In this project:  
> - `deliveries` table: ball-level (highest granularity — 850K rows)  
> - `matches` table: match-level  
> - Aggregated views: season-level or career-level  
> Analysis at the wrong granularity produces wrong results. E.g., computing batting average at match-level and then averaging those averages (instead of total runs / total dismissals) gives a wrong result (Simpson's Paradox)."

---

**Q45. What is Simpson's Paradox and is it relevant to IPL analysis?**

> "Simpson's Paradox: a trend that appears in aggregated data reverses when data is disaggregated into subgroups.  
> IPL example: Bowler A has better economy than Bowler B overall, but when split by over phase, Bowler B is better in every phase. This can happen if Bowler A bowls more middle overs (easier phase) than Bowler B who bowls mostly death overs. Always stratify by over phase when comparing bowlers."

---

**Q46. How did you ensure reproducibility of your analysis?**

> "1. Fixed random seeds where sampling was used.  
> 2. Pinned all package versions in `requirements.txt`.  
> 3. Modular pipeline: `data_cleaning.py` is separate from analysis notebooks.  
> 4. Saved intermediate cleaned CSVs — notebooks always read from `data/cleaned/`, never from raw.  
> 5. All charts saved to `dashboard_images/` with consistent naming."

---

**Q47. What is the difference between precision and recall?**

> "Precision = TP / (TP + FP) — of predicted wins, how many were actually wins?  
> Recall = TP / (TP + FN) — of actual wins, how many did we predict?  
> In a match outcome prediction model, high recall matters more (don't miss actual wins), so I'd tune the classification threshold toward recall."

---

**Q48. How would you handle class imbalance in a win prediction model?**

> "1. SMOTE — synthetic minority oversampling.  
> 2. Class weights — `class_weight='balanced'` in sklearn.  
> 3. Resampling — undersample majority class.  
> 4. Change evaluation metric — use F1-score or AUC-ROC instead of accuracy.  
> For IPL, wins and losses are roughly 50/50 so imbalance is minimal."

---

**Q49. What version control practices did you follow?**

> "Git with feature branches:  
> - `main` — clean, working code only  
> - `feature/data-cleaning` — cleaning pipeline  
> - `feature/eda` — analysis notebooks  
> Commit messages follow Conventional Commits format: `feat:`, `fix:`, `docs:`.  
> `.gitignore` excludes raw data files (> 50MB) and Jupyter checkpoints."

---

**Q50. Where do you see data analytics in cricket evolving?**

> "Three vectors: (1) **Ball-tracking data** (Hawk-Eye, Pitch Vision) — enable 3D trajectory analysis for field placement optimisation. (2) **Real-time analytics** — in-game strategy adjustments using live win probability models. (3) **Player biometrics** — fatigue-adjusted performance models that account for workload. Teams like MI and CSK already have analytics departments; the gap between data-rich and data-poor franchises will widen."

---

*End of 50 Interview Questions*
