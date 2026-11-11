#![no_std]
//! One honest, passive Diffie–Hellman session. No network or random sampler.

/// The boundary between protocol control flow and a concrete group library.
/// Aeneas translates this trait into an explicit record of operations.
pub trait Dh {
    type Secret;
    type Public;
    type Key;
    fn public(secret: &Self::Secret) -> Self::Public;
    fn agree(secret: &Self::Secret, peer: &Self::Public) -> Self::Key;
}

/// Public transcript and both local outputs. Keys stay local in a real protocol.
pub struct Session<P, K> {
    pub alice_public: P,
    pub bob_public: P,
    pub alice_key: K,
    pub bob_key: K,
}

/// Run the actual protocol control flow over two caller-supplied secrets.
/// The native adapter uses the existing ristretto255-dh implementation.
pub fn session<D: Dh>(alice: &D::Secret, bob: &D::Secret) -> Session<D::Public, D::Key> {
    let alice_public = D::public(alice);
    let bob_public = D::public(bob);
    let alice_key = D::agree(alice, &bob_public);
    let bob_key = D::agree(bob, &alice_public);
    Session {
        alice_public,
        bob_public,
        alice_key,
        bob_key,
    }
}
