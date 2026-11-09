import Concrete.Model

namespace DhConcrete
open OracleComp OracleSpec

/-- Concrete real/ideal distinguishing advantage equals sampled-DDH advantage.
The raw input distributions are unchanged; no uniform-secret replacement is made. -/
theorem advantage_eq (μ ν : ProbComp Secret)
    (adversary : Public → Public → Key → ProbComp Bool) :
    DhPoc.sampledSessionAdvantage model μ ν adversary =
      DhPoc.sampledDDHAdvantage decodeScalar generator μ ν
        (DhPoc.rawReduction model adversary) :=
  DhPoc.sampledSessionAdvantage_eq model μ ν adversary

#print axioms advantage_eq
end DhConcrete
