//! Exhaustive control-flow regression over F_7. This is not a secure group.
use schnorr_core::{messages, public, verify, Group};
struct Mod7;
impl Group for Mod7 {
    type Scalar = u8;
    type Point = u8;
    fn base_mul(s: &u8) -> u8 {
        s % 7
    }
    fn point_mul(p: &u8, s: &u8) -> u8 {
        (p * s) % 7
    }
    fn point_add(p: &u8, q: &u8) -> u8 {
        (p + q) % 7
    }
    fn scalar_add(a: &u8, b: &u8) -> u8 {
        (a + b) % 7
    }
    fn scalar_mul(a: &u8, b: &u8) -> u8 {
        (a * b) % 7
    }
    fn point_eq(p: &u8, q: &u8) -> bool {
        p == q
    }
}
#[test]
fn every_honest_transcript_accepts() {
    for sk in 0..7 {
        for r in 0..7 {
            for c in 0..7 {
                let pk = public::<Mod7>(&sk);
                let out = messages::<Mod7>(&sk, &r, &c);
                assert!(verify::<Mod7>(&pk, &out.commitment, &c, &out.response));
                assert!(!verify::<Mod7>(
                    &pk,
                    &out.commitment,
                    &c,
                    &((out.response + 1) % 7)
                ));
            }
        }
    }
}
