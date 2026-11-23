{-# OPTIONS --safe --without-K --cubical-compatible #-}
-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
module TwoSidedEntailedAtBound where
open import ResidualEvidence.Prelude
open import ResidualEvidence.Core
open import MetaManifold.Evidence.Counts using (Present)
open import MetaManifold.Evidence.TwoSided

-- Must fail: with y = nlo = 2 all of the counted reads may be wrong, so a zero
-- latent is admissible and presence is not entailed, however small nhi is.
invalid : Holds (case₂ 2 2 0) Present
invalid = entailed₂-sound (s≤s (s≤s z≤n))
