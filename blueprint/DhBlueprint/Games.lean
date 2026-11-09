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

Let $`\mu,\nu` be laws on raw secrets. The experiments draw independently
from $`\mu` and $`\nu` and run the extracted session. The adversary observes
both public encodings and one key. Advantage is the absolute difference
of the two acceptance probabilities.

::::definition "real_game" (lean := "DhConcrete.nativeReal") (uses := "extracted_session")
:::AnchorlessBlueprint.pair DhConcrete.nativeReal -docstrings
The real experiment supplies Alice's computed key. A non-success result
maps to `false`; {bpref "session_refinement"}[session refinement] excludes
that branch under the selected configuration.
:::
::::

::::definition "ideal_game" (lean := "DhConcrete.nativeIdeal") (uses := "extracted_session")
:::AnchorlessBlueprint.pair DhConcrete.nativeIdeal -docstrings
The ideal experiment retains the native public outputs and supplies
$`k(cg)` for an independent uniform $`c\in\mathbb Z/L\mathbb Z`.
Thus the ideal challenge is an encoded group element, rather than a
uniform byte string.
:::
::::

::::definition "encoding_reduction" (lean := "DhPoc.rawReduction")
:::AnchorlessBlueprint.pair DhPoc.rawReduction -docstrings
For the concrete model, the reduction is

$$`R_A(g,X,Y,Z)=A(p(X),p(Y),k(Z)).`

It applies the canonical encodings and invokes $`A` once.
:::
::::

::::theorem "game_transport" (lean := "DhConcrete.nativeAdvantage_eq") (uses := "session_refinement, real_game, ideal_game, encoding_reduction")
:::AnchorlessBlueprint.pair DhConcrete.nativeAdvantage_eq -docstrings
For the selected backend and arbitrary raw-secret laws,

$$`\operatorname{Adv}_{\rm native}(\mu,\nu,A)
=\operatorname{Adv}_{\rm sampledDDH}(d,g,\mu,\nu,R_A).`

The equality preserves the input distributions. It follows from the
real and ideal game equalities, each obtained by substituting the
session refinement.
:::
::::
