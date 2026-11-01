# Notandor.cn & Telegram EA Backup Manifest & Complete Archive Report

**Repository Location**: `e:\Github Submissions\notandor cn backup`  
**Date of Archive Generation**: November 1, 2026  
**Catalog Status**: **12,727+ Posts Indexed** across all categories  
**Telegram Repository**: `t.me/www_notandor_cn` (**13,800+ Direct File Documents**)  
**Active Continuous Daemon**: `crawler.py --download` (Running in background)

---

## 1. Executive Summary

This backup infrastructure provides an automated, continuous, and dual-source mirror of all 14,000+ Expert Advisors (EAs), indicators, and algorithmic trading systems from both:
1. The **Notandor.cn Web Platform** (`https://www.notandor.cn/`), indexing **12,727+ posts** with automatic Aliyun WAF puzzle solving, Lanzou batch folder parameter parsing, and CDN anti-hotlink resolution.
2. The **Official Telegram Repository** (`t.me/www_notandor_cn`), hosting **13,800+ individual `.zip` archives** directly on Telegram's high-speed CDN.

---

## 2. Live Backup Status & Asset Count

```
============================================================
          NOTANDOR.CN & TELEGRAM BACKUP STATUS          
============================================================
  Total Catalog Posts Indexed:      12,727+
  Telegram Channel Messages:        13,800+ Documents
  Active Download Daemons:          RUNNING (Background)
  Downloaded Archive Files:         316+ (111.26 MB)
  Total Extracted Trading Assets:   622+
    - MQL4 Source Codes (.mq4):     9
    - MT4 Compiled EAs (.ex4):      107
    - MQL5 Source Codes (.mq5):     27
    - MT5 Compiled EAs (.ex5):      202
    - Strategy Presets (.set):      277
============================================================
```

---

## 3. Storage Hierarchy

```
notandor cn backup/
├── crawler.py                  # Master automated web & cloud crawler daemon
├── tg_cataloger.py             # Telegram web preview spider (indexes t.me/s/www_notandor_cn)
├── tg_downloader.py            # Telethon MTProto direct channel downloader
├── solve_acw.js                # Node.js V8 sandboxed WAF challenge solver
├── README.md                   # Complete system guide & dual-pipeline instructions
├── BACKUP_MANIFEST.md          # Comprehensive inventory & technical audit report
│
├── metadata/
│   ├── ea_catalog.json         # Master index of 12,727+ web posts (3.2+ MB)
│   ├── tg_channel_catalog.json # Telegram channel file catalog
│   ├── download_manifest.json  # Resumable download tracking state
│   └── extracted_index.json    # Inventory of unpacked trading assets
│
├── downloads/                  # Raw downloaded .zip / .rar archives
│   ├── 55634_The_Gold_Phantom[notandor.cn].zip
│   ├── 55634_Equity 2026[notandor.cn].mq4.zip
│   ├── 55629_Vertex Stag EURUSD EA[notandor.cn].ex4.zip
│   ├── 55625_Breakout Retest Pro EA Source Code[notandor.cn].mq4.zip
│   ├── 55606_WallStreet Recovery PRO_1.7_fix[notandor.cn].ex4.zip
│   └── ... (continuous stream)
│
└── extracted_eas/              # Classified trading software assets
    ├── mq4/                    # MQL4 Source Codes (.mq4)
    ├── ex4/                    # MetaTrader 4 Compiled Robots (.ex4)
    ├── mq5/                    # MQL5 Source Codes (.mq5)
    ├── ex5/                    # MetaTrader 5 Compiled Robots (.ex5)
    ├── set/                    # Optimized Parameter Presets (.set)
    └── other/                  # Documentation, manuals, and templates
```
