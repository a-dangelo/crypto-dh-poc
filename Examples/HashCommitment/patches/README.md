# Aeneas probabilistic effects

The patch applies to Aeneas commit `de16f3cf877976e966906dc890f63dcb418884fa`.
`toolchain.json` records the patch digest, the Charon revision, and the digests of
the modified Lean runtime files. `scripts/check-toolchain.sh` checks these
identities and the source-built extractor before extraction.

## Runtime

`RustEffect.Input.uniform n` has response type `Fin (n + 1)`.
`Result.uniform n` emits this request and returns its response. The patch does
not replace `Result`: return, bind, failure, and divergence retain their existing
definitions. Probability is supplied by the example's interpreter, not by the
runtime operation itself. The deterministic weakest precondition rejects both
failure and uniform requests, so a random computation does not acquire an
ordinary deterministic specification by this extension.

The tracked files under `evidence/runtime/` are exact snapshots for documentation
and audit. They are not a second runtime used by the build.

## Extraction

The opt-in flag `-probabilistic` disables `simplify_duplicate_calls`. Identical
monadic calls may denote independent requests, so substituting a previous
result is invalid. It also prevents `filter_useless` from deleting monadic calls
on the basis of failure analysis alone. Pure unused assignments still simplify.
Ordinary extraction does not enable this flag and retains its prior behaviour.

The adjacent `inline_useless_var_assignments` pass requires a nonmonadic binding
before substituting its expression. `simplify_let_bindings` reassociates binds;
`merge_let_app_then_decompose_tuple` changes tuple destructuring; and
`simplify_let_then_ok` removes a final return using the right-unit law. These
transformations do not identify separate random requests. This review is not a
semantic proof of the entire extractor. The generated-code regressions check
separate draws, result reuse, branches, and identical opaque calls.

## Reproduction

Both bootstrap modes materialise and check VCV-io at
`88efe9715a9fa9e7d89635c38cf70259836766c2`, as recorded in `toolchain.json`.
Existing VCV-io checkouts must have that revision and no unrecorded changes;
the script does not reset them.

Use `scripts/bootstrap.sh --runtime-only` for a Lean-only consumer. Full
bootstrap requires OCaml 5.3.0 and opam and builds the patched extractor from
source. Charon uses the exact upstream pin. The scripts do not reuse an Aeneas
release binary with the modified Lean runtime.

The full bootstrap currently targets Linux x86_64. Install the official Lean
`v4.35.0` toolchain, OCaml `5.3.0`, opam, and the Rust nightly specified by
`vendor/aeneas/charon/rust-toolchain`. The bootstrap pins Dune `3.17.2`, builds
Aeneas, and obtains Charon from the matching upstream release after checking its
SHA-256 digest. Both Charon executables are checked again before extraction.
`ELAN_HOME`, `OPAMROOT`, `RUSTUP_HOME`, `CARGO_HOME`, and `XDG_CACHE_HOME` can point
to writable workspace directories. `BUILD_JOBS` defaults to four. For the Lean
backend, `LEAN_NUM_THREADS=2` avoids excessive memory use in the upstream async
benchmark. Fetch mathlib caches with `lake exe cache get` before building.

The package versions used for this source build are recorded in
`evidence/ocaml-packages.txt`. They are build provenance, not part of the
cryptographic assumptions.

### Clean-checkout prerequisites

Use Python 3.11 or later (`tomllib` is used by extraction), Git, curl, tar,
GNU Make, a C compiler, pkg-config, and GMP development headers. Initialise opam
and select an OCaml 5.3.0 switch before full bootstrap. With official elan and
rustup already installed, the required toolchains can be selected as follows:

```sh
elan toolchain install leanprover/lean4:v4.35.0
opam switch create hash-commitment 5.3.0
eval "$(opam env --switch=hash-commitment)"
rustup toolchain install nightly-2026-09-17 --profile minimal \
  --component rustc-dev,llvm-tools,rust-src,miri
scripts/bootstrap.sh
(cd lean && lake exe cache get)
scripts/check.sh
```

Ensure elan's and Cargo's `bin` directories are on `PATH`; extraction and tests
use Cargo from the pinned Rust nightly. The checked-in Lake manifest supplies
the remaining Lean dependency revisions. `lake exe cache get` materialises
those dependencies and obtains available cached build artifacts. Runtime-only
bootstrap obtains the two source dependencies but does not install compilers,
fetch Lake caches, or build anything.
