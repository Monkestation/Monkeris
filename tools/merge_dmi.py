#!/usr/bin/env python3
"""
merge_dmi.py - Merges icon states from one DMI file into another.

This script parses that metadata and the underlying sprite sheet to copy
icon states from a source DMI into a target DMI, skipping any states that
already exist in the target.

Requirements:
    pip install Pillow

Usage:
    python tools/merge_dmi.py <source.dmi> <target.dmi>

The original target file is backed up as <target.dmi>.bak before any changes
are written. Only states missing from the target are added, existing states
are never overwritten. Both DMI files must use the same icon size (width x
height); states from a differently-sized source are skipped.

Example:
    python tools/merge_dmi.py icons/obj/bureaucracy-monke.dmi icons/obj/bureaucracy.dmi
"""

import io
import math
import shutil
import struct
import sys
import zlib

from PIL import Image


def read_png_chunks(data):
    """Read all PNG chunks from raw bytes, returning list of (type, data, crc)."""
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError("Not a PNG file")
    chunks = []
    pos = 8
    while pos < len(data):
        length = struct.unpack('>I', data[pos:pos+4])[0]
        chunk_type = data[pos+4:pos+8]
        chunk_data = data[pos+8:pos+8+length]
        crc = data[pos+8+length:pos+12+length]
        chunks.append((chunk_type, chunk_data, crc))
        pos += 12 + length
    return chunks


def get_dmi_description(filepath):
    """Extract the BYOND DMI description string from a DMI file."""
    with open(filepath, 'rb') as f:
        data = f.read()
    for chunk_type, chunk_data, _ in read_png_chunks(data):
        if chunk_type == b'zTXt':
            null_pos = chunk_data.index(b'\x00')
            if chunk_data[:null_pos].decode('latin-1') == 'Description':
                compressed = chunk_data[null_pos+2:]  # skip null + compression method byte
                return zlib.decompress(compressed).decode('latin-1')
        elif chunk_type == b'tEXt':
            null_pos = chunk_data.index(b'\x00')
            if chunk_data[:null_pos].decode('latin-1') == 'Description':
                return chunk_data[null_pos+1:].decode('latin-1')
    return None


def parse_dmi_description(desc):
    """
    Parse the BYOND DMI description block into a header dict and a list of
    state dicts. Each state dict contains: name, dirs, frames, raw_lines.
    raw_lines preserves the original metadata lines so they can be
    round-tripped exactly into the output file.
    """
    header = {}
    states = []
    current_state = None

    for line in desc.strip().split('\n'):
        line = line.strip()
        if line.startswith('# BEGIN DMI') or line.startswith('# END DMI'):
            continue
        if line.startswith('version'):
            header['version'] = line.split('=')[1].strip()
        elif line.startswith('width'):
            header['width'] = int(line.split('=')[1].strip())
        elif line.startswith('height'):
            header['height'] = int(line.split('=')[1].strip())
        elif line.startswith('state'):
            if current_state is not None:
                states.append(current_state)
            name = line.split('=', 1)[1].strip().strip('"')
            current_state = {'name': name, 'dirs': 1, 'frames': 1, 'raw_lines': [line]}
        elif current_state is not None:
            current_state['raw_lines'].append(line)
            if line.startswith('dirs'):
                current_state['dirs'] = int(line.split('=')[1].strip())
            elif line.startswith('frames'):
                current_state['frames'] = int(line.split('=')[1].strip())

    if current_state is not None:
        states.append(current_state)

    return header, states


def get_state_frame_count(state):
    return state['dirs'] * state['frames']


def extract_state_images(dmi_path, header, states):
    """
    Slice the sprite sheet into individual PIL images per state, returned as
    a dict mapping state name -> list of frame images (in sheet order).
    """
    img = Image.open(dmi_path).convert('RGBA')
    w, h = header['width'], header['height']
    cols = img.width // w

    result = {}
    frame_index = 0
    for state in states:
        count = get_state_frame_count(state)
        frames = []
        for _ in range(count):
            col = frame_index % cols
            row = frame_index // cols
            box = (col * w, row * h, (col + 1) * w, (row + 1) * h)
            frames.append(img.crop(box))
            frame_index += 1
        result[state['name']] = frames

    return result


def build_dmi_description(header, states):
    """Reconstruct the BYOND DMI description string from header and state list."""
    lines = ['# BEGIN DMI']
    lines.append(f"version = {header['version']}")
    lines.append(f"\twidth = {header['width']}")
    lines.append(f"\theight = {header['height']}")
    for state in states:
        for line in state['raw_lines']:
            lines.append(f"\t{line}" if not line.startswith('state') else line)
    lines.append('# END DMI')
    return '\n'.join(lines) + '\n'


def build_dmi(header, states, all_frames_map):
    """
    Assemble a complete DMI file (as bytes) from the given states and frames.
    Lays out frames in a near-square grid, embeds the description as a zTXt
    chunk before the first IDAT chunk (matching BYOND's format).
    """
    w, h = header['width'], header['height']
    total_frames = sum(get_state_frame_count(s) for s in states)
    cols = math.ceil(math.sqrt(total_frames))

    sheet = Image.new('RGBA', (cols * w, math.ceil(total_frames / cols) * h), (0, 0, 0, 0))
    frame_index = 0
    for state in states:
        for frame in all_frames_map[state['name']]:
            col = frame_index % cols
            row = frame_index // cols
            sheet.paste(frame, (col * w, row * h))
            frame_index += 1

    # Encode as PNG first, then inject our Description zTXt chunk
    png_bytes = io.BytesIO()
    sheet.save(png_bytes, format='PNG', optimize=False)
    chunks = read_png_chunks(png_bytes.getvalue())

    desc = build_dmi_description(header, states)
    keyword = b'Description\x00'
    compressed_desc = zlib.compress(desc.encode('latin-1'))
    ztxt_data = keyword + b'\x00' + compressed_desc
    ztxt_crc = struct.pack('>I', zlib.crc32(b'zTXt' + ztxt_data) & 0xffffffff)
    ztxt_chunk = struct.pack('>I', len(ztxt_data)) + b'zTXt' + ztxt_data + ztxt_crc

    result = b'\x89PNG\r\n\x1a\n'
    desc_injected = False
    for chunk_type, chunk_data, crc in chunks:
        # Drop any existing Description chunk
        if chunk_type in (b'zTXt', b'tEXt'):
            null_pos = chunk_data.find(b'\x00')
            if null_pos >= 0 and chunk_data[:null_pos] == b'Description':
                continue
        # Inject ours just before image data
        if chunk_type == b'IDAT' and not desc_injected:
            result += ztxt_chunk
            desc_injected = True
        result += struct.pack('>I', len(chunk_data)) + chunk_type + chunk_data + crc

    return result


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    source_path = sys.argv[1]
    target_path = sys.argv[2]

    print(f"Reading source: {source_path}")
    src_header, src_states = parse_dmi_description(get_dmi_description(source_path))
    src_frames = extract_state_images(source_path, src_header, src_states)
    print(f"  {len(src_states)} states found")

    print(f"Reading target: {target_path}")
    tgt_header, tgt_states = parse_dmi_description(get_dmi_description(target_path))
    tgt_frames = extract_state_images(target_path, tgt_header, tgt_states)
    print(f"  {len(tgt_states)} states found")

    tgt_state_names = {s['name'] for s in tgt_states}
    to_add = [s for s in src_states if s['name'] not in tgt_state_names]

    if not to_add:
        print("\nNothing to do - all source states already exist in target.")
        return

    print(f"\nStates to add ({len(to_add)}): {[s['name'] for s in to_add]}")

    if src_header['width'] != tgt_header['width'] or src_header['height'] != tgt_header['height']:
        print(
            f"\nERROR: Icon sizes differ - "
            f"source is {src_header['width']}x{src_header['height']}, "
            f"target is {tgt_header['width']}x{tgt_header['height']}. Aborting."
        )
        sys.exit(1)

    merged_states = tgt_states + to_add
    merged_frames = {**tgt_frames, **{s['name']: src_frames[s['name']] for s in to_add}}

    print(f"\nBuilding merged DMI ({len(merged_states)} states total)...")
    result = build_dmi(tgt_header, merged_states, merged_frames)

    backup_path = target_path + '.bak'
    shutil.copy2(target_path, backup_path)
    print(f"Backed up original to: {backup_path}")

    with open(target_path, 'wb') as f:
        f.write(result)

    print(f"Done. Added {len(to_add)} new states to {target_path}")


if __name__ == '__main__':
    main()
