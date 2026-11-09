(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Negative control for scripts/check-rocq.sh itself, not part of the leg.
   This file compiles, but its theorem rests on an axiom.  The check script
   runs its Print Assumptions parser over this output and demands that the
   parser refuses it, so a gate that has stopped noticing axioms fails. *)

From MetaManifoldEvidence Require Import ResidualEvidence Counts CheckerBridge.
Import Prelude.

Axiom cheat : forall y n : nat, PresenceAgrees y n.

Theorem leak : forall y n : nat, PresenceAgrees y n.
Proof. exact cheat. Qed.

Check @leak.
Print Assumptions leak.
