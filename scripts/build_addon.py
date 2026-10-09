#!/usr/bin/env python3
"""Package the standalone N Talent Calculator for WoW 3.3.5a.

The approved DBC-to-Lua data generator must be run first. This package works
standalone (NCore is optional) and does not modify the original data sources.
"""
import argparse
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "NTalentCalculator"
CONTENTS = ("NTalentCalculator.toc", "Data.lua", "Engine.lua", "Progression.lua", "UI.lua")


def build(output_dir):
    toc_path = SOURCE / CONTENTS[0]
    toc = toc_path.read_text(encoding="utf-8")
    version = re.search(r"^## Version:\s*(\S+)", toc, re.M)
    if not version or not re.fullmatch(r"\d+\.\d+\.\d+(?:[-.][A-Za-z0-9.-]+)?", version.group(1)):
        raise ValueError("Invalid or missing addon version in NTalentCalculator.toc")
    if "## Interface: 30300" not in toc or "## OptionalDeps: NCore" not in toc:
        raise ValueError("Addon should support WoW 3.3.5a and standalone installation")
    expected_lines = []
    for item in CONTENTS[1:]:
        if not (SOURCE / item).is_file():
            raise ValueError("Missing addon file: " + item)
        expected_lines.append(item)
    for line in expected_lines:
        if line not in toc.splitlines():
            raise ValueError("File absent from TOC: " + line)
    output = Path(output_dir)
    output.mkdir(parents=True, exist_ok=True)
    name = f"N-Talent-Calculator-v{version.group(1)}.zip"
    archive = output / name
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as z:
        for name in CONTENTS:
            z.write(SOURCE / name, arcname="NTalentCalculator/" + name)
    print(f"Built standalone addon: {archive}")
    return archive


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--output-dir", default="dist")
    args = p.parse_args()
    build(args.output_dir)
