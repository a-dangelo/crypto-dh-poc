import Verso
import VersoManual
import VersoBlueprint
import DhBlueprint.Code
import Concrete.Standard

open Verso.Genre Verso.Genre.Manual Informal

#doc (Manual) "Program and refinement" =>
%%%
tag := "refinement"
%%%

The Rust entry point is [`poc_dh::session`](source/concrete/rust/poc_dh.rs.html#L25).
It calls `public` twice and `agree` twice, with explicit 64-byte secrets and
canonical 32-byte public values. Charon and Aeneas extract this wrapper together
with patched BAIF dalek 5.0.0 at
`95b5831c63ff1c5f6287bd3a77569412a9afdbfb`.

# Declaration origins

`Concrete.GeneratedAdapter` contains declarations copied from the full Aeneas
output by [`slice-concrete.py`](source/scripts/slice-concrete.py).
Its import and header are local packaging. The retained declarations are
`poc_dh.Session`, `poc_dh.session`, and the `public` and `agree` dispatchers,
each with four target-specific implementations: twelve declarations in total.
The theorem below selects only `x86_64-no-tables`.

The adapter imports the extracted `Curve25519Dalek.Funs` backend.
The [linkage report](source/concrete/evidence/linkage-comparison.json)
records 129 unchanged type blocks and 2,731 unchanged function or implementation
blocks against the pinned backend, after comment and outer-whitespace normalization.
These counts describe the backend comparison, not this theorem's dependency closure.
The [extraction manifest](source/concrete/evidence/extraction-inputs.json)
records the wrapper, patches and output hashes. The documentation replay checks
these retained artifacts; it does not repeat extraction.

# Extracted concrete session

::::definition "extracted_session" (lean := "Curve25519Dalek.poc_dh.session")
:::AnchorlessBlueprint.pair Curve25519Dalek.poc_dh.session -docstrings
*Origin: Aeneas output, retained by the slicer.*

This is the translated `poc_dh.session`. It computes two public values and
two local keys, propagating Aeneas failures. This declaration is the entry called by
{bpref "real_game"}[the native real experiment] and
{bpref "ideal_game"}[the native ideal experiment].
:::
::::

::::theorem "public_contract" (lean := "DhConcrete.native_public_eq")
:::AnchorlessBlueprint.pair DhConcrete.native_public_eq -docstrings
*Origin: hand-written refinement theorem.*

For every $`s\in\mathrm{Bytes}_{64}`, under the target configuration,

$$`\mathrm{public}(s)=\mathrm{ok}(p(d(s)g)).`

`extracted_public_link` proves the selected generated wrapper equal to
`publicCompose` by `rfl`. The composition's mathematical result follows
from the imported BAIF specifications.
:::
::::

::::theorem "agreement_contract" (lean := "DhConcrete.native_agree_eq")
:::AnchorlessBlueprint.pair DhConcrete.native_agree_eq -docstrings
*Origin: hand-written refinement theorem.*

Under the same target configuration, for every 64-byte secret input $`s` and $`P\in G`,

$$`\mathrm{agree}(s,p(P))=\mathrm{ok}(k(d(s)P)).`

`extracted_agree_link` is the corresponding definitional equality for
`agreeCompose`. The proof uses the BAIF decompression, multiplication and
compression specifications. The Ristretto relation identifies the encoding
even when decoding chooses a different Edwards representative.
:::
::::

::::theorem "session_refinement" (lean := "DhConcrete.native_session_refines") (uses := "extracted_session, public_contract, agreement_contract")
:::AnchorlessBlueprint.pair DhConcrete.native_session_refines -docstrings
*Origin: hand-written refinement theorem about the extracted session.*

Under that configuration, for all 64-byte inputs $`a,b`, put $`\alpha=d(a)` and $`\beta=d(b)`.
The extracted session returns

$$`\mathrm{ok}\,(p(\alpha g),p(\beta g),
k(\alpha\beta g),k(\alpha\beta g)).`

Substitution of the two primitive contracts proves total successful
execution and honest agreement. Commutativity identifies the local keys.
:::
::::

# Extracted operations inside wrappers

The hand-written [`publicCompose` and `agreeCompose`](source/concrete/Concrete/Primitives.lean.html)
call extracted backend operations: wide scalar reduction, basepoint multiplication,
decompression, point multiplication, compression, and conversion to bytes.
The imported BAIF specifications prove their mathematical behavior.
`extracted_public_link` and `extracted_agree_link` identify these compositions
with the selected extracted wrapper implementations by `rfl`.

The {bpref "session_refinement"}[session-refinement proof] unfolds `poc_dh.session`
and applies the two primitive contracts. The hand-written native experiments
{bpref "real_game"}[`nativeReal`] and {bpref "ideal_game"}[`nativeIdeal`] call that
same extracted declaration. The {bpref "real_transport"}[real] and
{bpref "ideal_transport"}[ideal] transport theorems connect them to the generic
sampled games. The {bpref "game_transport"}[advantage equality] and
{ref "sampling"}[sampling comparison] then give the {bpref "final_bound"}[native bound].

[The Rust wrapper](source/concrete/rust/poc_dh.rs.html) ·
[Primitive proofs](source/concrete/Concrete/Primitives.lean.html) ·
[Encoding and group model](source/concrete/Concrete/Algebra.lean.html) ·
[Extraction comparison](source/concrete/evidence/linkage-comparison.json)
