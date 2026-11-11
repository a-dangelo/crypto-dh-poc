# Verification of reconstructed documentation

## Initial reconstruction

Checked on 9 November 2026 against the recovered core snapshot
`a27d45ad02331a96279032a11872d6ec7af47860`.

- Fresh cloud concrete build passed (4,097 jobs). All 22 axiom closures match the
  preserved audit exactly. All 67 source/evidence contents remain hash-identical.
  The original snapshot README is preserved at `docs/recovered/README.md`; the
  current root README is revised documentation. Snapshot verification and private
  export resolve this path explicitly and retain the original manifests.
- Native VersoBlueprint build and `vbp check` passed: 26 preview manifest/cache
  entries, no errors. Private HTML checks passed for 39 pages and 1,979 links.
- All 13 Lean panels are contiguous excerpts of the defining source commands.
  The export preserves 500 token hovers and tactic-state data.
- Mathematical statements were checked against the current declarations and
  assumptions. Graph dependencies and line-count qualifications were reviewed.
- Browser review under `/crypto-dh-poc/` passed at 1,180 px and 500 px. The wide
  layout places prose left and Lean right; the narrow layout stacks prose first.
  Neither viewport had page-level horizontal overflow. Mathematics, navigation,
  keyboard folding and a tactic-state expansion were checked interactively.
- The public output has nine HTML pages. Its checks reject raw source files,
  source archives and logs. Full-source links point to the private repository.
  Build-machine path prefixes are removed. Every HTML page requests no indexing.

The dependency bootstrap script reproduces the commands used for the fresh cloud
restoration and passes syntax/pin checks. It has not yet been run end-to-end from
an empty GitHub runner. No Rust extraction or native execution was repeated during
this documentation rebuild. Historical evidence remains identified separately.

## Source revision and relocated checks

Checked on 9 November 2026 after the docstring and verification-layout changes.

- Both project modules named `Audit.lean` and the project `Examples.lean` module
  are removed. The two verification scripts preserve every original axiom command
  and the four arithmetic/failure regression declarations.
- The cloud builds of `Concrete` and `DhPoc` passed. The relocated checks reproduce
  all 22 concrete and 16 generic axiom dependencies. Existing module-import and
  unused-variable warnings remain.
- Sixteen retained Lean modules have changes only inside comments. The moved
  regression declarations have identical text outside comments. Generated Lean
  translations and Rust sources are byte-identical to the historical snapshot.
- The 66-file current manifest and 67-file historical manifest pass independent
  hash checks. Original manifests and reports are unchanged. Modified historical
  files are preserved as text under `docs/recovered/source/`.

The report `current-source-replay.json` binds the current manifest to the fresh
build and axiom logs. This replay does not repeat Rust extraction or native tests.
Integrated website checks for the revised chapters are reported separately.

## Integrated 17-panel revision

Checked on 9 November 2026 after the comprehensive prose revision.

- `lake build DhBlueprint vbp`, the full `scripts/build.sh`, and `vbp check`
  passed. The Blueprint check reported 34 entries and no errors.
- Private output checks passed for 38 HTML pages, 2,129 links and all 66 current
  file hashes. All 67 historical file hashes were verified independently.
- Public output checks passed for nine HTML pages, 143 files and 467 local links.
  All 17 source panels are exact declaration excerpts, with 613 retained hovers.
  The export contains no full source files, source archives, logs or local
  machine paths. The requested wording exclusions also passed.
- Browser checks passed at viewport widths of 1,180 px and 500 px. Page widths
  were 1,165 px and 485 px, respectively, with no horizontal overflow or KaTeX
  errors. Desktop panels use two columns. Narrow panels place prose before code
  in one column. Theorem numbers wrap correctly at narrow widths.
- Keyboard source disclosure and the native `nativeReal_eq` tactic-state
  expansion were checked interactively. The expanded proof reported
  `All goals completed`.

GitHub Actions run `42574657160` built and deployed the earlier 13-panel revision
`5e29bb0` and saved its build cache. Its live website was verified at
<https://a-dangelo.com/crypto-dh-poc/>. The 17-panel revision above passed the
cloud checks and awaits its own CI run and deployment. This documentation replay
did not repeat Rust extraction or native tests.
