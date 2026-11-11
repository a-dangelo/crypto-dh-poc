import Lake
open Lake DSL

package «schnorr-poc»

require aeneas from "../vendor/aeneas/backends/lean"
require VCVio from "../vendor/VCVio"

@[default_target] lean_lib Schnorr
