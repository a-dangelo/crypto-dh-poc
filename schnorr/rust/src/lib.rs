#![no_std]
//! Interactive Schnorr with explicit nonce and challenge inputs.
//! Group arithmetic, parsing, and entropy generation are separate boundaries.

/// Operations on valid scalar and group representations.
/// The Lean refinement states the required functional contracts.
pub trait Group {
    type Scalar;
    type Point;
    fn base_mul(s: &Self::Scalar) -> Self::Point;
    fn point_mul(p: &Self::Point, s: &Self::Scalar) -> Self::Point;
    fn point_add(p: &Self::Point, q: &Self::Point) -> Self::Point;
    fn scalar_add(a: &Self::Scalar, b: &Self::Scalar) -> Self::Scalar;
    fn scalar_mul(a: &Self::Scalar, b: &Self::Scalar) -> Self::Scalar;
    fn point_eq(p: &Self::Point, q: &Self::Point) -> bool;
}

pub struct Messages<P, S> {
    pub commitment: P,
    pub response: S,
}

pub fn public<G: Group>(secret: &G::Scalar) -> G::Point {
    G::base_mul(secret)
}

pub fn commit<G: Group>(nonce: &G::Scalar) -> G::Point {
    G::base_mul(nonce)
}

pub fn respond<G: Group>(
    secret: &G::Scalar,
    nonce: &G::Scalar,
    challenge: &G::Scalar,
) -> G::Scalar {
    let product = G::scalar_mul(challenge, secret);
    G::scalar_add(nonce, &product)
}

pub fn verify<G: Group>(
    public: &G::Point,
    commitment: &G::Point,
    challenge: &G::Scalar,
    response: &G::Scalar,
) -> bool {
    let lhs = G::base_mul(response);
    let product = G::point_mul(public, challenge);
    let rhs = G::point_add(commitment, &product);
    G::point_eq(&lhs, &rhs)
}

/// The deterministic prover core. A live protocol sends the commitment before
/// it receives the verifier's challenge; this helper returns both messages.
pub fn messages<G: Group>(
    secret: &G::Scalar,
    nonce: &G::Scalar,
    challenge: &G::Scalar,
) -> Messages<G::Point, G::Scalar> {
    let commitment = commit::<G>(nonce);
    let response = respond::<G>(secret, nonce, challenge);
    Messages {
        commitment,
        response,
    }
}

/// A stateful scalar sampler. No distribution or entropy quality is implied.
pub trait ScalarRng<S> {
    fn sample(&mut self) -> S;
}

/// The RNG-taking entry point. The extracted state transition is related to an
/// OracleComp sampling effect separately from its ideal probabilistic meaning.
pub fn commit_random<G: Group, R: ScalarRng<G::Scalar>>(rng: &mut R) -> (G::Point, G::Scalar) {
    let nonce = rng.sample();
    let commitment = commit::<G>(&nonce);
    (commitment, nonce)
}
