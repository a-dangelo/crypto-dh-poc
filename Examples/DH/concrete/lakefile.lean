import Lake
open Lake DSL
package «dh-concrete»
require mathlib from "../lean/.lake/packages/mathlib"
require aeneas from "../vendor/aeneas-dalek/backends/lean"
require EllipticCurve from "vendor/EllipticCurve"
require «curve25519-dalek» from "../vendor/dalek-proof"
require VCVio from "../vendor/VCVio"
lean_lib DhPoc where
  srcDir := "../lean"
@[default_target] lean_lib Concrete
