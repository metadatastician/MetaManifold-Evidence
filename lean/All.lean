-- SPDX-License-Identifier: AGPL-3.0-or-later
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

import ResidualEvidence
import Counts
import Bounds
import CheckerBridge
import CountsGrid
import CountsJuliaTable
import CountsCertificate
import ExplorerTable
import Correspondence

/-!
The Lean recheck leg of the counts theorems and of the checker-explorer
correspondence: imports every module and prints
the axioms each declaration depends on. scripts/check-lean.sh demands that
this list is exactly the set of theorem, def, abbrev, inductive and
structure declarations of the ported modules, and that no printed axiom lies
outside its allow-list (which is empty).
-/

-- ResidualEvidence.lean
#print axioms MetaManifoldEvidence.ResidualEvidence.Le
#print axioms MetaManifoldEvidence.ResidualEvidence.Candidate
#print axioms MetaManifoldEvidence.ResidualEvidence.Case
#print axioms MetaManifoldEvidence.ResidualEvidence.Holds
#print axioms MetaManifoldEvidence.ResidualEvidence.Int
#print axioms MetaManifoldEvidence.ResidualEvidence.«⊖»
#print axioms MetaManifoldEvidence.ResidualEvidence.«+ᵢ»
#print axioms MetaManifoldEvidence.ResidualEvidence.absᵢ
#print axioms MetaManifoldEvidence.ResidualEvidence.signᵢ
#print axioms MetaManifoldEvidence.ResidualEvidence.«==ᵢ»
#print axioms MetaManifoldEvidence.ResidualEvidence.range
#print axioms MetaManifoldEvidence.ResidualEvidence.View
#print axioms MetaManifoldEvidence.ResidualEvidence.Verdict
#print axioms MetaManifoldEvidence.ResidualEvidence.IdStatus
#print axioms MetaManifoldEvidence.ResidualEvidence.Row
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.«not»
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.«∧»
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.«∨»
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.World
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.latent
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.noise
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.absN
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.through
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.Config
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.observe
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.target
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.zeroCheck
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.admits
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.consIf
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.noiseLoop
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.latentLoop
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.enumerate
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.present
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.absent
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.any
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.classify
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.presenceOf
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.latentsFrom
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.latents
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.presence
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.identityOf
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.identity
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.length
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.map
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.forEach
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.summarise
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.report
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.bounds
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.views
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.flags
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.allConfigs
#print axioms MetaManifoldEvidence.ResidualEvidence.Checker.table

-- Counts.lean
#print axioms MetaManifoldEvidence.Counts.Uplus
#print axioms MetaManifoldEvidence.Counts.«≤-refl»
#print axioms MetaManifoldEvidence.Counts.«≤-pred»
#print axioms MetaManifoldEvidence.Counts.peel
#print axioms MetaManifoldEvidence.Counts.«≤-zero»
#print axioms MetaManifoldEvidence.Counts.«suc≰zero»
#print axioms MetaManifoldEvidence.Counts.«≤-trans»
#print axioms MetaManifoldEvidence.Counts.«≤-total»
#print axioms MetaManifoldEvidence.Counts.«zero-+»
#print axioms MetaManifoldEvidence.Counts.«suc-+»
#print axioms MetaManifoldEvidence.Counts.«≤-step»
#print axioms MetaManifoldEvidence.Counts.«≤-+ʳ»
#print axioms MetaManifoldEvidence.Counts.«+-monoʳ»
#print axioms MetaManifoldEvidence.Counts.«+-cancelʳ»
#print axioms MetaManifoldEvidence.Counts.«+-assoc»
#print axioms MetaManifoldEvidence.Counts.«+-zero»
#print axioms MetaManifoldEvidence.Counts.«+-suc»
#print axioms MetaManifoldEvidence.Counts.«+-comm»
#print axioms MetaManifoldEvidence.Counts.subst
#print axioms MetaManifoldEvidence.Counts.«suc-∸-suc»
#print axioms MetaManifoldEvidence.Counts.«zero-∸»
#print axioms MetaManifoldEvidence.Counts.«+-∸»
#print axioms MetaManifoldEvidence.Counts.«≤-diff»
#print axioms MetaManifoldEvidence.Counts.«<-true»
#print axioms MetaManifoldEvidence.Counts.«zero-<-suc»
#print axioms MetaManifoldEvidence.Counts.«<-false»
#print axioms MetaManifoldEvidence.Counts.Direction
#print axioms MetaManifoldEvidence.Counts.World
#print axioms MetaManifoldEvidence.Counts.latent
#print axioms MetaManifoldEvidence.Counts.observed
#print axioms MetaManifoldEvidence.Counts.Bounded
#print axioms MetaManifoldEvidence.Counts.ReadFibre
#print axioms MetaManifoldEvidence.Counts.Present
#print axioms MetaManifoldEvidence.Counts.Absent
#print axioms MetaManifoldEvidence.Counts.noiseless
#print axioms MetaManifoldEvidence.Counts.«case»
#print axioms MetaManifoldEvidence.Counts.InInterval
#print axioms MetaManifoldEvidence.Counts.«fibre⇒interval»
#print axioms MetaManifoldEvidence.Counts.«interval⇒fibre»
#print axioms MetaManifoldEvidence.Counts.verdict
#print axioms MetaManifoldEvidence.Counts.«irrefl»
#print axioms MetaManifoldEvidence.Counts.«entailed-sound»
#print axioms MetaManifoldEvidence.Counts.«≤0»
#print axioms MetaManifoldEvidence.Counts.«refuted-sound»
#print axioms MetaManifoldEvidence.Counts.«unresolved-sound»
#print axioms MetaManifoldEvidence.Counts.Sound
#print axioms MetaManifoldEvidence.Counts.«verdict-sound»
#print axioms MetaManifoldEvidence.Counts.«never-inconsistent»

-- Bounds.lean
#print axioms MetaManifoldEvidence.Bounds.lo
#print axioms MetaManifoldEvidence.Bounds.hi
#print axioms MetaManifoldEvidence.Bounds.«≤⇒lo»
#print axioms MetaManifoldEvidence.Bounds.«lo⇒≤»
#print axioms MetaManifoldEvidence.Bounds.InBounds
#print axioms MetaManifoldEvidence.Bounds.«fibre⇒bounds»
#print axioms MetaManifoldEvidence.Bounds.«bounds⇒fibre»
#print axioms MetaManifoldEvidence.Bounds.VerdictView
#print axioms MetaManifoldEvidence.Bounds.view
#print axioms MetaManifoldEvidence.Bounds.«view-at»
#print axioms MetaManifoldEvidence.Bounds.«entailed-anti»
#print axioms MetaManifoldEvidence.Bounds.«unresolved-mono»
#print axioms MetaManifoldEvidence.Bounds.«refuted-only-at-zero»
#print axioms MetaManifoldEvidence.Bounds.«refuted-fragile»
#print axioms MetaManifoldEvidence.Bounds.«never-strengthens»

-- CheckerBridge.lean
#print axioms MetaManifoldEvidence.CheckerBridge.asConfig
#print axioms MetaManifoldEvidence.CheckerBridge.naturals
#print axioms MetaManifoldEvidence.CheckerBridge.spanFrom
#print axioms MetaManifoldEvidence.CheckerBridge.span
#print axioms MetaManifoldEvidence.CheckerBridge.min
#print axioms MetaManifoldEvidence.CheckerBridge.checkerLatents
#print axioms MetaManifoldEvidence.CheckerBridge.upto6
#print axioms MetaManifoldEvidence.CheckerBridge.PresenceAgrees
#print axioms MetaManifoldEvidence.CheckerBridge.«presence-agrees»
#print axioms MetaManifoldEvidence.CheckerBridge.LatentsAgree
#print axioms MetaManifoldEvidence.CheckerBridge.«latents-agree»

-- CountsGrid.lean
#print axioms MetaManifoldEvidence.CountsGrid.Row
#print axioms MetaManifoldEvidence.CountsGrid.cell
#print axioms MetaManifoldEvidence.CountsGrid.upto
#print axioms MetaManifoldEvidence.CountsGrid.along
#print axioms MetaManifoldEvidence.CountsGrid.cells
#print axioms MetaManifoldEvidence.CountsGrid.grid

-- CountsJuliaTable.lean
#print axioms MetaManifoldEvidence.CountsJuliaTable.expected

-- CountsCertificate.lean
#print axioms MetaManifoldEvidence.CountsCertificate.«julia-agrees»

-- ExplorerTable.lean
#print axioms MetaManifoldEvidence.ExplorerTable.expected

-- Correspondence.lean
#print axioms MetaManifoldEvidence.Correspondence.«checker-matches-explorer»
