#!/usr/bin/env python3
"""Export the shared book using the common publication boundary."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).resolve().parents[2] / "scripts/export-public.py"), run_name="__main__")
