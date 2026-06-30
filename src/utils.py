"""
IPL Analysis – Shared Utility Functions
"""

import os
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns

# ─────────────────────────────────────────────
# PLOT STYLE
# ─────────────────────────────────────────────

IPL_PALETTE = [
    "#1A237E", "#0D47A1", "#1565C0", "#1976D2",
    "#1E88E5", "#42A5F5", "#90CAF9", "#BBDEFB",
    "#FFB300", "#FF6F00",
]

TEAM_COLORS = {
    "Mumbai Indians"            : "#004BA0",
    "Chennai Super Kings"       : "#FFCC00",
    "Royal Challengers Bangalore": "#CC0000",
    "Kolkata Knight Riders"     : "#3B215A",
    "Delhi Capitals"            : "#17479E",
    "Sunrisers Hyderabad"       : "#F7A721",
    "Rajasthan Royals"          : "#EA1A85",
    "Punjab Kings"              : "#DCDDDF",
    "Lucknow Super Giants"      : "#A72056",
    "Gujarat Titans"            : "#1C4A74",
    "Kochi Tuskers Kerala"      : "#BE1515",
    "Rising Pune Supergiant"    : "#6E1F7A",
}


def set_plot_style() -> None:
    """Apply consistent dark-professional style to all matplotlib figures."""
    plt.rcParams.update({
        "figure.facecolor"  : "#0F172A",
        "axes.facecolor"    : "#1E293B",
        "axes.edgecolor"    : "#334155",
        "axes.labelcolor"   : "#CBD5E1",
        "xtick.color"       : "#94A3B8",
        "ytick.color"       : "#94A3B8",
        "text.color"        : "#F1F5F9",
        "grid.color"        : "#334155",
        "grid.linestyle"    : "--",
        "grid.alpha"        : 0.4,
        "font.family"       : "sans-serif",
        "axes.titlesize"    : 14,
        "axes.titleweight"  : "bold",
        "axes.titlecolor"   : "#F1F5F9",
        "axes.labelsize"    : 11,
        "legend.facecolor"  : "#1E293B",
        "legend.edgecolor"  : "#334155",
        "legend.labelcolor" : "#CBD5E1",
    })
    sns.set_theme(style="darkgrid", palette=IPL_PALETTE)


def save_fig(fig: plt.Figure, name: str, subdir: str = "eda") -> str:
    """Save figure to dashboard_images/<subdir>/<name>.png"""
    base = os.path.join(
        os.path.dirname(__file__), "..", "dashboard_images", subdir
    )
    os.makedirs(base, exist_ok=True)
    path = os.path.join(base, f"{name}.png")
    fig.savefig(path, dpi=150, bbox_inches="tight",
                facecolor=fig.get_facecolor())
    plt.close(fig)
    return path


def human_format(x: float, _pos=None) -> str:
    """Format large numbers as 1.2K, 3.4M etc."""
    if x >= 1_000_000:
        return f"{x/1_000_000:.1f}M"
    if x >= 1_000:
        return f"{x/1_000:.1f}K"
    return str(int(x))


def add_value_labels(ax: plt.Axes, fmt: str = "{:.0f}",
                     padding: float = 3, fontsize: int = 9) -> None:
    """Annotate bar chart bars with their values."""
    for patch in ax.patches:
        val = patch.get_height()
        if val == 0:
            continue
        ax.annotate(
            fmt.format(val),
            xy=(patch.get_x() + patch.get_width() / 2, val),
            xytext=(0, padding),
            textcoords="offset points",
            ha="center", va="bottom",
            fontsize=fontsize, color="#F1F5F9"
        )


def load_cleaned() -> tuple:
    """Load cleaned DataFrames from disk."""
    base = os.path.join(os.path.dirname(__file__), "..", "data", "cleaned")
    m = pd.read_csv(os.path.join(base, "matches_cleaned.csv"),
                    parse_dates=["date"])
    d = pd.read_csv(os.path.join(base, "deliveries_cleaned.csv"))
    return m, d
