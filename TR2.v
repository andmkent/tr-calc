(* begin hide *)
Require Import LibTactics.
Require Import List.
Require Import ListSet.
Require Import Arith.
Require Import Relations.
Require Import Bool.
Require Import Coq.Program.Wf.
Require Import String.

Import ListNotations.
Open Scope list_scope.
(* end hide *)

Section LTR.

(** * Basic Definitions for λTR *)

(** Identifiers and objects: *)

Notation opt := option.

Inductive id : Type :=
  Id : nat -> id.

Inductive step : Type := car | cdr.
Hint Constructors step.

Definition path : Type := list step.

Inductive object : Type :=
| obj : path -> id -> object.
Hint Constructors object.

Definition var := (obj []).

(** Types and propositions: *)
Inductive type : Type :=
| tTop  : type
| tBot  : type
| tNat  : type
| tStr  : type
| tT    : type
| tF    : type
| tU    : type -> type -> type
| tCons : type -> type -> type
| tλ    : id -> (type * type) -> prop -> opt object -> type

with prop : Type :=
| Is    : object -> type -> prop
| IsNot : object -> type -> prop
| And   : prop -> prop -> prop
| Or    : prop -> prop -> prop
| TT    : prop
| FF    : prop
| Unk   : prop.
Hint Constructors type prop.

Fixpoint Not (p : prop) : prop :=
  match p with
    | Is o t => IsNot o t
    | IsNot o t => Is o t
    | And p q => Or (Not p) (Not q)
    | Or p q => And (Not p) (Not q)
    | TT => FF
    | FF => TT
    | Unk => Unk
  end.

Hint Resolve eq_nat_dec.

Notation tBool := (tU tT tF).

Infix "::=" := Is (at level 30, right associativity).
Infix "::~" := IsNot (at level 30, right associativity).
Notation "P '&&' Q" := (And P Q). 
Notation "P '||' Q" := (Or P Q).
Notation "P '-->' Q" := (Or (Not P) Q) (at level 90).

(** Expressions and primitive operations: *)
Inductive const_op :=
  opAdd1 | opIsZero | opIsNum | opIsBool | opIsProc | 
  opIsCons | opIsStr | opStrLen | opPlus.
Hint Constructors const_op.

Inductive poly_op :=
 opCar | opCdr.
Hint Constructors poly_op.

Inductive op : Type :=
| c_op : const_op -> op
| p_op : poly_op -> op.
Hint Constructors op.

Inductive exp : Type :=
| eVar : id -> exp
| eOp  : op -> exp
| eTrue  : exp
| eFalse : exp
| eNum : nat -> exp
| eStr : string -> exp
| eIf  : exp -> exp -> exp -> exp
| eλ : id -> type -> exp -> exp
| eApp : exp -> exp -> exp
| eLet : id -> exp -> exp -> exp
| eCons : exp -> exp -> exp.
Hint Constructors exp.

Notation "$" := eVar.
Notation "#t" := eTrue.
Notation "#f" := eFalse.
Notation "#" := eNum.
Notation λ := eλ.
Notation Str := eStr.
Notation If := eIf.
Notation Let := eLet.
Notation Car  := (eApp (eOp (p_op opCar))).
Notation Cdr := (eApp (eOp (p_op opCdr))).
Notation Add1 := (eApp (eOp (c_op opAdd1))).
Notation "Zero?" := (eApp (eOp (c_op opIsZero))).
Notation "Nat?" := (eApp (eOp (c_op opIsNum))).
Notation "Bool?" := (eApp (eOp (c_op opIsBool))).
Notation "Proc?" := (eApp (eOp (c_op opIsProc))).
Notation "Cons?" := (eApp (eOp (c_op opIsCons))).
Notation Cons := eCons.
Notation "Str?" := (eApp (eOp (c_op opIsStr))).
Notation StrLen := (eApp (eOp (c_op opStrLen))).
Notation Plus := (fun x y =>
                    (eApp (eApp (eOp (c_op opPlus)) x) y)).
Notation Apply := eApp.

(** Constant types: *)
Definition const_type (c : const_op) (x:id) : type :=
  match c with
    | opIsNum =>
      (tλ x 
          (tTop, tBool) 
          ((var x) ::= tNat)
          (Some (var x)))
    | opIsProc =>
      (tλ x 
          (tTop, tBool) 
          ((var x) ::= (tλ x (tBot, tTop) TT None)) 
          None)
    | opIsBool =>
      (tλ x 
          (tTop, tBool) 
          ((var x) ::= tBool)
          None)
    | opIsCons =>
      (tλ x 
          (tTop, tBool) 
          ((var x) ::= (tCons tTop tTop))
          None)
    | opAdd1 =>
      (tλ x 
          (tNat, tNat) 
          TT
          None)
    | opIsZero =>
      (tλ x 
          (tNat, tBool) 
          TT
          None)
    | opIsStr =>
      (tλ x 
          (tTop, tBool) 
          ((var x) ::= tStr)
          None)
    | opStrLen =>
      (tλ x 
          (tStr, tNat) 
          TT
          None)
    | opPlus =>
      (tλ x 
          (tNat, (tλ x 
                     (tNat, tNat) 
                     TT
                     None))
          TT
          None)
  end.

(** Decidable equality of defined types thus far: *)

Theorem id_eqdec : 
  forall (x y : id),
    {x = y} + {x <> y}.
Proof. decide equality. Defined.
Hint Resolve id_eqdec.

Theorem step_eqdec : 
  forall (x y: step),
    {x = y} + {x <> y}.
Proof. decide equality. Defined.
Hint Resolve step_eqdec.

Hint Resolve list_eq_dec.

Theorem path_eqdec : 
  forall (x y: path),
    {x = y} + {x <> y}.
Proof. decide equality. Defined.
Hint Resolve path_eqdec.

Theorem obj_eqdec : 
  forall (x y: object),
    {x = y} + {x <> y}.
Proof. decide equality. Defined.
Hint Resolve obj_eqdec.

Fixpoint type_eqdec (x y : type) : {x=y}+{x<>y}
with prop_eqdec (x y : prop) : {x=y}+{x<>y}.
Proof.
  decide equality.
  decide equality.
  decide equality.
  decide equality.
Defined.
Hint Resolve type_eqdec prop_eqdec.


(** * Utility Functions 
 Substitution, free variable checking, etc... *)

Fixpoint setU {X:Type} (dec : forall x y : X, {x=y} + {x<>y})
         (l:list (set X)) : set X :=
  match l with
    | nil => nil
    | x :: xs => set_union dec x (setU dec xs)
  end.

(** Free variable calculations: *)
(* free variables in objects *)
Definition fv_set_o (opto : opt object) : set id :=
  match opto with
    | None => []
    | Some (obj _ x) => [x]
  end.

(* free variables in types *)

Fixpoint fv_set_t (t : type) : set id :=
  match t with
    | tU lhs rhs =>
      set_union id_eqdec (fv_set_t lhs) (fv_set_t rhs)
    | tλ x (t1, t2) p1 o =>
      setU id_eqdec
           [[x];
             (fv_set_t t1);
             (fv_set_t t2);
             (fv_set_p p1);
             (fv_set_o o)]
    | tCons t1 t2 =>
      set_union id_eqdec
                (fv_set_t t1)
                (fv_set_t t2)
    | _ => nil
  end

(* free variables in propositions *)
with fv_set_p (p: prop) : set id :=
  match p with
    | o ::= t => set_union id_eqdec (fv_set_o (Some o)) (fv_set_t t)
    | o ::~ t => set_union id_eqdec (fv_set_o (Some o)) (fv_set_t t)
    | p && q => set_union id_eqdec (fv_set_p p) (fv_set_p q)
    | p || q => set_union id_eqdec (fv_set_p p) (fv_set_p q)
    | _ => nil
  end.

(** Substitution functions: *)
Definition subst_o (o newobj: opt object) (z:id) : opt object :=
  match o with
    | None => None
    | Some (obj pth1 x) =>
      match id_eqdec x z, newobj with
        | left _, None => None
        | left _, Some (obj pth2 y) => Some (obj (pth1 ++ pth2) y)
        | right _, _ => o
      end
  end.


(** _we use true/false instead of +/- for substitution_ *)
Fixpoint subst_p
         (p:prop)
         (opto:opt object)
         (x:id) : prop :=
  match p with
    | (obj pth1 z) ::= t =>
      match id_eqdec x z , set_mem id_eqdec z (fv_set_t t) with
        | left _, _ =>
          match opto with
            | None => TT
            | Some (obj pth2 y) =>
              Is (obj (pth1 ++ pth2) y) (subst_t t opto x)
          end
        | right _, false => p
        | right _, true => TT
      end
    | (obj pth1 z) ::~ t =>
      match id_eqdec x z , set_mem id_eqdec z (fv_set_t t) with
        | left _, _ =>
          match opto with
            | None => TT
            | Some (obj pth2 y) =>
              IsNot (obj (pth1 ++ pth2) y) (subst_t t opto x)
          end
        | right _, false => p
        | right _, true => TT
      end
    | P || Q => (subst_p P opto x) || (subst_p Q opto x)
    | P && Q => (subst_p P opto x) && (subst_p Q opto x)
    | _ => p
  end

with subst_t
             (t:type)
             (opto:opt object)
             (x:id) : type :=
  match t with
    | tU lhs rhs => tU (subst_t lhs opto x) (subst_t rhs opto x)
    | tλ y (t1, t2) p1 opto2 =>
      if id_eqdec x y
      then t
      else tλ y
                ((subst_t t1 opto x),
                 (subst_t t2 opto x))
                (subst_p p1 opto x)
                (subst_o opto2 opto x)
    | tCons t1 t2 => tCons (subst_t t1 opto x)
                           (subst_t t2 opto x)
    | _ => t
  end.

(** All uses of subst_p' and subst_t' "in the wild" call the positive case, from
which the negative case may then be called.  *) 

(** A few helpers to reason about subtyping: *)

Inductive isUnion : type -> Prop :=
| isU : forall t1 t2, isUnion (tU t1 t2).

Fixpoint typestructuralsize (t:type) : nat :=
  match t with
    | tU t1 t2 =>
      S (plus (typestructuralsize t1) (typestructuralsize t2))
    | tλ x (t1, t2) _ _ => S (plus (typestructuralsize t1) (typestructuralsize t2))
    | tCons t1 t2 => S (plus (typestructuralsize t1) (typestructuralsize t2))
    | _ => 1
  end.

Program Fixpoint common_subtype (type1 type2:type)
        {measure (plus (typestructuralsize type1) (typestructuralsize type2))} : bool :=
  match type1, type2 with
    | tTop , _ => true
    | _, tTop => true
    | tBot, _ => false
    | _, tBot => false
    | tU t1 t2, _ => orb (common_subtype t1 type2) 
                             (common_subtype t2 type2)
    | _, tU t1 t2 => orb (common_subtype type1 t1) 
                             (common_subtype type1 t2)
    | tNat, tNat => true
    | tNat, _ => false
    | tStr, tStr => true
    | tStr, _ => false
    | tT, tT => true
    | tT, _ => false
    | tF, tF => true
    | tF, _ => false
    | tλ _ _ _ _, tλ _ _ _ _ => true
    | tλ _ _ _ _, _ => false
    | tCons t1 t2, tCons t3 t4 => andb (common_subtype t1 t3)
                                       (common_subtype t2 t4)
    | tCons _ _, _ => false
  end.
Solve Obligations using crush.

(*
TODO - We must prove all types have a principal type
if we're going to use this for Removed *)

(* NOTE: Our lookup models an environment where every variable in scope
has some type present (even if its only tTop). *)

(** * λTR Core Relations 
   Logic, TypeOf, Subtyping, etc... *)

(** ** Sub-Object Relation*)
Inductive SubObj : relation (opt object) :=
| SO_Refl : forall x, SubObj x x
| SO_Top : forall x, SubObj x None.

(** ** Proves Relation *)
(** "Proves P Q" means proposition "P implies Q" is tautilogical. *)

Inductive Proves : relation prop :=
| P_Refl :
    forall P,
      Proves P P
| P_False :
    forall P,
      Proves FF P
| P_True :
    forall P,
      Proves P TT
| P_AndI :
    forall P Q R,
      Proves P Q 
      -> Proves P R 
      -> Proves P (Q && R)
| P_AndE_lhs :
    forall P Q R,
      Proves P R 
      -> Proves (P && Q) R
| P_AndE_rhs :
    forall P Q R,
      Proves Q R
      -> Proves (P && Q) R
| P_OrI_lhs :
    forall P Q R,
      Proves P Q
      -> Proves P (Q || R)
| P_OrI_rhs :
    forall P Q R,
      Proves P R
      -> Proves P (Q || R)
| P_OrE :
    forall P Q R Y,
      Proves (P && Q) Y
      -> Proves (P && R) Y
      -> Proves (P && (Q || R)) Y
| P_Or :
    forall P Q R,
      Proves P R
      -> Proves Q R
      -> Proves (P || Q) R
| P_Sub :
    forall P τ σ ox,
      Proves P (ox ::= τ)
      -> SubType τ σ
      -> Proves P (ox ::= σ)
| P_SubNot :
    forall P τ σ ox,
      Proves P (ox ::~ σ)
      -> SubType τ σ
      -> Proves P (ox ::~ τ)
| P_RestrictBot :
    forall P ox τ σ,
      Proves P (ox ::= τ)
      -> Proves P (ox ::= σ)
      -> common_subtype τ σ = false
      -> Proves P (ox ::= tBot)
| P_RemoveBot :
    forall P τ σ ox,
      Proves P (ox ::= τ)
      -> Proves P (ox ::~ σ)
      -> SubType τ σ
      -> Proves P (ox ::= tBot)
| P_Bot : 
    forall P Q ox,
      Proves P (ox ::= tBot) 
      -> Proves P Q
| P_PairUpdate :
    forall P π x τ σ,
    Proves P ((obj (π ++ [car]) x) ::= τ)
    -> Proves P ((obj (π ++ [cdr]) x) ::= σ)
    -> Proves P ((obj π x) ::= (tCons τ σ))

(** SubType *)

with SubType : relation type :=
| S_Refl : 
    forall τ, SubType τ τ
| S_Top : 
    forall τ, SubType τ tTop
| S_Bot : 
    forall τ, SubType tBot τ
| S_UnionSuper_l :
    forall τ σ1 σ2,
      SubType τ σ1
      -> SubType τ (tU σ1 σ2)
| S_UnionSuper_r :
    forall τ σ1 σ2,
      SubType τ σ2
      -> SubType τ (tU σ1 σ2)
| S_UnionSub :
    forall τ1 τ2 σ,
      SubType τ1 σ
      -> SubType τ2 σ
      -> SubType (tU τ1 τ2) σ
| S_Abs :
    forall x y τ τ' σ σ' ψ ψ' o o',
      SubType (subst_t τ (Some (var y)) x) τ'
      -> SubType σ' (subst_t σ (Some (var y)) x) 
      -> Proves (subst_p ψ (Some (var y)) x) ψ'
      -> SubObj (subst_o o (Some (var y)) x) o'
      -> SubType (tλ x (σ, τ) ψ o)
                 (tλ y (σ', τ') ψ' o')
| S_Pair :
    forall τ1 σ1 τ2 σ2,
      SubType τ1 τ2
      -> SubType σ1 σ2
      -> SubType (tCons τ1 σ1) (tCons τ2 σ2).


(** ** TypeOf *)

Inductive TypeOf : prop -> exp -> type -> prop -> opt object -> Prop :=
| T_Nat :
    forall Γ n,
      TypeOf Γ (#n) tNat TT None
| T_Str :
    forall Γ s,
      TypeOf Γ (Str s) tStr TT None
| T_Const :
    forall τ Γ c x,
      τ = (const_type c x)
      -> TypeOf Γ (eOp (c_op c)) τ TT None
| T_True :
    forall Γ,
      TypeOf Γ #t tT TT None
| T_False :
    forall Γ,
      TypeOf Γ #f tF FF None
| T_Var :
    forall τ Γ x,
      Proves Γ ((var x) ::= τ)
      -> TypeOf Γ ($ x) τ ((var x) ::~ tF) (Some (var x))
| T_Abs :
    forall σ τ o Γ x ψ e,
      TypeOf (Γ && ((var x) ::= σ)) e τ ψ o
      -> TypeOf Γ 
                (eλ x σ e) 
                (tλ x (σ, τ) ψ o) 
                TT 
                None
| T_App :
    forall τ'' σ τ o'' o o' Γ e x fψ fo ψ e' ψ' ψf'',
      TypeOf Γ e (tλ x (σ, τ) fψ fo) ψ o
      -> TypeOf Γ e' σ ψ' o'
      -> (subst_t τ o' x) = τ''
      -> (subst_p fψ o' x) = ψf''
      -> (subst_o fo o' x) = o''
      -> TypeOf Γ (Apply e e') τ'' ψf'' o''
| T_If :
    forall τ τ' o o1 Γ e1 ψ1 e2 ψ2 e3 ψ3,
      TypeOf Γ e1 τ' ψ1 o1
      -> TypeOf (Γ && ψ1) e2 τ ψ2 o
      -> TypeOf (Γ && (Not ψ1)) e3 τ ψ3 o
      -> TypeOf Γ (If e1 e2 e3) τ (ψ2 || ψ3) o
| T_Cons :
    forall τ1 τ2 o1 o2 Γ e1 ψ1 e2 ψ2,
      TypeOf Γ e1 τ1 ψ1 o1
      -> TypeOf Γ e2 τ2 ψ2 o2
      -> TypeOf Γ (Cons e1 e2) (tCons τ1 τ2) TT None
| T_Car :
    forall τ1 τ2 o' o Γ e ψ0 ψ x,
      TypeOf Γ e (tCons τ1 τ2) ψ0 o
      -> (subst_p ((obj [car] x) ::~ tF) o x) = ψ
      -> (subst_o (Some (obj [car] x)) o x) = o'
      -> TypeOf Γ (Car e) τ1 ψ o'
| T_Cdr :
    forall τ1 τ2 o' o Γ e ψ0 ψ x,
      TypeOf Γ e (tCons τ1 τ2) ψ0 o
      -> (subst_p ((obj [cdr] x) ::~ tF) o x) = ψ
      -> (subst_o (Some (obj [cdr] x)) o x) = o'
      -> TypeOf Γ (Cdr e) τ2 ψ o'
| T_Let :
    forall σ' τ σ o1' o0 o1 Γ e0 ψ0 e1 ψ1 x ψ1',
      TypeOf Γ e0 τ ψ0 o0
      -> TypeOf (Γ && ((var x) ::= τ)
                   && (((var x) ::~ tF) --> ψ0)
                   && (((var x) ::= tF) --> (Not ψ0))) 
                e1
                σ
                ψ1
                o1
      -> (subst_t σ o0 x) = σ'
      -> (subst_p ψ1 o0 x) = ψ1'
      -> (subst_o o1 o0 x) = o1'
      -> TypeOf Γ (Let x e0 e1) σ' ψ1' o1'
| T_Subsume :
    forall τ' τ o' o Γ e ψ ψ',
      TypeOf Γ e τ ψ o
      -> Proves (Γ && ψ) ψ'
      -> SubType τ τ'
      -> SubObj o o'
      -> TypeOf Γ e τ' ψ' o'.


(** * Proof Helpers *)

(** * Proof Helpers/Lemmas and Automation *)

Lemma then_else_eq : forall (T:Type) (P1 P2:Prop) (test: sumbool P1 P2) (Q:T),
(if test then Q else Q) = Q.
Proof.
  crush.
Qed.
Hint Rewrite then_else_eq.


Lemma if_eq_id : forall (T:Type) x (t1 t2: T),
(if id_eqdec x x then t1 else t2) = t1.
Proof.
  intros T x t1 t2.
  destruct (id_eqdec x x); auto. tryfalse.
Qed.
Hint Rewrite if_eq_id.

Lemma if_eq_obj : forall (T:Type) x (t1 t2: T),
(if obj_eqdec x x then t1 else t2) = t1.
Proof.
  intros T x t1 t2.
  destruct (obj_eqdec x x); auto. tryfalse.
Qed.
Hint Rewrite if_eq_obj.

Lemma neq_id_neq : forall (T:Type) x y (P Q:T),
x <> y ->
((if (id_eqdec x y) then P else Q) = Q).
Proof.
  intros.
  destruct (id_eqdec x y); crush.
Qed.

Lemma neq_obj_neq : forall (T:Type) x y (P Q:T) pth1 pth2,
x <> y ->
((if (obj_eqdec (obj pth1 x) (obj pth2 y)) then P else Q) = Q).
Proof.
  intros.
  destruct (obj_eqdec (obj pth1 x) (obj pth2 y)); crush.
Qed.

Lemma if_eq_type : forall (T:Type) x (t1 t2: T),
(if type_eqdec x x then t1 else t2) = t1.
Proof.
  intros T x t1 t2.
  destruct (type_eqdec x x); auto. tryfalse.
Qed.
Hint Rewrite if_eq_type.

Lemma subst_Some_tNat : forall x y,
(subst_p (var x ::= tNat) (Some (var y)) x)
 = (var y ::= tNat).
Proof.
  intros x y.
  simpl. destruct (id_eqdec x x); crush.
Qed.  
Hint Rewrite subst_Some_tNat.


Fixpoint in_prop (q p : prop) : bool :=
  if prop_eqdec q p then true else
    match p with
      | And p1 p2 => orb (in_prop q p1) (in_prop q p2)
      | Or  p1 p2 => andb (in_prop q p1) (in_prop q p2)
      | _ => false
    end.

Lemma in_prop_Proves : forall p q,
in_prop q p = true
-> Proves p q.
Proof with crush.
  Hint Constructors Proves.
  Hint Rewrite orb_true_iff.
  Hint Rewrite andb_true_iff.
  intros p; induction p...
  destruct (prop_eqdec q (o ::= t))...
  destruct (prop_eqdec q (o ::~ t))...
  destruct (prop_eqdec q (p1 && p2))...
  destruct (prop_eqdec q (p1 || p2))...
  destruct (prop_eqdec q TT)...
  destruct (prop_eqdec q Unk)...
Qed.

Lemma true_tBool : 
SubType tT tBool.
Proof. 
  Hint Constructors SubType.
  crush.
Qed.

Lemma false_tBool : 
SubType tF tBool.
Proof. 
  Hint Constructors SubType.
  crush.
Qed.
Hint Resolve true_tBool false_tBool.

Ltac simple_subobject :=
  match goal with
    | |- SubObj ?o ?o => solve [eapply SO_Refl]
    | |- SubObj None ?o => solve [eapply SO_Refl]
    | |- SubObj ?o None => solve [eapply SO_Top]
  end.

Ltac simple_proves :=
  match goal with
  | |- Proves FF ?P => solve [eapply P_False]
  | |- Proves ?P TT => solve [eapply P_True]
  | |- Proves ?P ?P => solve [eapply P_Refl]
  | |- Proves ?P ?Q => solve [eapply in_prop_Proves; crush]
  end.

Ltac simple_subtype :=
  match goal with
  | |- SubType ?P tTop => solve [eapply S_Top]
  | |- SubType ?P ?P => solve [eapply P_Refl]
  | |- SubType ?t1 (tU ?t1 ?t2) =>
    solve [eapply S_UnionSuper_l; eapply S_Refl]
  | |- SubType ?t2 (tU ?t1 ?t2) =>
    solve [eapply S_UnionSuper_r ; eapply S_Refl]
  | |- SubType ?t1 (tU (tU ?t1 ?t2) ?t3) =>
    solve [eapply S_UnionSuper_l; eapply S_UnionSuper_l; eapply S_Refl]
  | |- SubType ?t2 (tU (tU ?t1 ?t2) ?t3) =>
    solve [eapply S_UnionSuper_l; eapply S_UnionSuper_r; eapply S_Refl]
  | |- SubType ?t2 (tU ?t1 (tU ?t2 ?t3)) =>
    solve [eapply S_UnionSuper_r; eapply S_UnionSuper_l; eapply S_Refl]
  | |- SubType ?t3 (tU ?t1 (tU ?t2 ?t3)) =>
    solve [eapply S_UnionSuper_r; eapply S_UnionSuper_r; eapply S_Refl]
  end.

(** *Typechecked Examples *)

(** Unhygeinic Or macro *)
Notation tmp := (Id 1729).
Notation OR := (fun p q => 
                  (Let tmp p
                       (If ($ tmp)
                           ($ tmp)
                           q))).
(** And Macro *)
Notation AND := (fun p q =>
                (If p q #f)).

Example example1:
  forall x,
    TypeOf ((var x) ::= tTop)
           (If (Nat? ($ x))
               (Add1 ($ x))
               (#0))
           tNat
           TT
           None.
Proof with crush. 
  intros x.
  eapply T_Subsume.
  crush.
  eapply T_If.
  eapply T_App.
  eapply T_Const...
  eapply T_Var...
  crush.
  crush.
  crush.
  crush.
  eapply T_App...
  eapply T_Const...
  eapply T_Var...
  crush.
  eapply T_Nat...
  crush.
  crush.
  crush.
  crush.
  simple_subobject.
Grab Existential Variables.
crush. crush.
Qed.


(*
 x = y   -- solve[reflexivity] -- possibly some rewrites?
subst_p (var ?84152 ::= tNat) (Some (var x)) ?84152
In Prop proves?

*)

Admitted.


Example example2:
  forall x,
    TypeOf TT
           (λ x (tU tStr tNat)
              (If (Nat? ($ x))
                  (Add1 ($ x))
                  (StrLen ($ x))))
           (tλ x
               ((tU tStr tNat), tNat)
               TT
               None)
           TT
           None.
Proof. Admitted.

Example example3:
  forall x y,
    x <> y ->
    TypeOf
      ((var y) ::= tTop)
      (Let x (Nat? ($ y))
          (If ($ x)
              ($ y)
              (# 0)))
      tNat
      TT
      None.
Proof. Admitted.

Example example4:
  forall x f,
    TypeOf (((var x) ::= tTop) 
              && ((var f) ::= (tλ x ((tU tStr tNat), tNat) TT None)))
           (If (OR (Nat? ($ x)) (Str? ($ x)))
               (Apply ($ f) ($ x))
               (# 0))
           tNat
           TT
           None.
Proof. Admitted.

Example example5:
  forall x y,
    TypeOf (((var x) ::= tTop) && ((var y) ::= tTop))
           (If (AND (Nat? ($ x)) (Str? ($ y)))
               (Plus ($ x) (StrLen ($ y)))
               (# 0))
           tNat
           TT
           None.
Proof. Admitted.

Example example7:
  forall x y,
    TypeOf (((var x) ::= tTop) && ((var y) ::= tTop))
           (If (If (Nat? ($ x)) (Str? ($ y)) #f)
               (Plus ($ x) (StrLen ($ y)))
               (# 0))
           tNat
           TT
           None.
Proof. Admitted.

Example example8:
  forall x,
    TypeOf TT
           (λ x tTop
              (OR (Str? ($ x)) (Nat? ($ x))))
           (tλ x
               (tTop, (tU tStr tNat))
               ((var x) ::= (tU tStr tNat))
               None)
           TT
           None.
Proof. Admitted.

Example example9:
  forall x f,
    TypeOf (((var x) ::= tTop)
              && ((var f) ::= (tλ x ((tU tStr tNat), tNat) TT None)))
           (If (Let tmp (Nat? ($ x))
                    (If ($ tmp) ($ tmp) (Str? ($ x))))
               (Apply ($ f) ($ x))
               (# 0))
           tNat
           TT
           None.
Proof. Admitted.

Example example10:
  forall p,
    TypeOf ((var p) ::= (tCons tTop tTop))
           (If (Nat? (Car ($ p)))
               (Add1 (Car ($ p)))
               (# 7))
           tNat
           TT
           None.
Proof. Admitted.

Example example11:
  forall p g x,
    TypeOf ((var p) ::= (tCons tTop tTop)
            && ((var g) ::= (tλ x ((tU tNat tNat), tNat) TT None)))
           (If (AND (Nat? (Car ($ p))) (Nat? (Cdr ($ p))))
               (Apply ($ g) ($ p))
               (# 42))
           tNat
           TT
           None.

Example example12:
  forall x y,
    TypeOf TT
           (λ x (tCons tTop tTop)
              (Nat? (Car ($ x))))
           (tλ y
               ((tCons tTop tTop), (tCons tTop tTop))
               ((var y) ::= (tCons tNat tTop))
               None)
           TT
           None.
Proof. Admitted.

Example example13:
  forall x y,
    TypeOf (((var x) ::= tTop) && ((var y) ::= (tU tNat tStr)))
           (If (AND (Nat? ($ x)) (Str? ($ y)))
               (Plus ($ x) (StrLen ($ y)))
               (If (Nat? ($ x))
                   (Plus ($ x) ($ y))
                   (# 42)))
           tNat
           TT
           None.
Proof. Admitted.

Example example14:
  forall x y,
    TypeOf (((var x) ::= tTop) && ((var y) ::= (tCons tTop (tU tNat tStr))))
           (If (AND (Nat? ($ x)) (Str? (Cdr ($ y))))
               (Plus ($ x) (StrLen ($ y)))
               (If (Nat? ($ x))
                   (Plus ($ x) (Cdr ($ y)))
                   (# 42)))
           tNat
           TT
           None.
Proof. Admitted.

Abort All.
End LTR.

        