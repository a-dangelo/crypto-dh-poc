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

The 31-line Rust wrapper takes explicit 64-byte secrets and exchanges
canonical 32-byte public values. Agreement returns an optional encoding.
The backend is patched BAIF dalek 5.0.0 at
`95b5831c63ff1c5f6287bd3a77569412a9afdbfb`.

::::definition "extracted_session" (lean := "Curve25519Dalek.poc_dh.session")
:::AnchorlessBlueprint.pair Curve25519Dalek.poc_dh.session -docstrings
The session computes two public values and two local keys, propagating
Aeneas failures. `GeneratedAdapter.lean` is a mechanical slice of the
full extraction. The full extraction’s inherited backend declarations match
the pinned proof source after removal of block comments.
:::
::::

::::theorem "public_contract" (lean := "DhConcrete.native_public_eq")
:::AnchorlessBlueprint.pair DhConcrete.native_public_eq -docstrings
For every $`s\in\mathrm{Bytes}_{64}`, under the target configuration,

$$`\mathrm{public}(s)=\mathrm{ok}(p(d(s)g)).`

The generated wrapper is definitionally equal to the composition covered
by the imported primitive specifications.
:::
::::

::::theorem "agreement_contract" (lean := "DhConcrete.native_agree_eq")
:::AnchorlessBlueprint.pair DhConcrete.native_agree_eq -docstrings
Under the same target configuration, for every raw secret $`s` and $`P\in G`,

$$`\mathrm{agree}(s,p(P))=\mathrm{ok}(k(d(s)P)).`

The proof uses the BAIF decompression, multiplication and compression
specifications. A decoded Edwards representative may differ from $`P`;
the Ristretto relation suffices to identify the resulting encoding.
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
