import Verso
import VersoManual
import VersoBlueprint
import DhBlueprint.Code
import Concrete.Standard
import DhPoc.Parameterized
import DhPoc.PPT

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
