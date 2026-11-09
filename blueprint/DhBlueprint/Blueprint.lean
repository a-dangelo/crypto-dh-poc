import Verso
import VersoManual
import VersoBlueprint
import DhBlueprint.Code
import Concrete.Standard

import VersoBlueprint.Commands.Graph
import VersoBlueprint.Commands.Summary
import DhBlueprint.Refinement
import DhBlueprint.DH
import DhBlueprint.Games
import DhBlueprint.Sampling
import DhBlueprint.Trust

open Verso.Genre Verso.Genre.Manual Informal

#doc (Manual) "A Rust DH session, verified in Lean" =>

We verify a coin-explicit Rust implementation of one passive Ristretto
Diffie–Hellman session. Charon and Aeneas translate the wrapper and patched
BAIF dalek backend. The Lean development proves functional refinement and
a reduction to VCVio's standard DDH game.

Throughout, $`L` is the scalar order, $`G=E[L]` the Edwards torsion subgroup,
and $`g` the selected basepoint. Write $`p:G\to B` for canonical Ristretto
encoding into $`B=\mathrm{Bytes}_{32}`, and $`k(P)=\mathrm{some}(p(P))`.
Let $`\Omega` be the uniform law on 64-byte inputs and
$`d(s)=\operatorname{LE}(s)\bmod L`.

::::theorem "main_bound" (lean := "DhConcrete.wideAdvantage_le_of_standardDDH") (uses := "game_transport, bias_bound, hybrid_bound, numeric_loss")
:::AnchorlessBlueprint.pair DhConcrete.wideAdvantage_le_of_standardDDH -docstrings
Assume `Aeneas.Std.target = "x86_64-no-tables"` and fix a passive adversary
$`A:B\to B\to\mathrm{Option}(B)\to\mathrm{ProbComp}(\mathrm{Bool})`.
Let $`R_A(g,X,Y,Z)=A(p(X),p(Y),k(Z))`.
For $`\varepsilon\in\mathbb R_{\ge0}\cup\{\infty\}`, if
$`\operatorname{Adv}_{\rm DDH}(g,R_A)\le\varepsilon`, then

$$`\operatorname{Adv}_{\rm native}(\Omega,\Omega,A)
\le\varepsilon+2^{-260}.`

The two inputs are independent. The native experiments execute the
extracted `poc_dh.session`. The proof combines exact game transport with
four sampling replacements.
:::
::::

`x86_64-no-tables` selects the serial x86-64 backend without precomputed
tables. {bpref "session_refinement"}[Session refinement] states its full
successful-output equation.

:::AnchorlessBlueprint.note "VCVio: the adversary type"
An adversary $`A` is a randomized test of two public encodings and a challenge
key. [`ProbComp Bool`](https://github.com/Verified-zkEVM/VCVio/blob/88efe9715a9fa9e7d89635c38cf70259836766c2/VCVio/OracleComp/ProbComp/Basic.lean#L28-L31) is VCVio's type for a probabilistic computation that
returns a bit. The experiment accepts when this bit is `true`.
`Option B` permits rejection by agreement on an invalid public encoding.
The honest sessions here return `some` of a 32-byte shared encoding.
:::

Here $`\operatorname{Adv}_{\rm native}` is the absolute difference between
acceptance probabilities in {bpref "real_game"}[the real experiment] and
{bpref "ideal_game"}[the ideal experiment].
{bpref "encoding_reduction"}[The encoding reduction] defines $`R_A`.
{ref "dh"}[Diffie–Hellman in one page] describes the exchange.

The axiom closure is Lean's standard three axioms together with
`RustAx.core` and `RustAx.subtle`. The result concerns the patched,
selected backend in Aeneas semantics. {ref "trust"}[Trust and provenance]
records the extraction boundary and excluded runtime claims.

Original proof revision: `a27d45ad02331a96279032a11872d6ec7af47860`.
[Source manifest](source/manifest.json) · [Download source](source-snapshot.zip)

{include 0 DhBlueprint.DH}
{include 0 DhBlueprint.Refinement}
{include 0 DhBlueprint.Games}
{include 0 DhBlueprint.Sampling}
{include 0 DhBlueprint.Trust}

{blueprint_graph (direction := LR)}
{blueprint_summary}
