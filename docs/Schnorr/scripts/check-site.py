#!/usr/bin/env python3
"""Check the shared book, including both chapter libraries."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).resolve().parents[2] / "scripts/check-site.py"), run_name="__main__")
