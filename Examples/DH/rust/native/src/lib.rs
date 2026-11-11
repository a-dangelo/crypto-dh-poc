//! Concrete adapter. This file is tested, but is outside the extracted proof.
use dh_core::Dh;
use ristretto255_dh::{EphemeralSecret, PublicKey};

pub struct RistrettoDh;
impl Dh for RistrettoDh {
    type Secret = [u8; 64];
    type Public = [u8; 32];
    type Key = Option<[u8; 32]>;
    fn public(secret: &Self::Secret) -> Self::Public {
        PublicKey::from(&EphemeralSecret::from(*secret)).into()
    }
    fn agree(secret: &Self::Secret, peer: &Self::Public) -> Self::Key {
        match PublicKey::try_from(*peer) {
            Ok(public) => Some(
                EphemeralSecret::from(*secret)
                    .diffie_hellman(&public)
                    .into(),
            ),
            Err(_) => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rand_core::{OsRng, RngCore};

    #[test]
    fn agreement_for_128_real_sessions() {
        for _ in 0..128 {
            let mut a = [0; 64];
            let mut b = [0; 64];
            OsRng.fill_bytes(&mut a);
            OsRng.fill_bytes(&mut b);
            let out = dh_core::session::<RistrettoDh>(&a, &b);
            assert_eq!(out.alice_key, out.bob_key);
            assert!(out.alice_key.is_some());
            assert_eq!(out.alice_key, RistrettoDh::agree(&a, &out.bob_public));
        }
    }

    #[test]
    fn malformed_public_encoding_is_rejected() {
        assert_eq!(RistrettoDh::agree(&[1; 64], &[255; 32]), None);
    }

    #[test]
    fn deterministic_edges_and_zero_secret_are_not_hidden() {
        for a in [[0; 64], [1; 64], [255; 64]] {
            for b in [[0; 64], [2; 64], [255; 64]] {
                let out = dh_core::session::<RistrettoDh>(&a, &b);
                assert_eq!(out.alice_key, out.bob_key);
                if a == [0; 64] || b == [0; 64] {
                    assert_eq!(out.alice_key, Some([0; 32]));
                }
            }
        }
    }
}
