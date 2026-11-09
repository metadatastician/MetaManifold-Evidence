-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

import Bounds

/-!
Lean re-proof of `MetaManifold.Evidence.CheckerBridge`
(agda/src/MetaManifold/Evidence/CheckerBridge.agda).

The counts model against the ported finite checker of residual-evidence-types
(model 'signed-integer-v1'). They meet on residual y ∈ 0..6 and noise bound
n ∈ 0..6 under the exact view with no assumption on the latent. On that whole
shared domain, the checker's presence verdict is `verdict y n`
(`presence-agrees`), and the natural latents among the checker's candidates
are the counts interval [lo, hi] cut off at 6 (`latents-agree`). Each of the
49 cells is decided by kernel reduction (`rfl`); the premises y ≤ 6 and
n ≤ 6 are kept as hypotheses of the inductive order, as in Agda.
-/

namespace MetaManifoldEvidence.CheckerBridge

open MetaManifoldEvidence.ResidualEvidence
open MetaManifoldEvidence.ResidualEvidence.Checker
open MetaManifoldEvidence.Counts (verdict)
open MetaManifoldEvidence.Bounds (lo hi)
open Le

/-- The checker configuration for y observed reads under noise bound n. -/
def asConfig (y n : Nat) : Config :=
  Config.config (Int.pos y) n View.exact false

/-- The non-negative entries of a list of integers, as naturals, in order. -/
def naturals : List ResidualEvidence.Int → List Nat
  | [] => []
  | .pos k :: xs => k :: naturals xs
  | .negsuc _ :: xs => naturals xs

/-- `from` of `span`. -/
def spanFrom : Nat → Nat → List Nat
  | _, 0 => []
  | x, k + 1 => x :: spanFrom (x + 1) k

/-- lo, lo + 1, …, hi; empty when hi < lo. -/
def span (a b : Nat) : List Nat := spanFrom a ((b + 1) - a)

/-- The smaller of two naturals (Agda `min`, by `_<_` = `Nat.blt`). -/
def min (a b : Nat) : Nat :=
  match Nat.blt a b with
  | true => a
  | false => b

/-- The checker's natural latents for a counts cell. -/
def checkerLatents (y n : Nat) : List Nat :=
  naturals (latents (enumerate (asConfig y n)))

/-- A property of every k ≤ 6 follows from its seven instances. -/
theorem upto6 (P : Nat → Prop) (p0 : P 0) (p1 : P 1) (p2 : P 2) (p3 : P 3) (p4 : P 4)
    (p5 : P 5) (p6 : P 6) : ∀ {k : Nat}, k ≤ₐ 6 → P k
  | 0, _ => p0
  | 1, _ => p1
  | 2, _ => p2
  | 3, _ => p3
  | 4, _ => p4
  | 5, _ => p5
  | 6, _ => p6
  | _ + 7, h => (Counts.«suc≰zero» (Counts.peel (Counts.peel (Counts.peel
    (Counts.peel (Counts.peel (Counts.peel h))))))).elim

/-- The checker's presence verdict is the counts verdict on the shared domain. -/
def PresenceAgrees (y n : Nat) : Prop := presence (asConfig y n) = verdict y n

theorem «presence-agrees» {y n : Nat} : y ≤ₐ 6 → n ≤ₐ 6 → PresenceAgrees y n :=
  fun py => upto6 (fun y => ∀ {n : Nat}, n ≤ₐ 6 → PresenceAgrees y n)
    (upto6 (PresenceAgrees 0) rfl rfl rfl rfl rfl rfl rfl)
    (upto6 (PresenceAgrees 1) rfl rfl rfl rfl rfl rfl rfl)
    (upto6 (PresenceAgrees 2) rfl rfl rfl rfl rfl rfl rfl)
    (upto6 (PresenceAgrees 3) rfl rfl rfl rfl rfl rfl rfl)
    (upto6 (PresenceAgrees 4) rfl rfl rfl rfl rfl rfl rfl)
    (upto6 (PresenceAgrees 5) rfl rfl rfl rfl rfl rfl rfl)
    (upto6 (PresenceAgrees 6) rfl rfl rfl rfl rfl rfl rfl)
    py

/-- The checker's natural latents are the counts interval, cut off at 6. -/
def LatentsAgree (y n : Nat) : Prop := checkerLatents y n = span (lo y n) (min (hi y n) 6)

theorem «latents-agree» {y n : Nat} : y ≤ₐ 6 → n ≤ₐ 6 → LatentsAgree y n :=
  fun py => upto6 (fun y => ∀ {n : Nat}, n ≤ₐ 6 → LatentsAgree y n)
    (upto6 (LatentsAgree 0) rfl rfl rfl rfl rfl rfl rfl)
    (upto6 (LatentsAgree 1) rfl rfl rfl rfl rfl rfl rfl)
    (upto6 (LatentsAgree 2) rfl rfl rfl rfl rfl rfl rfl)
    (upto6 (LatentsAgree 3) rfl rfl rfl rfl rfl rfl rfl)
    (upto6 (LatentsAgree 4) rfl rfl rfl rfl rfl rfl rfl)
    (upto6 (LatentsAgree 5) rfl rfl rfl rfl rfl rfl rfl)
    (upto6 (LatentsAgree 6) rfl rfl rfl rfl rfl rfl rfl)
    py

end MetaManifoldEvidence.CheckerBridge
