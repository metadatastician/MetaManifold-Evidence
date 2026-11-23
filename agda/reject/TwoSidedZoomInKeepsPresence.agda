{-# OPTIONS --safe --without-K --cubical-compatible #-}
-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
module TwoSidedZoomInKeepsPresence where
open import ResidualEvidence.Prelude
open import ResidualEvidence.Finite.Row using (entailed)
open import MetaManifold.Evidence.TwoSided

-- Must fail: presence does not survive zooming IN.  A clade with 5 counted
-- reads and nlo = 1 is entailed; a clade inside it with 1 counted read is not.
-- entailed-up runs from the inner clade to the outer one, never the reverse.
invalid : verdict₂ 5 1 0 ≡ entailed → verdict₂ 1 1 0 ≡ entailed
invalid = entailed-up {1} {5} {1} 0 0 (s≤s z≤n)
