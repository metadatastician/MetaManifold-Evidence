(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Port of agda/src/MetaManifold/Evidence/CountsGrid.agda: the grid the
   Julia certificate is checked on, one row per read count and noise bound
   in 0..k, holding the closed forms `verdict`, `lo`, `hi`. *)

From Coq Require Import List.
Import ListNotations.
From MetaManifoldEvidence Require Import ResidualEvidence Counts Bounds.
Import Row.

(* reads, noise bound, verdict, lower end, upper end *)
Inductive Row : Set :=
| row : nat -> nat -> Verdict -> nat -> nat -> Row.

Definition cell (y n : nat) : Row := row y n (verdict y n) (lo y n) (hi y n).

(* 0 :: 1 :: ... :: k :: [], built with the same accumulator as Agda. *)
Fixpoint upto_go (i : nat) (acc : list nat) : list nat :=
  match i with
  | 0 => 0 :: acc
  | S i' => upto_go i' (S i' :: acc)
  end.

Definition upto (k : nat) : list nat := upto_go k [].

(* Every pair, first component outermost.  Agda's local `along` calls back
   into `cells`; here it is a nested fix with the same clauses. *)
Fixpoint cells (ys ns : list nat) : list Row :=
  match ys with
  | [] => []
  | y :: ys' =>
      (fix along (ms : list nat) : list Row :=
         match ms with
         | [] => cells ys' ns
         | m :: ms' => cell y m :: along ms'
         end) ns
  end.

Definition grid (k : nat) : list Row := cells (upto k) (upto k).
