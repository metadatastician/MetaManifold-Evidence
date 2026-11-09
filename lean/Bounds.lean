-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

import Counts

/-!
Lean re-proof of `MetaManifold.Evidence.Bounds` (agda/src/MetaManifold/Evidence/Bounds.agda).

The interval ends lo y n = y ∸ n and hi y n = y + n, the proof that the
fibre is exactly the latents in [lo, hi], the complete characterisation of
the verdict (`VerdictView`), and how the verdict moves with the bound.
-/

namespace MetaManifoldEvidence.Bounds

open MetaManifoldEvidence.ResidualEvidence
open MetaManifoldEvidence.Counts
open Le

------------------------------------------------------------------------
-- The interval ends

/-- `lo y n = y - n`: Agda's builtin truncated `_-_` is `Nat.sub`. -/
def lo (y n : Nat) : Nat := y - n

def hi (y n : Nat) : Nat := y + n

/-- Reads y are within n of x exactly when x is at least y ∸ n. -/
theorem «≤⇒lo» : ∀ y n x : Nat, y ≤ₐ x + n → lo y n ≤ₐ x
  | 0, 0, _, _ => «z≤n»
  | 0, n + 1, x, _ => subst (fun t => t ≤ₐ x) («zero-∸» (n + 1)).symm «z≤n»
  | _ + 1, 0, _, p => p
  | y + 1, n + 1, x, p =>
    subst (fun t => t ≤ₐ x) («suc-∸-suc» y n).symm («≤⇒lo» y n x (peel p))

theorem «lo⇒≤» : ∀ y n x : Nat, lo y n ≤ₐ x → y ≤ₐ x + n
  | 0, _, _, _ => «z≤n»
  | _ + 1, 0, _, p => p
  | y + 1, n + 1, x, p =>
    «s≤s» («lo⇒≤» y n x (subst (fun t => t ≤ₐ x) («suc-∸-suc» y n) p))

/-- The fibre over y is exactly the latents in [lo y n, hi y n]. -/
def InBounds (y n x : Nat) : Prop := (lo y n ≤ₐ x) ∧ (x ≤ₐ hi y n)

theorem «fibre⇒bounds» {y n : Nat} (c : ReadFibre y n) : InBounds y n (latent c.1) :=
  ⟨«≤⇒lo» y n (latent c.1) («fibre⇒interval» c).1, («fibre⇒interval» c).2⟩

def «bounds⇒fibre» {y n x : Nat} (b : InBounds y n x) :
    {c : ReadFibre y n // latent c.1 = x} :=
  «interval⇒fibre» ⟨«lo⇒≤» y n x b.1, b.2⟩

------------------------------------------------------------------------
-- A complete characterisation of the verdict

inductive VerdictView (y n : Nat) : Verdict → Prop where
  | «v-entailed» : n + 1 ≤ₐ y → VerdictView y n .entailed
  | «v-refuted» : y = 0 → n = 0 → VerdictView y n .refuted
  | «v-unresolved» : y ≤ₐ n → 1 ≤ₐ n → VerdictView y n .unresolved

open VerdictView

theorem view (y n : Nat) : VerdictView y n (verdict y n) := by
  unfold verdict
  cases eq : Nat.blt n y with
  | true => exact «v-entailed» («<-true» n y eq)
  | false =>
    cases y with
    | zero =>
      cases n with
      | zero => exact «v-refuted» rfl rfl
      | succ m => exact «v-unresolved» «z≤n» («s≤s» «z≤n»)
    | succ k =>
      exact
        let yn : k + 1 ≤ₐ n := «<-false» n (k + 1) eq
        «v-unresolved» yn («≤-trans» («s≤s» «z≤n») yn)

/-- The view at a verdict the function returned. -/
theorem «view-at» {y n : Nat} {v : Verdict} (h : verdict y n = v) : VerdictView y n v :=
  h ▸ view y n

------------------------------------------------------------------------
-- Moving the bound

/-- Lowering the noise bound keeps an entailment. -/
theorem «entailed-anti» {y n n' : Nat} : n' ≤ₐ n → verdict y n = .entailed →
    verdict y n' = .entailed := by
  intro nn h
  cases «view-at» h with
  | «v-entailed» ny =>
    have w := view y n'
    generalize verdict y n' = v at w ⊢
    cases w with
    | «v-entailed» _ => rfl
    | «v-refuted» y0 _ =>
      exact («suc≰zero» (subst (fun t => n + 1 ≤ₐ t) y0 ny)).elim
    | «v-unresolved» yn' _ =>
      exact («irrefl» n («≤-trans» ny («≤-trans» yn' nn))).elim

/-- Raising the noise bound keeps an unresolved verdict unresolved. -/
theorem «unresolved-mono» {y n n' : Nat} : n ≤ₐ n' → verdict y n = .unresolved →
    verdict y n' = .unresolved := by
  intro nn h
  cases «view-at» h with
  | «v-unresolved» yn one =>
    have w := view y n'
    generalize verdict y n' = v at w ⊢
    cases w with
    | «v-unresolved» _ _ => rfl
    | «v-entailed» n'y =>
      exact («irrefl» n' («≤-trans» n'y («≤-trans» yn nn))).elim
    | «v-refuted» _ n'0 =>
      exact («suc≰zero» (subst (fun t => 1 ≤ₐ t) n'0 («≤-trans» one nn))).elim

/-- Refuted happens only at zero reads under zero noise. -/
theorem «refuted-only-at-zero» {y n : Nat} : verdict y n = .refuted → (y = 0) ∧ (n = 0) := by
  intro h
  cases «view-at» h with
  | «v-refuted» y0 n0 => exact ⟨y0, n0⟩

/-- Any positive bound turns a refutation into unresolved. -/
theorem «refuted-fragile» {y n n' : Nat} : verdict y n = .refuted → 1 ≤ₐ n' →
    verdict y n' = .unresolved := by
  intro h one
  have y0 := («refuted-only-at-zero» (y := y) (n := n) h).1
  subst y0
  have w := view 0 n'
  generalize verdict 0 n' = v at w ⊢
  cases w with
  | «v-unresolved» _ _ => rfl
  | «v-entailed» p => exact («suc≰zero» p).elim
  | «v-refuted» _ n'0 => exact («suc≰zero» (subst (fun t => 1 ≤ₐ t) n'0 one)).elim

/-- More noise never strengthens a verdict. -/
theorem «never-strengthens» {y n n' : Nat} : n ≤ₐ n' →
    (verdict y n' = .entailed → verdict y n = .entailed) ∧
    (verdict y n' = .refuted → n' = 0) :=
  fun nn => ⟨«entailed-anti» (y := y) (n := n') (n' := n) nn,
             fun h => («refuted-only-at-zero» (y := y) (n := n') h).2⟩

end MetaManifoldEvidence.Bounds
