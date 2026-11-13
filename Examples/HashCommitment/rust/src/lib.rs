//! Hash-based commitment scheme, generic over an abstract keyed hash.
//!
//! * `commit(k, m, rng) = (H(k, m, s), s)` where `s` is 32 fresh bytes from `rng`.
//! * `verify(k, m, c, s) = (H(k, m, s) == c)`.
//!
//! This crate is extracted to Lean with Charon + Aeneas (see `../README.md`).
//! It is deliberately written in the small fragment of Rust that Aeneas supports.
#![no_std]

use rand_core::{CryptoRng, RngCore};

/// Length of a message, in bytes.
pub const MSG_LEN: usize = 32;
/// Length of an opening (the commitment randomness), in bytes.
pub const OPENING_LEN: usize = 32;
/// Length of a commitment (a hash digest), in bytes.
pub const DIGEST_LEN: usize = 32;

/// An abstract keyed hash of a `(message, opening)` pair: `K × [u8; 32] × [u8; 32] → [u8; 32]`.
///
/// The two parts are passed separately; an implementation typically absorbs them with two
/// `update` calls on a streaming hasher. No concrete hash is provided: the scheme is generic
/// over this trait, and on the Lean side it becomes the `hash` field of VCVio's
/// `KeyedHashFamily K (M × S) C`.
pub trait KeyedHash<K> {
    fn hash(key: &K, msg: &[u8; MSG_LEN], opening: &[u8; OPENING_LEN]) -> [u8; DIGEST_LEN];
}

/// Commit to `msg` using 32 bytes supplied by `rng` and hash `(msg, opening)`.
/// Uniformity is a contract of the selected RNG model, not of `CryptoRng`.
/// Returns `(commitment, opening)`.
pub fn commit<K, H: KeyedHash<K>, R: RngCore + CryptoRng>(
    key: &K,
    msg: &[u8; MSG_LEN],
    rng: &mut R,
) -> ([u8; DIGEST_LEN], [u8; OPENING_LEN]) {
    let mut opening = [0u8; OPENING_LEN];
    rng.fill_bytes(&mut opening);
    let c = H::hash(key, msg, &opening);
    (c, opening)
}

/// Verify that `opening` opens `c` to `msg`.
pub fn verify<K, H: KeyedHash<K>>(
    key: &K,
    msg: &[u8; MSG_LEN],
    c: &[u8; DIGEST_LEN],
    opening: &[u8; OPENING_LEN],
) -> bool {
    let h = H::hash(key, msg, opening);
    h == *c
}

/// Draw two bytes in two distinct calls. The nonzero buffers test complete overwrite.
pub fn fresh_draws<R: RngCore + CryptoRng>(rng: &mut R) -> (u8, u8) {
    let mut first = [173u8; 1];
    let mut second = [91u8; 1];
    rng.fill_bytes(&mut first);
    rng.fill_bytes(&mut second);
    (first[0], second[0])
}

/// Draw one byte and return that same value twice.
pub fn reused_draw<R: RngCore + CryptoRng>(rng: &mut R) -> (u8, u8) {
    let mut byte = [173u8; 1];
    rng.fill_bytes(&mut byte);
    (byte[0], byte[0])
}

/// Branch on a sampled byte. Under ideal entropy, the true branch has probability 1/256.
pub fn branch_draw<R: RngCore + CryptoRng>(rng: &mut R) -> bool {
    let mut byte = [173u8; 1];
    rng.fill_bytes(&mut byte);
    if byte[0] == 0 {
        true
    } else {
        false
    }
}

/// Exercise `fill_bytes` at length zero; no byte is requested.
pub fn empty_draw<R: RngCore + CryptoRng>(rng: &mut R) {
    let mut empty = [];
    rng.fill_bytes(&mut empty);
}

/// Abstract effectful call used only to test extraction's duplicate-call optimization.
/// The trait has no Rust implementation in the library.
pub trait OpaqueEntropy {
    fn sample() -> u8;
}

/// Two identical opaque calls must remain distinct in probabilistic extraction mode.
pub fn duplicate_opaque<E: OpaqueEntropy>() -> (u8, u8) {
    let first = E::sample();
    let second = E::sample();
    (first, second)
}

/// An unused answer does not make its sampling event removable.
pub fn unused_opaque<E: OpaqueEntropy>() -> u8 {
    let _discarded = E::sample();
    E::sample()
}

#[cfg(test)]
mod tests {
    //! Smoke tests only (not extracted: Charon does not see `cfg(test)` code).
    //! The toy hash and RNG below are NOT cryptographic.
    use super::*;
    use rand_core::{impls, CryptoRng, RngCore};

    /// Toy streaming "hasher": NOT collision resistant, just for testing the plumbing.
    struct ToyHasher {
        key: u8,
        state: [u8; DIGEST_LEN],
        pos: usize,
    }
    impl ToyHasher {
        fn new(key: u8) -> Self {
            ToyHasher {
                key,
                state: [0u8; DIGEST_LEN],
                pos: 0,
            }
        }
        fn update(&mut self, data: &[u8]) {
            for b in data {
                let i = self.pos % DIGEST_LEN;
                self.state[i] = self.state[i].wrapping_mul(31).wrapping_add(*b ^ self.key);
                self.pos += 1;
            }
        }
        fn finalize(self) -> [u8; DIGEST_LEN] {
            self.state
        }
    }

    /// Toy keyed "hash": absorbs the message and the opening with two `update` calls.
    struct ToyHash;
    impl KeyedHash<u8> for ToyHash {
        fn hash(key: &u8, msg: &[u8; MSG_LEN], opening: &[u8; OPENING_LEN]) -> [u8; DIGEST_LEN] {
            let mut h = ToyHasher::new(*key);
            h.update(msg);
            h.update(opening);
            h.finalize()
        }
    }

    /// Toy counter RNG: NOT cryptographic, just for testing the plumbing.
    struct CounterRng(u64);
    impl RngCore for CounterRng {
        fn next_u32(&mut self) -> u32 {
            self.next_u64() as u32
        }
        fn next_u64(&mut self) -> u64 {
            self.0 = self.0.wrapping_add(0x9E37_79B9_7F4A_7C15);
            self.0
        }
        fn fill_bytes(&mut self, dst: &mut [u8]) {
            impls::fill_bytes_via_next(self, dst)
        }
    }
    impl CryptoRng for CounterRng {}

    #[test]
    fn commit_then_verify() {
        let mut rng = CounterRng(1);
        let msg = [7u8; MSG_LEN];
        let (c, s) = commit::<u8, ToyHash, _>(&3, &msg, &mut rng);
        assert!(verify::<u8, ToyHash>(&3, &msg, &c, &s));
        let mut other = msg;
        other[0] ^= 1;
        assert!(!verify::<u8, ToyHash>(&3, &other, &c, &s));
    }

    /// Deterministic fixture that counts and fills bytes; it is not a CSPRNG.
    struct ByteCounter {
        next: u8,
        calls: usize,
    }
    impl RngCore for ByteCounter {
        fn next_u32(&mut self) -> u32 {
            self.next_u64() as u32
        }
        fn next_u64(&mut self) -> u64 {
            let mut bytes = [0u8; 8];
            self.fill_bytes(&mut bytes);
            u64::from_le_bytes(bytes)
        }
        fn fill_bytes(&mut self, dst: &mut [u8]) {
            self.calls += 1;
            for byte in dst {
                *byte = self.next;
                self.next = self.next.wrapping_add(1);
            }
        }
    }
    impl CryptoRng for ByteCounter {}

    #[test]
    fn sampling_call_structure() {
        let mut rng = ByteCounter { next: 5, calls: 0 };
        assert_eq!(fresh_draws(&mut rng), (5, 6));
        assert_eq!(rng.calls, 2);
        assert_eq!(reused_draw(&mut rng), (7, 7));
        assert_eq!(rng.calls, 3);
        empty_draw(&mut rng);
        assert_eq!(rng.calls, 4);
        assert_eq!(rng.next, 8);
    }

    #[test]
    fn branch_all_bytes() {
        for next in 0..=255 {
            let mut rng = ByteCounter { next, calls: 0 };
            assert_eq!(branch_draw(&mut rng), next == 0);
            assert_eq!(rng.calls, 1);
        }
    }
}
