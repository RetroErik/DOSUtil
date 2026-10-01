"""Reverse post-20:00 source patches recorded in the local Codex session.

This produces a candidate ASM without touching the workspace source. The
candidate must build byte-for-byte identical COM files before it is installed.
"""

from pathlib import Path
import json
import re

backup = Path(__file__).resolve().parent
session_dir = Path.home() / ".codex/sessions/2026/09/26"
session = next(session_dir.glob("rollout-2026-09-26T17-12-23*.jsonl"))
cutoff = "2026-09-26T18:00:09.000Z"
pattern = re.compile(r'tools\.apply_patch\(("(?:\\.|[^"\\])*")\)')


def reverse_patch(source, patch, target):
    lines = patch.splitlines()
    header = f"*** Update File: XGA/xga-demo/{target}"
    if header not in lines:
        return source, False
    start = lines.index(header) + 1
    end = next((i for i in range(start, len(lines))
                if lines[i].startswith("*** ")), len(lines))
    hunks = []
    old, new = [], []
    for line in lines[start:end]:
        if line.startswith("@@"):
            if old or new:
                hunks.append((old, new))
            old, new = [], []
        elif line.startswith("+"):
            new.append(line[1:])
        elif line.startswith("-"):
            old.append(line[1:])
        elif line.startswith(" "):
            old.append(line[1:])
            new.append(line[1:])
        else:
            raise ValueError(f"Unexpected patch line: {line!r}")
    if old or new:
        hunks.append((old, new))
    for old, new in reversed(hunks):
        positions = [i for i in range(len(source) - len(new) + 1)
                     if source[i:i + len(new)] == new]
        if len(positions) != 1:
            raise ValueError(f"Hunk has {len(positions)} matches: {new[:3]!r}")
        pos = positions[0]
        source[pos:pos + len(new)] = old
    return source, True


calls = {target: [] for target in ("xga_dreams.asm", "README.md")}
for line in session.open(encoding="utf-8"):
    event = json.loads(line)
    if event["timestamp"] <= cutoff or event["type"] != "response_item":
        continue
    # This README patch failed verification and never changed the file.
    if event["timestamp"].startswith("2026-09-26T18:08:41"):
        continue
    payload = event["payload"]
    if payload.get("type") != "custom_tool_call":
        continue
    for match in pattern.finditer(payload.get("input", "")):
        patch = json.loads(match.group(1))
        for target in calls:
            if f"*** Update File: XGA/xga-demo/{target}" in patch.splitlines():
                calls[target].append((event["timestamp"], patch))

for target, edits in calls.items():
    text = (backup / target).read_text(encoding="utf-8")
    ends_with_newline = text.endswith("\n")
    source = text.splitlines()
    for timestamp, patch in reversed(edits):
        source, changed = reverse_patch(source, patch, target)
        assert changed
        print("reversed", target, timestamp)
    out = backup / (target + ".recovered")
    out.write_text("\n".join(source) + ("\n" if ends_with_newline else ""),
                   encoding="utf-8", newline="\n")
    print("recovered", out, "patches", len(edits))
