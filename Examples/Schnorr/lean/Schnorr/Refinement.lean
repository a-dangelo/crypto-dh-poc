import Schnorr.Generated.SchnorrCore
import Examples.Schnorr.SigmaProtocol

/-! Conditional refinement of the extracted Rust protocol on valid associated-type
values. Arithmetic, representation validity, parsing, and randomness implementations
are separate boundaries. Contracts cover every native value, including adversarial
verifier inputs; no concrete arithmetic backend is assumed verified. -/
namespace SchnorrProof

open Aeneas.Std

variable {F G D S P : Type} [Field F] [AddCommGroup G] [Module F G] [DecidableEq G]

/-- The native arithmetic contract. Decoding an encoding recovers the mathematical value.
All primitive calls terminate successfully and return exactly the chosen encoding
of the decoded mathematical operation. Native inputs need not have unique
representations, but primitive outputs must use these chosen canonical encodings. -/
structure PrimitiveModel (F G D S P : Type) [Field F] [AddCommGroup G]
    [Module F G] [DecidableEq G] (g : G) where
  ops : schnorr_core.Group D S P
  scalar : F → S
  point : G → P
  decodeScalar : S → F
  decodePoint : P → G
  decode_scalar : ∀ x, decodeScalar (scalar x) = x
  decode_point : ∀ x, decodePoint (point x) = x
  base_mul : ∀ s, ops.base_mul s = .ok (point (decodeScalar s • g))
  point_mul : ∀ p s, ops.point_mul p s = .ok (point (decodeScalar s • decodePoint p))
  point_add : ∀ p q, ops.point_add p q = .ok (point (decodePoint p + decodePoint q))
  scalar_add : ∀ a b, ops.scalar_add a b = .ok (scalar (decodeScalar a + decodeScalar b))
  scalar_mul : ∀ a b, ops.scalar_mul a b = .ok (scalar (decodeScalar a * decodeScalar b))
  point_eq : ∀ p q, ops.point_eq p q = .ok (decide (decodePoint p = decodePoint q))

variable {g : G} (M : PrimitiveModel F G D S P g)

@[simp] theorem public_eq (sk : F) :
    schnorr_core.«public» M.ops (M.scalar sk) = .ok (M.point (sk • g)) := by
  simp [schnorr_core.«public», M.base_mul, M.decode_scalar]

@[simp] theorem commit_eq (r : F) :
    schnorr_core.commit M.ops (M.scalar r) = .ok (M.point (r • g)) := by
  simp [schnorr_core.commit, M.base_mul, M.decode_scalar]

@[simp] theorem respond_eq (sk r c : F) :
    schnorr_core.respond M.ops (M.scalar sk) (M.scalar r) (M.scalar c) =
      .ok (M.scalar (r + c * sk)) := by
  simp [schnorr_core.respond, M.scalar_mul, M.scalar_add, M.decode_scalar]

@[simp] theorem messages_eq (sk r c : F) :
    schnorr_core.messages M.ops (M.scalar sk) (M.scalar r) (M.scalar c) =
      .ok ⟨M.point (r • g), M.scalar (r + c * sk)⟩ := by
  simp [schnorr_core.messages, commit_eq, respond_eq]

/-- Verifier refinement for arbitrary native associated-type values, not only
honest encodings. Invalid byte strings are outside these types and this theorem. -/
theorem verify_eq (pk R : P) (c z : S) :
    schnorr_core.verify M.ops pk R c z =
      .ok (decide (M.decodeScalar z • g =
        M.decodePoint R + M.decodeScalar c • M.decodePoint pk)) := by
  simp [schnorr_core.verify, M.base_mul, M.point_mul, M.point_add,
    M.point_eq, M.decode_point]

theorem verify_accepts_iff (pk R : P) (c z : S) :
    schnorr_core.verify M.ops pk R c z = .ok true ↔
      M.decodeScalar z • g = M.decodePoint R + M.decodeScalar c • M.decodePoint pk := by
  rw [verify_eq]
  simp

theorem honest_complete (sk r c : F) :
    schnorr_core.verify M.ops (M.point (sk • g)) (M.point (r • g))
      (M.scalar c) (M.scalar (r + c * sk)) = .ok true := by
  rw [verify_accepts_iff]
  simp [M.decode_scalar, M.decode_point, add_smul, mul_smul]

/-- Transfer of VCVio's special soundness to two accepted native transcripts. -/
theorem special_soundness [SampleableType F] [SampleableType G]
    (pk R : P) (c₁ c₂ z₁ z₂ : S)
    (hne : M.decodeScalar c₁ ≠ M.decodeScalar c₂)
    (h₁ : schnorr_core.verify M.ops pk R c₁ z₁ = .ok true)
    (h₂ : schnorr_core.verify M.ops pk R c₂ z₂ = .ok true) :
    ((M.decodeScalar z₁ - M.decodeScalar z₂) *
      (M.decodeScalar c₁ - M.decodeScalar c₂)⁻¹) • g = M.decodePoint pk := by
  have hv₁ := (verify_accepts_iff M pk R c₁ z₁).mp h₁
  have hv₂ := (verify_accepts_iff M pk R c₂ z₂).mp h₂
  have h := Schnorr.sigma_speciallySound F G g (M.decodePoint pk) (M.decodePoint R)
    (M.decodeScalar c₁) (M.decodeScalar c₂) (M.decodeScalar z₁) (M.decodeScalar z₂)
    hne (by simpa [Schnorr.sigma] using hv₁) (by simpa [Schnorr.sigma] using hv₂)
    ((M.decodeScalar z₁ - M.decodeScalar z₂) *
      (M.decodeScalar c₁ - M.decodeScalar c₂)⁻¹) (by simp [Schnorr.sigma])
  simpa using h

end SchnorrProof
