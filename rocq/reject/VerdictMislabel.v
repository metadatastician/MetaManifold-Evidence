(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Expected rejection (mirrors agda/reject/VerdictMislabel.agda): 3 reads
   under bound 1 is entailed, not unresolved. *)

From MetaManifoldEvidence Require Import ResidualEvidence Counts.
Import Row.

Definition invalid : verdict 3 1 = unresolved :=
  eq_refl.
