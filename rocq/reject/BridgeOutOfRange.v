(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Expected rejection (mirrors agda/reject/BridgeOutOfRange.agda): the bridge
   needs y ≤ 6.  At y = 7 the checker, confined to -6..6, finds no candidate
   and says inconsistent, while counts say entailed. *)

From MetaManifoldEvidence Require Import ResidualEvidence Counts CheckerBridge.

Definition invalid : Checker.presence (asConfig 7 0) = verdict 7 0 :=
  eq_refl.
