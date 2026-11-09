# Rust DH verification blueprint

This editable VersoBlueprint documents the Diffie–Hellman proof derived from
the recovered snapshot at `a27d45ad02331a96279032a11872d6ec7af47860`.
The current sources include revised docstrings and separate verification scripts.
The recovered snapshot and its evidence remain available with their original hashes.
The documentation does not reconstruct the lost Git history.

The paired renderer adapts `verso-blueprint-declarations` from a-dangelo/scratchpad
at 4b097e96e75f996d1228621bfc4b353aa803ed96. Mathematical prose appears on the
left and actual imported Lean source on the right. SubVerso supplies defining
commands, token hovers and tactic states. At narrow widths, prose precedes code.

The opening theorem links its experiments and refinement assumptions.
One short page recalls the DH exchange. Two framework notes explain the
adversary type and oracle interface. The games chapter displays the primitive
model and distinguishes it from the stateful CKA scheme interface.

## Reproduce on Linux x86_64

Install Git, Python 3 and official elan with Lean 4.35.0, then run from the
repository root:

```sh
elan toolchain install leanprover/lean4:v4.35.0
bash blueprint/scripts/bootstrap-docs.sh
cd blueprint
sh scripts/build.sh
lake exe vbp check
python3 scripts/export-public.py --repository-revision "$(git rev-parse HEAD)"
```

Use the committed Lake manifests. Do not run `lake update`: it can change the
audited dependency graph. The bootstrap fetches pinned proof-library sources and
Lean caches; it does not install Rust toolchains or repeat Charon/Aeneas extraction.
A clean build needs several gigabytes of disk and RAM. Two Lean threads are the
default. GitHub Actions runs the same source, proof and documentation checks.

## Source versions and proof checks

`source-manifest.json` records the 67 historical source and evidence files.
`current-source-manifest.json` records the 66 current files and maps each changed
historical file to its preserved text under `docs/recovered/`.
The generated translations, Rust sources and original verification reports are
unchanged. Current declaration panels and source links use the revised files.
The private export includes the historical snapshot under `source/historical/`.

The build checks both manifests, compiles `Concrete` and `DhPoc`, and runs
`scripts/check-concrete-axioms.lean` and `scripts/check-generic-axioms.lean`.
The latter also checks the arithmetic witness and failure regressions.
Both scripts must reproduce the recorded axiom dependencies.
`verification/current-source-replay.json` records the fresh cloud replay and
states which historical checks were not repeated.

## Outputs and publication

- `_out/site/html-multi`: complete private review output, including source and
  evidence. **Do not publish this directory publicly.**
- `_out/site/pages-public`: the public website. It contains the prose and declaration
  panels, native hovers and graph assets. Full source and evidence
  links point to the private GitHub repository. No source archive, raw proof files
  or logs are included.

The public export checks declaration fidelity, local links, publication boundaries
and project-relative paths. It adds `noindex, nofollow`; these request crawler
behavior and do not restrict access. Anyone with the URL can read the website.

`.github/workflows/blueprint-pages.yml` builds on pushes and pull requests. Only
`main` can upload the sanitized artifact and deploy to GitHub Pages. Repository
visibility remains private. The existing owner-private Site is not made public.

See `verification/QA.md` for tested behavior and verification limits.
