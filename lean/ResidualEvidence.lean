-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

/-!
Port of the residual-evidence-types vocabulary used by the counts theorems,
from hyperpolymath/residual-evidence-types at commit
559bba424f1819e4eb7c3104b418c4c5f5a1a22f (the commit scripts/fetch-layer-a.sh
pins):

* `ResidualEvidence.Prelude`: `_≤_` (as `Le`, notation `≤ₐ`);
* `ResidualEvidence.Core`: `Candidate`, `Case`, `Holds`;
* `ResidualEvidence.Finite.Int`: `Int` (`pos`/`negsuc`), `_⊖_`, `_+ᵢ_`,
  `absᵢ`, `signᵢ`, `_==ᵢ_`, `range`;
* `ResidualEvidence.Finite.Row`: `View`, `Verdict`, `IdStatus`, `Row`;
* `ResidualEvidence.Finite.Checker`: the definitions `presence`, `enumerate`
  and `latents` reduce through, and the 546-row `table` that
  `tests/correspondence/Correspondence.agda` proves equal to the explorer's
  table (lean/Correspondence.lean proves the same equation for this port).

Only definitions a theorem here mentions, directly or through the
definitions it unfolds, are ported. Every function is written with the same
clauses as the Agda source. Agda's builtin `Nat` operations map to the Lean
core functions that compute the same values: `_+_` to `Nat.add`, `_-_`
(truncated) to `Nat.sub`, `_<_` to `Nat.blt`, `_==_` to `Nat.beq`.
See lean/CORRESPONDENCE.adoc for every deliberate difference.
-/

namespace MetaManifoldEvidence.ResidualEvidence

universe u v

------------------------------------------------------------------------
-- Prelude

/-- `ResidualEvidence.Prelude._≤_`: the inductive order with the same two
constructors `z≤n` and `s≤s`, not Lean's `Nat.le`. -/
inductive Le : Nat → Nat → Prop where
  | «z≤n» {n : Nat} : Le 0 n
  | «s≤s» {m n : Nat} : Le m n → Le (m + 1) (n + 1)

@[inherit_doc] infix:50 " ≤ₐ " => Le

------------------------------------------------------------------------
-- Core

/-- `Candidate observe r E = Σ W (λ world → (observe world ≡ r) × E world)`. -/
def Candidate {W : Type u} {O : Type v} (observe : W → O) (r : O) (E : W → Prop) : Type u :=
  {world : W // observe world = r ∧ E world}

/-- `record Case observe r E` with constructor `inhabited` and field `witness`. -/
structure Case {W : Type u} {O : Type v} (observe : W → O) (r : O) (E : W → Prop) : Type u where
  inhabited ::
  witness : Candidate observe r E

/-- `Holds c P = (x : Candidate observe r E) → P (fst x)`. -/
def Holds {W : Type u} {O : Type v} {observe : W → O} {r : O} {E : W → Prop}
    (_c : Case observe r E) (P : W → Prop) : Prop :=
  ∀ x : Candidate observe r E, P x.1

------------------------------------------------------------------------
-- Finite.Int: Agda.Builtin.Int, defined here rather than Lean's `Int`

/-- `Agda.Builtin.Int.Int`: `pos n` is n, `negsuc n` is −(n+1). -/
inductive Int : Type where
  | pos : Nat → Int
  | negsuc : Nat → Int

open Int

/-- `_⊖_`: m − n, landing in whichever constructor the sign demands. -/
def «⊖» : Nat → Nat → Int
  | m, 0 => pos m
  | 0, n + 1 => negsuc n
  | m + 1, n + 1 => «⊖» m n

/-- `_+ᵢ_`. -/
def «+ᵢ» : Int → Int → Int
  | pos m, pos n => pos (m + n)
  | pos m, negsuc n => «⊖» m (n + 1)
  | negsuc m, pos n => «⊖» n (m + 1)
  | negsuc m, negsuc n => negsuc ((m + n) + 1)

infixl:65 " +ᵢ " => «+ᵢ»

/-- `absᵢ` (JS `Math.abs`). -/
def absᵢ : Int → Int
  | pos n => pos n
  | negsuc n => pos (n + 1)

/-- `signᵢ` (JS `Math.sign`). -/
def signᵢ : Int → Int
  | pos 0 => pos 0
  | pos (_ + 1) => pos 1
  | negsuc _ => negsuc 0

/-- `_==ᵢ_`, with Agda's builtin `_==_` on `Nat` as `Nat.beq`. -/
def «==ᵢ» : Int → Int → Bool
  | pos m, pos n => Nat.beq m n
  | negsuc m, negsuc n => Nat.beq m n
  | pos _, negsuc _ => false
  | negsuc _, pos _ => false

infix:50 " ==ᵢ " => «==ᵢ»

/-- Ascending −6..6, thirteen elements: the explorer's residual loop order. -/
def range : List Int :=
  [negsuc 5, negsuc 4, negsuc 3, negsuc 2, negsuc 1, negsuc 0,
   pos 0, pos 1, pos 2, pos 3, pos 4, pos 5, pos 6]

------------------------------------------------------------------------
-- Finite.Row

/-- `View`: exact = x ↦ x, sign = Math.sign, magnitude = Math.abs. -/
inductive View : Type where
  | exact | sign | magnitude

/-- `Verdict`. -/
inductive Verdict : Type where
  | entailed | refuted | unresolved | inconsistent

/-- `IdStatus`: identify(c, w => w.latent).status in the explorer. -/
inductive IdStatus : Type where
  | identified | unidentified | «no-candidate»

/-- `record Row` with constructor `row`. -/
structure Row : Type where
  row ::
  residual : Int
  noiseBound : Nat
  view : View
  assumeZero : Bool
  count : Nat
  presence : Verdict
  identity : IdStatus
  values : List Int

------------------------------------------------------------------------
-- Finite.Checker

namespace Checker

/-- `not`, `_∧_`, `_∨_` with the Agda clauses. -/
def «not» : Bool → Bool
  | true => false
  | false => true

def «∧» : Bool → Bool → Bool
  | true, b => b
  | false, _ => false

def «∨» : Bool → Bool → Bool
  | true, _ => true
  | false, b => b

/-- `World = Int × Int`. -/
abbrev World : Type := Int × Int

def latent : World → Int := Prod.fst
def noise : World → Int := Prod.snd

/-- `∣_∣`: |x| as a natural number. -/
def absN : Int → Nat
  | pos n => n
  | negsuc n => n + 1

def through : View → Int → Int
  | .exact, x => x
  | .sign, x => signᵢ x
  | .magnitude, x => absᵢ x

/-- `record Config` with constructor `config`. -/
structure Config : Type where
  config ::
  residual : Int
  noiseBound : Nat
  view : View
  assumeZero : Bool

open Config

def observe (cfg : Config) (w : World) : Int :=
  through (view cfg) (latent w +ᵢ noise w)

def target (cfg : Config) : Int :=
  through (view cfg) (residual cfg)

def zeroCheck : Bool → Int → Bool
  | false, _ => true
  | true, l => l ==ᵢ pos 0

/-- `admits`; Agda's builtin `_<_` is `Nat.blt`. -/
def admits (cfg : Config) (w : World) : Bool :=
  «∧» (Nat.blt (absN (noise w)) (noiseBound cfg + 1))
    («∧» (zeroCheck (assumeZero cfg) (latent w))
      (observe cfg w ==ᵢ target cfg))

def consIf : Bool → World → List World → List World
  | true, w, ws => w :: ws
  | false, _, ws => ws

def noiseLoop (cfg : Config) (l : Int) : List Int → List World → List World
  | [], rest => rest
  | n :: ns, rest => consIf (admits cfg (l, n)) (l, n) (noiseLoop cfg l ns rest)

def latentLoop (cfg : Config) : List Int → List World
  | [] => []
  | l :: ls => noiseLoop cfg l range (latentLoop cfg ls)

/-- `c.candidates`, latent ascending, then noise. -/
def enumerate (cfg : Config) : List World :=
  latentLoop cfg range

def present (w : World) : Bool := «not» (latent w ==ᵢ pos 0)
def absent (w : World) : Bool := latent w ==ᵢ pos 0

def any (p : World → Bool) : List World → Bool
  | [] => false
  | w :: ws => «∨» (p w) (any p ws)

def classify : Bool → Bool → Verdict
  | _, false => .entailed
  | false, true => .refuted
  | true, true => .unresolved

def presenceOf : List World → Verdict
  | [] => .inconsistent
  | ws@(_ :: _) => classify (any present ws) (any absent ws)

/-- `latentsFrom`, with the mutually defined `latentsStep` inlined as a match
on the same Boolean, so that the recursion is structural on the list. -/
def latentsFrom (x : Int) : List World → List Int
  | [] => []
  | w :: ws =>
    match x ==ᵢ latent w with
    | true => latentsFrom x ws
    | false => latent w :: latentsFrom (latent w) ws

def latents : List World → List Int
  | [] => []
  | w :: ws => latent w :: latentsFrom (latent w) ws

def presence (cfg : Config) : Verdict :=
  presenceOf (enumerate cfg)

def identityOf : List Int → IdStatus
  | [] => .«no-candidate»
  | [_] => .identified
  | _ :: _ :: _ => .unidentified

def identity (cfg : Config) : IdStatus :=
  identityOf (latents (enumerate cfg))

------------------------------------------------------------------------
-- The table

def length {A : Type} : List A → Nat
  | [] => 0
  | _ :: xs => length xs + 1

def map {A B : Type} (f : A → B) : List A → List B
  | [] => []
  | x :: xs => f x :: map f xs

/-- One iteration of a JavaScript `for` loop. -/
def forEach {A B : Type} : List A → (A → List B → List B) → List B → List B
  | [], _, rest => rest
  | x :: xs, body, rest => body x (forEach xs body rest)

def summarise (cfg : Config) (ws : List World) : Row :=
  Row.row (residual cfg) (noiseBound cfg) (view cfg) (assumeZero cfg)
    (length ws) (presenceOf ws) (identityOf (latents ws)) (latents ws)

def report (cfg : Config) : Row :=
  summarise cfg (enumerate cfg)

def bounds : List Nat := [0, 1, 2, 3, 4, 5, 6]

def views : List View := [.exact, .sign, .magnitude]

def flags : List Bool := [false, true]

/-- The 546 configurations in the explorer's order. -/
def allConfigs : List Config :=
  forEach range (fun r =>
  forEach bounds (fun b =>
  forEach views (fun v =>
  forEach flags (fun z =>
  fun rest => Config.config r b v z :: rest)))) []

def table : List Row :=
  map report allConfigs

end Checker

end MetaManifoldEvidence.ResidualEvidence
