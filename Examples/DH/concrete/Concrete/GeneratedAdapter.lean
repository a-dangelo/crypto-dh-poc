-- Automatically sliced from the actual full Aeneas output. Do not edit.
-- The script checks all unchanged backend declarations against the pinned proof source.
import Curve25519Dalek.Funs
open Aeneas Aeneas.Std Result ControlFlow Error
noncomputable section
namespace Curve25519Dalek

/-- [curve25519_dalek::poc_dh::Session]
    Source: 'curve25519-dalek/src/poc_dh.rs', lines 5:0-10:1
    Visibility: public -/
structure poc_dh.Session where
  alice_public : Array Std.U8 32#usize
  bob_public : Array Std.U8 32#usize
  alice_key : Option (Array Std.U8 32#usize)
  bob_key : Option (Array Std.U8 32#usize)


/-- [curve25519_dalek::poc_dh::public::x86_64-tables]:
    Source: 'curve25519-dalek/src/poc_dh.rs', lines 12:0-15:1
    Visibility: public -/
def poc_dh.public.«x86_64-tables»
  (random_bytes : Array Std.U8 64#usize) : Result (Array Std.U8 32#usize) := do
  let scalar ← scalar.Scalar.from_bytes_mod_order_wide random_bytes
  let rp ← ristretto.«RistrettoPointx86_64-tables».mul_base scalar
  let cr ← ristretto.«RistrettoPointx86_64-tables».compress rp
  ristretto.CompressedRistretto.to_bytes cr


/-- [curve25519_dalek::poc_dh::public::x86_64-no-tables]:
    Source: 'curve25519-dalek/src/poc_dh.rs', lines 12:0-15:1
    Visibility: public -/
def poc_dh.public.«x86_64-no-tables»
  (random_bytes : Array Std.U8 64#usize) : Result (Array Std.U8 32#usize) := do
  let scalar ← scalar.Scalar.from_bytes_mod_order_wide random_bytes
  let rp ← ristretto.«RistrettoPointx86_64-no-tables».mul_base scalar
  let cr ← ristretto.«RistrettoPointx86_64-no-tables».compress rp
  ristretto.CompressedRistretto.to_bytes cr


/-- [curve25519_dalek::poc_dh::public::i686-tables]:
    Source: 'curve25519-dalek/src/poc_dh.rs', lines 12:0-15:1
    Visibility: public -/
def poc_dh.public.«i686-tables»
  (random_bytes : Array Std.U8 64#usize) : Result (Array Std.U8 32#usize) := do
  let scalar ← scalar.Scalar.from_bytes_mod_order_wide random_bytes
  let rp ← ristretto.«RistrettoPointi686-tables».mul_base scalar
  let cr ← ristretto.«RistrettoPointi686-tables».compress rp
  ristretto.CompressedRistretto.to_bytes cr


/-- [curve25519_dalek::poc_dh::public::i686-no-tables]:
    Source: 'curve25519-dalek/src/poc_dh.rs', lines 12:0-15:1
    Visibility: public -/
def poc_dh.public.«i686-no-tables»
  (random_bytes : Array Std.U8 64#usize) : Result (Array Std.U8 32#usize) := do
  let scalar ← scalar.Scalar.from_bytes_mod_order_wide random_bytes
  let rp ← ristretto.«RistrettoPointi686-no-tables».mul_base scalar
  let cr ← ristretto.«RistrettoPointi686-no-tables».compress rp
  ristretto.CompressedRistretto.to_bytes cr


/-- [curve25519_dalek::poc_dh::public]:
    Source: 'curve25519-dalek/src/poc_dh.rs', lines 12:0-15:1
    Visibility: public -/
def poc_dh.public
  (a : Array Std.U8 64#usize) : Result (Array Std.U8 32#usize) := do
  let tgt ← get_target
  if tgt = "x86_64-tables"
  then poc_dh.public.«x86_64-tables» a
  else
    if tgt = "x86_64-no-tables"
    then poc_dh.public.«x86_64-no-tables» a
    else
      if tgt = "i686-tables"
      then poc_dh.public.«i686-tables» a
      else poc_dh.public.«i686-no-tables» a


/-- [curve25519_dalek::poc_dh::agree::x86_64-tables]:
    Source: 'curve25519-dalek/src/poc_dh.rs', lines 17:0-23:1
    Visibility: public -/
def poc_dh.agree.«x86_64-tables»
  (random_bytes : Array Std.U8 64#usize) (peer_bytes : Array Std.U8 32#usize) :
  Result (Option (Array Std.U8 32#usize))
  := do
  let scalar ← scalar.Scalar.from_bytes_mod_order_wide random_bytes
  let o ←
    ristretto.CompressedRistretto.decompress.«x86_64-tables» peer_bytes
  match o with
  | none => ok none
  | some peer =>
    let rp ←
      «Shared0RistrettoPointx86_64-tables».Insts.«CoreOpsArithMulSharedAScalarRistrettoPointx86_64-tables».mul
        peer scalar
    let cr ← ristretto.«RistrettoPointx86_64-tables».compress rp
    let a ← ristretto.CompressedRistretto.to_bytes cr
    ok (some a)


/-- [curve25519_dalek::poc_dh::agree::x86_64-no-tables]:
    Source: 'curve25519-dalek/src/poc_dh.rs', lines 17:0-23:1
    Visibility: public -/
def poc_dh.agree.«x86_64-no-tables»
  (random_bytes : Array Std.U8 64#usize) (peer_bytes : Array Std.U8 32#usize) :
  Result (Option (Array Std.U8 32#usize))
  := do
  let scalar ← scalar.Scalar.from_bytes_mod_order_wide random_bytes
  let o ←
    ristretto.CompressedRistretto.decompress.«x86_64-no-tables» peer_bytes
  match o with
  | none => ok none
  | some peer =>
    let rp ←
      «Shared0RistrettoPointx86_64-no-tables».Insts.«CoreOpsArithMulSharedAScalarRistrettoPointx86_64-no-tables».mul
        peer scalar
    let cr ← ristretto.«RistrettoPointx86_64-no-tables».compress rp
    let a ← ristretto.CompressedRistretto.to_bytes cr
    ok (some a)


/-- [curve25519_dalek::poc_dh::agree::i686-tables]:
    Source: 'curve25519-dalek/src/poc_dh.rs', lines 17:0-23:1
    Visibility: public -/
def poc_dh.agree.«i686-tables»
  (random_bytes : Array Std.U8 64#usize) (peer_bytes : Array Std.U8 32#usize) :
  Result (Option (Array Std.U8 32#usize))
  := do
  let scalar ← scalar.Scalar.from_bytes_mod_order_wide random_bytes
  let o ← ristretto.CompressedRistretto.decompress.«i686-tables» peer_bytes
  match o with
  | none => ok none
  | some peer =>
    let rp ←
      «Shared0RistrettoPointi686-tables».Insts.«CoreOpsArithMulSharedAScalarRistrettoPointi686-tables».mul
        peer scalar
    let cr ← ristretto.«RistrettoPointi686-tables».compress rp
    let a ← ristretto.CompressedRistretto.to_bytes cr
    ok (some a)


/-- [curve25519_dalek::poc_dh::agree::i686-no-tables]:
    Source: 'curve25519-dalek/src/poc_dh.rs', lines 17:0-23:1
    Visibility: public -/
def poc_dh.agree.«i686-no-tables»
  (random_bytes : Array Std.U8 64#usize) (peer_bytes : Array Std.U8 32#usize) :
  Result (Option (Array Std.U8 32#usize))
  := do
  let scalar ← scalar.Scalar.from_bytes_mod_order_wide random_bytes
  let o ←
    ristretto.CompressedRistretto.decompress.«i686-no-tables» peer_bytes
  match o with
  | none => ok none
  | some peer =>
    let rp ←
      «Shared0RistrettoPointi686-no-tables».Insts.«CoreOpsArithMulSharedAScalarRistrettoPointi686-no-tables».mul
        peer scalar
    let cr ← ristretto.«RistrettoPointi686-no-tables».compress rp
    let a ← ristretto.CompressedRistretto.to_bytes cr
    ok (some a)


/-- [curve25519_dalek::poc_dh::agree]:
    Source: 'curve25519-dalek/src/poc_dh.rs', lines 17:0-23:1
    Visibility: public -/
def poc_dh.agree
  (a : Array Std.U8 64#usize) (a1 : Array Std.U8 32#usize) :
  Result (Option (Array Std.U8 32#usize))
  := do
  let tgt ← get_target
  if tgt = "x86_64-tables"
  then poc_dh.agree.«x86_64-tables» a a1
  else
    if tgt = "x86_64-no-tables"
    then poc_dh.agree.«x86_64-no-tables» a a1
    else
      if tgt = "i686-tables"
      then poc_dh.agree.«i686-tables» a a1
      else poc_dh.agree.«i686-no-tables» a a1


/-- [curve25519_dalek::poc_dh::session]:
    Source: 'curve25519-dalek/src/poc_dh.rs', lines 25:0-31:1
    Visibility: public -/
def poc_dh.session
  (alice : Array Std.U8 64#usize) (bob : Array Std.U8 64#usize) :
  Result poc_dh.Session
  := do
  let alice_public ← poc_dh.public alice
  let bob_public ← poc_dh.public bob
  let alice_key ← poc_dh.agree alice bob_public
  let bob_key ← poc_dh.agree bob alice_public
  ok { alice_public, bob_public, alice_key, bob_key }


end Curve25519Dalek
