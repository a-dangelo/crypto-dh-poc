import DhPoc.ModuloSampling
import DhPoc.SamplingHybrids
import DhPoc.SamplingSchedule
import VCVio.CryptoFoundations.Asymptotics.Security

/-!
# Prime-order and sampling-width families

These theorems concern a family of models of the extracted generic session.
They do not turn the fixed native Curve25519 program into a growing group family.
The generator bijection makes `q` the group order, not just a scalar modulus.
Standard-DDH hardness and preservation of the chosen efficient-adversary class
are explicit hypotheses, not axioms or consequences of sampling bounds.
-/

namespace DhPoc
open OracleComp OracleSpec ENNReal

/-- A prime-order group model with uniform `w`-bit raw inputs reduced modulo `q`.
The bijection identifies the whole group with scalar multiples of the generator.
The primitive contracts come from `RawPrimitiveModel`; no implementation is supplied here. -/
structure PrimeOrderModel (D P K G : Type) (q w : ℕ)
    [Fact (Nat.Prime q)] [AddCommGroup G] [Module (ZMod q) G]
    extends RawPrimitiveModel D (Fin (2 ^ w)) P K (ZMod q) G where
  scalar_eq : ∀ s, scalar s = (s.val : ZMod q)
  generator_bijective : Function.Bijective (fun a : ZMod q => a • generator)

variable {D P K G : Type} {q w : ℕ}
    [Fact (Nat.Prime q)] [AddCommGroup G] [Module (ZMod q) G]

/-- The session with two independent uniform `w`-bit inputs has advantage at most
standard DDH plus four modular-reduction errors. This is a finite, concrete bound
for each choice of prime group order and bit width. -/
theorem moduloSessionAdvantage_le_standard
    (M : PrimeOrderModel D P K G q w)
    (A : P → P → K → ProbComp Bool) :
    sampledSessionAdvantage M.toRawPrimitiveModel ($ᵗ Fin (2 ^ w)) ($ᵗ Fin (2 ^ w)) A ≤
      DiffieHellman.ddhAdvantage M.generator (rawReduction M.toRawPrimitiveModel A) +
        4 * samplingError q w := by
  rw [sampledSessionAdvantage_eq]
  refine (sampledDDHAdvantage_le_standard M.scalar M.generator
    ($ᵗ Fin (2 ^ w)) ($ᵗ Fin (2 ^ w)) (rawReduction M.toRawPrimitiveModel A)).trans ?_
  have h : (letI : MeasurableSpace (ZMod q) := ⊤
      measureETVDist (M.scalar <$> ($ᵗ Fin (2 ^ w))) ($ᵗ ZMod q)) ≤
      samplingError q w := by
    have hs : M.scalar = fun s => (s.val : ZMod q) := funext M.scalar_eq
    rw [hs]
    simpa only [samplingError, Nat.cast_pow, Nat.cast_ofNat] using
      uniform_modulo_measureETVDist_le (2 ^ w) q
  have hsum := mul_le_mul (show (2 : ℝ≥0∞) ≤ 2 from le_rfl)
    (add_le_add h h) bot_le bot_le
  have heq : 2 * (samplingError q w + samplingError q w) = 4 * samplingError q w := by ring
  rw [heq] at hsum
  exact add_le_add le_rfl hsum

section Families

variable {D P K G : ℕ → Type} {q w : ℕ → ℕ}
    [∀ n, Fact (Nat.Prime (q n))] [∀ n, AddCommGroup (G n)]
    [∀ n, Module (ZMod (q n)) (G n)]

/-- Parameter-indexed adversaries for the encoded session. -/
abbrev FamilyAdversary (P K : ℕ → Type) :=
  (n : ℕ) → P n → P n → K n → ProbComp Bool

/-- The same encoding reduction at every security parameter. -/
def familyReduction (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n))
    (A : FamilyAdversary P K) (n : ℕ) : DiffieHellman.DDHAdversary (ZMod (q n)) (G n) :=
  rawReduction (M n).toRawPrimitiveModel (A n)

/-- Session advantage as a security-parameter family. -/
noncomputable def parameterizedSessionAdvantage
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n))
    (A : FamilyAdversary P K) (n : ℕ) : ℝ≥0∞ :=
  sampledSessionAdvantage (M n).toRawPrimitiveModel
    ($ᵗ Fin (2 ^ w n)) ($ᵗ Fin (2 ^ w n)) (A n)

/-- If `q(n) ≤ 2^b(n)` and `w(n) ≥ b(n)+n+2`, negligible standard-DDH
advantage for the encoding reduction implies negligible session advantage.
`negligible` is VCVio's superpolynomial-decay predicate, not a fixed small bound. -/
theorem parameterizedSessionAdvantage_negligible
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n))
    (A : FamilyAdversary P K) (b : ℕ → ℕ)
    (hq : ∀ n, q n ≤ 2 ^ b n) (hw : ∀ n, b n + n + 2 ≤ w n)
    (hDDH : negligible fun n =>
      DiffieHellman.ddhAdvantage (M n).generator (familyReduction M A n)) :
    negligible (parameterizedSessionAdvantage M A) := by
  apply negligible_of_le (fun n => moduloSessionAdvantage_le_standard (M n) (A n))
  exact negligible_add hDDH (four_samplingError_negligible q w b hq hw)

/-- The encoded-session family as an asymptotic security game. -/
noncomputable def parameterizedSessionGame
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n)) :
    SecurityGame (FamilyAdversary P K) := ⟨parameterizedSessionAdvantage M⟩

/-- Standard uniform-scalar DDH in the corresponding group family. -/
noncomputable def parameterizedDDHGame
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n)) :
    SecurityGame ((n : ℕ) → DiffieHellman.DDHAdversary (ZMod (q n)) (G n)) :=
  ⟨fun A n => DiffieHellman.ddhAdvantage (M n).generator (A n)⟩

/-- Conditional asymptotic security against a chosen efficient-adversary class.
Applications must instantiate both efficiency predicates and prove that the
encoding reduction preserves them, as well as supply the group-family DDH
assumption. No runtime or encoding-cost claim is hidden in this theorem. -/
theorem parameterizedSession_secure
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n))
    (b : ℕ → ℕ) (hq : ∀ n, q n ≤ 2 ^ b n) (hw : ∀ n, b n + n + 2 ≤ w n)
    (sessionEfficient : FamilyAdversary P K → Prop)
    (ddhEfficient : ((n : ℕ) → DiffieHellman.DDHAdversary (ZMod (q n)) (G n)) → Prop)
    (hreduce : ∀ A, sessionEfficient A → ddhEfficient (familyReduction M A))
    (hDDH : (parameterizedDDHGame M).secureAgainst ddhEfficient) :
    (parameterizedSessionGame M).secureAgainst sessionEfficient := by
  intro A hA
  exact parameterizedSessionAdvantage_negligible M A b hq hw
    (hDDH (familyReduction M A) (hreduce A hA))

end Families
end DhPoc
