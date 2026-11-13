import Lake
open Lake DSL
-- One checked runtime for the combined book; extraction pins remain per example.
require aeneas from "../Examples/HashCommitment/vendor/aeneas/backends/lean"
require VCVio from "../Examples/DH/vendor/VCVio"
require mathlib from "../Examples/DH/lean/.lake/packages/mathlib"
require DhBlueprint from "DH"
require SchnorrBlueprint from "Schnorr"
require HashCommitmentBlueprint from "HashCommitment"
package ExamplesBlueprint where
  precompileModules := false
  leanOptions := #[⟨`experimental.module, true⟩]
@[default_target] lean_lib ExamplesBlueprint
