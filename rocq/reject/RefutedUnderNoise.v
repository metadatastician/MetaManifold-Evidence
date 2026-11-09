(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Expected rejection (mirrors agda/reject/RefutedUnderNoise.agda):
   refuted_sound is for y = n = 0 only; under noise 1 the latent may be 1. *)

From MetaManifoldEvidence Require Import ResidualEvidence Counts.
Import Prelude Core.

Definition invalid : Holds (case 0 1) Absent :=
  refuted_sound.
