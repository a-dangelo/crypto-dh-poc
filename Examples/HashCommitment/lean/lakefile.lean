import Lake
open Lake DSL
require aeneas from "../vendor/aeneas/backends/lean"
require VCVio from "../vendor/VCVio"
package HashCommitment where
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`relaxedAutoImplicit, false⟩]
@[default_target] lean_lib HashCommitment
