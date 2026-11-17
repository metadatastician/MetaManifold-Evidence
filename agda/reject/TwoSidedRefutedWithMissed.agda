{-# OPTIONS --safe --without-K --cubical-compatible #-}
-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
module TwoSidedRefutedWithMissed where
open import ResidualEvidence.Prelude
open import ResidualEvidence.Finite.Row using (refuted)
open import MetaManifold.Evidence.TwoSided

-- Must fail: no read is counted, but one read may have been missed (nhi = 1),
-- so absence is not established.  The verdict is unresolved, not refuted.
invalid : verdict₂ 0 0 1 ≡ refuted
invalid = refl
