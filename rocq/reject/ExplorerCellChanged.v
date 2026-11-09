(* SPDX-License-Identifier: MPL-2.0 *)
(* SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell *)

(* Expected rejection for Correspondence.v: change one cell of the 546-row
   explorer table -- the presence verdict of the first row, entailed to
   unresolved -- and the ported checker's table no longer equals it.  Shows
   that `checker_matches_explorer` is decided cell by cell and is not
   vacuous. *)

From MetaManifoldEvidence Require Import ResidualEvidence ExplorerTable.
Import Row Checker.

Definition oneCellChanged : list Checker.Row :=
  match expected with
  | cons (row r b v z k _ i xs) rest => cons (row r b v z k unresolved i xs) rest
  | nil => nil
  end.

Definition invalid : Checker.table = oneCellChanged :=
  eq_refl.
