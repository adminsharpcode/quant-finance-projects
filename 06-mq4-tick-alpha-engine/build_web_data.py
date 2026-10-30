"""
Web Data Bundle Builder
------------------------
Extracts catalog and backtest metrics into lightweight JS bundle for client-side web application.
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

# Compact catalog items for web search (first 300 diverse items)
compact_catalog = []
for item in cat["catalog"][:400]:
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

const MQ4_CATALOG = {json.dumps(compact_catalog, indent=2)};
"""

out_js = os.path.join(web_dir, "data.js")
with open(out_js, "w", encoding="utf-8") as f:
    f.write(js_content)

print(f"Generated web data bundle: {out_js} ({os.path.getsize(out_js)} bytes)")
