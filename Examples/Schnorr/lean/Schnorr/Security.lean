import Schnorr.Refinement

/-! Security transfer with ideal independent field randomness. This is not a claim
about an implemented RNG, byte parsing, a concrete group backend, malicious-verifier
zero knowledge, or Fiat–Shamir signatures. The observed output retains the complete
Aeneas `Result`, so errors and divergence are never replaced with default successes. -/
namespace SchnorrProof

open OracleSpec OracleComp
open Aeneas.Std

variable {F G D S P : Type} [Field F] [SampleableType F]
  [AddCommGroup G] [Module F G] [SampleableType G] [DecidableEq G]
  {g : G} (M : PrimitiveModel F G D S P g)

/-- The public transcript observation, including every Result constructor. -/
def observeMessages (c : S) (out : Result (schnorr_core.Messages P S)) :
    Result (P × S × S) := do
  let msg ← out
  pure (msg.commitment, c, msg.response)

@[simp] theorem observeMessages_fail (c : S) (e : Error) :
    observeMessages (P := P) c (.fail e) = .fail e := by
  simp [observeMessages]

@[simp] theorem observeMessages_div (c : S) :
    observeMessages (P := P) c .div = .div := by
  simp [observeMessages]

/-- Run the extracted commitment before sampling the challenge, then run the
extracted response. A failed or divergent commitment remains a failed or divergent
observation, rather than being replaced by a successful transcript. The primitive
contract proves that commitment returns successfully; hence an effect branch is
unreachable. This argument is independent of the runtime's effect vocabulary. -/
def rustTranscript (sk : F) : ProbComp (Result (P × S × S)) := do
  let r ← $ᵗ F
  match h : (schnorr_core.commit M.ops (M.scalar r)).match with
  | .ok R => do
    let c ← $ᵗ F
    pure (do
      let z ← schnorr_core.respond M.ops (M.scalar sk) (M.scalar r) (M.scalar c)
      pure (R, M.scalar c, z))
  | .div => pure .div
  | .vis _ _ => False.elim (by simp [commit_eq] at h)

/-- The extracted batch helper under the same ideal independent samples. -/
def batchTranscript (sk : F) : ProbComp (Result (P × S × S)) := do
  let r ← $ᵗ F
  let c ← $ᵗ F
  pure (observeMessages (M.scalar c)
    (schnorr_core.messages M.ops (M.scalar sk) (M.scalar r) (M.scalar c)))

omit [SampleableType G] in
/-- Interactive ordering and the batch helper have identical transcript outputs
under the explicit primitive contracts. -/
theorem rustTranscript_eq_batch (sk : F) :
    rustTranscript M sk = batchTranscript M sk := by
  unfold rustTranscript batchTranscript
  congr 1
  funext r
  split
  · simp_all [commit_eq, respond_eq, messages_eq, observeMessages]
  · rename_i heq
    simp [commit_eq] at heq
  · rename_i eff k heq
    simp [commit_eq] at heq

/-- Encode a complete mathematical transcript as a successful native observation. -/
def encodeTranscript (t : G × F × F) : Result (P × S × S) :=
  .ok (M.point t.1, M.scalar t.2.1, M.scalar t.2.2)

def encodedRealTranscript (pk : G) (sk : F) : ProbComp (Result (P × S × S)) :=
  encodeTranscript M <$> (Schnorr.sigma F G g).realTranscript pk sk

/-- The simulator needs only the public statement, not the witness. -/
def encodedSimulator (pk : G) : ProbComp (Result (P × S × S)) :=
  encodeTranscript M <$> Schnorr.simTranscript F G g pk

/-- A pointwise program equality, hence also equality in distribution. The left
side runs the extracted Rust `commit` and `respond`, not a replacement mathematical prover. -/
theorem rustTranscript_eq_encodedReal (pk : G) (sk : F) :
    rustTranscript M sk = encodedRealTranscript M pk sk := by
  rw [rustTranscript_eq_batch]
  simp [batchTranscript, encodedRealTranscript, ChallengeVerifyProtocol.realTranscript,
    Schnorr.sigma, monad_norm, messages_eq, observeMessages, encodeTranscript]
  rfl

/-- The actual extracted `messages` helper also realizes the encoded VCVio
transcript when nonce and challenge are sampled independently. -/
theorem batchTranscript_eq_encodedReal (pk : G) (sk : F) :
    batchTranscript M sk = encodedRealTranscript M pk sk :=
  (rustTranscript_eq_batch M sk).symm.trans (rustTranscript_eq_encodedReal M pk sk)

omit [SampleableType G] in
/-- Explicit distribution of the encoded public-input-only simulator. -/
theorem encodedSimulator_eq (pk : G) :
    encodedSimulator M pk = (do
      let c ← $ᵗ F
      let z ← $ᵗ F
      pure (.ok (M.point (z • g - c • pk), M.scalar c, M.scalar z))) := by
  simp [encodedSimulator, Schnorr.simTranscript, encodeTranscript, monad_norm]

/-- Perfect honest-verifier zero knowledge transferred from pinned VCVio Schnorr
via a deterministic encoding of observations. Requires a valid witness relation. -/
theorem perfect_hvzk (pk : G) (sk : F) (hsk : sk • g = pk) :
    rustTranscript M sk =ᵈ encodedSimulator M pk := by
  rw [rustTranscript_eq_encodedReal M pk sk]
  exact (Schnorr.sigma_hvzk F G g pk sk (by simpa using hsk)).map (encodeTranscript M)


end SchnorrProof
