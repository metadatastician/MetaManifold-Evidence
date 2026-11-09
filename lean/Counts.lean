-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

import ResidualEvidence

/-!
Lean re-proof of `MetaManifold.Evidence.Counts` (agda/src/MetaManifold/Evidence/Counts.agda).

Read counts as residual evidence: a world pairs a latent abundance with an
observed read count that differs from it by noise d in either direction, and
evidence bounds the noise by n. Statements follow the Agda ones clause for
clause; lean/CORRESPONDENCE.adoc records every deliberate difference.
-/

namespace MetaManifoldEvidence.Counts

open MetaManifoldEvidence.ResidualEvidence
open Le

universe u v

------------------------------------------------------------------------
-- Arithmetic on naturals (core Lean only)

/-- `_⊎_`, in a sort that can carry data (Agda: `Set (a ⊔ b)`). -/
inductive Uplus (A : Sort u) (B : Sort v) : Sort (max 1 u v) where
  | inj₁ : A → Uplus A B
  | inj₂ : B → Uplus A B

infixr:30 " ⊎ " => Uplus

theorem «≤-refl» : ∀ {n : Nat}, n ≤ₐ n
  | 0 => «z≤n»
  | _ + 1 => «s≤s» «≤-refl»

-- Pattern matching on a `≤ₐ` proof whose indices are not variables makes
-- Lean's match compiler use `Nat.succ.injEq`, which rests on `propext`.
-- The lemmas below therefore split on the naturals and use these two
-- inversions, each an eliminator application with variable indices.

/-- Inversion of `s≤s` (Agda: the `peel` of Bounds, by pattern matching). -/
theorem «≤-pred» : ∀ {a b : Nat}, a ≤ₐ b → Nat.pred a ≤ₐ Nat.pred b
  | _, _, «z≤n» => «z≤n»
  | _, _, «s≤s» p => p

theorem peel {a b : Nat} (p : a + 1 ≤ₐ b + 1) : a ≤ₐ b := «≤-pred» p

/-- No successor is below zero (Agda: an absurd pattern). -/
theorem «≤-zero» : ∀ {a b : Nat}, a ≤ₐ b → b = 0 → a = 0
  | _, _, «z≤n», _ => rfl
  | _, _, «s≤s» _, h => Nat.noConfusion h

theorem «suc≰zero» {a : Nat} (p : a + 1 ≤ₐ 0) : False :=
  Nat.noConfusion («≤-zero» p rfl)

theorem «≤-trans» : ∀ {a b c : Nat}, a ≤ₐ b → b ≤ₐ c → a ≤ₐ c
  | 0, _, _, _, _ => «z≤n»
  | _ + 1, 0, _, p, _ => («suc≰zero» p).elim
  | _ + 1, _ + 1, 0, _, q => («suc≰zero» q).elim
  | _ + 1, _ + 1, _ + 1, p, q => «s≤s» («≤-trans» (peel p) (peel q))

/-- `≤-total`, by recursion on the two naturals (the result carries data). -/
def «≤-total» : ∀ a b : Nat, (a ≤ₐ b) ⊎ (b ≤ₐ a)
  | 0, _ => .inj₁ «z≤n»
  | _ + 1, 0 => .inj₂ «z≤n»
  | a + 1, b + 1 =>
    match «≤-total» a b with
    | .inj₁ p => .inj₁ («s≤s» p)
    | .inj₂ p => .inj₂ («s≤s» p)

-- Lean's `Nat.add` recurses on its second argument, Agda's builtin `_+_` on
-- its first. These two equations, definitional in Agda, are lemmas here.
theorem «zero-+» : ∀ a : Nat, 0 + a = a
  | 0 => rfl
  | a + 1 => congrArg Nat.succ («zero-+» a)

theorem «suc-+» (a : Nat) : ∀ b : Nat, (a + 1) + b = (a + b) + 1
  | 0 => rfl
  | b + 1 => congrArg Nat.succ («suc-+» a b)

theorem «≤-step» : ∀ {a b : Nat}, a ≤ₐ b → a ≤ₐ b + 1
  | _, _, «z≤n» => «z≤n»
  | _, _, «s≤s» p => «s≤s» («≤-step» p)

theorem «≤-+ʳ» (m : Nat) : ∀ k : Nat, m ≤ₐ m + k
  | 0 => «≤-refl»
  | k + 1 => «≤-step» («≤-+ʳ» m k)

theorem «+-monoʳ» (m : Nat) : ∀ {a b : Nat}, a ≤ₐ b → m + a ≤ₐ m + b
  | _, b, «z≤n» => «≤-+ʳ» m b
  | _, _, «s≤s» p => «s≤s» («+-monoʳ» m p)

theorem «+-cancelʳ» : ∀ (m : Nat) {a b : Nat}, m + a ≤ₐ m + b → a ≤ₐ b
  | 0, a, b, p => «zero-+» a ▸ «zero-+» b ▸ p
  | m + 1, a, b, p =>
    «+-cancelʳ» m (peel («suc-+» m a ▸ «suc-+» m b ▸ p))

theorem «+-assoc» (a b : Nat) : ∀ c : Nat, (a + b) + c = a + (b + c)
  | 0 => rfl
  | c + 1 => congrArg Nat.succ («+-assoc» a b c)

/-- Definitional in Lean (`Nat.add` recurses on its second argument). -/
theorem «+-zero» (a : Nat) : a + 0 = a := rfl

/-- Definitional in Lean (`Nat.add` recurses on its second argument). -/
theorem «+-suc» (a b : Nat) : a + (b + 1) = (a + b) + 1 := rfl

theorem «+-comm» : ∀ a b : Nat, a + b = b + a
  | a, 0 => («zero-+» a).symm
  | a, b + 1 => (congrArg Nat.succ («+-comm» a b)).trans («suc-+» b a).symm

/-- Agda's `subst`; Lean's `Eq.subst` is the same eliminator. -/
theorem subst {A : Sort u} (P : A → Prop) {x y : A} (h : x = y) (px : P x) : P y :=
  h ▸ px

theorem «suc-∸-suc» (n : Nat) : ∀ m : Nat, (n + 1) - (m + 1) = n - m
  | 0 => rfl
  | m + 1 => congrArg Nat.pred («suc-∸-suc» n m)

theorem «zero-∸» : ∀ m : Nat, 0 - m = 0
  | 0 => rfl
  | m + 1 => congrArg Nat.pred («zero-∸» m)

theorem «+-∸» : ∀ {m n : Nat}, m ≤ₐ n → m + (n - m) = n
  | 0, n, _ => «zero-+» n
  | _ + 1, 0, p => («suc≰zero» p).elim
  | m + 1, n + 1, p =>
    («suc-+» m ((n + 1) - (m + 1))).trans
      (congrArg Nat.succ ((congrArg (m + ·) («suc-∸-suc» n m)).trans («+-∸» (peel p))))

/-- `≤-diff`: m ≤ n gives the difference as a witness. -/
def «≤-diff» {m n : Nat} (p : m ≤ₐ n) : {k : Nat // m + k = n} :=
  ⟨n - m, «+-∸» p⟩

/-- `<-true`, with Agda's builtin `_<_` as `Nat.blt`. -/
theorem «<-true» : ∀ a b : Nat, Nat.blt a b = true → a + 1 ≤ₐ b
  | 0, _ + 1, _ => «s≤s» «z≤n»
  | a + 1, b + 1, eq => «s≤s» («<-true» a b eq)
  | _, 0, eq => Bool.noConfusion eq

/-- Nat.blt 0 (suc b) computes to true (Agda: a clause of `_<_`). -/
theorem «zero-<-suc» : ∀ b : Nat, Nat.blt 0 (b + 1) = true
  | 0 => rfl
  | _ + 1 => rfl

/-- `<-false`, with Agda's builtin `_<_` as `Nat.blt`. -/
theorem «<-false» : ∀ a b : Nat, Nat.blt a b = false → b ≤ₐ a
  | _, 0, _ => «z≤n»
  | 0, b + 1, eq => Bool.noConfusion ((«zero-<-suc» b).symm.trans eq)
  | a + 1, b + 1, eq => «s≤s» («<-false» a b eq)

------------------------------------------------------------------------
-- Worlds, observation, evidence

inductive Direction : Type where
  | over | under

open Direction

structure World : Type where
  world ::
  base : Nat
  noise : Nat
  dir : Direction

open World

def latent : World → Nat
  | world b _ over => b
  | world b d under => b + d

def observed : World → Nat
  | world b d over => b + d
  | world b _ under => b

/-- Evidence: the noise is within the bound n (in reads). -/
def Bounded (n : Nat) (w : World) : Prop := noise w ≤ₐ n

/-- The fibre over observation y under noise bound n. -/
def ReadFibre (y n : Nat) : Type := Candidate observed y (Bounded n)

def Present (w : World) : Prop := ¬ (latent w = 0)
def Absent (w : World) : Prop := latent w = 0

------------------------------------------------------------------------
-- Every case is inhabited: the noiseless world.

def noiseless (y n : Nat) : ReadFibre y n :=
  ⟨world y 0 under, rfl, «z≤n»⟩

def «case» (y n : Nat) : Case observed y (Bounded n) :=
  Case.inhabited (noiseless y n)

------------------------------------------------------------------------
-- The fibre is the interval: y ≤ x + n and x ≤ y + n.

def InInterval (y n x : Nat) : Prop := (y ≤ₐ x + n) ∧ (x ≤ₐ y + n)

theorem «fibre⇒interval» {y n : Nat} (c : ReadFibre y n) : InInterval y n (latent c.1) :=
  by
    obtain ⟨⟨b, d, dir⟩, h, dn⟩ := c
    cases dir with
    | over =>
      -- y = b + d, latent = b
      subst h
      exact ⟨«+-monoʳ» b dn, «≤-trans» («≤-+ʳ» b d) («≤-+ʳ» (b + d) n)⟩
    | under =>
      -- y = b, latent = b + d
      subst h
      exact ⟨subst (fun t => b ≤ₐ t) («+-assoc» b d n).symm («≤-+ʳ» b (d + n)), «+-monoʳ» b dn⟩

def «interval⇒fibre» {y n x : Nat} (i : InInterval y n x) :
    {c : ReadFibre y n // latent c.1 = x} :=
  match «≤-total» x y with
  | .inj₁ xy =>
    match «≤-diff» xy with
    | ⟨d, xdy⟩ =>
      -- reads over latent by d; d ≤ n because x + d = y ≤ x + n
      ⟨⟨world x d over, xdy, «+-cancelʳ» x (subst (fun t => t ≤ₐ x + n) xdy.symm i.1)⟩, rfl⟩
  | .inj₂ yx =>
    match «≤-diff» yx with
    | ⟨d, ydx⟩ =>
      ⟨⟨world y d under, rfl, «+-cancelʳ» y (subst (fun t => t ≤ₐ y + n) ydx.symm i.2)⟩, ydx⟩

------------------------------------------------------------------------
-- Closed-form presence verdict and its soundness

/-- `verdict`, with Agda's builtin `_<_` as `Nat.blt`. -/
def verdict (y n : Nat) : Verdict :=
  match Nat.blt n y with
  | true => .entailed
  | false =>
    match y with
    | 0 =>
      match n with
      | 0 => .refuted
      | _ + 1 => .unresolved
    | _ + 1 => .unresolved

theorem «irrefl» : ∀ k : Nat, ¬ (k + 1 ≤ₐ k)
  | 0, p => «suc≰zero» p
  | k + 1, p => «irrefl» k (peel p)

/-- n < y: every candidate latent is at least y − n ≥ 1. -/
theorem «entailed-sound» {y n : Nat} : n + 1 ≤ₐ y → Holds («case» y n) Present :=
  fun ny c latent0 =>
    «irrefl» n
      («≤-trans» ny (subst (fun t => y ≤ₐ t) («zero-+» n)
        (subst (fun t => y ≤ₐ t + n) latent0 («fibre⇒interval» c).1)))

theorem «≤0» : ∀ {x : Nat}, x ≤ₐ 0 → x = 0
  | _, «z≤n» => rfl

/-- y = n = 0: the only candidate latent is 0. -/
theorem «refuted-sound» : Holds («case» 0 0) Absent :=
  fun c => «≤0» («fibre⇒interval» c).2

/-- y ≤ n with y + n > 0: latent 0 and latent y + n are both candidates. -/
theorem «unresolved-sound» {y n : Nat} : y ≤ₐ n → ¬ (y + n = 0) →
    (¬ Holds («case» y n) Present) ∧ (¬ Holds («case» y n) Absent) :=
  fun yn nonzero =>
    let zeroCandidate : ReadFibre y n := ⟨world 0 y over, «zero-+» y, yn⟩
    let topCandidate : ReadFibre y n := ⟨world y n under, rfl, «≤-refl»⟩
    ⟨fun h => h zeroCandidate rfl, fun h => nonzero (h topCandidate)⟩

/-- The verdict function is sound for every constructor it can return. -/
inductive Sound (y n : Nat) : Verdict → Prop where
  | «is-entailed» : Holds («case» y n) Present → Sound y n .entailed
  | «is-refuted» : Holds («case» y n) Absent → Sound y n .refuted
  | «is-unresolved» : ¬ Holds («case» y n) Present → ¬ Holds («case» y n) Absent →
      Sound y n .unresolved

theorem «verdict-sound» (y n : Nat) : Sound y n (verdict y n) := by
  unfold verdict
  cases eq : Nat.blt n y with
  | true => exact .«is-entailed» («entailed-sound» («<-true» n y eq))
  | false =>
    cases y with
    | zero =>
      cases n with
      | zero => exact .«is-refuted» «refuted-sound»
      | succ m =>
        exact
          let p := «unresolved-sound» (y := 0) (n := m + 1) «z≤n» (fun h => Nat.noConfusion h)
          .«is-unresolved» p.1 p.2
    | succ k =>
      exact
        let p := «unresolved-sound» (y := k + 1) (n := n) («<-false» n (k + 1) eq)
          (fun h => Nat.noConfusion (((«suc-+» k n).symm.trans h)))
        .«is-unresolved» p.1 p.2

/-- Counts never produce `inconsistent`. -/
theorem «never-inconsistent» (y n : Nat) : ¬ (verdict y n = .inconsistent) := by
  have s := «verdict-sound» y n
  generalize verdict y n = v at s ⊢
  cases s <;> exact fun h => Verdict.noConfusion h

end MetaManifoldEvidence.Counts
