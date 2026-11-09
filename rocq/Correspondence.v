(* SPDX-License-Identifier: MPL-2.0 *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Port of residual-evidence-types tests/correspondence/Correspondence.agda
   (commit 559bba424f1819e4eb7c3104b418c4c5f5a1a22f), used here as a
   machine check on the Rocq port of the finite checker.

   Agda proves  checker-matches-explorer : table ≡ expected  by refl, for the
   Agda checker.  This file proves the same equation for the Rocq port of the
   checker against the same 546 rows (transcribed mechanically by
   scripts/gen-rocq-explorer-table.sh).  So the ported checker and the Agda
   checker agree on that table: identical rows -- count, presence verdict,
   identity status and latent list -- for each of the 546 configurations,
   including the 49 that CheckerBridge.v quantifies over.  This is agreement
   on the table, not a proof that the two definitions are equal: a
   configuration outside the table (for example residual 7) is not covered. *)

From MetaManifoldEvidence Require Import ResidualEvidence ExplorerTable.

Theorem checker_matches_explorer : Checker.table = expected.
Proof. reflexivity. Qed.
