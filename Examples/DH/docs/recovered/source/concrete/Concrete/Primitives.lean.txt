import Concrete.Algebra
import Proofs.Scalar.FromBytesModOrderWide
import Proofs.Ristretto.MulBase
import Proofs.Ristretto.Compress
import Proofs.Ristretto.Decompress
import Proofs.Ristretto.Mul
import Proofs.Ristretto.ToBytes

open Aeneas Aeneas.Std Result Aeneas.Std.WP
open Curve25519Dalek curve25519
namespace DhConcrete

/-- Helper composition of extracted primitives; Native.lean proves equality to the extracted adapter. -/
noncomputable def publicCompose (raw : Array U8 64#usize) : Result (Array U8 32#usize) := do
  let s ← scalar.Scalar.from_bytes_mod_order_wide raw
  let p ← ristretto.«RistrettoPointx86_64-no-tables».mul_base s
  let c ← ristretto.«RistrettoPointx86_64-no-tables».compress p
  ristretto.CompressedRistretto.to_bytes c

theorem publicCompose_spec (raw : Array U8 64#usize) :
    publicCompose raw ⦃ r => r.asNat 8 =
      Ristretto.encodeRep ((raw.asNat 8 % L) • basepoint) ⦄ := by
  unfold publicCompose
  step as ⟨s, hs⟩
  have hsb : s.asNat < 2 ^ 255 := by
    rw [hs]
    exact lt_trans (Nat.mod_lt _ L_pos) (lt_trans L_lt_two_pow_253 (by norm_num))
  step as ⟨p, hpon, hpeven, hp, hpb⟩
  step as ⟨c, hc⟩
  step as ⟨r, hr⟩
  subst r
  change c.asNat = _
  rw [hc, hp, hs]

noncomputable def agreeCompose (raw : Array U8 64#usize) (peer : Array U8 32#usize) :
    Result (Option (Array U8 32#usize)) := do
  let s ← scalar.Scalar.from_bytes_mod_order_wide raw
  let p ← ristretto.CompressedRistretto.decompress.«x86_64-no-tables» peer
  match p with
  | none => pure none
  | some p =>
    let q ← «Shared0RistrettoPointx86_64-no-tables».Insts.«CoreOpsArithMulSharedAScalarRistrettoPointx86_64-no-tables».mul p s
    let c ← ristretto.«RistrettoPointx86_64-no-tables».compress q
    let r ← ristretto.CompressedRistretto.to_bytes c
    pure (some r)

/-- Agreement on every honest public encoding, irrespective of decoded representative. -/
theorem agreeCompose_spec (raw : Array U8 64#usize) (peer : Array U8 32#usize)
    (g : Group) (hpeer : peer.asNat 8 = encode g) :
    agreeCompose raw peer ⦃ r => ∃ bytes, r = some bytes ∧ bytes.asNat 8 =
      Ristretto.encodeRep ((raw.asNat 8 % L) • g.val) ⦄ := by
  unfold agreeCompose
  step as ⟨s, hs⟩
  have hsb : s.asNat < 2 ^ 255 := by
    rw [hs]
    exact lt_trans (Nat.mod_lt _ L_pos) (lt_trans L_lt_two_pow_253 (by norm_num))
  step as ⟨p, hp, hpvalid⟩
  obtain ⟨q, hq, _⟩ := decode_encode g
  have hdec : p.map edwards.EdwardsPoint.«x86_64-no-tables».toPoint = some q := by
    rw [hp]
    change Ristretto.decodeRep (peer.asNat 8) = some q
    rw [hpeer, hq]
  cases p with
  | none => simp at hdec
  | some p =>
    have hqeq : p.toPoint = q := by simpa using hdec
    obtain ⟨hpon, hpeven, hpb⟩ := hpvalid p rfl
    step as ⟨r, hron, hr, hrb⟩
    step as ⟨c, hc⟩
    step as ⟨bytes, hbytes⟩
    refine ⟨bytes, rfl, ?_⟩
    subst bytes
    change c.asNat = _
    rw [hc, hr, hs, hqeq]
    exact agree_decode g _ q hq

#print axioms publicCompose_spec
#print axioms agreeCompose_spec
end DhConcrete
