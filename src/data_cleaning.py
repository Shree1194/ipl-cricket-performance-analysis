"""
IPL Cricket Performance Analysis (2008–2024)
=============================================
Step 1: Data Cleaning Pipeline
Author: Data Analytics Portfolio Project
"""

import pandas as pd
import numpy as np
import os
import warnings
warnings.filterwarnings("ignore")


# ─────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────
RAW_DIR     = os.path.join(os.path.dirname(__file__), "..", "data", "raw")
CLEANED_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "cleaned")

MATCHES_RAW     = os.path.join(RAW_DIR, "matches.csv")
DELIVERIES_RAW  = os.path.join(RAW_DIR, "deliveries.csv")
MATCHES_CLEAN   = os.path.join(CLEANED_DIR, "matches_cleaned.csv")
DELIVERIES_CLEAN= os.path.join(CLEANED_DIR, "deliveries_cleaned.csv")


# ─────────────────────────────────────────────
# TEAM NAME NORMALISATION MAP
# (franchises changed names over the years)
# ─────────────────────────────────────────────
TEAM_NAME_MAP = {
    "Delhi Daredevils"              : "Delhi Capitals",
    "Deccan Chargers"               : "Sunrisers Hyderabad",
    "Pune Warriors"                 : "Rising Pune Supergiant",
    "Kings XI Punjab"               : "Punjab Kings",
    "Rising Pune Supergiants"       : "Rising Pune Supergiant",
}

# City / venue fixes
CITY_FIXES = {
    "Bengaluru"    : "Bangalore",
    "Delhi"        : "Delhi",
    "Mumbai"       : "Mumbai",
    "Kolkata"      : "Kolkata",
    "Hyderabad"    : "Hyderabad",
    "Chennai"      : "Chennai",
    "Chandigarh"   : "Mohali",
}

# Known venues → city fallback when city is null
VENUE_CITY_MAP = {
    "M Chinnaswamy Stadium"                            : "Bangalore",
    "Wankhede Stadium"                                 : "Mumbai",
    "Eden Gardens"                                     : "Kolkata",
    "Feroz Shah Kotla"                                 : "Delhi",
    "Arun Jaitley Stadium"                             : "Delhi",
    "MA Chidambaram Stadium"                           : "Chennai",
    "Rajiv Gandhi International Stadium"               : "Hyderabad",
    "Punjab Cricket Association IS Bindra Stadium"     : "Mohali",
    "Sawai Mansingh Stadium"                           : "Jaipur",
    "Brabourne Stadium"                                : "Mumbai",
    "DY Patil Stadium"                                 : "Mumbai",
    "Subrata Roy Sahara Stadium"                       : "Pune",
    "Maharashtra Cricket Association Stadium"          : "Pune",
    "Narendra Modi Stadium"                            : "Ahmedabad",
    "Sardar Patel Stadium"                             : "Ahmedabad",
    "Motera Stadium"                                   : "Ahmedabad",
    "Himachal Pradesh Cricket Association Stadium"     : "Dharamsala",
    "JSCA International Stadium Complex"               : "Ranchi",
    "Greenfield International Stadium"                 : "Thiruvananthapuram",
    "Shaheed Veer Narayan Singh International Stadium" : "Raipur",
    "Holkar Cricket Stadium"                           : "Indore",
    "ACA-VDCA Cricket Stadium"                         : "Visakhapatnam",
}


# ─────────────────────────────────────────────
# HELPER FUNCTIONS
# ─────────────────────────────────────────────

def load_raw(path: str, label: str) -> pd.DataFrame:
    """Load CSV and report shape."""
    df = pd.read_csv(path)
    print(f"  [{label}] Loaded  → {df.shape[0]:,} rows × {df.shape[1]} cols")
    return df


def normalise_team_names(df: pd.DataFrame, cols: list) -> pd.DataFrame:
    """Replace legacy franchise names with current names."""
    for col in cols:
        if col in df.columns:
            df[col] = df[col].replace(TEAM_NAME_MAP)
    return df


def fix_nulls_matches(df: pd.DataFrame) -> pd.DataFrame:
    """
    Impute / drop nulls in matches DataFrame.
    - city          → derive from venue map
    - winner        → 'No Result' for tie/no-result rows
    - player_of_match → 'Not Awarded'
    - umpire2       → 'Unknown'
    """
    # City from venue
    df["city"] = df["city"].fillna(df["venue"].map(VENUE_CITY_MAP))
    df["city"] = df["city"].replace(CITY_FIXES)

    # Winner
    no_result_mask = df["result"].str.lower().isin(["no result", "tie"]) | df["winner"].isna()
    df.loc[no_result_mask, "winner"] = df.loc[no_result_mask, "result"].str.title().fillna("No Result")

    # Player of the match
    df["player_of_match"] = df["player_of_match"].fillna("Not Awarded")

    # Umpires
    for col in ["umpire1", "umpire2"]:
        if col in df.columns:
            df[col] = df[col].fillna("Unknown")

    return df


def fix_nulls_deliveries(df: pd.DataFrame) -> pd.DataFrame:
    """
    Impute nulls in deliveries DataFrame.
    - player_dismissed   → 'not_out'
    - dismissal_kind     → 'not_out'
    - fielder            → 'none'
    - extra_runs numeric → 0
    """
    df["player_dismissed"] = df["player_dismissed"].fillna("not_out")
    df["dismissal_kind"]   = df["dismissal_kind"].fillna("not_out")
    df["fielder"]          = df["fielder"].fillna("none")

    extra_cols = ["wide_runs", "bye_runs", "legbye_runs", "noball_runs",
                  "penalty_runs", "extras"]
    for col in extra_cols:
        if col in df.columns:
            df[col] = df[col].fillna(0).astype(int)
    return df


def engineer_matches_features(df: pd.DataFrame) -> pd.DataFrame:
    """Add derived columns to matches DataFrame."""
    # Season
    df["date"]   = pd.to_datetime(df["date"], dayfirst=True, errors="coerce")
    df["season"] = df["date"].dt.year

    # Batting / chasing flags
    df["batting_first_team"]  = df["team1"].where(df["toss_decision"] == "bat", df["team2"])
    df["chasing_team"]        = df["team2"].where(df["toss_decision"] == "bat", df["team1"])
    df["batting_first_won"]   = (df["winner"] == df["batting_first_team"]).astype(int)
    df["chasing_won"]         = (df["winner"] == df["chasing_team"]).astype(int)

    # Toss winner won match?
    df["toss_winner_won"] = (df["toss_winner"] == df["winner"]).astype(int)

    # Day / Night flag (approximate; most IPL matches are D/N)
    if "dl_applied" not in df.columns:
        df["dl_applied"] = 0
    df["dl_applied"] = df["dl_applied"].fillna(0).astype(int)

    return df


def engineer_delivery_features(df: pd.DataFrame) -> pd.DataFrame:
    """Add derived columns to deliveries DataFrame."""
    # Over phase
    def over_phase(over: int) -> str:
        if over <= 6:
            return "Powerplay"
        elif over <= 15:
            return "Middle"
        else:
            return "Death"

    df["over_phase"] = df["over"].apply(over_phase)

    # Is boundary?
    df["is_four"] = (df["batsman_runs"] == 4).astype(int)
    df["is_six"]  = (df["batsman_runs"] == 6).astype(int)
    df["is_dot"]  = (df["batsman_runs"] == 0).astype(int)

    # Is wicket (bowler's wicket only)
    bowler_wickets = ["caught", "bowled", "lbw", "stumped",
                      "caught and bowled", "hit wicket"]
    df["is_bowler_wicket"] = df["dismissal_kind"].isin(bowler_wickets).astype(int)
    df["is_wicket"]        = df["is_wicket"].fillna(0).astype(int)

    # Legal delivery flag
    df["is_legal"] = (df["wide_runs"] == 0).astype(int)

    return df


def remove_duplicates(df: pd.DataFrame, label: str) -> pd.DataFrame:
    before = len(df)
    df = df.drop_duplicates()
    print(f"  [{label}] Duplicates removed → {before - len(df)}")
    return df


def enforce_dtypes_matches(df: pd.DataFrame) -> pd.DataFrame:
    df["id"]     = df["id"].astype(str)
    df["season"] = df["season"].astype("Int64")
    return df


def enforce_dtypes_deliveries(df: pd.DataFrame) -> pd.DataFrame:
    int_cols = ["inning", "over", "ball", "batsman_runs",
                "extra_runs", "total_runs", "is_wicket"]
    for col in int_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0).astype(int)
    df["match_id"] = df["match_id"].astype(str)
    return df


def save_cleaned(df: pd.DataFrame, path: str, label: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    df.to_csv(path, index=False)
    print(f"  [{label}] Saved   → {path}  ({df.shape[0]:,} rows × {df.shape[1]} cols)")


# ─────────────────────────────────────────────
# MAIN PIPELINE
# ─────────────────────────────────────────────

def clean_matches() -> pd.DataFrame:
    print("\n── Cleaning matches.csv ──")
    df = load_raw(MATCHES_RAW, "matches")
    df = remove_duplicates(df, "matches")
    df = normalise_team_names(df, ["team1", "team2", "winner",
                                   "toss_winner", "batting_first_team"])
    df = fix_nulls_matches(df)
    df = engineer_matches_features(df)
    df = enforce_dtypes_matches(df)
    save_cleaned(df, MATCHES_CLEAN, "matches")
    return df


def clean_deliveries(matches_df: pd.DataFrame) -> pd.DataFrame:
    print("\n── Cleaning deliveries.csv ──")
    df = load_raw(DELIVERIES_RAW, "deliveries")
    df = remove_duplicates(df, "deliveries")
    df = fix_nulls_deliveries(df)
    df = engineer_delivery_features(df)
    df = enforce_dtypes_deliveries(df)

    # Merge season from matches
    season_map = matches_df.set_index("id")["season"].to_dict()
    df["season"] = df["match_id"].map(season_map)

    # Normalise team names in deliveries
    df = normalise_team_names(df, ["batting_team", "bowling_team"])

    save_cleaned(df, DELIVERIES_CLEAN, "deliveries")
    return df


def run_cleaning_pipeline() -> tuple:
    """Entry-point: cleans both datasets and returns DataFrames."""
    print("=" * 55)
    print("  IPL Data Cleaning Pipeline")
    print("=" * 55)
    matches    = clean_matches()
    deliveries = clean_deliveries(matches)
    print("\n✅  Cleaning complete.\n")

    # Quick summary
    print("── Summary ──")
    print(f"  Seasons  : {matches['season'].nunique()} ({int(matches['season'].min())}–{int(matches['season'].max())})")
    print(f"  Matches  : {len(matches):,}")
    print(f"  Deliveries: {len(deliveries):,}")
    print(f"  Teams    : {matches['team1'].nunique()}")
    print(f"  Venues   : {matches['venue'].nunique()}")
    return matches, deliveries


if __name__ == "__main__":
    run_cleaning_pipeline()
