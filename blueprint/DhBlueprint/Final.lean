import Verso
import VersoManual
import VersoBlueprint
import DhBlueprint.Code
import Concrete.Standard

open Verso.Genre Verso.Genre.Manual Informal

#doc (Manual) "Final security bound" =>
%%%
tag := "final"
%%%

The {bpref "game_transport"}[implementation bridge] and
{ref "sampling"}[sampling comparison] transfer a supplied DDH bound to
the extracted session. The {ref "trust"}[scope statement] records the trust
boundary and the separate requirements for resource-bounded and asymptotic conclusions.

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
