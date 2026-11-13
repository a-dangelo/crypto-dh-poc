import Lake
open Lake DSL
require «HashCommitment» from "../../Examples/HashCommitment/lean"
require VersoBlueprint from git "https://github.com/leanprover/verso-blueprint"@"4943d3335ffa9221a39949e60836a8ad5dc2a456"
package HashCommitmentBlueprint where
  precompileModules := false
  leanOptions := #[⟨`experimental.module, true⟩]
@[default_target] lean_lib HashCommitmentBlueprint
