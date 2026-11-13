# Rust cryptographic verification examples

Small Rust programs, Aeneas extraction, and Lean security proofs connected to
VCVio. The [shared verification blueprint](https://a-dangelo.com/crypto-dh-poc/)
contains one chapter per example, with Diffie–Hellman, interactive Schnorr, and hash commitment in separate chapters.

## Examples

- [Diffie–Hellman](Examples/DH/README.md): the existing coin-explicit Ristretto
  implementation, concrete refinement, and conditional DDH security reduction.
  Its Rust and Lean source remain unchanged by the directory reorganization.
- [Interactive Schnorr](Examples/Schnorr/README.md): extracted prover/verifier
  control flow, conditional arithmetic refinement, special soundness and perfect
  honest-verifier zero knowledge. The stateful RNG interpretation is proved
  separately; no concrete RNG distribution or dalek arithmetic theorem is claimed.

- [Hash commitment](Examples/HashCommitment/README.md): generic Rust randomness,
  an explicit ideal-entropy interpretation, and implementation-to-model
  correspondence. The binding bound reduces to keyed collision resistance; it
  does not establish hiding or verify an operating-system RNG.

Each example keeps its code, proofs, dependency pins, scripts and evidence under
its own directory. Shared book sources, rendering and website checks live in
[`docs/`](docs/README.md). Adding a chapter does not require importing another
example into its proof package.

## Reproduction

Use each example's README for its independent checks. Use `docs/README.md` to
build the common book. The supported full stack runs on Linux x86_64; cloud CI
performs the documentation build and publishes the checked site.
