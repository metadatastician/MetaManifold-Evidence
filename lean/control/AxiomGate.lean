-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

-- Gate self-test, not part of the proofs. A theorem that rests on `propext`
-- (by `rw` with an `Iff`, as `simp` and `omega` would) and one that rests on
-- nothing. scripts/check-lean.sh runs its axiom audit on this file's output
-- and demands that the audit flags the first and passes the second; a gate
-- that cannot see `propext` would pass anything.

theorem «uses-propext» (p q : Prop) (h : p ↔ q) (hp : p) : q := by
  rw [← h]
  exact hp

theorem «uses-nothing» (p : Prop) (hp : p) : p := hp

#print axioms «uses-propext»
#print axioms «uses-nothing»
