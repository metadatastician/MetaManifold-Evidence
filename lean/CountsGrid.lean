-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

import Bounds

/-!
Lean port of `MetaManifold.Evidence.CountsGrid`
(agda/src/MetaManifold/Evidence/CountsGrid.agda): the grid the Julia
certificate is checked on, one row per read count and noise bound in 0..k,
holding the proved closed forms `verdict`, `lo`, `hi`.
-/

namespace MetaManifoldEvidence.CountsGrid

open MetaManifoldEvidence.ResidualEvidence (Verdict)
open MetaManifoldEvidence.Counts (verdict)
open MetaManifoldEvidence.Bounds (lo hi)

/-- reads, noise bound, verdict, lower end, upper end -/
inductive Row : Type where
  | row : Nat → Nat → Verdict → Nat → Nat → Row

/-- The row the closed forms give for `y` reads under bound `n`. -/
def cell (y n : Nat) : Row := Row.row y n (verdict y n) (lo y n) (hi y n)

/-- `0 ∷ 1 ∷ … ∷ k ∷ []`. -/
def upto (k : Nat) : List Nat := go k []
where
  go : Nat → List Nat → List Nat
    | 0, acc => 0 :: acc
    | i + 1, acc => go i ((i + 1) :: acc)

/-- Agda's local `along`, with the outer call `cells ys ns` it ends in passed
as `rest`, so that both recursions are structural. -/
def along (y : Nat) : List Nat → List Row → List Row
  | [], rest => rest
  | n :: ms, rest => cell y n :: along y ms rest

/-- Every pair, first component outermost, in the order Julia emits them. -/
def cells : List Nat → List Nat → List Row
  | [], _ => []
  | y :: ys, ns => along y ns (cells ys ns)

def grid (k : Nat) : List Row := cells (upto k) (upto k)

end MetaManifoldEvidence.CountsGrid
