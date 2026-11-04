#!/usr/bin/env python3
"""Drop monthly partition children (<table>_yYYYY_mMM) from generated db types.

ensure_partitions() rolls a window of month partitions with the calendar, so
their generated types change every month without any schema change. Apps use
the parent tables only; the contract excludes the children. Reads stdin,
writes stdout.
"""
import re
import sys

out, skip = [], False
start = re.compile(r"^      [a-z0-9_]+_y\d{4}_m\d{2}: \{$")
for line in sys.stdin.read().split("\n"):
    if not skip and start.match(line):
        skip = True
        continue
    if skip:
        if line == "      }":
            skip = False
        continue
    out.append(line)
sys.stdout.write("\n".join(out))
