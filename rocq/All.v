(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Requires every module of the Rocq recheck leg and prints, for each
   theorem, its statement (Check) and its assumptions (Print Assumptions).
   scripts/check-rocq.sh demands "Closed under the global context" for
   every name below, and that every Theorem and Lemma in rocq/*.v is
   listed here. *)

From MetaManifoldEvidence Require
  ResidualEvidence ExplorerTable Correspondence Counts Bounds CountsGrid
  CountsJuliaTable CountsCertificate
  CheckerBridge.

(* The Agda theorems and constructions (one row each in CORRESPONDENCE.adoc). *)
Check @MetaManifoldEvidence.Counts.noiseless.
Print Assumptions MetaManifoldEvidence.Counts.noiseless.
Check @MetaManifoldEvidence.Counts.case.
Print Assumptions MetaManifoldEvidence.Counts.case.
Check @MetaManifoldEvidence.Counts.fibre_to_interval.
Print Assumptions MetaManifoldEvidence.Counts.fibre_to_interval.
Check @MetaManifoldEvidence.Counts.interval_to_fibre.
Print Assumptions MetaManifoldEvidence.Counts.interval_to_fibre.
Check @MetaManifoldEvidence.Counts.verdict.
Print Assumptions MetaManifoldEvidence.Counts.verdict.
Check @MetaManifoldEvidence.Counts.entailed_sound.
Print Assumptions MetaManifoldEvidence.Counts.entailed_sound.
Check @MetaManifoldEvidence.Counts.refuted_sound.
Print Assumptions MetaManifoldEvidence.Counts.refuted_sound.
Check @MetaManifoldEvidence.Counts.unresolved_sound.
Print Assumptions MetaManifoldEvidence.Counts.unresolved_sound.
Check @MetaManifoldEvidence.Counts.verdict_sound.
Print Assumptions MetaManifoldEvidence.Counts.verdict_sound.
Check @MetaManifoldEvidence.Counts.never_inconsistent.
Print Assumptions MetaManifoldEvidence.Counts.never_inconsistent.
Check @MetaManifoldEvidence.Bounds.lo.
Print Assumptions MetaManifoldEvidence.Bounds.lo.
Check @MetaManifoldEvidence.Bounds.hi.
Print Assumptions MetaManifoldEvidence.Bounds.hi.
Check @MetaManifoldEvidence.Bounds.lo_to_le.
Print Assumptions MetaManifoldEvidence.Bounds.lo_to_le.
Check @MetaManifoldEvidence.Bounds.fibre_to_bounds.
Print Assumptions MetaManifoldEvidence.Bounds.fibre_to_bounds.
Check @MetaManifoldEvidence.Bounds.bounds_to_fibre.
Print Assumptions MetaManifoldEvidence.Bounds.bounds_to_fibre.
Check @MetaManifoldEvidence.Bounds.view.
Print Assumptions MetaManifoldEvidence.Bounds.view.
Check @MetaManifoldEvidence.Bounds.view_at.
Print Assumptions MetaManifoldEvidence.Bounds.view_at.
Check @MetaManifoldEvidence.Bounds.entailed_anti.
Print Assumptions MetaManifoldEvidence.Bounds.entailed_anti.
Check @MetaManifoldEvidence.Bounds.unresolved_mono.
Print Assumptions MetaManifoldEvidence.Bounds.unresolved_mono.
Check @MetaManifoldEvidence.Bounds.refuted_only_at_zero.
Print Assumptions MetaManifoldEvidence.Bounds.refuted_only_at_zero.
Check @MetaManifoldEvidence.Bounds.refuted_fragile.
Print Assumptions MetaManifoldEvidence.Bounds.refuted_fragile.
Check @MetaManifoldEvidence.Bounds.never_strengthens.
Print Assumptions MetaManifoldEvidence.Bounds.never_strengthens.
Check @MetaManifoldEvidence.CheckerBridge.presence_agrees.
Print Assumptions MetaManifoldEvidence.CheckerBridge.presence_agrees.
Check @MetaManifoldEvidence.CheckerBridge.latents_agree.
Print Assumptions MetaManifoldEvidence.CheckerBridge.latents_agree.
Check @MetaManifoldEvidence.CountsCertificate.julia_agrees.
Print Assumptions MetaManifoldEvidence.CountsCertificate.julia_agrees.

(* Supporting lemmas of the port. *)
Check @MetaManifoldEvidence.ResidualEvidence.Prelude.Le_iff.
Print Assumptions MetaManifoldEvidence.ResidualEvidence.Prelude.Le_iff.
Check @MetaManifoldEvidence.ResidualEvidence.Prelude.builtin_nat_clauses.
Print Assumptions MetaManifoldEvidence.ResidualEvidence.Prelude.builtin_nat_clauses.
Check @MetaManifoldEvidence.ResidualEvidence.Checker.bool_clauses.
Print Assumptions MetaManifoldEvidence.ResidualEvidence.Checker.bool_clauses.
Check @MetaManifoldEvidence.ResidualEvidence.Checker.latentsFrom_step.
Print Assumptions MetaManifoldEvidence.ResidualEvidence.Checker.latentsFrom_step.
Check @MetaManifoldEvidence.Correspondence.checker_matches_explorer.
Print Assumptions MetaManifoldEvidence.Correspondence.checker_matches_explorer.
Check @MetaManifoldEvidence.Counts.le_refl.
Print Assumptions MetaManifoldEvidence.Counts.le_refl.
Check @MetaManifoldEvidence.Counts.le_trans.
Print Assumptions MetaManifoldEvidence.Counts.le_trans.
Check @MetaManifoldEvidence.Counts.le_total.
Print Assumptions MetaManifoldEvidence.Counts.le_total.
Check @MetaManifoldEvidence.Counts.le_plus_r.
Print Assumptions MetaManifoldEvidence.Counts.le_plus_r.
Check @MetaManifoldEvidence.Counts.plus_mono_r.
Print Assumptions MetaManifoldEvidence.Counts.plus_mono_r.
Check @MetaManifoldEvidence.Counts.plus_cancel_r.
Print Assumptions MetaManifoldEvidence.Counts.plus_cancel_r.
Check @MetaManifoldEvidence.Counts.le_diff.
Print Assumptions MetaManifoldEvidence.Counts.le_diff.
Check @MetaManifoldEvidence.Counts.ltb_true.
Print Assumptions MetaManifoldEvidence.Counts.ltb_true.
Check @MetaManifoldEvidence.Counts.ltb_false.
Print Assumptions MetaManifoldEvidence.Counts.ltb_false.
Check @MetaManifoldEvidence.Counts.irrefl.
Print Assumptions MetaManifoldEvidence.Counts.irrefl.
Check @MetaManifoldEvidence.Counts.le0.
Print Assumptions MetaManifoldEvidence.Counts.le0.
Check @MetaManifoldEvidence.Bounds.le_to_lo.
Print Assumptions MetaManifoldEvidence.Bounds.le_to_lo.
Check @MetaManifoldEvidence.CheckerBridge.upto6.
Print Assumptions MetaManifoldEvidence.CheckerBridge.upto6.
