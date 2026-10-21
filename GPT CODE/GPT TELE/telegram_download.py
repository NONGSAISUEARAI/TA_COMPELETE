"""Download videos from Telegram chats accessible to your account."""

import argparse
import asyncio
import getpass
import os
from pathlib import Path
import re
import sys
import time
from urllib.parse import urlparse


def message_link(value):
    parsed = urlparse(value)
    if parsed.scheme != "https" or parsed.netloc.lower() != "t.me":
        raise ValueError("Use an https://t.me/... message link.")
    parts = parsed.path.strip("/").split("/")
    if parts[0] == "c" and len(parts) in (3, 4):
        if not all(p.isdigit() and int(p) > 0 for p in parts[1:]):
            raise ValueError("Invalid private message link.")
        return int("-100" + parts[1]), int(parts[-1])
    if len(parts) in (2, 3) and re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", parts[0]):
        if all(p.isdigit() and int(p) > 0 for p in parts[1:]):
            return parts[0], int(parts[-1])
    raise ValueError("Expected a message link, for example https://t.me/c/123456/789")


def safe_name(value):
    name = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", value).strip(" .")
    return (name[:160].rstrip(" .") or "video.mp4")


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    source = result.add_mutually_exclusive_group(required=True)
    source.add_argument("--list-chats", action="store_true", help="Show chat names and IDs")
    source.add_argument("--chat", help="Chat ID, @username, or me (Saved Messages)")
    source.add_argument("--link", help="HTTPS Telegram message link")
    result.add_argument("--message-id", type=int, help="Download one message from --chat")
    result.add_argument("--limit", type=int, help="Scan this many recent messages; default: all")
    result.add_argument("--output", type=Path, default=Path("downloads"))
    result.add_argument("--session", type=Path, default=Path(".sessions/account"))
    return result


async def run(args):
    from telethon import TelegramClient, errors, utils

    api_id = os.environ.get("TELEGRAM_API_ID") or input("Telegram API ID: ").strip()
    api_hash = os.environ.get("TELEGRAM_API_HASH") or getpass.getpass("Telegram API hash: ")
    if not api_id.isdigit() or int(api_id) <= 0 or not api_hash.strip():
        raise ValueError("A positive API ID and API hash are required (my.telegram.org).")

    args.session.parent.mkdir(parents=True, exist_ok=True)
    async with TelegramClient(str(args.session), int(api_id), api_hash.strip()) as client:
        if args.list_chats:
            async for dialog in client.iter_dialogs():
                print(f"{dialog.id}\t{dialog.name}")
            return 0

        if args.link:
            target, selected_id = message_link(args.link)
        else:
            target = int(args.chat) if re.fullmatch(r"-?\d+", args.chat) else args.chat
            selected_id = args.message_id

        # Enumerating dialogs caches access hashes needed for private channel IDs.
        if isinstance(target, int):
            async for dialog in client.iter_dialogs():
                if dialog.id == target:
                    break
        entity = await client.get_entity(target)
        destination = args.output / str(utils.get_peer_id(entity))
        destination.mkdir(parents=True, exist_ok=True)
        messages = client.iter_messages(entity, ids=[selected_id]) if selected_id else client.iter_messages(entity, limit=args.limit)
        downloaded = skipped = failed = 0
        async for message in messages:
            if message is None:
                print("Message not found or inaccessible.", file=sys.stderr)
                failed += 1
                continue
            document = message.document
            if not (message.video or (document and (document.mime_type or "").startswith("video/"))):
                if selected_id:
                    print("The selected message does not contain a downloadable video.", file=sys.stderr)
                    failed += 1
                continue

            original = message.file.name or f"video{message.file.ext or '.mp4'}"
            final = destination / f"{message.id}_{safe_name(original)}"
            size = message.file.size
            if final.is_file() and size is not None and final.stat().st_size == size:
                print(f"Already downloaded: {final.name}")
                skipped += 1
                continue
            # Exclusive creation prevents two runs from overwriting each other's data.
            partial = final.with_name(final.name + ".part")
            last_update = 0.0

            def progress(current, total):
                nonlocal last_update
                now = time.monotonic()
                if now - last_update >= 1 or current == total:
                    print(f"\r{final.name}: {current / 1048576:.1f} / {(total or 0) / 1048576:.1f} MiB", end="", flush=True)
                    last_update = now

            try:
                with partial.open("xb") as stream:
                    print(f"Downloading: {final.name}")
                    result = await client.download_media(message, file=stream, progress_callback=progress)
                    if result is None:
                        raise OSError("Telegram returned no media.")
                print()
                if size is not None and partial.stat().st_size != size:
                    raise OSError("Incomplete download; remove the .part file before retrying.")
                partial.replace(final)
                downloaded += 1
            except FileExistsError:
                print(f"Partial file already exists: {partial}. Remove it to restart this video.", file=sys.stderr)
                failed += 1
            except (errors.RPCError, OSError) as exc:
                print(f"\nFailed message {message.id}: {exc}", file=sys.stderr)
                failed += 1
        print(f"Completed: {downloaded} downloaded, {skipped} skipped, {failed} failed.")
        return 1 if failed else 0


def main():
    cli = parser()
    args = cli.parse_args()
    if args.message_id is not None and (not args.chat or args.message_id <= 0):
        cli.error("--message-id requires --chat and a positive message ID")
    if args.limit is not None and args.limit <= 0:
        cli.error("--limit must be positive")
    if args.link:
        try:
            message_link(args.link)
        except ValueError as exc:
            cli.error(str(exc))
    try:
        return asyncio.run(run(args))
    except ImportError:
        print("Install dependencies: python -m pip install -r requirements.txt", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\nCancelled. Remove incomplete .part files before restarting.", file=sys.stderr)
        return 130
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
