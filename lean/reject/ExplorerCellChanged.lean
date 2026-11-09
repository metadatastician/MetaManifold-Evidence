-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

import Correspondence

open MetaManifoldEvidence.ResidualEvidence
open MetaManifoldEvidence.ResidualEvidence.Checker (table)
open MetaManifoldEvidence.ExplorerTable (expected)

/-- The list with the `count` cell of row k (from 0) increased by one. -/
def bumpCount : Nat → List Row → List Row
  | _, [] => []
  | 0, r :: rs => { r with count := r.count + 1 } :: rs
  | k + 1, r :: rs => r :: bumpCount k rs

-- Must fail: the explorer correspondence's rfl is not vacuous. The checker's
-- table differs from the explorer's in one cell, the candidate count of row
-- 273 (residual 0, bound 3, sign view, assumeZero true: 1 candidate, made 2).
set_option maxRecDepth 2000 in
set_option maxHeartbeats 1000000 in
theorem invalid : table = bumpCount 273 expected := rfl
