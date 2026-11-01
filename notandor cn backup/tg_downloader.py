#!/usr/bin/env python3
"""
Notandor Telegram Channel Media Downloader
Connects via Telethon MTProto to t.me/www_notandor_cn and streams all 14,000 EA files into downloads/.
"""

import sys
sys.stdout.reconfigure(encoding='utf-8')
import os
import argparse
import asyncio
from pathlib import Path
from telethon import TelegramClient
from telethon.tl.types import DocumentAttributeFilename

BASE_DIR = Path(__file__).resolve().parent
DOWNLOADS_DIR = BASE_DIR / "downloads"
METADATA_DIR = BASE_DIR / "metadata"
DOWNLOADS_DIR.mkdir(parents=True, exist_ok=True)
METADATA_DIR.mkdir(parents=True, exist_ok=True)

# Default public developer API credentials (or user-supplied)
DEFAULT_API_ID = 2040
DEFAULT_API_HASH = "b18441a1ff607e10a989891a5462e627"
CHANNEL_USERNAME = "www_notandor_cn"


async def download_channel_files(api_id, api_hash, session_name="notandor_tg_session", limit=None):
    client = TelegramClient(str(BASE_DIR / session_name), int(api_id), str(api_hash))
    await client.start()
    
    me = await client.get_me()
    print(f"\n[✓] Successfully connected to Telegram as: {me.first_name} (@{me.username or me.phone})")
    
    channel = await client.get_entity(CHANNEL_USERNAME)
    print(f"[*] Accessing channel: {channel.title} (@{channel.username})")
    print(f"[*] Destination directory: {DOWNLOADS_DIR}\n")
    
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
        print(f"[↓] [{message.id}] Downloading: {file_name} ({file_size_kb:.1f} KB)...")
        try:
            await message.download_media(file=str(out_path))
            downloaded_count += 1
            print(f"  [✓] Saved: {out_path.name}")
        except Exception as e:
            print(f"  [!] Failed downloading {file_name}: {e}")
            error_count += 1
            
    print("\n" + "="*50)
    print("[✓] Telegram Download Session Completed!")
    print(f"    Downloaded: {downloaded_count}")
    print(f"    Skipped: {skipped_count}")
    print(f"    Errors: {error_count}")
    print("="*50)


def main():
    parser = argparse.ArgumentParser(description="Notandor Telegram Channel Downloader")
    parser.add_argument("--api-id", type=int, default=int(os.getenv("TG_API_ID", DEFAULT_API_ID)), help="Telegram API ID")
    parser.add_argument("--api-hash", type=str, default=os.getenv("TG_API_HASH", DEFAULT_API_HASH), help="Telegram API Hash")
    parser.add_argument("--limit", type=int, default=None, help="Limit number of messages to process")
    args = parser.parse_args()
    
    asyncio.run(download_channel_files(args.api_id, args.api_hash, limit=args.limit))


if __name__ == '__main__':
    main()
