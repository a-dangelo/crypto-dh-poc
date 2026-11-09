import Lake
open Lake DSL

package «dh-poc»

-- Exact source revisions are recorded in ../evidence/versions.json.
-- bootstrap.sh materializes these dependencies under vendor/.
require aeneas from "../vendor/aeneas/backends/lean"
require VCVio from "../vendor/VCVio"

@[default_target] lean_lib DhPoc
