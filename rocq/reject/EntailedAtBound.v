(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Expected rejection (mirrors agda/reject/EntailedAtBound.agda): entailed_sound
   needs n < y strictly; at y = n = 2 the premise 3 ≤ 2 has no proof, so the
   boundary cannot be moved onto y = n.  The implicit y, n are given
   explicitly so the failure is the premise, not an inferred bound. *)

From MetaManifoldEvidence Require Import ResidualEvidence Counts.
Import Prelude Core.

Definition invalid : Holds (case 2 2) Present :=
  @entailed_sound 2 2 (s_le_s (s_le_s z_le_n)).
