//! Executable Ristretto instance for tests. Its primitive contracts are not
//! discharged by the Lean development; the proved endpoint remains generic.
use curve25519_dalek::{ristretto::RistrettoPoint, scalar::Scalar};
use schnorr_core::Group;

pub struct Ristretto;

impl Group for Ristretto {
    type Scalar = Scalar;
    type Point = RistrettoPoint;
    fn base_mul(s: &Scalar) -> RistrettoPoint {
        RistrettoPoint::mul_base(s)
    }
    fn point_mul(p: &RistrettoPoint, s: &Scalar) -> RistrettoPoint {
        p * s
    }
    fn point_add(p: &RistrettoPoint, q: &RistrettoPoint) -> RistrettoPoint {
        p + q
    }
    fn scalar_add(a: &Scalar, b: &Scalar) -> Scalar {
        a + b
    }
    fn scalar_mul(a: &Scalar, b: &Scalar) -> Scalar {
        a * b
    }
    fn point_eq(p: &RistrettoPoint, q: &RistrettoPoint) -> bool {
        p == q
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use schnorr_core::{commit, messages, public, respond, verify};

    #[test]
    fn honest_transcripts_and_mutations() {
        for i in 0..32u64 {
            let sk = Scalar::from(i);
            let nonce = Scalar::from(i * i + 3);
            let challenge = Scalar::from(i + 7);
            let pk = public::<Ristretto>(&sk);
            let out = messages::<Ristretto>(&sk, &nonce, &challenge);
            assert!(verify::<Ristretto>(
                &pk,
                &out.commitment,
                &challenge,
                &out.response
            ));
            assert!(!verify::<Ristretto>(
                &pk,
                &out.commitment,
                &challenge,
                &(out.response + Scalar::ONE)
            ));
            assert!(!verify::<Ristretto>(
                &pk,
                &(out.commitment + RistrettoPoint::mul_base(&Scalar::ONE)),
                &challenge,
                &out.response
            ));
        }
    }

    #[test]
    fn stateful_entry_point_consumes_one_scalar() {
        struct Fixed {
            nonce: Scalar,
            calls: u8,
        }
        impl schnorr_core::ScalarRng<Scalar> for Fixed {
            fn sample(&mut self) -> Scalar {
                self.calls += 1;
                self.nonce
            }
        }
        let nonce = Scalar::from(17u64);
        let mut rng = Fixed { nonce, calls: 0 };
        let (commitment, sampled) = schnorr_core::commit_random::<Ristretto, _>(&mut rng);
        assert_eq!(rng.calls, 1);
        assert_eq!(sampled, nonce);
        assert_eq!(commitment, commit::<Ristretto>(&nonce));
    }

    #[test]
    fn two_distinct_challenges_extract_the_witness() {
        let sk = Scalar::from(29u64);
        let nonce = Scalar::from(71u64);
        let c1 = Scalar::from(3u64);
        let c2 = Scalar::from(8u64);
        let pk = public::<Ristretto>(&sk);
        let commitment = commit::<Ristretto>(&nonce);
        let z1 = respond::<Ristretto>(&sk, &nonce, &c1);
        let z2 = respond::<Ristretto>(&sk, &nonce, &c2);
        assert!(verify::<Ristretto>(&pk, &commitment, &c1, &z1));
        assert!(verify::<Ristretto>(&pk, &commitment, &c2, &z2));
        let extracted = (z1 - z2) * (c1 - c2).invert();
        assert_eq!(extracted, sk);
        assert_eq!(public::<Ristretto>(&extracted), pk);
    }
}
