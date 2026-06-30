# 🏏 IPL Cricket Performance Analysis (2008–2024)

> **End-to-end Data Analytics Portfolio Project**  
> Python · Pandas · SQL · Power BI · Statistical Modelling

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Business Problem](#business-problem)
3. [Objectives](#objectives)
4. [Dataset](#dataset)
5. [Project Architecture](#project-architecture)
6. [Workflow](#workflow)
7. [Tech Stack](#tech-stack)
8. [Key KPIs & Insights](#key-kpis--insights)
9. [Screenshots](#screenshots)
10. [Installation Guide](#installation-guide)
11. [How to Run](#how-to-run)
12. [SQL Queries Covered](#sql-queries-covered)
13. [Power BI Dashboard](#power-bi-dashboard)
14. [Best XI Model](#best-xi-model)
15. [Future Improvements](#future-improvements)
16. [License](#license)

---

## Project Overview

This project performs a **complete end-to-end data analytics investigation** of 17 seasons of IPL (Indian Premier League) cricket — from 2008 to 2024 — across **850,000+ ball-by-ball delivery records** and **1,095+ matches**.

The analysis goes beyond simple statistics. It uses **statistical hypothesis testing, weighted scoring models, and business-style storytelling** to answer questions that a franchise management team, broadcaster, or sports data consultancy would actually care about.

---

## Business Problem

Cricket franchises, broadcasters, and fantasy sports platforms make decisions based on player and team performance data. However, raw statistics are often misleading:

- A high run-scorer may be inconsistent (feast or famine)
- A low-economy bowler may rarely take wickets
- Winning the toss *feels* important — but does it actually matter statistically?

**This project converts raw cricket data into decision-grade insights.**

---

## Objectives

| # | Objective |
|---|-----------|
| 1 | Clean and standardise 17 seasons of IPL ball-by-ball data |
| 2 | Answer 15+ business-style analytical questions |
| 3 | Identify the most consistent, high-impact players |
| 4 | Build a venue-specific win probability framework |
| 5 | Develop a weighted Best XI scoring model |
| 6 | Produce a recruiter-ready Power BI dashboard |

---

## Dataset

| File | Source | Rows | Columns |
|------|--------|------|---------|
| `matches.csv` | Kaggle IPL Complete Dataset | ~1,095 | 18 |
| `deliveries.csv` | Kaggle IPL Complete Dataset | ~850,000 | 21 |

**Download:** [Kaggle — IPL Complete Dataset](https://www.kaggle.com/datasets/patrickb1912/ipl-complete-dataset-20082020)

Place files in `data/raw/` before running the pipeline.

**Key columns:**

*matches.csv*
- `id`, `season`, `city`, `date`, `team1`, `team2`
- `toss_winner`, `toss_decision`, `winner`, `result`
- `player_of_match`, `venue`

*deliveries.csv*
- `match_id`, `inning`, `over`, `ball`
- `batsman`, `bowler`, `batsman_runs`, `total_runs`
- `dismissal_kind`, `player_dismissed`

---

## Project Architecture

```
IPL-Analysis/
│
├── data/
│   ├── raw/                  ← Place matches.csv & deliveries.csv here
│   └── cleaned/               ← Auto-generated: matches_cleaned.csv, deliveries_cleaned.csv
│
├── notebooks/
│   ├── 01_data_cleaning.ipynb       ← Cleaning pipeline walkthrough
│   ├── 02_eda.ipynb                 ← 31 visualisations with storytelling
│   └── 03_advanced_analytics.ipynb ← Business questions + Best XI model
│
├── sql/
│   └── ipl_analysis_queries.sql    ← 52 interview-level SQL queries
│
├── powerbi/
│   └── dashboard_plan.md           ← 6-page dashboard design + DAX measures
│
├── dashboard_images/               ← Auto-saved chart PNGs
│
├── reports/
│   ├── interview_questions.md      ← 50 Q&A across Python, SQL, Power BI, Stats
│   └── resume_content.md           ← ATS bullets, LinkedIn description, GitHub bio
│
├── src/
│   ├── data_cleaning.py            ← Production ETL pipeline
│   └── utils.py                    ← Shared plot styling & helper functions
│
├── README.md
├── requirements.txt
└── .gitignore
```

---

## Workflow

```
Raw CSV Data
     │
     ▼
[1] DATA CLEANING (src/data_cleaning.py)
     • Handle nulls, duplicates, type errors
     • Normalise team names (17 variants → 10 teams)
     • Engineer 15 derived features
     │
     ▼
[2] EDA (notebooks/02_eda.ipynb)
     • 31 visualisations
     • Section-wise storytelling
     • Plotly interactive charts
     │
     ▼
[3] ADVANCED ANALYTICS (notebooks/03_advanced_analytics.ipynb)
     • Statistical tests (Chi-Square)
     • Pressure-performance analysis
     • Consistency scoring (CV method)
     • Death-over composite ranking
     │
     ▼
[4] SQL LAYER (sql/ipl_analysis_queries.sql)
     • 52 interview-ready queries
     • 3 views (batting, bowling, match summary)
     │
     ▼
[5] POWER BI DASHBOARD (powerbi/)
     • 6 pages, dark theme
     • Drill-through, slicers, bookmarks
     │
     ▼
[6] BEST XI MODEL
     • Weighted batting + bowling scores
     • Min-Max normalisation
     • Composite all-rounder ranking
```

---

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Data Cleaning | Python, Pandas, NumPy | ETL pipeline |
| Visualisation | Matplotlib, Seaborn, Plotly | 31+ charts |
| SQL Analysis | SQLite / PostgreSQL | 52 queries |
| Dashboard | Power BI | 6-page interactive report |
| Notebooks | Jupyter | Documented analysis |
| Version Control | Git / GitHub | Reproducibility |

---

## Key KPIs & Insights

### Team Performance
| KPI | Value |
|-----|-------|
| Most successful franchise | Mumbai Indians (5 titles) |
| Highest all-time win % (min 40 matches) | Chennai Super Kings (~60%) |
| Teams preferring to chase (2022+) | 70%+ chose field first |

### Toss Analysis
| Finding | Statistic |
|---------|-----------|
| Toss winner win rate | ~51.5% |
| Statistical significance | p ≈ 0.05 (borderline) |
| Conclusion | **Toss impact is marginal** |

### Batting Records
| Record | Player | Value |
|--------|--------|-------|
| Most IPL runs | V Kohli | 7,000+ |
| Best season | V Kohli (2016) | 973 runs |
| Highest strike rate (1000+ balls) | KL Rahul | ~135+ |

### Bowling Records
| Record | Player | Value |
|--------|--------|-------|
| Most wickets | DJ Bravo / SL Malinga | 170+ |
| Best economy (50+ wickets) | R Ashwin | ~7.0 |
| Best death-over composite | JJ Bumrah | Score: 87/100 |

### Venue Insights
| Venue Type | Example | Chase Win % |
|-----------|---------|-------------|
| Chase-friendly | Eden Gardens | 60%+ |
| Bat-friendly | MA Chidambaram | < 45% |

---

## Screenshots

20 EDA charts generated from a real, public IPL ball-by-ball dataset (2008–2017 seasons, 636 matches, 150K+ deliveries), saved in `dashboard_images/eda/`.

<table>
<tr>
<td align="center"><img src="dashboard_images/eda/chart01_most_wins.png" width="260"/><br/><sub>Most Wins</sub></td>
<td align="center"><img src="dashboard_images/eda/chart02_win_percentage.png" width="260"/><br/><sub>Win Percentage</sub></td>
<td align="center"><img src="dashboard_images/eda/chart03_matches_per_season.png" width="260"/><br/><sub>Matches Per Season</sub></td>
</tr>
<tr>
<td align="center"><img src="dashboard_images/eda/chart04_toss_decision_trend.png" width="260"/><br/><sub>Toss Decision Trend</sub></td>
<td align="center"><img src="dashboard_images/eda/chart05_toss_winner_match_winner.png" width="260"/><br/><sub>Toss Winner Match Winner</sub></td>
<td align="center"><img src="dashboard_images/eda/chart06_top_venues.png" width="260"/><br/><sub>Top Venues</sub></td>
</tr>
<tr>
<td align="center"><img src="dashboard_images/eda/chart07_top_run_scorers.png" width="260"/><br/><sub>Top Run Scorers</sub></td>
<td align="center"><img src="dashboard_images/eda/chart08_top_wicket_takers.png" width="260"/><br/><sub>Top Wicket Takers</sub></td>
<td align="center"><img src="dashboard_images/eda/chart09_strike_rate_leaders.png" width="260"/><br/><sub>Strike Rate Leaders</sub></td>
</tr>
<tr>
<td align="center"><img src="dashboard_images/eda/chart10_economy_leaders.png" width="260"/><br/><sub>Economy Leaders</sub></td>
<td align="center"><img src="dashboard_images/eda/chart11_dhoni_death_overs.png" width="260"/><br/><sub>Dhoni Death Overs</sub></td>
<td align="center"><img src="dashboard_images/eda/chart12_dismissal_types.png" width="260"/><br/><sub>Dismissal Types</sub></td>
</tr>
<tr>
<td align="center"><img src="dashboard_images/eda/chart13_run_rate_by_phase.png" width="260"/><br/><sub>Run Rate By Phase</sub></td>
<td align="center"><img src="dashboard_images/eda/chart14_player_of_match_leaders.png" width="260"/><br/><sub>Player Of Match Leaders</sub></td>
<td align="center"><img src="dashboard_images/eda/chart15_sixes_trend_by_season.png" width="260"/><br/><sub>Sixes Trend By Season</sub></td>
</tr>
<tr>
<td align="center"><img src="dashboard_images/eda/chart16_bat_first_vs_chase.png" width="260"/><br/><sub>Bat First Vs Chase</sub></td>
<td align="center"><img src="dashboard_images/eda/chart17_toss_analysis.png" width="260"/><br/><sub>Toss Analysis</sub></td>
<td align="center"><img src="dashboard_images/eda/chart18_toss_by_team.png" width="260"/><br/><sub>Toss By Team</sub></td>
</tr>
<tr>
<td align="center"><img src="dashboard_images/eda/chart19_strike_rate_extended.png" width="260"/><br/><sub>Strike Rate Extended</sub></td>
<td align="center"><img src="dashboard_images/eda/chart20_sixes_and_fours.png" width="260"/><br/><sub>Sixes And Fours</sub></td>
<td></td>
</tr>
</table>

---

## Installation Guide

### Prerequisites
- Python 3.9+
- Power BI Desktop (free)
- Jupyter Notebook or JupyterLab

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/IPL-Analysis.git
cd IPL-Analysis

# 2. Create virtual environment
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # macOS/Linux

# 3. Install dependencies
pip install -r requirements.txt

# 4. Download dataset
# Place matches.csv and deliveries.csv in data/raw/
```

---

## How to Run

```bash
# Step 1: Run data cleaning pipeline
python src/data_cleaning.py

# Step 2: Open notebooks in order
jupyter notebook notebooks/01_data_cleaning.ipynb
jupyter notebook notebooks/02_eda.ipynb
jupyter notebook notebooks/03_advanced_analytics.ipynb

# Step 3: SQL queries
# Load cleaned CSVs into SQLite:
# sqlite3 ipl.db
# .mode csv
# .import data/cleaned/matches_cleaned.csv matches
# .import data/cleaned/deliveries_cleaned.csv deliveries
# Then run queries from sql/ipl_analysis_queries.sql

# Step 4: Power BI
# Open Power BI Desktop
# Get Data → CSV → data/cleaned/matches_cleaned.csv
# Get Data → CSV → data/cleaned/deliveries_cleaned.csv
# Follow instructions in powerbi/dashboard_plan.md
```

---

## SQL Queries Covered

| Category | Count | Key Topics |
|----------|-------|-----------|
| Team Analysis | 5 | Wins, head-to-head, season trends |
| Toss Analysis | 3 | Decision trends, win rate |
| Batting Analysis | 7 | Orange Cap, strike rate, consistency |
| Bowling Analysis | 5 | Purple Cap, economy, death overs |
| Venue Analysis | 3 | Average scores, chase success |
| Window Functions | 7 | RANK, LAG, LEAD, running totals, moving avg |
| CTEs & Subqueries | 5 | Partnerships, best spells, POTM |
| Advanced | 10 | 200+ scores, consecutive wins, domain violations |
| Views | 3 | Batting summary, bowling summary, match summary |
| Bonus | 6 | Consistency, dismissal types, NTILE |
| **Total** | **54** | |

---

## Power BI Dashboard

| Page | Content |
|------|---------|
| 1 — Executive Summary | KPI cards, season trend, top teams |
| 2 — Team Analysis | Win %, bat vs chase, head-to-head |
| 3 — Player Analysis | Orange/Purple Cap, strike rate, POTM |
| 4 — Venue Analysis | Map, chase win %, scoring rates |
| 5 — Season Analysis | Run rate trends, season milestones |
| 6 — Best XI | Weighted scores, radar charts, role breakdown |

**DAX Measures:** Win %, Batting Average, Economy, Strike Rate, Composite Score  
**Interactivity:** Drill-through, Slicers, Bookmarks, Dynamic titles, Tooltips

---

## Best XI Model

### Methodology

```
Batting Score (55% weight):
  - Total Runs        → 30%
  - Average           → 25%
  - Strike Rate       → 25%
  - Sixes             → 10%
  - Boundary %        → 10%

Bowling Score (45% weight):
  - Wickets           → 35%
  - Economy (inverted)→ 30%
  - Bowling Average   → 20%
  - Dot Ball %        → 15%

All metrics normalised via Min-Max scaling.
Overall = Batting Score × 0.55 + Bowling Score × 0.45
```

---

## Future Improvements

| Enhancement | Description |
|-------------|-------------|
| Win Probability Model | XGBoost classifier using venue, toss, team form, playing XI |
| Auction Value Scoring | Map composite score to typical IPL auction price (value investing) |
| Real-time Dashboard | DirectQuery Power BI connected to live IPL API |
| Player Injury Risk | Workload-adjusted performance using fatigue proxy features |
| NLP Analysis | Sentiment analysis of post-match press conferences |
| Interactive Web App | Streamlit or Dash app with filter-driven player comparison |

---

## License

MIT License. See `LICENSE` for details.

---

*Built as a portfolio demonstration of end-to-end data analytics capability.*  
*Connect on [LinkedIn](https://linkedin.com/in/YOUR_PROFILE)*
