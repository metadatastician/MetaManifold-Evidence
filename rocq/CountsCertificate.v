(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Rocq recheck leg (route: re-proved) of
   agda/src/MetaManifold/Evidence/CountsCertificate.agda.  The Julia verdict
   code agrees with the closed forms on every read count and noise bound in
   0..12.  `expected` is generated from the Agda table by
   scripts/gen-rocq-table.sh; `grid 12` is computed from `verdict`, `lo`
   and `hi`.  Agda proves this by `refl`; here by kernel computation. *)

From MetaManifoldEvidence Require Import CountsGrid CountsJuliaTable.

Theorem julia_agrees : grid 12 = expected.
Proof. reflexivity. Qed.
