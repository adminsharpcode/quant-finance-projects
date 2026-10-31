"""
Web Data Bundle Builder (With Sequential Test Leaderboard)
-----------------------------------------------------------
Bundles catalog, backtest metrics, and 1,297 sequential test leaderboard into data.js.
"""

import os
import json
import pandas as pd

ROOT = r"e:\Github Submissions\06-mq4-tick-alpha-engine"
data_dir = os.path.join(ROOT, "data")
web_dir = os.path.join(ROOT, "web")
os.makedirs(web_dir, exist_ok=True)

with open(os.path.join(data_dir, "mq4_strategy_catalog.json"), "r", encoding="utf-8") as f:
    cat = json.load(f)

with open(os.path.join(data_dir, "pipeline_results.json"), "r", encoding="utf-8") as f:
    pipe = json.load(f)

with open(os.path.join(data_dir, "sequential_test_summary.json"), "r", encoding="utf-8") as f:
    seq_summary = json.load(f)

ml_insights_path = os.path.join(data_dir, "ml_codebase_insights.json")
ml_insights = {}
if os.path.exists(ml_insights_path):
    with open(ml_insights_path, "r", encoding="utf-8") as f:
        ml_insights = json.load(f)

meta_label_path = os.path.join(data_dir, "ml_meta_labeling_results.json")
meta_label_data = {}
if os.path.exists(meta_label_path):
    with open(meta_label_path, "r", encoding="utf-8") as f:
        meta_label_data = json.load(f)

df_board = pd.read_csv(os.path.join(data_dir, "sequential_test_leaderboard.csv"))
# Filter top 100 for web UI
top_board = df_board[df_board['Type'] == 'Expert Advisor'].sort_values('ProfitFactor', ascending=False).head(100).to_dict(orient='records')

compact_catalog = []
for item in cat["catalog"][:350]:
    compact_catalog.append({
        "name": item["filename"],
        "type": item["file_type"],
        "loc": item["lines_of_code"],
        "indicators": item["builtin_indicators"][:4],
        "is_martingale": item["is_martingale_or_grid"],
        "has_sl": item["has_stoploss"],
        "has_tp": item["has_takeprofit"]
    })

js_content = f"""// Auto-generated quantitative data bundle for web dashboard
const MQ4_SUMMARY = {json.dumps(cat['summary'], indent=2)};

const PIPELINE_RESULTS = {json.dumps(pipe, indent=2)};

const SEQUENTIAL_SUMMARY = {json.dumps(seq_summary, indent=2)};

const SEQUENTIAL_LEADERBOARD = {json.dumps(top_board, indent=2)};

const MQ4_CATALOG = {json.dumps(compact_catalog, indent=2)};

const ML_INSIGHTS = {json.dumps(ml_insights, indent=2)};

const ML_META_LABELING = {json.dumps(meta_label_data, indent=2)};
"""

out_js = os.path.join(web_dir, "data.js")
with open(out_js, "w", encoding="utf-8") as f:
    f.write(js_content)

print(f"Generated web data bundle with sequential leaderboard: {out_js} ({os.path.getsize(out_js)} bytes)")
