import Verso
import VersoManual
import VersoBlueprint

open Verso.Genre Verso.Genre.Manual Informal

#doc (Manual) "Diffie–Hellman in one page" =>
%%%
tag := "dh"
%%%

Diffie–Hellman lets two parties compute the same secret group element from
private scalars and public messages. Write the group additively, with
basepoint $`g` and scalar order $`L`.

Alice chooses $`\alpha\in\mathbb Z/L\mathbb Z` and sends $`X=\alpha g`.
Bob chooses $`\beta\in\mathbb Z/L\mathbb Z` and sends $`Y=\beta g`.
Alice computes $`\alpha Y` and Bob computes $`\beta X`. These agree because

$$`\alpha Y=(\alpha\beta)g=(\beta\alpha)g=\beta X.`

For the stated security bound, the caller's 64-byte inputs $`a,b` are sampled
independently and uniformly. The implementation sets $`\alpha=d(a)`,
$`\beta=d(b)`, where
$`d(s)=\operatorname{LE}(s)\bmod L`. It sends canonical Ristretto encodings
$`p(X),p(Y)` and returns the shared encoding $`p((\alpha\beta)g)`.
“Raw” refers to the byte inputs before this scalar reduction.
{bpref "session_refinement"}[Session refinement] proves this equation for
the extracted program, including successful execution and equal local keys.

Correctness says that the parties agree. The security experiment asks whether
a passive observer can distinguish their shared encoding from an independent
encoded group element, given $`p(X),p(Y)`. The DDH assumption bounds the
corresponding test on group elements. {bpref "encoding_reduction"}[The reduction]
converts those elements to the byte values expected by the observer.
{ref "sampling"}[The sampling comparison] accounts for the small bias from
reduction modulo $`L`.

This exchange does not authenticate either party. An active intermediary can
establish a different secret with each party. The theorem concerns one honest
exchange observed passively. A KDF and a protocol for authentication or
repeated key updates require separate constructions and security games.
