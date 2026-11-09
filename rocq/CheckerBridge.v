(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Rocq recheck leg (route: re-proved) of
   agda/src/MetaManifold/Evidence/CheckerBridge.agda: the counts model
   against the ported finite checker of residual-evidence-types, on residual
   y in 0..6 and noise bound n in 0..6, exact view, no zero assumption.
   As in Agda, each of the 49 cells is decided by computation. *)

From Coq Require Import List.
Import ListNotations.
From MetaManifoldEvidence Require Import ResidualEvidence Counts Bounds.
Import Prelude FiniteInt Row.

(* The checker configuration for y observed reads under noise bound n. *)
Definition asConfig (y n : nat) : Checker.Config :=
  Checker.config (pos y) n exact false.

(* The non-negative entries of a list of integers, as naturals, in order. *)
Fixpoint naturals (xs : list Int) : list nat :=
  match xs with
  | [] => []
  | pos k :: xs' => k :: naturals xs'
  | negsuc _ :: xs' => naturals xs'
  end.

(* Agda's local `from` in `span`. *)
Fixpoint span_from (x k : nat) : list nat :=
  match k with
  | 0 => []
  | S k' => x :: span_from (S x) k'
  end.

(* lo, lo + 1, ..., hi; empty when hi < lo.  _-_ is Nat.sub. *)
Definition span (a b : nat) : list nat := span_from a (S b - a).

(* The smaller of two naturals, by Agda's builtin _<_ (Nat.ltb). *)
Definition min (a b : nat) : nat :=
  match Nat.ltb a b with
  | true => a
  | false => b
  end.

(* The checker's natural latents for a counts cell. *)
Definition checkerLatents (y n : nat) : list nat :=
  naturals (Checker.latents (Checker.enumerate (asConfig y n))).

(* A property of every k ≤ 6 follows from its seven instances.
   Agda: P : Nat → Set p; here P : nat -> Prop. *)
Lemma upto6 : forall (P : nat -> Prop),
  P 0 -> P 1 -> P 2 -> P 3 -> P 4 -> P 5 -> P 6 -> forall {k : nat}, k ≤ 6 -> P k.
Proof.
  intros P p0 p1 p2 p3 p4 p5 p6 k h.
  repeat match goal with
         | H : ?a ≤ ?b |- _ => inversion H; subst; clear H
         end; assumption.
Qed.

Definition PresenceAgrees (y n : nat) : Prop :=
  Checker.presence (asConfig y n) = verdict y n.

Theorem presence_agrees : forall {y n : nat}, y ≤ 6 -> n ≤ 6 -> PresenceAgrees y n.
Proof.
  intros y n py. revert n.
  refine (upto6 (fun y => forall n, n ≤ 6 -> PresenceAgrees y n) _ _ _ _ _ _ _ py);
    intros n pn;
    refine (upto6 (PresenceAgrees _) _ _ _ _ _ _ _ pn);
    reflexivity.
Qed.

Definition LatentsAgree (y n : nat) : Prop :=
  checkerLatents y n = span (lo y n) (min (hi y n) 6).

Theorem latents_agree : forall {y n : nat}, y ≤ 6 -> n ≤ 6 -> LatentsAgree y n.
Proof.
  intros y n py. revert n.
  refine (upto6 (fun y => forall n, n ≤ 6 -> LatentsAgree y n) _ _ _ _ _ _ _ py);
    intros n pn;
    refine (upto6 (LatentsAgree _) _ _ _ _ _ _ _ pn);
    reflexivity.
Qed.
