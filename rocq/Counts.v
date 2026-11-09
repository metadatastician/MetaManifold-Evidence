(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Rocq recheck leg (route: re-proved) of
   agda/src/MetaManifold/Evidence/Counts.agda.  Statements follow the Agda
   ones; CORRESPONDENCE.adoc records the reading and every difference.
   Proofs are by hand: no automation beyond induction, inversion and
   rewriting with closed standard-library equations. *)

From Coq Require Import Arith.
From MetaManifoldEvidence Require Import ResidualEvidence.
Import Prelude Core Row.

(* ------------------------------------------------------------------ *)
(* Arithmetic on the ported order (Agda: ≤-refl ... <-false), by hand  *)

Lemma le_refl : forall n, n ≤ n.
Proof. induction n; constructor; assumption. Qed.

Lemma le_trans : forall a b c, a ≤ b -> b ≤ c -> a ≤ c.
Proof.
  intros a b c p; revert c; induction p as [|m n p IH]; intros c q.
  - constructor.
  - inversion q as [|m' c' q']; subst. constructor. apply IH, q'.
Qed.

(* Agda's ≤-total returns a disjoint sum in Set; `sum` keeps it informative. *)
Fixpoint le_total (a b : nat) : (a ≤ b) + (b ≤ a) :=
  match a, b with
  | 0, _ => inl z_le_n
  | S _, 0 => inr z_le_n
  | S a', S b' =>
      match le_total a' b' with
      | inl p => inl (s_le_s p)
      | inr p => inr (s_le_s p)
      end
  end.

Lemma le_plus_r : forall m k, m ≤ m + k.
Proof. induction m; intros k; simpl; constructor; auto. Qed.

Lemma plus_mono_r : forall m {a b}, a ≤ b -> m + a ≤ m + b.
Proof. induction m; intros a b p; simpl; [exact p | constructor; apply IHm, p]. Qed.

Lemma plus_cancel_r : forall m {a b}, m + a ≤ m + b -> a ≤ b.
Proof.
  induction m; intros a b p; simpl in p; [exact p|].
  inversion p; subst. apply IHm; assumption.
Qed.

(* Agda's ≤-diff: m ≤ n gives the difference as a witness (Σ in Set). *)
Definition le_diff {m n : nat} (p : m ≤ n) : { k : nat | m + k = n }.
Proof.
  exists (n - m).
  induction p as [n|m n p IH]; simpl.
  - destruct n; reflexivity.
  - rewrite IH; reflexivity.
Defined.

(* Bridge from the builtin Boolean comparison (Nat.ltb) to the order. *)
Lemma ltb_true : forall a b, Nat.ltb a b = true -> S a ≤ b.
Proof.
  induction a as [|a IH]; intros [|b] H; try discriminate.
  - constructor; constructor.
  - constructor; exact (IH b H).
Qed.

Lemma ltb_false : forall a b, Nat.ltb a b = false -> b ≤ a.
Proof.
  induction a as [|a IH]; intros [|b] H; try discriminate; try constructor.
  exact (IH b H).
Qed.

(* Agda: the local `absurd`/`go` of entailed-sound and `irrefl` of Bounds. *)
Lemma irrefl : forall k, ~ (S k ≤ k).
Proof. induction k; intros H; inversion H; subst; auto. Qed.

(* Agda: the local `le0` of refuted-sound and `≤0` of Bounds. *)
Lemma le0 : forall {x}, x ≤ 0 -> x = 0.
Proof. intros x H; inversion H; reflexivity. Qed.

(* ------------------------------------------------------------------ *)
(* Worlds, observation, evidence                                       *)

Inductive Direction : Set := over | under.

Record World : Set := world {
  base : nat;
  noise : nat;
  dir : Direction
}.

Definition latent (w : World) : nat :=
  match w with
  | world b d over => b
  | world b d under => b + d
  end.

Definition observed (w : World) : nat :=
  match w with
  | world b d over => b + d
  | world b d under => b
  end.

Definition Bounded (n : nat) (w : World) : Prop := noise w ≤ n.

Definition ReadFibre (y n : nat) : Type := Candidate observed y (Bounded n).

Definition Present (w : World) : Prop := ~ (latent w = 0).
Definition Absent (w : World) : Prop := latent w = 0.

(* ------------------------------------------------------------------ *)
(* Every case is inhabited: the noiseless world.                       *)

Definition noiseless (y n : nat) : ReadFibre y n :=
  exist _ (world y 0 under) (conj eq_refl z_le_n).

Definition case (y n : nat) : Case observed y (Bounded n) :=
  inhabited (noiseless y n).

(* ------------------------------------------------------------------ *)
(* The fibre is the interval: y ≤ x + n and x ≤ y + n.                 *)

Definition InInterval (y n x : nat) : Prop := (y ≤ x + n) /\ (x ≤ y + n).

Theorem fibre_to_interval : forall {y n : nat} (c : ReadFibre y n),
  InInterval y n (latent (proj1_sig c)).
Proof.
  intros y n [[b d [|]] [Hobs Hb]]; unfold Bounded in Hb; simpl in *; subst y;
    unfold InInterval; split.
  - (* over: y = b + d, latent = b *)
    exact (plus_mono_r b Hb).
  - exact (le_trans _ _ _ (le_plus_r b d) (le_plus_r (b + d) n)).
  - (* under: y = b, latent = b + d *)
    rewrite <- Nat.add_assoc. apply le_plus_r.
  - exact (plus_mono_r b Hb).
Qed.

Theorem interval_to_fibre : forall {y n x : nat}, InInterval y n x ->
  { c : ReadFibre y n | latent (proj1_sig c) = x }.
Proof.
  intros y n x [lo hi].
  destruct (le_total x y) as [xy | yx].
  - (* reads over latent by d *)
    destruct (le_diff xy) as [d xd].
    assert (dn : d ≤ n) by (apply (plus_cancel_r x); rewrite xd; exact lo).
    exact (exist _ (exist _ (world x d over) (conj xd dn)) eq_refl).
  - (* latent over reads by d *)
    destruct (le_diff yx) as [d yd].
    assert (dn : d ≤ n) by (apply (plus_cancel_r y); rewrite yd; exact hi).
    exact (exist _ (exist _ (world y d under) (conj eq_refl dn)) yd).
Defined.

(* ------------------------------------------------------------------ *)
(* Closed-form presence verdict and its soundness                      *)

(* Same case split as the Agda `with` chain: n < y first (builtin Boolean
   comparison), then y, then n. *)
Definition verdict (y n : nat) : Verdict :=
  match Nat.ltb n y with
  | true => entailed
  | false =>
      match y with
      | 0 => match n with
             | 0 => refuted
             | S _ => unresolved
             end
      | S _ => unresolved
      end
  end.

Theorem entailed_sound : forall {y n : nat}, S n ≤ y -> Holds (case y n) Present.
Proof.
  intros y n ny c latent0.
  destruct (fibre_to_interval c) as [lo _].
  rewrite latent0 in lo; simpl in lo.
  exact (irrefl n (le_trans _ _ _ ny lo)).
Qed.

Theorem refuted_sound : Holds (case 0 0) Absent.
Proof.
  intros c. destruct (fibre_to_interval c) as [_ hi].
  exact (le0 hi).
Qed.

Theorem unresolved_sound : forall {y n : nat}, y ≤ n -> ~ (y + n = 0) ->
  (~ Holds (case y n) Present) /\ (~ Holds (case y n) Absent).
Proof.
  intros y n yn nonzero. split.
  - intros h.
    (* zero-candidate: world zero y over *)
    exact (h (exist _ (world 0 y over) (conj eq_refl yn)) eq_refl).
  - intros h.
    (* top-candidate: world y n under *)
    exact (nonzero (h (exist _ (world y n under) (conj eq_refl (le_refl n))))).
Qed.

(* The verdict function is sound for every constructor it can return. *)
Inductive Sound (y n : nat) : Verdict -> Prop :=
| is_entailed : Holds (case y n) Present -> Sound y n entailed
| is_refuted : Holds (case y n) Absent -> Sound y n refuted
| is_unresolved : ~ Holds (case y n) Present -> ~ Holds (case y n) Absent ->
                  Sound y n unresolved.

Theorem verdict_sound : forall y n : nat, Sound y n (verdict y n).
Proof.
  intros y n. unfold verdict.
  destruct (Nat.ltb n y) eqn:E.
  - apply is_entailed, entailed_sound, ltb_true, E.
  - destruct y as [|k].
    + destruct n as [|m].
      * apply is_refuted, refuted_sound.
      * destruct (@unresolved_sound 0 (S m) z_le_n ltac:(discriminate)) as [p q].
        apply is_unresolved; assumption.
    + destruct (@unresolved_sound (S k) n (ltb_false n (S k) E) ltac:(discriminate))
        as [p q].
      apply is_unresolved; assumption.
Qed.

(* Counts never produce `inconsistent`. *)
Theorem never_inconsistent : forall y n : nat, ~ (verdict y n = inconsistent).
Proof.
  intros y n. unfold verdict.
  destruct (Nat.ltb n y); [discriminate|].
  destruct y as [|k]; [destruct n|]; discriminate.
Qed.
