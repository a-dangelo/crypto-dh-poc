# Schnorr documentation verification

Status on 2026-11-11: editable documentation source is prepared. The full
VersoBlueprint document has not yet been rendered and is not a finished website.

## Completed checks

- Python scripts pass `py_compile`; `scripts/build.sh` passes `bash -n`.
- Static checks find no DH or Concrete imports in the documentation package.
- The manifest pins VersoBlueprint at
  `4943d3335ffa9221a39949e60836a8ad5dc2a456`.
- Every declaration referenced by a Blueprint node exists in the current
  Schnorr source. This is a source check, not document elaboration.
- `lake build SchnorrBlueprint.Code` succeeded, including the copied local
  renderer's source-window and source-spelling checks.
- The documentation build's proof stage succeeded. Its strict audit checked
  all 18 advertised endpoints and found only `propext`, `Classical.choice`,
  and `Quot.sound`. See `../../evidence/blueprint-axioms.log`.

The protocol's separate full replay is recorded in
`../../evidence/verification.json`. It includes Rust tests, exact extraction
comparison, the Lean proof build, the axiom audit, and import isolation.
That replay does not establish documentation rendering or browser behavior.

## Pending checks

- Elaborate the complete `SchnorrBlueprint.Blueprint` document.
- Render the HTML and run `lake exe vbp check`.
- Export the final source snapshot and check local links and declaration panels.
- Run Chromium at desktop and narrow widths with `scripts/browser-qa.py`.
- Inspect screenshots, rendered mathematics, the dependency graph, source panels,
  and type hovers.

The full document build did not reach a confirmed completion. No rendered site
or browser QA result is claimed. No publication or deployment was performed.
