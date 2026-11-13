import VCVio.OracleComp.Constructions.SampleableType.Basic
import VCVio.OracleComp.SimSemantics.SimulateQ

/-!
# Abstract byte sampling

The model requests a vector of bytes without exposing an RNG state. Its uniform
interpretation is independently defined using VCV-io's canonical vector sampler.
The bridge proves that the effectful ideal dictionary in the extracted computation
has this law. A concrete operating-system RNG or CSPRNG is not verified here.
-/

open OracleComp OracleSpec

namespace HashCommitment.Model

/-- A byte. -/
abbrev Byte := BitVec 8
/-- `n` bytes. -/
abbrev Bytes (n : ℕ) := Vector Byte n

/-- The oracle interface of reified programs: query `n : ℕ`, get `n` bytes back. -/
@[reducible] def RngSpec : OracleSpec ℕ := fun n => Bytes n

/-- The single oracle operation: ask for `n` random bytes. -/
def randomBytes (n : ℕ) : OracleComp RngSpec (Bytes n) :=
  liftM (OracleSpec.query (spec := RngSpec) n)

/-- The probabilistic interpretation: answer every byte query with fresh uniform bytes. -/
def uniformImpl : QueryImpl RngSpec ProbComp := fun n => $ᵗ (Bytes n)

end HashCommitment.Model

