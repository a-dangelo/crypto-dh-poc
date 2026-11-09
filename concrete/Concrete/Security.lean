import Concrete.Model

namespace DhConcrete
open OracleComp OracleSpec

/-- The concrete model's session advantage equals its sampled-DDH advantage.
The correspondence preserves the raw-secret distributions. -/
theorem advantage_eq (μ ν : ProbComp Secret)
    (adversary : Public → Public → Key → ProbComp Bool) :
    DhPoc.sampledSessionAdvantage model μ ν adversary =
      DhPoc.sampledDDHAdvantage decodeScalar generator μ ν
        (DhPoc.rawReduction model adversary) :=
  DhPoc.sampledSessionAdvantage_eq model μ ν adversary

#print axioms advantage_eq
end DhConcrete
