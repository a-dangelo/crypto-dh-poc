import Aeneas.Std.Primitives
import VCVio.OracleComp.Constructions.SampleableType.Basic

/-!
# Probability semantics for bounded extracted computations

`interpret` reads the actual Aeneas interaction tree. Failure, divergence and exhausted
fuel remain explicit outcomes. A finite program is a witness of bounded execution, not
an alternative implementation: clients must prove its embedding equals the extracted
term. Adequacy then identifies the interpretation of that term with the witness's law.
-/

namespace HashCommitment.Probability

open Aeneas.Std OracleComp OracleSpec ProbComp

/-- Outcomes retain all exceptional mass; no conditioning or renormalisation occurs. -/
inductive Outcome (α : Type) where
  | success : α → Outcome α
  | failure : Error → Outcome α
  | divergence : Outcome α
  | cutoff : Outcome α

/-- Inspect at most `fuel` observable tree nodes. -/
def interpret {α : Type} : Nat → Result α → ProbComp (Outcome α)
  | 0, _ => pure .cutoff
  | fuel + 1, t => match t.match with
    | .ok a => pure (.success a)
    | .div => pure .divergence
    | .vis (.fail e) _ => pure (.failure e)
    | .vis (.uniform n) k => do
        let x ← uniformFin n
        interpret fuel (k x)

/-- Finite, successful trees; the branches are indexed by all possible random answers. -/
inductive Program (α : Type) where
  | pure : α → Program α
  | sample : (n : Nat) → (Fin (n + 1) → Program α) → Program α

namespace Program

variable {α β : Type}

/-- Embed a finite witness into Aeneas's existing interaction-tree monad. -/
def toResult : Program α → Result α
  | .pure a => Result.ok a
  | .sample n k => Result.vis (.uniform n) (fun x => toResult (k x))

/-- Interpret the same finite witness using VCV-io's uniform finite choice. -/
def toProb : Program α → ProbComp α
  | .pure a => Pure.pure a
  | .sample n k => do
      let x ← uniformFin n
      toProb (k x)

/-- One ideal uniform choice. -/
def uniform (n : Nat) : Program (Fin (n + 1)) := .sample n .pure

@[simp] theorem toResult_uniform (n : Nat) :
    (uniform n).toResult = Result.uniform n := rfl

@[simp] theorem toProb_uniform (n : Nat) :
    (uniform n).toProb = uniformFin n := by
  simp [uniform, toProb]

/-- Node bound, including the final return node. -/
def depth : Program α → Nat
  | .pure _ => 1
  | .sample _ k => 1 + Finset.univ.sup (fun x => depth (k x))

/-- Sequential composition of finite witnesses. -/
def bind : Program α → (α → Program β) → Program β
  | .pure a, f => f a
  | .sample n k, f => .sample n (fun x => bind (k x) f)

@[simp] theorem pure_bind (a : α) (f : α → Program β) :
    (Program.pure a).bind f = f a := rfl

@[simp] theorem bind_pure (p : Program α) : p.bind Program.pure = p := by
  induction p with
  | pure a => rfl
  | sample n k ih => simp [bind, ih]

@[simp] theorem bind_assoc {γ : Type} (p : Program α)
    (f : α → Program β) (g : β → Program γ) :
    (p.bind f).bind g = p.bind (fun a => (f a).bind g) := by
  induction p with
  | pure a => rfl
  | sample n k ih => simp [bind, ih]

/-- A compositional upper bound for sequential witnesses. -/
theorem depth_bind_le (p : Program α) (f : α → Program β) (bound : Nat)
    (hf : ∀ a, (f a).depth ≤ bound) :
    (p.bind f).depth ≤ p.depth + bound := by
  induction p with
  | pure a =>
      have h := hf a
      simp only [bind, depth]
      omega
  | sample n k ih =>
      simp only [bind, depth]
      have hs : Finset.univ.sup (fun x => ((k x).bind f).depth) ≤
          Finset.univ.sup (fun x => (k x).depth) + bound := by
        apply Finset.sup_le
        intro x _
        exact (ih x).trans (Nat.add_le_add_right
          (Finset.le_sup (f := fun x => (k x).depth) (Finset.mem_univ x)) bound)
      omega

/-- Return nodes at the sequencing boundary are not counted twice. -/
theorem depth_bind_le_add (p : Program α) (f : α → Program β) (extra : Nat)
    (hf : ∀ a, (f a).depth ≤ extra + 1) :
    (p.bind f).depth ≤ p.depth + extra := by
  induction p with
  | pure a =>
      have h := hf a
      simp only [bind, depth]
      omega
  | sample n k ih =>
      simp only [bind, depth]
      have hs : Finset.univ.sup (fun x => ((k x).bind f).depth) ≤
          Finset.univ.sup (fun x => (k x).depth) + extra := by
        apply Finset.sup_le
        intro x _
        exact (ih x).trans (Nat.add_le_add_right
          (Finset.le_sup (f := fun x => (k x).depth) (Finset.mem_univ x)) extra)
      omega

/-- Apply a deterministic function to a witness's result. -/
def map (p : Program α) (f : α → β) : Program β := p.bind (fun a => .pure (f a))

@[simp] theorem depth_map (p : Program α) (f : α → β) :
    (p.map f).depth = p.depth := by
  induction p with
  | pure a => rfl
  | sample n k ih =>
      change (1 + Finset.univ.sup (fun x => ((k x).map f).depth)) =
        1 + Finset.univ.sup (fun x => (k x).depth)
      simp only [ih]

/-- The finite witness preserves Aeneas sequencing exactly. -/
theorem toResult_bind (p : Program α) (f : α → Program β) :
    (p.bind f).toResult = (p.toResult >>= fun a => (f a).toResult) := by
  induction p with
  | pure a => simp [bind, toResult]
  | sample n k ih => simp [bind, toResult, ih]

/-- Its VCV-io interpretation preserves sequencing exactly. -/
theorem toProb_bind (p : Program α) (f : α → Program β) :
    (p.bind f).toProb = (p.toProb >>= fun a => (f a).toProb) := by
  induction p with
  | pure a => simp [bind, toProb]
  | sample n k ih => simp [bind, toProb, ih, LawfulMonad.bind_assoc]

@[simp] theorem toResult_map (p : Program α) (f : α → β) :
    (p.map f).toResult = (do let a ← p.toResult; Result.ok (f a)) := by
  exact toResult_bind p (fun a => .pure (f a))

@[simp] theorem toProb_map (p : Program α) (f : α → β) :
    (p.map f).toProb = (do let a ← p.toProb; Pure.pure (f a)) := by
  exact toProb_bind p (fun a => .pure (f a))

/-- A sufficient node bound makes the canonical interpretation exact. -/
theorem interpret_toResult (p : Program α) (fuel : Nat) (h : p.depth ≤ fuel) :
    interpret fuel p.toResult = (do let a ← p.toProb; Pure.pure (.success a)) := by
  induction p generalizing fuel with
  | pure a =>
      cases fuel with
      | zero => simp [depth] at h
      | succ fuel => simp [interpret, toResult, toProb]
  | sample n k ih =>
      cases fuel with
      | zero => simp [depth] at h
      | succ fuel =>
          have hk : ∀ x, (k x).depth ≤ fuel := by
            intro x
            have hx := Finset.le_sup (f := fun x => (k x).depth) (Finset.mem_univ x)
            simp only [depth] at h
            omega
          simp [interpret, toResult, toProb, ih _ _ (hk _)]

/-- Increasing an adequate fuel bound does not alter any outcome. -/
theorem interpret_stable (p : Program α) (fuel extra : Nat) (h : p.depth ≤ fuel) :
    interpret (fuel + extra) p.toResult = interpret fuel p.toResult := by
  rw [interpret_toResult p (fuel + extra) (by omega), interpret_toResult p fuel h]

/-- Distinct witnesses for the same extracted tree have the same probability law. -/
theorem interpretation_unique (p q : Program α) (h : p.toResult = q.toResult) :
    (do let a ← p.toProb; Pure.pure (Outcome.success a)) =
      (do let a ← q.toProb; Pure.pure (Outcome.success a)) := by
  rw [← interpret_toResult p (max p.depth q.depth) (Nat.le_max_left _ _), h,
    interpret_toResult q (max p.depth q.depth) (Nat.le_max_right _ _)]

end Program

/-- Transport adequacy only after proving equality with the actual extracted term. -/
theorem interpret_eq_of_representation {α : Type} (t : Result α) (p : Program α)
    (ht : t = p.toResult) (fuel : Nat) (hf : p.depth ≤ fuel) :
    interpret fuel t = (do let a ← p.toProb; pure (.success a)) := by
  rw [ht]
  exact p.interpret_toResult fuel hf

/-- A successful return introduces no random choice. -/
@[simp] theorem interpret_ok {α : Type} (a : α) (fuel : Nat) :
    interpret (fuel + 1) (Result.ok a) = pure (.success a) := by
  simp [interpret]

/-- One extracted uniform event has the corresponding VCV-io uniform law. -/
@[simp] theorem interpret_uniform (n fuel : Nat) :
    interpret (fuel + 2) (Result.uniform n) =
      (do let x ← uniformFin n; pure (Outcome.success x)) := by
  simp [Result.uniform, interpret]

@[simp] theorem interpret_fail {α : Type} (e : Error) (fuel : Nat) :
    interpret (fuel + 1) (Result.fail e : Result α) = pure (.failure e) := by
  simp [interpret]

@[simp] theorem interpret_div {α : Type} (fuel : Nat) :
    interpret (fuel + 1) (Result.div : Result α) = pure .divergence := by
  simp [interpret]

end HashCommitment.Probability
