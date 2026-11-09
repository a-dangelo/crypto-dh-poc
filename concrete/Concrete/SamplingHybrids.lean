import DhPoc.RawSecurity
import VCVio.EvalDist.MeasureTVDist.Bind

/-! Replacement of two independent secret-scalar distributions in both DDH branches.
The Boolean distance is the absolute difference of acceptance probabilities. -/

namespace DhPoc
open OracleComp OracleSpec MeasureTheory ENNReal

/-- Replacing two independent samples changes the output distribution by at most
the sum of their total variation distances. The bound holds for `ProbComp`
without an additional losslessness hypothesis. -/
theorem pair_bind_distance {α β γ : Type} [MeasurableSpace α] [DiscreteMeasurableSpace α]
    [MeasurableSpace β] [DiscreteMeasurableSpace β] [MeasurableSpace γ]
    (μ μ' : ProbComp α) (ν ν' : ProbComp β) (f : α → β → ProbComp γ) :
    measureETVDist (μ >>= fun a => ν >>= f a) (μ' >>= fun a => ν' >>= f a) ≤
      measureETVDist μ μ' + measureETVDist ν ν' := by
  refine (measureETVDist_bind_bind_le_add_lintegral μ μ'
    (fun a => ν >>= f a) (fun a => ν' >>= f a)
    Measurable.of_discrete Measurable.of_discrete
    (fun _ => measureETVDist ν ν')
    (Filter.Eventually.of_forall fun a =>
      measureETVDist_bind_le ν ν' (f a) Measurable.of_discrete)).trans ?_
  rw [lintegral_const]
  exact add_le_add le_rfl (mul_le_of_le_one_right' (evalDist_apply_univ_le_one μ'))

/-- The difference of acceptance probabilities is bounded by total variation distance. -/
theorem bool_distance_le_tv (μ ν : ProbComp Bool) :
    𝒟[μ].boolDist 𝒟[ν] ≤ measureETVDist μ ν :=
  Measure.absDiff_apply_le_etvDist _ _ (measurableSet_singleton true)

variable {S F G : Type} [Field F] [AddCommGroup G] [Module F G]

/-- The real sampled-DDH experiment commutes with deterministic scalar decoding
of the two independent samples. -/
theorem sampled_real_decoded (decode : S → F) (g : G) (μ ν : ProbComp S)
    (A : DiffieHellman.DDHAdversary F G) :
    sampledDDHReal decode g μ ν A =
      (do let a ← decode <$> μ; let b ← decode <$> ν
          A g (a • g) (b • g) ((a * b) • g)) := by
  simp only [sampledDDHReal, bind_map_left]

variable [SampleableType F]

theorem sampled_random_decoded (decode : S → F) (g : G) (μ ν : ProbComp S)
    (A : DiffieHellman.DDHAdversary F G) :
    sampledDDHRandom decode g μ ν A =
      (do let a ← decode <$> μ; let b ← decode <$> ν; let c ← $ᵗ F
          A g (a • g) (b • g) (c • g)) := by
  simp only [sampledDDHRandom, bind_map_left]

/-- Replacing the two secret-scalar distributions in each DDH branch bounds the
advantage by standard DDH plus four statistical errors. The independent uniform
challenge in the random branch remains unchanged. -/
theorem sampledDDHAdvantage_le_standard
    (decode : S → F) (g : G) (μ ν : ProbComp S)
    (A : DiffieHellman.DDHAdversary F G) :
    sampledDDHAdvantage decode g μ ν A ≤
      DiffieHellman.ddhAdvantage g A +
      2 * (letI : MeasurableSpace F := ⊤
        measureETVDist (decode <$> μ) ($ᵗ F) + measureETVDist (decode <$> ν) ($ᵗ F)) := by
  let : MeasurableSpace F := ⊤
  let d := measureETVDist (decode <$> μ) ($ᵗ F) + measureETVDist (decode <$> ν) ($ᵗ F)
  have hr : 𝒟[sampledDDHReal decode g μ ν A].boolDist
      𝒟[DiffieHellman.ddhRealExperiment g A] ≤ d := by
    refine (bool_distance_le_tv _ _).trans ?_
    rw [sampled_real_decoded]
    exact pair_bind_distance _ _ _ _ _
  have hi : 𝒟[DiffieHellman.ddhRandomExperiment g A].boolDist
      𝒟[sampledDDHRandom decode g μ ν A] ≤ d := by
    rw [Measure.boolDist_comm]
    refine (bool_distance_le_tv _ _).trans ?_
    rw [sampled_random_decoded]
    exact pair_bind_distance _ _ _ _ _
  calc
    _ ≤ 𝒟[sampledDDHReal decode g μ ν A].boolDist
          𝒟[DiffieHellman.ddhRealExperiment g A] +
        (DiffieHellman.ddhAdvantage g A +
          𝒟[DiffieHellman.ddhRandomExperiment g A].boolDist
            𝒟[sampledDDHRandom decode g μ ν A]) :=
      (Measure.boolDist_triangle _ _ _).trans
        (add_le_add le_rfl (Measure.boolDist_triangle _ _ _))
    _ ≤ d + (DiffieHellman.ddhAdvantage g A + d) := add_le_add hr (add_le_add le_rfl hi)
    _ = _ := by ring

end DhPoc
