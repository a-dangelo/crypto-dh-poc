import DhPoc.CoinSampling

/-!
# Coin-explicit session experiments

Both experiments use only fair-coin queries. The ideal experiment draws its
independent challenge by the same fixed-width modular sampler, rather than an
exact uniform odd-order draw. This costs one extra sampling-error term. No
strict finite fair-coin implementation of exact odd-order sampling is assumed.

The real experiment calls the Aeneas-extracted generic session. Its primitive
contracts are still parameters of `PrimeOrderModel`. Coin-query bounds below
do not assert the running time of those primitives or of deterministic code.
-/

namespace DhPoc.CoinSecurity

open OracleComp OracleSpec PFunctor MeasureTheory ENNReal Aeneas.Std

variable {D P K G : Type} {q w : ℕ}
    [Fact (Nat.Prime q)] [AddCommGroup G] [Module (ZMod q) G]

/-- Run the extracted generic session with two explicit width-bit coin samplers. -/
noncomputable def real (M : PrimeOrderModel D P K G q w)
    (A : P → P → K → OracleComp coinSpec Bool) : OracleComp coinSpec Bool := do
  let a ← CoinSampling.sample w
  let b ← CoinSampling.sample w
  match (dh_core.session M.operations a b).match with
  | .ok out => A out.alice_public out.bob_public out.alice_key
  | _ => pure false

/-- The independent ideal challenge also uses a width-bit coin sampler. -/
noncomputable def ideal (M : PrimeOrderModel D P K G q w)
    (A : P → P → K → OracleComp coinSpec Bool) : OracleComp coinSpec Bool := do
  let a ← CoinSampling.sample w
  let b ← CoinSampling.sample w
  let c ← CoinSampling.sample w
  match (dh_core.session M.operations a b).match with
  | .ok out => A out.alice_public out.bob_public (M.key (M.scalar c • M.generator))
  | _ => pure false

/-- Measure-level version of the new ideal experiment. -/
noncomputable def wideIdeal (M : PrimeOrderModel D P K G q w)
    (A : P → P → K → ProbComp Bool) : ProbComp Bool := do
  let a ← $ᵗ Fin (2 ^ w)
  let b ← $ᵗ Fin (2 ^ w)
  let c ← $ᵗ Fin (2 ^ w)
  match (dh_core.session M.operations a b).match with
  | .ok out => A out.alice_public out.bob_public (M.key (M.scalar c • M.generator))
  | _ => pure false

/-- The real coin experiment is exactly the existing extracted-session experiment. -/
theorem real_evalDistEq (M : PrimeOrderModel D P K G q w)
    (A : P → P → K → OracleComp coinSpec Bool) :
    real M A =ᵈ sampledReal M.toRawPrimitiveModel
      ($ᵗ Fin (2 ^ w)) ($ᵗ Fin (2 ^ w))
      (fun pa pb k => PPT.interpretCoins (A pa pb k)) := by
  unfold real sampledReal
  apply (CoinSampling.sample_evalDistEq w).bind
  intro a
  apply (CoinSampling.sample_evalDistEq w).bind
  intro b
  simp only [raw_session_refines, Result.match.ok]
  exact (PPT.interpretCoins_evalDistEq _).symm

/-- The ideal coin experiment is exactly the triple-wide-sample experiment. -/
theorem ideal_evalDistEq (M : PrimeOrderModel D P K G q w)
    (A : P → P → K → OracleComp coinSpec Bool) :
    ideal M A =ᵈ wideIdeal M (fun pa pb k => PPT.interpretCoins (A pa pb k)) := by
  unfold ideal wideIdeal
  apply (CoinSampling.sample_evalDistEq w).bind
  intro a
  apply (CoinSampling.sample_evalDistEq w).bind
  intro b
  apply (CoinSampling.sample_evalDistEq w).bind
  intro c
  simp only [raw_session_refines, Result.match.ok]
  exact (PPT.interpretCoins_evalDistEq _).symm

/-- A common prefix preserves a uniform continuation-distance bound. -/
theorem bind_distance_le {α β : Type} [MeasurableSpace α] [DiscreteMeasurableSpace α]
    [MeasurableSpace β] (μ : ProbComp α) (f g : α → ProbComp β) (ε : ℝ≥0∞)
    (h : ∀ a, measureETVDist (f a) (g a) ≤ ε) :
    measureETVDist (μ >>= f) (μ >>= g) ≤ ε := by
  refine (measureETVDist_bind_bind_le_lintegral μ f g
    Measurable.of_discrete Measurable.of_discrete (fun _ => ε)
    (Filter.Eventually.of_forall h)).trans ?_
  rw [lintegral_const]
  exact mul_le_of_le_one_right' (evalDist_apply_univ_le_one μ)

/-- Replacing just the ideal challenge costs at most one modular-sampling error. -/
theorem ideal_distance_le (M : PrimeOrderModel D P K G q w)
    (A : P → P → K → ProbComp Bool) :
    measureETVDist
      (sampledIdeal M.toRawPrimitiveModel ($ᵗ Fin (2 ^ w)) ($ᵗ Fin (2 ^ w)) A)
      (wideIdeal M A) ≤ samplingError q w := by
  let : MeasurableSpace (ZMod q) := ⊤
  simp only [sampledIdeal, wideIdeal, raw_session_refines, Result.match.ok]
  apply bind_distance_le
  intro a
  apply bind_distance_le
  intro b
  have h := measureETVDist_bind_le ($ᵗ ZMod q) (M.scalar <$> ($ᵗ Fin (2 ^ w)))
    (fun c => A (M.point (M.scalar a • M.generator))
      (M.point (M.scalar b • M.generator)) (M.key (c • M.generator)))
    Measurable.of_discrete
  simp only [bind_map_left] at h
  refine h.trans ?_
  rw [measureETVDist_comm]
  have hs : M.scalar = fun s : Fin (2 ^ w) => (s.val : ZMod q) := funext M.scalar_eq
  rw [hs]
  simpa only [samplingError, Nat.cast_pow, Nat.cast_ofNat] using
    uniform_modulo_measureETVDist_le (2 ^ w) q

/-- Absolute acceptance-probability difference for the two coin-only experiments. -/
noncomputable def advantage (M : PrimeOrderModel D P K G q w)
    (A : P → P → K → OracleComp coinSpec Bool) : ℝ≥0∞ :=
  𝒟[real M A].boolDist 𝒟[ideal M A]

/-- Two replacements in the real branch and three in the ideal branch cost `5δ`. -/
theorem advantage_le_standard (M : PrimeOrderModel D P K G q w)
    (A : P → P → K → OracleComp coinSpec Bool) :
    advantage M A ≤
      DiffieHellman.ddhAdvantage M.generator
        (rawReduction M.toRawPrimitiveModel (fun pa pb k => PPT.interpretCoins (A pa pb k))) +
        5 * samplingError q w := by
  let B := fun pa pb k => PPT.interpretCoins (A pa pb k)
  rw [advantage, (real_evalDistEq M A).evalDist_eq, (ideal_evalDistEq M A).evalDist_eq]
  calc
    _ ≤ sampledSessionAdvantage M.toRawPrimitiveModel
          ($ᵗ Fin (2 ^ w)) ($ᵗ Fin (2 ^ w)) B +
        𝒟[sampledIdeal M.toRawPrimitiveModel ($ᵗ Fin (2 ^ w)) ($ᵗ Fin (2 ^ w)) B].boolDist
          𝒟[wideIdeal M B] := Measure.boolDist_triangle _ _ _
    _ ≤ (DiffieHellman.ddhAdvantage M.generator (rawReduction M.toRawPrimitiveModel B) +
          4 * samplingError q w) + samplingError q w :=
      add_le_add (moduloSessionAdvantage_le_standard M B)
        ((bool_distance_le_tv _ _).trans (ideal_distance_le M B))
    _ = _ := by ring

/-- Two raw samples followed by a uniformly query-bounded adversary. -/
theorem real_rollBound (M : PrimeOrderModel D P K G q w)
    (A : P → P → K → OracleComp coinSpec Bool) (r : ℕ)
    (hA : ∀ pa pb k, (A pa pb k).IsTotalRollBound r) :
    (real M A).IsTotalRollBound (2 * w + r) := by
  simp only [real, raw_session_refines, Result.match.ok]
  have h := FreeM.isTotalRollBound_bind (CoinSampling.sample_rollBound w) fun a =>
    FreeM.isTotalRollBound_bind (CoinSampling.sample_rollBound w) fun b =>
      hA (M.point (M.scalar a • M.generator)) (M.point (M.scalar b • M.generator))
        (M.key ((M.scalar a * M.scalar b) • M.generator))
  convert h using 1
  omega

/-- Three raw samples followed by the adversary in the coin-explicit ideal game. -/
theorem ideal_rollBound (M : PrimeOrderModel D P K G q w)
    (A : P → P → K → OracleComp coinSpec Bool) (r : ℕ)
    (hA : ∀ pa pb k, (A pa pb k).IsTotalRollBound r) :
    (ideal M A).IsTotalRollBound (3 * w + r) := by
  simp only [ideal, raw_session_refines, Result.match.ok]
  have h := FreeM.isTotalRollBound_bind (CoinSampling.sample_rollBound w) fun a =>
    FreeM.isTotalRollBound_bind (CoinSampling.sample_rollBound w) fun b =>
      FreeM.isTotalRollBound_bind (CoinSampling.sample_rollBound w) fun c =>
        hA (M.point (M.scalar a • M.generator)) (M.point (M.scalar b • M.generator))
          (M.key (M.scalar c • M.generator))
  convert h using 1
  omega

section Families

variable {D P K G : ℕ → Type} {q w : ℕ → ℕ}
    [∀ n, Fact (Nat.Prime (q n))] [∀ n, AddCommGroup (G n)]
    [∀ n, Module (ZMod (q n)) (G n)]

/-- Coin-explicit security game over one parameter-tagged adversary program. -/
noncomputable def sessionGame
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n)) :
    SecurityGame (PPT.SessionAdversary P K) :=
  ⟨fun A n => advantage (M n) (fun pa pb k => A ⟨n, pa, pb, k⟩)⟩

/-- The five-error loss is negligible under the existing width schedule. -/
theorem five_samplingError_negligible (q w b : ℕ → ℕ) [∀ n, NeZero (q n)]
    (hq : ∀ n, q n ≤ 2 ^ b n) (hw : ∀ n, b n + n + 2 ≤ w n) :
    negligible (fun n => 5 * samplingError (q n) (w n)) := by
  have hδ : negligible (fun n => samplingError (q n) (w n)) :=
    negligible_of_le
      (fun n => le_mul_of_one_le_left' (show (1 : ℝ≥0∞) ≤ 4 by norm_num))
      (four_samplingError_negligible q w b hq hw)
  exact negligible_const_mul hδ (by norm_num)

/-- The coin-only experiments have negligible advantage under the stated DDH premise. -/
theorem advantage_negligible
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n))
    (A : PPT.SessionAdversary P K) (b : ℕ → ℕ)
    (hq : ∀ n, q n ≤ 2 ^ b n) (hw : ∀ n, b n + n + 2 ≤ w n)
    (hDDH : negligible fun n => DiffieHellman.ddhAdvantage (M n).generator
      (PPT.ddhFamily (q := q) (PPT.reduce M A) n)) :
    negligible ((sessionGame M).advantage A) := by
  apply negligible_of_le (fun n => advantage_le_standard (M n) (fun pa pb k => A ⟨n, pa, pb, k⟩))
  exact negligible_add hDDH (five_samplingError_negligible q w b hq hw)

/-- Backend-relative strict-PPT security for the new all-coin experiments.
The backend and encoder certificates remain explicit. Honest computation costs
are not consequences of this adversary-class security theorem. -/
theorem session_secure_isPPTBy
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n))
    (b : ℕ → ℕ) (hq : ∀ n, q n ≤ 2 ^ b n) (hw : ∀ n, b n + n + 2 ≤ w n)
    {C : StepClass} [C.HasProd] [C.HasSum] [C.HasOption]
    (Q : QuantitativeStepClass C) [Q.HasComposition]
    (bd : DynSystem.DynComputation.Boundary C coinSpec.toPFunctor (PPT.SessionInput P K) Bool)
    (ddhInputRep : C.Str (PPT.DDHInput G))
    (composition : Q.PolynomialComposition)
    (encoding : Q.PolyRealizer ddhInputRep bd.input (PPT.encodeInput M))
    (hDDH : (PPT.ddhGame M).secureAgainst
      (OracleComp.Complexity.IsPPTBy Q (bd.withInput ddhInputRep))) :
    (sessionGame M).secureAgainst (OracleComp.Complexity.IsPPTBy Q bd) := by
  intro A hA
  exact advantage_negligible M A b hq hw
    (hDDH (PPT.reduce M A) (PPT.isPPTBy_precomp composition encoding hA))

end Families

end DhPoc.CoinSecurity
