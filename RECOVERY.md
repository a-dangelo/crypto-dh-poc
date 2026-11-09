# Source provenance and verification

This checkout was assembled on 9 November 2026 from the persisted private project site. It starts a new Git history. The original repository and its Git objects were not recovered.

## Recovered proof-of-concept source

- Original source revision recorded by the snapshot: `a27d45ad02331a96279032a11872d6ec7af47860`. This is provenance, not a commit present in this new history.
- Persisted website source used for recovery: `b4bbea82c5242427beedc0ce5a79e1672929d45d`.
- Portable snapshot archive SHA256: `d3b2b0fdcdfb831bb516314a048a77e9356c8f255f3286131ad70a23183ce1a3`.
- `manifest.json` records the exact SHA256, byte count, and line count of all 67 recovered source and evidence files. All 67 contents were verified on the Mac after transfer and remain byte-for-byte unchanged. The recovered `README.md` is now stored at `docs/recovered/README.md`; the other 66 files retain their original paths.
- All 23 source hashes and line counts in `concrete/evidence/concrete-proof-report.json` were independently checked against these files.

The snapshot does not include original Git history, the original `.gitignore`, editable Blueprint sources, fetched dependencies, build caches, or raw LLBC. The `.gitignore` in this repository is new. Editable Blueprint material is reconstructed separately and documents its own provenance. Pinned dependency-fetching scripts are included.

## Verification limits

The included proof, extraction, axiom-audit, and native smoke-test logs are preserved evidence from the original cloud run. Recovery verified their hashes; it did not rerun those checks or regenerate those logs. Shell and Python source syntax checks passed on the Mac. No Rust compilation, Lean build, or extraction was run on the Mac. The documented full reproduction route targets Linux x86_64 and requires the pinned dependencies.

## Revised documentation and snapshot paths

The root `README.md` is a revised introduction. The snapshot README is preserved verbatim at [`docs/recovered/README.md`](docs/recovered/README.md), including its historical statement about the original task running only in the cloud. This imported checkout is now present on the Mac.

Both `manifest.json` and `blueprint/source-manifest.json` retain the original paths and hashes. For snapshot validation and export, only the manifest key `README.md` resolves to `docs/recovered/README.md`. The private source export still stores those original bytes as `source/README.md`, so the exported snapshot matches its unchanged manifest. Public source links point to the archived README in the private repository.

The reconstructed Blueprint and its later proof-only replay have separate provenance in `blueprint/verification/`. They do not replace or modify the historical proof, extraction, or native-test logs.
