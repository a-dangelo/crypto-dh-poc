import Verso
import VersoManual
import VersoBlueprint
import DhBlueprint.Code
import Concrete.Standard

open Verso.Genre Verso.Genre.Manual Informal

#doc (Manual) "Sampling and the DDH bound" =>
%%%
tag := "sampling"
%%%

We compare the decoded wide-input law with uniform scalar sampling.
Write $`N=2^{512}` and $`r=N\bmod L`.
Total variation distance, written $`\operatorname{TV}(\mu,\nu)`, is the
largest absolute difference between the probabilities that two laws assign to the
same event. For finite probability laws,
$`\operatorname{TV}(\mu,\nu)=\frac12\sum_x|\mu(x)-\nu(x)|`.

::::definition "wide_sampler" (lean := "DhConcrete.uniformWide")
:::AnchorlessBlueprint.pair DhConcrete.uniformWide -docstrings
The sampler draws uniformly from $`\mathrm{Fin}(N)` and encodes the
result as 64 little-endian bytes. The proved decoding identity gives

$$`d_*\Omega=(n\mapsto n\bmod L)_*U_{\mathrm{Fin}(N)}.`
:::
::::

::::theorem "bias_bound" (lean := "DhConcrete.uniformWide_scalar_measureETVDist_le") (uses := "wide_sampler")
:::AnchorlessBlueprint.pair DhConcrete.uniformWide_scalar_measureETVDist_le -docstrings
The decoded law satisfies

$$`\operatorname{TV}(d_*\Omega,U_{\mathbb Z/L\mathbb Z})\le r/N.`

The modulo-sampling lemma bounds arbitrary events through quotient
and remainder counts. The bound therefore controls total variation, not merely
point probabilities. We use this upper bound, without claiming the sharp
distance formula.
:::
::::

::::theorem "hybrid_bound" (lean := "DhPoc.sampledDDHAdvantage_le_standard") (uses := "ddh_real, ddh_random")
:::AnchorlessBlueprint.pair DhPoc.sampledDDHAdvantage_le_standard -docstrings
Replacing the two secret laws in each experiment gives

$$`\operatorname{Adv}_{\rm sampledDDH}
\le\operatorname{Adv}_{\rm DDH}
+2\bigl(\operatorname{TV}(d_*\mu,U)
+\operatorname{TV}(d_*\nu,U)\bigr).`

The ideal experiment's independent uniform challenge remains unchanged.
The four replacement costs follow from contraction under bind and the
triangle inequality for acceptance-probability distance.
:::
::::

::::theorem "numeric_loss" (lean := "DhConcrete.four_wideSamplingError_lt")
:::AnchorlessBlueprint.pair DhConcrete.four_wideSamplingError_lt -docstrings
For the Ristretto scalar order, exact arithmetic gives

$$`4\frac{2^{512}\bmod L}{2^{512}}<2^{-260}.`

Combining this inequality with {bpref "game_transport"}[exact transport]
and the hybrid bound proves {bpref "main_bound"}[the standard-DDH corollary].
:::
::::

The term $`2^{-260}` is a fixed statistical loss. It is not an asymptotic
negligibility statement. {ref "trust"}[The security scope] records the
separate requirements for such a statement.
