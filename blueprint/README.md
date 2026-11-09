# Rust DH verification blueprint

This is newly authored, editable VersoBlueprint documentation for the recovered,
hash-verified PoC snapshot at a27d45ad02331a96279032a11872d6ec7af47860.
It replaces the earlier documentation; it does not recover its Git history.

The paired renderer adapts `verso-blueprint-declarations` from a-dangelo/scratchpad
at 4b097e96e75f996d1228621bfc4b353aa803ed96. Mathematical prose appears on the
left and actual imported Lean source on the right. SubVerso supplies defining
commands, token hovers and tactic states. At narrow widths, prose precedes code.

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
default. The first GitHub Actions run validates the complete bootstrap recipe.

## Outputs and publication

- `_out/site/html-multi`: complete private review output, including source and
  evidence. **Do not publish this directory publicly.**
- `_out/site/pages-public`: the public website. It contains the prose and thirteen
  declaration panels, native hovers and graph assets. Full source and evidence
  links point to the private GitHub repository. No source archive, raw proof files
  or logs are included.

The public export checks declaration fidelity, local links, publication boundaries
and project-relative paths. It adds `noindex, nofollow`; these request crawler
behavior and do not restrict access. Anyone with the URL can read the website.

`.github/workflows/blueprint-pages.yml` builds on pushes and pull requests. Only
`main` can upload the sanitized artifact and deploy to GitHub Pages. Repository
visibility remains private. The existing owner-private Site is not made public.

See `verification/QA.md` for tested behavior and verification limits.
