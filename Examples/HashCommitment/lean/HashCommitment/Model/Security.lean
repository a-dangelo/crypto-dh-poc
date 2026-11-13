import HashCommitment.Model.HashCommitment
import VCVio.CryptoFoundations.HashCommitment

/-!
# Security of the reified hash commitment

The reified scheme is (literally) VCVio's `KeyedHashFamily.toCommitment`, so VCVio's theorems
about it apply. Here: binding ≤ keyed collision resistance of the hash.
-/

open OracleComp OracleSpec CommitmentScheme CollisionResistance

namespace HashCommitment.Model

variable {K M C : Type}

/-- The hash, as a VCVio keyed hash family on `(message, opening)` pairs. -/
def hashFamily (keygen : ProbComp K) (hashFn : K → M → Bytes 32 → C) :
    KeyedHashFamily K (M × Bytes 32) C where
  keygen := keygen
  hash k ms := hashFn k ms.1 ms.2

/-- The uniform reading of the reified `commit` is VCVio's hash-commitment `commit`. -/
theorem commit_uniform_eq [DecidableEq C] (keygen : ProbComp K)
    (hashFn : K → M → Bytes 32 → C) (key : K) (msg : M) :
    simulateQ uniformImpl (commit hashFn key msg) =
      (hashFamily keygen hashFn).toCommitment.commit key msg := by
  unfold commit randomBytes
  simp only [simulateQ_bind, simulateQ_spec_query, simulateQ_pure]
  rfl

/-- The reified scheme is VCVio's hash commitment for `hashFamily`. -/
theorem scheme_eq_toCommitment [DecidableEq C] (keygen : ProbComp K)
    (hashFn : K → M → Bytes 32 → C) :
    scheme keygen hashFn = (hashFamily keygen hashFn).toCommitment := by
  have hcommit : (scheme keygen hashFn).commit = (hashFamily keygen hashFn).toCommitment.commit := by
    funext k m; exact commit_uniform_eq keygen hashFn k m
  calc scheme keygen hashFn
      = { setup := keygen, commit := (scheme keygen hashFn).commit,
          verify := verify hashFn } := rfl
    _ = (hashFamily keygen hashFn).toCommitment := by rw [hcommit]; rfl

/-- **Binding ≤ keyed-CR.** The binding advantage of any adversary against the reified scheme
is bounded by the keyed collision-resistance advantage of the reduction adversary against
the hash. -/
theorem binding [DecidableEq M] [DecidableEq C] (keygen : ProbComp K)
    (hashFn : K → M → Bytes 32 → C) (A : BindingAdversary K M C (Bytes 32)) :
    bindingAdvantage (scheme keygen hashFn) A ≤
      keyedCRAdvantage (hashFamily keygen hashFn) (bindingAdversary_toKeyedCRAdversary A) := by
  rw [scheme_eq_toCommitment]
  exact bindingAdvantage_toCommitment_le_keyedCRAdvantage (hashFamily keygen hashFn) A

end HashCommitment.Model

