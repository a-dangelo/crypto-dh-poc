#!/usr/bin/env python3
"""Run browser QA for the shared book."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).resolve().parents[2] / "scripts/browser-qa.py"), run_name="__main__")
