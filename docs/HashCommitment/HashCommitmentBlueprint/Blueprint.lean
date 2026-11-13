import Verso
import VersoManual
import VersoBlueprint
import HashCommitmentBlueprint.Code
import HashCommitment
import HashCommitment.RngComposition

open Verso.Genre Verso.Genre.Manual Informal

#doc (Manual) "Hash commitment in Rust" =>

This example separates a generic Rust program from the probability law used to
analyse it. The program receives a mutable RNG. An ideal interpretation assigns
a probability distribution to its sampling operations. The bridge relates this
interpretation of the generated Lean code to the commitment model.

We thank the Beneficial AI Foundation (BAIF) team for its work on protocol
bridging and probabilistic effects in Aeneas.
The Rust scheme and bridge start from the team's
[toy-bridge experiment](https://github.com/Beneficial-AI-Foundation/toy-bridge/tree/5212ebba2f937765c7ed4d1fb52f3e46e10dcea9).
The model uses VCVio’s existing
[commitment-scheme interface and games](https://github.com/Verified-zkEVM/VCVio/blob/88efe9715a9fa9e7d89635c38cf70259836766c2/VCVio/CryptoFoundations/CommitmentScheme.lean).

> *Scope.* The ideal RNG supplies uniform randomness. This is an explicit
> interpretation, not a verified property of an operating-system RNG or a
> consequence of the Rust `CryptoRng` marker. Hash refinement and collision
> resistance are separate assumptions. No hiding theorem is claimed.

# Rust program and extraction

The caller supplies `&mut R`, with `R: RngCore + CryptoRng`. Commitment generation
fills a 32-byte opening and computes the keyed hash of the message and opening. Verification
recomputes that hash. The opening is returned with the commitment.

The generated code retains the generic `fill_bytes` call. It does not replace
the Rust RNG argument with a pre-sampled tape. This distinction separates
extraction from the choice of a probabilistic interpretation.

::::definition "hc_extracted_commit" (lean := "HashCommitment.Extracted.commit")
:::HashCommitmentBlueprint.pair HashCommitment.Extracted.commit -docstrings
This declaration is Aeneas output, not a hand-written protocol model. Its RNG
dictionary remains an argument. The body calls `fill_bytes` and writes the
returned slice back to the opening array.
:::
::::

::::definition "hc_extracted_verify" (lean := "HashCommitment.Extracted.verify")
:::HashCommitmentBlueprint.pair HashCommitment.Extracted.verify -docstrings
The generated verifier computes the keyed hash of the message and opening, then compares the digest.
It draws no randomness.
:::
::::

::::definition "hc_model_commit" (lean := "HashCommitment.Model.commit")
:::HashCommitmentBlueprint.pair HashCommitment.Model.commit -docstrings
The protocol model samples one opening and returns the hash together with that
opening. Its oracle specifies the requested randomness, not a mutable Rust state.
:::
::::

::::definition "hc_model_scheme" (lean := "HashCommitment.Model.scheme") (uses := "hc_model_commit")
:::HashCommitmentBlueprint.pair HashCommitment.Model.scheme -docstrings
VCVio’s commitment-scheme interface packages setup, commitment generation and
verification. `uniformImpl` interprets the sampling query as a uniform byte vector.
Key generation is a parameter. This Rust crate does not implement it.
:::
::::

# Sampling effect and ideal RNG

The patched Aeneas result type retains ordinary returns, failure and divergence.
It also permits a bounded uniform-sampling effect. The ideal RNG dictionary
interprets `fill_bytes` through these effects. The generic extracted caller does
not change.

> *Fresh calls.* Each executed sampling operation is a fresh effect. Equal
> expressions cannot be merged merely because their arguments agree. The
> probabilistic extraction mode disables duplicate-call simplification and
> deletion of unused monadic calls. Ordinary extraction keeps its original default.

::::definition "hc_effect" (lean := "Aeneas.Std.RustEffect.Input")
:::HashCommitmentBlueprint.pair Aeneas.Std.RustEffect.Input -docstrings
The patched runtime adds bounded uniform sampling alongside the existing
failure effect. Ordinary returns and divergence remain part of the result tree.
:::
::::

::::definition "hc_effect_answer" (lean := "Aeneas.Std.RustEffect.Output") (uses := "hc_effect")
:::HashCommitmentBlueprint.pair Aeneas.Std.RustEffect.Output -docstrings
An answer to `uniform n` lies in `Fin (n + 1)`. A failure effect has no answer.
:::
::::

::::definition "hc_ideal_rng" (lean := "HashCommitment.idealRng") (uses := "hc_effect")
:::HashCommitmentBlueprint.pair HashCommitment.idealRng -docstrings
This hand-written dictionary supplies the ideal interpretation at the extracted
trait interface. Its unit-valued handle carries no randomness. Fresh effects
supply the random values.
:::
::::

::::definition "hc_interpret" (lean := "HashCommitment.Probability.interpret") (uses := "hc_effect")
:::HashCommitmentBlueprint.pair HashCommitment.Probability.interpret -docstrings
The interpreter retains failure, divergence and exhausted fuel as explicit
outcomes. It neither removes nor renormalises their probability mass.
:::
::::

::::theorem "hc_fill_independent" (lean := "HashCommitment.fill_contents_independent") (uses := "hc_ideal_rng")
:::HashCommitmentBlueprint.pair HashCommitment.fill_contents_independent -docstrings
Equal-length input buffers give the same ideal filling computation. Old buffer
contents therefore do not affect the result.
:::
::::

::::theorem "hc_sequential_bytes" (lean := "HashCommitment.twoFills_interpret") (uses := "hc_ideal_rng")
:::HashCommitmentBlueprint.pair HashCommitment.twoFills_interpret -docstrings
Two actual `fill_bytes` calls have the product of their uniform slice laws.
The second call does not reuse the first call’s samples, even though both use
the same unit handle.
:::
::::

::::theorem "hc_empty_fill" (lean := "HashCommitment.fill_empty") (uses := "hc_ideal_rng")
:::HashCommitmentBlueprint.pair HashCommitment.fill_empty -docstrings
An empty request returns the empty buffer without drawing randomness.
:::
::::

::::theorem "hc_fill_law" (lean := "HashCommitment.fill_interpret") (uses := "hc_ideal_rng, hc_interpret")
:::HashCommitmentBlueprint.pair HashCommitment.fill_interpret -docstrings
With sufficient fuel, the actual ideal `fill_bytes` result has the uniform
byte-vector law, preserves the unit handle and returns the entire replaced slice.
:::
::::

::::theorem "hc_adequacy" (lean := "HashCommitment.Probability.Program.interpret_toResult") (uses := "hc_interpret")
:::HashCommitmentBlueprint.pair HashCommitment.Probability.Program.interpret_toResult -docstrings
A finite program witnesses a bounded, successful effect tree. Its probability law
agrees with interpretation of that tree once the fuel reaches its depth.
:::
::::

::::theorem "hc_stability" (lean := "HashCommitment.Probability.Program.interpret_stable") (uses := "hc_adequacy")
:::HashCommitmentBlueprint.pair HashCommitment.Probability.Program.interpret_stable -docstrings
Increasing sufficient fuel does not change the distribution. The result is
therefore independent of an arbitrary larger interpreter bound.
:::
::::

# Joint commitment law

The relevant distribution contains the commitment, opening and final RNG handle
together. Separate marginal equalities would not determine how the returned
commitment depends on the opening. The bridge must also account for the array
slice and its write-back operation in the generated caller.

::::definition "hc_hash_refines" (lean := "HashCommitment.Bridge.HashRefines")
:::HashCommitmentBlueprint.pair HashCommitment.Bridge.HashRefines -docstrings
Hash refinement asserts that the extracted hash dictionary returns the specified
hash value successfully. This assumption is distinct from collision resistance.
:::
::::

::::definition "hc_witness" (lean := "HashCommitment.Bridge.commitProgram")
:::HashCommitmentBlueprint.pair HashCommitment.Bridge.commitProgram -docstrings
This finite witness records the joint output: digest, opening and final RNG
handle. It is hand-written. Its type alone does not connect it to Rust.
:::
::::

::::theorem "hc_representation" (lean := "HashCommitment.Bridge.commit_representation") (uses := "hc_extracted_commit, hc_ideal_rng, hc_hash_refines, hc_witness")
:::HashCommitmentBlueprint.pair HashCommitment.Bridge.commit_representation -docstrings
Under hash refinement, the complete generated commitment term equals the
embedding of the finite witness. This equality connects the implementation to the witness.
It includes the generated array/slice write-back.
:::
::::

::::theorem "hc_depth" (lean := "HashCommitment.Bridge.commit_depth") (uses := "hc_witness")
:::HashCommitmentBlueprint.pair HashCommitment.Bridge.commit_depth -docstrings
Thirty-two byte-sampling events and a return node give a sufficient bound of 33.
:::
::::

::::theorem "hc_joint_law" (lean := "HashCommitment.Bridge.commit_uniform_joint_law") (uses := "hc_representation, hc_adequacy, hc_depth")
:::HashCommitmentBlueprint.pair HashCommitment.Bridge.commit_uniform_joint_law -docstrings
Interpretation starts from the actual generated effect tree. The right-hand side
samples a uniform 32-byte opening and returns the digest, encoded opening and
unit handle together. With fuel at least 33, failure, divergence and cutoff have
zero probability.
:::
::::

# Correctness and composition

Correctness asks whether an honestly generated commitment verifies. A composed
experiment passes the generated result to an observer or
continuation. Its correspondence must therefore use the full generated
commitment law, rather than only the deterministic verifier equation.

::::theorem "hc_verify" (lean := "HashCommitment.Bridge.verify_refines") (uses := "hc_extracted_verify, hc_hash_refines")
:::HashCommitmentBlueprint.pair HashCommitment.Bridge.verify_refines -docstrings
Under hash refinement, generated verification returns exactly the model’s
Boolean result. This statement concerns verification, not honest sampling.
:::
::::

::::definition "hc_honest_execution" (lean := "HashCommitment.honestExecution") (uses := "hc_extracted_commit")
:::HashCommitmentBlueprint.pair HashCommitment.honestExecution -docstrings
This experiment calls generated commitment generation and then generated
verification. Both calls remain visible in the statement’s dependency chain.
:::
::::

::::theorem "hc_honest_representation" (lean := "HashCommitment.honest_representation") (uses := "hc_honest_execution, hc_representation, hc_verify")
:::HashCommitmentBlueprint.pair HashCommitment.honest_representation -docstrings
The honest execution retains its sampling events, and every sampled opening
is accepted under the hash-refinement assumption.
:::
::::

::::theorem "hc_honest_correct" (lean := "HashCommitment.honest_correct") (uses := "hc_honest_representation, hc_adequacy")
:::HashCommitmentBlueprint.pair HashCommitment.honest_correct -docstrings
The actual honest execution accepts with probability one. This statement does
not discard exceptional outcomes: their probability is zero.
:::
::::

::::theorem "hc_continuation" (lean := "HashCommitment.Bridge.commit_continuation") (uses := "hc_joint_law")
:::HashCommitmentBlueprint.pair HashCommitment.Bridge.commit_continuation -docstrings
Any probabilistic continuation sees the same joint returned value in the
implementation and its finite model. This experiment invokes the generated
commitment. It is not merely a verifier-level statement.
:::
::::

# Binding reduction

Binding prevents two different messages from opening the same commitment.
For this keyed hash construction, such a pair gives a hash collision under the
stated encoding and hash-refinement conditions.

> *Which code does the binding game use?* The VCVio binding game calls setup
> and verification. It does not call honest commitment generation. Binding alone
> therefore does not establish the RNG bridge. The joint commitment law and
> composed experiment address that separate obligation.

::::definition "hc_implementation_scheme" (lean := "HashCommitment.implementationScheme") (uses := "hc_witness, hc_extracted_verify")
:::HashCommitmentBlueprint.pair HashCommitment.implementationScheme -docstrings
The VCVio interface uses the finite commitment distribution and the generated
verifier. The representation and joint-law results separately justify this distribution
as the semantics of the generated commitment under ideal entropy.
:::
::::

::::theorem "hc_scheme_extracted" (lean := "HashCommitment.implementation_commit_extracted") (uses := "hc_joint_law, hc_implementation_scheme")
:::HashCommitmentBlueprint.pair HashCommitment.implementation_commit_extracted -docstrings
Decoding the canonical interpretation of the actual generated commitment gives
the scheme’s joint output distribution. This theorem connects the finite scheme
interface to the generated tree, whose semantics is defined independently.
:::
::::

::::theorem "hc_scheme_eq" (lean := "HashCommitment.implementation_eq_model") (uses := "hc_implementation_scheme, hc_model_scheme, hc_verify")
:::HashCommitmentBlueprint.pair HashCommitment.implementation_eq_model -docstrings
Hash refinement and the uniform opening law identify this interface with the
abstract commitment scheme. The key generator remains a parameter.
:::
::::

::::theorem "hc_binding" (lean := "HashCommitment.implementation_binding") (uses := "hc_scheme_eq")
:::HashCommitmentBlueprint.pair HashCommitment.implementation_binding -docstrings
Every binding adversary induces a keyed collision-finding adversary with at
least the same advantage. The reduction does not prove collision resistance.
A binding guarantee follows from an assumed bound on the hash family’s
collision-finding advantage.
:::
::::

# Assumptions and reproduction

The [source package](source/HashCommitment/README.md.html) records the Rust and
dependency pins, [toolchain identity](source/HashCommitment/patches/toolchain.json.html),
[Aeneas patch](source/HashCommitment/patches/aeneas-probabilistic.patch.html), generated
files and reproduction commands. The extraction check regenerates these files in a
temporary directory and compares them with the checked-in files. The extraction mode must match
the patched Lean backend.

The trust boundary includes the Rust-to-Lean translation, the ideal entropy
interpretation and the abstract hash interface. A proof under this interface does
not verify a concrete operating-system RNG or a concrete hash implementation.
The shared book uses the patched runtime explicitly. The independent DH and
Schnorr extraction pins and historical evidence remain unchanged.

The extraction regressions distinguish fresh sampling from reuse. They interpret
the actual generated Rust regression functions, not only hand-written samplers.

::::theorem "hc_fresh_regression" (lean := "HashCommitment.Regressions.extracted_fresh_probability") (uses := "hc_ideal_rng, hc_adequacy")
:::HashCommitmentBlueprint.pair HashCommitment.Regressions.extracted_fresh_probability -docstrings
Two independent one-byte draws are equal with probability $`1/256`.
:::
::::

::::theorem "hc_reused_regression" (lean := "HashCommitment.Regressions.extracted_reused_probability") (uses := "hc_ideal_rng, hc_adequacy")
:::HashCommitmentBlueprint.pair HashCommitment.Regressions.extracted_reused_probability -docstrings
One sampled byte used twice is equal to itself with probability one. Merging the
two calls in the preceding program would therefore change its probability law.
:::
::::
