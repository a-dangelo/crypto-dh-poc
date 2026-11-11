import VCVio.OracleComp.Constructions.SampleableType
import Mathlib.Algebra.Field.ZMod
import VCVio.EvalDist.MeasureTVDist.Basic
import VCVio.OracleComp.Constructions.SampleableType.Measure
import Mathlib.Data.Nat.Periodic

/-! Total variation bounds for modular reduction of a uniform integer.
The proof counts arbitrary events without enumerating the 512-bit input space. -/

namespace DhPoc
open OracleComp OracleSpec MeasureTheory ProbabilityTheory
open scoped ENNReal

private theorem count_fin (p : ℕ → Prop) [DecidablePred p] (n : ℕ) :
    (Finset.univ.filter (fun k : Fin n => p k.val)).card = Nat.count p n := by
  rw [Nat.count_eq_card_filter_range]
  exact Finset.card_bij (fun a _ => a.val)
    (by simp) (by intro a _ b _ h; exact Fin.ext h)
    (by intro b hb; simp only [Finset.mem_filter, Finset.mem_range] at hb
        exact ⟨⟨b, hb.1⟩, by simp [hb.2], rfl⟩)

private theorem periodic_count_mul (p : ℕ → Prop) [DecidablePred p]
    (m q : ℕ) (hp : Function.Periodic p m) :
    Nat.count p (q * m) = q * Nat.count p m := by
  induction q with
  | zero => simp
  | succ q ih =>
    rw [Nat.succ_mul, Nat.count_add']
    have heq : (fun k => p (k + m)) = p := funext hp
    simp only [heq, ih]
    ring

private theorem periodic_count_div_mod (p : ℕ → Prop) [DecidablePred p]
    (m n : ℕ) (hp : Function.Periodic p m) :
    Nat.count p n = (n / m) * Nat.count p m + Nat.count p (n % m) := by
  conv_lhs => rw [← Nat.mod_add_div n m, Nat.add_comm, Nat.mul_comm m]
  rw [Nat.count_add]
  have heq : (fun k => p (n / m * m + k)) = p := by
    funext k
    simpa [Nat.nsmul_eq_mul, Nat.add_comm] using (hp.nsmul (n / m) k)
  simp only [heq, periodic_count_mul p m (n / m) hp]

private theorem uniform_fin_nat_event (n : ℕ) [NeZero n] (p : ℕ → Prop)
    [DecidablePred p] :
    Pr{let x ← $ᵗ Fin n}[p x.val] = (Nat.count p n : ℝ≥0∞) / n := by
  rw [SampleableType.prEvent_uniformSample, Fintype.card_fin, count_fin]

private theorem uniform_zmod_event (m : ℕ) [NeZero m] (p : ZMod m → Prop)
    [DecidablePred p] :
    Pr{let x ← $ᵗ ZMod m}[p x] =
      (Nat.count (fun k : ℕ => p (k : ZMod m)) m : ℝ≥0∞) / m := by
  rw [← SampleableType.prEvent_uniformSample_equiv (ZMod.finEquiv m).toEquiv p]
  have heq (x : Fin m) : (ZMod.finEquiv m).toEquiv x = (x.val : ZMod m) := by
    cases m with
    | zero => exact (NeZero.ne 0 rfl).elim
    | succ m =>
      change x = ((x : ZMod (m + 1)).val : ZMod (m + 1))
      exact (ZMod.natCast_zmod_val (n := m + 1) x).symm
  simp_rw [heq]
  exact uniform_fin_nat_event m (fun k => p (k : ZMod m))

private theorem ratio_discrepancy_le (n m q r a b : ℕ)
    (hn : 0 < n) (hm : 0 < m) (hdecomp : n = q * m + r)
    (ha : a ≤ m) (hb : b ≤ r) :
    ENNReal.absDiff (((q * a + b : ℕ) : ℝ≥0∞) / n)
      ((a : ℝ≥0∞) / m) ≤ (r : ℝ≥0∞) / n := by
  have hn0 : (n : ℝ≥0∞) ≠ 0 := by exact_mod_cast hn.ne'
  have hm0 : (m : ℝ≥0∞) ≠ 0 := by exact_mod_cast hm.ne'
  have hfin (x y : ℕ) (hy : (y : ℝ≥0∞) ≠ 0) :
      (x : ℝ≥0∞) / y ≠ ⊤ := ENNReal.div_ne_top (by simp) hy
  rw [ENNReal.absDiff_le_iff]
  have hnR : 0 < (n : ℝ) := by exact_mod_cast hn
  have hmR : 0 < (m : ℝ) := by exact_mod_cast hm
  have hdR : (n : ℝ) = q * m + r := by exact_mod_cast hdecomp
  have haR : (a : ℝ) ≤ m := by exact_mod_cast ha
  have hbR : (b : ℝ) ≤ r := by exact_mod_cast hb
  constructor
  · apply (ENNReal.toReal_le_toReal (hfin _ _ hn0)
      (ENNReal.add_ne_top.mpr ⟨hfin _ _ hm0, hfin _ _ hn0⟩)).mp
    rw [ENNReal.toReal_add (hfin a m hm0) (hfin r n hn0)]
    simp only [ENNReal.toReal_div, ENNReal.toReal_natCast]
    push_cast
    rw [div_le_iff₀ hnR]
    apply (mul_le_mul_iff_right₀ hmR).mp
    field_simp
    nlinarith [mul_le_mul_of_nonneg_left hbR (le_of_lt hmR)]
  · apply (ENNReal.toReal_le_toReal (hfin _ _ hm0)
      (ENNReal.add_ne_top.mpr ⟨hfin _ _ hn0, hfin _ _ hn0⟩)).mp
    rw [ENNReal.toReal_add (hfin (q * a + b) n hn0) (hfin r n hn0)]
    simp only [ENNReal.toReal_div, ENNReal.toReal_natCast]
    push_cast
    rw [← add_div, div_le_div_iff₀ hmR hnR]
    nlinarith [mul_le_mul_of_nonneg_right haR (Nat.cast_nonneg r : (0 : ℝ) ≤ r)]

/-- Reduction of a uniform integer in `[0,n)` modulo `m` has total variation
distance at most `(n % m)/n` from uniform `ZMod m`. No divisibility hypothesis is required. -/
theorem uniform_modulo_measureETVDist_le (n m : ℕ) [NeZero n] [NeZero m] :
    letI : MeasurableSpace (ZMod m) := ⊤
    measureETVDist ((fun x : Fin n => (x.val : ZMod m)) <$> ($ᵗ Fin n))
      ($ᵗ ZMod m) ≤ (n % m : ℕ) / (n : ℝ≥0∞) := by
  classical
  let : MeasurableSpace (ZMod m) := ⊤
  unfold measureETVDist Measure.etvDist
  refine iSup_le fun s => ?_
  change ENNReal.absDiff
    (𝒟[(fun x : Fin n => (x.val : ZMod m)) <$> ($ᵗ Fin n)] {x | x ∈ s.val})
    (𝒟[($ᵗ ZMod m : ProbComp (ZMod m))] {x | x ∈ s.val}) ≤ _
  rw [← prEvent_eq_evalDist_of_discrete, ← prEvent_eq_evalDist_of_discrete,
    prEvent_map, uniform_fin_nat_event n (fun k => (k : ZMod m) ∈ s.val),
    uniform_zmod_event m (fun x => x ∈ s.val)]
  let p : ℕ → Prop := fun k => (k : ZMod m) ∈ s.val
  have hp : Function.Periodic p m := by
    intro k
    simp [p, Nat.cast_add]
  rw [periodic_count_div_mod p m n hp]
  apply ratio_discrepancy_le n m (n / m) (n % m) (Nat.count p m) (Nat.count p (n % m))
    (Nat.pos_of_ne_zero (NeZero.ne n)) (Nat.pos_of_ne_zero (NeZero.ne m))
  · simpa [Nat.mul_comm, Nat.add_comm] using (Nat.mod_add_div n m).symm
  · exact Nat.count_le p
  · exact Nat.count_le p

end DhPoc
