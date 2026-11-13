import HashCommitment.Model.Rng
import VCVio.CryptoFoundations.CommitmentScheme

/-!
# Abstract hash commitment

A commitment samples a 32-byte opening and returns the keyed hash together with
that opening. Verification recomputes the hash. The key generator and hash function
are parameters. These definitions are independent of the extracted implementation.

Adapted from Marco Stronati's toy-bridge at
5212ebba2f937765c7ed4d1fb52f3e46e10dcea9.
-/

open OracleComp OracleSpec

namespace HashCommitment.Model

variable {K M C : Type}

/-- The reified Rust `commit`. Its only effect is one `randomBytes` query. -/
def commit (hashFn : K → M → Bytes 32 → C) (key : K) (msg : M) :
    OracleComp RngSpec (C × Bytes 32) := do
  let opening ← randomBytes 32
  let c := hashFn key msg opening
  return (c, opening)

/-- The reified Rust `verify`. Deterministic, so a plain function. -/
def verify [DecidableEq C] (hashFn : K → M → Bytes 32 → C) (key : K) (msg : M) (c : C)
    (opening : Bytes 32) : Bool :=
  let h := hashFn key msg opening
  decide (h = c)

/-- The commitment scheme of the reified programs. The key generator `keygen` is a free
parameter (the Rust crate has no key generation). -/
def scheme [DecidableEq C] (keygen : ProbComp K) (hashFn : K → M → Bytes 32 → C) :
    CommitmentScheme K M C (Bytes 32) where
  setup := keygen
  commit k m := simulateQ uniformImpl (commit hashFn k m)
  verify := verify hashFn

end HashCommitment.Model

