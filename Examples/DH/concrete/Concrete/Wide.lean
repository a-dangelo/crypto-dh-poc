import Concrete.Native
import Concrete.Sampler

namespace DhConcrete
open Aeneas.Std OracleComp OracleSpec ENNReal

/-- The extracted session advantage for two independent ideal 512-bit inputs
equals the corresponding sampled-DDH advantage after reduction modulo L. -/
theorem wideAdvantage_eq (hTarget : target = "x86_64-no-tables")
    (adversary : Public → Public → Key → ProbComp Bool) :
    nativeAdvantage uniformWide uniformWide adversary =
      DhPoc.sampledDDHAdvantage decodeScalar generator uniformWide uniformWide
        (DhPoc.rawReduction model adversary) :=
  nativeAdvantage_eq hTarget uniformWide uniformWide adversary

/-- A supplied bound on wide-sampler DDH also bounds the extracted session advantage. -/
theorem wideAdvantage_le (hTarget : target = "x86_64-no-tables")
    (adversary : Public → Public → Key → ProbComp Bool) (ε : ℝ≥0∞)
    (hDDH : DhPoc.sampledDDHAdvantage decodeScalar generator uniformWide uniformWide
      (DhPoc.rawReduction model adversary) ≤ ε) :
    nativeAdvantage uniformWide uniformWide adversary ≤ ε :=
  nativeAdvantage_le hTarget uniformWide uniformWide adversary ε hDDH

end DhConcrete
