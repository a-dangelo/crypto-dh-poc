import Concrete.Security
import Concrete.GeneratedAdapter

namespace DhConcrete
open Aeneas Aeneas.Std Curve25519Dalek OracleComp OracleSpec ENNReal

/-- The extracted public-value function is definitionally equal to the
composition used in the primitive proof. -/
theorem extracted_public_link (raw : Secret) :
    poc_dh.public.«x86_64-no-tables» raw = publicCompose raw := rfl

theorem extracted_agree_link (raw : Secret) (peer : Public) :
    poc_dh.agree.«x86_64-no-tables» raw peer = agreeCompose raw peer := rfl

/-- The extracted public-value function satisfies its specification under the
selected backend configuration. -/
theorem native_public_eq (hTarget : Aeneas.Std.target = "x86_64-no-tables")
    (raw : Secret) : poc_dh.public raw = .ok (point (decodeScalar raw • generator)) := by
  simpa [poc_dh.public, get_target, hTarget, extracted_public_link] using public_eq raw

theorem native_agree_eq (hTarget : Aeneas.Std.target = "x86_64-no-tables")
    (raw : Secret) (g : Group) :
    poc_dh.agree raw (point g) = .ok (key (decodeScalar raw • g)) := by
  simpa [poc_dh.agree, get_target, hTarget, extracted_agree_link] using agree_eq raw g

/-- The extracted Rust session succeeds with the stated public values and equal
shared keys under the selected backend configuration. -/
theorem native_session_refines (hTarget : Aeneas.Std.target = "x86_64-no-tables")
    (a b : Secret) :
    poc_dh.session a b = .ok {
      alice_public := point (decodeScalar a • generator),
      bob_public := point (decodeScalar b • generator),
      alice_key := key ((decodeScalar a * decodeScalar b) • generator),
      bob_key := key ((decodeScalar a * decodeScalar b) • generator) } := by
  simp only [poc_dh.session, native_public_eq hTarget, Aeneas.Std.bind_ok,
    native_agree_eq hTarget, smul_smul, mul_comm (decodeScalar b) (decodeScalar a)]

/-- The real experiment runs the extracted Rust session on the supplied raw samples. -/
noncomputable def nativeReal (μ ν : ProbComp Secret)
    (adversary : Public → Public → Key → ProbComp Bool) : ProbComp Bool := do
  let a ← μ
  let b ← ν
  match (poc_dh.session a b).match with
  | .ok out => adversary out.alice_public out.bob_public out.alice_key
  | _ => pure false

/-- The ideal experiment retains the extracted public values and replaces the
challenge with an independently sampled, encoded group element. -/
noncomputable def nativeIdeal (μ ν : ProbComp Secret)
    (adversary : Public → Public → Key → ProbComp Bool) : ProbComp Bool := do
  let a ← μ
  let b ← ν
  let c ← $ᵗ Scalar
  match (poc_dh.session a b).match with
  | .ok out => adversary out.alice_public out.bob_public (key (c • generator))
  | _ => pure false

noncomputable def nativeAdvantage (μ ν : ProbComp Secret)
    (adversary : Public → Public → Key → ProbComp Bool) : ℝ≥0∞ :=
  𝒟[nativeReal μ ν adversary].boolDist 𝒟[nativeIdeal μ ν adversary]

theorem nativeReal_eq (hTarget : Aeneas.Std.target = "x86_64-no-tables")
    (μ ν : ProbComp Secret) (adversary : Public → Public → Key → ProbComp Bool) :
    nativeReal μ ν adversary = DhPoc.sampledReal model μ ν adversary := by
  simp only [nativeReal, DhPoc.sampledReal, native_session_refines hTarget,
    DhPoc.raw_session_refines model, Result.match.ok]
  rfl

theorem nativeIdeal_eq (hTarget : Aeneas.Std.target = "x86_64-no-tables")
    (μ ν : ProbComp Secret) (adversary : Public → Public → Key → ProbComp Bool) :
    nativeIdeal μ ν adversary = DhPoc.sampledIdeal model μ ν adversary := by
  simp only [nativeIdeal, DhPoc.sampledIdeal, native_session_refines hTarget,
    DhPoc.raw_session_refines model, Result.match.ok]
  rfl

/-- The extracted session advantage equals the sampled-DDH advantage for the
selected backend. Primitive correctness is proved by the concrete model, and
the correspondence preserves both raw-secret samplers. -/
theorem nativeAdvantage_eq (hTarget : Aeneas.Std.target = "x86_64-no-tables")
    (μ ν : ProbComp Secret) (adversary : Public → Public → Key → ProbComp Bool) :
    nativeAdvantage μ ν adversary =
      DhPoc.sampledDDHAdvantage decodeScalar generator μ ν
        (DhPoc.rawReduction model adversary) := by
  rw [nativeAdvantage, nativeReal_eq hTarget, nativeIdeal_eq hTarget]
  exact advantage_eq μ ν adversary

/-- A supplied sampled-DDH bound also bounds the extracted session advantage. -/
theorem nativeAdvantage_le (hTarget : Aeneas.Std.target = "x86_64-no-tables")
    (μ ν : ProbComp Secret) (adversary : Public → Public → Key → ProbComp Bool) (ε : ℝ≥0∞)
    (hDDH : DhPoc.sampledDDHAdvantage decodeScalar generator μ ν
      (DhPoc.rawReduction model adversary) ≤ ε) : nativeAdvantage μ ν adversary ≤ ε := by
  rw [nativeAdvantage_eq hTarget]
  exact hDDH

end DhConcrete
