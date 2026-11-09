import Verso
import VersoManual
import VersoBlueprint
import DhBlueprint.Code
import Concrete.Standard

open Verso.Genre Verso.Genre.Manual Informal

#doc (Manual) "Games and reduction" =>
%%%
tag := "games"
%%%

# Model and origin

The extracted [`dh_core.Dh`](source/lean/DhPoc/Generated/DhCore.lean.html)
interface supplies `public` and `agree`. The following structure adds their
group specifications and representation maps.

::::definition "primitive_model" (lean := "DhPoc.RawPrimitiveModel")
:::AnchorlessBlueprint.pair DhPoc.RawPrimitiveModel -docstrings
The model bundles the operations, a decoder $`S\to F` for secret inputs,
public and key encodings, a basepoint, and two primitive correctness equations.
“Raw” means that the secret type $`S` is the caller's input representation,
before scalar decoding. Here $`S=\mathrm{Bytes}_{64}` and
$`d(s)=\operatorname{LE}(s)\bmod L`.
:::
::::

The local [`DhConcrete.model`](source/concrete/Concrete/Model.lean.html)
instantiates this interface with the extracted primitive compositions,
scalar reduction, canonical encoding, and proved contracts.
Its [algebra](source/concrete/Concrete/Algebra.lean.html) is
$`F=\mathbb Z/L\mathbb Z` and $`G=E[L]`, with the Edwards basepoint $`g`.
The curve definitions and Ristretto codec come from
[BAIF's pinned dalek development](https://github.com/Beneficial-AI-Foundation/curve25519-dalek-fork/tree/95b5831c63ff1c5f6287bd3a77569412a9afdbfb/Curve25519).
The local wire model converts `Ristretto.encodeRep` to 32 bytes and wraps
shared encodings in `some`.

[VCVio at `88efe971`](https://github.com/Verified-zkEVM/VCVio/tree/88efe9715a9fa9e7d89635c38cf70259836766c2)
supplies `ProbComp`, distribution semantics, acceptance-probability distance,
and the standard DDH experiments below. The native protocol experiments and
the raw-sampler DDH experiments are local definitions. They model one completed
honest exchange, with a passive adversary that receives two public values and one key.

:::AnchorlessBlueprint.note "VCVio: computations and oracles"
`OracleComp` describes a computation that may query typed oracles.
An oracle implementation supplies the replies and any state changes.
`ProbComp` specializes this interface to probabilistic sampling.
Here the adversary receives its three inputs once and returns a bit.
It has no protocol oracle for further sessions, corruption, or key release.
:::

This model instantiates the generic sampled experiments. The native
experiments below call the concrete implementation directly. In
[`CKAScheme`](https://github.com/a-dangelo/secure-messaging/blob/750c725fd91c58158218bff678c6bc1aadd196d7/SecureMessaging/CKA/Defs.lean),
the interface bundles algorithms for repeated key updates.
[`ddhCKA`](https://github.com/a-dangelo/secure-messaging/blob/750c725fd91c58158218bff678c6bc1aadd196d7/SecureMessaging/CKA/FromDDH/Construction.lean)
instantiates that scheme for separate stateful oracle games.

# Extracted implementation experiments

Let $`\mu,\nu` be laws on raw secrets. Both experiments draw independently
from these laws and evaluate the Aeneas declaration
`Curve25519Dalek.poc_dh.session`. The adversary returns a `ProbComp Bool` computation.

::::definition "real_game" (lean := "DhConcrete.nativeReal") (uses := "extracted_session")
:::AnchorlessBlueprint.pair DhConcrete.nativeReal -docstrings
The real experiment supplies Alice's computed key. The code matches on
`(poc_dh.session a b).match` and maps a non-success result to `false`.
{bpref "session_refinement"}[Session refinement] excludes that branch under
`x86_64-no-tables`, for every pair of raw inputs.
:::
::::

::::definition "ideal_game" (lean := "DhConcrete.nativeIdeal") (uses := "extracted_session")
:::AnchorlessBlueprint.pair DhConcrete.nativeIdeal -docstrings
The ideal experiment executes the same extracted session and retains its
public outputs. It supplies $`k(cg)` for an independent uniform
$`c\in F`. The challenge is an encoded group element, not a uniform byte string.
:::
::::

# Exact implementation bridge

Write $`M` for `DhConcrete.model`. The following are equalities of
`ProbComp` terms. They preserve $`A`, $`\mu`, and $`\nu`. They do not condition
on a successful run or introduce an abort-probability loss.

::::theorem "real_transport" (lean := "DhConcrete.nativeReal_eq") (uses := "real_game, session_refinement")
:::AnchorlessBlueprint.pair DhConcrete.nativeReal_eq -docstrings
Under the selected target configuration,

$$`\mathrm{nativeReal}(\mu,\nu,A)=\mathrm{sampledReal}(M,\mu,\nu,A).`

Substitute the complete successful-output equation into each definition.
The remaining computation is definitionally equal.
:::
::::

::::theorem "ideal_transport" (lean := "DhConcrete.nativeIdeal_eq") (uses := "ideal_game, session_refinement")
:::AnchorlessBlueprint.pair DhConcrete.nativeIdeal_eq -docstrings
Under the same configuration,

$$`\mathrm{nativeIdeal}(\mu,\nu,A)=\mathrm{sampledIdeal}(M,\mu,\nu,A).`

The independent uniform challenge is unchanged.
:::
::::

# Standard DDH and the encoding reduction

Instantiate VCVio's scalar action with $`F,G,g` as above and the uniform
sampler on $`F`. These are the imported reference experiments.

::::definition "ddh_real" (lean := "DiffieHellman.ddhRealExperiment")
:::AnchorlessBlueprint.pair DiffieHellman.ddhRealExperiment -docstrings
Draw independent uniform $`x,y\in F` and return
$`R(g,xg,yg,(xy)g)`.
:::
::::

::::definition "ddh_random" (lean := "DiffieHellman.ddhRandomExperiment")
:::AnchorlessBlueprint.pair DiffieHellman.ddhRandomExperiment -docstrings
Draw independent uniform $`x,y,z\in F` and return
$`R(g,xg,yg,zg)`.
:::
::::

::::definition "encoding_reduction" (lean := "DhPoc.rawReduction")
:::AnchorlessBlueprint.pair DhPoc.rawReduction -docstrings
For the concrete model, define

$$`R_A(g,X,Y,Z)=A(p(X),p(Y),k(Z)).`

The reduction computes three canonical encodings and invokes $`A` once.
A computational-cost claim must account for these encodings.
:::
::::

::::theorem "game_transport" (lean := "DhConcrete.nativeAdvantage_eq") (uses := "real_transport, ideal_transport, encoding_reduction")
:::AnchorlessBlueprint.pair DhConcrete.nativeAdvantage_eq -docstrings
For the selected target and arbitrary raw-secret laws,

$$`\operatorname{Adv}_{\rm native}(\mu,\nu,A)
=\operatorname{Adv}_{\rm sampledDDH}(d,g,\mu,\nu,R_A).`

The proof first applies the two native game equalities, then
[`DhConcrete.advantage_eq`](source/concrete/Concrete/Security.lean.html), which
instantiates `DhPoc.sampledSessionAdvantage_eq`.
The local [sampled-DDH games](source/lean/DhPoc/RawSecurity.lean.html)
preserve $`\mu,\nu` and decode their samples. This equality alone gives
no hardness bound for these laws. {ref "sampling"}[Sampling comparison]
relates the wide-input law to the standard uniform-scalar experiments.
:::
::::
