# Verification of reconstructed documentation

Checked on 9 November 2026 against the recovered core snapshot
`a27d45ad02331a96279032a11872d6ec7af47860`.

- Fresh cloud concrete build passed (4,097 jobs). All 22 axiom closures match the
  preserved audit exactly. All 67 source/evidence hashes remain unchanged.
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
