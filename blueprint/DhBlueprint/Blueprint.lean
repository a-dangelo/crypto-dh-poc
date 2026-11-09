import Verso
import VersoManual
import VersoBlueprint
import DhBlueprint.Code
import Concrete.Standard

import VersoBlueprint.Commands.Graph
import VersoBlueprint.Commands.Summary
import DhBlueprint.Refinement
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
Fix the `x86_64-no-tables` configuration and an adversary
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

The axiom closure is Lean's standard three axioms together with
`RustAx.core` and `RustAx.subtle`. The result concerns the patched,
selected backend in Aeneas semantics. {ref "trust"}[Trust and provenance]
records the extraction boundary and excluded runtime claims.

Proof snapshot: `a27d45ad02331a96279032a11872d6ec7af47860`.
[Source manifest](source/manifest.json) · [Download source](source-snapshot.zip)

{include 0 DhBlueprint.Refinement}
{include 0 DhBlueprint.Games}
{include 0 DhBlueprint.Sampling}
{include 0 DhBlueprint.Trust}

{blueprint_graph (direction := LR)}
{blueprint_summary}
