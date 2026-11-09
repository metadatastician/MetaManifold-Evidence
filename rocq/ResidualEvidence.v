(* SPDX-License-Identifier: MPL-2.0 *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* The part of residual-evidence-types that the MetaManifold counts theorems
   mention, ported by hand from the Agda sources of that library:

     ResidualEvidence/Prelude.agda       -> Module Prelude
     ResidualEvidence/Core.agda          -> Module Core
     ResidualEvidence/Finite/Int.agda    -> Module FiniteInt
     ResidualEvidence/Finite/Row.agda    -> Module Row
     ResidualEvidence/Finite/Checker.agda -> Module Checker

   Only the definitions the counts theorems reach are ported.  Each keeps the
   Agda constructors and computes by the same clauses.  Deliberate
   differences are listed in CORRESPONDENCE.adoc; the main one is that
   Agda's proof-relevant families in Set (_≡_, _≤_, _×_ of propositions,
   the empty type) become Rocq propositions (eq, Le, and, False). *)

From Coq Require Import List.
Import ListNotations.

(* ------------------------------------------------------------------ *)
Module Prelude.

(* Agda:  data _≤_ : Nat → Nat → Set where
            z≤n : ∀ {n} → zero ≤ n
            s≤s : ∀ {m n} → m ≤ n → suc m ≤ suc n
   Same two constructors, same implicit arguments; Set becomes Prop. *)
Inductive Le : nat -> nat -> Prop :=
| z_le_n : forall {n : nat}, Le 0 n
| s_le_s : forall {m n : nat}, Le m n -> Le (S m) (S n).

Notation "m ≤ n" := (Le m n) (at level 70, no associativity).

(* The ported order is the standard one.  No proof depends on this; it
   records that Le means what Peano.le means.  No statement uses Peano.le. *)
Lemma Le_iff : forall m n : nat, m ≤ n <-> m <= n.
Proof.
  split.
  - intros H; induction H.
    + apply le_0_n.
    + apply le_n_S; assumption.
  - revert n; induction m as [|m IH]; intros n H.
    + constructor.
    + destruct n as [|n].
      * inversion H.
      * constructor; apply IH; apply le_S_n; assumption.
Qed.

(* Agda's builtin Nat operations are used through their Rocq counterparts:
   _+_ as Nat.add, _-_ as Nat.sub, _<_ as Nat.ltb, _==_ as Nat.eqb.  Each
   Rocq function satisfies, by computation, the defining clauses of the
   Agda builtin (Agda.Builtin.Nat), and those structurally recursive clauses
   determine the function, so both compute the same values. *)
Lemma builtin_nat_clauses :
  (forall n, 0 + n = n) /\ (forall m n, S m + n = S (m + n)) /\
  (forall n, n - 0 = n) /\ (forall m, 0 - S m = 0) /\
  (forall n m, S n - S m = n - m) /\
  (forall n, Nat.ltb n 0 = false) /\ (forall m, Nat.ltb 0 (S m) = true) /\
  (forall n m, Nat.ltb (S n) (S m) = Nat.ltb n m) /\
  (Nat.eqb 0 0 = true) /\ (forall m, Nat.eqb 0 (S m) = false) /\
  (forall n, Nat.eqb (S n) 0 = false) /\
  (forall n m, Nat.eqb (S n) (S m) = Nat.eqb n m).
Proof.
  repeat split; intros; try reflexivity.
  destruct n; reflexivity.
Qed.

End Prelude.

(* ------------------------------------------------------------------ *)
Module Core.

(* Agda:  Candidate observe r E = Σ W (λ world → (observe world ≡ r) × E world)
   Σ over the worlds becomes sig (still a computationally relevant pair, so
   `fst` is proj1_sig); the inner × of two propositions becomes /\. *)
Definition Candidate {W O : Type} (observe : W -> O) (r : O) (E : W -> Prop) : Type :=
  { world : W | observe world = r /\ E world }.

(* Agda:  record Case observe r E where constructor inhabited
                                          field witness : Candidate observe r E *)
Record Case {W O : Type} (observe : W -> O) (r : O) (E : W -> Prop) : Type :=
  inhabited { witness : Candidate observe r E }.
Arguments inhabited {W O observe r E} _.
Arguments witness {W O observe r E} _.

(* Agda:  Holds c P = (x : Candidate observe r E) → P (fst x)
   The claim quantifies over every candidate, not over the witness of c. *)
Definition Holds {W O : Type} {observe : W -> O} {r : O} {E : W -> Prop}
  (c : Case observe r E) (P : W -> Prop) : Prop :=
  forall x : Candidate observe r E, P (proj1_sig x).

End Core.

(* ------------------------------------------------------------------ *)
Module FiniteInt.

(* Agda.Builtin.Int: pos n is n, negsuc n is -(n+1).  Not Z: the checker
   below pattern-matches on these two constructors. *)
Inductive Int : Set :=
| pos : nat -> Int
| negsuc : nat -> Int.

(* m ⊖ zero = pos m;  zero ⊖ suc n = negsuc n;  suc m ⊖ suc n = m ⊖ n *)
Fixpoint minus_int (m n : nat) : Int :=
  match n with
  | 0 => pos m
  | S n' => match m with
            | 0 => negsuc n'
            | S m' => minus_int m' n'
            end
  end.

(* _+ᵢ_ *)
Definition add_int (a b : Int) : Int :=
  match a, b with
  | pos m, pos n => pos (m + n)
  | pos m, negsuc n => minus_int m (S n)
  | negsuc m, pos n => minus_int n (S m)
  | negsuc m, negsuc n => negsuc (S (m + n))
  end.

(* absᵢ *)
Definition abs_int (a : Int) : Int :=
  match a with
  | pos n => pos n
  | negsuc n => pos (S n)
  end.

(* signᵢ *)
Definition sign_int (a : Int) : Int :=
  match a with
  | pos 0 => pos 0
  | pos (S _) => pos 1
  | negsuc _ => negsuc 0
  end.

(* _==ᵢ_, with Agda's builtin Nat _==_ as Nat.eqb (same clauses). *)
Definition eqb_int (a b : Int) : bool :=
  match a, b with
  | pos m, pos n => Nat.eqb m n
  | negsuc m, negsuc n => Nat.eqb m n
  | pos _, negsuc _ => false
  | negsuc _, pos _ => false
  end.

(* Ascending -6..6: the explorer's residual loop order. *)
Definition range : list Int :=
  [negsuc 5; negsuc 4; negsuc 3; negsuc 2; negsuc 1; negsuc 0;
   pos 0; pos 1; pos 2; pos 3; pos 4; pos 5; pos 6].

End FiniteInt.

(* ------------------------------------------------------------------ *)
Module Row.

(* exact = x ↦ x, sign = Math.sign, magnitude = Math.abs *)
Inductive View : Set := exact | sign | magnitude.

Inductive Verdict : Set := entailed | refuted | unresolved | inconsistent.

End Row.

(* ------------------------------------------------------------------ *)
Module Checker.

Import FiniteInt Row.

(* Agda's checker defines its own not, _∧_, _∨_; the standard negb, andb
   and orb are used here, and satisfy the Agda clauses by computation. *)
Lemma bool_clauses :
  negb true = false /\ negb false = true /\
  (forall b, andb true b = b) /\ (forall b, andb false b = false) /\
  (forall b, orb true b = true) /\ (forall b, orb false b = b).
Proof. repeat split. Qed.

Definition World : Set := (Int * Int)%type.

Definition latent (w : World) : Int := fst w.
Definition noise (w : World) : Int := snd w.

(* ∣_∣ *)
Definition abs_nat (a : Int) : nat :=
  match a with
  | pos n => n
  | negsuc n => S n
  end.

Definition through (v : View) (x : Int) : Int :=
  match v with
  | exact => x
  | sign => sign_int x
  | magnitude => abs_int x
  end.

Record Config : Set := config {
  residual : Int;
  noiseBound : nat;
  view : View;
  assumeZero : bool
}.

Definition observe (cfg : Config) (w : World) : Int :=
  through (view cfg) (add_int (latent w) (noise w)).

Definition target (cfg : Config) : Int :=
  through (view cfg) (residual cfg).

Definition zeroCheck (b : bool) (l : Int) : bool :=
  match b with
  | false => true
  | true => eqb_int l (pos 0)
  end.

(* Agda's _<_ on Nat is the builtin Boolean comparison, Nat.ltb here. *)
Definition admits (cfg : Config) (w : World) : bool :=
  Nat.ltb (abs_nat (noise w)) (S (noiseBound cfg)) &&
  (zeroCheck (assumeZero cfg) (latent w) &&
   eqb_int (observe cfg w) (target cfg)).

Definition consIf (b : bool) (w : World) (ws : list World) : list World :=
  match b with
  | true => w :: ws
  | false => ws
  end.

Fixpoint noiseLoop (cfg : Config) (l : Int) (ns : list Int) (rest : list World)
  : list World :=
  match ns with
  | [] => rest
  | n :: ns' => consIf (admits cfg (l, n)) (l, n) (noiseLoop cfg l ns' rest)
  end.

Fixpoint latentLoop (cfg : Config) (ls : list Int) : list World :=
  match ls with
  | [] => []
  | l :: ls' => noiseLoop cfg l range (latentLoop cfg ls')
  end.

Definition enumerate (cfg : Config) : list World := latentLoop cfg range.

Definition present (w : World) : bool := negb (eqb_int (latent w) (pos 0)).
Definition absent (w : World) : bool := eqb_int (latent w) (pos 0).

Fixpoint any (p : World -> bool) (ws : list World) : bool :=
  match ws with
  | [] => false
  | w :: ws' => p w || any p ws'
  end.

Definition classify (supporting counterexample : bool) : Verdict :=
  match supporting, counterexample with
  | _, false => entailed
  | false, true => refuted
  | true, true => unresolved
  end.

(* presenceOf [] = inconsistent;  presenceOf ws@(_ ∷ _) = classify ... *)
Definition presenceOf (ws : list World) : Verdict :=
  match ws with
  | [] => inconsistent
  | _ :: _ => classify (any present ws) (any absent ws)
  end.

(* Agda defines latentsFrom and latentsStep by mutual recursion, with
   latentsStep recursing on its own list argument.  Rocq's guard checker
   does not accept that split, so latentsFrom inlines latentsStep's match;
   latentsStep is kept as a definition and `latentsFrom_step` shows the
   Agda clause holds by computation. *)
Fixpoint latentsFrom (x : Int) (ws : list World) : list Int :=
  match ws with
  | [] => []
  | w :: ws' =>
      match eqb_int x (latent w) with
      | true => latentsFrom x ws'
      | false => latent w :: latentsFrom (latent w) ws'
      end
  end.

Definition latentsStep (b : bool) (x : Int) (w : World) (ws : list World) : list Int :=
  match b with
  | true => latentsFrom x ws
  | false => latent w :: latentsFrom (latent w) ws
  end.

Lemma latentsFrom_step : forall x w ws,
  latentsFrom x (w :: ws) = latentsStep (eqb_int x (latent w)) x w ws.
Proof. reflexivity. Qed.

Definition latents (ws : list World) : list Int :=
  match ws with
  | [] => []
  | w :: ws' => latent w :: latentsFrom (latent w) ws'
  end.

Definition presence (cfg : Config) : Verdict := presenceOf (enumerate cfg).

(* ---- The 546-row table, ported only so that this port can be compared,
   row for row, with the table the Agda checker is proved equal to
   (residual-evidence-types, tests/correspondence/Correspondence.agda,
   `checker-matches-explorer : table ≡ expected`).  See Correspondence.v. *)

(* Agda: Finite/Row.agda, data IdStatus (no-candidate spelt no_candidate). *)
Inductive IdStatus : Set := identified | unidentified | no_candidate.

(* Agda: Finite/Row.agda, record Row with constructor row.  Kept as a
   one-constructor inductive: the Agda field names would clash with the
   Config projections in Rocq's single namespace, and nothing projects them. *)
Inductive Row : Set :=
| row : Int -> nat -> View -> bool -> nat -> Verdict -> IdStatus -> list Int -> Row.

Definition identityOf (xs : list Int) : IdStatus :=
  match xs with
  | [] => no_candidate
  | [_] => identified
  | _ :: _ :: _ => unidentified
  end.

Definition identity (cfg : Config) : IdStatus := identityOf (latents (enumerate cfg)).

(* Agda's length and map have the clauses of List.length and List.map. *)
Definition summarise (cfg : Config) (ws : list World) : Row :=
  row (residual cfg) (noiseBound cfg) (view cfg) (assumeZero cfg)
      (length ws) (presenceOf ws) (identityOf (latents ws)) (latents ws).

Definition report (cfg : Config) : Row := summarise cfg (enumerate cfg).

Fixpoint forEach {A B : Type} (xs : list A) (body : A -> list B -> list B)
  (rest : list B) : list B :=
  match xs with
  | [] => rest
  | x :: xs' => body x (forEach xs' body rest)
  end.

Definition bounds : list nat := [0; 1; 2; 3; 4; 5; 6].
Definition views : list View := [exact; sign; magnitude].
Definition flags : list bool := [false; true].

Definition allConfigs : list Config :=
  forEach range (fun r =>
  forEach bounds (fun b =>
  forEach views (fun v =>
  forEach flags (fun z =>
  cons (config r b v z))))) [].

Definition table : list Row := map report allConfigs.

End Checker.
