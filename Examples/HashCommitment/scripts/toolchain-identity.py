#!/usr/bin/env python3
"""Reject stale or modified Aeneas sources and extractor binaries."""
import hashlib, json, pathlib, subprocess, sys
root = pathlib.Path(__file__).resolve().parents[1]
source = root / "vendor/aeneas"
lock = json.loads((root / "patches/toolchain.json").read_text())
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def git(*args): return subprocess.check_output(["git", "-C", str(source), *args])
untracked = set(git("ls-files", "--others", "--exclude-standard").decode().splitlines())
assert untracked <= {".hash-commitment-build.json"}, "unrecorded source files: " + str(sorted(untracked))
vcvio = root / "vendor/VCVio"
assert subprocess.check_output(["git", "-C", str(vcvio), "rev-parse", "HEAD"]).decode().strip() == lock["vcvio_revision"], "wrong VCV-io revision"
assert not subprocess.check_output(["git", "-C", str(vcvio), "status", "--porcelain", "--untracked-files=normal"]), "VCV-io checkout has unrecorded modifications"
assert git("rev-parse", "HEAD").decode().strip() == lock["aeneas_revision"], "wrong Aeneas base"
patch = root / "patches/aeneas-probabilistic.patch"
assert sha(patch) == lock["patch_sha256"], "patch digest mismatch"
assert hashlib.sha256(git("diff", "--binary", "HEAD")).hexdigest() == lock["patch_sha256"], "source differs from tracked patch"
for name, digest in lock["runtime_files"].items():
    assert sha(source / "backends/lean" / name) == digest, "runtime mismatch: " + name
if len(sys.argv) < 2 or sys.argv[1] != "runtime":
    assert subprocess.check_output(["git", "-C", str(source / "charon"), "rev-parse", "HEAD"]).decode().strip() == lock["charon_revision"]
    for name, digest in lock["charon_binaries"].items():
        assert sha(source / "charon/bin" / name) == digest, "Charon mismatch: " + name
    record = json.loads((source / ".hash-commitment-build.json").read_text())
    assert record["aeneas_revision"] == lock["aeneas_revision"]
    assert record["patch_sha256"] == lock["patch_sha256"]
    assert sha(source / "bin/aeneas") == record["binary_sha256"], "stale extractor"
print("Verified VCV-io pin and Aeneas source/patch/runtime" + ("" if sys.argv[-1] == "runtime" else "/binary"))
