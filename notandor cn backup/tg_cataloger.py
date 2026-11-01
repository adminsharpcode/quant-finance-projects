import sys
sys.stdout.reconfigure(encoding='utf-8')
import requests
import re
import json
import time
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
METADATA_DIR = BASE_DIR / "metadata"
METADATA_DIR.mkdir(parents=True, exist_ok=True)
TG_CATALOG_FILE = METADATA_DIR / "tg_channel_catalog.json"

s = requests.Session()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
}

def crawl_tg_channel(max_batches: int = 50):
    print("[*] Starting Telegram channel crawler for 'www_notandor_cn'...")
    catalog = {}
    if TG_CATALOG_FILE.exists():
        try:
            with open(TG_CATALOG_FILE, 'r', encoding='utf-8') as f:
                catalog = json.load(f)
        except Exception:
            pass

    current_url = 'https://t.me/s/www_notandor_cn'
    batch = 0
    total_files = len(catalog)

    while current_url and batch < max_batches:
        batch += 1
        try:
            r = s.get(current_url, headers=headers, timeout=20)
            if r.status_code != 200:
                print(f"  [!] HTTP {r.status_code} on {current_url}. Retrying...")
                time.sleep(2)
                continue

            html = r.text
            # Find all message blocks with documents
            # Pattern: <a class="tgme_widget_message_document_wrap" href="https://t.me/www_notandor_cn/(\d+)\?single">
            # <div class="tgme_widget_message_document_title[^"]*"[^>]*>(.*?)</div>
            # <div class="tgme_widget_message_document_extra[^"]*"[^>]*>(.*?)</div>
            doc_matches = re.findall(
                r'<a[^>]+class=["\']tgme_widget_message_document_wrap["\'][^>]+href=["\']https?://t\.me/www_notandor_cn/(\d+)[^"\']*["\'][^>]*>.*?'
                r'<div[^>]*class=["\']tgme_widget_message_document_title[^"\']*["\'][^>]*>(.*?)</div>.*?'
                r'<div[^>]*class=["\']tgme_widget_message_document_extra[^"\']*["\'][^>]*>(.*?)</div>',
                html,
                re.S
            )

            new_in_batch = 0
            for msg_id, doc_title, doc_size in doc_matches:
                doc_title = html_unescape(doc_title.strip())
                if msg_id not in catalog:
                    catalog[msg_id] = {
                        "msg_id": msg_id,
                        "file_name": doc_title,
                        "size": doc_size.strip(),
                        "url": f"https://t.me/www_notandor_cn/{msg_id}",
                        "channel": "www_notandor_cn"
                    }
                    new_in_batch += 1
                    total_files += 1

            # Extract oldest message ID to paginate backwards
            msgs = re.findall(r'data-post="www_notandor_cn/(\d+)"', html)
            oldest_id = min([int(m) for m in msgs]) if msgs else None
            
            print(f"  [+] Batch {batch}: found {len(doc_matches)} docs (+{new_in_batch} new). Oldest msg: {oldest_id}. Total cataloged: {total_files}")

            # Check next pagination link: /s/www_notandor_cn?before=...
            next_link_m = re.search(r'href="(/s/www_notandor_cn\?before=\d+)"', html)
            if next_link_m:
                current_url = "https://t.me" + next_link_m.group(1)
            elif oldest_id:
                current_url = f"https://t.me/s/www_notandor_cn?before={oldest_id}"
            else:
                break

            if batch % 10 == 0:
                with open(TG_CATALOG_FILE, 'w', encoding='utf-8') as f:
                    json.dump(catalog, f, ensure_ascii=False, indent=2)

            time.sleep(1.0)

        except Exception as e:
            print(f"  [!] Error crawling batch {batch}: {e}")
            time.sleep(2)

    with open(TG_CATALOG_FILE, 'w', encoding='utf-8') as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
    print(f"\n[✓] Telegram Cataloging complete! Total files indexed: {len(catalog)}")

def html_unescape(text):
    import html
    return html.unescape(text)

if __name__ == '__main__':
    crawl_tg_channel(max_batches=20)
