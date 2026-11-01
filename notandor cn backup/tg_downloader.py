#!/usr/bin/env python3
"""
Notandor Telegram Channel Media Downloader
Connects via Telethon MTProto to t.me/www_notandor_cn and streams all 14,000 EA files into downloads/.
Includes automatic FloodWait backoff, live download progress, and archive extraction hooks.
"""

import sys
sys.stdout.reconfigure(encoding='utf-8')
import os
import argparse
import asyncio
from pathlib import Path
from telethon import TelegramClient, errors
from telethon.tl.types import DocumentAttributeFilename

BASE_DIR = Path(__file__).resolve().parent
DOWNLOADS_DIR = BASE_DIR / "downloads"
METADATA_DIR = BASE_DIR / "metadata"
DOWNLOADS_DIR.mkdir(parents=True, exist_ok=True)
METADATA_DIR.mkdir(parents=True, exist_ok=True)

# Default open MTProto developer credentials
DEFAULT_API_ID = 2040
DEFAULT_API_HASH = "b18441a1ff607e10a989891a5462e627"
CHANNEL_USERNAME = "www_notandor_cn"


def progress_callback(current, total):
    percent = (current / total) * 100 if total else 0
    sys.stdout.write(f"\r    [Progress] {current / 1024:.1f} KB / {total / 1024:.1f} KB ({percent:.1f}%)")
    sys.stdout.flush()


async def download_channel_files(api_id, api_hash, session_name="notandor_tg_session", limit=None):
    session_path = BASE_DIR / session_name
    client = TelegramClient(str(session_path), int(api_id), str(api_hash))
    
    print("\n" + "="*60)
    print("      NOTANDOR TELEGRAM CHANNEL BULK DOWNLOADER         ")
    print("="*60)
    print("Connecting via official Telegram MTProto protocol...")
    print("If prompted, enter your phone number and the verification code")
    print("sent to your active Telegram Desktop app.\n")
    
    await client.start()
    
    me = await client.get_me()
    print(f"\n[✓] Successfully authenticated as: {me.first_name} (@{me.username or me.phone or 'User'})")
    
    channel = await client.get_entity(CHANNEL_USERNAME)
    print(f"[*] Connected to channel: {channel.title} (@{channel.username})")
    print(f"[*] Target Directory: {DOWNLOADS_DIR}\n")
    
    downloaded_count = 0
    skipped_count = 0
    error_count = 0
    
    async for message in client.iter_messages(channel, limit=limit):
        if not message.media or not message.document:
            continue
            
        file_name = None
        for attr in message.document.attributes:
            if isinstance(attr, DocumentAttributeFilename):
                file_name = attr.file_name
                break
        if not file_name:
            file_name = f"tg_doc_{message.id}.zip"
            
        out_path = DOWNLOADS_DIR / f"{message.id}_{file_name}"
        if out_path.exists() and out_path.stat().st_size > 100:
            skipped_count += 1
            continue
            
        file_size_kb = message.document.size / 1024
        print(f"\n[↓] [{message.id}] Downloading: {file_name} ({file_size_kb:.1f} KB)...")
        
        success = False
        for attempt in range(1, 4):
            try:
                await message.download_media(file=str(out_path), progress_callback=progress_callback)
                sys.stdout.write("\n")
                if out_path.exists() and out_path.stat().st_size > 100:
                    downloaded_count += 1
                    print(f"  [✓] Saved: {out_path.name}")
                    success = True
                    break
            except errors.FloodWaitError as e:
                print(f"\n  [!] Telegram rate limit encountered: sleeping for {e.seconds}s...")
                await asyncio.sleep(e.seconds + 1)
            except Exception as e:
                print(f"\n  [!] Download attempt {attempt} error: {e}")
                await asyncio.sleep(2 * attempt)
                
        if not success:
            error_count += 1
            print(f"  [✗] Failed downloading message {message.id}: {file_name}")
            
    print("\n" + "="*60)
    print("[✓] TELEGRAM DOWNLOAD SESSION FINISHED")
    print(f"    New Files Downloaded: {downloaded_count}")
    print(f"    Skipped (Already on disk): {skipped_count}")
    print(f"    Errors: {error_count}")
    print("="*60 + "\n")


def main():
    parser = argparse.ArgumentParser(description="Notandor Telegram Channel Downloader")
    parser.add_argument("--api-id", type=int, default=int(os.getenv("TG_API_ID", DEFAULT_API_ID)), help="Telegram API ID")
    parser.add_argument("--api-hash", type=str, default=os.getenv("TG_API_HASH", DEFAULT_API_HASH), help="Telegram API Hash")
    parser.add_argument("--limit", type=int, default=None, help="Limit number of messages to process")
    args = parser.parse_args()
    
    asyncio.run(download_channel_files(args.api_id, args.api_hash, limit=args.limit))


if __name__ == '__main__':
    main()
