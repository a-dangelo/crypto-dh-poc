import Concrete.Native
import Concrete.Sampler

namespace DhConcrete
open Aeneas.Std OracleComp OracleSpec ENNReal

/-- End-to-end equality for two independent, explicit ideal 512-bit random tapes.
The corresponding sampled-DDH hypothesis retains wide reduction modulo L. -/
theorem wideAdvantage_eq (hTarget : target = "x86_64-no-tables")
    (adversary : Public → Public → Key → ProbComp Bool) :
    nativeAdvantage uniformWide uniformWide adversary =
      DhPoc.sampledDDHAdvantage decodeScalar generator uniformWide uniformWide
        (DhPoc.rawReduction model adversary) :=
  nativeAdvantage_eq hTarget uniformWide uniformWide adversary

/-- A bound on the explicit wide-sampler DDH game transfers without loss. -/
theorem wideAdvantage_le (hTarget : target = "x86_64-no-tables")
    (adversary : Public → Public → Key → ProbComp Bool) (ε : ℝ≥0∞)
    (hDDH : DhPoc.sampledDDHAdvantage decodeScalar generator uniformWide uniformWide
      (DhPoc.rawReduction model adversary) ≤ ε) :
    nativeAdvantage uniformWide uniformWide adversary ≤ ε :=
  nativeAdvantage_le hTarget uniformWide uniformWide adversary ε hDDH

end DhConcrete
