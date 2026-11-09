(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Rocq recheck leg (route: re-proved) of
   agda/src/MetaManifold/Evidence/Bounds.agda. *)

From Coq Require Import Arith.
From MetaManifoldEvidence Require Import ResidualEvidence Counts.
Import Prelude Core Row.

(* ------------------------------------------------------------------ *)
(* The interval ends.  Agda's builtin _-_ on Nat is truncated
   subtraction, Nat.sub here (same clauses).                           *)

Definition lo (y n : nat) : nat := y - n.
Definition hi (y n : nat) : nat := y + n.

(* Agda: ≤⇒lo *)
Lemma le_to_lo : forall y n x, y ≤ x + n -> lo y n ≤ x.
Proof.
  induction y as [|y IH]; intros [|n] x p; simpl.
  - constructor.
  - constructor.
  - rewrite Nat.add_0_r in p. exact p.
  - rewrite Nat.add_succ_r in p. inversion p; subst. apply IH; assumption.
Qed.

(* Agda: lo⇒≤ *)
Theorem lo_to_le : forall y n x, lo y n ≤ x -> y ≤ x + n.
Proof.
  induction y as [|y IH]; intros [|n] x p; simpl in p.
  - constructor.
  - constructor.
  - rewrite Nat.add_0_r. exact p.
  - rewrite Nat.add_succ_r. constructor. apply IH, p.
Qed.

Definition InBounds (y n x : nat) : Prop := (lo y n ≤ x) /\ (x ≤ hi y n).

Theorem fibre_to_bounds : forall {y n : nat} (c : ReadFibre y n),
  InBounds y n (latent (proj1_sig c)).
Proof.
  intros y n c. destruct (fibre_to_interval c) as [below above].
  split; [apply le_to_lo; exact below | exact above].
Qed.

Theorem bounds_to_fibre : forall {y n x : nat}, InBounds y n x ->
  { c : ReadFibre y n | latent (proj1_sig c) = x }.
Proof.
  intros y n x [l h].
  exact (interval_to_fibre (conj (lo_to_le y n x l) h)).
Defined.

(* ------------------------------------------------------------------ *)
(* A complete characterisation of the verdict                          *)

Inductive VerdictView (y n : nat) : Verdict -> Prop :=
| v_entailed : S n ≤ y -> VerdictView y n entailed
| v_refuted : y = 0 -> n = 0 -> VerdictView y n refuted
| v_unresolved : y ≤ n -> S 0 ≤ n -> VerdictView y n unresolved.

Theorem view : forall y n : nat, VerdictView y n (verdict y n).
Proof.
  intros y n. unfold verdict.
  destruct (Nat.ltb n y) eqn:E.
  - apply v_entailed, ltb_true, E.
  - destruct y as [|k].
    + destruct n as [|m].
      * apply v_refuted; reflexivity.
      * apply v_unresolved; [constructor | constructor; constructor].
    + pose proof (ltb_false n (S k) E) as yn.
      apply v_unresolved; [exact yn | exact (le_trans _ _ _ (s_le_s z_le_n) yn)].
Qed.

Theorem view_at : forall {y n : nat} {v : Verdict}, verdict y n = v -> VerdictView y n v.
Proof. intros y n v h. rewrite <- h. apply view. Qed.

(* ------------------------------------------------------------------ *)
(* Moving the bound                                                    *)

Theorem entailed_anti : forall {y n n' : nat}, n' ≤ n ->
  verdict y n = entailed -> verdict y n' = entailed.
Proof.
  intros y n n' n'n h.
  pose proof (view_at h) as V; inversion V as [ny | |]; subst.
  destruct (view y n') as [ | y0 n'0 | yn' _ ].
  - reflexivity.
  - subst. inversion ny.
  - exact (False_ind _ (irrefl n (le_trans _ _ _ ny (le_trans _ _ _ yn' n'n)))).
Qed.

Theorem unresolved_mono : forall {y n n' : nat}, n ≤ n' ->
  verdict y n = unresolved -> verdict y n' = unresolved.
Proof.
  intros y n n' nn' h.
  pose proof (view_at h) as V; inversion V as [ | | yn one_n]; subst.
  destruct (view y n') as [ n'y | _ n'0 | ].
  - exact (False_ind _ (irrefl n' (le_trans _ _ _ n'y (le_trans _ _ _ yn nn')))).
  - subst. pose proof (le_trans _ _ _ one_n nn') as bad. inversion bad.
  - reflexivity.
Qed.

Theorem refuted_only_at_zero : forall {y n : nat}, verdict y n = refuted ->
  (y = 0) /\ (n = 0).
Proof.
  intros y n h. pose proof (view_at h) as V; inversion V as [ | y0 n0 | ]. split; assumption.
Qed.

Theorem refuted_fragile : forall {y n n' : nat}, verdict y n = refuted ->
  S 0 ≤ n' -> verdict y n' = unresolved.
Proof.
  intros y n n' h one_n'.
  destruct (refuted_only_at_zero h) as [y0 _]. subst y.
  destruct (view 0 n') as [ n'y | _ n'0 | ].
  - inversion n'y.
  - subst. inversion one_n'.
  - reflexivity.
Qed.

Theorem never_strengthens : forall {y n n' : nat}, n ≤ n' ->
  (verdict y n' = entailed -> verdict y n = entailed) /\
  (verdict y n' = refuted -> n' = 0).
Proof.
  intros y n n' nn'. split.
  - exact (@entailed_anti y n' n nn').
  - intros h. exact (proj2 (refuted_only_at_zero h)).
Qed.
