#!/usr/bin/env python3
"""
Notandor.cn Expert Advisor Crawler & Backup Engine
Automated multi-stage downloader with Aliyun WAF bypass, Lanzou folder/file resolution,
CDN anti-hotlink resolution, multi-category coverage (10,000+ EAs/indicators),
automatic archive unpacking, and resilient retry architecture.
"""

import sys
sys.stdout.reconfigure(encoding='utf-8', line_buffering=True)
sys.stderr.reconfigure(encoding='utf-8', line_buffering=True)
import os
import re
import json
import time
import html
import shutil
import zipfile
import argparse
import subprocess
import requests
import urllib3
from pathlib import Path
from urllib.parse import urlparse, urljoin

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# --- Configuration & Paths ---
BASE_DIR = Path(__file__).resolve().parent
DOWNLOADS_DIR = BASE_DIR / "downloads"
EXTRACTED_DIR = BASE_DIR / "extracted_eas"
METADATA_DIR = BASE_DIR / "metadata"
TEMP_DIR = BASE_DIR / "temp"

CATALOG_FILE = METADATA_DIR / "ea_catalog.json"
MANIFEST_FILE = METADATA_DIR / "download_manifest.json"
SOLVER_JS = BASE_DIR / "solve_acw.js"

for d in [DOWNLOADS_DIR, EXTRACTED_DIR, METADATA_DIR, TEMP_DIR]:
    d.mkdir(parents=True, exist_ok=True)

DEFAULT_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8'
}

SITE_CATEGORIES = {
    'expert-adviso': 234,
    'indicators': 132,
    'other': 94,
    'grid-expert-advisor': 35,
    'martin-expert-advisor': 40,
    'scalper-expert-adviso': 60,
    'trend-expert-advisor': 70
}


class WAFSolver:
    """Solves Aliyun WAF JavaScript challenge using Node.js sandbox."""
    
    @staticmethod
    def solve(html_content: str, temp_suffix: str = "waf") -> str:
        if 'arg1' not in html_content:
            return None
        temp_file = TEMP_DIR / f"temp_{temp_suffix}_{int(time.time()*1000)}.html"
        try:
            with open(temp_file, 'w', encoding='utf-8') as f:
                f.write(html_content)
            proc = subprocess.run(
                ['node', str(SOLVER_JS), str(temp_file)],
                capture_output=True,
                text=True,
                timeout=10
            )
            token = proc.stdout.strip()
            if token and token != 'null' and len(token) > 20:
                return token
        except Exception as e:
            print(f"  [!] WAF solver exception: {e}")
        finally:
            if temp_file.exists():
                try:
                    temp_file.unlink()
                except Exception:
                    pass
        return None


class NotandorCrawler:
    """Main crawler and download manager for Notandor.cn."""
    
    def __init__(self, delay: float = 0.8):
        self.session = requests.Session()
        self.session.verify = False
        from urllib3.util.retry import Retry
        from requests.adapters import HTTPAdapter
        retries = Retry(total=3, backoff_factor=1, status_forcelist=[500, 502, 503, 504], raise_on_status=False)
        adapter = HTTPAdapter(max_retries=retries)
        self.session.mount('http://', adapter)
        self.session.mount('https://', adapter)
        self.session.headers.update(DEFAULT_HEADERS)
        self.delay = delay
        self.catalog = self._load_catalog()
        self.manifest = self._load_manifest()

    def _load_catalog(self) -> dict:
        if CATALOG_FILE.exists():
            try:
                with open(CATALOG_FILE, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception:
                pass
        return {}

    def _save_catalog(self):
        with open(CATALOG_FILE, 'w', encoding='utf-8') as f:
            json.dump(self.catalog, f, ensure_ascii=False, indent=2)

    def _load_manifest(self) -> dict:
        if MANIFEST_FILE.exists():
            try:
                with open(MANIFEST_FILE, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception:
                pass
        return {}

    def _save_manifest(self):
        with open(MANIFEST_FILE, 'w', encoding='utf-8') as f:
            json.dump(self.manifest, f, ensure_ascii=False, indent=2)

    def crawl_category(self, category: str, start_page: int = 1, end_page: int = None):
        """Crawls a specific category pagination on Notandor."""
        max_p = end_page or SITE_CATEGORIES.get(category, 50)
        print(f"\n[*] Starting catalog crawl for category '{category}' (pages {start_page} to {max_p})...")
        initial_count = len(self.catalog)
        
        for p in range(start_page, max_p + 1):
            url = f"https://www.notandor.cn/files/{category}/page/{p}"
            success = False
            for attempt in range(1, 4):
                try:
                    resp = self.session.get(url, timeout=25)
                    if resp.status_code == 404:
                        print(f"  [-] Page {p} returned 404. Reached end of category '{category}'.")
                        return
                    if resp.status_code == 200:
                        articles = re.findall(
                            r'<article[^>]*class=["\'][^"\']*post-(\d+)[^"\']*["\'][^>]*>(.*?)</article>',
                            resp.text,
                            re.S
                        )
                        if not articles:
                            print(f"  [-] Page {p} contains 0 articles. End of category.")
                            return

                        page_new = 0
                        for pid, body in articles:
                            if pid in self.catalog:
                                continue
                            
                            title_m = re.search(r'<h[23][^>]*class=["\']item-title[^"\']*["\'][^>]*><a[^>]*>(.*?)</a>', body, re.S)
                            title = re.sub(r'<[^>]+>', '', title_m.group(1)).strip() if title_m else f"EA_{pid}"
                            
                            cat_m = re.search(r'<a[^>]*href=["\']https?://www\.notandor\.cn/files/([^"\']+)["\'][^>]*>(.*?)</a>', body, re.S)
                            cat = cat_m.group(2).strip() if cat_m else category
                            
                            desc_m = re.search(r'<div[^>]*class=["\']item-desc[^"\']*["\'][^>]*>(.*?)</div>', body, re.S)
                            desc = re.sub(r'<[^>]+>', '', desc_m.group(1)).strip() if desc_m else ""
                            
                            self.catalog[pid] = {
                                "post_id": pid,
                                "title": title,
                                "category": cat,
                                "description": desc,
                                "page_url": f"https://www.notandor.cn/file/{pid}.html",
                                "discovered_at_category": category,
                                "discovered_at_page": p,
                                "created_at": time.strftime("%Y-%m-%d %H:%M:%S")
                            }
                            page_new += 1

                        print(f"  [+] [{category}] Page {p}/{max_p}: found {len(articles)} items (+{page_new} new). Total catalog: {len(self.catalog)}")
                        success = True
                        break
                    else:
                        time.sleep(1.5 * attempt)
                except Exception as e:
                    time.sleep(2 * attempt)

            if not success:
                print(f"  [!] Failed crawling page {p} after 3 attempts.")

            if p % 10 == 0 or p == max_p:
                self._save_catalog()

            time.sleep(self.delay)

        self._save_catalog()
        print(f"[✓] Completed crawl for '{category}'. Added {len(self.catalog) - initial_count} new entries.")

    def crawl_all_categories(self):
        """Systematically crawls every category across the entire website."""
        print(f"\n{'='*60}\n  LAUNCHING FULL SITE CATALOG CRAWL (ALL CATEGORIES)\n{'='*60}")
        for cat, max_p in SITE_CATEGORIES.items():
            self.crawl_category(cat, start_page=1, end_page=max_p)
        print(f"\n[✓] ALL CATEGORIES CRAWLED! Total unique items in catalog: {len(self.catalog)}")

    def _sanitize_filename(self, name: str) -> str:
        clean = re.sub(r'[\\/*?:"<>|]', "_", name).strip()
        clean = re.sub(r'\s+', " ", clean)
        return clean[:120] if len(clean) > 120 else clean

    def _download_via_curl(self, direct_url: str, referer: str, out_path: Path) -> bool:
        """Downloads file bytes using curl with robust connection handling and progress."""
        try:
            cmd = [
                'curl.exe', '-L', '--globoff', '--connect-timeout', '20',
                '--max-time', '180', '--retry', '2',
                '-H', f'Referer: {referer}',
                '-H', f'User-Agent: {DEFAULT_HEADERS["User-Agent"]}',
                direct_url, '-o', str(out_path)
            ]
            proc = subprocess.run(cmd, capture_output=True, timeout=210)
            if proc.returncode == 0 and out_path.exists() and out_path.stat().st_size > 100:
                return True
        except Exception as e:
            print(f"    [!] curl download error: {e}")
        return False

    def _resolve_lanrar_cdn(self, cdn_url: str, referer: str, out_path: Path) -> bool:
        """Resolves Lanrar CDN download link and downloads the raw archive with retry."""
        headers = {
            'User-Agent': DEFAULT_HEADERS['User-Agent'],
            'Referer': referer,
            'Accept-Encoding': 'gzip, deflate'
        }
        for attempt in range(1, 4):
            try:
                resp = self.session.get(cdn_url, headers=headers, timeout=25)
                
                # Check if direct file
                if resp.content.startswith(b'PK\x03\x04') or resp.content.startswith(b'Rar!'):
                    with open(out_path, 'wb') as fp:
                        fp.write(resp.content)
                    return True

                # Check WAF
                html_text = resp.text
                if 'arg1' in html_text:
                    token = WAFSolver.solve(html_text, temp_suffix="cdn")
                    if token:
                        domain = urlparse(cdn_url).netloc
                        self.session.cookies.set('acw_sc__v2', token, domain=domain)
                        resp2 = self.session.get(cdn_url, headers=headers, timeout=25)
                        if resp2.content.startswith(b'PK\x03\x04') or resp2.content.startswith(b'Rar!'):
                            with open(out_path, 'wb') as fp:
                                fp.write(resp2.content)
                            return True
                        html_text = resp2.text

                # Solve ajax.php on CDN
                file_m = re.search(r"['\"]file['\"]\s*:\s*['\"]([^'\"]+)['\"]", html_text)
                sign_m = re.search(r"['\"]sign['\"]\s*:\s*['\"]([^'\"]+)['\"]", html_text)
                if not (file_m and sign_m):
                    print(f"    [!] CDN parameters not found on attempt {attempt}/3")
                    time.sleep(2 * attempt)
                    continue

                host = f"{urlparse(cdn_url).scheme}://{urlparse(cdn_url).netloc}"
                ajax_url = f"{host}/file/ajax.php"
                ajax_headers = {
                    'User-Agent': DEFAULT_HEADERS['User-Agent'],
                    'Referer': cdn_url,
                    'X-Requested-With': 'XMLHttpRequest',
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                }
                ajax_data = {
                    'file': file_m.group(1),
                    'el': 2,
                    'sign': sign_m.group(1)
                }
                res_ajax = self.session.post(ajax_url, data=ajax_data, headers=ajax_headers, timeout=25)
                try:
                    res_json = res_ajax.json()
                except Exception:
                    res_json = {}

                if not res_json.get('url'):
                    print(f"    [!] CDN did not return valid URL on attempt {attempt}/3")
                    time.sleep(2 * attempt)
                    continue

                final_direct_url = res_json['url']
                return self._download_via_curl(final_direct_url, host, out_path)
            except Exception as e:
                print(f"    [!] Lanrar CDN attempt {attempt}/3 failed: {e}")
                time.sleep(2 * attempt)

        return False

    def _download_single_lanzou_file(self, lanzou_url: str, out_path: Path) -> bool:
        """Resolves and downloads a single file from Lanzou Cloud."""
        headers = {
            'User-Agent': DEFAULT_HEADERS['User-Agent'],
            'Referer': 'https://www.notandor.cn/',
            'Accept-Encoding': 'gzip, deflate'
        }
        for attempt in range(1, 4):
            try:
                resp = self.session.get(lanzou_url, headers=headers, timeout=25)
                html_text = resp.text

                # Solve Lanzou WAF challenge if present
                if 'arg1' in html_text:
                    token = WAFSolver.solve(html_text, temp_suffix="lanzou")
                    if token:
                        domain = urlparse(lanzou_url).netloc
                        self.session.cookies.set('acw_sc__v2', token, domain=domain)
                        resp = self.session.get(lanzou_url, headers=headers, timeout=25)
                        html_text = resp.text

                # Extract iframe
                iframe_m = re.search(r'<iframe[^>]+src=["\']([^"\']+)["\']', html_text)
                if not iframe_m:
                    return False
                    
                iframe_rel = iframe_m.group(1)
                base_host = f"{urlparse(lanzou_url).scheme}://{urlparse(lanzou_url).netloc}"
                iframe_url = urljoin(base_host, iframe_rel)

                resp_if = self.session.get(iframe_url, headers=headers, timeout=25)
                html_if = resp_if.text

                # Extract download API parameters
                dom_ajaxs_m = re.search(r"var\s+dom_ajaxs\s*=\s*['\"]([^'\"]+)['\"]", html_if)
                wp_sign_m = re.search(r"var\s+wp_sign\s*=\s*['\"]([^'\"]+)['\"]", html_if)
                ajaxdata_m = re.search(r"var\s+ajaxdata\s*=\s*['\"]([^'\"]+)['\"]", html_if)
                
                # Alternate patterns in Lanzou scripts
                if not wp_sign_m:
                    wp_sign_m = re.search(r"['\"]sign['\"]\s*:\s*['\"]([^'\"]+)['\"]", html_if)
                if not ajaxdata_m:
                    ajaxdata_m = re.search(r"['\"]websignkey['\"]\s*:\s*['\"]([^'\"]+)['\"]", html_if)
                if not dom_ajaxs_m:
                    domain2_m = re.search(r"var\s+domain2\s*=\s*['\"]([^'\"]+)['\"]", html_if)
                    if domain2_m:
                        dom_ajaxs_m = domain2_m
                    else:
                        dom_ajaxs_m = re.search(r"url\s*:\s*['\"]([^'\"]*ajaxfile\.php[^'\"]*)['\"]", html_if)

                if not (dom_ajaxs_m and wp_sign_m and ajaxdata_m):
                    time.sleep(2 * attempt)
                    continue

                api_url = dom_ajaxs_m.group(1)
                if api_url.startswith('/'):
                    api_url = urljoin(base_host, api_url)
                elif not api_url.startswith('http'):
                    api_url = 'https://apifile.lanzouw.com/' + api_url

                sign_val = wp_sign_m.group(1)
                key_val = ajaxdata_m.group(1)

                post_data = {
                    'action': 'downprocess',
                    'websignkey': key_val,
                    'signs': key_val,
                    'sign': sign_val,
                    'websign': '2',
                    'kd': 0,
                    'ves': 1
                }
                ajax_headers = {
                    'User-Agent': DEFAULT_HEADERS['User-Agent'],
                    'Referer': iframe_url,
                    'X-Requested-With': 'XMLHttpRequest',
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                }
                res_api = self.session.post(api_url, data=post_data, headers=ajax_headers, timeout=25)
                res_json = res_api.json()
                if res_json.get('zt') != 1:
                    time.sleep(2 * attempt)
                    continue

                dom = res_json['dom']
                url_part = res_json['url']
                cdn_url = f"{dom}/file/{url_part}"

                return self._resolve_lanrar_cdn(cdn_url, iframe_url, out_path)
            except Exception as e:
                print(f"    [!] Error in single file attempt {attempt}/3: {e}")
                time.sleep(2 * attempt)
        return False

    def _download_lanzou_folder(self, folder_url: str, password: str, post_id: str, base_title: str) -> list:
        """Resolves and downloads all subfiles from a Lanzou folder."""
        downloaded_files = []
        headers = {
            'User-Agent': DEFAULT_HEADERS['User-Agent'],
            'Referer': 'https://www.notandor.cn/',
            'Accept-Encoding': 'gzip, deflate'
        }
        
        html_text = ""
        for attempt in range(1, 4):
            try:
                resp = self.session.get(folder_url, headers=headers, timeout=25)
                html_text = resp.text
                if 'arg1' in html_text:
                    token = WAFSolver.solve(html_text, temp_suffix="folder")
                    if token:
                        domain = urlparse(folder_url).netloc
                        self.session.cookies.set('acw_sc__v2', token, domain=domain)
                        resp = self.session.get(folder_url, headers=headers, timeout=25)
                        html_text = resp.text
                if html_text:
                    break
            except Exception as e:
                print(f"    [!] Folder page fetch attempt {attempt}/3 error: {e}")
                time.sleep(2 * attempt)

        if not html_text:
            return downloaded_files

        # Extract filemoreajax.php parameters dynamically
        t_m = re.search(r"var\s+[a-zA-Z0-9_]+\s*=\s*['\"](\d{10})['\"]", html_text)
        k_m = re.search(r"var\s+[a-zA-Z0-9_]+\s*=\s*['\"]([a-f0-9]{32})['\"]", html_text)
        fid_m = re.search(r"['\"]fid['\"]\s*:\s*['\"]?(\d+)['\"]?", html_text)
        uid_m = re.search(r"['\"]uid['\"]\s*:\s*['\"]?(\d+)['\"]?", html_text)
        puid_m = re.search(r"['\"]puid['\"]\s*:\s*['\"]([^'\"]+)['\"]", html_text)

        t_val = t_m.group(1) if t_m else ""
        k_val = k_m.group(1) if k_m else ""
        fid_val = fid_m.group(1) if fid_m else ""
        uid_val = uid_m.group(1) if uid_m else ""
        puid_val = puid_m.group(1) if puid_m else ""

        if not (fid_val and uid_val and puid_val and t_val and k_val):
            print(f"    [!] Could not parse folder parameters from {folder_url}")
            return downloaded_files

        base_host = f"{urlparse(folder_url).scheme}://{urlparse(folder_url).netloc}"
        folder_api = f"{base_host}/filemoreajax.php?file={fid_val}"

        folder_headers = {
            'User-Agent': DEFAULT_HEADERS['User-Agent'],
            'Referer': folder_url,
            'X-Requested-With': 'XMLHttpRequest',
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
        }

        pg = 1
        while True:
            post_data = {
                'lx': 2,
                'fid': fid_val,
                'uid': uid_val,
                'puid': puid_val,
                'pg': pg,
                'rep': '0',
                't': t_val,
                'k': k_val,
                'up': 1,
                'ls': 1,
                'pwd': password or ''
            }
            res_json = None
            for attempt in range(1, 4):
                try:
                    res_folder = self.session.post(folder_api, data=post_data, headers=folder_headers, timeout=25)
                    res_json = res_folder.json()
                    break
                except Exception as e:
                    print(f"    [!] Folder page {pg} request attempt {attempt}/3 error: {e}")
                    time.sleep(2 * attempt)

            if not res_json or res_json.get('zt') != 1:
                break

            items = res_json.get('text', [])
            if not items:
                break

            print(f"    [+] Folder page {pg}: {len(items)} files listed.")
            for it in items:
                sub_id = it.get('id')
                sub_name = it.get('name_all', f"file_{sub_id}")
                clean_sub_name = self._sanitize_filename(sub_name)
                if not clean_sub_name.endswith('.zip') and not clean_sub_name.endswith('.rar'):
                    clean_sub_name += ".zip"
                sub_file_path = DOWNLOADS_DIR / f"{post_id}_{clean_sub_name}"

                if sub_file_path.exists() and sub_file_path.stat().st_size > 100:
                    print(f"      [~] Subfile already downloaded: {clean_sub_name}")
                    downloaded_files.append(str(sub_file_path))
                    continue

                sub_lanzou_url = f"{base_host}/{sub_id}"
                print(f"      [↓] Downloading subfile: {clean_sub_name} ({it.get('size')})")
                try:
                    ok = self._download_single_lanzou_file(sub_lanzou_url, sub_file_path)
                    if ok:
                        downloaded_files.append(str(sub_file_path))
                        print(f"      [✓] Downloaded: {clean_sub_name}")
                    else:
                        print(f"      [✗] Failed to resolve subfile: {clean_sub_name}")
                except Exception as e:
                    print(f"      [!] Error downloading subfile: {e}")
                time.sleep(self.delay)

            pg += 1
            if len(items) < 10:
                break

        return downloaded_files

    def download_post(self, post_id: str) -> dict:
        """Resolves download links for a post with resilient retry logic."""
        entry = self.catalog.get(post_id, {})
        title = entry.get('title', f"EA_{post_id}")
        clean_title = self._sanitize_filename(title)

        result = {
            "post_id": post_id,
            "title": title,
            "status": "PENDING",
            "files": [],
            "total_bytes": 0,
            "updated_at": time.strftime("%Y-%m-%d %H:%M:%S")
        }

        print(f"\n[>] Processing Post {post_id}: {title}")
        try:
            # Step 1: Request modal from admin-ajax.php with automatic retry
            ajax_url = "https://www.notandor.cn/wp-admin/admin-ajax.php"
            ajax_data = {
                'action': 'get_app_down_btn',
                'post_id': post_id,
                'id': '1'
            }
            ajax_headers = {
                'X-Requested-With': 'XMLHttpRequest',
                'Referer': f"https://www.notandor.cn/file/{post_id}.html"
            }
            
            modal_html = None
            for attempt in range(1, 4):
                try:
                    resp_modal = self.session.post(ajax_url, data=ajax_data, headers=ajax_headers, timeout=35)
                    if resp_modal.status_code == 200:
                        modal_html = resp_modal.text
                        break
                    else:
                        time.sleep(2 * attempt)
                except Exception as e:
                    if attempt == 3:
                        result["status"] = "ERROR_MODAL_EXCEPTION"
                        result["error"] = str(e)
                        print(f"  [!] Modal error after 3 attempts: {e}")
                        return result
                    time.sleep(2 * attempt)

            if not modal_html:
                result["status"] = "ERROR_MODAL_EMPTY"
                return result

            # Step 2: Extract download.php links and password
            links = re.findall(
                r'<a[^>]+href=["\']([^"\']+/download\.php\?[^"\']+)["\'][^>]*>(.*?)</a>',
                modal_html,
                re.I | re.S
            )
            if not links:
                result["status"] = "NO_DOWNLOAD_LINKS"
                print("  [-] No download links found in modal.")
                return result

            chosen_link = None
            for href, text in links:
                t_clean = re.sub(r'<[^>]+>', '', text).strip().lower()
                if 'tg' not in t_clean and 'telegram' not in t_clean:
                    chosen_link = html.unescape(href)
                    break
            if not chosen_link:
                chosen_link = html.unescape(links[0][0])

            pwd_m = re.search(r'data-clipboard-text=["\']([^"\']*)["\']', modal_html)
            password = pwd_m.group(1).strip() if pwd_m else ""
            if not password:
                col_pwd = re.findall(r'<div[^>]*class=["\']col-2[^"\']*["\'][^>]*>(.*?)</div>', modal_html, re.S)
                for c in col_pwd:
                    c_clean = re.sub(r'<[^>]+>', '', c).strip()
                    if c_clean and c_clean not in ["提取码", "无"]:
                        password = c_clean
                        break

            print(f"  [+] Extracted download link: {chosen_link}")
            if password:
                print(f"  [+] Extraction password: '{password}'")

            # Step 3: Follow 302 redirect from download.php with retry
            lanzou_target = None
            for attempt in range(1, 4):
                try:
                    resp_redir = self.session.get(
                        chosen_link,
                        headers={'Referer': f"https://www.notandor.cn/file/{post_id}.html"},
                        allow_redirects=False,
                        timeout=25
                    )
                    lanzou_target = resp_redir.headers.get('Location')
                    if not lanzou_target and resp_redir.status_code == 200:
                        meta_redir = re.search(r'url=([^"\'>\s]+)', resp_redir.text, re.I)
                        if meta_redir:
                            lanzou_target = meta_redir.group(1)
                    if lanzou_target:
                        break
                except Exception as e:
                    time.sleep(2 * attempt)

            if not lanzou_target:
                result["status"] = "NO_LANZOU_TARGET"
                print("  [-] No Lanzou redirect target found.")
                return result

            print(f"  [+] Resolved Lanzou Target: {lanzou_target}")

            # Step 4: Check if Folder or Single File
            is_folder = bool(re.search(r'/[bB]0?[a-zA-Z0-9]{6,}', lanzou_target))

            if is_folder:
                print("  [*] Identified as Lanzou BATCH FOLDER.")
                downloaded = self._download_lanzou_folder(lanzou_target, password, post_id, clean_title)
                result["files"] = downloaded
                result["total_bytes"] = sum(Path(f).stat().st_size for f in downloaded if Path(f).exists())
                result["status"] = "SUCCESS" if downloaded else "EMPTY_FOLDER"
            else:
                print("  [*] Identified as Lanzou SINGLE FILE.")
                out_file = DOWNLOADS_DIR / f"{post_id}_{clean_title}.zip"
                if out_file.exists() and out_file.stat().st_size > 100:
                    print(f"  [~] Already downloaded: {out_file.name}")
                    result["files"] = [str(out_file)]
                    result["total_bytes"] = out_file.stat().st_size
                    result["status"] = "SUCCESS"
                else:
                    ok = self._download_single_lanzou_file(lanzou_target, out_file)
                    if ok and out_file.exists() and out_file.stat().st_size > 100:
                        print(f"  [✓] Successfully downloaded: {out_file.name} ({out_file.stat().st_size} bytes)")
                        result["files"] = [str(out_file)]
                        result["total_bytes"] = out_file.stat().st_size
                        result["status"] = "SUCCESS"
                    else:
                        result["status"] = "ERROR_DOWNLOAD"
                        print(f"  [✗] Failed downloading: {clean_title}")

            return result
        except Exception as e:
            result["status"] = "ERROR_EXCEPTION"
            result["error"] = str(e)
            print(f"  [!] Exception during post {post_id}: {e}")
            return result

    def download_all(self, limit: int = None, auto_extract: bool = True):
        """Downloads EAs across the catalog with continuous mirroring and automatic extraction."""
        if not self.catalog:
            print("[-] Catalog is empty. Please run with --catalog first.")
            return

        post_ids = list(self.catalog.keys())
        total = len(post_ids)
        if limit:
            post_ids = post_ids[:limit]
            print(f"\n[*] Starting download of {len(post_ids)} items (limited from {total})...")
        else:
            print(f"\n[*] Starting continuous download of all {total} catalog items...")

        success_count = 0
        error_count = 0
        skipped_count = 0

        for idx, pid in enumerate(post_ids, 1):
            if pid in self.manifest and self.manifest[pid].get("status") == "SUCCESS":
                files = self.manifest[pid].get("files", [])
                if any(Path(f).exists() for f in files):
                    skipped_count += 1
                    continue

            print(f"\n[{idx}/{len(post_ids)}] (Progress: {idx/len(post_ids)*100:.1f}%)")
            try:
                res = self.download_post(pid)
            except Exception as e:
                print(f"  [!] Fatal loop exception downloading post {pid}: {e}")
                res = {"post_id": pid, "status": "ERROR_EXCEPTION", "error": str(e), "files": [], "total_bytes": 0}

            self.manifest[pid] = res
            self._save_manifest()

            if res.get("status") == "SUCCESS":
                success_count += 1
            else:
                error_count += 1

            # Auto-extract every 10 posts
            if auto_extract and success_count > 0 and success_count % 10 == 0:
                try:
                    self.extract_and_catalog_files()
                except Exception as ex:
                    print(f"  [!] Auto-extract error: {ex}")

            time.sleep(self.delay)

        if auto_extract:
            try:
                self.extract_and_catalog_files()
            except Exception as ex:
                print(f"  [!] Final auto-extract error: {ex}")

        print("\n" + "="*50)
        print(f"[✓] Download run completed!")
        print(f"    Success: {success_count}")
        print(f"    Skipped (already backed up): {skipped_count}")
        print(f"    Errors: {error_count}")
        print("="*50)

    def extract_and_catalog_files(self):
        """Unpacks all downloaded zip/rar files and organizes .mq4, .ex4, .mq5, .ex5, .set."""
        extracted_index = {
            "mq4": [],
            "ex4": [],
            "mq5": [],
            "ex5": [],
            "set": [],
            "other": []
        }

        # 1. Extract ZIP archives
        zip_files = list(DOWNLOADS_DIR.glob("*.zip"))
        for zpath in zip_files:
            try:
                if not zipfile.is_zipfile(zpath):
                    continue
                with zipfile.ZipFile(zpath, 'r') as zf:
                    for info in zf.infolist():
                        if info.is_dir():
                            continue
                        fname = os.path.basename(info.filename)
                        if not fname:
                            continue
                        
                        ext = os.path.splitext(fname)[1].lower().replace('.', '')
                        target_dir = EXTRACTED_DIR / ext if ext in ["mq4", "ex4", "mq5", "ex5", "set"] else EXTRACTED_DIR / "other"
                        target_dir.mkdir(parents=True, exist_ok=True)
                        
                        target_file = target_dir / fname
                        if not target_file.exists():
                            with zf.open(info) as src, open(target_file, 'wb') as dst:
                                shutil.copyfileobj(src, dst)
            except Exception:
                pass

        # 2. Extract RAR archives using Windows tar.exe
        rar_files = list(DOWNLOADS_DIR.glob("*.rar"))
        rar_temp = TEMP_DIR / "rar_extract"
        for rpath in rar_files:
            try:
                rar_temp.mkdir(parents=True, exist_ok=True)
                subprocess.run(['tar', '-xf', str(rpath), '-C', str(rar_temp)], capture_output=True, timeout=30)
                for fpath in rar_temp.rglob('*'):
                    if fpath.is_file():
                        fname = fpath.name
                        ext = fpath.suffix.lower().replace('.', '')
                        target_dir = EXTRACTED_DIR / ext if ext in ["mq4", "ex4", "mq5", "ex5", "set"] else EXTRACTED_DIR / "other"
                        target_dir.mkdir(parents=True, exist_ok=True)
                        target_file = target_dir / fname
                        if not target_file.exists():
                            shutil.copy2(fpath, target_file)
                shutil.rmtree(rar_temp, ignore_errors=True)
            except Exception:
                pass

        # Build master index
        for cat in ["mq4", "ex4", "mq5", "ex5", "set", "other"]:
            cat_dir = EXTRACTED_DIR / cat
            if cat_dir.exists():
                extracted_index[cat] = [f.name for f in cat_dir.glob('*.*')]

        with open(METADATA_DIR / "extracted_index.json", 'w', encoding='utf-8') as f:
            json.dump(extracted_index, f, ensure_ascii=False, indent=2)

    def print_status(self):
        """Displays status report of catalog, downloads, and extracted files."""
        total_catalog = len(self.catalog)
        total_manifest = len(self.manifest)
        success_manifest = sum(1 for m in self.manifest.values() if m.get("status") == "SUCCESS")
        
        dl_files = list(DOWNLOADS_DIR.glob("*.*"))
        total_dl_bytes = sum(f.stat().st_size for f in dl_files)
        
        mq4_count = len(list((EXTRACTED_DIR / "mq4").glob("*.mq4"))) if (EXTRACTED_DIR / "mq4").exists() else 0
        ex4_count = len(list((EXTRACTED_DIR / "ex4").glob("*.ex4"))) if (EXTRACTED_DIR / "ex4").exists() else 0
        mq5_count = len(list((EXTRACTED_DIR / "mq5").glob("*.mq5"))) if (EXTRACTED_DIR / "mq5").exists() else 0
        ex5_count = len(list((EXTRACTED_DIR / "ex5").glob("*.ex5"))) if (EXTRACTED_DIR / "ex5").exists() else 0
        set_count = len(list((EXTRACTED_DIR / "set").glob("*.set"))) if (EXTRACTED_DIR / "set").exists() else 0

        print("\n" + "="*60)
        print("          NOTANDOR.CN BACKUP REPOSITORY STATUS          ")
        print("="*60)
        print(f"  Total Catalog Posts Indexed:      {total_catalog}")
        print(f"  Posts Processed in Manifest:      {total_manifest}")
        print(f"  Successfully Backed Up Posts:     {success_manifest}")
        print(f"  Downloaded Archive Files:         {len(dl_files)} ({total_dl_bytes / (1024*1024):.2f} MB)")
        print(f"  Total Extracted Trading Assets:   {mq4_count + ex4_count + mq5_count + ex5_count + set_count}")
        print(f"    - MQL4 Source Codes (.mq4):     {mq4_count}")
        print(f"    - MT4 Compiled EAs (.ex4):      {ex4_count}")
        print(f"    - MQL5 Source Codes (.mq5):     {mq5_count}")
        print(f"    - MT5 Compiled EAs (.ex5):      {ex5_count}")
        print(f"    - Strategy Presets (.set):      {set_count}")
        print("="*60 + "\n")


def main():
    parser = argparse.ArgumentParser(description="Notandor.cn EA Backup Engine")
    parser.add_argument("--catalog", action="store_true", help="Crawl and build complete catalog index")
    parser.add_argument("--all-categories", action="store_true", help="Crawl all site categories (EAs, indicators, other)")
    parser.add_argument("--category", type=str, default="expert-adviso", help="Specific category to crawl")
    parser.add_argument("--pages", type=int, default=None, help="Maximum pages to crawl for category")
    parser.add_argument("--start-page", type=int, default=1, help="Start page for catalog crawl")
    parser.add_argument("--download", action="store_true", help="Download EAs in catalog")
    parser.add_argument("--limit", type=int, default=None, help="Limit number of posts to download")
    parser.add_argument("--continuous", action="store_true", help="Keep running continuously with auto-reconnect on network outages")
    parser.add_argument("--extract", action="store_true", help="Extract and organize downloaded archives")
    parser.add_argument("--status", action="store_true", help="Show backup status and statistics")
    args = parser.parse_args()

    crawler = NotandorCrawler()

    if args.status:
        crawler.print_status()
        return

    if args.catalog:
        if args.all_categories:
            crawler.crawl_all_categories()
        else:
            crawler.crawl_category(category=args.category, start_page=args.start_page, end_page=args.pages)

    if args.download:
        if args.continuous:
            print("[*] Continuous Daemon Mode active: will retry and resume automatically.")
            while True:
                try:
                    crawler.download_all(limit=args.limit)
                    all_done = all(
                        pid in crawler.manifest and crawler.manifest[pid].get("status") == "SUCCESS"
                        for pid in list(crawler.catalog.keys())[:args.limit]
                    )
                    if all_done:
                        print("[✓] All target posts successfully downloaded!")
                        break
                    print("[*] Cycle complete, pausing 10 seconds before next pass...")
                    time.sleep(10)
                except KeyboardInterrupt:
                    print("\n[!] Daemon stopped by user.")
                    break
                except Exception as e:
                    print(f"[!] Daemon cycle encountered error: {e}. Reconnecting in 15s...")
                    time.sleep(15)
        else:
            crawler.download_all(limit=args.limit)

    if args.extract:
        crawler.extract_and_catalog_files()

    if not any([args.catalog, args.download, args.extract, args.status]):
        parser.print_help()


if __name__ == "__main__":
    main()
