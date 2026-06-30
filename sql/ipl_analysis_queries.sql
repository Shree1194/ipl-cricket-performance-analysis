-- ============================================================
-- IPL Cricket Performance Analysis (2008–2024)
-- 50+ Interview-Level SQL Queries
-- Database: SQLite / PostgreSQL / MySQL compatible
-- ============================================================

-- ============================================================
-- TABLE CREATION
-- ============================================================

CREATE TABLE IF NOT EXISTS matches (
    id                  VARCHAR(20)  PRIMARY KEY,
    season              INTEGER,
    city                VARCHAR(100),
    date                DATE,
    team1               VARCHAR(100),
    team2               VARCHAR(100),
    toss_winner         VARCHAR(100),
    toss_decision       VARCHAR(10),
    result              VARCHAR(20),
    dl_applied          INTEGER DEFAULT 0,
    winner              VARCHAR(100),
    win_by_runs         INTEGER DEFAULT 0,
    win_by_wickets      INTEGER DEFAULT 0,
    player_of_match     VARCHAR(100),
    venue               VARCHAR(200),
    umpire1             VARCHAR(100),
    umpire2             VARCHAR(100),
    batting_first_team  VARCHAR(100),
    chasing_team        VARCHAR(100),
    batting_first_won   INTEGER DEFAULT 0,
    chasing_won         INTEGER DEFAULT 0,
    toss_winner_won     INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS deliveries (
    match_id            VARCHAR(20),
    inning              INTEGER,
    batting_team        VARCHAR(100),
    bowling_team        VARCHAR(100),
    over                INTEGER,
    ball                INTEGER,
    batsman             VARCHAR(100),
    non_striker         VARCHAR(100),
    bowler              VARCHAR(100),
    is_super_over       INTEGER DEFAULT 0,
    wide_runs           INTEGER DEFAULT 0,
    bye_runs            INTEGER DEFAULT 0,
    legbye_runs         INTEGER DEFAULT 0,
    noball_runs         INTEGER DEFAULT 0,
    penalty_runs        INTEGER DEFAULT 0,
    batsman_runs        INTEGER DEFAULT 0,
    extra_runs          INTEGER DEFAULT 0,
    total_runs          INTEGER DEFAULT 0,
    player_dismissed    VARCHAR(100),
    dismissal_kind      VARCHAR(50),
    fielder             VARCHAR(100),
    is_wicket           INTEGER DEFAULT 0,
    is_bowler_wicket    INTEGER DEFAULT 0,
    over_phase          VARCHAR(20),
    is_four             INTEGER DEFAULT 0,
    is_six              INTEGER DEFAULT 0,
    is_dot              INTEGER DEFAULT 0,
    is_legal            INTEGER DEFAULT 0,
    season              INTEGER
);


-- ============================================================
-- SECTION 1: BASIC TEAM ANALYSIS
-- ============================================================

-- Q1: Total wins per team (all-time)
SELECT
    winner                          AS team,
    COUNT(*)                        AS total_wins
FROM matches
WHERE winner NOT IN ('No Result', 'Tie', 'Not Awarded')
GROUP BY winner
ORDER BY total_wins DESC;


-- Q2: Win percentage per team (min 40 matches)
SELECT
    t.team,
    t.matches_played,
    COALESCE(w.wins, 0)             AS wins,
    ROUND(COALESCE(w.wins, 0) * 100.0 / t.matches_played, 2) AS win_pct
FROM (
    SELECT team1 AS team, COUNT(*) AS matches_played FROM matches GROUP BY team1
    UNION ALL
    SELECT team2, COUNT(*) FROM matches GROUP BY team2
) t
LEFT JOIN (
    SELECT winner AS team, COUNT(*) AS wins
    FROM matches
    WHERE winner NOT IN ('No Result', 'Tie')
    GROUP BY winner
) w ON t.team = w.team
GROUP BY t.team
HAVING SUM(t.matches_played) >= 40
ORDER BY win_pct DESC;


-- Q3: Season-wise wins per team
SELECT
    m.season,
    m.winner                        AS team,
    COUNT(*)                        AS wins
FROM matches m
WHERE m.winner NOT IN ('No Result', 'Tie')
GROUP BY m.season, m.winner
ORDER BY m.season, wins DESC;


-- Q4: Teams that have won batting first vs chasing
SELECT
    winner                          AS team,
    SUM(batting_first_won)          AS wins_batting_first,
    SUM(chasing_won)                AS wins_chasing,
    COUNT(*)                        AS total_wins
FROM matches
WHERE winner NOT IN ('No Result', 'Tie')
GROUP BY winner
ORDER BY total_wins DESC;


-- Q5: Head-to-head record between two specific teams
SELECT
    team1, team2, winner,
    COUNT(*) AS matches
FROM matches
WHERE (team1 = 'Mumbai Indians' AND team2 = 'Chennai Super Kings')
   OR (team1 = 'Chennai Super Kings' AND team2 = 'Mumbai Indians')
GROUP BY winner;


-- ============================================================
-- SECTION 2: TOSS ANALYSIS
-- ============================================================

-- Q6: Does toss winner win the match?
SELECT
    toss_winner_won,
    COUNT(*)                        AS matches,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM matches
WHERE winner NOT IN ('No Result', 'Tie')
GROUP BY toss_winner_won;


-- Q7: Toss decision trends by season
SELECT
    season,
    SUM(CASE WHEN toss_decision = 'bat'   THEN 1 ELSE 0 END) AS chose_bat,
    SUM(CASE WHEN toss_decision = 'field' THEN 1 ELSE 0 END) AS chose_field,
    COUNT(*)                                                   AS total
FROM matches
GROUP BY season
ORDER BY season;


-- Q8: Win rate when choosing to bat vs field
SELECT
    toss_decision,
    COUNT(*)                        AS total_decisions,
    SUM(toss_winner_won)            AS times_won_match,
    ROUND(SUM(toss_winner_won) * 100.0 / COUNT(*), 2) AS win_pct
FROM matches
WHERE winner NOT IN ('No Result', 'Tie')
GROUP BY toss_decision;


-- ============================================================
-- SECTION 3: BATTING ANALYSIS
-- ============================================================

-- Q9: All-time top run scorers
SELECT
    batsman,
    SUM(batsman_runs)               AS total_runs,
    COUNT(DISTINCT match_id)        AS matches,
    ROUND(SUM(batsman_runs) * 100.0 / SUM(is_legal), 2) AS strike_rate
FROM deliveries
GROUP BY batsman
HAVING SUM(is_legal) >= 500
ORDER BY total_runs DESC
LIMIT 20;


-- Q10: Batting average (runs per dismissal)
SELECT
    d.batsman,
    SUM(d.batsman_runs)             AS total_runs,
    COUNT(DISTINCT d.match_id)      AS innings,
    SUM(d.is_wicket)                AS dismissals,
    CASE
        WHEN SUM(d.is_wicket) = 0 THEN NULL
        ELSE ROUND(SUM(d.batsman_runs) * 1.0 / SUM(d.is_wicket), 2)
    END                             AS batting_avg
FROM deliveries d
GROUP BY d.batsman
HAVING SUM(d.is_legal) >= 500
ORDER BY batting_avg DESC NULLS LAST
LIMIT 20;


-- Q11: Most sixes in IPL history
SELECT
    batsman,
    SUM(is_six)                     AS sixes,
    SUM(is_four)                    AS fours,
    ROUND(SUM(is_six) * 100.0 / NULLIF(SUM(is_legal), 0), 2) AS six_pct
FROM deliveries
GROUP BY batsman
ORDER BY sixes DESC
LIMIT 15;


-- Q12: Orange Cap winner per season
WITH season_runs AS (
    SELECT
        d.season,
        d.batsman,
        SUM(d.batsman_runs) AS runs
    FROM deliveries d
    WHERE d.season IS NOT NULL
    GROUP BY d.season, d.batsman
),
ranked AS (
    SELECT
        season, batsman, runs,
        RANK() OVER (PARTITION BY season ORDER BY runs DESC) AS rnk
    FROM season_runs
)
SELECT season, batsman, runs AS orange_cap_runs
FROM ranked
WHERE rnk = 1
ORDER BY season;


-- Q13: Virat Kohli season-wise performance
SELECT
    d.season,
    SUM(d.batsman_runs)             AS runs,
    SUM(d.is_legal)                 AS balls,
    ROUND(SUM(d.batsman_runs) * 100.0 / NULLIF(SUM(d.is_legal), 0), 1) AS strike_rate,
    SUM(d.is_four)                  AS fours,
    SUM(d.is_six)                   AS sixes
FROM deliveries d
WHERE d.batsman = 'V Kohli'
GROUP BY d.season
ORDER BY d.season;


-- Q14: Batsmen with highest average in death overs (min 100 balls)
SELECT
    batsman,
    SUM(batsman_runs)               AS runs,
    SUM(is_legal)                   AS balls,
    ROUND(SUM(batsman_runs) * 100.0 / NULLIF(SUM(is_legal), 0), 1) AS death_sr
FROM deliveries
WHERE over_phase = 'Death'
GROUP BY batsman
HAVING SUM(is_legal) >= 100
ORDER BY death_sr DESC
LIMIT 15;


-- Q15: Batsmen with highest powerplay run rate (min 100 balls)
SELECT
    batsman,
    SUM(batsman_runs)               AS pp_runs,
    SUM(is_legal)                   AS pp_balls,
    ROUND(SUM(batsman_runs) * 100.0 / NULLIF(SUM(is_legal), 0), 1) AS pp_sr
FROM deliveries
WHERE over_phase = 'Powerplay'
GROUP BY batsman
HAVING SUM(is_legal) >= 100
ORDER BY pp_sr DESC
LIMIT 15;


-- ============================================================
-- SECTION 4: BOWLING ANALYSIS
-- ============================================================

-- Q16: All-time top wicket takers
SELECT
    bowler,
    SUM(is_bowler_wicket)           AS wickets,
    COUNT(DISTINCT match_id)        AS matches,
    ROUND(SUM(total_runs) * 6.0 / NULLIF(SUM(is_legal), 0), 2) AS economy
FROM deliveries
GROUP BY bowler
HAVING SUM(is_legal) >= 500
ORDER BY wickets DESC
LIMIT 20;


-- Q17: Purple Cap winner per season
WITH season_wkts AS (
    SELECT
        season,
        bowler,
        SUM(is_bowler_wicket) AS wickets
    FROM deliveries
    WHERE season IS NOT NULL
    GROUP BY season, bowler
),
ranked AS (
    SELECT
        season, bowler, wickets,
        RANK() OVER (PARTITION BY season ORDER BY wickets DESC) AS rnk
    FROM season_wkts
)
SELECT season, bowler, wickets AS purple_cap_wickets
FROM ranked
WHERE rnk = 1
ORDER BY season;


-- Q18: Bowler economy in different phases
SELECT
    bowler,
    ROUND(SUM(CASE WHEN over_phase='Powerplay' THEN total_runs END) * 6.0
          / NULLIF(SUM(CASE WHEN over_phase='Powerplay' THEN is_legal END), 0), 2) AS pp_economy,
    ROUND(SUM(CASE WHEN over_phase='Middle' THEN total_runs END) * 6.0
          / NULLIF(SUM(CASE WHEN over_phase='Middle' THEN is_legal END), 0), 2) AS mid_economy,
    ROUND(SUM(CASE WHEN over_phase='Death' THEN total_runs END) * 6.0
          / NULLIF(SUM(CASE WHEN over_phase='Death' THEN is_legal END), 0), 2) AS death_economy
FROM deliveries
GROUP BY bowler
HAVING SUM(is_legal) >= 500
ORDER BY death_economy
LIMIT 15;


-- Q19: Best bowling average (runs per wicket, min 50 wickets)
SELECT
    bowler,
    SUM(is_bowler_wicket)           AS wickets,
    SUM(total_runs)                 AS runs_conceded,
    ROUND(SUM(total_runs) * 1.0 / NULLIF(SUM(is_bowler_wicket), 0), 2) AS avg,
    ROUND(SUM(total_runs) * 6.0 / NULLIF(SUM(is_legal), 0), 2) AS economy
FROM deliveries
GROUP BY bowler
HAVING SUM(is_bowler_wicket) >= 50
ORDER BY avg
LIMIT 15;


-- Q20: Dot ball percentage per bowler (min 500 legal balls)
SELECT
    bowler,
    SUM(is_legal)                   AS legal_balls,
    SUM(is_dot)                     AS dots,
    ROUND(SUM(is_dot) * 100.0 / NULLIF(SUM(is_legal), 0), 1) AS dot_pct
FROM deliveries
GROUP BY bowler
HAVING SUM(is_legal) >= 500
ORDER BY dot_pct DESC
LIMIT 15;


-- ============================================================
-- SECTION 5: VENUE ANALYSIS
-- ============================================================

-- Q21: Average first innings score per venue
SELECT
    m.venue,
    ROUND(AVG(inn1.total), 1)       AS avg_first_innings_score,
    COUNT(*)                        AS matches
FROM (
    SELECT match_id, SUM(total_runs) AS total
    FROM deliveries
    WHERE inning = 1
    GROUP BY match_id
) inn1
JOIN matches m ON inn1.match_id = m.id
GROUP BY m.venue
HAVING COUNT(*) >= 15
ORDER BY avg_first_innings_score DESC;


-- Q22: Chase success rate per venue
SELECT
    venue,
    COUNT(*)                        AS total_matches,
    SUM(chasing_won)                AS chasing_wins,
    ROUND(SUM(chasing_won) * 100.0 / COUNT(*), 1) AS chase_pct
FROM matches
WHERE winner NOT IN ('No Result', 'Tie')
GROUP BY venue
HAVING COUNT(*) >= 15
ORDER BY chase_pct DESC;


-- Q23: Highest individual innings at each venue
SELECT
    m.venue,
    d.batsman,
    SUM(d.batsman_runs)             AS runs
FROM deliveries d
JOIN matches m ON d.match_id = m.id
GROUP BY m.venue, d.match_id, d.batsman
ORDER BY runs DESC
LIMIT 20;


-- ============================================================
-- SECTION 6: WINDOW FUNCTIONS
-- ============================================================

-- Q24: Running total of wins per team per season
SELECT
    season,
    winner                          AS team,
    COUNT(*)                        AS season_wins,
    SUM(COUNT(*)) OVER (
        PARTITION BY winner
        ORDER BY season
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                               AS cumulative_wins
FROM matches
WHERE winner NOT IN ('No Result', 'Tie')
GROUP BY season, winner
ORDER BY winner, season;


-- Q25: Rank batsmen by runs within each season
WITH season_runs AS (
    SELECT season, batsman, SUM(batsman_runs) AS runs
    FROM deliveries
    WHERE season IS NOT NULL
    GROUP BY season, batsman
)
SELECT
    season,
    batsman,
    runs,
    RANK()       OVER (PARTITION BY season ORDER BY runs DESC) AS rank_in_season,
    DENSE_RANK() OVER (PARTITION BY season ORDER BY runs DESC) AS dense_rank,
    ROW_NUMBER() OVER (PARTITION BY season ORDER BY runs DESC) AS row_num
FROM season_runs
ORDER BY season, rank_in_season
LIMIT 50;


-- Q26: LAG / LEAD — YoY runs change for each batsman
WITH season_runs AS (
    SELECT season, batsman, SUM(batsman_runs) AS runs
    FROM deliveries
    WHERE season IS NOT NULL
    GROUP BY season, batsman
    HAVING SUM(is_legal) >= 200
)
SELECT
    season,
    batsman,
    runs,
    LAG(runs)  OVER (PARTITION BY batsman ORDER BY season) AS prev_season_runs,
    LEAD(runs) OVER (PARTITION BY batsman ORDER BY season) AS next_season_runs,
    runs - LAG(runs) OVER (PARTITION BY batsman ORDER BY season) AS yoy_change
FROM season_runs
ORDER BY batsman, season;


-- Q27: Moving average of team wins (3-season rolling)
WITH team_wins AS (
    SELECT season, winner AS team, COUNT(*) AS wins
    FROM matches
    WHERE winner NOT IN ('No Result', 'Tie')
    GROUP BY season, winner
)
SELECT
    season, team, wins,
    ROUND(AVG(wins) OVER (
        PARTITION BY team
        ORDER BY season
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3season_avg
FROM team_wins
ORDER BY team, season;


-- Q28: Percentile rank of batsmen by total runs
WITH runs AS (
    SELECT batsman, SUM(batsman_runs) AS total_runs
    FROM deliveries
    GROUP BY batsman
    HAVING SUM(is_legal) >= 500
)
SELECT
    batsman,
    total_runs,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_runs) * 100, 1) AS percentile_rank
FROM runs
ORDER BY total_runs DESC
LIMIT 20;


-- Q29: Cumulative runs for Virat Kohli across seasons
SELECT
    season,
    SUM(batsman_runs)               AS season_runs,
    SUM(SUM(batsman_runs)) OVER (ORDER BY season) AS cumulative_runs
FROM deliveries
WHERE batsman = 'V Kohli'
GROUP BY season
ORDER BY season;


-- Q30: Top-N batsmen per team (using ROW_NUMBER)
WITH team_runs AS (
    SELECT
        batting_team,
        batsman,
        SUM(batsman_runs) AS runs
    FROM deliveries
    GROUP BY batting_team, batsman
),
ranked AS (
    SELECT
        batting_team,
        batsman,
        runs,
        ROW_NUMBER() OVER (PARTITION BY batting_team ORDER BY runs DESC) AS rn
    FROM team_runs
)
SELECT batting_team, batsman, runs
FROM ranked
WHERE rn <= 3
ORDER BY batting_team, rn;


-- ============================================================
-- SECTION 7: CTE & SUBQUERIES
-- ============================================================

-- Q31: Batsmen who scored 50+ in a single innings (count)
WITH innings_scores AS (
    SELECT match_id, batsman, SUM(batsman_runs) AS inn_runs
    FROM deliveries
    GROUP BY match_id, batsman
)
SELECT
    batsman,
    COUNT(*) FILTER (WHERE inn_runs >= 50) AS half_centuries,
    COUNT(*) FILTER (WHERE inn_runs >= 100) AS centuries
FROM innings_scores
GROUP BY batsman
ORDER BY centuries DESC, half_centuries DESC
LIMIT 20;


-- Q32: Matches where team scored 200+ in first innings
WITH inn1 AS (
    SELECT match_id, batting_team, SUM(total_runs) AS score
    FROM deliveries
    WHERE inning = 1
    GROUP BY match_id, batting_team
)
SELECT
    m.season,
    i.batting_team,
    i.score,
    m.venue,
    m.winner
FROM inn1 i
JOIN matches m ON i.match_id = m.id
WHERE i.score >= 200
ORDER BY i.score DESC;


-- Q33: Players who won POTM most in a single season
WITH potm AS (
    SELECT season, player_of_match, COUNT(*) AS awards
    FROM matches
    WHERE player_of_match NOT IN ('Not Awarded', 'NA')
    GROUP BY season, player_of_match
)
SELECT
    season,
    player_of_match,
    awards,
    RANK() OVER (PARTITION BY season ORDER BY awards DESC) AS rnk
FROM potm
ORDER BY season, rnk;


-- Q34: Bowler's best spell (most wickets in a single match-innings)
SELECT
    match_id,
    inning,
    bowler,
    SUM(is_bowler_wicket)   AS wickets,
    SUM(total_runs)         AS runs_conceded,
    SUM(is_legal)           AS balls
FROM deliveries
GROUP BY match_id, inning, bowler
ORDER BY wickets DESC, runs_conceded
LIMIT 20;


-- Q35: Partnerships — top run partnerships
SELECT
    match_id,
    inning,
    batsman,
    non_striker,
    SUM(batsman_runs) AS partnership_runs
FROM deliveries
GROUP BY match_id, inning, batsman, non_striker
ORDER BY partnership_runs DESC
LIMIT 20;


-- ============================================================
-- SECTION 8: ADVANCED QUERIES
-- ============================================================

-- Q36: Economy rate comparison: powerplay vs death for same bowler
SELECT
    bowler,
    ROUND(SUM(CASE WHEN over_phase = 'Powerplay' THEN total_runs ELSE 0 END) * 6.0
          / NULLIF(SUM(CASE WHEN over_phase = 'Powerplay' THEN is_legal ELSE 0 END), 0), 2) AS pp_eco,
    ROUND(SUM(CASE WHEN over_phase = 'Death' THEN total_runs ELSE 0 END) * 6.0
          / NULLIF(SUM(CASE WHEN over_phase = 'Death' THEN is_legal ELSE 0 END), 0), 2) AS death_eco,
    SUM(is_bowler_wicket) AS total_wickets
FROM deliveries
GROUP BY bowler
HAVING SUM(is_legal) >= 400
ORDER BY death_eco;


-- Q37: Super Over matches
SELECT
    season,
    team1,
    team2,
    winner,
    venue
FROM matches
WHERE result = 'tie' OR win_by_runs = 0 AND win_by_wickets = 0
ORDER BY season;


-- Q38: Lowest defended total (smallest first innings win)
SELECT
    m.id,
    m.season,
    m.venue,
    m.batting_first_team  AS defending_team,
    m.winner,
    inn1.total            AS score_defended
FROM matches m
JOIN (
    SELECT match_id, SUM(total_runs) AS total
    FROM deliveries
    WHERE inning = 1
    GROUP BY match_id
) inn1 ON m.id = inn1.match_id
WHERE m.batting_first_won = 1
ORDER BY inn1.total
LIMIT 10;


-- Q39: Average score by over number (all seasons)
SELECT
    over,
    inning,
    ROUND(AVG(over_runs), 2) AS avg_runs_per_over
FROM (
    SELECT match_id, inning, over, SUM(total_runs) AS over_runs
    FROM deliveries
    GROUP BY match_id, inning, over
) t
GROUP BY over, inning
ORDER BY inning, over;


-- Q40: Teams with most consecutive wins in a single season
-- (Requires ordered match data with match dates)
WITH ranked_wins AS (
    SELECT
        m.season,
        m.date,
        m.winner,
        ROW_NUMBER() OVER (PARTITION BY m.season, m.winner ORDER BY m.date) AS rn,
        ROW_NUMBER() OVER (PARTITION BY m.season, m.winner ORDER BY m.date)
            - ROW_NUMBER() OVER (PARTITION BY m.season ORDER BY m.date) AS grp
    FROM matches m
    WHERE m.winner NOT IN ('No Result', 'Tie')
)
SELECT season, winner AS team, COUNT(*) AS consecutive_wins
FROM ranked_wins
GROUP BY season, winner, grp
ORDER BY consecutive_wins DESC
LIMIT 10;


-- ============================================================
-- SECTION 9: VIEWS
-- ============================================================

-- View 1: Batting card summary
CREATE OR REPLACE VIEW vw_batting_summary AS
SELECT
    batsman                                    AS player,
    COUNT(DISTINCT match_id)                   AS innings,
    SUM(batsman_runs)                          AS total_runs,
    ROUND(SUM(batsman_runs) * 100.0
          / NULLIF(SUM(is_legal), 0), 1)       AS strike_rate,
    ROUND(SUM(batsman_runs) * 1.0
          / NULLIF(SUM(is_wicket), 0), 2)      AS avg,
    SUM(is_four)                               AS fours,
    SUM(is_six)                                AS sixes,
    SUM(is_dot)                                AS dots
FROM deliveries
GROUP BY batsman;


-- View 2: Bowling card summary
CREATE OR REPLACE VIEW vw_bowling_summary AS
SELECT
    bowler                                     AS player,
    COUNT(DISTINCT match_id)                   AS matches,
    SUM(is_bowler_wicket)                      AS wickets,
    SUM(total_runs)                            AS runs_conceded,
    ROUND(SUM(total_runs) * 6.0
          / NULLIF(SUM(is_legal), 0), 2)       AS economy,
    ROUND(SUM(total_runs) * 1.0
          / NULLIF(SUM(is_bowler_wicket), 0), 2) AS avg,
    ROUND(SUM(is_legal) * 1.0
          / NULLIF(SUM(is_bowler_wicket), 0), 1) AS strike_rate,
    ROUND(SUM(is_dot) * 100.0
          / NULLIF(SUM(is_legal), 0), 1)       AS dot_pct
FROM deliveries
GROUP BY bowler;


-- View 3: Match result summary
CREATE OR REPLACE VIEW vw_match_summary AS
SELECT
    id,
    season,
    date,
    city,
    venue,
    team1,
    team2,
    toss_winner,
    toss_decision,
    batting_first_team,
    chasing_team,
    winner,
    result,
    win_by_runs,
    win_by_wickets,
    player_of_match,
    batting_first_won,
    chasing_won,
    toss_winner_won
FROM matches;


-- ============================================================
-- SECTION 10: BONUS QUERIES
-- ============================================================

-- Q41: Player consistency — innings with 30+ runs
WITH bat_inn AS (
    SELECT match_id, batsman, SUM(batsman_runs) AS inn_runs
    FROM deliveries
    GROUP BY match_id, batsman
    HAVING SUM(is_legal) > 0
)
SELECT
    batsman,
    COUNT(*)                                     AS total_innings,
    SUM(CASE WHEN inn_runs >= 30 THEN 1 ELSE 0 END) AS quality_innings,
    ROUND(SUM(CASE WHEN inn_runs >= 30 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS consistency_pct
FROM bat_inn
GROUP BY batsman
HAVING COUNT(*) >= 30
ORDER BY consistency_pct DESC
LIMIT 20;


-- Q42: Dismissal type breakdown per bowler
SELECT
    bowler,
    dismissal_kind,
    COUNT(*) AS times
FROM deliveries
WHERE dismissal_kind NOT IN ('not_out', 'run out', 'retired hurt', 'obstructing the field')
  AND dismissal_kind IS NOT NULL
GROUP BY bowler, dismissal_kind
ORDER BY bowler, times DESC;


-- Q43: Balls faced vs runs — dot ball % per batsman
SELECT
    batsman,
    SUM(is_legal)  AS balls_faced,
    SUM(is_dot)    AS dot_balls,
    ROUND(SUM(is_dot) * 100.0 / NULLIF(SUM(is_legal), 0), 1) AS dot_pct,
    SUM(batsman_runs) AS runs
FROM deliveries
GROUP BY batsman
HAVING SUM(is_legal) >= 500
ORDER BY dot_pct
LIMIT 15;


-- Q44: Over-by-over scoring trend for a specific match
-- (Replace 'MATCH_ID_HERE' with actual ID)
SELECT
    over,
    inning,
    SUM(total_runs)   AS over_runs,
    SUM(is_wicket)    AS wickets
FROM deliveries
WHERE match_id = 'MATCH_ID_HERE'
GROUP BY over, inning
ORDER BY inning, over;


-- Q45: Average extras per team (wide + no-ball)
SELECT
    bowling_team,
    ROUND(AVG(extras_per_match), 2) AS avg_extras
FROM (
    SELECT match_id, bowling_team,
           SUM(wide_runs + noball_runs) AS extras_per_match
    FROM deliveries
    GROUP BY match_id, bowling_team
) t
GROUP BY bowling_team
ORDER BY avg_extras DESC;


-- Q46: Teams with most wins in each city
WITH city_wins AS (
    SELECT city, winner AS team, COUNT(*) AS wins
    FROM matches
    WHERE winner NOT IN ('No Result', 'Tie')
      AND city IS NOT NULL
    GROUP BY city, winner
),
ranked AS (
    SELECT city, team, wins,
           RANK() OVER (PARTITION BY city ORDER BY wins DESC) AS rnk
    FROM city_wins
)
SELECT city, team, wins FROM ranked WHERE rnk = 1 ORDER BY wins DESC;


-- Q47: Batsmen dismissed most by a single bowler
SELECT
    d.bowler,
    d.player_dismissed AS batsman,
    COUNT(*) AS times_dismissed
FROM deliveries d
WHERE d.is_bowler_wicket = 1
GROUP BY d.bowler, d.player_dismissed
ORDER BY times_dismissed DESC
LIMIT 20;


-- Q48: Highest team totals ever
SELECT
    d.match_id,
    d.batting_team,
    d.inning,
    SUM(d.total_runs)  AS team_total,
    m.season,
    m.venue
FROM deliveries d
JOIN matches m ON d.match_id = m.id
WHERE d.is_super_over = 0
GROUP BY d.match_id, d.batting_team, d.inning, m.season, m.venue
ORDER BY team_total DESC
LIMIT 20;


-- Q49: Month-wise IPL match distribution
SELECT
    EXTRACT(MONTH FROM date) AS month,
    COUNT(*)                 AS matches
FROM matches
GROUP BY month
ORDER BY month;


-- Q50: Bowling performance against top-order (batsmen 1–3)
-- Requires position tracking — approximate using over 1-6 as top-order proxy
SELECT
    bowler,
    SUM(is_bowler_wicket) AS wickets,
    ROUND(SUM(total_runs) * 6.0 / NULLIF(SUM(is_legal), 0), 2) AS economy
FROM deliveries
WHERE over BETWEEN 1 AND 6  -- powerplay = top order
GROUP BY bowler
HAVING SUM(is_legal) >= 200
ORDER BY wickets DESC
LIMIT 15;


-- Q51: NTILE — divide batsmen into performance tiers (quartiles)
WITH runs AS (
    SELECT batsman, SUM(batsman_runs) AS total_runs
    FROM deliveries
    GROUP BY batsman
    HAVING SUM(is_legal) >= 500
)
SELECT
    batsman,
    total_runs,
    NTILE(4) OVER (ORDER BY total_runs) AS quartile,
    CASE NTILE(4) OVER (ORDER BY total_runs)
        WHEN 4 THEN 'Elite'
        WHEN 3 THEN 'Good'
        WHEN 2 THEN 'Average'
        ELSE 'Below Average'
    END AS tier
FROM runs
ORDER BY total_runs DESC;


-- Q52: First over analysis — runs and wickets in over 1
SELECT
    bowling_team,
    ROUND(AVG(over_runs), 2)  AS avg_first_over_runs,
    SUM(wickets)              AS total_wickets
FROM (
    SELECT match_id, bowling_team,
           SUM(total_runs) AS over_runs,
           SUM(is_bowler_wicket) AS wickets
    FROM deliveries
    WHERE over = 1
    GROUP BY match_id, bowling_team
) t
GROUP BY bowling_team
ORDER BY total_wickets DESC;
