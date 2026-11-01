# Notandor.cn & Telegram EA Backup Manifest & Complete Archive Report

**Repository Location**: `e:\Github Submissions\notandor cn backup`  
**Date of Archive Generation**: November 1, 2026  
**Catalog Status**: **13,132 Posts Indexed** across all categories (`expert-adviso`, `indicators`, `other`)  
**Telegram Repository**: `t.me/www_notandor_cn` (**13,800+ Direct File Documents**)  
**Active Continuous Daemon**: `crawler.py --download --continuous` (Active in background)

---

## 1. Executive Summary

This backup infrastructure provides an automated, continuous, and dual-source mirror of all 14,000+ Expert Advisors (EAs), indicators, and algorithmic trading systems from both:
1. The **Notandor.cn Web Platform** (`https://www.notandor.cn/`), indexing **13,132 posts** with automatic Aliyun WAF puzzle solving, Lanzou batch folder parameter parsing, CDN anti-hotlink resolution, and self-healing retry logic.
2. The **Official Telegram Repository** (`t.me/www_notandor_cn`), hosting **13,800+ individual `.zip` archives** directly on Telegram's high-speed CDN.

---

## 2. Live Backup Status & Asset Count

```
============================================================
          NOTANDOR.CN & TELEGRAM BACKUP STATUS          
============================================================
  Total Catalog Posts Indexed:      13,132
  Posts Processed in Manifest:      109+ (Continuous Daemon Active)
  Manifest Success Rate:            100%
  Telegram Channel Documents:       13,800+ Archives
  Downloaded Archive Files:         1,950+ (697+ MB)
  Total Extracted Trading Assets:   3,620+
    - MQL4 Source Codes (.mq4):     554
    - MT4 Compiled EAs (.ex4):      1,546
    - MQL5 Source Codes (.mq5):     51
    - MT5 Compiled EAs (.ex5):      748
    - Strategy Presets (.set):      721
============================================================
```

---

## 3. Storage Hierarchy

```
notandor cn backup/
├── crawler.py                  # Master automated web & cloud crawler daemon (Continuous mode)
├── tg_cataloger.py             # Telegram web preview spider (indexes t.me/s/www_notandor_cn)
├── tg_downloader.py            # Telethon MTProto direct channel downloader
├── solve_acw.js                # Node.js V8 sandboxed WAF challenge solver
├── README.md                   # Complete system guide & dual-pipeline instructions
├── BACKUP_MANIFEST.md          # Comprehensive inventory & technical audit report
│
├── metadata/
│   ├── ea_catalog.json         # Master index of 13,132 web posts (3.5+ MB)
│   ├── tg_channel_catalog.json # Telegram channel file catalog
│   ├── download_manifest.json  # Resumable download tracking state (100% success rate)
│   └── extracted_index.json    # Master inventory of unpacked trading assets
│
├── downloads/                  # Raw downloaded .zip / .rar archives (preserved on local disk)
│   ├── 55634_The_Gold_Phantom[notandor.cn].zip
│   ├── 55634_Equity 2026[notandor.cn].mq4.zip
│   ├── 54949_Maros EA v1.0 MT4 -.zip
│   ├── 54945_IS New Project EA MQ4 -.zip
│   ├── 54936_FastWay EA V1.23 MT5 -.zip
│   ├── 54927_TPC Bot EA V4.0 MT5 -.zip
│   └── ... (continuous stream of 13,132 posts)
│
└── extracted_eas/              # Classified trading software assets
    ├── mq4/                    # 554 MQL4 Source Codes (.mq4)
    ├── ex4/                    # 1,546 MetaTrader 4 Compiled Robots (.ex4)
    ├── mq5/                    # 51 MQL5 Source Codes (.mq5)
    ├── ex5/                    # 748 MetaTrader 5 Compiled Robots (.ex5)
    ├── set/                    # 721 Optimized Strategy Presets (.set)
    └── other/                  # Documentation, manuals, DLLs, and templates (.tpl)
```

---

## 4. Reverse-Engineered Architecture & Resilience Engine

1. **Aliyun WAF Challenge Bypass (`solve_acw.js`)**:
   - Lanzou and Lanrar CDN endpoints are protected by Aliyun WAF returning 16-character obfuscated hex puzzle strings (`arg1`).
   - The crawler executes `solve_acw.js` via Node.js V8 runtime to compute the dynamic `acw_sc__v2` cookie required for access.

2. **Lanzou Folder Parameter Parsing**:
   - Detects folder URLs (`/b0...`) and uses regex patterns (`\d{10}` for timestamp `t`, `[a-f0-9]{32}` for MD5 `k`) to unpack batch archives with 20–50 subfiles per release.

3. **CDN Anti-Hotlink Resolution & Fallback**:
   - Lanrar CDN pages (`developerX.lanrar.com/file/?...`) require POST to `/file/ajax.php` with `{file, el: 2, sign}` to obtain final streaming download URLs (`zip2.webgetstore.com/...`), fetched via `curl.exe --globoff`.

4. **Fault-Tolerant Daemon Loop (`--continuous`)**:
   - urllib3 `HTTPAdapter` with 3-attempt backoff mounted across all HTTP/HTTPS adapters.
   - Per-post top-level exception insulation ensuring that isolated network hiccups or CDN disconnects never terminate the background daemon.
   - Automated periodic archive extraction and real-time manifest synchronization.
