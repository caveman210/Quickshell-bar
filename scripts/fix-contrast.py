#!/usr/bin/env python3
"""Raise terminal foreground colors to a readable contrast.

Keeps the generated (often very dark) background intact and only
lightens/darkens the foreground slots until they clear WCAG AA (4.5:1).
"""
import re
import sys

TARGET = 4.5


def srgb_to_lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def luminance(rgb):
    r, g, b = (srgb_to_lin(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def parse_hex(value):
    value = value.strip().lstrip("#")
    if len(value) != 6:
        return None
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def to_hex(rgb):
    return "#" + "".join(f"{max(0, min(255, round(c))):02x}" for c in rgb)


def adjust(fg, bg, target=TARGET):
    if contrast(fg, bg) >= target:
        return fg

    # Dark backgrounds: mix toward white. Light backgrounds: toward black.
    toward = (255, 255, 255) if luminance(bg) < 0.5 else (0, 0, 0)

    for step in range(1, 101):
        t = step / 100.0
        mixed = tuple(f + (w - f) * t for f, w in zip(fg, toward))
        if contrast(mixed, bg) >= target:
            return tuple(round(c) for c in mixed)

    return toward


def main(path):
    with open(path, "r", encoding="utf-8") as handle:
        lines = handle.readlines()

    bg = None
    sel_bg = None

    for line in lines:
        match = re.match(r"\s*background\s+(#[0-9A-Fa-f]{6})", line)
        if match:
            bg = parse_hex(match.group(1))
        match = re.match(r"\s*selection_background\s+(#[0-9A-Fa-f]{6})", line)
        if match:
            sel_bg = parse_hex(match.group(1))

    if bg is None:
        return

    fg_keys = {"foreground", "cursor"} | {f"color{i}" for i in range(1, 16)}

    with open(path, "w", encoding="utf-8") as handle:
        for line in lines:
            match = re.match(r"(\s*)([A-Za-z0-9_]+)\s+(#[0-9A-Fa-f]{6})(.*)", line)
            if not match:
                handle.write(line)
                continue

            indent, key, value, rest = match.groups()

            if key == "selection_foreground" and sel_bg is not None:
                rgb = parse_hex(value)
                handle.write(f"{indent}{key} {to_hex(adjust(rgb, sel_bg))}{rest}\n")
            elif key in fg_keys:
                rgb = parse_hex(value)
                handle.write(f"{indent}{key} {to_hex(adjust(rgb, bg))}{rest}\n")
            else:
                handle.write(line)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(1)
    main(sys.argv[1])
