{-# OPTIONS --safe --without-K --cubical-compatible #-}
-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

-- Read counts with two separate noise bounds, and how verdicts move between
-- nested clades.
--
-- Counts.agda bounds the noise by one number n in both directions.  Counts
-- that come from placing reads on a tree are not symmetric.  For a clade C:
--
--   y    reads whose placement inside C is decided;
--   nlo  at most this many of those y reads are wrongly counted;
--   nhi  at most this many reads that belong to C were not counted (reads
--        whose placement is undecided, plus reads wrongly excluded).
--
-- This module proves, for all natural numbers:
--
--   * the candidate latents are exactly the x with y ≤ x + nlo and
--     x ≤ y + nhi (the interval [y ∸ nlo, y + nhi], stated monus-free);
--   * every case is inhabited;
--   * the closed-form verdict is sound for every constructor it returns:
--     entailed when nlo < y, refuted when y = nhi = 0, unresolved otherwise;
--   * with nlo = nhi = n it is the verdict of Counts.agda;
--   * presence depends only on nlo, absence only on nhi;
--   * zooming out keeps presence: if C is inside C′ then y ≤ y′, and an
--     entailed verdict for C is an entailed verdict for C′ PROVIDED the
--     same nlo bounds C′ (containment alone is not enough);
--   * zooming in keeps absence: a refuted verdict for C′ is a refuted
--     verdict for a clade C inside it PROVIDED y ≤ y′ and nhi ≤ nhi′.
--
-- Not proved here: that any particular placement method meets a stated nlo
-- or nhi, or that the bounds of two nested clades stand in the relation a
-- zoom law needs.  Those are assumptions supplied by measurement.

module MetaManifold.Evidence.TwoSided where

open import Agda.Builtin.Bool using (Bool; true; false)
open import Agda.Builtin.Nat using (_<_)
open import ResidualEvidence.Prelude
open import ResidualEvidence.Core
open import ResidualEvidence.Finite.Row using (Verdict; entailed; refuted; unresolved; inconsistent)
open import MetaManifold.Evidence.Counts
  using ( _⊎_; inj₁; inj₂; ≤-refl; ≤-trans; ≤-total; ≤-+ʳ; +-monoʳ; +-cancelʳ
        ; +-assoc; subst; ≤-diff; <-true; <-false
        ; Direction; over; under; World; world; latent; observed
        ; Present; Absent )
  renaming (verdict to verdict₁)

------------------------------------------------------------------------
-- Evidence with two bounds

-- `over`: the reads exceed the latent, by at most nlo.
-- `under`: the latent exceeds the reads, by at most nhi.
Bounded₂ : Nat → Nat → World → Set
Bounded₂ nlo nhi (world b d over)  = d ≤ nlo
Bounded₂ nlo nhi (world b d under) = d ≤ nhi

Fibre₂ : Nat → Nat → Nat → Set
Fibre₂ y nlo nhi = Candidate observed y (Bounded₂ nlo nhi)

noiseless₂ : ∀ y nlo nhi → Fibre₂ y nlo nhi
noiseless₂ y nlo nhi = world y zero under , refl , z≤n

case₂ : ∀ y nlo nhi → Case observed y (Bounded₂ nlo nhi)
case₂ y nlo nhi = inhabited (noiseless₂ y nlo nhi)

------------------------------------------------------------------------
-- The fibre is the interval: y ≤ x + nlo and x ≤ y + nhi.

InInterval₂ : Nat → Nat → Nat → Nat → Set
InInterval₂ y nlo nhi x = (y ≤ x + nlo) × (x ≤ y + nhi)

fibre₂⇒interval : ∀ {y nlo nhi} (c : Fibre₂ y nlo nhi) →
  InInterval₂ y nlo nhi (latent (fst c))
fibre₂⇒interval {y} {nlo} {nhi} (world b d over , refl , d≤nlo) =
  +-monoʳ b d≤nlo , ≤-trans (≤-+ʳ b d) (≤-+ʳ (b + d) nhi)
fibre₂⇒interval {y} {nlo} {nhi} (world b d under , refl , d≤nhi) =
  subst (λ t → b ≤ t) (sym (+-assoc b d nlo)) (≤-+ʳ b (d + nlo)) , +-monoʳ b d≤nhi

interval⇒fibre₂ : ∀ {y nlo nhi x} → InInterval₂ y nlo nhi x →
  Σ (Fibre₂ y nlo nhi) (λ c → latent (fst c) ≡ x)
interval⇒fibre₂ {y} {nlo} {nhi} {x} (lo , hi) with ≤-total x y
... | inj₁ x≤y with ≤-diff x≤y
...   | d , x+d≡y =
  (world x d over , x+d≡y , +-cancelʳ x (subst (λ t → t ≤ x + nlo) (sym x+d≡y) lo)) , refl
interval⇒fibre₂ {y} {nlo} {nhi} {x} (lo , hi) | inj₂ y≤x with ≤-diff y≤x
...   | d , y+d≡x =
  (world y d under , refl , +-cancelʳ y (subst (λ t → t ≤ y + nhi) (sym y+d≡x) hi)) , y+d≡x

------------------------------------------------------------------------
-- Closed-form verdict

decide : Bool → Nat → Nat → Verdict
decide true  _       _       = entailed
decide false zero    zero    = refuted
decide false zero    (suc _) = unresolved
decide false (suc _) _       = unresolved

verdict₂ : Nat → Nat → Nat → Verdict
verdict₂ y nlo nhi = decide (nlo < y) y nhi

------------------------------------------------------------------------
-- Soundness

private
  no-suc≤ : ∀ k → suc k ≤ k → ⊥
  no-suc≤ zero    ()
  no-suc≤ (suc k) (s≤s p) = no-suc≤ k p

  le0 : ∀ {x} → x ≤ zero → x ≡ zero
  le0 z≤n = refl

  suc≢zero : ∀ {m} → suc m ≡ zero → ⊥
  suc≢zero ()

-- nlo < y: every candidate latent is at least one.
entailed₂-sound : ∀ {y nlo nhi} → suc nlo ≤ y → Holds (case₂ y nlo nhi) Present
entailed₂-sound {y} {nlo} n<y c latent≡0 with fibre₂⇒interval c
... | lo , _ = no-suc≤ nlo (≤-trans n<y (subst (λ t → y ≤ t + nlo) latent≡0 lo))

-- y = nhi = 0: the only candidate latent is 0, whatever nlo is.
refuted₂-sound : ∀ {nlo} → Holds (case₂ zero nlo zero) Absent
refuted₂-sound c with fibre₂⇒interval c
... | _ , hi = le0 hi

-- 1 ≤ y ≤ nlo: latent 0 and latent y are both candidates.
unresolved-pos-sound : ∀ {k nlo nhi} → suc k ≤ nlo →
  (¬ Holds (case₂ (suc k) nlo nhi) Present) × (¬ Holds (case₂ (suc k) nlo nhi) Absent)
unresolved-pos-sound {k} {nlo} {nhi} y≤nlo =
  (λ h → h (world zero (suc k) over , refl , y≤nlo) refl) ,
  (λ h → suc≢zero (h (noiseless₂ (suc k) nlo nhi)))

-- y = 0 with nhi ≥ 1: latent 0 and latent nhi are both candidates.
unresolved-zero-sound : ∀ {nlo m} →
  (¬ Holds (case₂ zero nlo (suc m)) Present) × (¬ Holds (case₂ zero nlo (suc m)) Absent)
unresolved-zero-sound {nlo} {m} =
  (λ h → h (world zero zero over , refl , z≤n) refl) ,
  (λ h → suc≢zero (h (world zero (suc m) under , refl , ≤-refl)))

data Sound₂ (y nlo nhi : Nat) : Verdict → Set where
  is-entailed   : Holds (case₂ y nlo nhi) Present → Sound₂ y nlo nhi entailed
  is-refuted    : Holds (case₂ y nlo nhi) Absent  → Sound₂ y nlo nhi refuted
  is-unresolved : ¬ Holds (case₂ y nlo nhi) Present → ¬ Holds (case₂ y nlo nhi) Absent →
                  Sound₂ y nlo nhi unresolved

private
  sound-by : ∀ y nlo nhi b → (nlo < y) ≡ b → Sound₂ y nlo nhi (decide b y nhi)
  sound-by y       nlo nhi     true  eq = is-entailed (entailed₂-sound (<-true nlo y eq))
  sound-by zero    nlo zero    false eq = is-refuted refuted₂-sound
  sound-by zero    nlo (suc m) false eq =
    let p = unresolved-zero-sound {nlo} {m} in is-unresolved (fst p) (snd p)
  sound-by (suc k) nlo nhi     false eq =
    let p = unresolved-pos-sound {k} {nlo} {nhi} (<-false nlo (suc k) eq)
    in is-unresolved (fst p) (snd p)

verdict₂-sound : ∀ y nlo nhi → Sound₂ y nlo nhi (verdict₂ y nlo nhi)
verdict₂-sound y nlo nhi = sound-by y nlo nhi (nlo < y) refl

never-inconsistent₂ : ∀ y nlo nhi → ¬ (verdict₂ y nlo nhi ≡ inconsistent)
never-inconsistent₂ y nlo nhi = go (nlo < y) y nhi
  where
  go : ∀ b y nhi → ¬ (decide b y nhi ≡ inconsistent)
  go true  _       _       ()
  go false zero    zero    ()
  go false zero    (suc _) ()
  go false (suc _) _       ()

------------------------------------------------------------------------
-- The symmetric case is Counts.agda

symmetric-agrees : ∀ y n → verdict₂ y n n ≡ verdict₁ y n
symmetric-agrees y n with n < y
... | true  = refl
... | false with y
...   | zero  with n
...     | zero  = refl
...     | suc _ = refl
symmetric-agrees y n | false | suc _ = refl

------------------------------------------------------------------------
-- Which bound each verdict depends on

private
  ≤⇒<-true : ∀ a b → suc a ≤ b → (a < b) ≡ true
  ≤⇒<-true zero    (suc b) _       = refl
  ≤⇒<-true (suc a) (suc b) (s≤s p) = ≤⇒<-true a b p

  <-zero : ∀ n → (n < zero) ≡ false
  <-zero zero    = refl
  <-zero (suc n) = refl

  entailed-b : ∀ b y nhi → decide b y nhi ≡ entailed → b ≡ true
  entailed-b true  _       _       _  = refl
  entailed-b false zero    zero    ()
  entailed-b false zero    (suc _) ()
  entailed-b false (suc _) _       ()

  refuted-b : ∀ b y nhi → decide b y nhi ≡ refuted → (y ≡ zero) × (nhi ≡ zero)
  refuted-b true  _       _       ()
  refuted-b false zero    zero    _  = refl , refl
  refuted-b false zero    (suc _) ()
  refuted-b false (suc _) _       ()

-- entailed ⇔ nlo < y.  nhi plays no part.
entailed⇒lt : ∀ y nlo nhi → verdict₂ y nlo nhi ≡ entailed → suc nlo ≤ y
entailed⇒lt y nlo nhi eq = <-true nlo y (entailed-b (nlo < y) y nhi eq)

lt⇒entailed : ∀ y nlo nhi → suc nlo ≤ y → verdict₂ y nlo nhi ≡ entailed
lt⇒entailed y nlo nhi p = cong (λ b → decide b y nhi) (≤⇒<-true nlo y p)

-- refuted ⇔ y = nhi = 0.  nlo plays no part.
refuted⇒zero : ∀ y nlo nhi → verdict₂ y nlo nhi ≡ refuted → (y ≡ zero) × (nhi ≡ zero)
refuted⇒zero y nlo nhi eq = refuted-b (nlo < y) y nhi eq

zero⇒refuted : ∀ nlo → verdict₂ zero nlo zero ≡ refuted
zero⇒refuted nlo = cong (λ b → decide b zero zero) (<-zero nlo)

------------------------------------------------------------------------
-- Nested clades.  If clade C lies inside clade C′, every read counted for C
-- is counted for C′, so y ≤ y′.

-- Zooming out keeps presence, whatever happens to the upper bound.
entailed-up : ∀ {y y′ nlo} nhi nhi′ → y ≤ y′ →
  verdict₂ y nlo nhi ≡ entailed → verdict₂ y′ nlo nhi′ ≡ entailed
entailed-up {y} {y′} {nlo} nhi nhi′ y≤y′ e =
  lt⇒entailed y′ nlo nhi′ (≤-trans (entailed⇒lt y nlo nhi e) y≤y′)

-- Zooming in keeps absence, whatever the lower bounds are.
refuted-down : ∀ {y y′ nhi nhi′} nlo nlo′ → y ≤ y′ → nhi ≤ nhi′ →
  verdict₂ y′ nlo′ nhi′ ≡ refuted → verdict₂ y nlo nhi ≡ refuted
refuted-down {y} {y′} {nhi} {nhi′} nlo nlo′ y≤y′ nhi≤nhi′ r
  with refuted⇒zero y′ nlo′ nhi′ r
... | y′≡0 , nhi′≡0 =
  at-zero y nhi (le0 (subst (λ t → y ≤ t) y′≡0 y≤y′)) (le0 (subst (λ t → nhi ≤ t) nhi′≡0 nhi≤nhi′))
  where
  at-zero : ∀ y nhi → y ≡ zero → nhi ≡ zero → verdict₂ y nlo nhi ≡ refuted
  at-zero .zero .zero refl refl = zero⇒refuted nlo
