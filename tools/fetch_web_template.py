"""Fetch only the Godot 4.7.2 Web release template from the official TPZ.

The official export-template archive is about 1.3 GB. This script reads its ZIP
central directory, downloads one Web template through concurrent HTTP range
requests, verifies the resulting ZIP and installs it into the local Godot
export-templates directory.
"""

from __future__ import annotations

import concurrent.futures
import os
from pathlib import Path
import struct
import tempfile
import time
import urllib.error
import urllib.request
import zipfile
import zlib


VERSION = "4.7.2"
TPZ_URL = (
    "https://github.com/godotengine/godot/releases/download/"
    "4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
)
ENTRY_NAME = "templates/web_nothreads_release.zip"
CHUNK_SIZE = 256 * 1024
MAX_WORKERS = 8


def fetch_range(start: int, end: int) -> bytes:
    expected_size = end - start + 1
    last_error: Exception | None = None
    for attempt in range(4):
        request = urllib.request.Request(
            TPZ_URL,
            headers={"Range": f"bytes={start}-{end}"},
        )
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                status = getattr(response, "status", response.getcode())
                if status != 206:
                    raise RuntimeError(
                        f"Expected HTTP 206 for range request, got {status}."
                    )
                payload = response.read()
            if len(payload) != expected_size:
                raise RuntimeError(
                    f"Range {start}-{end} returned {len(payload)} bytes, "
                    f"expected {expected_size}."
                )
            return payload
        except (TimeoutError, urllib.error.URLError) as error:
            last_error = error
            if attempt < 3:
                time.sleep(1 + attempt * 2)
    raise RuntimeError(
        f"Range {start}-{end} failed after four attempts: {last_error}"
    )


def get_total_size() -> int:
    request = urllib.request.Request(TPZ_URL, method="HEAD")
    with urllib.request.urlopen(request, timeout=60) as response:
        length = response.headers.get("Content-Length")
    if length is None:
        raise RuntimeError("Template server did not return Content-Length.")
    return int(length)


def find_central_directory(
    tail: bytes,
    tail_start: int,
) -> tuple[int, bytes, int]:
    eocd_index = -1
    for index in range(len(tail) - 22, max(-1, len(tail) - 65557), -1):
        if tail[index : index + 4] == b"PK\x05\x06":
            eocd_index = index
            break
    if eocd_index < 0:
        raise RuntimeError("Could not find the ZIP end-of-central-directory record.")

    entry_count = struct.unpack_from("<H", tail, eocd_index + 10)[0]
    central_size = struct.unpack_from("<I", tail, eocd_index + 12)[0]
    central_offset = struct.unpack_from("<I", tail, eocd_index + 16)[0]
    central_index = central_offset - tail_start
    if central_index < 0 or central_index + central_size > len(tail):
        raise RuntimeError("ZIP central directory is not inside the downloaded tail.")
    return entry_count, tail[central_index : central_index + central_size], central_index


def read_entry(
    central_data: bytes,
    entry_count: int,
    wanted_name: str,
) -> tuple[int, int, int]:
    cursor = 0
    for _ in range(entry_count):
        if central_data[cursor : cursor + 4] != b"PK\x01\x02":
            raise RuntimeError("Invalid ZIP central-directory entry.")
        method = struct.unpack_from("<H", central_data, cursor + 10)[0]
        compressed_size = struct.unpack_from("<I", central_data, cursor + 20)[0]
        name_length = struct.unpack_from("<H", central_data, cursor + 28)[0]
        extra_length = struct.unpack_from("<H", central_data, cursor + 30)[0]
        comment_length = struct.unpack_from("<H", central_data, cursor + 32)[0]
        local_offset = struct.unpack_from("<I", central_data, cursor + 42)[0]
        name = central_data[cursor + 46 : cursor + 46 + name_length].decode("utf-8")
        if name == wanted_name:
            return method, compressed_size, local_offset
        cursor += 46 + name_length + extra_length + comment_length
    raise RuntimeError(f"Template entry was not found: {wanted_name}")


def download_entry(
    method: int,
    compressed_size: int,
    local_offset: int,
    destination: Path,
) -> None:
    header = fetch_range(local_offset, local_offset + 4095)
    if header[:4] != b"PK\x03\x04":
        raise RuntimeError("Invalid local ZIP header for the Web template.")
    name_length = struct.unpack_from("<H", header, 26)[0]
    extra_length = struct.unpack_from("<H", header, 28)[0]
    data_start = local_offset + 30 + name_length + extra_length
    data_end = data_start + compressed_size - 1

    ranges = [
        (start, min(start + CHUNK_SIZE - 1, data_end))
        for start in range(data_start, data_end + 1, CHUNK_SIZE)
    ]
    chunks: list[bytes | None] = [None] * len(ranges)

    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {
            executor.submit(fetch_range, start, end): index
            for index, (start, end) in enumerate(ranges)
        }
        for future in concurrent.futures.as_completed(futures):
            index = futures[future]
            chunks[index] = future.result()

    compressed = b"".join(chunk for chunk in chunks if chunk is not None)
    if len(compressed) != compressed_size:
        raise RuntimeError(
            f"Downloaded {len(compressed)} template bytes; expected {compressed_size}."
        )

    if method == 8:
        unpacked = zlib.decompress(compressed, -zlib.MAX_WBITS)
    elif method == 0:
        unpacked = compressed
    else:
        raise RuntimeError(f"Unsupported ZIP compression method: {method}")

    destination.write_bytes(unpacked)
    with zipfile.ZipFile(destination) as template_zip:
        bad_file = template_zip.testzip()
        if bad_file is not None:
            raise RuntimeError(f"Downloaded template contains a bad file: {bad_file}")


def main() -> None:
    project_builds = Path(__file__).resolve().parent.parent / "builds"
    project_builds.mkdir(parents=True, exist_ok=True)
    total_size = get_total_size()
    tail_size = min(2 * 1024 * 1024, total_size)
    tail_start = total_size - tail_size
    cached_tail = project_builds / "export_templates_tail.bin"
    if cached_tail.is_file() and cached_tail.stat().st_size == tail_size:
        tail = cached_tail.read_bytes()
    else:
        tail = fetch_range(tail_start, total_size - 1)
    entry_count, central_data, _central_index = find_central_directory(tail, tail_start)
    method, compressed_size, local_offset = read_entry(
        central_data,
        entry_count,
        ENTRY_NAME,
    )

    appdata = os.environ.get("APPDATA")
    if not appdata:
        raise RuntimeError("APPDATA is not set; cannot locate the Godot template directory.")
    install_directory = (
        Path(appdata) / "Godot" / "export_templates" / f"{VERSION}.stable"
    )
    install_directory.mkdir(parents=True, exist_ok=True)
    destination = install_directory / Path(ENTRY_NAME).name

    with tempfile.TemporaryDirectory(dir=project_builds) as temporary_directory:
        staged_template = Path(temporary_directory) / destination.name
        download_entry(method, compressed_size, local_offset, staged_template)
        destination.write_bytes(staged_template.read_bytes())

    print(f"WEB_TEMPLATE_OK={destination}")
    print(f"WEB_TEMPLATE_BYTES={destination.stat().st_size}")


if __name__ == "__main__":
    main()

