import Verso
import VersoManual
import VersoBlueprint
import DhBlueprint.Code
import Concrete.Standard
import DhPoc.Parameterized
import DhPoc.PPT
import DhPoc.CoinResources

open Verso.Genre Verso.Genre.Manual Informal

#doc (Manual) "Final security bound" =>
%%%
tag := "final"
%%%

# Native implementation

The {bpref "game_transport"}[implementation bridge] and
{ref "sampling"}[sampling comparison] give the bound for the fixed native
implementation. The family results below concern the generic sampled model.
A native-family instantiation requires a refinement proof at every parameter.

Let $`G,g` be the {ref "games"}[concrete group and basepoint].
Let $`B=\mathrm{Bytes}_{32}`,
$`p:G\to B` the canonical Ristretto encoding, and
$`k(P)=\mathrm{some}(p(P))`. Let $`\Omega` be the uniform law on
64-byte inputs. The experiments draw the two inputs independently.

::::theorem "final_bound" (lean := "DhConcrete.wideAdvantage_le_of_standardDDH") (uses := "game_transport, bias_bound, hybrid_bound, numeric_loss")
:::AnchorlessBlueprint.pair DhConcrete.wideAdvantage_le_of_standardDDH -docstrings
Assume `Aeneas.Std.target = "x86_64-no-tables"` and fix a passive adversary
$`A:B\to B\to\mathrm{Option}(B)\to\mathrm{ProbComp}(\mathrm{Bool})`.
Let $`R_A(g,X,Y,Z)=A(p(X),p(Y),k(Z))`.
For $`\varepsilon\in\mathbb R_{\ge0}\cup\{\infty\}`, if
$`\operatorname{Adv}_{\rm DDH}(g,R_A)\le\varepsilon`, then

$$`\operatorname{Adv}_{\rm native}(\Omega,\Omega,A)
\le\varepsilon+2^{-260}.`
:::
::::

# Group order and sampling width

Let $`q` be prime and $`w\in\mathbb N` be a sampling width. Put
$`N=2^w` and $`\delta(q,w)=(N\bmod q)/N`.

::::definition "prime_order_model" (lean := "DhPoc.PrimeOrderModel") (uses := "primitive_model")
:::AnchorlessBlueprint.pair DhPoc.PrimeOrderModel -docstrings
Raw values lie in $`\mathrm{Fin}(2^w)` and decode modulo $`q` into
$`\mathbb Z/q\mathbb Z`. The model supplies the primitive contracts and
representation maps. Every group element is a unique scalar multiple of
its generator, so $`q` is the group order.
:::
::::

Fix such a model $`M` and put $`g=M.\mathrm{generator}`.
Let $`\Omega_w=U_{\mathrm{Fin}(2^w)}` be the uniform raw sampler,
and let $`A` be a session adversary.
Write $`\operatorname{Adv}_{\rm session}(M,A)` for the advantage of
`sampledReal` and `sampledIdeal` with `M.toRawPrimitiveModel` and two independent
$`\Omega_w` draws. Let $`R_A` be `rawReduction M.toRawPrimitiveModel A`.

::::theorem "parameterized_bound" (lean := "DhPoc.moduloSessionAdvantage_le_standard") (uses := "prime_order_model, hybrid_bound")
:::AnchorlessBlueprint.pair DhPoc.moduloSessionAdvantage_le_standard -docstrings
For every $`A`,

$$`\operatorname{Adv}_{\rm session}(M,A)
\le\operatorname{Adv}_{\rm DDH}(g,R_A)+4\delta(q,w).`

Counting residues modulo $`q` bounds total variation by $`\delta(q,w)`.
The four replacements give the displayed loss.
:::
::::

# Negligible advantage

Let $`\lambda\in\mathbb N` index models $`M_\lambda` with prime orders
$`q(\lambda)` and widths $`w(\lambda)`. Choose $`b:\mathbb N\to\mathbb N`
such that, for every $`\lambda`,

$$`q(\lambda)\le2^{b(\lambda)},\qquad
w(\lambda)\ge b(\lambda)+\lambda+2.`

Then $`4\delta(q(\lambda),w(\lambda))\le2^{-\lambda}`.
A nonnegative family is [negligible](https://github.com/Verified-zkEVM/VCVio/blob/88efe9715a9fa9e7d89635c38cf70259836766c2/VCVio/CryptoFoundations/Asymptotics/Negligible.lean#L39-L40) if, for every positive integer $`c`,
it is at most $`\lambda^{-c}` for all sufficiently large $`\lambda`.
For an adversary family $`A=(A_\lambda)`, let $`R_A` denote
[`familyReduction M A`](source/lean/DhPoc/Parameterized.lean.html#L67),
the encoding reduction at each parameter.
Write $`g_\lambda=M_\lambda.\mathrm{generator}`.
[`parameterizedSessionAdvantage M A`](source/lean/DhPoc/Parameterized.lean.html#L72)
is the family $`\lambda\mapsto\operatorname{Adv}_{\rm session}(M_\lambda,A_\lambda)`.

::::theorem "parameterized_negligibility" (lean := "DhPoc.parameterizedSessionAdvantage_negligible") (uses := "parameterized_bound")
:::AnchorlessBlueprint.pair DhPoc.parameterizedSessionAdvantage_negligible -docstrings
Under this width schedule, if
$`\lambda\mapsto\operatorname{Adv}_{\rm DDH}(g_\lambda,R_{A_\lambda})`
is negligible, then
$`\lambda\mapsto\operatorname{Adv}_{\rm session}(M_\lambda,A_\lambda)`
is negligible.
:::
::::

Choose classes $`\mathcal C_S` and $`\mathcal C_D` of session and DDH
adversary families. VCVio's [`secureAgainst`](https://github.com/Verified-zkEVM/VCVio/blob/88efe9715a9fa9e7d89635c38cf70259836766c2/VCVio/CryptoFoundations/Asymptotics/Security.lean#L55-L56)
means that every member of the chosen class has negligible advantage.
The [session](source/lean/DhPoc/Parameterized.lean.html#L92) and
[DDH](source/lean/DhPoc/Parameterized.lean.html#L97) game wrappers collect
the advantage families above. Applications supply the efficiency
predicates and justify their resource interpretation.

::::theorem "parameterized_security" (lean := "DhPoc.parameterizedSession_secure") (uses := "parameterized_negligibility")
:::AnchorlessBlueprint.pair DhPoc.parameterizedSession_secure -docstrings
Under the same width schedule, suppose the encoding reduction maps
$`\mathcal C_S` into $`\mathcal C_D` and DDH is secure against
$`\mathcal C_D`. Then the generic sampled-session family is secure against
$`\mathcal C_S`.
:::
::::

# Backend-relative strict PPT

Here an adversary is one fair-coin program whose
[input](source/lean/DhPoc/PPT.lean.html#L112) contains the parameter and session
transcript. VCVio's [`IsPPTBy`](https://github.com/Verified-zkEVM/VCVio/blob/88efe9715a9fa9e7d89635c38cf70259836766c2/VCVio/CryptoFoundations/Asymptotics/ComputationalComplexity.lean#L371)
certifies strict polynomial bounds relative to the chosen backend and input representations.

The reduction first runs the deterministic
[encoding](source/lean/DhPoc/PPT.lean.html#L148), then calls the same adversary.
`PolyRealizer` certifies executable encoding code and polynomial work and output size.
`PolynomialComposition` bounds its composition overhead. These certificates
derive strict-PPT preservation. The
[semantic bridge](source/lean/DhPoc/PPT.lean.html#L161) identifies this reduction
with the preceding probability-level reduction.

A conventional machine-model interpretation still needs backend adequacy,
a unary parameter representation and polynomial growth of other represented inputs.
Native parameter generation, sampling and curve-operation costs require separate arguments.

::::theorem "ppt_security" (lean := "DhPoc.PPT.session_secure_isPPTBy") (uses := "parameterized_negligibility")
:::AnchorlessBlueprint.pair DhPoc.PPT.session_secure_isPPTBy -docstrings
Under the same order and width assumptions, suppose the encoding has a
`PolyRealizer` certificate and the backend has a `PolynomialComposition` certificate.
If DDH is secure against `IsPPTBy` at the DDH input boundary, then the
sampled session is secure against `IsPPTBy` at the session input boundary.
:::
::::

# Experiments with explicit fair coins

The preceding ideal game samples its challenge uniformly from the scalar field.
Here both experiments use only fair-coin queries, including the challenge sampler.
Fix a prime-order model $`M` with generator $`g` and retain the sampling error $`\delta(q,w)`.

::::theorem "coin_sampler" (lean := "DhPoc.CoinSampling.sample_evalDistEq")
:::AnchorlessBlueprint.pair DhPoc.CoinSampling.sample_evalDistEq -docstrings
The recursive sampler `CoinSampling.sample w` has exactly the uniform law on
$`\mathrm{Fin}(2^w)`. Its
[`sample_rollBound`](source/lean/DhPoc/CoinSampling.lean.html#L28) theorem
bounds every branch by $`w` coin queries. No rejection loop is needed.
:::
::::

The [real experiment](source/lean/DhPoc/CoinSecurity.lean.html#L24) samples two
raw values, then calls the extracted `dh_core.session M.operations`.
The [ideal experiment](source/lean/DhPoc/CoinSecurity.lean.html#L33) also samples
an independent raw value $`c` and uses $`M.\mathrm{key}(M.\mathrm{scalar}(c)g)`
as its challenge. Both experiments then call the same coin-program adversary $`A`.
Write $`\operatorname{Adv}_{\rm coin}(M,A)` for their acceptance-probability difference,
and let $`R_A` be the encoding reduction after fair-coin interpretation.

::::theorem "coin_bound" (lean := "DhPoc.CoinSecurity.advantage_le_standard") (uses := "coin_sampler, parameterized_bound")
:::AnchorlessBlueprint.pair DhPoc.CoinSecurity.advantage_le_standard -docstrings
For every coin-program adversary $`A`,

$$`\operatorname{Adv}_{\rm coin}(M,A)
\le\operatorname{Adv}_{\rm DDH}(g,R_A)+5\delta(q,w).`

The extra $`\delta(q,w)` accounts for the reduced raw challenge in the ideal game.
The earlier game with a uniform scalar challenge retains its $`4\delta(q,w)` bound.
:::
::::

::::theorem "coin_ppt_security" (lean := "DhPoc.CoinSecurity.session_secure_isPPTBy") (uses := "coin_bound, ppt_security")
:::AnchorlessBlueprint.pair DhPoc.CoinSecurity.session_secure_isPPTBy -docstrings
Under the same order and width schedule, $`5\delta(q(\lambda),w(\lambda))`
is negligible. If the encoding has a `PolyRealizer` certificate, the backend
has a `PolynomialComposition` certificate, and DDH is secure against `IsPPTBy`
at its input boundary, then the coin experiments are secure against `IsPPTBy`
at the session input boundary.
:::
::::

::::theorem "coin_resources" (lean := "DhPoc.CoinResources.games_polynomial_coinBound") (uses := "coin_sampler")
:::AnchorlessBlueprint.pair DhPoc.CoinResources.games_polynomial_coinBound -docstrings
Suppose $`A` satisfies `IsPPTBy`. Assume polynomial upper bounds in $`\lambda`
on the represented session-input size and on $`w(\lambda)`.
Then one polynomial bounds the number of coin queries on every branch of
both complete experiments. The proof derives the adversary's query bound
from its strict-PPT witness and adds at most $`3w(\lambda)` honest queries.
:::
::::

This last theorem counts randomness, not the running time of honest arithmetic.
Its input-size and width upper bounds are explicit premises. The width lower
bound used for negligible bias does not supply them.

# From the security statements to Rust

The two conclusions use different extracted entry points. The following paths
read backwards from each security statement to its program.

## Parameterized session

The {bpref "coin_ppt_security"}[coin-experiment theorem] first uses
[`advantage_negligible`](source/lean/DhPoc/CoinSecurity.lean.html#L190)
and {bpref "coin_bound"}[the five-error bound]. The
[`real_evalDistEq`](source/lean/DhPoc/CoinSecurity.lean.html#L53) and
[`ideal_evalDistEq`](source/lean/DhPoc/CoinSecurity.lean.html#L67) lemmas
connect its coin syntax to the sampled experiments, with one additional
ideal-challenge comparison. It then uses the same generic refinement path below.

1. {bpref "ppt_security"}[Strict-PPT security] uses
   [`parameterizedSessionAdvantage_negligible`](source/lean/DhPoc/Parameterized.lean.html#L81).
   [`ddhFamily_reduce`](source/lean/DhPoc/PPT.lean.html#L161) identifies its
   coin-program reduction with `familyReduction`.
2. The negligibility proof uses
   [`moduloSessionAdvantage_le_standard`](source/lean/DhPoc/Parameterized.lean.html#L34).
   That bound first rewrites the session advantage with
   [`sampledSessionAdvantage_eq`](source/lean/DhPoc/RawSecurity.lean.html#L83),
   then applies the sampling comparison.
3. The real and ideal game equalities use
   [`raw_session_refines`](source/lean/DhPoc/RawSampler.lean.html#L33).
   This theorem unfolds the Aeneas entry
   [`dh_core.session`](source/lean/DhPoc/Generated/DhCore.lean.html#L43)
   under the `public_spec` and `agree_spec` contracts of `RawPrimitiveModel`.
4. Aeneas generated that entry from
   [`session<D: Dh>`](source/rust/src/lib.rs.html#L24).
   The Rust function supplies the protocol control flow. Its `Dh` trait
   leaves the primitive implementation abstract.

Thus the family theorem concerns the extracted generic Rust session under
primitive contracts at every parameter. It does not instantiate a growing
family of native curve implementations.

## Fixed native session

1. {bpref "final_bound"}[The native bound] uses
   [`wideAdvantage_le_standard`](source/concrete/Concrete/Standard.lean.html#L11)
   and the numerical sampling bound.
2. [`wideAdvantage_eq`](source/concrete/Concrete/Wide.lean.html#L9) specializes
   [`nativeAdvantage_eq`](source/concrete/Concrete/Native.lean.html#L79).
   The latter uses `nativeReal_eq`, `nativeIdeal_eq`, and `advantage_eq`
   to identify the native and sampled-DDH experiments.
3. Those game equalities use
   [`native_session_refines`](source/concrete/Concrete/Native.lean.html#L28).
   Its `native_public_eq` and `native_agree_eq` contracts connect the
   selected generated primitives to the imported BAIF specifications.
4. The refinement unfolds
   [`Curve25519Dalek.poc_dh.session`](source/concrete/Concrete/GeneratedAdapter.lean.html#L184),
   extracted from [`poc_dh::session`](source/concrete/rust/poc_dh.rs.html#L25).
   The [extraction manifest](source/concrete/evidence/extraction-inputs.json)
   and [linkage comparison](source/concrete/evidence/linkage-comparison.json)
   record its connection to the pinned dalek backend.

This path requires `Aeneas.Std.target = "x86_64-no-tables"` and uses two
independent uniform 64-byte inputs. The Rust wrapper receives those inputs
from its caller. The theorem bounds its advantage by the supplied DDH bound
plus $`2^{-260}`. It does not prove native runtime or an asymptotic
security claim for this fixed curve.
