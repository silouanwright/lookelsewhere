#!/usr/bin/env python3
"""Run this checkout's desktop tests inside Oligarchy, never on the host desktop."""
import os
from pathlib import Path
import subprocess as sp
import sys

root=Path(__file__).resolve().parents[2]
harness=Path(os.environ.get('OLIGARCHY_HARNESS_HOME',str(Path.home()/'Documents/ChatGPT/SnipExpand/oligarchy-pilot')))
runner=harness/'run.py'
if not runner.is_file():
    raise SystemExit('Oligarchy runner missing. Set OLIGARCHY_HARNESS_HOME; no host fallback is allowed.')
raise SystemExit(sp.call([sys.executable,str(runner),'look-elsewhere','--source',str(root),*sys.argv[1:]]))
