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

`Concrete.GeneratedAdapter` imports the retained `Curve25519Dalek.Funs`
backend and contains the extracted `Curve25519Dalek.poc_dh.session` below.
The [linkage report](source/concrete/evidence/linkage-comparison.json)
checks the full extraction against the pinned backend declarations.
The [extraction manifest](source/concrete/evidence/extraction-inputs.json)
records the wrapper, patches and output hashes.

::::definition "extracted_session" (lean := "Curve25519Dalek.poc_dh.session")
:::AnchorlessBlueprint.pair Curve25519Dalek.poc_dh.session -docstrings
The extracted session computes two public values and two local keys,
propagating Aeneas failures. This declaration is the entry called by
{bpref "real_game"}[the native real experiment] and
{bpref "ideal_game"}[the native ideal experiment].
:::
::::

::::theorem "public_contract" (lean := "DhConcrete.native_public_eq")
:::AnchorlessBlueprint.pair DhConcrete.native_public_eq -docstrings
For every $`s\in\mathrm{Bytes}_{64}`, under the target configuration,

$$`\mathrm{public}(s)=\mathrm{ok}(p(d(s)g)).`

`extracted_public_link` proves the selected generated wrapper equal to
`publicCompose` by `rfl`. The composition's mathematical result follows
from the imported BAIF specifications.
:::
::::

::::theorem "agreement_contract" (lean := "DhConcrete.native_agree_eq")
:::AnchorlessBlueprint.pair DhConcrete.native_agree_eq -docstrings
Under the same target configuration, for every raw secret $`s` and $`P\in G`,

$$`\mathrm{agree}(s,p(P))=\mathrm{ok}(k(d(s)P)).`

`extracted_agree_link` is the corresponding definitional equality for
`agreeCompose`. The proof uses the BAIF decompression, multiplication and
compression specifications. The Ristretto relation identifies the encoding
even when decoding chooses a different Edwards representative.
:::
::::

::::theorem "session_refinement" (lean := "DhConcrete.native_session_refines") (uses := "extracted_session, public_contract, agreement_contract")
:::AnchorlessBlueprint.pair DhConcrete.native_session_refines -docstrings
Under that configuration, for all raw inputs $`a,b`, put $`\alpha=d(a)` and $`\beta=d(b)`.
The extracted session returns

$$`\mathrm{ok}\,(p(\alpha g),p(\beta g),
k(\alpha\beta g),k(\alpha\beta g)).`

Substitution of the two primitive contracts proves total successful
execution and honest agreement. Commutativity identifies the local keys.
:::
::::

[The Rust wrapper](source/concrete/rust/poc_dh.rs.html) ·
[Primitive proofs](source/concrete/Concrete/Primitives.lean.html) ·
[Encoding and group model](source/concrete/Concrete/Algebra.lean.html) ·
[Extraction comparison](source/concrete/evidence/linkage-comparison.json)
