# IPL Power BI Dashboard — Design Plan

## Theme
Dark professional theme (`#0F172A` background, `#F1F5F9` text, accent `#1E88E5` / `#FFB300`)

---

## Page 1 — Executive Summary

### Visuals
| Visual | Type | Field(s) |
|--------|------|---------|
| Total Matches | Card | COUNT(id) |
| Total Seasons | Card | DISTINCTCOUNT(season) |
| Total Teams | Card | DISTINCTCOUNT(team1) |
| Total Venues | Card | DISTINCTCOUNT(venue) |
| Matches per Season | Line chart | season → COUNT(id) |
| Wins by Team (Top 8) | Horizontal bar | winner → COUNT(*) |
| Toss Decision Trend | Stacked bar | season, toss_decision |
| Season slicer | Slicer | season |

### DAX Measures
```DAX
Total Matches = COUNTROWS(matches)

Win % = 
DIVIDE(
    COUNTROWS(FILTER(matches, matches[winner] = SELECTEDVALUE(matches[team1]))),
    COUNTROWS(matches)
) * 100

Toss Win % = 
DIVIDE(
    COUNTROWS(FILTER(matches, matches[toss_winner_won] = 1)),
    COUNTROWS(FILTER(matches, matches[result] <> "No Result"))
) * 100
```

---

## Page 2 — Team Analysis

### Visuals
| Visual | Type | Field(s) |
|--------|------|---------|
| Win % by Team | Bar chart | team, win_pct |
| Wins: Bat First vs Chase | Clustered bar | team, batting_first_won, chasing_won |
| Season-wise Team Performance | Line | season, team, wins |
| Toss Decision by Team | 100% stacked bar | team, toss_decision |
| Head-to-Head Matrix | Matrix | team1, team2, wins |
| Team filter | Slicer | team1 |

### DAX Measures
```DAX
Wins Batting First = 
CALCULATE(
    COUNTROWS(matches),
    matches[batting_first_won] = 1
)

Chase Success % = 
DIVIDE(
    CALCULATE(COUNTROWS(matches), matches[chasing_won] = 1),
    CALCULATE(COUNTROWS(matches), matches[result] = "wickets")
) * 100
```

---

## Page 3 — Player Analysis

### Visuals
| Visual | Type | Field(s) |
|--------|------|---------|
| Top 15 Run Scorers | Horizontal bar | batsman, total_runs |
| Top 15 Wicket Takers | Horizontal bar | bowler, total_wickets |
| Strike Rate Leaders | Scatter | batsman, runs, strike_rate |
| Economy Leaders | Bar | bowler, economy |
| Orange Cap Timeline | Bar | season, batsman, runs |
| Purple Cap Timeline | Bar | season, bowler, wickets |
| Player POTM Awards | Treemap | player_of_match, count |
| Player name filter | Slicer | batsman/bowler |

### DAX Measures
```DAX
Batting Average = 
DIVIDE(
    SUM(deliveries[batsman_runs]),
    SUMX(deliveries, IF(deliveries[is_wicket]=1, 1, 0))
)

Bowling Economy = 
DIVIDE(SUM(deliveries[total_runs]) * 6, SUM(deliveries[is_legal]))

Strike Rate = 
DIVIDE(SUM(deliveries[batsman_runs]) * 100, SUM(deliveries[is_legal]))
```

---

## Page 4 — Venue Analysis

### Visuals
| Visual | Type | Field(s) |
|--------|------|---------|
| Matches by City | Map | city, COUNT(*) |
| Avg Score by Venue | Bar | venue, avg_score |
| Chase Win % by Venue | Bar + reference line @ 50 | venue, chase_pct |
| Wickets by Venue | Bar | venue, wickets |
| Venue filter | Slicer | venue |

---

## Page 5 — Season Analysis

### Visuals
| Visual | Type | Field(s) |
|--------|------|---------|
| KPI: Season Summary | Cards | matches, total_runs, avg_score |
| Run Rate Trend | Line | season, avg_run_rate |
| Top Scorer per Season | Table | season, batsman, runs |
| Top Wicket Taker per Season | Table | season, bowler, wickets |
| Season boundary % | Line | season, boundary_pct |
| Season slicer | Slicer | season |

---

## Page 6 — Best XI Dashboard

### Visuals
| Visual | Type | Field(s) |
|--------|------|---------|
| Best XI Table | Table | player, role, batting_score, bowling_score, overall_score |
| Batting Score Bar | Bar | player, batting_score |
| Bowling Score Bar | Bar | player, bowling_score |
| Radar Chart | Custom visual | player, runs, avg, SR, wickets, economy |
| Parameter: Role weight | What-if parameter | bat_weight (0–1 slider) |

### DAX Measures
```DAX
Batting Score = 
VAR MaxRuns = MAXX(ALL(batting_summary), batting_summary[total_runs])
VAR MaxAvg  = MAXX(ALL(batting_summary), batting_summary[avg])
VAR MaxSR   = MAXX(ALL(batting_summary), batting_summary[strike_rate])
RETURN
    DIVIDE(batting_summary[total_runs], MaxRuns) * 0.30 +
    DIVIDE(batting_summary[avg], MaxAvg)         * 0.25 +
    DIVIDE(batting_summary[strike_rate], MaxSR)  * 0.25 +
    ... 

Overall Score = 
[Batting Score] * 0.55 + [Bowling Score] * 0.45
```

---

## Bookmarks & Interactivity

| Bookmark | Purpose |
|----------|---------|
| All Seasons | Reset all slicers |
| IPL 2016 | Pre-set filter to Kohli's best year |
| Mumbai Indians | Pre-set for MI analysis |
| CSK | Pre-set for CSK analysis |
| Death Bowlers | Filter deliveries to over > 16 |

## Drill-Through
- Click any team → drill to Team Analysis page (filtered)
- Click any player → drill to Player Analysis page (filtered)
- Click any venue → drill to Venue Analysis page (filtered)

## Dynamic Titles
```DAX
Chart Title = 
"Performance for " & SELECTEDVALUE(matches[season], "All Seasons")
```

## Tooltips
- Hover on bar → show full stats card
- Hover on scatter point → show player summary tooltip page
```

---

## Data Model (Star Schema)

```
fact_deliveries ──────── dim_player (batsman/bowler)
      │                  dim_team
      └──────────────── dim_match
                              │
                        dim_venue
                        dim_season
```

## Connection Steps (Power BI Desktop)
1. Get Data → Text/CSV → `data/cleaned/matches_cleaned.csv`
2. Get Data → Text/CSV → `data/cleaned/deliveries_cleaned.csv`
3. Manage Relationships:
   - `deliveries[match_id]` → `matches[id]` (Many-to-One)
4. Create calculated columns in Power Query (M)
5. Build DAX measures as listed above
6. Apply dark theme: View → Themes → Import → use JSON below

## Theme JSON (save as `ipl_theme.json`)
```json
{
  "name": "IPL Dark Pro",
  "dataColors": ["#1E88E5","#FFB300","#E53935","#00897B","#7B1FA2","#FF6F00","#1565C0","#558B2F"],
  "background": "#0F172A",
  "foreground": "#F1F5F9",
  "tableAccent": "#1E88E5",
  "visualStyles": {
    "*": {
      "*": {
        "background": [{"color": {"solid": {"color": "#1E293B"}}}],
        "border": [{"color": {"solid": {"color": "#334155"}}}]
      }
    }
  }
}
```
