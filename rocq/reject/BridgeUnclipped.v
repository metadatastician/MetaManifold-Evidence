(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Expected rejection (mirrors agda/reject/BridgeUnclipped.agda): the
   checker's latents stop at 6, so the cut-off min (hi y n) 6 cannot be
   dropped: at y = 6, n = 1 the counts interval reaches 7. *)

From MetaManifoldEvidence Require Import ResidualEvidence Bounds CheckerBridge.

Definition invalid : checkerLatents 6 1 = span (lo 6 1) (hi 6 1) :=
  eq_refl.
