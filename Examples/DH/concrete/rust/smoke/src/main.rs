use curve25519_dalek::poc_dh;
use ristretto255_dh::{EphemeralSecret, PublicKey};

fn main() {
    for i in 0..128u8 {
        let a = [i; 64];
        let b = [i.wrapping_mul(3).wrapping_add(1); 64];
        let out = poc_dh::session(&a, &b);
        assert_eq!(out.alice_key, out.bob_key);
        assert!(out.alice_key.is_some());
        let legacy_a = EphemeralSecret::from(a);
        let legacy_b = EphemeralSecret::from(b);
        let legacy_ap = PublicKey::from(&legacy_a);
        let legacy_bp = PublicKey::from(&legacy_b);
        assert_eq!(out.alice_public, <[u8; 32]>::from(legacy_ap));
        assert_eq!(out.bob_public, <[u8; 32]>::from(legacy_bp));
        assert_eq!(out.alice_key, Some(legacy_a.diffie_hellman(&legacy_bp).into()));
    }
    assert_eq!(poc_dh::agree(&[1; 64], &[255; 32]), None);
    println!("128 deterministic sessions agree and match the legacy implementation; malformed public encoding rejected.");
}
