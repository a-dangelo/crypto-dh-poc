//! Coin-explicit, one-session DH over the pinned verified dalek backend.
use crate::ristretto::{CompressedRistretto, RistrettoPoint};
use crate::scalar::Scalar;

pub struct Session {
    pub alice_public: [u8; 32],
    pub bob_public: [u8; 32],
    pub alice_key: Option<[u8; 32]>,
    pub bob_key: Option<[u8; 32]>,
}

pub fn public(random_bytes: &[u8; 64]) -> [u8; 32] {
    let scalar = Scalar::from_bytes_mod_order_wide(random_bytes);
    RistrettoPoint::mul_base(&scalar).compress().to_bytes()
}

pub fn agree(random_bytes: &[u8; 64], peer_bytes: &[u8; 32]) -> Option<[u8; 32]> {
    let scalar = Scalar::from_bytes_mod_order_wide(random_bytes);
    match CompressedRistretto(*peer_bytes).decompress() {
        Some(peer) => Some((&peer * &scalar).compress().to_bytes()),
        None => None,
    }
}

pub fn session(alice: &[u8; 64], bob: &[u8; 64]) -> Session {
    let alice_public = public(alice);
    let bob_public = public(bob);
    let alice_key = agree(alice, &bob_public);
    let bob_key = agree(bob, &alice_public);
    Session { alice_public, bob_public, alice_key, bob_key }
}
