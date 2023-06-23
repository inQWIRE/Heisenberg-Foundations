Require Import Psatz.
Require Import Reals.

Require Export QuantumLib.Complex.
Require Export QuantumLib.Matrix.
Require Export QuantumLib.Quantum.
Require Export QuantumLib.Eigenvectors.
                                          
Require Import Setoid.
Require Import Permutation.

Require Export new_Helper.

Declare Scope Predicate_scope.
Delimit Scope Predicate_scope with P.
Open Scope Predicate_scope.



(************************)
(* Helper Lemmas *)
(************************)

Lemma Copp_opp : forall (a b : C), -a = b <-> a = -b. Proof. split; intros; [rewrite <- H | rewrite H]; lca. Qed. 

Lemma Cplus_opp_r : forall c : C, c + - c = 0. Proof. intros; lca. Qed.

Lemma Cplus_inj_r : forall (c c1 c2 : C),
    c1 = c2 -> c1 + c = c2 + c.
Proof. intros. rewrite H. reflexivity. Qed.

Lemma Cplus_inj_l : forall (c c1 c2 : C),
    c1 = c2 -> c + c1 = c + c2.
Proof. intros. rewrite H. reflexivity. Qed.

Lemma Cplus_inv_r : forall (c c1 c2 : C),
    c1 + c = c2 + c -> c1 = c2.
Proof. intros. apply Cplus_inj_r with (c:=-c) in H.
  rewrite <- ! Cplus_assoc in H.
  rewrite ! Cplus_opp_r in H.
  rewrite ! Cplus_0_r in H.
  assumption.
Qed.

Lemma Cplus_inv_l : forall (c c1 c2 : C),
    c + c1= c + c2 -> c1 = c2.
Proof. intros. apply Cplus_inj_l with (c:=-c) in H.
  rewrite ! Cplus_assoc in H.
  rewrite ! Cplus_opp_l in H.
  rewrite ! Cplus_0_l in H.
  assumption.
Qed.

Lemma Cplus_zero_iff_equals_minus : forall (c1 c2 : C),
    c1 + c2 = 0 <-> c1 = -c2.
Proof. split.
  - intro. apply Cplus_inj_r with (c := -c2) in H.
    rewrite <- ! Cplus_assoc in H.
    rewrite Cplus_opp_r in H.
    rewrite Cplus_0_l, Cplus_0_r in H.
    assumption.
  - intro. rewrite H. rewrite Cplus_opp_l. reflexivity.
Qed.

Lemma adjoint_inj : forall {j k : nat} (A B : Matrix j k),
    A = B -> A † = B †.
Proof. intros. rewrite H. reflexivity. Qed.

Lemma Mmult_inj_l : forall {i j k : nat} (m : Matrix i j) (m1 m2 : Matrix j k),
    m1 = m2 -> m × m1 = m × m2.
Proof. intros. rewrite H. reflexivity. Qed.

Lemma Mmult_inj_r : forall {i j k : nat} (m : Matrix j k) (m1 m2 : Matrix i j) ,
    m1 = m2 -> m1 × m = m2 × m.
Proof. intros. rewrite H. reflexivity. Qed.

Lemma Mplus_inj_r : forall {j k : nat} (m m1 m2 : Matrix j k),
    m1 = m2 -> m1 .+ m = m2 .+ m.
Proof. intros. rewrite H. reflexivity. Qed.

Lemma Mplus_opp_r : forall {j k : nat} (m : Matrix j k),
    WF_Matrix m -> m .+ - C1 .* m = Zero.
Proof. intros. lma'. Qed.

Lemma Mplus_opp_l : forall {j k : nat} (m : Matrix j k),
    WF_Matrix m -> - C1 .* m .+ m = Zero.
Proof. intros. lma'. Qed.

Lemma Mplus_inv_r : forall {j k : nat} (m m1 m2 : Matrix j k),
    WF_Matrix m -> m1 .+ m = m2 .+ m -> m1 = m2.
Proof. intros. apply Mplus_inj_r with (m := -C1.*m) in H0.
  rewrite ! Mplus_assoc in H0.
  rewrite ! Mplus_opp_r in H0; auto.
  rewrite ! Mplus_0_r in H0.
  assumption.
Qed. 

Lemma Mplus_zero_iff_equals_minus : forall {j k : nat} (m1 m2 : Matrix j k),
    WF_Matrix m2 -> (m1 .+ m2 = Zero <-> m1 = -C1 .* m2).
Proof. intros. split.
  - intro. apply Mplus_inj_r with (m := -C1 .* m2) in H0.
    rewrite Mplus_assoc in H0.
    rewrite Mplus_opp_r in H0; auto.
    rewrite Mplus_0_l, Mplus_0_r in H0.
    assumption.
  - intro. rewrite H0. lma'.
Qed.


Lemma trace_kron_dist : forall n m (A : Square n) (B : Square m),
    m <> 0%nat -> trace (A ⊗ B) = ((trace A) * (trace B))%G.
Proof.
  intros.
  unfold trace, kron.
  rewrite big_sum_product; auto.
Qed.


Lemma In_list_WF_Matrix_implies_WF_big_kron : forall {m n} (A : list (Matrix m n)),
    (forall a, In a A -> WF_Matrix a) -> WF_Matrix (⨂ A).
Proof. intros. induction A.
  - auto with wf_db.
  - simpl.
    apply WF_kron; auto.
    specialize (H a). assert (In a (a :: A)). { simpl. left. reflexivity. }
    apply H in H0. assumption.
    apply IHA. intros.
    specialize (H a0). assert (In a0 (a :: A)). {simpl. right. assumption. }
    apply H in H1. assumption.
Qed.

Lemma big_kron_split : forall {m n} (A B : list (Matrix m n)),
    (forall a, In a A -> WF_Matrix a) -> (forall b, In b B -> WF_Matrix b) -> 
    (⨂ (A ++ B)) = (⨂ A) ⊗ (⨂ B).
Proof. intros. induction A.
  - simpl. rewrite kron_1_l. easy.
    induction B.
    + simpl. auto with wf_db.
    + simpl. apply WF_kron; try easy.
      specialize (H0 a). assert (In a (a :: B)). { simpl. left. reflexivity. }
      apply H0 in H1. assumption.
      apply IHB. intros.
      specialize (H0 b). assert (In b (a :: B)). { simpl. right. assumption. }
      apply H0 in H2. assumption.
  - simpl. rewrite IHA. rewrite kron_assoc.
    rewrite ! app_length.
    assert ((Init.Nat.mul (Nat.pow m (@length (Matrix m n) A))
               (Nat.pow m (@length (Matrix m n) B))) =
              (Nat.pow m (Init.Nat.add (@length (Matrix m n) A) (@length (Matrix m n) B)))).
    { rewrite Nat.pow_add_r. reflexivity. }
    assert ((Init.Nat.mul (Nat.pow n (@length (Matrix m n) A))
               (Nat.pow n (@length (Matrix m n) B))) =
              (Nat.pow n (Init.Nat.add (@length (Matrix m n) A) (@length (Matrix m n) B)))).
    { rewrite Nat.pow_add_r. reflexivity. }
    rewrite ! H1, ! H2.
    reflexivity.
    specialize (H a). assert (In a (a :: A)). { simpl. left. reflexivity. }
    apply H in H1. assumption.
    assert  (forall a, In a A -> WF_Matrix a).
    { intros. specialize (H a0). assert (In a0 (a :: A)).
      { simpl. right. assumption. }
      apply H in H2. assumption. }
    apply In_list_WF_Matrix_implies_WF_big_kron in H1.
    assumption.
    apply In_list_WF_Matrix_implies_WF_big_kron in H0.
    assumption.
    intros. specialize (H a0). assert (In a0 (a :: A)).
    { simpl. right. assumption. }
    apply H in H2. assumption.
Qed.


(************************)
(* Defining coeficients *)
(************************)


Definition Coef := C.

Definition cBigMul (cs : list Coef) : Coef :=
  fold_left Cmult cs C1.

Lemma cBigMul_app : forall (l1 l2 : list Coef),
  (cBigMul l1) * (cBigMul l2) = cBigMul (l1 ++ l2).
Proof. induction l1 as [| h]; try easy.
  intros. simpl.
  - unfold cBigMul. simpl. lca.
  - intros l2. simpl. unfold cBigMul. simpl.
    rewrite 2 fold_left_Cmult. rewrite <- Cmult_assoc.
    unfold cBigMul in IHl1.
    rewrite  IHl1; easy.
Qed.


(**********************)
(* Defining the types *)
(**********************)

(* this is the lowest level, only Pauli gates are defined *)
Inductive Pauli :=
| gI
| gX
| gY
| gZ.


Definition beq_Pauli (a b : Pauli) : bool :=
  match a, b with
  | gI, gI => true
  | gZ, gI => false
  | gY, gI => false
  | gX, gI => false
  | gI, gZ => false
  | gZ, gZ => true
  | gY, gZ => false
  | gX, gZ => false
  | gI, gY => false
  | gZ, gY => false
  | gY, gY => true
  | gX, gY => false
  | gI, gX => false
  | gZ, gX => false
  | gY, gX => false
  | gX, gX => true
  end.


Definition translate_P (g : Pauli) : Square 2 :=
  match g with
  | gI => I 2
  | gX => σx
  | gY => σy
  | gZ => σz
  end.

Lemma WF_Matrix_Pauli : forall (g : Pauli), WF_Matrix (translate_P g).
Proof. intros. 
  destruct g; simpl; auto with wf_db.
Qed.

Lemma In_list_WF_Matrix_Pauli : forall (A : list Pauli),
  forall a : Square 2, In a (map translate_P A) -> WF_Matrix a.
Proof. induction A; intros.
  - simpl in H. exfalso. assumption.
  - simpl in H. destruct H.
    + rewrite <- H. apply WF_Matrix_Pauli.
    + apply IHA. assumption.
Qed.

Lemma WF_Matrix_nth_Pauli : forall (l : list Pauli),
  forall i : nat, WF_Matrix (nth i (map translate_P l) Zero).
Proof. intros. destruct (nth_in_or_default i (map translate_P l) Zero).
  - apply In_list_WF_Matrix_Pauli with (A := l). assumption.
  - rewrite e. auto with wf_db.
Qed.

Lemma WF_Unitary_Pauli : forall (g : Pauli), WF_Unitary (translate_P g).
Proof. intros.
       destruct g; simpl; auto with unit_db.
Qed.

Lemma WF_Matrix_Big_Pauli : forall (l : list Pauli), WF_Matrix (⨂ map translate_P l).
Proof. intros.
  induction l; simpl; auto with wf_db.
  apply Matrix.WF_kron; try lia; try apply IHl.
  apply WF_Matrix_Pauli.
Qed.

#[export] Hint Resolve WF_Matrix_Pauli WF_Matrix_Big_Pauli : wf_db.
#[export] Hint Resolve WF_Unitary_Pauli : unit_db.


(* Here we define a gMul to give Coef followed by a gMul to give the actual type *)
(* this allows for an easy zip in gMulT *)

Definition gMul_Coef (g1 g2 : Pauli) : Coef :=
  match g1, g2 with
  | gI, _ => C1
  | _, gI => C1
  | gX, gX => C1
  | gY, gY => C1
  | gZ, gZ => C1
  | gX, gY => Ci
  | gY, gX => (- Ci)%C
  | gX, gZ => (-Ci)%C
  | gZ, gX => Ci
  | gY, gZ => Ci
  | gZ, gY => (-Ci)%C
  end.



Definition gMul_base (g1 g2 : Pauli) : Pauli :=
  match g1, g2 with
  | gI, _ => g2
  | _, gI => g1
  | gX, gX => gI
  | gY, gY => gI
  | gZ, gZ => gI
  | gX, gY => gZ
  | gY, gX => gZ
  | gX, gZ => gY
  | gZ, gX => gY
  | gY, gZ => gX
  | gZ, gY => gX
  end.




(* scaling, multiplication, and tensoring done at this level *)
Definition TType (len : nat) := (Coef * (list Pauli))%type.


(* we define an error TType for when things go wrong *)
Definition ErrT : TType 0 := (C1, []).


Definition gMulT {n} (A B : TType n) : TType n :=
  match A with
  | (c1, g1) =>
    match B with
    | (c2, g2) =>(c1 * c2 * (cBigMul (zipWith gMul_Coef g1 g2)), 
                       zipWith gMul_base g1 g2)
    end
  end.

Definition gTensorT {n m} (A : TType n) (B : TType m) : TType (n + m) :=
  match A with
  | (c1, g1) =>
    match B with
    | (c2, g2) => (c1 * c2, g1 ++ g2)
    end
  end.

Definition gScaleT {n} (c : Coef) (A : TType n) : TType n :=
  match A with
  | (c1, g1) => (c * c1, g1)
  end.

Definition translate {n} (A : TType n) : Square (2 ^ n)%nat := 
  (fst A) .* ⨂ (map translate_P (snd A)).


Lemma gScaleT_comm : forall {n} (c1 c2 : Coef) (t : TType n),
    gScaleT c1 (gScaleT c2 t) = gScaleT c2 (gScaleT c1 t).
Proof. intros n c1 c2 t.
  unfold gScaleT. destruct t. f_equal. lca.
Qed.

  
(** Not Useful??
(*** incomplete definition ***)
(* Restrictive additive type of  1/sqrt2 (a + b) form *)
Inductive AddType (n : nat) : Type :=
| OneOverSqrt2 (t1 t2 : TType n) : (* Anticommutative t1 t2 -> *) AddType n 
| LeftOneOverSqrt2 : TType n -> AddType n -> AddType n
| RightOneOverSqrt2 : AddType n -> TType n -> AddType n
| BothOneOverSqrt2 : AddType n -> AddType n -> AddType n.

Arguments OneOverSqrt2 {n}.
Arguments LeftOneOverSqrt2 {n}.
Arguments RightOneOverSqrt2 {n}.
Arguments BothOneOverSqrt2 {n}.

Fixpoint UnfoldSqrt2OnAddType_C {n} (A : AddType n) (c : C) {struct A} :=
  match A with
  | OneOverSqrt2 L R (*A'*) =>  OneOverSqrt2
                           (gScaleT c L)
                           (gScaleT c R)
                           (*A'*)
  | LeftOneOverSqrt2 L A' =>  LeftOneOverSqrt2
                               (gScaleT c L)
                               (UnfoldSqrt2OnAddType_C A' (c*c))
  | RightOneOverSqrt2 A' R => RightOneOverSqrt2
                                (UnfoldSqrt2OnAddType_C A' (c*c))
                                (gScaleT (RtoC (sqrt 2)) R)
  | BothOneOverSqrt2 A' B' => BothOneOverSqrt2
                                (UnfoldSqrt2OnAddType_C A' (c*c))
                                (UnfoldSqrt2OnAddType_C B' (c*c))
  end.

Definition UnfoldSqrt2OnAddType {n} (A : AddType n) := (UnfoldSqrt2OnAddType_C A (1/√2)).

Fixpoint UnfoldAddTypeToList {n} (A : AddType n) :=
  match A with
  | OneOverSqrt2 L R =>  [L; R]
  | LeftOneOverSqrt2 L A' =>  [L] ++ (UnfoldAddTypeToList A')
  | RightOneOverSqrt2 A' R => (UnfoldAddTypeToList A') ++ [R]
  | BothOneOverSqrt2 A' B' => (UnfoldAddTypeToList A') ++ (UnfoldAddTypeToList B') 
  end. 

Definition translate_Add_to_A {n} (A : AddType n) :=
  UnfoldAddTypeToList (UnfoldSqrt2OnAddType A).

Inductive WF_AddType (n : nat) (A : AddType n) : Prop := 
| 


(** this is here for reference 
Definition WF_TType (n : nat) (a : TType n) : Prop := n <> O /\ length (snd a) = n.
(*
Inductive WF_TType (n : nat) (a : TType n) : Prop :=
(* | WF_TT_nil : forall (c : Coef), WF_TType_nil n (c, []) *)
| WF_TT : n <> O /\ length (snd a) = n -> WF_TType n a.
*) **)
*)


  



(* Additive Type: list elements are added to each other *)
(* len is the number of qubits (= number of tensoring elements) *)
Definition AType (len : nat) := list (TType len).

(* we define an error AType for when things go wrong *)
Definition ErrA : AType 0 := [].


Fixpoint gTensorA  {n m : nat} (a : AType n) (b : AType m) {struct a}: AType (n+m) :=
  match a with
  | [] => []
  | h :: t => map (fun x : TType m => gTensorT h x) b ++ gTensorA t b
  end.

Fixpoint gTensorA'  {n m : nat} (a : AType n) (b : AType m) {struct b}: AType (n+m) :=
  match b with
  | [] => []
  | h :: t => map (fun x : TType n => gTensorT x h) a ++ gTensorA' a t
  end.

Fixpoint gMulA {n : nat} (a b : AType n) {struct a} : AType n :=
  match a with
  | [] => []
  | h :: t => map (fun x : TType n => gMulT h x) b ++ gMulA t b
  end.

Fixpoint gMulA' {n : nat} (a b : AType n) {struct b} : AType n :=
  match b with
  | [] => []
  | h :: t => map (fun x : TType n => gMulT x h) a ++ gMulA' a t
  end.

Definition gScaleA {n : nat} (c : Coef) (a : AType n) :=
  map (fun a' => gScaleT c a') a .

Definition gAddA {n : nat} (a b : AType n) : AType n :=  a ++ b.

Definition translateA {n} (a : AType n) : Square (2 ^ n) :=
  fold_left Mplus (map translate a) Zero.


Lemma translateA_app : forall {n} (a1 a2 : AType n),
translateA (a1 ++ a2) = (translateA a1) .+ (translateA a2).
Proof. intros. unfold translateA. rewrite map_app.
  rewrite fold_left_Mplus_app_Zero. reflexivity.
Qed.

Lemma gScaleA_dist_app : forall {n} (c : Coef) (a1 a2 : AType n),
    gScaleA c (a1 ++ a2) = (gScaleA c a1) ++ (gScaleA c a2).
Proof. intros n c a1 a2.
  unfold gScaleA. apply map_app.
Qed.

Lemma gScaleA_comm : forall {n} (c1 c2 : Coef) (a : AType n),
    gScaleA c1 (gScaleA c2 a) = gScaleA c2 (gScaleA c1 a).
Proof. intros n c1 c2 a.
  unfold gScaleA. rewrite ! map_map.
  f_equal. apply functional_extensionality.
  intros. rewrite gScaleT_comm.
  reflexivity.
Qed.


Inductive Predicate (n : nat) : Type :=
| G : AType n -> Predicate n
| Cap : Predicate n -> Predicate n -> Predicate n
| Cup : Predicate n -> Predicate n -> Predicate n
| Err : Predicate n.

Arguments G {n}.
Arguments Cap {n}.
Arguments Cup {n}.
Arguments Err {n}.

Definition translateP {n} (A : Predicate n) :=
  match A with
  | G a => translateA a
  | Cap a b => Zero
  | Cup a b => Zero
  | Err => Zero
  end.

(* you cannot multiply cap or cup types 
   so any of these options returns Err *)
Definition mul {n} (A B : Predicate n) : Predicate n :=
  match A with
  | G a =>
    match B with
    | G b => G (gMulA a b)
    | _ => Err
    end
  | _ => Err
  end.

Definition add {n} (A B : Predicate n) : Predicate n :=
  match A with
  | G a =>
    match B with
    | G b => G (gAddA a b)
    | _ => Err
    end
  | _ => Err
  end.

Definition tensor {n m} (A : Predicate n) (B : Predicate m): Predicate (n + m) :=
  match A with
  | G a =>
      match B with
      | G b => G (gTensorA a b)
      | _ => Err
      end
  | _ => Err
  end.

Definition scale {n} (c : Coef) (A : Predicate n) : Predicate n :=
  match A with
  | G a => G (gScaleA c a)
  | _ => Err
  end.

Lemma gMulA_nil_r : forall n (a : AType n), gMulA a [] = [].
Proof. intros n a. induction a; try easy. Qed.

Lemma gMulA'_nil_l : forall n (a : AType n), gMulA [] a = [].
Proof. intros n a. induction a; try easy. Qed.

Lemma gScaleT_1 : forall n (A : TType n), gScaleT C1 A = A.
Proof. intros n A. destruct A. simpl. rewrite Cmult_1_l. reflexivity. Qed.

Lemma gScaleA_1 : forall n (A : AType n), gScaleA C1 A = A.
Proof. intros n A. induction A; simpl; try easy. rewrite gScaleT_1. rewrite IHA. reflexivity. Qed.
                                                
#[export] Hint Rewrite gMulA_nil_r gMulA'_nil_l gScaleT_1 gScaleA_1 : typing_db.


Definition i {n} (A : Predicate n) := scale Ci A.
Notation "- A" := (scale (Copp C1) A)  (at level 35, right associativity) : Predicate_scope.

Infix "⊗'" := tensor (at level 39, left associativity) : Predicate_scope.
Infix "*'" := mul (at level 40, left associativity) : Predicate_scope.
Infix "·'" := scale (at level 43, left associativity) : Predicate_scope.
Infix "+'" := add (at level 50, left associativity) : Predicate_scope.

Notation "A ∩ B" := (Cap A B) (at level 60, no associativity) : Predicate_scope.
Notation "A ⊍ B" := (Cup A B) (at level 60, no associativity) : Predicate_scope.


(******************************************************************************)
(* Defining different types of Predicates to ensure WF(Well-formedness) and translations *)
(******************************************************************************)

Inductive TPredicate {n} : Predicate n -> Prop :=
| G_tp : forall t : TType n, TPredicate (G [t]).


Definition proper_length_TType_nil (n : nat) (t : TType n) : Prop := length (snd t) = n.
Definition proper_length_TType (n : nat) (t : TType n) : Prop := n <> O /\ length (snd t) = n.

Lemma proper_length_TType_implies_proper_length_TType_nil : forall {n} (t : TType n),
   proper_length_TType n t -> proper_length_TType_nil n t.
Proof.  intros. destruct H. auto. Qed.

Lemma proper_length_TType_gScaleT : forall {n : nat} (c : Coef) (t : TType n),
  proper_length_TType n t -> proper_length_TType n (gScaleT c t).
Proof. intros n c t H. destruct t. unfold proper_length_TType in *. simpl in *. assumption.
Qed.


Inductive proper_length_TPredicate {n} : Predicate n -> Prop :=
| pl_tp : forall t : TType n, proper_length_TType n t -> proper_length_TPredicate (G [t]).

Lemma proper_length_TPredicate_implies_TPredicate : forall {n} (T : Predicate n),
    proper_length_TPredicate T -> TPredicate T.
Proof. intros n T H. inversion H. constructor. Qed.


Inductive APredicate {n} : Predicate n -> Prop :=
| G_ap : forall a : AType n, APredicate (G a).

Inductive proper_length_AType_nil (n : nat) : AType n -> Prop :=
| proper_length_A_nil_Base : proper_length_AType_nil n nil
| proper_length_A_nil_Cons (t : TType n) (a : AType n) : proper_length_TType n t -> proper_length_AType_nil n a -> proper_length_AType_nil n (t :: a).


Inductive proper_length_AType (n : nat) : AType n -> Prop :=
| proper_length_A_Sing (t : TType n) : proper_length_TType n t -> proper_length_AType n (cons t nil)
| proper_length_A_Cons (t : TType n) (a : AType n) : proper_length_TType n t -> proper_length_AType n a -> proper_length_AType n (t :: a).


Lemma proper_length_AType_implies_proper_length_AType_nil : forall {n} (a : AType n),
   proper_length_AType n a -> proper_length_AType_nil n a.
Proof.
  intros. induction H; constructor; try easy; constructor.
Qed.


Lemma proper_length_AType_gScaleA : forall {n : nat} (c : Coef) (a : AType n),
    proper_length_AType n a -> proper_length_AType n (gScaleA c a).
Proof. intros n c a H. induction H.
  - constructor. apply proper_length_TType_gScaleT. assumption.
  - simpl in *. constructor.
    + apply proper_length_TType_gScaleT. assumption.
    + assumption.
Qed.

Lemma proper_length_AType_App : forall {n : nat} (a1 a2 : AType n),
    proper_length_AType n a1 -> proper_length_AType n a2 ->
    proper_length_AType n (a1 ++ a2).
Proof. intros n a1 a2 H H0.
  induction H; simpl; constructor; assumption.
Qed.

Inductive proper_length_APredicate {n} : Predicate n -> Prop :=
| pl_ap : forall a : AType n, proper_length_AType n a -> proper_length_APredicate (G a).

Lemma proper_length_APredicate_implies_APredicate : forall {n} (A : Predicate n),
    proper_length_APredicate A -> APredicate A.
Proof. intros n A H. inversion H. constructor. Qed.

Lemma  proper_length_TPredicate_implies_proper_length_APredicate :
  forall {n} (T : Predicate n),
    proper_length_TPredicate T -> proper_length_APredicate T.
Proof. intros n T H. inversion H. do 2 constructor. auto. Qed. 

Inductive CPredicate {n} : Predicate n -> Prop :=
| Cap_p : forall A B : Predicate n, CPredicate (Cap A B)
| Cup_p : forall A B : Predicate n, CPredicate (Cup A B).

Lemma TPredicate_implies_APredicate : forall {n} (T : Predicate n),
    TPredicate T -> APredicate T.
Proof. intros. inversion H; apply G_ap. Qed.


Lemma TPredicate_simplify : forall {n} (A : Predicate n),
  TPredicate A -> (exists t, A = G [t]).
Proof. intros. destruct A; try easy.
       inversion H; subst.
       exists t. reflexivity. 
Qed.

Lemma APredicate_simplify : forall {n} (A : Predicate n),
  APredicate A -> (exists a, A = G a).
Proof. intros. destruct A; try easy.
       exists a. reflexivity. 
Qed.



#[export] Hint Resolve TPredicate_implies_APredicate TPredicate_simplify APredicate_simplify : wfpt_db.



Definition pI : Predicate 1 := G [ (C1, [gI]) ].
Definition pX : Predicate 1 := G [ (C1, [gX]) ].
Definition pY : Predicate 1 := G [ (C1, [gY]) ].
Definition pZ : Predicate 1 := G [ (C1, [gZ]) ].

Lemma Y_is_iXZ : pY = (i (pX *' pZ)).
Proof. simpl.
  unfold gMulA; simpl. unfold pY. compute.
  autorewrite with R_db.
  assert (R0 = (-R0)%R). { lra. }
  rewrite <- H.
  constructor.
Qed.

#[export] Hint Resolve Y_is_iXZ : wfpt_db.

(***************)
(* TPredicate Lemmas *)
(***************)
Lemma TI : TPredicate pI. Proof. easy. Qed.
Lemma TX : TPredicate pX. Proof. easy. Qed.
Lemma TZ : TPredicate pZ. Proof. easy. Qed.

Lemma T_scale : forall {n} (A : Predicate n) (c : Coef), TPredicate A -> (TPredicate (scale c A)).  
Proof. intros. inversion H. simpl. easy. Qed. 

Lemma T_neg : forall {n} (A : Predicate n), TPredicate A -> TPredicate (- A).
Proof. intros. inversion H. simpl. easy. Qed. 
 
Lemma T_i : forall {n} (A : Predicate n), TPredicate A -> TPredicate (i A).
Proof. intros. inversion H. simpl. easy. Qed. 

Lemma T_mul : forall {n} (A B : Predicate n), TPredicate A -> TPredicate B -> TPredicate (A *' B).
Proof. intros. inversion H. inversion H0. simpl. easy. Qed.

Lemma T_tensor : forall {n m} (A : Predicate n) (B : Predicate m), TPredicate A -> TPredicate B -> TPredicate (A ⊗' B).
Proof. intros. inversion H. inversion H0. simpl. constructor. Qed.

Lemma TY : TPredicate pY.
Proof. easy. Qed.

#[export] Hint Resolve TI TX TZ TY T_scale T_neg T_i T_mul T_tensor : wfpt_db.




(***************)
(* APredicate Lemmas *)
(***************)

Lemma AI : APredicate pI. Proof. easy. Qed.
Lemma AX : APredicate pX. Proof. easy. Qed.
Lemma AZ : APredicate pZ. Proof. easy. Qed.

Lemma A_scale : forall {n} (A : Predicate n) (c : Coef), APredicate A -> (APredicate (scale c A)).  
Proof. intros. destruct A; easy. Qed.
Locate "-".

Lemma A_neg : forall {n} (A : Predicate n), APredicate A -> APredicate (- A).
Proof. intros. destruct A; easy. Qed. 
 
Lemma A_i : forall {n} (A : Predicate n), APredicate A -> APredicate (i A).
Proof. intros. destruct A; easy. Qed. 

Lemma A_mul : forall {n} (A B : Predicate n), APredicate A -> APredicate B -> APredicate (A *' B).
Proof. intros.
       destruct A; destruct B; easy.
Qed.

Lemma A_tensor : forall {n m} (A : Predicate n) (B : Predicate m), APredicate A -> APredicate B -> APredicate (A ⊗' B).
Proof. intros.
       destruct A; destruct B; easy.
Qed.

Lemma AY : APredicate pY.
Proof. easy. Qed.

#[export] Hint Resolve AI AX AZ AY A_scale A_neg A_i A_mul A_tensor : wfpt_db.



(**************************)
(* Well Formedness Lemmas *)
(**************************)

(** can be commented out: anticommute_TType defined below
Definition Anticommutative_direct {n} (t1 t2 : TType n) : Prop :=
  cBigMul (zipWith gMul_Coef (snd t1) (snd t2)) = Copp (cBigMul (zipWith gMul_Coef (snd t2) (snd t1))).
**)
(* inductive version
Inductive Anticommutative_direct {n} : TType n -> TType n -> Prop :=
| AC : forall t1 t2 : TType n, cBigMul (zipWith gMul_Coef (snd t1) (snd t2)) = Copp (cBigMul (zipWith gMul_Coef (snd t2) (snd t1))) -> Anticommutative_direct t1 t2.
*)


(** Can define directly on Pauli strings, and cons on the list of Paulis **)
(*
Inductive Commutative_test : forall n, TType n -> TType n -> Prop :=
| comm_base_test : Commutative_test 1 (C1,[gX]) (C1,[gI])
| comm_tensor_test : forall m n (A B : TType m) (C D : TType n),
    Commutative_test m A B ->
    Commutative_test n C D ->
    Commutative_test (m+n) (gTensorT A C) (gTensorT B D)
                         
with 

Anticommutative_test : forall n, TType n -> TType n -> Prop :=
| anticomm_base_test : Anticommutative_test 1 (C1,[gX]) (C1,[gY])
| anticomm_tensor_test : forall m n (A B : TType m) (C D : TType n),
    Anticommutative_test m A B ->
    Commutative_test n C D ->
    Anticommutative_test (m+n) (gTensorT A C) (gTensorT B D).
*)

(** can be commented out
Inductive Commutative : list Pauli -> list Pauli -> Prop :=
| comm_base_I_L : forall (P:Pauli), Commutative [gI] [P]
| comm_base_I_R : forall (P:Pauli), Commutative [P] [gI]
| comm_base_same : forall (P:Pauli), Commutative [P] [P]
| comm_tensor_comm : forall (a b : Pauli) (A B : list Pauli),
    Commutative [a] [b] ->
    Commutative A B ->
    Commutative (a::A) (b::B)
| comm_tensor_anticomm : forall (a b : Pauli) (A B : list Pauli),
    Anticommutative [a] [b] ->
    Anticommutative A B ->
    Commutative (a::A) (b::B)

with 

Anticommutative : list Pauli -> list Pauli -> Prop :=
| anticomm_base_XY : Anticommutative [gX] [gY]
| anticomm_base_YX : Anticommutative [gY] [gX]
| anticomm_base_XZ : Anticommutative [gX] [gZ]
| anticomm_base_ZX : Anticommutative [gZ] [gX]
| anticomm_base_YZ : Anticommutative [gY] [gZ]
| anticomm_base_ZY : Anticommutative [gZ] [gY]
| anticomm_tensor_anticomm_comm : forall (a b : Pauli) (A B : list Pauli),
    Anticommutative [a] [b] ->
    Commutative A B ->
    Anticommutative (a::A) (b::B)
| anticomm_tensor_comm_anticomm : forall (a b : Pauli) (A B : list Pauli),
    Commutative [a] [b] ->
    Anticommutative A B ->
    Anticommutative (a::A) (b::B).
**)


(* old version : now proper_length_TType
Definition WF_TType (n : nat) (t : TType n) : Prop := n <> O /\ length (snd t) = n.
 *)
(* inductive version of the old version
Inductive WF_TType (n : nat) (t : TType n) : Prop :=
(* | WF_TT_nil : forall (c : Coef), WF_TType_nil n (c, []) *)
| WF_TT : n <> O /\ length (snd t) = n -> WF_TType n t.
 *)

Lemma translate_gScaleT : forall {n} (c : Coef) (t : TType n),
    proper_length_TType n t -> translate (gScaleT c t) = c .* translate t.
Proof. intros.  destruct H. destruct t. unfold gScaleT. unfold translate. simpl in *.
  rewrite map_length. rewrite H0. rewrite Mscale_assoc. reflexivity.
Qed.

Lemma WF_Matrix_translate_nil : forall {n : nat} (t : TType n), proper_length_TType_nil n t -> WF_Matrix (translate t).
Proof. intros. destruct t. unfold translate. destruct H. simpl in *.
  rewrite map_length. apply WF_scale. 
  rewrite <- map_length with (f := translate_P).
  apply WF_big_kron with (A := I 2).
  intros.
  rewrite map_nth with (f := translate_P) (d := gI).
  auto with wf_db.
Qed.

Lemma WF_Matrix_translate : forall {n : nat} (t : TType n), proper_length_TType n t -> WF_Matrix (translate t).
Proof. intros. apply proper_length_TType_implies_proper_length_TType_nil in H.
  apply WF_Matrix_translate_nil.
  assumption.
Qed.

#[export] Hint Resolve WF_Matrix_translate_nil WF_Matrix_translate : wf_db.


(** define this directly on the list of Paulis **)
(*
Inductive trace_zero_TType : forall n, TType n -> Prop :=
| trace_zero_X : forall c, trace_zero_TType 1 (c, [gX])
| trace_zero_Y : forall c, trace_zero_TType 1 (c, [gY])
| trace_zero_Z : forall c, trace_zero_TType 1 (c, [gZ])
| trace_zero_L : forall (n m : nat) (A : TType n) (B : TType m), trace_zero_TType n A -> trace_zero_TType (n+m) (gTensorT A B)
| trace_zero_R : forall (n m : nat) (A : TType n) (B : TType m), trace_zero_TType m B -> trace_zero_TType (n+m) (gTensorT A B).
*)

Inductive trace_zero_syntax : list Pauli -> Prop :=
| trace_zero_syntax_X : trace_zero_syntax [gX]
| trace_zero_syntax_Y : trace_zero_syntax [gY]
| trace_zero_syntax_Z : trace_zero_syntax [gZ]
| trace_zero_syntax_L : forall (A B : list Pauli), trace_zero_syntax A -> trace_zero_syntax (A++B)
| trace_zero_syntax_R : forall (A B : list Pauli), trace_zero_syntax B -> trace_zero_syntax (A++B).

Lemma trace_zero_syntax_implies_trace_zero : forall (A : list Pauli),
    trace_zero_syntax A -> trace (⨂ map translate_P A) = 0.
Proof. intros. induction H.
  1-3 : pauli_matrix_computation.
  1-2 : rewrite map_app; rewrite big_kron_app; try apply WF_Matrix_nth_Pauli;
  rewrite ! app_length;
  rewrite ! map_length;
  assert (H0 : (2 ^ (length A + length B))%nat = (2 ^ (length A) * 2 ^ (length B))%nat).
  1,3: rewrite Nat.pow_add_r; reflexivity.
  1-2: rewrite H0;
  rewrite trace_kron_dist;
  rewrite map_length in IHtrace_zero_syntax;
  try rewrite IHtrace_zero_syntax;
  try rewrite Cmult_0_l; try rewrite Cmult_0_r;
  try reflexivity.
  1-2: intro; rewrite Nat.pow_eq_0_iff in H1; destruct H1; lia.
Qed.

  
Inductive WF_TType (n : nat) (t : TType n) : Prop :=
  (* | WF_TT_nil : forall (c : Coef), WF_TType_nil n (c, []) *)
  | WF_TT : proper_length_TType n t -> (fst t = C1 \/ fst t = Copp C1) -> trace_zero_syntax (snd t) -> WF_TType n t.
(** Coef = 1, -1, somewhere Pauli of trace zero
X, Y, Z, WF A -> A⊗B, WF A -> B⊗A
 **)

Lemma WF_ErrT : ~ WF_TType 0 ErrT.
Proof. intros H.
       inversion H. simpl in *. destruct H0. contradiction.
Qed.
Lemma WF_ErrT_n : forall n : nat, ~ WF_TType n ErrT.
Proof. intros n H. inversion H. destruct H0. unfold ErrT in *.
  simpl in *. rewrite <- H3 in H0. contradiction.
Qed.




(* old definition: not needed
Inductive restricted_addition {n : nat}: AType n -> Prop :=
| add_restrict_base : forall (t1 t2 : TType n), WF_TType n t1 -> WF_TType n t2 -> (fst t1 = RtoC (√2) \/ fst t1 = Copp (RtoC (√2))) ->
                      (fst t2 = RtoC (√2) \/ fst t2 = Copp (RtoC (√2))) -> restricted_addition [t1; t2].
*)
(*
has the form of 1/√2 (a + b)
*)



(* old definition: not needed
Inductive restricted_addition {n : nat}: AType n -> Prop :=
| add_restrict_base : forall (t : TType n), WF_TType n t -> restricted_addition [t]
| add_restrict_inductive : forall (a1 a2 : AType n),
    restricted_addition a1 -> restricted_addition a2 ->
   (** a1 a2 anticommutative precondition **) 
    restricted_addition (gScaleA (1/√2) (a1 ++ a2)).
 **)




Lemma translateA_gScaleA_nil : forall {n} (c : Coef) (A : AType n),
    proper_length_AType_nil n A -> translateA (gScaleA c A) = c .* (translateA A).
Proof. intros. induction A; simpl; unfold translateA in *; simpl.
  - rewrite Mscale_0_r. reflexivity.
  - unfold gScaleA in *. rewrite ! fold_left_Mplus. rewrite Mscale_plus_distr_r.
    rewrite IHA. f_equal. apply translate_gScaleT. inversion H; assumption.
    inversion H. assumption.
Qed.

Lemma translateA_gScaleA : forall {n} (c : Coef) (A : AType n),
    proper_length_AType n A -> translateA (gScaleA c A) = c .* (translateA A).
Proof. intros. apply proper_length_AType_implies_proper_length_AType_nil in H.
  apply translateA_gScaleA_nil. assumption.
Qed.


Lemma WF_Matrix_translateA_nil : forall {n : nat} (a : AType n), proper_length_AType_nil n a -> WF_Matrix (translateA a).
Proof. intros. unfold translateA.
  induction a; simpl.
  - auto with wf_db.
  - rewrite fold_left_Mplus.
    apply WF_plus.
    apply IHa.
    inversion H.
    assumption.
    apply WF_Matrix_translate.
    inversion H.
    assumption.
Qed.

Lemma WF_Matrix_translateA : forall {n : nat} (a : AType n), proper_length_AType n a -> WF_Matrix (translateA a).
Proof. intros.
  apply proper_length_AType_implies_proper_length_AType_nil in H.
  apply WF_Matrix_translateA_nil.
  assumption.
Qed.


#[export] Hint Resolve WF_Matrix_translateA_nil WF_Matrix_translateA : wf_db.



Definition anticommute_AType_semantic {n : nat} (a1 a2 : AType n) : Prop :=
  (translateA a1)×(translateA a2) = -C1 .* (translateA a2)×(translateA a1).

Inductive restricted_addition_semantic {n : nat}: AType n -> Prop :=
| add_restrict_base_semantic : forall (t : TType n), WF_TType n t -> restricted_addition_semantic [t]
| add_restrict_inductive_semantic : forall (a1 a2 : AType n),
    restricted_addition_semantic a1 -> restricted_addition_semantic a2 ->
    anticommute_AType_semantic a1 a2 -> 
    restricted_addition_semantic (gScaleA (1/√2) (a1 ++ a2)).


Lemma restricted_addition_semantic_implies_proper_length_AType: forall {n : nat} (a : AType n),
  restricted_addition_semantic a -> proper_length_AType n a.
Proof. intros n a H. induction H.
  - constructor. inversion H. assumption.
  - apply proper_length_AType_gScaleA.
    apply proper_length_AType_App; assumption.
Qed.



Definition anticommute_TType {n : nat} (t1 t2 : TType n) : Prop :=
  let (c1, Ps1) := t1 in
  let (c2, Ps2) := t2 in
  (cBigMul (zipWith gMul_Coef Ps1 Ps2)) = (- (cBigMul (zipWith gMul_Coef Ps2 Ps1)))%C.

Definition commute_TType {n : nat} (t1 t2 : TType n) : Prop :=
  let (c1, Ps1) := t1 in
  let (c2, Ps2) := t2 in
  (cBigMul (zipWith gMul_Coef Ps1 Ps2)) = (cBigMul (zipWith gMul_Coef Ps2 Ps1)).


Fixpoint anticommute_TType_AType {n : nat} (t : TType n) (a : AType n) : Prop :=
  match a with
  | t1 :: a1 => anticommute_TType t t1 /\ anticommute_TType_AType t a1
  | nil => True
  end. 
  
Fixpoint anticommute_AType_syntactic {n : nat} (a1 a2 : AType n) : Prop :=
  match a1 with
  | t1 :: a1' => anticommute_TType_AType t1 a2 /\ anticommute_AType_syntactic a1' a2
  | nil => True
  end.

(* not needed?
Inductive restricted_addition_syntactic : forall (n : nat), AType n -> Prop :=
| add_restrict_base_syntactic : forall n (t : TType n), WF_TType n t -> restricted_addition_syntactic n [t]
| add_restrict_inductive_syntactic : forall n (a1 a2 : AType n),
    restricted_addition_syntactic n a1 -> restricted_addition_syntactic n a2 ->
    anticommute_AType_syntactic a1 a2  ->
    restricted_addition_syntactic n (gScaleA (1/√2) (a1 ++ a2))
| add_restrict_tensor_syntactic : forall n m (a1 : AType n) (a2 : AType m),
    restricted_addition_syntactic n a1 -> restricted_addition_syntactic m a2 ->
    restricted_addition_syntactic (n+m) (gTensorA a1 a2).
*)

Inductive restricted_addition_syntactic {n : nat} : AType n -> Prop :=
| add_restrict_base_syntactic : forall (t : TType n), WF_TType n t -> restricted_addition_syntactic [t]
| add_restrict_inductive_syntactic : forall (a1 a2 : AType n),
    restricted_addition_syntactic a1 -> restricted_addition_syntactic a2 ->
    anticommute_AType_syntactic a1 a2  ->
    restricted_addition_syntactic (gScaleA (1/√2) (a1 ++ a2)).


Lemma restricted_addition_syntactic_implies_proper_length_AType: forall {n : nat} (a : AType n),
  restricted_addition_syntactic a -> proper_length_AType n a.
Proof. intros n a H. induction H.
  - constructor. inversion H. assumption.
  - apply proper_length_AType_gScaleA.
    apply proper_length_AType_App; assumption.
Qed.


Lemma translate_gMulT: forall (l l0 : list Pauli) (a b : Coef), length l0 = length l -> translate (gMulT (a, l) (b, l0)) =  (a * b .* ((⨂ map translate_P l) × (⨂ map translate_P l0)))%M.
Proof. induction l.
    - intros. simpl in *. rewrite length_zero_iff_nil in H. rewrite H. simpl. unfold translate, cBigMul, gMul_Coef, zipWith. simpl. rewrite Cmult_1_r.  lma'.
    - intros. simpl in *. destruct l0; try discriminate.
      simpl in *. inversion H.
      rewrite ! map_length. 
      assert (2 ^ length l + (2 ^ length l + 0) = 2 ^ (S (length l)))%nat. { simpl. easy. }
      rewrite ! H1.
      rewrite H0.
      assert (@Mmult (2 ^ S (length l)) (2 ^ S (length l)) (2 ^ S (length l)) (translate_P a ⊗ (⨂ map translate_P l)) (translate_P p ⊗ (⨂ map translate_P l0)) =  (@Mmult 2 2 2 (translate_P a) (translate_P p)) ⊗ (@Mmult (2 ^ length l) (2 ^ length l) (2 ^ length l) (⨂ map translate_P l) (⨂ map translate_P l0))).
      { rewrite ! map_length. rewrite ! H1.
        apply kron_mixed_product' with (A:= translate_P a) (B:= big_kron (map translate_P l)) (C:= translate_P p) (D:= big_kron (map translate_P l0)); easy. } 
      rewrite ! map_length in H2.
      setoid_rewrite kron_mixed_product.
      rewrite ! map_length in IHl.
      setoid_rewrite <- Mscale_kron_dist_r with (x:= a0 * b) at 1.
      rewrite <- IHl; try easy.
      unfold translate, cBigMul, zipWith, gMul_Coef, uncurry. simpl. rewrite ! fold_left_Cmult.

      setoid_rewrite <- Mscale_kron_dist_r.
      rewrite <- Mscale_assoc.
      setoid_rewrite Mscale_kron_dist_r.
      setoid_rewrite <- Mscale_kron_dist_l.
      setoid_rewrite Mscale_kron_dist_r.
      rewrite <- Mscale_assoc.
      setoid_rewrite <- Mscale_kron_dist_r.
      setoid_rewrite Mscale_kron_dist_l.
      setoid_rewrite Mscale_assoc.
      setoid_rewrite <- Mscale_kron_dist_l.
      symmetry.
      rewrite <- Mscale_assoc.

assert (translate_P a × translate_P p
  ⊗ (a0 * b
     .* (fold_left Cmult
           (map
              (fun p0 : Pauli * Pauli =>
               match fst p0 with
               | gI => C1
               | gX => match snd p0 with
                       | gY => Ci
                       | gZ => (- Ci)%C
                       | _ => C1
                       end
               | gY => match snd p0 with
                       | gX => (- Ci)%C
                       | gZ => Ci
                       | _ => C1
                       end
               | gZ => match snd p0 with
                       | gX => Ci
                       | gY => (- Ci)%C
                       | _ => C1
                       end
               end) (combine l l0)) C1
         .* (⨂ map translate_P
                 (map (fun p0 : Pauli * Pauli => gMul_base (fst p0) (snd p0))
                    (combine l l0)))))%M
        =
          ((a0 * b) .* (translate_P a × translate_P p)
  ⊗ ((fold_left Cmult
           (map
              (fun p0 : Pauli * Pauli =>
               match fst p0 with
               | gI => C1
               | gX => match snd p0 with
                       | gY => Ci
                       | gZ => (- Ci)%C
                       | _ => C1
                       end
               | gY => match snd p0 with
                       | gX => (- Ci)%C
                       | gZ => Ci
                       | _ => C1
                       end
               | gZ => match snd p0 with
                       | gX => Ci
                       | gY => (- Ci)%C
                       | _ => C1
                       end
               end) (combine l l0)) C1
         .* (⨂ map translate_P
                 (map (fun p0 : Pauli * Pauli => gMul_base (fst p0) (snd p0))
                    (combine l l0))))))%M).
{ 
  rewrite Mscale_kron_dist_r.
  rewrite <- Mscale_kron_dist_l.
  easy.
}
rewrite ! map_length in H3.
rewrite ! combine_length in H3.
rewrite H1 in H3.
replace (Init.Nat.min (length l) (length l)) with (length l) in H3 by lia.
setoid_rewrite H3.
rewrite ! map_length.
rewrite ! combine_length.
rewrite H1.
replace (Init.Nat.min (length l) (length l)) with (length l) by lia.
f_equal.
destruct a, p; simpl; try lma'.
Qed.


Lemma Pauli_anticomm_cons_comm_anticomm : forall (p p0 : Pauli) (l l0 : list Pauli),
    length l = length l0 ->
    cBigMul (zipWith gMul_Coef (p :: l) (p0 :: l0)) =
      (- cBigMul (zipWith gMul_Coef (p0 :: l0) (p :: l)))%C ->
    (gMul_Coef p p0 = (- gMul_Coef p0 p)%C ->
     cBigMul (zipWith gMul_Coef l l0) =
       cBigMul (zipWith gMul_Coef l0 l)) /\
      (gMul_Coef p p0 = gMul_Coef p0 p ->
       cBigMul (zipWith gMul_Coef l l0) =
         (- cBigMul (zipWith gMul_Coef l0 l))%C).
Proof. intros p p0 l l0 H H0. split.
  - intros H1. destruct p, p0; simpl in H1; inversion H1; try (contradict H1; lra);
      unfold cBigMul, gMul_Coef, zipWith, uncurry in *; simpl in *;
      rewrite ! fold_left_Cmult in H0; rewrite Copp_mult_distr_l in *;
      try rewrite ! Copp_involutive in H0; apply C_inv_l in H0; try nonzero; try easy; apply C0_snd_neq; simpl; lra.
  - intros H1. destruct p, p0; simpl in H1; inversion H1; try (contradict H1; lra);
      unfold cBigMul, gMul_Coef, zipWith, uncurry in *; simpl in *;
      rewrite ! fold_left_Cmult in H0; rewrite ! Cmult_1_l in H0; easy.
Qed.

Lemma Pauli_comm_cons_comm_anticomm : forall (p p0 : Pauli) (l l0 : list Pauli),
    length l = length l0 ->
    cBigMul (zipWith gMul_Coef (p :: l) (p0 :: l0)) =
      cBigMul (zipWith gMul_Coef (p0 :: l0) (p :: l)) ->
    (gMul_Coef p p0 =  gMul_Coef p0 p ->
     cBigMul (zipWith gMul_Coef l l0) =
       cBigMul (zipWith gMul_Coef l0 l)) /\
      (gMul_Coef p p0 = (- gMul_Coef p0 p)%C ->
       cBigMul (zipWith gMul_Coef l l0) =
         (- cBigMul (zipWith gMul_Coef l0 l))%C).
Proof. intros p p0 l l0 H H0. split.
  - intros H1. destruct p, p0; simpl in H1; inversion H1; try (contradict H1; lra);
      unfold cBigMul, gMul_Coef, zipWith, uncurry in *; simpl in *;
      rewrite ! fold_left_Cmult in H0; try rewrite ! Copp_involutive in H0;
      apply C_inv_l in H0; try nonzero; try easy; apply C0_snd_neq; simpl; lra.
  - intros H1. destruct p, p0; simpl in H1; inversion H1; try lra;
      unfold cBigMul, zipWith, uncurry in *; simpl in *;
      rewrite ! fold_left_Cmult in H0; try rewrite ! Cmult_1_l in H0;
      try rewrite <- ! Copp_mult_distr_l in H0; try rewrite ! Copp_mult_distr_r in H0;
      try apply C_inv_l in H0;
      try easy; try nonzero; try apply Copp_opp in H0; try easy.
Qed.

Lemma Pauli_comm_syntactic_implies_semantic : forall (p1 p2 : Pauli),
    gMul_Coef p1 p2 = gMul_Coef p2 p1 -> translate_P p1 × translate_P p2 = translate_P p2 × translate_P p1.
Proof. intros. destruct p1, p2; simpl in *; try lma'; inversion H; lra. Qed.

Lemma Pauli_anticomm_syntactic_implies_semantic : forall (p1 p2 : Pauli),
    gMul_Coef p1 p2 = (- gMul_Coef p2 p1)%C -> translate_P p1 × translate_P p2 = -C1 .* translate_P p2 × translate_P p1.
Proof. intros. destruct p1, p2; simpl in *; try lma'; inversion H; lra. Qed.

Lemma Pauli_comm_or_anticomm_syntactic : forall (p1 p2 : Pauli),
    gMul_Coef p1 p2 = gMul_Coef p2 p1 \/ gMul_Coef p1 p2 = (- gMul_Coef p2 p1)%C. 
Proof. intros. destruct p1, p2; simpl;
     [ left | left | left | left |
    left | left | right | right |
    left | right | left | right |
       left | right | right | left ];
    lca.
Qed.

Lemma Pauli_comm_or_anticomm_semantic : forall (p1 p2 : Pauli),
    translate_P p1 × translate_P p2 = translate_P p2 × translate_P p1
    \/
      translate_P p1 × translate_P p2 = -C1 .* translate_P p2 × translate_P p1.
Proof. intros. destruct p1, p2; simpl;
  [ left | left | left | left |
    left | left | right | right |
    left | right | left | right |
    left | right | right | left ];
    lma'.
Qed.

Lemma anticommute_commute_TType_syntactic_implies_semantic_nil : forall {n : nat} (t1 t2 : TType n),
    length (snd t1) = length (snd t2) ->
    proper_length_TType_nil n t1 -> proper_length_TType_nil n t2 ->
    ((anticommute_TType t1 t2 ->
      translate t1 × translate t2 .+ translate t2 × translate t1 = Zero)
     /\ (commute_TType t1 t2 ->
        translate t1 × translate t2 = translate t2 × translate t1)).
Proof. intros n t1 t2 H H0 H1. unfold anticommute_TType, commute_TType.
  destruct t1, t2.
  simpl in *.
  unfold translate. simpl.
  rewrite ! map_length.

  rewrite ! H.
  inversion H1.
  setoid_rewrite Mscale_mult_dist_l at 1.
  setoid_rewrite Mscale_mult_dist_r at 2.
  setoid_rewrite Mscale_mult_dist_l at 1.
  setoid_rewrite Mscale_mult_dist_r at 1.
  setoid_rewrite Mscale_mult_dist_l at 1.
  setoid_rewrite Mscale_mult_dist_r at 2.
  setoid_rewrite Mscale_mult_dist_l at 1.
  setoid_rewrite Mscale_mult_dist_r at 1.
  distribute_scale.
  setoid_rewrite <- Mscale_plus_distr_r.
  clear H2.

  gen n.
  gen l0. gen l.
  induction l; intros; simpl in *.
  - symmetry in H. rewrite length_zero_iff_nil in H. rewrite H.
    split; intros; lma'.
    unfold cBigMul, zipWith, gMul_Coef, uncurry in *; simpl in *.
    inversion H2. lra.
  - destruct l0; try discriminate.
    simpl in *.
    split; intros; simpl in *.
    + apply Pauli_anticomm_cons_comm_anticomm in H2; auto.
      destruct H2.
      destruct (Pauli_comm_or_anticomm_syntactic a p).
      * remember H4 as H5. clear HeqH5.
        apply H3 in H4.
        apply Pauli_comm_syntactic_implies_semantic in H5.
        inversion H.
        rewrite ! map_length. 
        rewrite ! H7.
        setoid_rewrite kron_mixed_product.
        rewrite H5.
        setoid_rewrite <- kron_plus_distr_l.
        assert (proper_length_TType_nil (length l0) (c, l)). { easy. }
        assert (proper_length_TType_nil (length l0) (c, l0)). { easy. }
        pose (IHl l0 H7  (length l0) H6 H8).
        destruct a0.
        apply H9 in H4.
        setoid_rewrite <- Mscale_kron_dist_r.
        rewrite H4.
        rewrite kron_0_r.
        reflexivity.
      * remember H4 as H5. clear HeqH5.
        apply H2 in H4.
        apply Pauli_anticomm_syntactic_implies_semantic in H5.
        inversion H.
        rewrite ! map_length. 
        rewrite ! H7.
        setoid_rewrite kron_mixed_product.
        rewrite H5.
        distribute_scale.
        rewrite <- Mscale_kron_dist_r.
        setoid_rewrite <- kron_plus_distr_l.
        assert (proper_length_TType_nil (length l0) (c, l)). { easy. }
        assert (proper_length_TType_nil (length l0) (c, l0)). { easy. }
        pose (IHl l0 H7  (length l0) H6 H8).
        destruct a0.
        apply H10 in H4.
        setoid_rewrite <- Mscale_kron_dist_r.
        rewrite Mscale_plus_distr_r.
        setoid_rewrite Mscale_assoc at 1.
        setoid_rewrite Cmult_comm at 1.
        setoid_rewrite <- Mscale_assoc at 1.
        rewrite H4.
        rewrite Mplus_opp_l.
        rewrite kron_0_r.
        reflexivity.
        apply WF_scale.
        apply WF_mult.
        rewrite <- map_length with (f := translate_P).
        apply WF_Matrix_Big_Pauli.
        rewrite <- H7.
        rewrite <- map_length with (f := translate_P).
        apply WF_Matrix_Big_Pauli.
    + apply Pauli_comm_cons_comm_anticomm in H2; auto.
      destruct H2.
      destruct (Pauli_comm_or_anticomm_syntactic a p).
      * remember H4 as H5. clear HeqH5.
        apply H2 in H4.
        apply Pauli_comm_syntactic_implies_semantic in H5.
        inversion H.
        rewrite ! map_length. 
        rewrite ! H7.
        setoid_rewrite kron_mixed_product.
        rewrite H5.
        assert (proper_length_TType_nil (length l0) (c, l)). { easy. }
        assert (proper_length_TType_nil (length l0) (c, l0)). { easy. }
        pose (IHl l0 H7  (length l0) H6 H8).
        destruct a0.
        apply H10 in H4.
        setoid_rewrite <- Mscale_kron_dist_r.
        rewrite H4.
        reflexivity.
      * remember H4 as H5. clear HeqH5.
        apply H3 in H4.
        apply Pauli_anticomm_syntactic_implies_semantic in H5.
        inversion H.
        rewrite ! map_length. 
        rewrite ! H7.
        setoid_rewrite kron_mixed_product.
        rewrite H5.
        distribute_scale.
        rewrite <- Mscale_kron_dist_r.
        assert (proper_length_TType_nil (length l0) (c, l)). { easy. }
        assert (proper_length_TType_nil (length l0) (c, l0)). { easy. }
        pose (IHl l0 H7  (length l0) H6 H8).
        destruct a0.
        apply H9 in H4.
        setoid_rewrite <- Mscale_kron_dist_r.
        setoid_rewrite Mscale_assoc at 1.
        setoid_rewrite Cmult_comm at 1.
        setoid_rewrite <- Mscale_assoc at 1.
        rewrite Mscale_plus_distr_r in H4.
        rewrite Mplus_comm in H4.
        rewrite Mplus_zero_iff_equals_minus in H4.
        rewrite <- H4.
        reflexivity.
        apply WF_scale.
        apply WF_mult.
        rewrite <- H7.
        rewrite <- map_length with (f := translate_P).
        apply WF_Matrix_Big_Pauli.
        rewrite <- map_length with (f := translate_P).
        apply WF_Matrix_Big_Pauli.
Qed.

Lemma anticommute_commute_TType_syntactic_implies_semantic: forall {n : nat} (t1 t2 : TType n),
    length (snd t1) = length (snd t2) ->
    proper_length_TType n t1 -> proper_length_TType n t2 ->
    ((anticommute_TType t1 t2 ->
      translate t1 × translate t2 .+ translate t2 × translate t1 = Zero)
     /\ (commute_TType t1 t2 ->
        translate t1 × translate t2 = translate t2 × translate t1)).
Proof. intros. apply proper_length_TType_implies_proper_length_TType_nil in H0.
  apply proper_length_TType_implies_proper_length_TType_nil in H1.
  apply anticommute_commute_TType_syntactic_implies_semantic_nil; auto.
Qed.

Lemma anticommute_AType_implies_semantic_anticommute_nil : forall {n : nat} (a1 a2 : AType n),
    proper_length_AType_nil n a1 -> proper_length_AType_nil n a2 ->
    anticommute_AType_syntactic a1 a2 -> anticommute_AType_semantic a1 a2.
Proof. intros n a1 a2 G1 G2 H. unfold anticommute_AType_semantic.
  induction a1.
  - unfold translateA. simpl in *. rewrite Mmult_0_l, Mmult_0_r. reflexivity.
  - unfold translateA in *. simpl in *.
    destruct H.
    inversion G1; subst.
    apply IHa1 in H0; auto.
    rewrite ! fold_left_Mplus. rewrite ! Mmult_plus_distr_l, ! Mmult_plus_distr_r.
    rewrite H0. f_equal.
    clear IHa1. clear H3. clear H4. clear H0.
    induction a2.
    + simpl in *. distribute_scale. rewrite Mmult_0_l, Mmult_0_r, Mscale_0_r. reflexivity.
    + simpl in *.
      destruct H.
      inversion G2; subst.
      apply IHa2 in H0; auto.
      rewrite ! fold_left_Mplus. distribute_scale.
      rewrite ! Mmult_plus_distr_l, ! Mmult_plus_distr_r.
      rewrite H0. rewrite Mscale_plus_distr_r, Mscale_mult_dist_l.
      f_equal.
      inversion G1; inversion G2.
      clear - n a a0 H H5 H9.
      inversion H5. inversion H9. rewrite <- H3 in H1.
      destruct (anticommute_commute_TType_syntactic_implies_semantic a a0 H1 H5 H9).
      apply H4 in H.
      rewrite <- Mplus_zero_iff_equals_minus.
      assumption.
      auto with wf_db.
Qed.

Lemma anticommute_AType_implies_semantic_anticommute : forall {n : nat} (a1 a2 : AType n),
    proper_length_AType n a1 -> proper_length_AType n a2 ->
    anticommute_AType_syntactic a1 a2 -> anticommute_AType_semantic a1 a2.
Proof. intros. apply proper_length_AType_implies_proper_length_AType_nil in H.
  apply proper_length_AType_implies_proper_length_AType_nil in H0.
  apply anticommute_AType_implies_semantic_anticommute_nil; auto.
Qed.

Lemma restricted_addition_syntactic_implies_semantic : forall {n : nat} (A : AType n),
    restricted_addition_syntactic A -> restricted_addition_semantic A.
Proof.
  intros n A H. induction H.
  - constructor. assumption.
  - constructor; try easy.
    apply restricted_addition_syntactic_implies_proper_length_AType in H.
    apply restricted_addition_syntactic_implies_proper_length_AType in H0.
    apply anticommute_AType_implies_semantic_anticommute in H1; auto.
Qed.
    

Lemma restricted_addition_semantic_implies_trace_zero : forall {n : nat} (A : AType n),
    restricted_addition_semantic A -> trace (translateA A) = C0.
Proof. intros. induction H.
  - do 2 destruct H. unfold translateA.
    destruct t. unfold translate.
    simpl in *. rewrite Mplus_0_l.
    rewrite map_length.
    rewrite H2.
    rewrite trace_mult_dist.
    rewrite <- H2.
    rewrite <- map_length with (f := translate_P).
    rewrite trace_zero_syntax_implies_trace_zero; auto; lca.
  - rewrite translateA_gScaleA.
    rewrite trace_mult_dist.
    rewrite translateA_app.
    rewrite trace_plus_dist.
    rewrite IHrestricted_addition_semantic1.
    rewrite IHrestricted_addition_semantic2.
    rewrite Cplus_0_l, Cmult_0_r.
    reflexivity.
    apply proper_length_AType_App.
    apply restricted_addition_semantic_implies_proper_length_AType in H.
    assumption.
    apply restricted_addition_semantic_implies_proper_length_AType in H0.
    assumption.
Qed.

Lemma list_Pauli_hermitian : forall (l : list Pauli),  (⨂ map translate_P l) † = ⨂ map translate_P l.
Proof. intros l. induction l.
  - simpl. lma'.
  - simpl. setoid_rewrite kron_adjoint. rewrite IHl.
    destruct a; simpl.
    + replace  (Matrix.I 2) †  with  (Matrix.I 2) by lma'. reflexivity.
    + replace (σx) † with  (σx) by lma'. reflexivity.
    + replace (σy) † with  (σy) by lma'. reflexivity.
    + replace (σz) † with  (σz) by lma'. reflexivity.
Qed.

Lemma restricted_addition_semantic_implies_Hermitian : forall {n : nat} (A : AType n),
    restricted_addition_semantic A -> (translateA A) † = (translateA A).
Proof. intros. 
  induction H.
  - unfold translateA. unfold translate. destruct t. simpl. rewrite ! Mplus_0_l.
    destruct H. simpl in *.
    destruct H0; rewrite H0.
    + rewrite Mscale_1_l. apply list_Pauli_hermitian.
    + rewrite map_length. destruct H. simpl in *.
      rewrite H2.
      rewrite Mscale_adj.
      replace  ((- C1) ^* ) with  (- C1)%C by lca.
      f_equal. apply list_Pauli_hermitian.
  - rewrite translateA_gScaleA.
    rewrite Mscale_adj.
    replace ((C1 / √ 2) ^* ) with (C1 / √ 2) by lca.
    f_equal.
    rewrite translateA_app.
    rewrite Mplus_adjoint.
    rewrite IHrestricted_addition_semantic1.
    rewrite IHrestricted_addition_semantic2.
    reflexivity.
    apply proper_length_AType_App.
    apply restricted_addition_semantic_implies_proper_length_AType in H.
    assumption.
    apply restricted_addition_semantic_implies_proper_length_AType in H0.
    assumption.
Qed.


Lemma unit_Pauli : forall (p : Pauli), WF_Unitary (translate_P p).
Proof. intros. 
       destruct p; simpl; auto with unit_db.
Qed.

Lemma unit_list_Pauli : forall (l : list Pauli), WF_Unitary (⨂ map translate_P l).
Proof. intros.
  apply big_kron_unitary.
  intros a H.
  rewrite in_map_iff in H.
  do 2 destruct H.
  rewrite <- H.
  apply unit_Pauli.
Qed.

#[export] Hint Resolve unit_Pauli unit_list_Pauli : unit_db.


(* norm of coeff = 1, precondition *)
Lemma uni_TType : forall {n} (A : TType n), fst A * fst A ^* = C1 -> WF_TType n A -> WF_Unitary (translate A). 
Proof. intros n A H H0. 
  unfold translate. pose (scale_unitary (2 ^ (length (snd A))) (fst A) (⨂ map translate_P (snd A))) as w.
  destruct A. inversion H0.
  unfold translate.
  rewrite map_length in *.
  destruct H1. simpl in *.
  subst. unfold WF_Unitary in *. show_dimensions.
  apply w.
  - pose (big_kron_unitary 2 (map translate_P l)) as w0.
    rewrite map_length in *.
    apply w0.
    intros a H4. 
    apply in_map_iff in H4.
    do 2 destruct H4.
    rewrite <- H4.
    apply unit_Pauli.
  - assumption.
Qed.

Lemma restricted_addition_semantic_implies_Unitary : forall {n : nat} (A : AType n),
    restricted_addition_semantic A -> WF_Unitary (translateA A).
Proof. intros. induction H.
  - unfold translateA. simpl. rewrite Mplus_0_l.
    apply uni_TType; auto.
    destruct H.
    destruct H0; rewrite H0; lca.
  - rewrite translateA_gScaleA.
    unfold WF_Unitary.
    split.
    destruct IHrestricted_addition_semantic1.
    destruct IHrestricted_addition_semantic2.
    rewrite translateA_app.
    auto with wf_db.
    destruct IHrestricted_addition_semantic1.
    destruct IHrestricted_addition_semantic2.
    rewrite ! translateA_app.
    setoid_rewrite restricted_addition_semantic_implies_Hermitian in H3; auto.
    setoid_rewrite restricted_addition_semantic_implies_Hermitian in H5; auto.
    rewrite Mscale_adj.
    replace ((C1 / √ 2) ^* ) with (C1 / √ 2) by lca.
    rewrite Mplus_adjoint.
    setoid_rewrite restricted_addition_semantic_implies_Hermitian; auto.
    distribute_scale.
    assert (C1 / √ 2 * (C1 / √ 2) = C1/C2).
    {  replace (C1 / √ 2) with (/ √ 2) by lca.
       rewrite Cinv_sqrt2_sqrt. lca. }
    rewrite H6.
    distribute_plus.
    rewrite H3, H5.
    unfold anticommute_AType_semantic in H1.
    rewrite H1.
    setoid_rewrite Mplus_comm at 3.
    setoid_rewrite Mplus_assoc.
    setoid_rewrite Mplus_comm at 2.
    setoid_rewrite Mplus_assoc.
    assert (- C1 .* translateA a2 × translateA a1
                .+ translateA a2 × translateA a1 = @Zero (2^n) (2^n)).
    { distribute_scale. apply Mplus_opp_l. auto with wf_db. }
    rewrite H7. rewrite Mplus_0_r.
    lma'.
    apply proper_length_AType_App.
    apply restricted_addition_semantic_implies_proper_length_AType in H.
    assumption.
    apply restricted_addition_semantic_implies_proper_length_AType in H0.
    assumption.
Qed.

(** These are here for reference

We have: Unitary Hermitian trace zero.

Unitary -> Diagonalizable, Spectral decomposition D = U × A × U†.
Hermitian -> Diagonal values are real. (even within WF_Spectral: D = U × A × U†)
A and D share the same Eigenvalues: diagble_eigenpairs_transfer
U sends the eigenpair of A (v, c) to the eigenpair of B (Uv, c): diagble_eigenpairs_transfer
Unitary + Hermitian -> eigenvalues are either +1 or -1.
trace zero -> trace cyclic -> sum of eigenvalues are 0



Lemma hermitian_implies_real_diagonals : forall {n : nat} (A : Square n),
      A † = A -> (forall (i : nat), i < n -> snd (A i i) = 0%R. 


Lemma diagble_eigenpairs_transfer : forall {n} (A B X X' : Square n),
  WF_Matrix A -> WF_Diagonal B -> WF_Matrix X -> WF_Matrix X' ->
  A = X' × B × X -> X × X' = I n ->
  (forall x, x < n -> Eigenpair A (X' × (e_i x), B x x)).


Lemma restricted_addition_semantic_implies_Unitary : forall {n : nat} (A : AType n),
    restricted_addition_semantic A -> WF_Unitary (translateA A).

Theorem unit_implies_diagble : forall {n} (A : Square n),
  WF_Unitary A -> WF_Diagonalizable A.

Theorem unit_implies_spectral : forall {n} (A : Square n),
  WF_Unitary A -> WF_Spectral A.

Definition WF_Spectral {n : nat} (A : Square n) : Prop :=
  WF_Matrix A /\ (exists (U D: Square n), 
    WF_Diagonal D /\ WF_Unitary U /\ D = U × A × U†).

UA=BU
U : A -> B
v |-> Uv
cUv=UAv=BUv

U† B = A U†
U† : B -> A
w |-> U†w
c U† w=U† B w=A U† w



Definition WF_Diagonalizable {n : nat} (A : Square n) : Prop :=
  WF_Matrix A /\ (exists (X X' B: Square n), 
    WF_Diagonal B /\ WF_Matrix X /\ WF_Matrix X' /\ X × X' = I n /\ B = X × A × X').

Lemma eig_unit_conv : forall {n} (v : Vector n) (c : C) (U B : Square n),
  WF_Matrix v -> WF_Unitary U -> 
  Eigenpair B (U × v, c) -> Eigenpair (U† × B × U) (v, c). 

Lemma eig_unit_norm1 : forall {n} (U : Square n) (c : C),
  WF_Unitary U -> (exists v, WF_Matrix v /\ v <> Zero /\ Eigenpair U (v, c)) -> (c * c^* = C1)%C.
Lemma diagble_eigenpairs_transfer : forall {n} (A B X X' : Square n),
  WF_Matrix A -> WF_Diagonal B -> WF_Matrix X -> WF_Matrix X' ->
  A = X' × B × X -> X × X' = I n ->
  (forall x, x < n -> Eigenpair A (X' × (e_i x), B x x)).

**)

(* spectral decomposition *)
Definition WF_Spectral {n : nat} (A : Square n) : Prop :=
  WF_Matrix A /\ (exists (U D: Square n), 
    WF_Diagonal D /\ WF_Unitary U /\ D = U † × A × U).

Lemma pad1_adjoint : forall {n : nat} (A : Square n) (c : C),
    (pad1 A c) † = pad1 (A †) (c ^* ).
Proof. intros. 
  prep_matrix_equality. 
  unfold pad1, Mmult, col_wedge, row_wedge, e_i, Matrix.scale, Matrix.adjoint.
  simpl.
  bdestruct_all; simpl; try lia; try lca; try easy.
Qed.

Lemma spectral_pad1 : forall {n} (A : Square n) (c : C),
  WF_Spectral A -> WF_Spectral (pad1 A c).
Proof. intros n A c [H [U [D [[Hwf Hd] [H1 H0]]]]].
       split. apply WF_pad1; auto.
       exists (pad1 U C1), (pad1 D c).
       split. split; try (apply WF_pad1; auto).
  - intros i0 j H2. 
    destruct i0; destruct j; try lia;
      unfold pad1, col_wedge, row_wedge, scale, e_i;
      bdestruct_all; try easy; try lca.
    do 2 rewrite Sn_minus_1.
    apply Hd; lia. 
  - split; try (apply WF_pad1; auto).
    split.
    destruct H1.
    apply WF_pad1; easy.
    rewrite pad1_adjoint.
    replace (C1 ^* ) with C1 by lca.
    destruct H1 as [H1 H2].
    rewrite <- pad1_mult, H2, Cmult_1_r, pad1_I.
    easy.
    rewrite pad1_adjoint.
    replace (C1 ^* ) with C1 by lca.
    do 2 rewrite <- pad1_mult.
    rewrite <- H0, Cmult_1_r, Cmult_1_l.
    easy.
Qed.


Theorem unit_implies_spectral : forall {n} (A : Square n),
  WF_Unitary A -> WF_Spectral A.
Proof. induction n as [| n']. 
       - intros A [H H0]. 
         apply WF0_Zero_l in H. 
         rewrite H.
         unfold WF_Spectral.
         split; auto with wf_db.
         exists (Zero), (Zero).
         split.
         + unfold WF_Diagonal.
           split; auto with wf_db.
         + split.
           * unfold WF_Unitary.
             split; auto with wf_db.
           * lma'.
       - intros A H. 
         assert (H0 := H).
         apply unitary_reduction_step1 in H.
         destruct H as [X [H1 [c H2]]].
         assert (H3 : WF_Unitary ((X) † × A × X)).
         { do 2 try apply Mmult_unitary.
           apply transpose_unitary.
           all : easy. }
         assert (H4 : (forall (i j : nat), (i = 0%nat \/ j = 0%nat) /\ i <> j -> ((X) † × A × X) i j = C0)).
         { apply unitary_reduction_step2; try easy. 
           exists c. easy. }
         apply unitary_reduction_step3 in H3; try easy.
         destruct H3 as [A' [H5 H6]].
         assert (H7 : WF_Spectral ((X) † × A × X)).
         apply IHn' in H5.
         { rewrite <- H6. 
           apply spectral_pad1.
           easy. }
         destruct H7 as [Hwf Hd].
         split. 
         destruct H0; easy.
         destruct Hd as [U [D [H7 [H8 H9]]]].
         exists (X × U).
         exists D.
         destruct H1 as [H1wf H1u].
         destruct H8 as [H8wf H8u].
         split; try easy.
         split; auto with wf_db.
         split; auto with wf_db.
         rewrite Mmult_adjoint.
         rewrite Mmult_assoc.
         rewrite <- Mmult_assoc with (C := U).
         rewrite H1u.
         rewrite Mmult_1_l.
         auto.
         auto with wf_db.
         rewrite Mmult_adjoint.
         repeat rewrite Mmult_assoc.
         repeat rewrite Mmult_assoc in H9.
         easy.
Qed.

Lemma spectral_eigenpairs_transfer : forall {n} (A D U : Square n),
WF_Matrix A -> WF_Diagonal D -> WF_Unitary U ->
  A = U × D × U† ->
  (forall x, (x < n)%nat -> Eigenpair A (U × (e_i x), D x x)).
Proof. intros. destruct H1.
  apply (diagble_eigenpairs_transfer A D (U†) U); auto with wf_db.
  Qed.

Lemma big_sum_double_sum_comm : forall (f : nat -> nat -> C) (n m : nat),
    big_sum (fun x => (big_sum (fun y => f x y) n)) m = big_sum (fun y => (big_sum (fun x => f x y) m)) n.
Proof. induction n as [| n'].
  - setoid_rewrite big_sum_0_bounded; easy.
  - intros.
    destruct m as [| m'].
    + setoid_rewrite big_sum_0_bounded; easy.
    + rewrite 2 big_sum_extend_double.
      rewrite IHn'.
      lca.
Qed.

Lemma trace_cyclic : forall {n m : nat} (A : Matrix n m) (B : Matrix m n),
    trace (A × B) = trace (B × A).
Proof. intros.
  unfold trace, Mmult.
  rewrite big_sum_double_sum_comm.
  f_equal.
  apply functional_extensionality.
  intros.
  f_equal.
  apply functional_extensionality.
  intros.
  lca.
Qed.

Lemma hermitian_implies_real_diagonals : forall {n : nat} (A : Square n),
    A † = A -> (forall (i : nat), (i < n)%nat -> snd (A i i) = 0%R).
Proof. intros.
  unfold adjoint in H.
  apply equal_f with (x := i0) in H.
  apply equal_f with (x := i0) in H.
  unfold Cconj in H.
  destruct (A i0 i0).
  inversion H.
  simpl in *.
  lra.
Qed.



Lemma Unitary_Hermitian_trace_zero_eigenvalues_plus_minus_1 : forall {n} (A : Square n),
  WF_Unitary A -> A † = A -> trace A = 0 ->
  (exists U D, WF_Diagonal D /\ WF_Unitary U /\ A = U × D × U† /\ trace D = C0 /\
  (forall x, (x < n)%nat -> Eigenpair A (U × (e_i x), D x x) /\ (D x x = C1 \/ D x x = (Copp C1)))).
Proof. intros n A WFUA HA TA.
  remember WFUA as WFSA. clear HeqWFSA.
  apply unit_implies_spectral in WFSA.
  destruct WFSA as [WFA [U [D [WFDD [WFUU H]]]]].
  remember H as  H'. clear HeqH'.
  remember WFUU as WFUU'. clear HeqWFUU'.
  destruct WFUU as [WFU UU].
  apply (@Mmult_inj_l n n n U) in H.
  rewrite <- ! Mmult_assoc in H.
  remember UU as UU'. clear HeqUU'.
  apply Minv_flip in UU'; auto with wf_db.
  rewrite UU' in H.
  rewrite Mmult_1_l in H; auto.
  apply (@Mmult_inj_r n n n (U†)) in H.
  setoid_rewrite Mmult_assoc in H at 2.
  rewrite UU' in H.
  rewrite Mmult_1_r in H; auto.
  remember WFDD as WFDD'. clear HeqWFDD'.
  destruct WFDD as [WFD DD].
  (exists U, D). repeat (split; auto).
  rewrite <- H in TA.
  rewrite trace_cyclic in TA.
  rewrite <- Mmult_assoc in TA.
  rewrite UU in TA.
  rewrite Mmult_1_l in TA; auto with wf_db.
  apply spectral_eigenpairs_transfer; auto.
  remember H' as H''. clear HeqH''.
  apply (@Mmult_inj_r n n n D) in H'.
  rewrite H'' in H' at 3.
  repeat setoid_rewrite <- Mmult_assoc in H'.
  setoid_rewrite Mmult_assoc in H' at 3.
  rewrite UU' in H'.
  rewrite Mmult_1_r in H'; auto with wf_db.
  destruct WFUA as [_ UA].
  rewrite HA in UA.
  setoid_rewrite Mmult_assoc in H' at 2.
  rewrite UA in H'.
  rewrite Mmult_1_r in H'; auto with wf_db.
  rewrite UU in H'.
  do 2 apply equal_f with (x := x) in H'.
  unfold I in H'.
  destruct (blt_reflect x n); try contradiction.
  destruct (beq_reflect x x); try contradiction.
  simpl in H'.
  unfold Mmult in H'.
  assert (H1 : (D x x) * (D x x) = C1).
  { rewrite <- H'. symmetry. apply big_sum_unique.
    (exists x). repeat (split; auto).
    intros.
    rewrite DD; auto.
    rewrite Cmult_0_l.
    reflexivity. }
  assert (H2 : D † = D).
  { rewrite ! H''.
    rewrite ! Mmult_adjoint.
    rewrite adjoint_involutive.
    rewrite HA.
    rewrite ! Mmult_assoc.
    reflexivity. }
  apply hermitian_implies_real_diagonals with (i := x) in H2; auto.
  destruct (D x x).
  simpl in H2.
  subst.
  unfold Cmult, C1 in H1.
  simpl in H1.
  inversion H1.
  autorewrite with R_db in *.
  clear H3.
  assert (r = 1 \/ r = -1).
  { nra. }
  destruct H.
  left. subst. lca.
  right. subst. lca.
Qed.


(** Should be provable from the above. **)
(* List of diagonal of D is balanced, count of positives equal to m1, count of negatives equal to m2, then m1 = m2, otherwise contradiction. so n is even.

exists (L1 L2 : list (Vector n)), forall v in L1 -> A v = v /\ forall w in L2 -> A v = -v /\ length L1 = length L2.
 *)


(** 
Try to express basis as a list of Vectors.
Set, orthonormal **)






(* {P} U {Q}
For both P and Q, the only eigenvalues are +1 and -1, and the dimension of +1-eigenstates equals that of the -1-eigenstates.

Let { v1, v2, ..., vn, w1, w2, ..., wn } be the eigenvectors of P where the vi's are the +1 eigenvectors and the wi's are the -1 eigenvectors.

P = U'† D U' for some diagonal D and unitary U'.
Since there is a spectral decomposition for P, we can make { v1, v2, ..., vn, w1, w2, ..., wn } as an orthonormal basis that spans the whole space.

Consider { U v1, U v2, ..., U vn, U w1, U w2, ..., U wn }.
Since unitary matrices preserve innerproducts, { U v1, U v2, ..., U vn, U w1, U w2, ..., U wn } also forms an orthonormal basis.

By the assertion {P} U {Q}, given any linear combination v = a1 v1 + ... + an vn, we have QUv = Uv.

Hence { U v1, U v2, ..., U vn } forms a basis for the +1 eigenspace of Q.

Given a w such that Pw = -w we want to show that QUw = -Uw.
Since eigenvectors corresponding to distinct eigenvalues are orthogonal, the -1 eigenspace of Q is orthogonal to the +1 eigenspace of Q.
Therefore, the -1 eigenspace of Q must be spanned by { U w1, U w2, ..., U wn }.
Since { U w1, U w2, ..., U wn } is orthonormal, they form an orthonormal basis of the -1 eigenspace of Q.

Hence, given any linear combination w = a1 w1 + ... + an wn, we have QUw = - Uw.

For any basis v' in { v1, v2, ..., vn, w1, w2, ..., wn }, QUv' = UPv', 
*)




Lemma trace_zero_syntax_nonempty :
  ~ trace_zero_syntax [].
Proof. intro. dependent induction H;
  apply IHtrace_zero_syntax; (* Search (_ ++ _ = []); *)
  apply app_eq_nil in x;
    destruct x; auto.
Qed.

Lemma trace_zero_syntax_non_gI :
  ~ trace_zero_syntax [gI].
Proof. intro.
  dependent induction H.
  - apply app_eq_unit in x.
    destruct x.
    + destruct H0.
      subst.
      apply trace_zero_syntax_nonempty in H.
      contradiction.
    + destruct H0.
      apply IHtrace_zero_syntax.
      assumption.
  - apply app_eq_unit in x.
    destruct x.
    + destruct H0.
      apply IHtrace_zero_syntax.
      assumption.
    + destruct H0.
      subst.
      apply trace_zero_syntax_nonempty in H.
      contradiction.
Qed.


Lemma eq_implies_JMeq : forall (A : Type) (x y : A), 
    x = y -> JMeq x y.
Proof. intros A x y H. rewrite H. reflexivity. Qed.

Lemma restricted_addition_semantic_non_nil : forall {n : nat},
    ~ (@restricted_addition_semantic n []).
Proof. intro. intro.
  dependent induction H.
  rewrite gScaleA_dist_app in x.
  apply app_eq_nil in x.
  destruct x.
  unfold gScaleA in *.
  apply map_eq_nil in H2, H3.
  subst.
  apply IHrestricted_addition_semantic1.
  apply eq_implies_JMeq.
  reflexivity.
Qed.

Lemma restricted_addition_syntactic_non_nil : forall {n : nat},
    ~ (@restricted_addition_syntactic n []).
Proof. intro. intro.
  dependent induction H.
  rewrite gScaleA_dist_app in x.
  apply app_eq_nil in x.
  destruct x.
  unfold gScaleA in *.
  apply map_eq_nil in H2, H3.
  subst.
  apply IHrestricted_addition_syntactic1.
  apply eq_implies_JMeq.
  reflexivity.
Qed.



Inductive WF_AType (n : nat) : AType n -> Prop :=
| WF_A_syntactic (a : AType n) : restricted_addition_syntactic a -> WF_AType n a.

Lemma restricted_addition_syntactic_implies_WF_AType : forall {n} (a : AType n),
    restricted_addition_syntactic a -> WF_AType n a.
Proof. intros n a H. constructor. auto. Qed.

Lemma WF_AType_implies_proper_length_AType : forall {n} (a : AType n),
    WF_AType n a -> proper_length_AType n a.
Proof. intros n a H. destruct H.
  apply restricted_addition_syntactic_implies_proper_length_AType; auto.
Qed.

(** ** probably not needed
Inductive WF_AType_nil (n : nat) : AType n -> Prop :=
| WF_A_nil : WF_AType_nil n nil
| WF_A_nil_syntactic (a : AType n) : restricted_addition_syntactic a -> WF_AType_nil n a.

Lemma WF_AType_implies_WF_AType_nil : forall {n} (A : AType n),
    WF_AType n A -> WF_AType_nil n A.
Proof.
  intros. induction H; constructor; try easy; constructor.
Qed.
 *)

(** ** probably not needed
Inductive WF_TType_list_nil (n : nat) : AType n -> Prop :=
| WF_T_list_nil : WF_TType_list_nil n nil
| WF_T_list_nil_Cons (a : TType n) (b : AType n) : WF_TType n a -> WF_TType_list_nil n b -> WF_TType_list_nil n (a :: b).

Lemma WF_TType_list_nil_implies_proper_length_AType_nil : forall {n} (a : AType n),
    WF_TType_list_nil n a -> proper_length_AType_nil n a.
Proof. intros n a H. induction H.
  - constructor.
  - constructor; auto.
    destruct H; auto.
Qed.

Inductive WF_TType_list (n : nat) : AType n -> Prop :=
| WF_T_list_Sing (a : TType n) : WF_TType n a -> WF_TType_list n (cons a nil)
| WF_T_list_Cons (a : TType n) (b : AType n) : WF_TType n a -> WF_TType_list n b -> WF_TType_list n (a :: b).

Lemma WF_TType_list_implies_proper_length_AType : forall {n} (a : AType n),
    WF_TType_list n a -> proper_length_AType n a.
Proof. intros n a H. induction H.
  - constructor. destruct H; auto.
  - constructor; auto.
    destruct H; auto.
Qed.

Lemma WF_TType_list_implies_WF_TType_list_nil : forall {n} (A : AType n),
    WF_TType_list n A -> WF_TType_list_nil n A.
Proof. intros. induction H; constructor; try easy; constructor. Qed.

Lemma WF_TType_list_app : forall {n} (a1 a2 : AType n),
    WF_TType_list n a1 -> WF_TType_list n a2 -> WF_TType_list n (a1 ++ a2).
Proof. intros n a1 a2 H H0.
  induction H.
  - constructor; auto.
  - simpl in *. constructor; auto.
Qed.

(** ** does not work
Lemma WF_TType_list_gScaleA : forall {n} (c : Coef) (a : AType n),
    WF_TType_list n (gScaleA c a) <-> WF_TType_list n a.
Proof. *)

(** ** does not work
Lemma WF_AType_implies_WF_TType_list : forall  {n} (A : AType n),
    WF_AType n A -> WF_TType_list n A.
Proof. intros n A H. destruct H. induction H.
  - constructor. auto.
  - rewrite gScaleA_dist_app.
    apply WF_TType_list_app.*)
*)
    





(** ** Failed attempt: non-working old definition
Definition RA {n : nat} (a : AType n) := restricted_addition_syntactic a.
Definition RA_semantic {n : nat} (a : AType n) := restricted_addition_semantic a.

Inductive WF_AType_nil (n : nat) : AType n -> Prop :=
| WF_A_nil : WF_AType_nil n nil
| WF_A_nil_Cons (a : TType n) (b : AType n) : WF_TType n a -> WF_AType_nil n b -> WF_AType_nil n (a :: b).

Inductive WF_AType (n : nat) : AType n -> Prop :=
| WF_A_Sing (a : TType n) : WF_TType n a -> WF_AType n (cons a nil)
| WF_A_Cons (a : TType n) (b : AType n) : WF_TType n a -> WF_AType n b -> WF_AType n (a :: b).

Lemma WF_AType_implies_WF_AType_nil : forall {n} (A : AType n),
    WF_AType n A -> WF_AType_nil n A.
Proof. intros. induction H; constructor; try easy; constructor. Qed.
*)


Inductive anticommute_APredicate_syntactic {n} : Predicate n -> Predicate n -> Prop :=
| anticomm_Pred : forall (a1 a2 : AType n),  anticommute_AType_syntactic a1 a2 ->
                             anticommute_APredicate_syntactic (G a1) (G a2).


Inductive WF_Predicate {n} : Predicate n -> Prop :=
| WF_G : forall a : AType n, WF_AType n a -> WF_Predicate (G a)
| WF_Cap : forall T1 T2 : Predicate n, WF_Predicate T1 -> WF_Predicate T2 -> WF_Predicate (Cap T1 T2)
| WF_Cup : forall T1 T2 : Predicate n, WF_Predicate T1 -> WF_Predicate T2 -> WF_Predicate (Cup T1 T2).



(* we are treating I as not well-formed 
Lemma WF_I : WF_Predicate pI. Proof. repeat constructor; try lia; try easy. Qed. *)
Lemma not_WF_I : ~ WF_Predicate pI.
Proof. intro. 
  inversion H; subst.
  inversion H1; subst.
  inversion H0.
  - inversion H3; subst.
    simpl in *.
    apply trace_zero_syntax_non_gI in H6.
    contradiction. 
  - rewrite gScaleA_dist_app in H2.
    apply app_eq_unit in H2.
    destruct H2.
    + destruct H2.
      apply map_eq_nil in H2. subst.
      apply restricted_addition_syntactic_non_nil in H3.
      assumption.
    + destruct H2.
      apply map_eq_nil in H6. subst.
      apply restricted_addition_syntactic_non_nil in H4.
      assumption.
Qed.




Lemma WF_X : WF_Predicate pX. Proof. repeat constructor; try lia; easy. Qed.
Lemma WF_Z : WF_Predicate pZ. Proof. repeat constructor; try lia; easy. Qed.


Lemma WF_TType_scale : forall {n} (a : TType n) (c : Coef),
    c = C1 \/ c = (- C1)%C -> WF_TType n a -> WF_TType n (gScaleT c a).
Proof. intros n a c H H0. inversion H0. constructor.
  - apply proper_length_TType_gScaleT. assumption.
  - destruct a. simpl in *.
    destruct H; destruct H2; subst; autorewrite with C_db;
      [ left | right | right | left ]; reflexivity.
  - destruct a. simpl in *. assumption.
Qed.



Lemma WF_AType_scale : forall {n} (A : AType n) (c : Coef),
    c = C1 \/ c = (- C1)%C -> WF_AType n A -> WF_AType n (gScaleA c A).
Proof. intros n A c H H0. inversion H0; subst.
  constructor.
  induction H1; simpl in *.
  - constructor. apply WF_TType_scale; easy.
  - apply WF_A_syntactic in H1_, H1_0.
    remember H1_ as H1'. clear HeqH1'.
    remember H1_0 as H2'. clear HeqH2'.
    destruct H1', H2'.
    apply restricted_addition_syntactic_implies_proper_length_AType in H2, H3.
    apply IHrestricted_addition_syntactic1 in H1_.
    apply IHrestricted_addition_syntactic2 in H1_0.
    clear IHrestricted_addition_syntactic1. clear IHrestricted_addition_syntactic2.
    inversion H0; subst. clear H0.
    rewrite gScaleA_comm. rewrite gScaleA_dist_app.
    constructor; try easy.
    clear -H1.
    induction a; simpl in *.
    + apply Logic.I.
    + destruct H1. split.
      2: apply IHa; try assumption.
      clear -H.
      induction a0; simpl in *.
      * apply Logic.I.
      * destruct H. split.
        2: apply IHa0; try  assumption.
        destruct a, a0.
        simpl in *.
        assumption.
Qed.

Lemma WF_Predicate_scale : forall {n} (A : Predicate n) (c : Coef), 
    c = C1 \/ c = (- C1)%C -> APredicate A -> 
    WF_Predicate A -> (WF_Predicate (scale c A)).  
Proof. intros n A c H H0 H1. 
  induction H0; simpl. constructor. inversion H1; subst.
  apply WF_AType_scale; try easy.
Qed.


Lemma WF_AType_app : forall {n} (a b : AType n),
    anticommute_AType_syntactic a b ->
    WF_AType n a -> WF_AType n b -> WF_AType n (gScaleA (C1 / √ 2) (a ++ b)).
Proof. intros n a b H H0 H1.
  destruct H0, H1.
  repeat constructor; try easy.
Qed.


Lemma gMulT_gScaleT_l : forall {n} (a b : TType n) (c : Coef),
    gMulT (gScaleT c a) b = gScaleT c (gMulT a b).
Proof. intros n a b c. destruct a, b. simpl.
  f_equal. rewrite ! Cmult_assoc.
  reflexivity.
Qed.

Lemma gMulA_gScaleA_l : forall {n} (A B : AType n) (c : Coef),
    (gMulA (gScaleA c A) B) = gScaleA c (gMulA A B).
Proof. intros n A B c. induction A.
  - simpl. reflexivity.
  - simpl. rewrite gScaleA_dist_app.
    rewrite IHA. f_equal.
    unfold gScaleA.
    rewrite map_map.
    f_equal.
    apply functional_extensionality.
    intros. apply gMulT_gScaleT_l.
Qed.

Lemma gMulT_gScaleT_r : forall {n} (a b : TType n) (c : Coef),
    gMulT a (gScaleT c b) = gScaleT c (gMulT a b).
Proof. intros n a b c. destruct a, b. simpl.
  f_equal. rewrite ! Cmult_assoc.
  do 2 f_equal. rewrite Cmult_comm. reflexivity.
Qed.

Lemma gMulA_gScaleA_r : forall {n} (A B : AType n) (c : Coef),
    (gMulA A (gScaleA c B)) = gScaleA c (gMulA A B).
Proof. intros n A B c. induction A.
  - simpl. reflexivity.
  - simpl. rewrite gScaleA_dist_app.
    rewrite IHA. f_equal.
    unfold gScaleA.
    rewrite ! map_map.
    f_equal.
    apply functional_extensionality.
    intros. apply gMulT_gScaleT_r.
Qed.

Lemma proper_length_TType_zipWith_gMul_base : forall (n : nat) (c c0 c1 : Coef) (l l0 : list Pauli),
    proper_length_TType n (c, l) ->
    proper_length_TType n (c0, l0) ->
    proper_length_TType n (c1, zipWith gMul_base l l0).
Proof. intros n c c0 c1 l l0 H H0.
  destruct H, H0. simpl in *.
  constructor; try assumption.
  simpl in *.
  apply zipWith_len_pres; try assumption.
Qed.

Lemma trace_zero_syntax_zipWith_gMul_base_anticomm : forall (l l0 : list Pauli),
    length l = length l0 ->
    cBigMul (zipWith gMul_Coef l l0) = (- cBigMul (zipWith gMul_Coef l0 l))%C ->
    trace_zero_syntax (zipWith gMul_base l l0).
Proof. induction l.
  - intros.
    simpl in *.
    symmetry in H. rewrite length_zero_iff_nil in H.
    rewrite H. subst.
    unfold zipWith, gMul_base, cBigMul in *. simpl in *.
    inversion H0. lra.
  - intros.
    destruct l0.
    + simpl in *. inversion H.
    + simpl in *. inversion H.
      unfold zipWith in *. simpl in *.
      apply Pauli_anticomm_cons_comm_anticomm in H0; try assumption.
      destruct H0.
      unfold zipWith in *.
      assert (C1 = C1). { easy. }
      assert (Ci = (- - Ci)%C). { rewrite Copp_involutive. easy. }
      assert ((- Ci)%C = (- Ci)%C). {easy. }
      destruct a, p; simpl in *;
        try (apply H1 in H3; clear H4; clear H5; rename H3 into anticomm);
        try (apply H0 in H4; clear H3; clear H5; rename H4 into comm);
        try (apply H0 in H5; clear H3; clear H4; rename H5 into comm).
      all : unfold gMul_base at 1; unfold uncurry at 1; simpl in *.
      2,3,4,5,7,8,9,10,12,13,14,15 : 
      rewrite cons_conc in *; apply trace_zero_syntax_L; constructor.
      all : rewrite cons_conc in *; apply trace_zero_syntax_R; apply IHl; assumption.
      all : apply IHl; try assumption.
Qed.




Lemma big_kron_map_translate_P_twice (l : list Pauli) :
  (⨂ map translate_P l) × (⨂ map translate_P l) = I (2 ^ (length l)).
Proof. induction l.
  - simpl. lma'.
  - simpl. setoid_rewrite kron_mixed_product.
    rewrite IHl.
    assert (2 ^ length l + (2 ^ length l + 0) =  2 ^ S (length l))%nat. { simpl; easy. }
    assert (I 2 × I 2 = I 2). { lma'. }
    assert (σx × σx = I 2). { lma'. }
    assert (σy × σy = I 2). { lma'. }
    assert (σz × σz = I 2). { lma'. }
    destruct a; simpl;
      try rewrite H0;
      try rewrite H1;
      try rewrite H2;
      try rewrite H3;
      try rewrite H4;
      show_dimensions;
      rewrite map_length;
      rewrite kron_2_l;
      reflexivity.
Qed.

Lemma zipWith_gMul_base_inv : forall (l : list Pauli),
    zipWith gMul_base l l = repeat gI (length l).
Proof. intros l. induction l.
  - unfold zipWith, gMul_base; easy.
  - unfold zipWith, gMul_base, uncurry in *; simpl.
    rewrite IHl. f_equal.
    destruct a; easy.
Qed.

Lemma cBigMul_zipWith_gMul_Coef_inv : forall (l : list Pauli),
    cBigMul (zipWith gMul_Coef l l) = C1.
Proof. intros l. induction l.
  - unfold cBigMul, zipWith, uncurry, gMul_Coef; easy.
  - unfold cBigMul, zipWith, uncurry, gMul_Coef in *; simpl.
    rewrite fold_left_Cmult.
    rewrite IHl.
    destruct a; lca.
Qed.

Lemma gMulT_inv : forall {n} (t : TType n),
    WF_TType n t -> gMulT t t = (C1, repeat gI n).
Proof. intros n t H0.
  destruct H0. destruct H.
  destruct t. simpl in *.
  rewrite zipWith_gMul_base_inv.
  rewrite cBigMul_zipWith_gMul_Coef_inv.
  subst. f_equal.
  destruct H0; rewrite H0; lca.
Qed.

Lemma translate_gMulT_split : forall {n} (t1 t2 : TType n),
    proper_length_TType n t1 -> proper_length_TType n t2 ->
    translate (gMulT t1 t2) = (translate t1) × (translate t2).
Proof. intros n t1 t2 H0 H1.
  destruct H0, H1.
  destruct t1, t2. simpl in *.
  setoid_rewrite translate_gMulT.
  2: subst; auto.
  unfold translate. simpl.
  show_dimensions.
  rewrite map_length.
  rewrite H0.
  rewrite <- Mscale_assoc.
  rewrite <- Mscale_mult_dist_r.
  rewrite <- Mscale_mult_dist_l.
  easy.
Qed.

Lemma translate_mult_inv : forall {n} (t : TType n),
    WF_TType n t -> (translate t) × (translate t) = Matrix.I (2^n)%nat.
Proof. intros n t H0.
  remember H0.
  destruct H0. rewrite <- translate_gMulT_split; auto.
  rewrite gMulT_inv; auto.
  unfold translate; simpl.
  rewrite Mscale_1_l.
  clear -n.
  induction n; auto; simpl in *.
  rewrite IHn.
  pose id_kron.
  specialize (e 2%nat (2^n)%nat).
  show_dimensions.
  rewrite ! map_length.
  rewrite ! repeat_length.
  rewrite e.
  simpl.
  easy.
Qed.



Lemma gMul_Coef_comm_anticomm : forall (p1 p2 : Pauli),
    (gMul_Coef p1 p2 = gMul_Coef p2 p1) \/ (gMul_Coef p1 p2 = - gMul_Coef p2 p1)%C.
Proof. intros p1 p2. destruct p1, p2; unfold gMul_Coef; simpl; auto.
  all: right; lca.
Qed.

Lemma gMul_Coef_comm_1 : forall (p1 p2 : Pauli),
    (gMul_Coef p1 p2 = gMul_Coef p2 p1) -> gMul_Coef p1 p2 = C1.
Proof. intros p1 p2 H. destruct p1, p2; unfold gMul_Coef in *; auto.
  all: inversion H; lra.
Qed.

Lemma gMul_Coef_anticomm_plus_minus_i : forall (p1 p2 : Pauli),
    (gMul_Coef p1 p2 = - gMul_Coef p2 p1)%C -> (gMul_Coef p1 p2 = Ci \/ gMul_Coef p1 p2 = (- Ci)%C).
Proof. intros p1 p2 H. destruct p1, p2; unfold gMul_Coef in *; auto.
  all: inversion H; lra.
Qed.

(** prove stronger lemma: 
even occurrences of anticommuting Paulis have coefficients +1 or -1
odd occurrences of anticommuting Paulis have coefficients +I or -i **)

Lemma cBigMul_zipWith_gMul_Coef_comm_anticomm_plus_minus_1_i : forall (l l0 : list Pauli),
    length l = length l0 ->
    (cBigMul (zipWith gMul_Coef l l0) = cBigMul (zipWith gMul_Coef l0 l)
     -> cBigMul (zipWith gMul_Coef l l0) = C1 \/ cBigMul (zipWith gMul_Coef l l0) = (-C1)%C)
      /\ (cBigMul (zipWith gMul_Coef l l0) = (- (cBigMul (zipWith gMul_Coef l0 l)))%C
     -> cBigMul (zipWith gMul_Coef l l0) = Ci \/ cBigMul (zipWith gMul_Coef l l0) = (-Ci)%C).
Proof. induction l; intros.
  - simpl in *. symmetry in H. Search (length ?a = 0%nat). rewrite length_zero_iff_nil in H.
    subst.
    unfold cBigMul, zipWith, gMul_Coef; simpl.
    split; intros.
    + auto.
    + inversion H. lra.
  - destruct l0.
    + simpl in H. inversion H.
    + inversion H.
      simpl in *.
      destruct (IHl l0); auto.
      split; intros.
       * apply Pauli_comm_cons_comm_anticomm in H3; auto.
         destruct H3.
         unfold zipWith, cBigMul in *; simpl.
         rewrite fold_left_Cmult.
         unfold uncurry at 1 3; simpl.
         destruct (gMul_Coef_comm_anticomm a p).
         -- specialize (H0 (H3 H5)).
            apply gMul_Coef_comm_1 in H5.
            rewrite H5.
            rewrite Cmult_1_l.
            auto.
         -- specialize (H2 (H4 H5)).
            apply gMul_Coef_anticomm_plus_minus_i in H5.
            destruct H2, H5; rewrite H2, H5;
              [ right | left | left | right ]; lca.
       * apply Pauli_anticomm_cons_comm_anticomm in H3; auto.
         destruct H3.
         unfold zipWith, cBigMul in *; simpl.
         rewrite fold_left_Cmult.
         unfold uncurry at 1 3; simpl.
         destruct (gMul_Coef_comm_anticomm a p).
         -- specialize (H2 (H4 H5)).
            apply gMul_Coef_comm_1 in H5.
            rewrite H5.
            rewrite Cmult_1_l.
            auto.
         -- specialize (H0 (H3 H5)).
            apply gMul_Coef_anticomm_plus_minus_i in H5.
            destruct H0, H5; rewrite H0, H5;
              [ left | right | right | left ]; lca.
Qed.

Lemma cBigMul_zipWith_gMul_Coef_comm_plus_minus_1 : forall (l l0 : list Pauli),
    length l = length l0 ->
    cBigMul (zipWith gMul_Coef l l0) = cBigMul (zipWith gMul_Coef l0 l)
    -> cBigMul (zipWith gMul_Coef l l0) = C1 \/ cBigMul (zipWith gMul_Coef l l0) = (-C1)%C.
(** The number of the anticommuting paulis must be even, so the number of Ci coefficients in the multiplied tensor must also be even. Hence, the multiplication of all coefficients must be either 1 or -1 **)
Proof. apply cBigMul_zipWith_gMul_Coef_comm_anticomm_plus_minus_1_i. Qed.

Lemma trace_zero_syntax_zipWith_gMul_base_comm : forall (n : nat) (l l0 : list Pauli),
  cBigMul (zipWith gMul_Coef l l0) = cBigMul (zipWith gMul_Coef l0 l)
  -> length l = n -> length l0 = n ->
  zipWith gMul_base l l0 <> repeat gI n ->
  trace_zero_syntax (zipWith gMul_base l l0).
Proof. intros. gen l0 n.  induction l.
  - intros.
    simpl in *.
    rewrite <- H0 in H1.
    rewrite length_zero_iff_nil in H1.
    subst.
    unfold zipWith, gMul_base, cBigMul in *. simpl in *.
    contradiction.
  - intros.
    destruct l0.
    + simpl in *. rewrite <- H1 in H0. inversion H0.
    + simpl in *. destruct n; inversion H0; inversion H1.
      unfold zipWith in *. simpl in *.
      
      unfold cBigMul in *. simpl in *.
      rewrite ! fold_left_Cmult in H.
      unfold uncurry at 1 3 in H. unfold uncurry at 1 in H2.
      unfold uncurry at 1.
      simpl in *.
      destruct (gMul_base a p) eqn:base.
      * assert ( ~ (uncurry gMul_base (a, p) = gI /\ map (uncurry gMul_base) (combine l l0) = repeat gI n)).
      { generalize H2. apply not_iff_compat.
        split. intros. destruct H3. unfold uncurry in H3. simpl in *.
        f_equal. auto. intros. inversion H3. split; auto. }
        assert (gMul_Coef a p = C1).
        { destruct a, p; unfold gMul_Coef; simpl; auto.
          all: unfold gMul_base in base; simpl in base; inversion base. }
        assert (gMul_Coef p a = C1).
        { destruct a, p; unfold gMul_Coef; simpl; auto.
          all: unfold gMul_base in base; simpl in base; inversion base. }

        rewrite H6, H7 in *. rewrite ! Cmult_1_l in H.
        unfold "<>" in H3.
        unfold uncurry at 1 in H3.
        simpl in H3.
        assert ( map (uncurry gMul_base) (combine l l0) <> repeat gI n ).
        { intro.
          assert (gMul_base a p = gI /\ map (uncurry gMul_base) (combine l l0) = repeat gI n).
          { auto. }
          destruct (H3 H9). }
        specialize (IHl l0 H n H4 H5 H8).
        Search ([?a] ++ ?b). rewrite cons_conc.
        apply trace_zero_syntax_R. assumption.
      * rewrite cons_conc. do 2 constructor.
      * rewrite cons_conc. do 2 constructor.
      * rewrite cons_conc. do 2 constructor.
Qed.

Lemma zipWith_gMul_base_eq : forall (n : nat) (l l0 : list Pauli),
    length l = length l0 ->
    (zipWith gMul_base l l0 = repeat gI (length l) <-> l = l0).
Proof. intros n l l0 H.
  split; intro.
  - gen l0. induction l; intros; simpl in *.
    + inversion H.
      symmetry in H2. rewrite length_zero_iff_nil in H2.
      subst. easy.
    + destruct l0.
      * inversion H.
      * simpl in *. inversion H.
        inversion H0.
        f_equal.
        -- unfold uncurry, gMul_base in H3.
           destruct a, p; try easy; inversion H3.
        -- rewrite H3 in H4.
           unfold zipWith in IHl.
           specialize (IHl l0 H2 H4).
           easy.
  - rewrite H0. rewrite zipWith_gMul_base_inv. easy.
Qed.


Lemma zipWith_gMul_base_neq : forall (n : nat) (l l0 : list Pauli),
    length l = length l0 ->
    (zipWith gMul_base l l0 <> repeat gI (length l) <-> l <> l0).
Proof. intros n l l0 H.
  apply zipWith_gMul_base_eq in H; auto.
  apply not_iff_compat in H. easy.
Qed.
  
(* simple multiplication does not preserve well-formedness
Lemma WF_AType_map_gMulT : forall {n} (a : TType n) (B : AType n),
    WF_TType n a -> WF_AType n B -> WF_AType n (map (fun x : TType n => gMulT a x) B).
Proof. intros n a B0 H H0.
  induction H0; simpl; constructor; try apply WF_TType_mul; easy.
Qed.

Lemma WF_AType_mul : forall {n} (A B : AType n),
    WF_AType n A -> WF_AType n B -> WF_AType n (gMulA A B).
Proof.  intros n A0 B0 H H0.
   induction H.
   - simpl. rewrite <- app_nil_end.
     apply WF_AType_map_gMulT; easy.
   - simpl. apply WF_AType_app; try easy.
     apply WF_AType_map_gMulT; easy.
Qed.

Lemma WF_Predicate_mul : forall {n} (A B : Predicate n),
    APredicate A -> APredicate B -> 
  WF_Predicate A -> WF_Predicate B ->
  WF_Predicate (A *' B). 
Proof. intros n A B H H0 H1 H2.
  induction H, H0. inversion H1; inversion H2; subst.
  constructor. apply WF_AType_mul; easy.
Qed.
 *)

(** Precondition: Commute -> gMulT a b <> (c, gI^n) <- use repeat function **)
Lemma WF_TType_mul_commute : forall {n} (a b : TType n),
    commute_TType a b -> (snd (gMulT a b) <> repeat gI n) ->
    WF_TType n a -> WF_TType n b -> WF_TType n (gMulT a b).
Proof. intros n a b H H0 H1 H2. 
  unfold gMulT. destruct a, b.
  unfold commute_TType in H.
  do 2 destruct H1, H2; simpl in *.
  constructor; simpl.
  simpl; split; try assumption.
  apply zipWith_len_pres; assumption.
  apply cBigMul_zipWith_gMul_Coef_comm_plus_minus_1 in H; subst; auto.
  destruct H, H3, H5; rewrite H, H3, H5; autorewrite with C_db;
    [ left | right | right | left | right | left | left | right ]; reflexivity.
  apply trace_zero_syntax_zipWith_gMul_base_comm with (n := n);
    try assumption.
Qed.

(** Precondition : commute -> a <> b **)
Lemma WF_TType_mul_commute' : forall {n} (a b : TType n),
    commute_TType a b -> snd a <> snd b ->
    WF_TType n a -> WF_TType n b -> WF_TType n (gMulT a b).
Proof. intros n a b H H0 H1 H2.
  destruct a, b. simpl in H0.
  remember H1. remember H2. clear Heqw Heqw0.
  destruct w, w0. destruct H3, H6. simpl in H9, H10.
  rewrite <- zipWith_gMul_base_neq in H0; auto.
  2: subst; auto.
  apply WF_TType_mul_commute; simpl; subst; auto.
Qed.



Lemma cBigMul_zipWith_gMul_Coef_anticomm_plus_minus_i : forall (l l0 : list Pauli),
    length l = length l0 ->
    (cBigMul (zipWith gMul_Coef l l0) = (- (cBigMul (zipWith gMul_Coef l0 l)))%C
     -> cBigMul (zipWith gMul_Coef l l0) = Ci \/ cBigMul (zipWith gMul_Coef l l0) = (-Ci)%C).
Proof. apply cBigMul_zipWith_gMul_Coef_comm_anticomm_plus_minus_1_i. Qed.


Lemma WF_TType_mul_anticommute : forall {n} (a b : TType n),
    anticommute_TType a b ->
    WF_TType n a -> WF_TType n b -> WF_TType n (gScaleT Ci (gMulT a b)).
Proof. intros n a b H H0 H1.
  unfold anticommute_TType in H.
  destruct a, b.
  unfold gMulT.
  destruct H0, H1.
  inversion H0; inversion H1.
  simpl in *.
  constructor; simpl.
  - constructor; auto.
    simpl.
    rewrite zipWith_len_pres with (n := n); auto.
  - subst.
    apply cBigMul_zipWith_gMul_Coef_anticomm_plus_minus_i in H; auto.
    destruct H, H2, H4; rewrite H, H2, H4;
      [ right | left | left | right | left | right | right | left ]; lca.
  - subst.
    apply trace_zero_syntax_zipWith_gMul_base_anticomm; auto.
Qed.


Lemma anticommute_TType_gScaleT : forall {n} (c : Coef) (t1 t2 : TType n),
    anticommute_TType t1 (gScaleT c t2) <->  anticommute_TType t1 t2.
Proof. intros n c t1 t2.
  split; intros; destruct t1, t2; easy.
Qed.
  
Lemma anticommute_TType_AType_gScaleA : forall {n} (c : Coef) (t : TType n) (a : AType n),
    anticommute_TType_AType t (gScaleA c a) <-> anticommute_TType_AType t a.
Proof. intros n c t a.
  split; intros.
  - induction a; auto.
    simpl in *. destruct H.
    specialize (IHa H0).
    split; auto.
    rewrite anticommute_TType_gScaleT in H.
    easy.
  - induction a; auto.
    simpl in *. destruct H.
    specialize (IHa H0).
    split; auto.
    rewrite anticommute_TType_gScaleT.
    easy.
Qed.

Lemma anticommute_AType_syntactic_gScaleA : forall {n} (c : Coef) (a b : AType n),
    anticommute_AType_syntactic a (gScaleA c b) <-> anticommute_AType_syntactic a b.
Proof. intros n c a b.
  split; intros.
  - induction a; auto.
    simpl in *. destruct H.
    specialize (IHa H0).
    split; auto.
    rewrite anticommute_TType_AType_gScaleA in H.
    auto.
  - induction a; auto.
    simpl in *. destruct H.
    specialize (IHa H0).
    split; auto.
    rewrite anticommute_TType_AType_gScaleA.
    auto.
Qed.

Lemma anticommute_AType_syntactic_nil_r : forall {n} (a : AType n), anticommute_AType_syntactic a [] <-> True.
Proof. intros n a.
  split.
  - intro.
    induction a; auto.
  - intro.
    induction a; auto.
    simpl.
    rewrite and_comm.
    rewrite kill_true.
    apply IHa.
Qed.

Lemma anticommute_TType_comm : forall {n} (a b : TType n), anticommute_TType a b -> anticommute_TType b a.
Proof. intros n a b H.
  destruct a,b; simpl in *.
  rewrite H.
  lca.
Qed.

Lemma anticommute_AType_syntactic_comm : forall {n} (a b : AType n), anticommute_AType_syntactic a b -> anticommute_AType_syntactic b a.
Proof. intros n a b H.
  induction a.
  - apply anticommute_AType_syntactic_nil_r. auto.
  - simpl in *.
    destruct H. specialize (IHa H0).
    clear H0.
    induction b.
    + simpl. auto.
    + simpl in *.
      destruct H, IHa.
      specialize (IHb H0 H2).
      repeat split; auto.
      apply anticommute_TType_comm.
      auto.
Qed.

Lemma anticommute_TType_AType_app_dist : forall {n} (t : TType n) (a1 a2 : AType n),
    anticommute_TType_AType t (a1 ++ a2) <-> anticommute_TType_AType t a1 /\ anticommute_TType_AType t a2.
Proof. intros n t a1 a2.
  split.
  - intro. split.
    + induction a1.
      * simpl. auto.
      * simpl in *. destruct H.
        specialize (IHa1 H0).
        split; auto.
    + induction a1.
      * simpl in *. auto.
      * simpl in *. destruct H.
        specialize (IHa1 H0).
        auto.
  - intro. destruct H.
    induction a1; auto.
    simpl in *. destruct H.
    specialize (IHa1 H1).
    split; auto.
Qed.

Lemma anticommute_TType_AType_app_comm : forall {n} (t : TType n) (a1 a2 : AType n),
    anticommute_TType_AType t (a1 ++ a2) <->  anticommute_TType_AType t (a2 ++ a1).
Proof. intros n t a1 a2.
  split; intro;
    rewrite anticommute_TType_AType_app_dist;
    rewrite and_comm;
    rewrite <- anticommute_TType_AType_app_dist;
    auto.
Qed.

Lemma anticommute_AType_syntactic_app_dist_l : forall {n} (a b c : AType n), anticommute_AType_syntactic (a ++ b) c <-> anticommute_AType_syntactic a c /\ anticommute_AType_syntactic b c.
Proof. intros n a b c.
  split.
  - intro. split.
    + induction a.
      * simpl. auto.
      * simpl in *. destruct H.
        specialize (IHa H0).
        split; auto.
    + induction a.
      * simpl in *. auto.
      * simpl in *. destruct H.
        apply (IHa H0).
  - intro. destruct H.
    induction a; auto.
    simpl in *. destruct H.
    specialize (IHa H1).
    split; auto.
Qed.

Lemma anticommute_AType_syntactic_app_comm_l : forall {n} (a b c : AType n), anticommute_AType_syntactic (a ++ b) c <-> anticommute_AType_syntactic (b ++ a) c.
Proof. intros n a b c. rewrite ! anticommute_AType_syntactic_app_dist_l. rewrite and_comm.
  split; auto.
Qed.

Lemma anticommute_AType_syntactic_app_dist_r : forall {n} (a b c : AType n), anticommute_AType_syntactic a (b ++ c) <-> anticommute_AType_syntactic a b /\ anticommute_AType_syntactic a c.
Proof. intros n a b c.
  split.
  - intros.
    apply anticommute_AType_syntactic_comm in H.
    rewrite anticommute_AType_syntactic_app_dist_l in H.
    destruct H.
    split; apply anticommute_AType_syntactic_comm; auto.
  - intros [H H0].
    apply anticommute_AType_syntactic_comm.
    rewrite anticommute_AType_syntactic_app_dist_l.
    apply anticommute_AType_syntactic_comm in H.
    apply anticommute_AType_syntactic_comm in H0.
    split; auto.
Qed.

Lemma anticommute_AType_syntactic_app_comm_r : forall {n} (a b c : AType n), anticommute_AType_syntactic a (b ++ c) <-> anticommute_AType_syntactic a (c ++ b).
Proof. intros n a b c. rewrite ! anticommute_AType_syntactic_app_dist_r. rewrite and_comm.
  split; auto.
Qed.

Lemma gMulA_dist_app_l : forall {n} (a a1 a2 : AType n),
    gMulA (a1 ++ a2) a = (gMulA a1 a) ++ (gMulA a2 a).
Proof. intros n a a1 a2.
  induction a1; auto.
  simpl. rewrite IHa1.
  rewrite app_assoc.
  auto.
Qed.

(** counterexample

YYYYYZ, XXYYZZ, 
XXXXXI, ZZZIII

1/√2 (a1 + a2)* 1/√2 (b1 + b2) = 1/2 (a1 b1 + a1 b2 + a2 b1 + a2 b2) =
1/√2 ( 1/√2 (a1 b1 + a1 b2) + 1/√2 (a2 b1 + a2 b2) )

a1 b1 a2 b1 + a1 b1 a2 b2 + a1 b2 a2 b1 + a1 b2 a2 b2
- a2 b1 a1 b1 + a2 b2 a1 b1 + a2 b1 a1 b2 - a2 b2 a1 b2
- a2 b1 a1 b1 + a2 b2 a1 b1 - a2 a1 b1 b2 - a2 b2 a1 b2
- a2 b1 a1 b1 + a2 b2 a1 b1 - a2 b2 a1 b1 - a2 b2 a1 b2
- a2 b1 a1 b1 - a2 b2 a1 b2

a2 b1 a1 b1 + a2 b2 a1 b1 + a2 b1 a1 b2 + a2 b2 a1 b2
a2 b1 a1 b1 + a2 b2 a1 b1 - a2 a1 b1 b2 + a2 b2 a1 b2
a2 b1 a1 b1 + a2 b2 a1 b1 - a2 b2 a1 b1 + a2 b2 a1 b2
a2 b1 a1 b1 + a2 b2 a1 b2


Inductive restricted_addition_syntactic (n : nat) : AType n -> Prop :=
    add_restrict_base_syntactic : forall t : TType n,
                                  WF_TType n t -> restricted_addition_syntactic [t]
  | add_restrict_inductive_syntactic : forall a1 a2 : AType n,
                                       restricted_addition_syntactic a1 ->
                                       restricted_addition_syntactic a2 ->
                                       anticommute_AType_syntactic a1 a2 ->
                                       restricted_addition_syntactic
                                         (gScaleA (C1 / √ 2) (a1 ++ a2)).
 **)

Lemma WF_AType_dist_app : forall {n} (a1 a2 : AType n),
    WF_AType n a1 -> WF_AType n a2 -> anticommute_AType_syntactic a1 a2 ->
    WF_AType n (gScaleA (C1 / √ 2) (a1 ++ a2)).
Proof. intros n a1 a2 H H0 H1. 
  do 2 constructor; inversion H; inversion H0; auto.
Qed.

(* not needed?
(** prove for the simple tensored Paulis case of multiplication **)
Lemma WF_AType_mul_anticommutative_l : forall {n} (t : TType n) (A : AType n),
    anticommute_TType_AType t A ->
    WF_TType n t -> WF_AType n A -> WF_AType n (gScaleA (Ci)%C (map (fun (a : TType n) => gMulT t a) A)).
Proof. intros n t A H H0 H1.
  destruct H1.
  induction H1; simpl in *.
  - inversion H0. inversion H2.
    inversion H1. inversion H7.
    destruct t, t0. simpl in *.
    destruct H. clear H12. do 3 constructor. 
    + constructor; simpl; auto.
      rewrite zipWith_len_pres with (n:=n); auto.
    + simpl. rewrite <- H11 in H6.
      apply cBigMul_zipWith_gMul_Coef_anticomm_plus_minus_i in H; auto.
      destruct H, H3, H8; rewrite H, H3, H8;
        [ right | left | left | right | left | right | right | left ]; lca.
    + simpl. rewrite <- H11 in H6.
      apply trace_zero_syntax_zipWith_gMul_base_anticomm; auto.
  - assert (  (gScaleA Ci (map (fun a : TType n => gMulT t a) (gScaleA (C1 / √ 2) (a1 ++ a2)))) =
                (gScaleA (C1 / √ 2) ((gScaleA Ci (map (fun a : TType n => gMulT t a) a1)) ++
                  (gScaleA Ci (map (fun a : TType n => gMulT t a) a2)))) ).
    { unfold gScaleA. rewrite <- ! map_app.
      rewrite ! map_map. f_equal.
      apply functional_extensionality. intro.
      destruct t, x. simpl. f_equal. lca. }
    rewrite H2. clear H2.
    rewrite anticommute_TType_AType_gScaleA in H.
    rewrite anticommute_TType_AType_app_dist in H.
    destruct H.
    apply WF_AType_dist_app.
    + apply IHrestricted_addition_syntactic1; auto.
    + apply IHrestricted_addition_syntactic2; auto.
    + rewrite anticommute_AType_syntactic_gScaleA.
      apply anticommute_AType_syntactic_comm.
      rewrite anticommute_AType_syntactic_gScaleA.
      apply anticommute_AType_syntactic_comm.
      clear IHrestricted_addition_syntactic1 IHrestricted_addition_syntactic2.
      clear H1_ H1_0.
      induction a1; auto.
      simpl in *.
      destruct H, H1.
      specialize (IHa1 H3 H4).
      split; auto.
      clear IHa1.
      clear H3 H4.
      induction a2; auto.
      simpl in *.
      destruct H2, H1.
      specialize (IHa2 H3 H4).
      split; auto.
      clear IHa2.
      clear H3 H4.
      
      unfold gMulT, anticommute_TType in *.
      destruct t, a, a0.
      (* don't know how to proceed *)
      *)

(* does not work
Lemma WF_AType_mul_anticommutative : forall {n} (A B : AType n),
    anticommute_AType_syntactic A B ->
    WF_AType n A -> WF_AType n B -> WF_AType n (gScaleA (Ci)%C (gMulA A B)).
Proof. intros n A B H H0 H1.
  constructor. destruct H0, H1.

  induction H0.
  - simpl in *. rewrite app_nil_r.
    destruct H.
    induction H1.
    + simpl. constructor.
      destruct H. unfold anticommute_TType in H.
      destruct t, t0. simpl in *.
      constructor; simpl in *.
      3:{ destruct H0, H1. destruct H0, H1. simpl in *. rewrite <- H9 in H8.
          apply trace_zero_syntax_zipWith_gMul_base_anticomm; assumption. }
      1:{ apply proper_length_TType_zipWith_gMul_base with (c:=c) (c0:=c0);
          destruct H0; destruct H1; assumption. }
      destruct H0, H1. simpl in *.
      destruct H0, H1. simpl in *.
      apply cBigMul_zipWith_gMul_Coef_anticomm_plus_minus_i in H.
      2: subst; auto.
      destruct H, H4, H6; rewrite H, H4, H6;
      [ right | left | left | right | left | right | right | left ]; lca.
    + Search gScaleA.
      unfold gScaleA.
      rewrite ! map_map.
      assert ((fun x : TType n => gScaleT Ci (gMulT t (gScaleT (C1 / √ 2) x)))
              = (fun x : TType n => gScaleT (C1 / √ 2) (gMulT t (gScaleT Ci x)))).
      { apply functional_extensionality. intros.
        destruct x, t. simpl in *. f_equal. lca. }
      rewrite H3. rewrite <- map_map.
      assert ( (map (gScaleT (C1 / √ 2)) (map (fun x : TType n => gMulT t (gScaleT Ci x)) (a1 ++ a2))) = gScaleA (C1 / √ 2) (map (fun x : TType n => gMulT t (gScaleT Ci x)) (a1 ++ a2)) ).
      { unfold gScaleA. easy. }
      rewrite H4.
      rewrite map_app.
      constructor;
      clear H2;
      clear H3; clear H4;
      rewrite anticommute_TType_AType_gScaleA in H;
      rewrite anticommute_TType_AType_app_dist in H;
      destruct H.
      assert ( (map (fun x : TType n => gMulT t (gScaleT Ci x)) a1) =
                 (gScaleA Ci (map (fun x : TType n => gMulT t x) a1)) ).
      { unfold gScaleA.
        rewrite map_map. f_equal.
        apply functional_extensionality. intro.
        destruct x, t. simpl.
        f_equal. lca. }
      rewrite H3. 
      apply IHrestricted_addition_syntactic1. auto.
      assert ( (map (fun x : TType n => gMulT t (gScaleT Ci x)) a2) =
                 (gScaleA Ci (map (fun x : TType n => gMulT t x) a2)) ).
      { unfold gScaleA.
        rewrite map_map. f_equal.
        apply functional_extensionality. intro.
        destruct x, t. simpl.
        f_equal. lca. }
      rewrite H3.
      apply IHrestricted_addition_syntactic2. auto.
      assert ( (map (fun x : TType n => gMulT t (gScaleT Ci x)) a1) =
                 (gScaleA Ci (map (fun x : TType n => gMulT t x) a1)) ).
      { unfold gScaleA.
        rewrite map_map. f_equal.
        apply functional_extensionality. intro.
        destruct x, t. simpl.
        f_equal. lca. }
      rewrite H3.
      assert ( (map (fun x : TType n => gMulT t (gScaleT Ci x)) a2) =
                 (gScaleA Ci (map (fun x : TType n => gMulT t x) a2)) ).
      { unfold gScaleA.
        rewrite map_map. f_equal.
        apply functional_extensionality. intro.
        destruct x, t. simpl.
        f_equal. lca. }
      rewrite H4.
      clear H3. clear H4.
      rewrite anticommute_AType_syntactic_gScaleA.
      apply anticommute_AType_syntactic_comm.
      rewrite anticommute_AType_syntactic_gScaleA.
      apply anticommute_AType_syntactic_comm.
      specialize (IHrestricted_addition_syntactic1 H).
      specialize (IHrestricted_addition_syntactic2 H2).
      clear IHrestricted_addition_syntactic1.
      clear IHrestricted_addition_syntactic2.
      clear H1_. clear H1_0. 
      induction a1; auto.
      simpl in *. destruct H, H1.
      specialize (IHa1 H3 H4).
      split; auto.
      clear IHa1.
      induction a2; auto.
      apply anticommute_AType_syntactic_comm in H4.
      simpl in *. destruct H2, H1, H4.
      apply anticommute_AType_syntactic_comm in H7.
      specialize (IHa2 H5 H6 H7).
      split; auto.
      clear IHa2.
      clear -H0 H H2 H1. (** anticommute_TType (gMulT t a) (gMulT t a0) **)
      destruct t, a, a0.
      simpl in *.
      admit.
  - rewrite gScaleA_dist_app.
    rewrite gMulA_dist_app_l.
    rewrite gScaleA_dist_app.
    rewrite ! gMulA_gScaleA_l.
    setoid_rewrite gScaleA_comm at 1.
    setoid_rewrite gScaleA_comm at 2.
    rewrite <- gScaleA_dist_app.
    apply anticommute_AType_syntactic_comm in H.
    rewrite anticommute_AType_syntactic_gScaleA in H.
    apply anticommute_AType_syntactic_comm in H.
    rewrite anticommute_AType_syntactic_app_dist_l in H.
    destruct H.
    specialize (IHrestricted_addition_syntactic1 H).
    specialize (IHrestricted_addition_syntactic2 H2).
    constructor; auto.
    rewrite anticommute_AType_syntactic_gScaleA.
    apply anticommute_AType_syntactic_comm.
    rewrite anticommute_AType_syntactic_gScaleA.

    
(** second try **)
    clear - H H2 H0 H1.
    
    induction a2; auto.
    apply anticommute_AType_syntactic_comm in H0.
    simpl in *.
    destruct H2, H0.
    apply anticommute_AType_syntactic_comm in H4.
    specialize (IHa2 H3 H4).
    rewrite anticommute_AType_syntactic_app_dist_l.
    split; auto.
    apply anticommute_AType_syntactic_comm.
    clear IHa2.

    induction a1; auto.
    simpl in *.
    destruct H, H0, H4.
    specialize (IHa1 H5 H6 H7).
    rewrite anticommute_AType_syntactic_app_dist_l.
    split; auto.
    clear IHa1.
    clear - H H2 H0 H1.

    induction H1; simpl in *.
    + destruct H, H2. clear H3 H4.
      repeat split; auto.
      admit.
    + rewrite anticommute_TType_AType_gScaleA in H, H2.
      rewrite anticommute_TType_AType_app_dist in H, H2.
      destruct H, H2.
      specialize (IHrestricted_addition_syntactic1 H H2).
      specialize (IHrestricted_addition_syntactic2 H3 H4).
      assert ( (map (fun x : TType n => gMulT a1 x) (gScaleA (C1 / √ 2) (a0 ++ a2)))
               = (gScaleA (C1 / √ 2) (map (fun x : TType n => gMulT a1 x) (a0 ++ a2))) ).
      { unfold gScaleA. rewrite ! map_map.
        f_equal. apply functional_extensionality. intro.
        destruct a1, x. simpl. f_equal. lca. }
      rewrite H5. clear H5.
      assert ( (map (fun x : TType n => gMulT a x) (gScaleA (C1 / √ 2) (a0 ++ a2)))
               = (gScaleA (C1 / √ 2) (map (fun x : TType n => gMulT a x) (a0 ++ a2))) ).
      { unfold gScaleA. rewrite ! map_map.
        f_equal. apply functional_extensionality. intro.
        destruct a, x. simpl. f_equal. lca. }
      rewrite H5. clear H5.
      rewrite anticommute_AType_syntactic_gScaleA.
      apply anticommute_AType_syntactic_comm.
      rewrite anticommute_AType_syntactic_gScaleA.
      apply anticommute_AType_syntactic_comm.
      rewrite ! map_app.
      rewrite ! anticommute_AType_syntactic_app_dist_l.
      rewrite ! anticommute_AType_syntactic_app_dist_r.
      repeat split; auto.
      clear IHrestricted_addition_syntactic1 IHrestricted_addition_syntactic2.
      clear H1_ H1_0.

      * induction a0; auto.
        simpl in *. destruct H, H2, H1.
        specialize (IHa0 H5 H6 H7).
        split; auto.
        clear IHa0 H5 H6 H7.

        induction a2; auto.
        simpl in *. destruct H3, H4, H1.
        specialize (IHa2 H5 H6 H7).
        split; auto.
        clear IHa2 H5 H6 H7.


                            
    (* first try
    clear - H H2 H0.


    
    induction a2; auto.
    apply anticommute_AType_syntactic_comm in H0.
    simpl in *.
    destruct H2, H0.
    apply anticommute_AType_syntactic_comm in H3.
    specialize (IHa2 H2 H3).
    rewrite anticommute_AType_syntactic_app_dist_l.
    split; auto.
    apply anticommute_AType_syntactic_comm.
    clear IHa2.

    
    induction a1; auto.
    simpl in *.
    destruct H, H0, H3.
    specialize (IHa1 H4 H5 H6).
    rewrite anticommute_AType_syntactic_app_dist_l.
    split; auto.
    clear IHa1.
    clear - H H1 H0.
     

    induction a0; auto.
    simpl in *.
    destruct H, H1.
    specialize (IHa0 H2 H3).
    repeat split.
    3: apply anticommute_AType_syntactic_comm; simpl; split.
    4: apply anticommute_AType_syntactic_comm; auto.
    all: clear IHa0.
    clear H2 H3.

    
    2-3: induction a2; auto; simpl in *.
    2: destruct H2, H3; specialize (IHa2 H4 H5); split; auto; clear IHa2;
    clear - H H2 H1 H3 H0.
    3: destruct H2, H3; specialize (IHa2 H4 H5); split; auto; clear IHa2;
    clear - H H2 H1 H3 H0.
    2:{ destruct   }
         (* a1 a0 a a2 = - a1 a a0 a2 = a a1 a0 a2 = 
a0 a2 comm: a a1 a2 a0 = - a a2 a1 a0
a0 a2 anticomm : - a a1 a2 a0 = a a2 a1 a0
            a a2 a1 a0 *)
*)
*)

(* not needed?
(** prove for the simple tensored Paulis case of multiplication **)
(** commute_AType_syntactic, anticommute_AType_syntactic mutually define? **)
(** commute_AType_syntactic term-wise definition of commuttivity **)
(** permutation : vol3 software foundations, or monoid.v **)
Lemma WF_AType_mul_commutative : forall {n} (A B : AType n),
    commute_AType_syntactic A B -> A not a permutation of B ->
    WF_AType n A -> WF_AType n B -> WF_AType n (gMulA A B).
Proof. Admitted. *)



Lemma WF_TType_tensor : forall {n m} (a : TType n) (b : TType m), WF_TType n a -> WF_TType m b -> WF_TType (n+m) (gTensorT a b).
Proof. intros n m a b H H0.
  destruct H, H0.
  constructor.
  - unfold proper_length_TType in *. destruct H, H0. split; try lia.
    unfold gTensorT. destruct a, b. simpl in *. rewrite app_length. subst. reflexivity.
  - destruct a, b. unfold gTensorT. simpl in *.
    destruct H1, H3; subst; autorewrite with C_db;
      [left | right | right | left]; reflexivity.
  - destruct a, b. unfold gTensorT. simpl in *.
    constructor. assumption.
Qed.

Lemma map_gTensorT_gScaleA : forall {n m} (c : Coef) (a : TType n) (A : AType m),
    map (fun x : TType m => gTensorT a x) (gScaleA c A) =
      gScaleA c (map (fun x : TType m => gTensorT a x) A).
Proof. intros n m c a A.
  induction A.
  - simpl. auto.
  - simpl. f_equal; auto.
    clear IHA.
    destruct a, a0. simpl.
    f_equal. lca.
Qed.



Lemma gTensorT_gScaleT_comm_l : forall {n m} (c : Coef) (a : TType n) (b : TType m), gTensorT (gScaleT c a) b = gScaleT c (gTensorT a b).
Proof. intros n m c a b.
  unfold gScaleT, gTensorT.
  destruct a, b.
  f_equal.
  lca.
Qed. 

Lemma gTensorA_gScaleA_comm_l : forall {n m} (c : Coef) (a : AType n) (b : AType m), gTensorA (gScaleA c a) b = gScaleA c (gTensorA a b).
Proof. intros n m c a b.
  induction a.
  - auto.
  - simpl.
    Search gScaleA.
    rewrite gScaleA_dist_app.
    rewrite IHa.
    f_equal.
    unfold gScaleA.
    rewrite map_map.
    f_equal.
    apply functional_extensionality.
    intros t.
    apply gTensorT_gScaleT_comm_l.
Qed.

Lemma gTensorT_gScaleT_comm_r : forall {n m} (c : Coef) (a : TType n) (b : TType m), gTensorT a (gScaleT c b) = gScaleT c (gTensorT a b).
Proof. intros n m c a b.
  unfold gScaleT, gTensorT.
  destruct a, b.
  f_equal.
  lca.
Qed. 

Lemma gTensorA_gScaleA_comm_r : forall {n m} (c : Coef) (a : AType n) (b : AType m), gTensorA a (gScaleA c b) = gScaleA c (gTensorA a b).
Proof. intros n m c a b.
  induction a.
  - auto.
  - simpl.
    Search gScaleA.
    rewrite gScaleA_dist_app.
    rewrite IHa.
    f_equal.
    unfold gScaleA.
    rewrite ! map_map.
    f_equal.
    apply functional_extensionality.
    intros t.
    apply gTensorT_gScaleT_comm_r.
Qed.

Lemma gTensorA_app_dist : forall {n m} (a1 a2 : AType n) (a0 : AType m), gTensorA (a1 ++ a2) a0 = (gTensorA a1 a0) ++ (gTensorA a2 a0).
Proof. intros n m a1 a2 a0.
  induction a1; auto.
  simpl.
  rewrite <- app_assoc.
  f_equal.
  auto.
Qed.


Lemma gTensorA_nil_r : forall {n m} (a : AType n), @gTensorA n m a [] = [].
Proof. intros n m a.
  induction a.
  - auto.
  - simpl.
    apply IHa.
Qed.

Lemma fold_left_Cmult_app : forall {l l0}, fold_left Cmult (l ++ l0) C1 = (fold_left Cmult l C1) * (fold_left Cmult l0 C1).
Proof. intros l l0.
  induction l.
  - simpl. lca.
  - simpl.
    rewrite ! fold_left_Cmult.
    rewrite IHl.
    lca.
Qed.

Lemma WF_AType_map_gTensorT : forall {n m} (a : TType n) (B : AType m),
    WF_TType n a -> WF_AType m B -> WF_AType (n+m) (map (fun x : TType m => gTensorT a x) B).
Proof. intros n m a B0 H H0. 
  constructor.
  destruct H, H0. simpl in *.
  induction H0; simpl in *.
  - destruct a, t, H0. simpl in *.
    do 2 constructor; simpl in *.
    + constructor; destruct H, H0; simpl in *; try lia.
      rewrite app_length. subst. reflexivity.
    + destruct H1, H3; subst; autorewrite with C_db; [left | right | right | left]; reflexivity.
    + constructor. assumption.
  -  rewrite map_gTensorT_gScaleA.
     rewrite map_app.
     constructor; auto.
     clear IHrestricted_addition_syntactic1 IHrestricted_addition_syntactic2.
     clear -H0.
     induction a1.
     + simpl. auto.
     + simpl in *. destruct H0.
       split.
       2: apply IHa1; auto.
       clear IHa1.
       induction a2.
       * simpl. auto.
       * simpl in *. destruct H.
         apply anticommute_AType_syntactic_comm in H0.
         simpl in *.
         destruct H0.
         apply anticommute_AType_syntactic_comm in H2.
         split.
         2: apply IHa2; auto.
         clear IHa2.
         clear -H.
         destruct a, a0, a2.
         simpl in *.
         rewrite <- ! zipWith_app_product with (n:=length l); auto.
         unfold cBigMul in *.
         rewrite ! fold_left_Cmult_app.
         Search fold_left.
         rewrite H.
         lca.
Qed.

Lemma restricted_addition_syntactic_map_gTensorT : forall {n m} (a : TType n) (B : AType m),
    WF_TType n a -> restricted_addition_syntactic B -> restricted_addition_syntactic (map (fun x : TType m => gTensorT a x) B).
Proof. intros n m a B0 H H0.
  destruct H. simpl in *.
  induction H0; simpl in *.
  - destruct a, t, H0. simpl in *.
    do 2 constructor; simpl in *.
    + constructor; destruct H, H0; simpl in *; try lia.
      rewrite app_length. subst. reflexivity.
    + destruct H1, H3; subst; autorewrite with C_db; [left | right | right | left]; reflexivity.
    + constructor. assumption.
  -  rewrite map_gTensorT_gScaleA.
     rewrite map_app.
     constructor; auto.
     
     clear -H0.
     induction a1.
     + simpl. auto.
     + simpl in *. destruct H0.
       split.
       2: apply IHa1; auto.
       clear IHa1.
       induction a2.
       * simpl. auto.
       * simpl in *. destruct H.
         apply anticommute_AType_syntactic_comm in H0.
         simpl in *.
         destruct H0.
         apply anticommute_AType_syntactic_comm in H2.
         split.
         2: apply IHa2; auto.
         clear IHa2.
         clear -H.
         destruct a, a0, a2.
         simpl in *.
         rewrite <- ! zipWith_app_product with (n:=length l); auto.
         unfold cBigMul in *.
         rewrite ! fold_left_Cmult_app.
         Search fold_left.
         rewrite H.
         lca.
Qed.


















(* counterexample

1/√2(a1+a2) ⊗ 1/√2(b1+b2)

suppose a1*a2=-a2*a1 and b1*b2=-b2*b1

(a1+a2)⊗(b1+b2)
= ((a1+a2)⊗b1)+((a1+a2)⊗b2)
= a1⊗b1+a2⊗b1+a1⊗b2+a2⊗b2

((a1+a2)⊗b1)*((a1+a2)⊗b2)
= ((a1+a2)^2⊗(b1*b2))

((a1+a2)⊗b2)*((a1+a2)⊗b1)
= ((a1+a2)^2⊗(b2*b1))


((a1+a2)⊗(b1+b2))*((a1+a2)⊗(b1+b2))
=((a1+a2)⊗(b1+b2))^2
=((a1+a2)^2)⊗((b1+b2)^2)


-----------------------
a1 = X
a2 = Z
a0 = 1/√2(X+Z)

1/√2(X+Z) : X anticommutes with Z
1/√2(X+Z) ⊗ 1/√2(X+Z)

1/2(XX+XZ+ZX+ZZ)
= 1/√2(1/√2(XX+XZ)+1/√2(ZX+ZZ))

1/2(XX+XZ+ZX+ZZ)*1/2(XX+XZ+ZX+ZZ)
=1/4(XX*XX+XX*XZ+XX*ZX+XX*ZZ+
     XZ*XX+XZ*XZ+XZ*ZX+XZ*ZZ+
     ZX*XX+ZX*XZ+ZX*ZX+ZX*ZZ+
     ZZ*XX+ZZ*XZ+ZZ*ZX+ZZ*ZZ)
=1/4(+II -iIY-iYI-YY
     +iIY+II +YY -iYI
     +iYI+YY +II -iIY
     -YY +iYI+iIY+II)
=1/4(4*II)
=II

a1 = X
a2 = Z
a0 = X+Z
a1⊗a0 = XX+XZ
a2⊗a0 = ZX+ZZ

a1⊗a0 * a2⊗a0 = (XX+XZ)*(ZX+ZZ)
= XX*ZX+XX*ZZ+XZ*ZX+XZ*ZZ
= -iYI -YY   +YY   -iYI

a2⊗a0 * a1⊗a0 = (ZX+ZZ)*(XX+XZ)
= ZX*XX+ZZ*XX+ZX*XZ+ZZ*XZ
= iYI  -YY   +YY   +iYI

 *)
(** ** not needed?? does not work
Lemma WF_AType_tensor : forall {n m} (A : AType n) (B : AType m),
    WF_AType n A -> WF_AType m B -> WF_AType (n+m) (gTensorA A B).
Proof. intros n m A0 B0 H H0.
  destruct H, H0.
  constructor.

  dependent induction H.
  - simpl. rewrite <- app_nil_end.
    apply restricted_addition_syntactic_map_gTensorT; auto.
  - rewrite gTensorA_gScaleA_comm.
    rewrite gTensorA_app_dist.
    apply add_restrict_inductive_syntactic.
    + apply IHrestricted_addition_syntactic1; auto.
    + apply IHrestricted_addition_syntactic2; auto.
    + 
    subst.
    Admitted. *)
(*
anticommute_AType_syntactic (gTensorA a1 a0) (gTensorA a2 a0)

syntactically not true:

a1 = X
a2 = Z
a0 = X+Z
a1⊗a0 = XX+XZ
a2⊗a0 = ZX+ZZ

XX commutes with ZZ

but semantically true:

a1⊗a0 * a2⊗a0 = (XX+XZ)*(ZX+ZZ)
= XX*ZX+XX*ZZ+XZ*ZX+XZ*ZZ
= -iYI -YY   +YY   -iYI

a2⊗a0 * a1⊗a0 = (ZX+ZZ)*(XX+XZ)
= ZX*XX+ZZ*XX+ZX*XZ+ZZ*XZ
= iYI  -YY   +YY   +iYI

----------------------------------------------------

NOT TRUE: 

a1 = X+Y
a2 = Z
a0 = X+Z
a1⊗a0 = XX+XZ+YX+YZ
a2⊗a0 = ZX+ZZ
Then XX and YX are commutative with ZZ,
and XZ and YZ are commmutative with ZX.
XX*ZX+XZ*ZX+YX*ZX+YZ*ZX
+XX*ZZ+XZ*ZZ+YX*ZZ+YZ*ZZ
= -iYI+YY+iXI-XY
-YY-iYI+XY+iXI

ZX*XX+ZX*XZ+ZX*YX+ZX*YZ
+ZZ*XX+ZZ*XZ+ZZ*YX+ZZ*YZ
= iYI+YY-iXI-XY
-YY+iYI+XY-iXI

semantically anticommutes

--------------------------
a1 = X+Y
a2 = Z
a0 = X+Z

1/√2(X+Y) : X anticommutes with Y
1/√2(1/√2(X+Y)+Z) : Z anticommutes with X and Y
1/√2(X+Z) : Z anticommutes with X

1/√2(1/√2(X+Y)+Z) ⊗ 1/√2(X+Z)
**)

    
(** ** not needed?
Lemma WF_Predicate_tensor : forall {n m} (A : Predicate n) (B : Predicate m),
  APredicate A -> APredicate B -> 
  WF_Predicate A -> WF_Predicate B ->
  WF_Predicate (A ⊗' B). 
Proof. intros n m A B H H0 H1 H2. 
  induction H, H0. inversion H1; inversion H2; subst.
  constructor. apply WF_AType_tensor; easy.
Qed.
*)


Lemma WF_AType_add : forall {n} (A B : AType n),
     anticommute_AType_syntactic A B ->
    WF_AType n A -> WF_AType n B -> WF_AType n (gScaleA (C1 / √ 2) (gAddA A B)).
Proof. intros n A B H H0 H1.
  unfold gAddA.  apply WF_AType_app; easy.
Qed. 


Lemma WF_Predicate_add : forall {n} (A : Predicate n) (B : Predicate n),
    anticommute_APredicate_syntactic A B ->
    APredicate A -> APredicate B -> 
    WF_Predicate A -> WF_Predicate B ->
    WF_Predicate ((C1 / √ 2) ·' (A +' B)). 
Proof. intros n A B H H0 H1 H2 H3.
  induction H0, H1. inversion H; inversion H2; inversion H3; subst.
  constructor. apply WF_AType_add; try easy. Qed.
      

Lemma WF_AType_neg : forall {n} (A : AType n),
    WF_AType n A -> WF_AType n (gScaleA (Copp C1) A).
Proof. intros n A H.  apply WF_AType_scale; try easy. right. reflexivity. Qed.

Lemma WF_Predicate_neg : forall {n} (A : Predicate n),
    APredicate A -> 
    WF_Predicate A ->  WF_Predicate (- A). 
Proof. intros n A H H0.
  induction H. inversion H0; subst.
  constructor. apply WF_AType_neg; easy.
Qed.

(* scaling outside of +1 or -1 does not work 
Lemma WF_AType_i : forall {n} (A : AType n),
    WF_AType n A -> WF_AType n (gScaleA Ci A).
Proof. intros n A H.  apply WF_AType_scale; easy. Qed.

Lemma WF_Predicate_i : forall {n} (A : Predicate n),
    APredicate A -> 
    WF_Predicate A ->  WF_Predicate (i A). 
Proof. intros n A H H0.
  induction H. inversion H0; subst.
  constructor. apply WF_AType_i; easy.
Qed.
*)
Lemma WF_Y : WF_Predicate pY.
Proof. rewrite Y_is_iXZ. constructor. compute. autorewrite with R_db. do 3 constructor.
  - constructor.
    + lia.
    + simpl. lia.
  - left. simpl. lca.
  - constructor.
Qed.

#[export] Hint Resolve WF_I WF_X WF_Z WF_Y WF_AType_scale WF_Predicate_scale WF_AType_add WF_Predicate_add WF_AType_neg WF_Predicate_neg : wfpt_db.
(** 
Hint Resolve WF_AType_implies_WF_AType_nil WF_I WF_X WF_Z WF_Y WF_AType_mul WF_Predicate_mul WF_AType_scale WF_Predicate_scale WF_AType_tensor WF_Predicate_tensor WF_AType_add WF_Predicate_add WF_AType_neg WF_Predicate_neg WF_AType_i WF_Predicate_i : wfpt_db. *)


Lemma fold_left_WF_Matrix_AType : forall {n} (a : TType n) (A : list (TType n)),  
    fold_left Mplus (map translate A) (Zero .+ translate a)%M
    =  (fold_left Mplus (map translate A) (Zero) .+  translate a)%M.
Proof. intros n a A. apply (fold_left_Mplus (translate a) Zero (map translate A)).
Qed.

Lemma WF_Matrix_AType : forall {n} (A : AType n), WF_AType n A -> WF_Matrix (translateA A). 
Proof. intros n A H. destruct H.
  induction H.
  - destruct H.
    unfold translateA. simpl.
    rewrite Mplus_0_l.
    apply WF_Matrix_translate; auto.
  - apply restricted_addition_syntactic_implies_proper_length_AType in H.
    apply restricted_addition_syntactic_implies_proper_length_AType in H0.
    rewrite translateA_gScaleA.
    2: apply proper_length_AType_App; auto.
    apply WF_scale.
    apply WF_Matrix_translateA.
    apply proper_length_AType_App; auto.
Qed.

#[export] Hint Resolve WF_Matrix_AType : wfpt_db.



(*************)
(* proper_length_TPredicate types *)
(*************)

(** ** probably not needed
Inductive WF_TPredicate {n} : Predicate n -> Prop :=
| WFT : forall T : Predicate n, TPredicate T -> WF_Predicate T -> WF_TPredicate T. *)

Lemma pl_tp_all : forall (c : Coef) (l : list Pauli),
    length l <> 0%nat ->
    @proper_length_TPredicate (length l) (G ([(c,l)])).
Proof. intros. do 2 constructor; auto. Qed.

#[export] Hint Resolve pl_tp_all : wfpt_db.

Lemma pl_tp_I : proper_length_TPredicate pI. Proof. do 2 constructor; auto. Qed.
Lemma pl_tp_X : proper_length_TPredicate pX. Proof. do 2 constructor; auto. Qed.
Lemma pl_tp_Z : proper_length_TPredicate pZ. Proof. do 2 constructor; auto. Qed.
Lemma pl_tp_Y : proper_length_TPredicate pY. Proof. do 2 constructor; auto. Qed.


Lemma pl_tp_mul : forall {n} (A B : Predicate n),
  proper_length_TPredicate A -> proper_length_TPredicate B -> 
  proper_length_TPredicate (A *' B). 
Proof. intros n A B H H0. 
  inversion H; inversion H0.
  inversion H1; inversion H3.
  simpl in *. constructor.
  destruct t, t0. constructor; auto.
  simpl in *.
  rewrite zipWith_len_pres with (n:=n); auto.
Qed.


Lemma pl_tp_tensor : forall {n m} (A : Predicate n) (B : Predicate m),
  proper_length_TPredicate A -> proper_length_TPredicate B ->
  proper_length_TPredicate (A ⊗' B). 
Proof. intros n m A B H H0. 
  inversion H; inversion H0.
  inversion H1. inversion H3.
  simpl in *. constructor.
  constructor; try lia.
  destruct t, t0. simpl in *.
  rewrite app_length.
  rewrite H6,H8. auto.
Qed.


Lemma pl_tp_scale : forall {n} (A : Predicate n) (c : Coef),
  proper_length_TPredicate A ->  proper_length_TPredicate (scale c A). 
Proof. intros n A c H.
  inversion H. inversion H0.
  do 2 constructor; auto.
  destruct t. simpl in *.
  auto.
Qed.

Lemma pl_tp_neg : forall {n} (A : Predicate n),
  proper_length_TPredicate A ->  proper_length_TPredicate (- A). 
Proof. intros n A H. 
  inversion H. inversion H0.
  do 2 constructor; auto.
  destruct t. simpl in *.
  auto.
Qed.
   
Lemma pl_tp_i : forall {n} (A : Predicate n),
  proper_length_TPredicate A ->  proper_length_TPredicate (i A). 
Proof. intros n A H.
  inversion H. inversion H0.
  do 2 constructor; auto.
  destruct t. simpl in *.
  auto.
Qed.


#[export] Hint Resolve pl_tp_all pl_tp_I pl_tp_X pl_tp_Z pl_tp_Y pl_tp_scale pl_tp_mul pl_tp_tensor pl_tp_neg pl_tp_i : wfpt_db.

(*************)
(* proper_length_APredicate types *)
(*************)

(** ** probably not needed
Inductive WF_APredicate {n} : Predicate n -> Prop :=
| WFA : forall T : Predicate n, APredicate T -> WF_Predicate T -> proper_length_APredicate T. *)



Lemma pl_ap_I : proper_length_APredicate pI. Proof. do 3 constructor; auto. Qed.
Lemma pl_ap_X : proper_length_APredicate pX. Proof. do 3 constructor; auto. Qed.
Lemma pl_ap_Z : proper_length_APredicate pZ. Proof. do 3 constructor; auto. Qed.
Lemma pl_ap_Y : proper_length_APredicate pY. Proof. do 3 constructor; auto. Qed.

Lemma proper_length_TType_gMulT : forall {n} (t t0 : TType n),
    proper_length_TType n t -> proper_length_TType n t0
    -> proper_length_TType n (gMulT t t0).
Proof. intros n t t0 H H0.
  destruct t, t0. simpl in *.
  destruct H, H0.
  constructor; auto.
  simpl in *.
  apply zipWith_len_pres; auto.
Qed.

Lemma proper_length_AType_gMulA : forall {n} (a a0 : AType n),
    proper_length_AType n a -> proper_length_AType n a0
    -> proper_length_AType n (gMulA a a0).
Proof. intros n a a0 H H0. induction H; simpl in *.
  - rewrite <- app_nil_end.
    induction H0; simpl in *.
    + constructor.
      apply proper_length_TType_gMulT; auto.
    + constructor; auto.
      apply proper_length_TType_gMulT; auto.
  - apply proper_length_AType_App; auto.
    clear IHproper_length_AType.
    induction H0; simpl in *.
    + constructor.
      apply proper_length_TType_gMulT; auto.
    + constructor; auto.
      apply proper_length_TType_gMulT; auto.
Qed.

Lemma pl_ap_mul : forall {n} (A B : Predicate n),
  proper_length_APredicate A -> proper_length_APredicate B -> 
  proper_length_APredicate (A *' B). 
Proof. intros n A B H H0. 
  inversion H; inversion H0.
  constructor.
  apply proper_length_AType_gMulA; auto.
Qed.

Lemma proper_length_TType_gTensorT : forall {n m} (t : TType n) (t0 : TType m),
    proper_length_TType n t -> proper_length_TType m t0
    -> proper_length_TType (n + m) (gTensorT t t0).
Proof. intros n m t t0 H H0.
  destruct H, H0.
  destruct t, t0.
  simpl in *.
  constructor.
  - lia.
  - simpl. rewrite app_length.
    rewrite H1, H2. auto.
Qed.

Lemma proper_length_AType_gTensorA : forall {n m} (a : AType n) (a0 : AType m),
    proper_length_AType n a -> proper_length_AType m a0
    -> proper_length_AType (n + m) (gTensorA a a0).
Proof. intros n m a a0 H H0.
  induction H; simpl in *.
  - rewrite <- app_nil_end.
    induction H0; simpl in *.
    + constructor.
      apply proper_length_TType_gTensorT; auto.
    + constructor; auto.
      apply proper_length_TType_gTensorT; auto.
  - apply proper_length_AType_App; auto.
    clear IHproper_length_AType.
    induction H0; simpl in *.
    + constructor.
      apply proper_length_TType_gTensorT; auto.
    + constructor; auto.
      apply proper_length_TType_gTensorT; auto.
Qed.      
  
Lemma pl_ap_tensor : forall {n m} (A : Predicate n) (B : Predicate m),
  proper_length_APredicate A -> proper_length_APredicate B ->
  proper_length_APredicate (A ⊗' B). 
Proof. intros n m A B H H0. 
  inversion H; inversion H0.
  simpl in *. constructor.
  apply proper_length_AType_gTensorA; auto.
Qed.


Lemma pl_ap_scale : forall {n} (A : Predicate n) (c : Coef),
  proper_length_APredicate A ->  proper_length_APredicate (scale c A). 
Proof. intros n A c H.
  inversion H.
  constructor.
  apply proper_length_AType_gScaleA; auto.
Qed.

Lemma pl_ap_neg : forall {n} (A : Predicate n),
  proper_length_APredicate A ->  proper_length_APredicate (- A). 
Proof. intros n A H. 
       apply pl_ap_scale; easy. 
Qed.
   
Lemma pl_ap_i : forall {n} (A : Predicate n),
  proper_length_APredicate A ->  proper_length_APredicate (i A). 
Proof. intros n A H.
       unfold i. 
       apply pl_ap_scale; easy. 
Qed.


Lemma pl_ap_G_sing : forall {n} (a : TType n) (A : AType n),
    proper_length_APredicate (G (a :: A)) -> proper_length_APredicate (G ([a])).
Proof. intros n a A H.
  inversion H; subst.
  inversion H1; subst.
  - destruct H2; do 3 constructor; auto.
  - destruct H3; do 3 constructor; auto.
Qed.

Lemma pl_ap_G_cons : forall {n} (a : TType n) (A : AType n),
    A <> [] -> proper_length_APredicate (G (a :: A)) -> proper_length_APredicate (G (A)).
Proof. intros n a A H H0. 
  inversion H0; subst.
  inversion H2; subst.
  - contradiction.
  - constructor; auto.
Qed.

Lemma pl_ap_G_cons' : forall {n} (a : TType n) (A : AType n),
    proper_length_AType n A -> proper_length_APredicate (G (a :: A)) -> proper_length_APredicate (G (A)).
Proof. intros n a A H H0. 
  inversion H0; subst.
  inversion H2; subst.
  - inversion H.
  - constructor; auto.
Qed.


#[export] Hint Resolve pl_ap_I pl_ap_X pl_ap_Z  pl_ap_Y pl_ap_scale pl_ap_mul pl_ap_tensor pl_ap_neg pl_ap_i pl_ap_G_sing pl_ap_G_cons pl_ap_G_cons' : wfpt_db.



(******************)
(* unitary lemmas *)
(******************)


Lemma unitary_two_pauli : forall (p1 p2 : Pauli),
    p1 <> p2 -> p1 <> gI -> p2 <> gI -> WF_Unitary (C1 / √ 2 .* translate_P p1 .+ C1 / √ 2 .* translate_P p2)%M /\ WF_Unitary (- C1 / √ 2 .* translate_P p1 .+ C1 / √ 2 .* translate_P p2)%M /\ WF_Unitary (C1 / √ 2 .* translate_P p1 .+ - C1 / √ 2 .* translate_P p2)%M.
Proof. intros. split; [ idtac | split ]; unfold translate_P, WF_Unitary;
  induction p1, p2; simpl; split; try contradiction; auto with wf_db;
    lma'; auto 15 with wf_db;
    autounfold with U_db; simpl;
    C_field_simplify; try nonzero;
    autorewrite with Cexp_db C_db;
    eapply c_proj_eq; simpl;
    repeat (autorewrite with R_db; field_simplify_eq; simpl);
    try easy.
Qed.


Lemma zipWith_gMul_base_symmetric : forall (l l0 : list Pauli), length l = length l0 -> zipWith gMul_base l l0 = zipWith gMul_base l0 l.
Proof. intros l. unfold zipWith, gMul_base, uncurry. induction l.
  - intros. rewrite combine_nil. simpl. easy.
  - intros. destruct l0; try discriminate. simpl. f_equal. destruct a, p; simpl; try easy. apply IHl. inversion H. easy.
Qed.


(* same as unitary_two_tensored_paulis except that (fst t2 = - C1/√2). *)
Lemma unitary_two_tensored_paulis' : forall {n} (t1 t2 : TType n), 
    proper_length_TType n t1 -> proper_length_TType n t2 ->
    (fst t1 = C1/√2) -> (fst t2 = - C1/√2) ->
    anticommute_TType t1 t2 ->
    WF_Unitary (@translateA n (t1 :: t2 :: nil)). 
Proof. intros. destruct t1, t2. simpl in *.
  destruct H, H0. simpl in *.
  rewrite H1, H2 in *. clear H1. clear H2.
  inversion H3; subst.
  unfold translateA.
  simpl. rewrite Mplus_0_l.
  unfold translate. simpl  in *.
  setoid_rewrite Cmult_comm at 2.
  setoid_rewrite <- Cmult_1_l at 5.
  setoid_rewrite <- Mscale_assoc at 2.
  replace ( C1 * / √ 2 ) with ( C1 / √ 2) by lca.
  setoid_rewrite <- Mscale_plus_distr_r with (x:=C1 / √ 2) (A:=⨂ map translate_P l) (B:=(-C1 .*(⨂ map translate_P l0))%M).
  rewrite ! map_length.
  apply unitary_hermitian_anticommute_unitary.
  rewrite <- map_length with (f:=translate_P).
  apply unit_list_Pauli.
  rewrite <- H5.
  rewrite <- map_length with (f:=translate_P).
  apply scale_unitary; try lca.
  apply unit_list_Pauli.
  apply list_Pauli_hermitian.
  setoid_rewrite Mscale_adj with (x := (-C1)%C) (A := (⨂ map translate_P l0)).
  replace ((- C1) ^* )%C with (-C1)%C by lca.
  rewrite map_length.
  rewrite H5.
  apply Mscale_inj with (c:= (-C1)%C).
  apply list_Pauli_hermitian.
  apply Mscale_inv with (c:= (-C1)%C).
  intro. inversion H1. lra.
  setoid_rewrite <- Mscale_mult_dist_r at 1.
  unfold Matrix.scale at 1.
  setoid_rewrite Mscale_assoc at 1.
  replace (- C1 * - C1)%C with (C1) by lca.
  rewrite Mscale_1_l.
  setoid_rewrite <- Mscale_mult_dist_l.
  unfold Matrix.scale at 2.
  setoid_rewrite Mscale_assoc.
  replace (-C1 * - C1)%C with (C1) by lca.
  rewrite Mscale_1_l.
  replace (Copp (RtoC (IZR (Zpos xH)))) with (RtoC (IZR (Zneg xH))) by lca.
  apply Mscale_inv with (c:=C1/C2).
  - intros G. apply C_inj_r with (c:=C2) in G. unfold Cdiv in G. rewrite <- Cmult_assoc in G. rewrite Cinv_l in G; try nonzero. rewrite Cmult_0_l in G. rewrite Cmult_1_l in G. contradict G. nonzero.
  - rewrite Mscale_assoc. rewrite Cmult_comm. rewrite <- Mscale_assoc.
    replace (C1 / C2) with ((C1/√2) * (C1/√2)) by C_field.
    rewrite Mscale_assoc. rewrite Cmult_assoc. symmetry. rewrite Cmult_comm. symmetry.
    assert ((C1 / √ 2 * (C1 / √ 2) .* ((⨂ map translate_P l) × (⨂ map translate_P l0)))%M
            = (translate (gMulT  (C1 / √ 2, l) (C1 / √ 2, l0)))%M).
    { rewrite <- translate_gMulT; easy. }
      rewrite <- map_length with (f:=translate_P).
    rewrite H1.
    assert ((C1 / √ 2 * (-1 * (C1 / √ 2)) .* ((⨂ map translate_P l0) × (⨂ map translate_P l)))%M
            = (translate (gMulT  (C1 / √ 2, l0) (-1 * (C1 / √ 2), l)))%M).
    { rewrite <- translate_gMulT; easy. }
    show_dimensions.
    rewrite map_length.
    rewrite <- H5.
    rewrite <- map_length with (f:=translate_P).
    rewrite H4.
    simpl.
    assert (C1 / √ 2 * (C1 / √ 2) * - cBigMul (zipWith gMul_Coef l0 l)
            = C1 / √ 2 * (-1 * (C1 / √ 2)) * cBigMul (zipWith gMul_Coef l0 l)).
    { rewrite <- ! Cmult_assoc. apply C_inj_l. symmetry. 
      rewrite Cmult_comm. rewrite <- ! Cmult_assoc. apply C_inj_l.
      lca. }
    rewrite <- H6.
    rewrite H2.
    rewrite zipWith_gMul_base_symmetric; easy.
Qed.

Fixpoint uni_Predicate {n} (A : Predicate n) :=
  match A with
  | G a => WF_Unitary (translateA a)
  | Cap a b => (uni_Predicate a) /\ (uni_Predicate b)
  | Cup a b => (uni_Predicate a) /\ (uni_Predicate b)
  | Err => False
  end.

Lemma uni_vec_I : uni_Predicate pI.
Proof. simpl. unfold translateA, translate, translate_P. simpl.
       rewrite Mplus_0_l, Mscale_1_l, kron_1_r. unfold WF_Unitary.
       split. auto with wf_db. lma'.
Qed.
  
Lemma uni_vec_X : uni_Predicate pX.
Proof. simpl. unfold translateA, translate, translate_P. simpl.
       rewrite Mplus_0_l, Mscale_1_l, kron_1_r. unfold WF_Unitary.
       split. auto with wf_db. lma'.
Qed.

Lemma uni_vec_Y : uni_Predicate pY.
Proof.  simpl. unfold translateA, translate, translate_P. simpl.
       rewrite Mplus_0_l, Mscale_1_l, kron_1_r. unfold WF_Unitary.
       split. auto with wf_db. lma'.
Qed.

  Lemma uni_vec_Z : uni_Predicate pZ.
Proof.  simpl. unfold translateA, translate, translate_P. simpl.
       rewrite Mplus_0_l, Mscale_1_l, kron_1_r. unfold WF_Unitary.
       split. auto with wf_db. lma'.
Qed.


#[export] Hint Resolve unit_Pauli uni_vec_I uni_vec_X uni_vec_Y uni_vec_Z : wfpt_db.


(******************************************************)
(* Showing translations preserves relevent properties *)
(******************************************************)

(* we actually use this to prove translate_mult, so we prove it first *)
Lemma translate_kron : forall {n m} (g1 : TType n) (g2 : TType m),
    length (snd g1) = n -> length (snd g2) = m ->
    translate (gTensorT g1 g2) = (translate g1) ⊗ (translate g2).
Proof. intros. unfold translate.
         destruct g1; destruct g2.
         simpl in *.
         do 3 (rewrite map_length). 
         rewrite H, H0 in *.
         rewrite Mscale_kron_dist_r.
         rewrite Mscale_kron_dist_l.
         rewrite Mscale_assoc.
         bdestruct_all; simpl. 
         rewrite Cmult_comm.
         rewrite map_app. 
         assert (H3 : forall (l : list Pauli) (i0 : nat), WF_Matrix (nth i0 (map translate_P l) Zero)).
         { intros.  
           bdestruct (i0 <? length (map translate_P l1)).
           + apply (nth_In _ (@Zero 2 2)) in H1.
             apply in_map_iff in H1.
             destruct H1 as [x [H3 H4] ].
             rewrite <- H3; apply WF_Matrix_Pauli.
           + rewrite nth_overflow; try lia. 
             auto with wf_db. }
         rewrite big_kron_app; auto.
         do 2 (rewrite map_length).
         rewrite app_length.
         rewrite H, H0 in *.
         reflexivity.
Qed.


Lemma fold_left_translateA_kron : forall {n m} (a : TType n) (B : AType m),
 length (snd a) = n -> proper_length_AType m B ->
    (fold_left Mplus (map (fun x : TType n => translate (gTensorT a x)) B) Zero
     =  translate a ⊗ fold_left Mplus (map translate B) Zero)%M.
Proof. intros n m a B H H0.  generalize dependent a. induction B.
  - intros a H.   simpl. lma.
  - intros a0 H.   simpl. rewrite 2 fold_left_Mplus. rewrite kron_plus_distr_l.
    inversion H0.
    + inversion H2. rewrite <- (translate_kron a0 a); try assumption. simpl.
      apply Zero_kron.
    + inversion H3. rewrite <- (translate_kron a0 a); try assumption.
      rewrite IHB; try assumption. reflexivity.
Qed.

Lemma translateA_kron : forall {n m} (a : AType n) (b : AType m),
    proper_length_AType n a -> proper_length_AType m b ->
    translateA (gTensorA a b) = (translateA a) ⊗ (translateA b).
Proof. intros n m a b H H0. induction H.
  - simpl. rewrite <- app_nil_end. unfold translateA. simpl. rewrite Mplus_0_l. rewrite <- fold_left_translateA_kron; inversion H; try assumption. rewrite map_map; reflexivity.
  - simpl. unfold translateA. simpl. rewrite fold_left_Mplus.
    unfold translateA in IHproper_length_AType. rewrite kron_plus_distr_r.  rewrite <- IHproper_length_AType.
    rewrite map_app. rewrite fold_left_Mplus_app_Zero.
    rewrite map_map. rewrite <- fold_left_translateA_kron; inversion H; try assumption. rewrite Mplus_comm. reflexivity.
Qed.
    

Lemma gMulT_reduce : forall (n : nat) (c1 c2 : Coef) (p1 p2 : Pauli) (l1 l2 : list Pauli),
  length l1 = n -> length l2 = n ->
  gMulT (c1, p1 :: l1) (c2, p2 :: l2) = 
  @gTensorT 1 n (gMul_Coef p1 p2, [gMul_base p1 p2]) (gMulT (c1, l1) (c2, l2)).
Proof. intros. simpl. rewrite zipWith_cons.
  apply injective_projections; try easy.
  simpl.
  unfold cBigMul.
  simpl.
  rewrite fold_left_Cmult.
  rewrite Cmult_assoc.
  replace (c1 * c2 * gMul_Coef p1 p2) with (gMul_Coef p1 p2 * (c1 * c2)) by lca.
  rewrite <- Cmult_assoc.
  reflexivity.
Qed.

Lemma translate_reduce : forall (n : nat) (c : Coef) (p : Pauli) (l : list Pauli),
  length l = n -> 
  @translate (S n) (c, p :: l) = (translate_P p) ⊗ @translate n (c, l).
Proof. intros. 
       unfold translate. 
       simpl. 
       rewrite map_length.
       replace (2^(length l) + (2^(length l) + 0))%nat with (2 * 2^(length l))%nat by lia. 
       rewrite <- Mscale_kron_dist_r.
       rewrite H; easy. 
Qed.

Lemma translate_Mmult : forall {n} (g1 g2 : TType n),
    length (snd g1) = n -> length (snd g2) = n ->
    translate (gMulT g1 g2) = (translate g1) × (translate g2).
Proof. intros. induction n as [| n'].
       - destruct g1; destruct g2. 
         destruct l; destruct l0; try easy. 
         unfold translate. simpl. 
         distribute_scale.
         rewrite Mmult_1_r; auto with wf_db.
         unfold zipWith, cBigMul. simpl.
         destruct c; destruct c0; try easy.
         autorewrite with C_db.
         reflexivity.
       - destruct g1; destruct g2.
         destruct l; destruct l0; try easy. 
         simpl in H; simpl in H0.
         apply Nat.succ_inj in H.
         apply Nat.succ_inj in H0.
         rewrite gMulT_reduce; try easy.
         replace (S n') with (1 + n')%nat by lia.
         rewrite translate_kron; try easy.
         rewrite IHn'; try easy.
         rewrite (translate_reduce _ c), (translate_reduce _ c0); try easy.
         restore_dims.
         rewrite kron_mixed_product.
         assert (H' : @translate 1 (gMul_Coef p p0, [gMul_base p p0]) = 
                      translate_P p × translate_P p0).
         { destruct p; destruct p0; simpl. 
           all : unfold translate; simpl. 
           all : lma'. }
         rewrite H'; easy. 
         simpl. 
         bdestruct_all.
         simpl. 
         apply zipWith_len_pres; easy.
Qed.

Lemma fold_left_translateA_Mmult : forall {n} (a : TType n) (B : AType n),
    proper_length_TType n a -> proper_length_AType n B ->
    fold_left Mplus (map (fun x : TType n => translate (gMulT a x)) B) Zero =
      translate a × fold_left Mplus (map translate B) Zero.
Proof. intros n a B H H0.
  induction H0.
  - simpl. rewrite 2 Mplus_0_l. inversion H; inversion H0; rewrite translate_Mmult; easy.
  - simpl. rewrite 2 fold_left_Mplus. rewrite Mmult_plus_distr_l. rewrite <- translate_Mmult.
    rewrite IHproper_length_AType. reflexivity.
    + inversion H. assumption.
    + inversion H0. assumption.
Qed. 

Lemma translateA_Mmult : forall {n} (a b : AType n),
    proper_length_AType n a -> proper_length_AType n b ->
    translateA (gMulA a b) = (translateA a) × (translateA b).
Proof. intros n a b H H0.
  unfold translateA. induction H.
  - simpl. rewrite <- app_nil_end. rewrite map_map. rewrite Mplus_0_l.
    apply fold_left_translateA_Mmult; try assumption.
  - simpl. rewrite map_app. rewrite map_map. rewrite fold_left_Mplus_app_Zero.
    rewrite fold_left_Mplus. rewrite Mmult_plus_distr_r. rewrite <- IHproper_length_AType.
    rewrite fold_left_translateA_Mmult; try assumption. rewrite Mplus_comm. reflexivity.
Qed.

Lemma map_translate_gAddA : forall {n} (a b : AType n),
    proper_length_AType n a -> proper_length_AType n b ->
    map translate (gAddA a b) = ((map translate a) ++ (map translate b))%M.
Proof. intros n a b H H0.
       unfold gAddA. induction H.
       - simpl. reflexivity.
       - simpl. rewrite IHproper_length_AType. reflexivity.
Qed.

Lemma translateA_Add : forall {n} (a b : AType n),
    proper_length_AType n a -> proper_length_AType n b ->
    translateA (gAddA a b) = (translateA a .+ translateA b)%M.
Proof. intros n a b H H0.
       unfold translateA. induction H.
       - simpl. rewrite fold_left_Mplus. rewrite Mplus_0_l. rewrite Mplus_comm. reflexivity.
       - simpl. rewrite map_translate_gAddA; auto.
         rewrite ! fold_left_Mplus. rewrite fold_left_Mplus_app_Zero. rewrite ! Mplus_assoc. f_equal. rewrite Mplus_comm. reflexivity.
Qed. 

Lemma translate_scale : forall {n} (A : TType n) (c : Coef),
  translate (gScaleT c A) = (c .* (translate A))%M.
Proof. intros. 
       unfold translate. 
       destruct A. simpl. 
       rewrite <- Mscale_assoc.     
       reflexivity. 
Qed.

Lemma translateA_scale : forall {n} (A : AType n) (c : Coef),
    translateA (gScaleA c A) = (c .* (translateA A))%M.
Proof. intros n A c.
  unfold translateA. unfold gScaleA.
  rewrite map_map.
  induction A.
  - simpl. lma.
  - simpl. rewrite 2 fold_left_Mplus. rewrite Mscale_plus_distr_r.
    rewrite IHA. rewrite translate_scale. reflexivity.
Qed.


Declare Scope AType_scope.
Delimit Scope AType_scope with A.
Open Scope AType_scope.


Definition eq_AType {n} (A1 A2 : AType n) := translateA A1 = translateA A2.
Infix "≡" := eq_AType (at level 70, no associativity): AType_scope.


(* will now show this is an equivalence relation *)
Lemma eq_AType_refl : forall {n} (A : AType n), A ≡ A.
Proof. intros n A. 
       unfold eq_AType. easy.
Qed.

Lemma eq_AType_sym : forall {n} (A B : AType n), A ≡ B -> B ≡ A.
Proof. intros n A B H. 
       unfold eq_AType in *.
       symmetry. easy. 
Qed.

Lemma eq_AType_trans : forall {n} (A B C : AType n),
    A ≡ B -> B ≡ C -> A ≡ C.
Proof.
  intros n A B C HAB HBC.
  unfold eq_AType in *.
  transitivity (translateA B); easy.
Qed.


Add Parametric Relation n : (AType n) (@eq_AType n)
  reflexivity proved by eq_AType_refl
  symmetry proved by eq_AType_sym
  transitivity proved by eq_AType_trans
    as eq_AType_rel.


Lemma permutation_preserves_additive_types :
  forall {n} (A A' : AType n),
    Permutation A A' -> A ≡ A'.
Proof. intros n A A' H.
       unfold "≡".
  induction H; simpl; try easy;
    unfold translateA in *; simpl in *;
    try (rewrite IHPermutation1, IHPermutation2; easy);
    rewrite ! fold_left_Mplus.
  - rewrite IHPermutation; easy.
  - rewrite Mplus_assoc. symmetry. rewrite Mplus_assoc.
    assert (translate x .+ translate y = translate y .+ translate x)%M.
    { rewrite Mplus_comm; easy. }
    rewrite H; easy.
Qed.

Lemma AType_comm : forall {n} (a b : AType n) c, gScaleA c (a ++ b) ≡ gScaleA c (b ++ a).
Proof. intros n a b c.
       unfold "≡".
  induction a; simpl; try rewrite app_nil_r; try easy.
  unfold translateA in *; simpl.
  rewrite fold_left_Mplus. 
  rewrite IHa. clear IHa.
  induction b; simpl; rewrite fold_left_Mplus; try easy.
  rewrite fold_left_Mplus.
  rewrite <- IHb. clear IHb.
  rewrite ! Mplus_assoc.
  assert (translate (gScaleT c a1) .+ translate (gScaleT c a) = translate (gScaleT c a) .+ translate (gScaleT c a1))%M.
  { rewrite Mplus_comm. easy. }
  rewrite H.
  easy.
Qed.

Lemma translateA_app_equiv : forall {n} (a b c : AType n),
    a ++ b ≡ c <-> ((translateA a) .+ (translateA b))%M = translateA c.
Proof. intros n a b c. unfold "≡", translateA in *.
       split; intros H;
         [rewrite map_app in H | rewrite map_app];
         [rewrite fold_left_Mplus_app_Zero in H | rewrite fold_left_Mplus_app_Zero];
         assumption. 
Qed.

Lemma gAddA_comm : forall {n} (a b : AType n) c, gScaleA c (gAddA a b) ≡ gScaleA c (gAddA b a).
Proof. intros n a b.
       unfold gAddA.
       apply AType_comm.
Qed.

Lemma gMulA_is_gMulA' : forall {n} (a b : AType n), gMulA a b ≡ gMulA' a b.
Proof.
  intros n a b.
  unfold gMulA, gMulA'.
  induction a.
  - induction b.
    + reflexivity.
    + simpl. easy.
  - rewrite translateA_app_equiv.
    rewrite IHa. clear IHa.
    induction b.
    + compute. autorewrite with R_db. reflexivity.
    + simpl.
      unfold translateA in *. simpl in *. rewrite ! map_app in *. rewrite ! map_map in *.
      rewrite ! fold_left_Mplus. rewrite Mplus_assoc.
      assert ((translate (gMulT a a1)
                 .+ fold_left Mplus
                 (map (fun x : TType n => translate (gMulT x a1)) a0 ++
                    map translate (gMulA' a0 b)) Zero)
              =
                (fold_left Mplus
                  (map (fun x : TType n => translate (gMulT x a1)) a0 ++
                     map translate (gMulA' a0 b)) Zero) .+  translate (gMulT a a1) )%M.
      { rewrite Mplus_comm. easy. }
      setoid_rewrite H.
      rewrite ! fold_left_Mplus_app_Zero.
      rewrite <- ! Mplus_assoc.
      assert (fold_left Mplus (map (fun x : TType n => translate (gMulT a x)) b) Zero
                .+ fold_left Mplus (map (fun x : TType n => translate (gMulT x a1)) a0) Zero
              =
                fold_left Mplus (map (fun x : TType n => translate (gMulT x a1)) a0) Zero
                  .+ fold_left Mplus (map (fun x : TType n => translate (gMulT a x)) b) Zero)%M.
      { rewrite Mplus_comm. easy. }
      rewrite H0. unfold gMulA'.
      unfold translateA in IHb.
      f_equal. rewrite Mplus_assoc. rewrite IHb.
      reflexivity.
Qed.

Lemma gTensorA_is_gTensorA' : forall {n m} (a : AType n) (b : AType m),
    gTensorA a b ≡ gTensorA' a b.
Proof. intros n m a b. 
  induction a.
  - induction b.
    + reflexivity.
    + simpl. easy. 
  - simpl.
    rewrite translateA_app_equiv with (a:=map (fun x : TType n => gTensorT a x) b) (b:=gTensorA a0 b) (c:=gTensorA' (a :: a0) b). unfold "≡" in IHa. rewrite IHa at 1. clear IHa.
    induction b.
    + compute. autorewrite with R_db. reflexivity.
    + simpl.
      unfold translateA in *. simpl. rewrite ! map_app in *. rewrite ! map_map in *.
      rewrite ! fold_left_Mplus. rewrite Mplus_assoc.
      assert ((translate (gTensorT a a1)
                 .+ fold_left Mplus
            (map (fun x : TType n => translate (gTensorT x a1)) a0 ++
                map translate (gTensorA' a0 b)) Zero)
             =
               (fold_left Mplus
            (map (fun x : TType n => translate (gTensorT x a1)) a0 ++
               map translate (gTensorA' a0 b)) Zero)
                 .+ translate (gTensorT a a1))%M.
      { rewrite Mplus_comm. easy. }
      setoid_rewrite H.
      rewrite ! fold_left_Mplus_app_Zero.
      setoid_rewrite Mplus_assoc at 2.
      setoid_rewrite <- IHb.
      assert (fold_left Mplus (map (fun x : TType n => translate (gTensorT x a1)) a0) Zero
                .+ fold_left Mplus (map (fun x : TType n => translate (gTensorT a x)) b) Zero
              =
                fold_left Mplus (map (fun x : TType n => translate (gTensorT a x)) b) Zero
                  .+ fold_left Mplus (map (fun x : TType n => translate (gTensorT x a1)) a0) Zero)%M.
      { rewrite Mplus_comm. easy. }
      rewrite <- ! Mplus_assoc.
      symmetry.
      setoid_rewrite H0.
      rewrite -> ! Mplus_assoc.
      reflexivity.
Qed.




(** G : equivalently, Cap&Cup: pointwise **)
Inductive eq_Predicate {n} : Predicate n -> Predicate n -> Prop :=
| G_eq : forall a b : AType n, translateA a = translateA b -> eq_Predicate (G a) (G b)
| Cap_eq : forall T1 T'1 T2 T'2 : Predicate n, T1 = T'1 -> T2 = T'2 -> eq_Predicate (Cap T1 T2) (Cap T'1 T'2)
| Arr_eq : forall T1 T'1 T2 T'2 : Predicate n, T1 = T'1 -> T2 = T'2 -> eq_Predicate (Cup T1 T2) (Cup T'1 T'2)
| Err_eq : eq_Predicate Err Err.



(* Declare Scope Predicate_scope.
Delimit Scope Predicate_scope with P. *)
Open Scope Predicate_scope.
Infix "≡" := eq_Predicate (at level 70, no associativity): Predicate_scope.

(* will now show this is an equivalence relation *)
Lemma eq_Predicate_refl : forall {n} (A : Predicate n), A ≡ A.
Proof. intros n A. destruct A; constructor; easy.
Qed.

Lemma eq_Predicate_sym : forall {n} (A B : Predicate n), A ≡ B -> B ≡ A.
Proof. intros n A B H. destruct A, B; inversion H; try discriminate; try constructor; try easy.
Qed.

Lemma eq_Predicate_trans : forall {n} (A B C : Predicate n),
    A ≡ B -> B ≡ C -> A ≡ C.
Proof.
  intros n A B C HAB HBC.
  destruct A, B, C; inversion HAB; inversion HBC; subst;
    try discriminate; try constructor; try easy.
    try (transitivity (translateA a0); easy).
Qed.


Add Parametric Relation n : (Predicate n) (@eq_Predicate n)
  reflexivity proved by eq_Predicate_refl
  symmetry proved by eq_Predicate_sym
  transitivity proved by eq_Predicate_trans
    as eq_Predicate_rel.





Lemma AType_Predicate_equiv_compat : forall{n} (A A' : AType n),
    (A ≡ A')%A -> (G A ≡ G A')%P.
Proof. intros n A A' H.
       unfold "≡"%A in *.
       constructor.
       assumption.
Qed.
       
Add Parametric Morphism (n : nat) : G
  with signature @eq_AType n ==> @eq_Predicate n as AType_Predicate_mor.
Proof.
  intros.
  apply AType_Predicate_equiv_compat; easy.
Qed.


Lemma add_comm : forall {n} (A A' : Predicate n) c, c ·' (A +' A') ≡ c ·' (A' +' A).
Proof. intros n A A' c.    
  destruct A, A'; simpl; try easy.
  constructor. apply gAddA_comm.
Qed.



#[export] Hint Resolve add_comm : base_types_db.
#[export] Hint Resolve add_comm : typing_db.
















(** 
Definition a1' : AType 2 := (Ci, gZ :: gI :: nil) :: nil.
Definition a2' : AType 2 := (Ci, gI :: gX :: nil) ::  (Ci, gY :: gZ :: nil) :: nil.
Definition a3' : AType 3 :=  (C1+Ci, gI :: gX :: gZ :: nil) :: (Ci, gY :: gZ :: gY :: nil) :: (Ci, gY :: gX :: gZ :: nil) :: nil.
Definition a4' : AType 3 := (C1, gY :: gY :: gX :: nil) :: nil.
Example test :  gMulA' (gTensorA' a1' a3') (gTensorA' a2' a4') = gTensorA (gMulA a1' a2') (gMulA a3' a4').
Proof. compute. replace R0 with 0 by lra. autorewrite with R_db. reflexivity. Qed.
***)



       
(*** Admitted ***)
(*
Lemma gMulA_gTensorA_dist : forall {n m : nat} (a1 a2 : AType n) (a3 a4 : AType m),
  WF_AType n a1 -> WF_AType n a2 -> WF_AType m a3 -> WF_AType m a4 -> 
  (gMulA (gTensorA a1 a3) (gTensorA a2 a4) ≡ gTensorA (gMulA a1 a2) (gMulA a3 a4))%A.
Proof. intros. unfold "≡"%A.


  (* rewrite gMulA_is_gMulA'. rewrite 2 gTensorA_is_gTensorA'. *)

  
  (* induction a1; simpl; try easy.
  
  - simpl. induction a4.
    + simpl. reflexivity.
    + induction a3.
      * simpl in *. rewrite <- gMulA_is_gMulA' in *. simpl. reflexivity.
      * rewrite <- gTensorA_is_gTensorA'. rewrite <- gMulA_is_gMulA'
      *)
  


  
  induction H. (*
  - simpl. rewrite ! app_nil_r. induction H2; simpl;  repeat (rewrite ! gMulA_is_gMulA'; rewrite ! gTensorA_is_gTensorA'; simpl); try rewrite ! app_nil_r. 
    admit.
  - simpl. *)

    induction H0; induction H1; induction H2; simpl in *; try easy. 
-
  
  16 : { clear IHWF_AType2. clear IHWF_AType1. clear IHWF_AType0.
         f_equal. apply (@gMulT_gTensorT_dist n m _ _ _ _); try easy; try constructor; try easy. rewrite ! map_app, ! map_map, <- ! app_assoc in *. f_equal. clear IHWF_AType.
         induction H6. simpl. f_equal. apply (@gMulT_gTensorT_dist n m _ _ _ _); try easy; try constructor; try easy.
         simpl. rewrite IHWF_AType. f_equal. apply (@gMulT_gTensorT_dist n m _ _ _ _); try easy; try constructor; try easy.


         f_equal.
         unfold gMulA.

         rewrite IHWF_AType. 
         f_equal.  f_equal. 



         (map (fun x : TType (n + m) => gMulT (gTensorT a a1) x) (gTensorA b0 (a2 :: b2))
              
   ++ gMulA (map (fun x : TType n => gTensorT a x) b1 ++ gTensorA b (a1 :: b1))
       (gTensorT a0 a2
          :: map (fun x : TType n => gTensorT a0 x) b2 ++ gTensorA b0 (a2 :: b2))) =
                                                                                
           (map (fun x : TType n => gTensorT (gMulT a a0) x) (gMulA b1 (a2 :: b2))
                
   ++ gTensorA (map (fun x : TType n => gMulT a x) b0 ++ gMulA b (a0 :: b0))
       (gMulT a1 a2 :: map (fun x : TType m => gMulT a1 x) b2 ++ gMulA b1 (a2 :: b2)))
*)



(***************************************************************************)
(* proving some preliminary lemmas on the TType level before we prove their 
                    counterparts on the Predicate level *)
(***************************************************************************)


Lemma gMulT_gTensorT_dist : forall {n m : nat} (t1 t2 : TType n) (t3 t4 : TType m),
    proper_length_TType n t1 -> proper_length_TType n t2 ->
    proper_length_TType m t3 -> proper_length_TType m t4 ->
  gMulT (gTensorT t1 t3) (gTensorT t2 t4) = gTensorT (gMulT t1 t2) (gMulT t3 t4).
Proof. intros. 
       destruct t1; destruct t2; destruct t3; destruct t4. 
       simpl gTensorT.
       inversion H; inversion H0; inversion H1; inversion H2. 
       simpl in *.
       bdestruct_all. simpl. 
       apply injective_projections; simpl. 
  - rewrite (Cmult_assoc).
    rewrite (Cmult_comm).
    symmetry.
    rewrite (Cmult_assoc).
    rewrite (Cmult_comm).
    rewrite (Cmult_comm ( c * c0 ) (cBigMul (zipWith gMul_Coef l l0))).
    rewrite (Cmult_assoc ).
    
    rewrite (Cmult_assoc (cBigMul (zipWith gMul_Coef l1 l2)) (cBigMul (zipWith gMul_Coef l l0)) (c * c0)).
    rewrite (Cmult_comm ( cBigMul (zipWith gMul_Coef l1 l2)) (cBigMul (zipWith gMul_Coef l l0))).
    rewrite (cBigMul_app).
    rewrite (zipWith_app_product _ n); try easy.
    rewrite <- 4 (Cmult_assoc).
    assert (c0 * (c1 * c2) = c1 * (c0 * c2)). { lca. }
    rewrite H11. reflexivity.
  - rewrite (zipWith_app_product _ n); try easy.
Qed.
     
Lemma gMulT_assoc : forall (n : nat) (t1 t2 t3 : TType n),
  proper_length_TType n t1 -> proper_length_TType n t2 -> proper_length_TType n t3 ->
  gMulT (gMulT t1 t2) t3 = gMulT t1 (gMulT t2 t3).
Proof. intros n t1 t2 t3 H H0 H1.
  induction n; [| destruct n].
  - inversion H; inversion H0; inversion H1.
    destruct t1; destruct t2; destruct t3.
    destruct l; destruct l0; destruct l1; try easy.
  - inversion H; inversion H0; inversion H1.
    destruct t1; destruct t2; destruct t3.
    destruct l; destruct l0; destruct l1; try easy.
    simpl in H3; simpl in H5; simpl in H7.
    apply Nat.succ_inj in H3;
      apply Nat.succ_inj in H5;
      apply Nat.succ_inj in H7.
    rewrite length_zero_iff_nil in *.
    rewrite H3, H5, H7.
    simpl. unfold cBigMul, zipWith, gMul_Coef, uncurry; induction p, p0, p1; apply injective_projections; simpl; try easy; try lca.
  - destruct t1, t2, t3.
    destruct l, l0, l1; inversion H; inversion H0; inversion H1.
    1-7 : simpl in *; try discriminate.
    simpl in H3; simpl in H5; simpl in H7.
         apply Nat.succ_inj in H3;
         apply Nat.succ_inj in H5;
           apply Nat.succ_inj in H7.
         repeat rewrite gMulT_reduce; try easy.
         assert (H9 : (c1, p1 :: l1) = @gTensorT 1 n (C1, [p1]) (c1, l1)).
         { simpl. bdestruct_all. apply injective_projections; simpl; try easy. lca. }
         assert (H10 : (c, p :: l) = @gTensorT 1 n (C1, [p]) (c, l)).
         { simpl. bdestruct_all. apply injective_projections; simpl; try easy. lca. }
         rewrite H9, H10. 
         do 2 replace (S n) with (1 + n)%nat by lia.
         pose (@gMulT_gTensorT_dist 1 (S n) (gMul_Coef p p0, [gMul_base p p0])  (C1, [p1]) (gMulT (c, l) (c0, l0)) (c1, l1)) as e; rewrite e at 1.
         pose (@gMulT_gTensorT_dist 1 (S n) (C1, [p]) (gMul_Coef p0 p1, [gMul_base p0 p1]) (c, l) (gMulT (c0, l0) (c1, l1))) as w; rewrite w at 1.
         all : try easy.
         rewrite IHn; try easy.
         assert (H11 : (@gMulT 1 (gMul_Coef p p0, [gMul_base p p0]) (C1, [p1])) = 
                      (@gMulT 1 (C1, [p]) (gMul_Coef p0 p1, [gMul_base p0 p1]))).
         { destruct p; destruct p0; destruct p1; compute; autorewrite with R_db; replace R0 with 0 by lra; autorewrite with R_db; try easy. }
         rewrite H11; easy. 
         all : simpl; bdestruct_all; try constructor; simpl. 
         all : try rewrite (zipWith_len_pres _ (S n)); try easy.
Qed.

Lemma gMulT_assoc_map : forall {n} (a a0 : TType n) (b : AType n),
    proper_length_AType n b -> proper_length_TType n a -> proper_length_TType n a0 ->
    map (fun x : TType n => gMulT (gMulT a a0) x) b = map (fun x : TType n => gMulT a (gMulT a0 x)) b.
Proof. intros n a a0 b H H0 H1.
  induction H.
  - simpl. rewrite gMulT_assoc; try easy.
  - simpl. rewrite gMulT_assoc; try easy. rewrite IHproper_length_AType; easy.
Qed.


Lemma gMulA_map_app : forall {n} (b b0 b1 b2 : AType n) (a : TType n),
    proper_length_AType n b -> proper_length_AType n b0 ->
    proper_length_AType n b1 -> proper_length_AType n b2 ->
    proper_length_TType n a ->
    gMulA (map (fun x : TType n => gMulT a x) b0 ++ gMulA b b1) b2
    = (map (fun x : TType n => gMulT a x) (gMulA b0 b2) ++ gMulA (gMulA b b1) b2).
Proof. intros n b b0 b1 b2 a H H0 H1 H2 H3. 
  induction H0.
  - simpl. rewrite <- app_nil_end. rewrite map_map.
    rewrite gMulT_assoc_map; try easy.
  - simpl. rewrite map_app. rewrite map_map. rewrite IHproper_length_AType. rewrite app_assoc.
    rewrite gMulT_assoc_map; try easy.
Qed. 

Lemma gMulA_assoc : forall (n : nat) (a1 a2 a3 : AType n),
  proper_length_AType n a1 -> proper_length_AType n a2 -> proper_length_AType n a3 ->
  gMulA (gMulA a1 a2) a3 = gMulA a1 (gMulA a2 a3).
Proof. intros n a1 a2 a3 H H0 H1.
  induction H; induction H0; induction H1; simpl in *; rewrite gMulT_assoc; try rewrite IHproper_length_AType; try easy. 
  + rewrite map_app. rewrite map_map. rewrite <- 2 app_nil_end.
    rewrite gMulT_assoc_map; try easy.
  + rewrite <- app_nil_end in *. rewrite map_map.
    rewrite gMulT_assoc_map; try easy.
  + rewrite <- IHproper_length_AType.
    rewrite gMulA_map_app; try easy; try constructor; try easy.
  + rewrite <- IHproper_length_AType. rewrite gMulA_map_app; try easy; try constructor; try easy. 
    rewrite map_app. rewrite map_map. rewrite app_assoc. rewrite gMulT_assoc_map; try easy.
Qed.


(* Multiplication laws *)

Lemma mul_assoc : forall {n} (A B C : Predicate n), 
    proper_length_APredicate A -> proper_length_APredicate B ->
    proper_length_APredicate C -> 
    A *' (B *' C) = A *' B *' C. 
Proof. intros. 
       destruct A; destruct B; destruct C; try easy.
       inversion H; inversion H0; inversion H1.
       unfold mul. f_equal.
       rewrite gMulA_assoc; easy. 
Qed.


Lemma mul_I_l : forall (A : Predicate 1), proper_length_APredicate A -> pI *' A = A.
Proof. intros A H.
  inversion H. 
  destruct A; try easy.
  inversion H0; inversion H1; subst.
  - clear H. clear H0. clear H1.
    simpl. f_equal. destruct t. 
    inversion H2. f_equal. simpl in *.
    destruct l. inversion H0.
    inversion H0. rewrite length_zero_iff_nil in H3.
    subst. f_equal. lca. 
  - clear H. clear H0. clear H1.
    simpl. f_equal. rewrite <- app_nil_end.
    destruct t.
    destruct H2. simpl in *.
    destruct l.
    + inversion H0.
    + inversion H0.
      rewrite length_zero_iff_nil in H2. subst.
      f_equal.
      * f_equal. lca.
      * simpl.
        induction H3.
        -- simpl. destruct t. f_equal.
           destruct H1. simpl in *.
           destruct l.
           ++ inversion H2.
           ++ inversion H2.
              rewrite length_zero_iff_nil in H4. subst.
              f_equal. lca.
        -- simpl. f_equal; auto.
           destruct t. destruct H1.
           simpl in *. destruct l.
           ++ inversion H2.
           ++ inversion H2. rewrite length_zero_iff_nil in H5. subst.
              f_equal. lca.
Qed.

Lemma mul_I_r : forall (A : Predicate 1), proper_length_APredicate A -> A *' pI = A.
Proof. intros A H.
  inversion H. 
  destruct A; try easy.
  inversion H0; inversion H1; subst.
  - clear H. clear H0. clear H1.
    simpl. f_equal. destruct t. 
    inversion H2. f_equal. simpl in *.
    destruct l. inversion H0.
    inversion H0. rewrite length_zero_iff_nil in H3.
    subst. destruct p; f_equal; lca. 
  - clear H. clear H0. clear H1.
    simpl. do 2 f_equal.
    + destruct t. simpl.
      destruct H2. simpl in *.
      destruct l.
      * inversion H0.
      * inversion H0.
        rewrite length_zero_iff_nil in H2. subst.
        destruct p; f_equal; lca.
    + induction H3; simpl in *.
      * destruct t0. destruct H.
        simpl in *. destruct l.
        -- inversion H0.
        -- inversion H0.
           rewrite length_zero_iff_nil in H3. subst.
           f_equal. destruct p; f_equal; lca.
      * f_equal; auto.
        destruct t0. destruct H.
        simpl in *. destruct l.
        -- inversion H0.
        -- inversion H0.
           rewrite length_zero_iff_nil in H4. subst.
           destruct p; f_equal; lca.
Qed.

Lemma Xsqr : pX *' pX = pI.
Proof. simpl. unfold zipWith, cBigMul, gMul_Coef, uncurry. simpl. unfold I.
  do 3 f_equal. unfold pI. repeat f_equal. lca. Qed.       

Lemma Zsqr : pZ *' pZ = pI.
Proof. simpl. unfold zipWith, cBigMul, gMul_Coef, uncurry. simpl. unfold I.
  do 3 f_equal. unfold pI. repeat f_equal. lca. Qed.

Lemma ZmulX : pZ *' pX = - (pX *' pZ).
Proof. simpl. do 3 f_equal.
  unfold zipWith, cBigMul, gMul_Coef, uncurry.  simpl. lca. Qed.



Lemma switch_neg : forall n (A : Predicate n) (c : Coef), - (c ·' A) = c ·' (- A).
  intros n A c.
  induction A; simpl; try rewrite IHA1, IHA2; try easy.
  f_equal. unfold gScaleA. rewrite 2 map_map. f_equal.
  apply functional_extensionality. intros x. destruct x.
  simpl. f_equal. lca.
Qed.


Lemma neg_inv : forall (n : nat) (A : Predicate n), APredicate A -> - - A = A.
Proof. intros n A H.
  destruct H.
  unfold "-"%P.
  f_equal.
  unfold gScaleA.
  rewrite map_map.
  unfold gScaleT.
  induction a; auto.
  simpl.
  rewrite IHa. f_equal.
  destruct a.
  f_equal.
  lca.
Qed.


Lemma gMulT_gScaleT_map : forall {n} (a : TType n) (b : AType n),
    proper_length_TType n a -> proper_length_AType n b ->
    (map (fun x : TType n => gMulT (gScaleT (- C1)%C a) x) b)
    = (map (fun x : TType n => gScaleT (- C1)%C (gMulT a x)) b).
Proof. intros n a b H H0. induction H0.
  - simpl. f_equal. destruct a, t. simpl. f_equal. lca.
  - simpl. rewrite IHproper_length_AType. f_equal. destruct a, t. simpl. f_equal. lca.
Qed.

Lemma neg_dist_l : forall (n : nat) (A B : Predicate n), 
  APredicate A -> APredicate B -> 
  -A *' B = - (A *' B).
Proof. intros. 
  inversion H; inversion H0; subst.
  simpl. f_equal. apply gMulA_gScaleA_l.
Qed.


Lemma neg_dist_r : forall (n : nat) (A B : Predicate n), 
  proper_length_APredicate A -> proper_length_APredicate B -> 
  A *' (-B) = - (A *' B).
Proof. intros. 
  inversion H; inversion H0; subst.
  simpl. f_equal. apply gMulA_gScaleA_r.
Qed.

Lemma neg_dist_add : forall (n : nat) (A B : Predicate n), - (A +' B) = -A +' -B.
Proof. intros n A B.
  induction A; induction B; simpl; try easy.
  f_equal. unfold gScaleA, gAddA.
  rewrite <- map_app. f_equal.
Qed. 

Lemma i_sqr : forall (n : nat) (A : Predicate n), i (i A) = -A.
Proof. intros. 
  induction A; try easy. 
  - destruct a.
    + unfold i. simpl. easy.
    + unfold i. simpl. do 2  f_equal.
      * destruct t. simpl. f_equal. lca.
      * unfold gScaleA. rewrite map_map.
        induction a.
        -- simpl. easy.
        -- simpl. rewrite IHa. f_equal. destruct a. simpl. f_equal. lca.
  Qed.

Lemma i_dist_l : forall (n : nat) (A B : Predicate n), 
  proper_length_APredicate A -> proper_length_APredicate B -> 
  i A *' B = i (A *' B).
Proof. intros. 
  inversion H; inversion H0; subst.
  simpl. f_equal. apply gMulA_gScaleA_l.
Qed.

Lemma i_dist_r : forall (n : nat) (A B : Predicate n), 
  proper_length_APredicate A -> proper_length_APredicate B -> 
  A *' i B = i (A *' B).
Proof. intros. 
  inversion H; inversion H0; subst.
  simpl. f_equal. apply gMulA_gScaleA_r.
Qed.

Lemma i_neg_comm : forall (n : nat) (A : Predicate n), i (-A) = -i A.
Proof. intros.
  induction A; try easy. 
  - destruct a.
    + unfold i. simpl. easy.
    + unfold i. simpl. unfold gScaleA. rewrite ! map_map. do 2 f_equal.
      * destruct t. simpl. f_equal. lca.
      * induction a.
        -- simpl. easy.
        -- simpl. rewrite IHa. f_equal. destruct a. simpl. f_equal. lca.
Qed.


#[export] Hint Resolve switch_neg neg_inv neg_dist_add i_sqr i_neg_comm : typing_db.
#[export] Hint Rewrite switch_neg neg_inv neg_dist_add i_sqr i_neg_comm : typing_db.



(** ** Tensor Laws *)


Lemma gTensorT_assoc : forall {n : nat} (t1 t2 t3 : TType n),
  proper_length_TType n t1 -> proper_length_TType n t2 -> proper_length_TType n t3 ->
  gTensorT (gTensorT t1 t2) t3 = gTensorT t1 (gTensorT t2 t3).
Proof. intros n t1 t2 t3 H H0 H1.
  unfold gTensorT. destruct t1, t2, t3. f_equal. lca. rewrite app_assoc. easy.
Qed.


Lemma gTensorA_assoc_map : forall {n} (a : TType n) (b b0 b1 b2 : AType n),
    proper_length_TType n a -> proper_length_AType n b  -> proper_length_AType n b0  -> proper_length_AType n b1  -> proper_length_AType n b2 ->
    gTensorA (map (fun x : TType n => gTensorT a x) b0 ++ gTensorA b b1) b2 =
      (map (fun x : TType n => gTensorT a x) (gTensorA b0 b2) ++ gTensorA (gTensorA b b1) b2).
Proof. intros n a b b0 b1 b2 H H0 H1 H2 H3.
  induction H1; simpl.
  - rewrite <- app_nil_end. f_equal. rewrite map_map. induction H3; simpl; try rewrite IHproper_length_AType; f_equal; destruct a, t, t0; simpl; f_equal; try lca; rewrite app_assoc; easy.
  - rewrite map_app, map_map. rewrite IHproper_length_AType, <- app_assoc. f_equal.
    clear IHproper_length_AType. induction H3; simpl; try rewrite IHproper_length_AType; f_equal; destruct a, t, t0; simpl; f_equal; try lca; rewrite app_assoc; easy.
Qed.


Lemma gTensorA_assoc : forall (n : nat) (a1 a2 a3 : AType n),
  proper_length_AType n a1 -> proper_length_AType n a2 -> proper_length_AType n a3 ->
  gTensorA (gTensorA a1 a2) a3 = gTensorA a1 (gTensorA a2 a3).
Proof. intros n a1 a2 a3 H H0 H1. 
  induction H; induction H0; induction H1; simpl in *; f_equal; try apply (gTensorT_assoc t t0 t1); try rewrite IHproper_length_AType; try easy; repeat rewrite <- app_nil_end in *; try rewrite map_app; try rewrite map_map.
  1,2: f_equal; clear IHproper_length_AType; clear IHproper_length_AType0; induction H3; simpl; try rewrite IHproper_length_AType; f_equal; destruct t, t0, t2; simpl; f_equal; try lca; repeat rewrite app_assoc; easy.
  + rewrite <- IHproper_length_AType. rewrite gTensorA_assoc_map; try easy; constructor; easy.
  + clear IHproper_length_AType1. clear IHproper_length_AType0.
    rewrite <- IHproper_length_AType. rewrite <- app_assoc. f_equal.
    * clear IHproper_length_AType; induction H4; simpl; try rewrite IHproper_length_AType; f_equal; destruct t, t0, t2; simpl; f_equal; try lca; rewrite app_assoc; easy.
    * rewrite gTensorA_assoc_map; try easy; constructor; easy.
Qed.


Lemma neg_tensor_dist_l : forall {n m} (A : Predicate n) (B : Predicate m), 
  proper_length_APredicate A -> proper_length_APredicate B -> 
  -A ⊗' B = - (A ⊗' B).
Proof. intros.
  inversion H; inversion H0; subst.
  simpl. f_equal. apply gTensorA_gScaleA_comm_l.
Qed.

Lemma neg_tensor_dist_r : forall {n m} (A : Predicate n) (B : Predicate m), 
  proper_length_APredicate A -> proper_length_APredicate B -> 
  A ⊗' (-B) = - (A ⊗' B).
Proof. intros. 
  inversion H; inversion H0; subst.
  simpl. f_equal. apply gTensorA_gScaleA_comm_r.
Qed.

Lemma i_tensor_dist_l : forall {n m} (A : Predicate n) (B : Predicate m), 
  proper_length_APredicate A -> proper_length_APredicate B -> 
  i A ⊗' B = i (A ⊗' B).
Proof. intros.
  inversion H; inversion H0; subst.
  simpl. f_equal. apply gTensorA_gScaleA_comm_l.
Qed.

Lemma i_tensor_dist_r : forall {n m} (A : Predicate n) (B : Predicate m), 
  proper_length_APredicate A -> proper_length_APredicate B -> 
  A ⊗' i B = i (A ⊗' B).
Proof. intros. 
  inversion H; inversion H0; subst.
  simpl. f_equal. apply gTensorA_gScaleA_comm_r.
Qed. 

(*** Not Derivable ***)
(*
(** **Multiplication & Tensor Laws *)

(* Appropriate restriction is that size A = size C and size B = size D,
   but axiomatization doesn't allow for that calculation. *)
(* This should be generalizable to the other, assuming we're multiplying
   valid types. *)
Lemma mul_tensor_dist : forall {n m} (A C : Predicate n) (B D : Predicate m),
  proper_length_APredicate A -> proper_length_APredicate B -> proper_length_APredicate C -> proper_length_APredicate D ->
  (A ⊗' B) *' (C ⊗' D) = (A *' C) ⊗' (B *' D).
Proof. intros.
       destruct A; destruct B; destruct C; destruct D; try easy.
       inversion H; inversion H0; inversion H1; inversion H2; subst.
       simpl. f_equal. Admitted.
Qed.



Lemma decompose_tensor : forall (A B : Predicate 1),
  proper_length_APredicate A -> proper_length_APredicate B ->
  A .⊗ B = (A .⊗ I) .* (I .⊗ B).
Proof.
  intros A B H H0.  
  rewrite mul_tensor_dist; auto with wfpt_db.
  rewrite mul_I_r, mul_I_l; easy.
Qed.


Lemma decompose_tensor_mult_l : forall (A B : Predicate 1),
  proper_length_APredicate A -> proper_length_APredicate B ->
  (A .* B) .⊗ I = (A .⊗ I) .* (B .⊗ I).
Proof.
  intros. 
  rewrite mul_tensor_dist; auto with wfpt_db.
Qed.


Lemma decompose_tensor_mult_r : forall (A B : Predicate 1),
  proper_length_APredicate A -> proper_length_APredicate B ->
  I .⊗ (A .* B) = (I .⊗ A) .* (I .⊗ B).
Proof.
  intros. 
  rewrite mul_tensor_dist; auto with wfpt_db.
Qed.
 
 *)

(*********************)
(* defining programs *)
(*********************)


Inductive prog :=
| H (n : nat)
| S (n : nat)
| T (n : nat)
| CNOT (n1 n2 : nat)
| seq (p1 p2 : prog).

(* denote successor as s instead of S since it overlaps with the S gate *)
Notation s := Datatypes.S.

(*** I & Paulis can be derived ***)

Infix ";;" := seq (at level 51, right associativity).

Fixpoint translate_prog (prg_len : nat) (p : prog) : Square (2^prg_len) :=
  match p with 
  | H n => (prog_simpl_app prg_len hadamard n)
  | S n => (prog_simpl_app prg_len Sgate n)
  | T n => (prog_simpl_app prg_len Tgate n)
  | CNOT n1 n2 => (prog_ctrl_app prg_len σx n1 n2)
  | seq p1 p2 => (translate_prog prg_len p2) × (translate_prog prg_len p1)
  end.

Lemma unit_prog : forall (prg_len : nat) (p : prog), 
  WF_Unitary (translate_prog prg_len p).
Proof. intros. induction p as [ | | | | ];
       try (apply unit_prog_simpl_app; auto with unit_db);
       try (apply unit_prog_ctrl_app; auto with unit_db);
       simpl. apply Mmult_unitary; easy.
Qed.


Lemma WF_Matrix_translate_prog : forall (n : nat) (p : prog),
    WF_Matrix (translate_prog n p).
Proof.
  intros n p.
  induction p; simpl.
  all : unfold prog_simpl_app; unfold prog_ctrl_app;
    try bdestruct_all; simpl; auto 15 with wf_db.
Qed.

#[export] Hint Resolve unit_prog : unit_db.
#[export] Hint Resolve WF_Matrix_translate_prog : wf_db.



Definition simpl_prog_H (p : nat -> prog) : Prop := 
  (forall (n : nat), p n = H n).

Definition simpl_prog_S (p : nat -> prog) : Prop := 
  (forall (n : nat), p n = S n).

Definition simpl_prog_T (p : nat -> prog) : Prop := 
  (forall (n : nat), p n = T n).
        
Definition simpl_prog (p : nat -> prog) : Prop := 
  simpl_prog_H p \/ simpl_prog_S p \/ simpl_prog_T p.

Definition simpl_prog' (p : prog) : Prop := 
  match p with
  | H _ => True
  | S _ => True
  | T _ => True
  | _ => False
  end.

Definition ctrl_prog (p : nat -> nat -> prog) : Prop := 
  (forall (n m : nat), p n m = CNOT n m).

Definition ctrl_prog' (p : prog) : Prop :=
  match p with 
  | CNOT _ _ => True 
  | _ => False
  end.


(**************************************)
(** ** Semantical Definitions ** **)
(**************************************)

(*****************************************)
(* Defining Eigenvector Semantics *)
(*****************************************)

Definition vecSatisfies {n} (v : Vector n) (U : Square n) : Prop :=
  WF_Matrix v /\ Eigenpair U (v, C1).

Fixpoint vecSatisfiesP {n} (v : Vector (2 ^ n)) (P : Predicate n) : Prop :=
  match P with
  | G A => vecSatisfies v (translateA A)
  | Cap a b => (vecSatisfiesP v a) /\ (vecSatisfiesP v b)
  | Cup a b => (vecSatisfiesP v a) \/ (vecSatisfiesP v b)
  | Err => False
  end.

(** ** not needed?
Definition vecSatisfiesA {n} (v : Vector (2 ^ n)) (A : AType n) : Prop :=
  vecSatisfies v (translateA A).

Notation "A [[ v ]]" := (vecSatisfiesA v A) (at level 0).
Notation "P [[[ v ]]]" := (vecSatisfiesP v P) (at level 0).


Definition vecSatisfies' {n} (v : Vector n) (U : Square n) : Prop :=
  WF_Matrix v /\ exists c, Eigenpair U (v, c).

Fixpoint vecSatisfiesP' {n} (v : Vector (2 ^ n)) (P : Predicate n) : Prop :=
  match P with
  | G A => vecSatisfies' v (translateA A)
  | Cap a b => (vecSatisfiesP' v a) /\ (vecSatisfiesP' v b)
  | Cup a b => (vecSatisfiesP' v a) \/ (vecSatisfiesP' v b)
  | Err => False
  end. 


Definition pairSatisfies {n} (p : Vector n * Coef) (U : Square n) : Prop :=
  WF_Matrix (fst p) /\ Eigenpair U p.

Fixpoint pairSatisfiesP {n} (p : Vector (2 ^ n) * Coef) (P : Predicate n) : Prop :=
  match P with
  | G A => pairSatisfies p (translateA A)
(** ** what to do for cap?? does a and b must have the same eigenvalue? ** **)
  | Cap a b => (pairSatisfiesP p a) /\ (pairSatisfiesP p b) 
  | Cup a b => (pairSatisfiesP p a) \/ (pairSatisfiesP p b)
  | Err => False
  end. 

*)

(** ** triples ** **)

Definition triple {n} (A : Predicate n) (g : prog) (B : Predicate n) :=
  forall (v : Vector (2 ^ n)), vecSatisfiesP v A -> vecSatisfiesP ((translate_prog n g) × v) B.


(** ** not needed?
(** A [[v]] := vecSatisfiesA v A **)
Definition triple_vecA {n} (A : AType n) (g : prog) (B : AType n) :=
  forall (v : Vector (2 ^ n)), vecSatisfiesA v A -> vecSatisfiesA ((translate_prog n g) × v) B.


(** P [[[v]]] := vecSatisfiesP v P **)
Definition triple_vecP {n} (A : Predicate n) (g : prog) (B : Predicate n) :=
  forall (v : Vector (2 ^ n)), vecSatisfiesP v A -> vecSatisfiesP ((translate_prog n g) × v) B.


Definition triple_vec' {n} (A : Predicate n) (g : prog) (B : Predicate n) :=
  forall (v : Vector (2 ^ n)), vecSatisfiesP' v A -> vecSatisfiesP' ((translate_prog n g) × v) B.

Definition triple_pair {n} (A : Predicate n) (g : prog) (B : Predicate n) :=
  forall (p : Vector (2 ^ n) * Coef), pairSatisfiesP p A -> pairSatisfiesP ((translate_prog n g) × (fst p), (snd p)) B.


Inductive is_Heisenberg_triple {n} : AType n ->  prog -> AType n -> Prop :=
| Heisenberg : forall (A : AType n) (U : prog) (B : AType n),
(*    APredicate A -> APredicate B -> 
    ((translate_prog n U) × translateP A = translateP B × (translate_prog n U)) -> *)
    ((translate_prog n U) × translateA A = translateA B × (translate_prog n U)) ->
    is_Heisenberg_triple A U B
(*
| Heisenberg_neg_l : forall (A : Predicate n) (U : prog) (B : Predicate n),
    CPredicate A -> is_Heisenberg_triple A U B
| Heisenberg_neg_r : forall (A : Predicate n) (U : prog) (B : Predicate n),
    CPredicate B -> is_Heisenberg_triple A U B
| Heisenberg_Err_l : forall (U : prog) (B : Predicate n), is_Heisenberg_triple Err U B
| Heisenberg_Err_r : forall (A : Predicate n) (U : prog), is_Heisenberg_triple A U Err.
*).

Definition tripleA {n} (A : AType n) (g : prog) (B : AType n) := triple_vecA A g B /\ is_Heisenberg_triple A g B.

Notation "{{ A }} g {{ B }}" := (tripleA A g B) (at level 70, no associativity).


Definition triple {n} (A : Predicate n) (g : prog) (B : Predicate n) := triple_vecP A g B.

Notation "{{{ A }}} g {{{ B }}}" := (triple A g B) (at level 70, no associativity).
*)

Notation "{{ A }} g {{ B }}" := (triple A g B) (at level 70, no associativity).


(** ** implication rules ** **)


Reserved Infix "⇒" (at level 65, no associativity).

(** ** not needed?
Reserved Infix "⇒A" (at level 65, no associativity).
Reserved Infix "⇒P" (at level 65, no associativity).


Definition PauliPred {n} (t : TType n) :=
  let (c, l) := t in c = C1.
 *)

Inductive implies {n} : Predicate n -> Predicate n -> Prop :=
| CapElim : forall (A B : Predicate n), (Cap A B) ⇒ (A)
| CapComm : forall (A B : Predicate n), (Cap A B) ⇒ (Cap B A)
| CapAssoc1 : forall (A B C : Predicate n), (Cap A (Cap B C)) ⇒ (Cap (Cap A B) C)
| CapAssoc2 : forall (A B C : Predicate n), (Cap (Cap A B) C) ⇒ (Cap A (Cap B C))
| CupIntro : forall (A B : Predicate n), (A) ⇒ (Cup A B)
| CupComm : forall (A B : Predicate n), (Cup A B) ⇒ (Cup B A)
| CupAssoc1 : forall (A B C : Predicate n), (Cup A (Cup B C)) ⇒ (Cup (Cup A B) C)
| CupAssoc2 : forall (A B C : Predicate n), (Cup (Cup A B) C) ⇒ (Cup A (Cup B C))
| PauliMult1 : forall (T1 T2 : TType n),
    WF_TType n T1 -> WF_TType n T2 ->
    (Cap (G [T1]) (G [T2]))
      ⇒ (Cap (G [T1]) (G [gMulT T1 T2]))
| PauliMult2 : forall (T1 T2 : TType n),
    (* PauliPred T1 -> PauliPred T2 -> *)
    WF_TType n T1 -> WF_TType n T2 ->
    (Cap (G [T1]) (G [gMulT T1 T2]))
      ⇒ (Cap (G [T1]) (G [T2]))
| AddComm : forall (A B : Predicate n), (A +' B) ⇒ (B +' A)
| AddAssoc1 : forall (A B C : Predicate n), ((A +' B) +' C) ⇒ (A +' (B +' C))
| AddAssoc2 : forall (A B C : Predicate n), (A +' (B +' C)) ⇒ ((A +' B) +' C)
| AddZeroElim : forall (A B C : Predicate n), (A +' ((C0 ·' C) *' B)) ⇒ (A) 
where "x ⇒ y" := (implies x y).

(** ** not needed?
Inductive impliesA {n} : AType n -> AType n -> Prop :=
| AddCommA : forall (A B : AType n), (gAddA A B) ⇒A (gAddA B A)
| AddAssoc1A : forall (A B C : AType n), (gAddA (gAddA A B) C) ⇒A (gAddA A (gAddA B C))
| AddAssoc2A : forall (A B C : AType n), (gAddA A (gAddA B C)) ⇒A (gAddA (gAddA A B) C)
| AddZeroElimA : forall (A B C : AType n), (gAddA A (gMulA (gScaleA C0 C) B)) ⇒A (A) 
where "x ⇒A y" := (impliesA x y).



Inductive impliesP {n} : Predicate n -> Predicate n -> Prop :=
| CapElimP : forall (A B : Predicate n), (Cap A B) ⇒P (A)
| CapCommP : forall (A B : Predicate n), (Cap A B) ⇒P (Cap B A)
| CapAssoc1P : forall (A B C : Predicate n), (Cap A (Cap B C)) ⇒P (Cap (Cap A B) C)
| CapAssoc2P : forall (A B C : Predicate n), (Cap (Cap A B) C) ⇒P (Cap A (Cap B C))
| CupIntroP : forall (A B : Predicate n), (A) ⇒P (Cup A B)
| CupCommP : forall (A B : Predicate n), (Cup A B) ⇒P (Cup B A)
| CupAssoc1P : forall (A B C : Predicate n), (Cup A (Cup B C)) ⇒P (Cup (Cup A B) C)
| CupAssoc2P : forall (A B C : Predicate n), (Cup (Cup A B) C) ⇒P (Cup A (Cup B C))
| PauliMult1P : forall (T1 T2 : TType n),
    WF_TType n T1 -> WF_TType n T2 ->
    (Cap (G [T1]) (G [T2]))
      ⇒P (Cap (G [T1]) (G [gMulT T1 T2]))
| PauliMult2P : forall (T1 T2 : TType n),
    PauliPred T1 -> PauliPred T2 ->
    WF_TType n T1 -> WF_TType n T2 ->
    (Cap (G [T1]) (G [gMulT T1 T2]))
      ⇒P (Cap (G [T1]) (G [T2]))
where "x ⇒P y" := (impliesP x y).
*)



(** *** prove that the semantics are actually implications *** **)
Lemma interpret_implies {n} (A B : Predicate n) :
  A ⇒ B -> (forall v : Vector (2 ^ n), vecSatisfiesP v A -> vecSatisfiesP v B).
Proof.
  intros H0 v H1.
  destruct H0.
  - destruct H1. easy.
  - destruct H1. constructor; easy.
  - do 2 destruct H1. try do 2 constructor; easy.
  - destruct H1. destruct H0. try do 2 constructor; easy.
  - left. easy.
  - destruct H1; [right | left]; easy.
  - destruct H1.
    + left. left. easy.
    + destruct H0.
      * left. right. easy.
      * right. easy.
  - destruct H1.
    + destruct H0.
      * left. easy.
      * right. left. easy.
    + right. right. easy.
  - destruct H1.
    constructor.
    + easy.
    + constructor.
      * destruct H1. easy.
      * destruct H1. destruct H3.
        unfold Eigenpair in *. simpl in *.
        unfold translateA in *. simpl in *.
        rewrite Mplus_0_l in *.
        destruct H0, H2; simpl in *.
        destruct T1. destruct T2.
        simpl in H6, H7.
        rewrite Mscale_1_l in *.
        setoid_rewrite translate_gMulT.
        unfold translate in *. simpl in *.
        rewrite <- Mscale_assoc.
        rewrite <- Mscale_mult_dist_r.
        rewrite <- Mscale_mult_dist_l.
        show_dimensions.
        rewrite map_length.
        destruct H0, H2. simpl in *.
        rewrite H10.
        setoid_rewrite Mmult_assoc.
        setoid_rewrite H5.
        setoid_rewrite H4.
        reflexivity.
        destruct H0, H2. simpl in *.
        subst.
        assumption.
  - destruct H1.
    constructor.
    + easy.
    + destruct H3.
      unfold vecSatisfiesP in *.
      unfold vecSatisfies in *.
      destruct H1.
      split; try easy.
      unfold translateA in *.
      simpl in *.
      rewrite Mplus_0_l in *.
      unfold Eigenpair in *. simpl in *.
      rewrite Mscale_1_l in *.
      remember H0. remember H2.
      destruct H0, H2. clear Heqw Heqw0.
      rewrite translate_gMulT_split in H4; auto.
      apply @Mmult_inj_l with (i:= (2^n)%nat) (m:= translate T1) in H4.
      rewrite <- 2 Mmult_assoc in H4.
      rewrite translate_mult_inv in H4; auto.
      rewrite Mmult_1_l in H4.
      * rewrite H5 in H4; easy.
      * apply WF_Matrix_translate; auto.
  - destruct A, B; try easy.
    simpl in *.
    unfold translateA in *.
    unfold gAddA in *.
    rewrite map_app in *.
    rewrite fold_left_Mplus_app_Zero in *.
    rewrite Mplus_comm.
    assumption.
  - destruct A, B, C; try easy.
    simpl in *.
    unfold gAddA in *.
    rewrite app_assoc.
    assumption.
  - destruct A, B, C; try easy.
    simpl in *.
    unfold gAddA in *.
    rewrite <- app_assoc.
    assumption.
  - destruct A, B, C; try easy.
    simpl in *.
    unfold gAddA in *.
    unfold translateA in *.
    rewrite map_app in H1.
    rewrite fold_left_Mplus_app_Zero in H1.
    assert (fold_left Mplus (map translate (gMulA (gScaleA C0 a1) a0)) Zero = Zero).
    { clear H1. clear a.
      unfold gScaleA in *.
      unfold gScaleT in *.
      induction a1.
      - easy.
      - simpl.
        rewrite map_app.
        rewrite map_map.
        rewrite fold_left_Mplus_app_Zero.
        rewrite IHa1.
        rewrite Mplus_0_r.
        destruct a.
        rewrite Cmult_0_l.
        clear IHa1.
        induction a0.
        + easy.
        + simpl in *. rewrite fold_left_Mplus.
          rewrite IHa0.
          rewrite Mplus_0_l.
          destruct a.
          unfold translate.
          simpl.
          rewrite ! Cmult_0_l.
          rewrite Mscale_0_l.
          reflexivity. }
    rewrite H0 in H1.
    rewrite Mplus_0_r in H1.
    assumption.
Qed.

(** ** not needed?
(** *** prove that the semantics are actually implications *** **)
Lemma interpret_impliesA {n} (A B : AType n) :
  A ⇒A B -> (forall v : Vector (2 ^ n), vecSatisfiesA v A -> vecSatisfiesA v B).
Proof.
  intros H0 v H1. 
  destruct H0.
  - unfold vecSatisfiesA in *.
    unfold translateA in *.
    unfold gAddA in *.
    rewrite map_app in *.
    rewrite fold_left_Mplus_app_Zero in *.
    rewrite Mplus_comm.
    assumption.
  - unfold vecSatisfiesA in *.
    unfold gAddA in *.
    rewrite app_assoc.
    assumption.
  - unfold vecSatisfiesA in *.
    unfold gAddA in *.
    rewrite <- app_assoc.
    assumption.
  - unfold vecSatisfiesA in *.
    unfold gAddA in *.
    unfold translateA in *.
    rewrite map_app in H1.
    rewrite fold_left_Mplus_app_Zero in H1.
    assert (fold_left Mplus (map translate (gMulA (gScaleA C0 C) B)) Zero = Zero).
    { clear H1.
      unfold gScaleA in *.
      unfold gScaleT in *.
      induction C.
      - easy.
      - simpl.
        rewrite map_app.
        rewrite map_map.
        rewrite fold_left_Mplus_app_Zero.
        rewrite IHC.
        rewrite Mplus_0_r.
        destruct a.
        rewrite Cmult_0_l.
        clear IHC.
        induction B.
        + easy.
        + simpl in *. rewrite fold_left_Mplus.
          rewrite IHB.
          rewrite Mplus_0_l.
          destruct a.
          unfold translate.
          simpl.
          rewrite ! Cmult_0_l.
          rewrite Mscale_0_l.
          reflexivity. }
    rewrite H0 in H1.
    rewrite Mplus_0_r in H1.
    assumption.
Qed.

(** *** prove that the semantics are actually implications *** **)
Lemma interpret_impliesP {n} (A B : Predicate n) :
  A ⇒P B -> (forall v : Vector (2 ^ n), vecSatisfiesP v A -> vecSatisfiesP v B).
Proof.
  intros H0 v H1.
  destruct H0.
  - destruct H1. easy.
  - destruct H1. constructor; easy.
  - do 2 destruct H1. try do 2 constructor; easy.
  - destruct H1. destruct H0. try do 2 constructor; easy.
  - left. easy.
  - destruct H1; [right | left]; easy.
  - destruct H1.
    + left. left. easy.
    + destruct H0.
      * left. right. easy.
      * right. easy.
  - destruct H1.
    + destruct H0.
      * left. easy.
      * right. left. easy.
    + right. right. easy.
  - destruct H1.
    constructor.
    + easy.
    + constructor.
      * destruct H1. easy.
      * destruct H1. destruct H3.
        unfold Eigenpair in *. simpl in *.
        unfold translateA in *. simpl in *.
        rewrite Mplus_0_l in *.
        destruct H0, H2; simpl in *.
        destruct T1. destruct T2.
        simpl in H6, H7.
        rewrite Mscale_1_l in *.
        setoid_rewrite translate_gMulT.
        unfold translate in *. simpl in *.
        rewrite <- Mscale_assoc.
        rewrite <- Mscale_mult_dist_r.
        rewrite <- Mscale_mult_dist_l.
        show_dimensions.
        rewrite map_length.
        rewrite H6.
        setoid_rewrite Mmult_assoc.
        setoid_rewrite H5.
        setoid_rewrite H4.
        reflexivity.
        subst.
        assumption.
  - destruct H1.
    constructor.
    + easy.
    + destruct H5.
      unfold vecSatisfiesP in *.
      unfold vecSatisfies in *.
      destruct H1.
      split; try easy.
      unfold translateA in *.
      simpl in *.
      rewrite Mplus_0_l in *.
      unfold Eigenpair in *. simpl in *.
      rewrite Mscale_1_l in *.
      destruct T1, T2.
      setoid_rewrite translate_gMulT in H6.
      2: destruct H3, H4; simpl in *; rewrite <- H8 in H9; easy.
      unfold translate in *. simpl in *.
      rewrite <- Mscale_mult_dist_r in H6.
      assert ( (⨂ map translate_P l) × (⨂ map translate_P l) × (c * c0 .* (⨂ map translate_P l0)) × v = (⨂ map translate_P l) × v).
      { rewrite ! Mmult_assoc.  f_equal. setoid_rewrite <- Mmult_assoc. assumption. }
      setoid_rewrite Mmult_assoc in H8.
      rewrite big_kron_map_translate_P_twice in H8.
      rewrite map_length in H8.
      rewrite Mmult_1_l in H8.
      clear H6.
      2: { apply WF_mult; auto.
           rewrite map_length.
           destruct H3, H4. simpl in *. rewrite <- H10 in H9.
           rewrite H9, H10.
           apply WF_scale.
           rewrite <- H10.
           rewrite <- map_length with (f := translate_P).
           apply WF_Matrix_Big_Pauli. }
      destruct H3, H4; simpl in *.
      rewrite H6 in H8.
      rewrite H0, H2 in *.
      rewrite Cmult_1_l, Mscale_1_l in *.
      rewrite H7 in H8.
      assumption.
Qed.


(** *** prove that the semantics are actually implications *** **)
Lemma interpret_implies' {n} (A B : Predicate n) :
  A ⇒ B -> (forall v : Vector (2 ^ n), vecSatisfiesP' v A -> vecSatisfiesP' v B).
Proof.
  intros H0 v H1.
  destruct H0.
  - destruct H1. easy.
  - destruct H1. constructor; easy.
  - do 2 destruct H1. try do 2 constructor; easy.
  - destruct H1. destruct H0. try do 2 constructor; easy.
  - left. easy.
  - destruct H1; [right | left]; easy.
  - destruct H1.
    + left. left. easy.
    + destruct H0.
      * left. right. easy.
      * right. easy.
  - destruct H1.
    + destruct H0.
      * left. easy.
      * right. left. easy.
    + right. right. easy.
  - destruct H1.
    constructor.
    + easy.
    + constructor.
      * destruct H1. easy.
      * destruct H1. destruct H3.
        unfold Eigenpair in *. simpl in *.
        unfold translateA in *. simpl in *.
        rewrite Mplus_0_l in *.
        destruct H0, H2; simpl in *.
        destruct T1. destruct T2.
        simpl in H6, H7.
        setoid_rewrite translate_gMulT.
        unfold translate in *. simpl in *.
        rewrite <- Mscale_assoc.
        rewrite <- Mscale_mult_dist_r.
        rewrite <- Mscale_mult_dist_l.
        show_dimensions.
        rewrite map_length.
        rewrite H6.
        setoid_rewrite Mmult_assoc.
        destruct H4, H5.
        setoid_rewrite H5.
        rewrite Mscale_mult_dist_r.
        setoid_rewrite H4.
        rewrite Mscale_assoc.
        exists (x0 * x)%C.
        reflexivity.
        subst.
        assumption.
  - destruct H1.
    constructor.
    + easy.
    + destruct H5.
      unfold vecSatisfiesP' in *.
      unfold vecSatisfies' in *.
      destruct H1.
      split; try easy.
      unfold translateA in *.
      simpl in *.
      rewrite Mplus_0_l in *.
      unfold Eigenpair in *. simpl in *.
      destruct T1, T2.
      setoid_rewrite translate_gMulT in H6.
      2: destruct H3, H4; simpl in *; rewrite <- H8 in H9; easy.
      unfold translate in *. simpl in *.
      rewrite <- Mscale_mult_dist_r in H6.
      destruct H6, H7.
      assert ( (⨂ map translate_P l) × (⨂ map translate_P l) × (c * c0 .* (⨂ map translate_P l0)) × v = (⨂ map translate_P l) × (x .* v)).
      { rewrite ! Mmult_assoc.  f_equal. setoid_rewrite <- Mmult_assoc. assumption. }
      setoid_rewrite Mmult_assoc in H8.
      rewrite big_kron_map_translate_P_twice in H8.
      rewrite map_length in H8.
      rewrite Mmult_1_l in H8.
      clear H6.
      2: { apply WF_mult; auto.
           rewrite map_length.
           destruct H3, H4. simpl in *. rewrite <- H10 in H9.
           rewrite H9, H10.
           apply WF_scale.
           rewrite <- H10.
           rewrite <- map_length with (f := translate_P).
           apply WF_Matrix_Big_Pauli. }
      destruct H3, H4; simpl in *.
      rewrite H6 in H8.
      rewrite H0, H2 in *.
      rewrite Cmult_1_l, Mscale_1_l in *.
      rewrite Mscale_mult_dist_r in H8.
      rewrite H7 in H8.
      rewrite H8.
      rewrite Mscale_assoc.
      exists (x * x0)%C.
      reflexivity.
  - destruct A, B; try easy.
    simpl in *.
    unfold translateA in *.
    unfold gAddA in *.
    rewrite map_app in *.
    rewrite fold_left_Mplus_app_Zero in *.
    rewrite Mplus_comm.
    assumption.
  - destruct A, B, C; try easy.
    simpl in *.
    unfold gAddA in *.
    rewrite app_assoc.
    assumption.
  - destruct A, B, C; try easy.
    simpl in *.
    unfold gAddA in *.
    rewrite <- app_assoc.
    assumption.
  - destruct A, B, C; try easy.
    simpl in *.
    unfold gAddA in *.
    unfold translateA in *.
    rewrite map_app in H1.
    rewrite fold_left_Mplus_app_Zero in H1.
    assert (fold_left Mplus (map translate (gMulA (gScaleA C0 a1) a0)) Zero = Zero).
    { clear H1. clear a.
      unfold gScaleA in *.
      unfold gScaleT in *.
      induction a1.
      - easy.
      - simpl.
        rewrite map_app.
        rewrite map_map.
        rewrite fold_left_Mplus_app_Zero.
        rewrite IHa1.
        rewrite Mplus_0_r.
        destruct a.
        rewrite Cmult_0_l.
        clear IHa1.
        induction a0.
        + easy.
        + simpl in *. rewrite fold_left_Mplus.
          rewrite IHa0.
          rewrite Mplus_0_l.
          destruct a.
          unfold translate.
          simpl.
          rewrite ! Cmult_0_l.
          rewrite Mscale_0_l.
          reflexivity. }
    rewrite H0 in H1.
    rewrite Mplus_0_r in H1.
    assumption.
Qed.


(*** Admitted ***)
(** *** prove that the semantics are actually implications *** **)
Lemma interpret_implies_pair {n} (A B : Predicate n) :
  A ⇒ B -> (forall p : Vector (2 ^ n) * Coef, pairSatisfiesP p A -> pairSatisfiesP p B).
Proof.
  intros H0 p H1.
  destruct H0.
  - destruct H1. easy.
  - destruct H1. constructor; easy.
  - do 2 destruct H1. try do 2 constructor; easy.
  - destruct H1. destruct H0. try do 2 constructor; easy.
  - left. easy.
  - destruct H1; [right | left]; easy.
  - destruct H1.
    + left. left. easy.
    + destruct H0.
      * left. right. easy.
      * right. easy.
  - destruct H1.
    + destruct H0.
      * left. easy.
      * right. left. easy.
    + right. right. easy.
  - destruct H1.
    constructor.
    + easy.
    + constructor.
      * destruct H1. easy.
      * destruct H1. destruct H3.
        unfold Eigenpair in *. simpl in *.
        unfold translateA in *. simpl in *.
        rewrite Mplus_0_l in *.
        destruct H0, H2; simpl in *.
        destruct T1. destruct T2.
        simpl in H6, H7.
        destruct p.
        setoid_rewrite translate_gMulT.
        2: subst; try easy.
        unfold translate in *. simpl in *.
        rewrite <- Mscale_assoc.
        rewrite <- Mscale_mult_dist_r.
        rewrite <- Mscale_mult_dist_l.
        show_dimensions.
        rewrite map_length.
        rewrite H6.
        setoid_rewrite Mmult_assoc.
        setoid_rewrite H5.
        rewrite Mscale_mult_dist_r.
        setoid_rewrite H4.
        admit.
  - destruct H1.
    constructor.
    + easy.
    + destruct H5.
      unfold vecSatisfiesP in *.
      unfold vecSatisfies in *.
      destruct H1.
      split; try easy.
      unfold translateA in *.
      simpl in *.
      rewrite Mplus_0_l in *.
      unfold Eigenpair in *. simpl in *.
      destruct p. simpl in *.
      destruct T1, T2.
      setoid_rewrite translate_gMulT in H6.
      2: destruct H3, H4; simpl in *; rewrite <- H8 in H9; easy.
      unfold translate in *. simpl in *.
      rewrite <- Mscale_mult_dist_r in H6.
      assert ( (⨂ map translate_P l) × (⨂ map translate_P l) × (c0 * c1 .* (⨂ map translate_P l0)) × m = (⨂ map translate_P l) × (c .* m)).
      { rewrite ! Mmult_assoc.  f_equal. setoid_rewrite <- Mmult_assoc. assumption. }
      setoid_rewrite Mmult_assoc in H8.
      rewrite big_kron_map_translate_P_twice in H8.
      rewrite map_length in H8.
      rewrite Mmult_1_l in H8.
      clear H6.
      2: { apply WF_mult; auto.
           rewrite map_length.
           destruct H3, H4. simpl in *. rewrite <- H10 in H9.
           rewrite H9, H10.
           apply WF_scale.
           rewrite <- H10.
           rewrite <- map_length with (f := translate_P).
           apply WF_Matrix_Big_Pauli. }
      destruct H3, H4; simpl in *.
      rewrite H6 in H8.
      rewrite H0, H2 in *.
      rewrite Cmult_1_l, Mscale_1_l in *.
      rewrite Mscale_mult_dist_r in H8.
      rewrite H7 in H8.
      rewrite H8.
      admit.
  - destruct A, B; try easy.
    simpl in *.
    unfold translateA in *.
    unfold gAddA in *.
    rewrite map_app in *.
    rewrite fold_left_Mplus_app_Zero in *.
    rewrite Mplus_comm.
    assumption.
  - destruct A, B, C; try easy.
    simpl in *.
    unfold gAddA in *.
    rewrite app_assoc.
    assumption.
  - destruct A, B, C; try easy.
    simpl in *.
    unfold gAddA in *.
    rewrite <- app_assoc.
    assumption.
  - destruct A, B, C; try easy.
    simpl in *.
    unfold gAddA in *.
    unfold translateA in *.
    rewrite map_app in H1.
    rewrite fold_left_Mplus_app_Zero in H1.
    assert (fold_left Mplus (map translate (gMulA (gScaleA C0 a1) a0)) Zero = Zero).
    { clear H1. clear a.
      unfold gScaleA in *.
      unfold gScaleT in *.
      induction a1.
      - easy.
      - simpl.
        rewrite map_app.
        rewrite map_map.
        rewrite fold_left_Mplus_app_Zero.
        rewrite IHa1.
        rewrite Mplus_0_r.
        destruct a.
        rewrite Cmult_0_l.
        clear IHa1.
        induction a0.
        + easy.
        + simpl in *. rewrite fold_left_Mplus.
          rewrite IHa0.
          rewrite Mplus_0_l.
          destruct a.
          unfold translate.
          simpl.
          rewrite ! Cmult_0_l.
          rewrite Mscale_0_l.
          reflexivity. }
    rewrite H0 in H1.
    rewrite Mplus_0_r in H1.
    assumption.
Admitted.

*)


(** ** maniplulation ** **)


(** ** not needed?
(** *** Heisenberg semantics should work for ATypes. *)
Lemma Eigenvector_Heisenberg_semantics_pair {n} (a b : AType n) (g : prog) : 
  WF_Unitary (translateA a) -> WF_Unitary (translateA b) ->
  (forall p : Vector (2^n) * Coef, pairSatisfiesP p (G a) -> pairSatisfiesP ((translate_prog n g) × (fst p), (snd p)) (G b)) -> ((translate_prog n g) × translateA a = translateA b × (translate_prog n g)).
Proof.
  intros H0 H1 H2. 
  unfold pairSatisfiesP in *.
  unfold pairSatisfies in *.
  simpl in *.
  assert (H': eq_eigs (translateA a) ((translate_prog n g)† × (translateA b) × (translate_prog n g))).
  { unfold eq_eigs. intros p H3 H4.
    destruct p. simpl in *.
    apply eig_unit_conv; auto with unit_db.
    specialize (H2 (m, c)).
    simpl in *.
    assert (WF_Matrix m /\ Eigenpair (translateA a) (m, c)). { auto. }
    apply H2 in H5.
    destruct H5.
    assumption. }
  apply eq_eigs_implies_eq_unit in H'; auto with unit_db.
  rewrite H'.
  rewrite <- ! Mmult_assoc.
  assert (WF_Unitary (translate_prog n g)). { auto with unit_db. }
  unfold WF_Unitary in H3.
  destruct H3.
  apply Minv_flip in H4; auto with wf_db.
  rewrite H4.
  rewrite Mmult_1_l.
  reflexivity.
  destruct H1.
  assumption.
Qed.

Lemma Heisenberg_Eigenvector_semantics_pair {n} (a b : AType n) (g : prog) : 
  ((translate_prog n g) × translateA a = translateA b × (translate_prog n g)) ->
  (forall p : Vector (2^n) * Coef, pairSatisfiesP p (G a) -> pairSatisfiesP ((translate_prog n g) × (fst p), (snd p)) (G b)).
Proof.
  intros H0 p H1.
  unfold pairSatisfiesP in *.
  unfold pairSatisfies in *.
  simpl in *.
  destruct H1.
  split.
  - auto with wf_db.
  - unfold Eigenpair in *. simpl in *.
    rewrite <- Mmult_assoc.
    rewrite <- H0.
    rewrite Mmult_assoc.
    setoid_rewrite H2.
    distribute_scale.
    reflexivity.
Qed.

*)


Definition Ceqb (c1 c2 : C) : bool :=
  if Ceq_dec c1 c2 then true else false.

Example test : Ceqb C1 C1 = true.
Proof. unfold Ceqb. destruct (Ceq_dec C1 C1).
  easy. contradiction.
Qed.

Lemma Ceqb_eq : forall c1 c2, c1 = c2 <-> Ceqb c1 c2 = true.
Proof. intros.
  unfold Ceqb.
  destruct (Ceq_dec c1 c2); intuition.
Qed.

Infix "=?" := Ceqb.

Lemma fold_left_Cplus : forall (c : C) (l : list C),
    fold_left Cplus l (0 + c) = c + (fold_left Cplus l 0).
Proof. intros c l. gen c.
  induction l.
  - intros. simpl. lca.
  - intros. simpl.
    rewrite <- Cplus_assoc.
    rewrite ! IHl.
    rewrite Cplus_assoc.
    easy.
Qed.

Lemma fold_left_Cplus_app : forall (l1 l2 : list C),
    fold_left Cplus (l1 ++ l2) 0 = (fold_left Cplus l1 0) + (fold_left Cplus l2 0).
Proof. intros. induction l1.
  - simpl. rewrite Cplus_0_l. easy.
  - simpl. rewrite ! fold_left_Cplus.
    rewrite IHl1. rewrite Cplus_assoc.
    easy.
Qed.

Lemma list_seq_decompose : forall (n1 n2 m : nat),
    List.seq m (n1 + n2)%nat = List.seq m n1 ++ List.seq (n1 + m) n2.
Proof. intros. gen m n2. induction n1; try easy.
  intros. simpl. f_equal. rewrite IHn1. rewrite <- plus_n_Sm. easy.
Qed.

Lemma filter_orth_app_permutation : forall A l f,
    Permutation l ((filter f l) ++ (filter (fun (x : A) => negb (f x)) l)).
Proof. intros. gen l.
  induction l; try easy.
  simpl. destruct (f a); simpl.
  - constructor. easy.
  - assert (Permutation ((a :: filter (fun x : A => negb (f x)) l) ++ filter f l) (filter f l ++ a :: filter (fun x : A => negb (f x)) l)).
    { apply Permutation_app_comm. }
    apply perm_trans with (l' := ((a :: filter (fun x : A => ¬ f x) l) ++ filter f l)); try easy.
    simpl. constructor.
    assert (Permutation (filter f l ++ filter (fun x : A => ¬ f x) l) (filter (fun x : A => ¬ f x) l ++ filter f l)). 
    { apply perm_trans with (l' := (filter f l ++ filter (fun x : A => ¬ f x) l)); try easy.
      apply Permutation_app_comm. }
    apply perm_trans with (l' := (filter f l ++ filter (fun x : A => ¬ f x) l)); easy.
Qed.

Lemma filter_orth_length : forall A l f, (length l = length (filter f l) + length (filter (fun (x : A) => negb (f x)) l))%nat.
Proof. intros.
  assert (Permutation l ((filter f l) ++ (filter (fun (x : A) => negb (f x)) l))).
  { apply (filter_orth_app_permutation A l f). }
  apply Permutation_length in H0.
  rewrite app_length in H0.
  easy.
Qed.

Lemma seq_matrix_filter_orth_app_permutation : forall n a (A : Square n),
    Permutation (List.seq 0 n)
      ((filter (fun x : nat => A x x =? a) (List.seq 0 n)) ++
         (filter (fun x : nat => negb (A x x =? a)) (List.seq 0 n))).
Proof. intros. apply filter_orth_app_permutation. Qed.

Lemma Clist_disjoint2_is_orth : forall l a b,
  (forall c : C, In c l -> (c=a \/ c=b)) -> (a <> b) ->
  (filter (fun x:C => Ceqb x b) l = filter (fun x:C => (negb (Ceqb x a))) l).
Proof. intros.
  induction l; try easy.
  assert (forall c : C, In c l -> c = a \/ c = b).
  { intros.
    assert (In c (a0 :: l)).
    { simpl. right. easy. }
    specialize (H0 c H3).
    easy. }
  specialize (IHl H2).
  assert (In a0 (a0 :: l)).
  { simpl. left. easy. }
  specialize (H0 a0 H3).
  simpl.
  destruct H0; rewrite H0.
  - unfold Ceqb.
    destruct (Ceq_dec a b);
      destruct (Ceq_dec a a);
      try contradiction.
    simpl. easy.
  - unfold Ceqb.
    destruct (Ceq_dec b b);
      destruct (Ceq_dec b a);
      try contradiction.
    symmetry in e0.
    contradiction.
    simpl.
    f_equal.
    easy.
Qed.

Lemma filter_Cdisjoint2_length : forall (a b : C) (l : list C),
    (forall c : C, In c l -> (c=a \/ c=b)) -> (a <> b) ->
    (length l = length (filter (fun x:C => Ceqb x a) l) + length (filter (fun x:C => Ceqb x b) l))%nat.
Proof. intros.
  rewrite (Clist_disjoint2_is_orth l a b); try easy.
  apply filter_orth_length.
Qed.

Lemma seq_matrix_filter_disjoint2_is_orth : forall n a b (A: Square n),
  (forall x:nat, In x (List.seq 0 n) -> (A x x = a \/ A x x = b)) -> (a <> b) ->
  (filter (fun x:nat => Ceqb (A x x) b) (List.seq 0 n) = filter (fun x:nat => (negb (Ceqb (A x x) a))) (List.seq 0 n)).
Proof. intros.
  apply filter_ext_in.
  intros.
  specialize (H0 a0 H2).
  destruct H0.
  - unfold Ceqb.
    rewrite H0.
    destruct (Ceq_dec a b);
      destruct (Ceq_dec a a);
      try contradiction.
    easy.
  - unfold Ceqb.
    rewrite H0.
    destruct (Ceq_dec b b);
      destruct (Ceq_dec b a);
      try contradiction.
    symmetry in e0.
    contradiction.
    easy.
Qed.

Lemma map_filter_Ceqb_comm : forall n a (f : nat -> C),
    (map f (filter (fun x : nat => f x =? a) (List.seq 0 n))) =
      (filter (fun c : C => c =? a) (map f (List.seq 0 n))).
Proof. induction n; intros; try easy.
  rewrite seq_S.
  simpl. rewrite filter_app, ! map_app, filter_app.
  simpl. 
  f_equal.
  - apply IHn.
  - unfold Ceqb.
    destruct (Ceq_dec (f n) a); easy.
Qed.

Lemma map_filter_matrix_Ceqb_comm : forall n a (A : Square n),
  (map (fun x : nat => A x x) (filter (fun x : nat => A x x =? a) (List.seq 0 n))) =
    (filter (fun c : C => c =? a) (map (fun x : nat => A x x) (List.seq 0 n))).
Proof. intros. apply map_filter_Ceqb_comm. Qed.


Lemma plusminus1list_sum_is_length_diff : forall n l,
    (forall x, In x l -> x = C1 \/ x = Copp C1) -> fold_left Cplus l C0 = n ->
    RtoC (INR (length (filter (fun c : C => Ceqb c C1) l))) = n + RtoC (INR (length (filter (fun c : C => Ceqb c (Copp C1)) l))).
Proof. intros. gen n. induction l.
  - intros. simpl in *. rewrite <- H1. lca.
  - intros.
    assert (forall x : C, In x l -> x = C1 \/ x = (- C1)%C).
    { intros.
      assert (In x (a :: l)).
      { simpl. right. easy. }
      specialize (H0 x H3).
      easy. }
    specialize (IHl H2).
    assert (In a (a :: l)).
    { simpl. left. easy. }
    specialize (H0 a H3).
    destruct H0; rewrite H0 in *.
    + rewrite cons_conc in H1.
      rewrite fold_left_Cplus_app in H1.
      simpl in H1. rewrite Cplus_0_l in H1.
      simpl. unfold Ceqb.
      destruct (Ceq_dec C1 C1);
        destruct (Ceq_dec C1 (Copp C1));
        try easy.
      * inversion e0. lra.
      * assert ((length (C1 :: filter (fun c : C => if Ceq_dec c C1 then true else false) l)) =
                  s (length (filter (fun c : C => if Ceq_dec c C1 then true else false) l))).
        { simpl. easy. }
        rewrite H4.
        rewrite S_O_plus_INR. simpl.
        apply Cplus_inj_l with (c := Copp C1) in H1.
        rewrite Cplus_assoc in H1.
        rewrite Cplus_opp_l in H1.
        rewrite Cplus_0_l in H1.
        specialize (IHl ((Copp C1) + n) H1).
        unfold Ceqb in IHl.
        assert (RtoC (1 + INR (length (filter (fun c : C => if Ceq_dec c C1 then true else false) l)))%R = C1 + RtoC (INR (length (filter (fun c : C => if Ceq_dec c C1 then true else false) l)))).
        { lca. }
        rewrite H5.
        rewrite IHl.
        rewrite ! Cplus_assoc.
        rewrite Cplus_opp_r.
        rewrite Cplus_0_l.
        easy.
    + rewrite cons_conc in H1.
      rewrite fold_left_Cplus_app in H1.
      simpl in H1. rewrite Cplus_0_l in H1.
      simpl. unfold Ceqb.
      destruct (Ceq_dec (Copp C1) C1);
        destruct (Ceq_dec (Copp C1) (Copp C1));
        try easy.
      * inversion e. lra.
      * assert ((length ((Copp C1) :: filter (fun c : C => if Ceq_dec c (Copp C1) then true else false) l)) = s (length (filter (fun c : C => if Ceq_dec c (- C1) then true else false) l))).
        { simpl. easy. }
        rewrite H4.
        rewrite S_O_plus_INR. simpl.
        apply Cplus_inj_l with (c := C1) in H1.
        rewrite Cplus_assoc in H1.
        rewrite Cplus_opp_r in H1.
        rewrite Cplus_0_l in H1.
        specialize (IHl (C1 + n) H1).
        unfold Ceqb in IHl.
        assert (RtoC (1 + INR (length (filter (fun c : C => if Ceq_dec c (- C1) then true else false) l)))%R = C1 + RtoC (INR (length (filter (fun c : C => if Ceq_dec c (- C1) then true else false) l)))).
        { lca. }
        rewrite H5.
        rewrite IHl.
        rewrite ! Cplus_assoc.
        setoid_rewrite Cplus_comm at 2.
        easy.
Qed.


Lemma Unitary_Hermitian_trace_zero_index_split : forall {n} (A : Square n),
    WF_Unitary A -> A † = A -> trace A = 0 ->
    (exists l1 l2 U D, Permutation (l1 ++ l2) (List.seq 0 n) /\
                    length l1 = length l2 /\ 
                    WF_Diagonal D /\ WF_Unitary U /\
                    A = U × D × U† /\ trace D = 0 /\
                    (forall x, In x l1 -> Eigenpair A (U × (e_i x), C1)) /\
                    (forall x, In x l2 -> Eigenpair A (U × (e_i x), Copp C1))).
Proof. intros n A WFUA HA TRA.
  specialize (Unitary_Hermitian_trace_zero_eigenvalues_plus_minus_1 A WFUA HA TRA); intros [U [D [WDDD [WFUU [SPECA [TRD0 EigenA_plus_minus_1]]]]]].

  assert (EigenA :  forall x : nat, (x < n)%nat -> Eigenpair A (U × e_i x, D x x)).
  { intros x H0.
    specialize (EigenA_plus_minus_1 x H0).
    destruct EigenA_plus_minus_1.
    assumption. }
  assert (plus_minus_1 :  forall x : nat, (x < n)%nat -> (D x x = C1 \/ D x x = (- C1)%C)).
  { intros x H0.
    specialize (EigenA_plus_minus_1 x H0).
    destruct EigenA_plus_minus_1.
    assumption. }
  
  assert (EigenA_in_seq : forall x:nat, In x (List.seq 0 n) -> Eigenpair A (U × e_i x, D x x)).
  { intros x H0.
    assert (x < n)%nat.
    { rewrite in_seq in H0. lia. }
    specialize (EigenA x H1).
    easy. }
  assert (plus_minus_1_in_seq : forall x:nat, In x (List.seq 0 n) -> D x x = C1 \/ D x x = (Copp C1)).
  { intros x H0.
    assert (x < n)%nat.
    { rewrite in_seq in H0. lia. }
    specialize (plus_minus_1 x H1).
    easy. }
  
  pose (plus1list_idx := filter (fun x:nat => Ceqb (D x x) C1) (List.seq 0 n)).
  pose (minus1list_idx := filter (fun x:nat => Ceqb (D x x) (Copp C1)) (List.seq 0 n)).
  pose (minus1list_idx_orth := filter (fun x:nat => negb (Ceqb (D x x) C1)) (List.seq 0 n)).

  pose (orth := seq_matrix_filter_disjoint2_is_orth n C1 (Copp C1) D).
  assert (plus_minus_1_different : C1 <> Copp C1).
  { intro. inversion H0. lra. }
  specialize (orth plus_minus_1_in_seq plus_minus_1_different).
  assert (minus1list_idx_orth_equal : minus1list_idx=minus1list_idx_orth).
  { apply orth. }

  pose (listD := map (fun x:nat => D x x) (List.seq 0 n)).
  pose (list_sum := fold_left Cplus listD C0).
  assert (trace_is_sum : list_sum = trace D).
  { clear -list_sum. 
    induction n.
    - simpl in *. easy.
    - unfold trace in *. simpl. rewrite <- IHn.
      unfold list_sum, listD.
      rewrite Cplus_comm.
      rewrite <- fold_left_Cplus.
      assert (H0: List.seq 0 (s n) = List.seq 0 n ++ [n]).
      { clear -n. pose list_seq_decompose.
        specialize (e n (s 0) 0%nat).
        simpl in e. rewrite <- plus_n_Sm in e. simpl in *.
        rewrite <- plus_n_O in e. easy. }
      rewrite H0. rewrite map_app. rewrite fold_left_Cplus_app.
      simpl. rewrite Cplus_0_l at 1. rewrite Cplus_comm.
      rewrite <- fold_left_Cplus. easy. }

  pose (plus1list := filter (fun c : C => Ceqb c C1) listD).
  pose (minus1list := filter (fun c : C => (Ceqb c (Copp C1))) listD).

  assert (plus_minus_1_in_listD : (forall x : C, In x listD -> x = C1 \/ x = (- C1)%C)).
  { intros.
    unfold listD in H0.
    rewrite in_map_iff in H0.
    do 2 destruct H0.
    rewrite <- H0.
    specialize (plus_minus_1_in_seq x0 H1).
    easy. }
    
  exists plus1list_idx, minus1list_idx, U, D.
  rewrite minus1list_idx_orth_equal.
  repeat (split; try easy).
  - apply Permutation_sym.
    apply seq_matrix_filter_orth_app_permutation.
  - rewrite <- minus1list_idx_orth_equal.
    rewrite <- ! map_length with (f := fun x:nat => D x x).
    assert (map_plus1list_idx: (map (fun x : nat => D x x) plus1list_idx) = plus1list).
    { apply map_filter_matrix_Ceqb_comm. }
    assert (map_minus1list_idx: (map (fun x : nat => D x x) minus1list_idx) = minus1list).
    { apply map_filter_matrix_Ceqb_comm. }
    rewrite map_plus1list_idx, map_minus1list_idx.
    rewrite TRD0 in trace_is_sum.
    pose (plusminus1list_sum_is_length_diff 0 listD plus_minus_1_in_listD trace_is_sum).
    rewrite Cplus_0_l in e.
    pose (INR_eq (length (filter (fun c : C => c =? C1) listD)) (length (filter (fun c : C => c =? - C1) listD))).
    inversion e.
    apply e0 in H1.
    easy.
  - intros.
    unfold plus1list_idx in H0.
    rewrite filter_In in H0.
    destruct H0.
    specialize (EigenA_in_seq x H0).
    unfold Ceqb in H1.
    destruct (Ceq_dec (D x x) C1); try discriminate.
    rewrite <- e.
    easy.
  - intros.
    rewrite <- minus1list_idx_orth_equal in H0.
    unfold minus1list_idx in H0.
    rewrite filter_In in H0.
    destruct H0.
    specialize (EigenA_in_seq x H0).
    unfold Ceqb in H1.
    destruct (Ceq_dec (D x x) (Copp C1)); try discriminate.
    rewrite <- e.
    easy.
Qed.





Lemma e_i_get_vec {n m : nat} (i : nat) (A : Matrix n m):
  WF_Matrix A -> A × e_i i = get_vec i A.
Proof. intros. unfold get_vec. unfold Mmult, e_i.
  apply functional_extensionality. intros.
  apply functional_extensionality. intros.
  bdestruct_all. 
  - assert ((fun y : nat => A x y * (if (y =? i)%nat && (y <? m) && true then C1 else 0)) =
              (fun y : nat => A x y * (if (y =? i)%nat && (y <? m) then C1 else 0))).
    { apply functional_extensionality. intros. rewrite andb_true_r. easy. }
    rewrite H2. clear H2.
    bdestruct (i <? m)%nat.
    + apply big_sum_unique.
      exists i.
      split; try easy.
      split.
      * bdestruct_all; try easy. simpl. lca.
      * intros. bdestruct_all; try easy.
        simpl. lca.
    + unfold WF_Matrix in H0.
      specialize (H0 x i).
      assert ((x >= n)%nat \/ (i >= m)%nat).
      { right. easy. }
      specialize (H0 H3).
      rewrite H0.
      assert ((fun y : nat => A x y * (if (y =? i)%nat && (y <? m) then C1 else 0)) =
                (fun y : nat => A x y * (if false then C1 else 0))).
      { apply functional_extensionality. intros. f_equal.
        bdestruct_all; easy. }
      rewrite H4.
      rewrite big_sum_0; try easy.
      intros. lca.
  - assert ((fun y : nat => A x y * (if (y =? i)%nat && (y <? m) && false then C1 else 0)) =
              (fun y : nat => A x y * (if false then C1 else 0))).
    { apply functional_extensionality. intros. f_equal.
      bdestruct_all; easy. }
    rewrite H2.
    rewrite big_sum_0; try easy.
    intros. lca.
Qed.


Lemma combine_map_list_app (X Y Z: Type) (f : X -> Y) (g : X -> Z) (l1 l2 : list X) :
  (combine
     (map (fun x => f x) (l1 ++ l2))
     (map (fun x => g x) (l1 ++ l2))) =
    (combine
     (map (fun x => f x) (l1))
     (map (fun x => g x) (l1))) ++
      (combine
         (map (fun x => f x) (l2))
         (map (fun x => g x) (l2))).
Proof. intros. induction l1; try easy.
  simpl. rewrite IHl1. easy.
Qed.

(** try Set Printing All: the type of fold_left takes two types A and B but the type of col_append is Matrix n m -> Vector n -> Matrix n (s m), the type A gets fixed as Matrix n m which is not what we want. We want the type A to incrementally increase as we append the column vectors to the matrix.**) (*
Definition list_vector_to_matrix_indirect {n} (l : list (Vector n)) : Matrix n (length l) := fold_left col_append l (@Zero n 0).
Check list_vector_to_matrix. *)

Definition list_vector_to_matrix {n} (l : list (Vector n)) : Matrix n (length l) := (fun r c : nat => (nth c l (@Zero n 1)) r 0%nat).
Check list_vector_to_matrix.

Lemma col_wedge_col_append : forall {n m} (v : Vector n) (M : Matrix n m),
    WF_Matrix M -> col_wedge M v m = col_append M v.
Proof. intros n m v M H.
  unfold col_wedge, col_append.
  apply functional_extensionality; intros.
  apply functional_extensionality; intros.
  bdestruct_all; try easy.
  unfold WF_Matrix in H.
  remember H as H'. clear HeqH'.
  specialize (H x x0).
  assert ((x >= n)%nat \/ (x0 >= m)%nat).
  { right. easy. }
  specialize (H H2).
  rewrite H.
  assert (x0 - 1 >= m)%nat.
  { lia. }
  specialize (H' x (x0 - 1)%nat).
  assert ((x >= n)%nat \/ (x0 - 1 >= m)%nat).
  { right. easy. }
  specialize (H' H4).
  easy.
Qed.

Lemma list_vector_to_matrix_col_wedge : forall {n} (x : Vector n) (l : list (Vector n)),
    list_vector_to_matrix (x :: l) = col_wedge (list_vector_to_matrix l) x 0.
Proof. intros n x l.
  unfold list_vector_to_matrix.
  simpl.
  unfold col_wedge. simpl.
  do 2 (apply functional_extensionality; intros).
  bdestruct_all.
  - rewrite H0.
    easy.
  - destruct x1.
    + contradiction.
    + assert (s x1 - 1 = x1)%nat.
      { lia. }
      rewrite H1.
      easy.
Qed.

Lemma WF_list_vector_to_matrix : forall {n} (l : list (Vector n)), Forall WF_Matrix l -> WF_Matrix (list_vector_to_matrix l).
Proof. intros n l H0.
  induction H0.
  - unfold WF_Matrix, list_vector_to_matrix.
    intros. simpl in *. destruct y; easy.
  - unfold WF_Matrix, list_vector_to_matrix.
    intros. simpl in *. destruct y.
    + destruct H2.
      * unfold WF_Matrix in H0.
        specialize (H0 x0 0%nat).
        assert ((x0 >= n)%nat \/ (0 >= 1)%nat).
        { left. easy. }
        specialize (H0 H3).
        easy.
      * lia.
    + destruct H2.
      * unfold list_vector_to_matrix in *.
        unfold WF_Matrix in IHForall.
        specialize (IHForall x0 y).
        assert ((x0 >= n)%nat \/ (y >= length l)%nat).
        { left. easy. }
        specialize (IHForall H3).
        easy.
      * assert (y >= length l)%nat.
        { lia. }
        rewrite nth_overflow; easy.
Qed.

Definition matrix_column_permutation {n m} (indices_list : list nat) (M : Matrix n m) : Matrix n (length indices_list) := list_vector_to_matrix (map (fun i : nat => get_vec i M) indices_list).

Definition vector_permutation {n} (indices_list : list nat) (v : Vector n) : Vector (length indices_list) := (fun r c : nat => v (nth r indices_list n) c).

Compute ((matrix_column_permutation [] (I 3)) × (matrix_column_permutation [] (I 3)) ⊤).
Compute ((I 0) 0%nat 0%nat).



Lemma matrix_column_permutation_assoc : forall {n m o} (indices_list : list nat) (M1 : Matrix m n) (M2 : Matrix n o), WF_Matrix M2 -> matrix_column_permutation indices_list (M1 × M2) = M1 × (matrix_column_permutation indices_list M2).
Proof. intros. unfold matrix_column_permutation.
  unfold list_vector_to_matrix.
  unfold Mmult.
  do 2 (apply functional_extensionality; intros).
  assert (Zero = @get_vec m o o (fun x1 z : nat => Σ (fun y : nat => M1 x1 y * M2 y z) n)).
  { unfold WF_Matrix in H0.
    unfold get_vec.
    do 2 (apply functional_extensionality; intros).
    bdestruct_all. 2: easy.
    rewrite big_sum_0. 1: easy.
    intros.
    specialize (H0 x3 o).
    assert ((x3 >= n)%nat \/ (o >= o)%nat). 1: right; lia.
    specialize (H0 H2).
    rewrite H0.
    lca. }
  rewrite H1.
  rewrite map_nth with (d := o).
  unfold get_vec.
  bdestruct_all.
  f_equal.
  apply functional_extensionality; intros.
  f_equal.
  assert (@Zero n o = (fun i0 x2 y : nat => if (y =? 0)%nat then M2 x2 i0 else 0) o).
  { do 2 (apply functional_extensionality; intros).
    bdestruct_all. 2: easy.
    unfold WF_Matrix in H0.
    specialize (H0 x2 o).
    assert ((x2 >= n)%nat \/ (o >= o)%nat). 1: right; lia.
    specialize (H0 H4).
    rewrite H0.
    easy. }
  setoid_rewrite H3.
  rewrite map_nth with (d := o).
  bdestruct_all.
  easy.
Qed.

Lemma   WF_Matrix_matrix_column_permutation_indices_list_I_n: forall (n : nat) (indices_list : list nat),
    WF_Matrix (matrix_column_permutation indices_list (I n)).
Proof. intros.
  unfold WF_Matrix.
  intros.
  unfold matrix_column_permutation.
  unfold list_vector_to_matrix.
  assert (Zero = get_vec n (I n)).
  { unfold get_vec.
    do 2 (apply functional_extensionality; intros).
    bdestruct_all; try easy.
    unfold I.
    bdestruct_all; try easy. }
  rewrite H1.
  rewrite map_nth with (d := n).
  unfold get_vec.
  bdestruct_all.
  destruct H0; unfold I; bdestruct_all; simpl; try easy.
  rewrite nth_overflow in H4; lia.
Qed.

#[export] Hint Resolve WF_Matrix_matrix_column_permutation_indices_list_I_n : wf_db.

  
Lemma matrix_column_permutation_inverse_r' : forall (n : nat) (indices_list : list nat),
    Permutation (List.seq 0 n) indices_list ->
    (matrix_column_permutation indices_list (I n)) × (matrix_column_permutation indices_list (I n)) ⊤ = I n.
Proof. intros.
  remember H0 as Perm. clear HeqPerm.
  unfold matrix_column_permutation.
  unfold transpose. unfold Mmult.
  do 2 (apply functional_extensionality; intros).
  unfold list_vector_to_matrix.

  assert (WF_Diagonal (I n)). 1: apply diag_I.
  unfold WF_Diagonal in H1. destruct H1.
  unfold WF_Matrix in H1.
  
  assert (Zero = get_vec n (I n)).
  { unfold WF_Matrix in H1.
    unfold get_vec.
    do 2 (apply functional_extensionality; intros).
    bdestruct_all; try easy.
    rewrite H1; try easy; try lia. }
  rewrite H3.

  assert ((fun y : nat =>
     nth y (map (fun i0 : nat => get_vec i0 (I n)) indices_list) 
       (get_vec n (I n)) x 0%nat *
     nth y (map (fun i0 : nat => get_vec i0 (I n)) indices_list) 
       (get_vec n (I n)) x0 0%nat) =
            (fun y : nat =>
     get_vec (nth y indices_list n) (I n) x 0%nat *
  get_vec (nth y indices_list n) (I n) x0 0%nat)).
  { apply functional_extensionality; intros.
    rewrite map_nth with (d := n). easy. }
  rewrite H4.
  
  unfold get_vec.
  bdestruct_all.

  unfold I in H1, H2.
  unfold WF_Matrix in H0.
  unfold I.
  bdestruct_all.
  - simpl.
    rewrite H8.
    replace
      (fun y : nat =>
         (if (x0 =? nth y indices_list n)%nat && true then C1 else 0) *
           (if (x0 =? nth y indices_list n)%nat && true then C1 else 0))
      with
      (fun y : nat =>
         (if (x0 =? nth y indices_list n)%nat then C1 else 0) *
           (if (x0 =? nth y indices_list n)%nat then C1 else 0))
      by (apply functional_extensionality; intros; rewrite andb_true_r; easy).
    rewrite Permutation_nth in H0; try easy.
    destruct H0. destruct H9 as [f H9]. destruct H9. destruct H10.
    specialize (FinFun.bInjective_bSurjective H9). intros.
    rewrite H12 in H10.
    specialize (FinFun.bSurjective_bBijective H9 H10). intros.
    destruct H13 as [g H13].
    destruct H13.
    
    assert (FinFun.bInjective (length (List.seq 0 n)) g).
    { unfold FinFun.bInjective.
      intros.
      remember H14. clear Heqa.
      specialize (H14 x1 H15).
      specialize (a y H16).
      destruct H14.
      destruct a.
      apply f_equal with (f := f) in H17.
      rewrite H18, H20 in H17.
      easy. }
    specialize (FinFun.bInjective_bSurjective H13). intros.
    rewrite H16 in H15.
    
    apply big_sum_unique.

    exists (g x0). rewrite ! H0.
    remember H10 as bSurjective_f. clear HeqbSurjective_f.
    unfold FinFun.bSurjective in H10.
    specialize (seq_length n 0). intros.
    rewrite <- H17 in H6, H7.
    specialize (H10 x0 H7).
    destruct H10.
    destruct H10.
    apply f_equal with (f := g) in H18.
    remember H14. clear Heqa.
    specialize (a x1 H10).
    destruct a.
    rewrite H19 in H18.
    rewrite <- H18.
    split; try easy.
    split.
    + specialize (H11 x1 H10).
      rewrite H11.
      apply f_equal with (f := f) in H18.
      specialize (H14 x0 H7).
      destruct H14.
      rewrite H21 in H18.
      rewrite H18.
      rewrite seq_nth.
      bdestruct_all.
      lca.
      rewrite H17 in H7.
      easy.
    + intros.
      remember H14. clear Heqa.
      specialize (a x0 H7).
      destruct a.
      apply f_equal with (f := f) in H18.
      rewrite H24 in H18.
      rewrite <- H18.
      rewrite H11; try easy.
      rewrite seq_nth.
      2: { unfold FinFun.bSurjective in H15.
           specialize (H15 x' H21).
           destruct H15.
           destruct H15.
           specialize (H14 x2 H15).
           destruct H14.
           apply f_equal with (f := f) in H25.
           rewrite H26 in H25.
           rewrite <- H17.
           rewrite <- H25.
           easy. }
      bdestruct_all; try lca.
      rewrite Nat.add_0_l in H25.
      rewrite <- H12 in bSurjective_f.
      rename bSurjective_f into bInjective_f.
      unfold FinFun.bInjective in bInjective_f.
      specialize (bInjective_f x1 x' H10 H21).
      apply bInjective_f in H25.
      contradiction.
  - simpl.
    replace C0 with (big_sum (fun _ : nat => C0) (length indices_list)) at 1 by (rewrite big_sum_0; easy).
    apply big_sum_eq_bounded.
    intros.
    bdestruct_all; simpl; lca.
  - simpl.
    replace C0 with (big_sum (fun _ : nat => C0) (length indices_list)) at 1 by (rewrite big_sum_0; easy).
    apply big_sum_eq_bounded.
    intros.
    bdestruct_all; simpl; lca.
  - simpl.
    replace C0 with (big_sum (fun _ : nat => C0) (length indices_list)) at 1 by (rewrite big_sum_0; easy).
    apply big_sum_eq_bounded.
    intros.
    bdestruct_all; simpl; lca.
  - simpl.
    replace C0 with (big_sum (fun _ : nat => C0) (length indices_list)) at 1 by (rewrite big_sum_0; easy).
    apply big_sum_eq_bounded.
    intros.
    bdestruct_all; simpl; lca.
  - simpl.
    replace C0 with (big_sum (fun _ : nat => C0) (length indices_list)) at 1 by (rewrite big_sum_0; easy).
    apply big_sum_eq_bounded.
    intros.
    bdestruct_all; simpl; lca.
Qed.

Lemma matrix_column_permutation_inverse_l' : forall (n : nat) (indices_list : list nat),
    Permutation (List.seq 0 n) indices_list ->
    (matrix_column_permutation indices_list (I n)) ⊤ × (matrix_column_permutation indices_list (I n)) = I (length indices_list).
Proof. intros.
  remember H0 as Perm. clear HeqPerm.
  apply Permutation_length in H0.
  rewrite seq_length in H0. rewrite <- ! H0.
  apply Minv_flip.
  assert (@WF_Matrix n n (matrix_column_permutation indices_list (I n)) =
            @WF_Matrix n (length indices_list) (matrix_column_permutation indices_list (I n))).
  { rewrite <- H0. easy. }
  rewrite H1. apply WF_Matrix_matrix_column_permutation_indices_list_I_n.
  apply WF_transpose.
  assert (@WF_Matrix n n (matrix_column_permutation indices_list (I n)) =
            @WF_Matrix n (length indices_list) (matrix_column_permutation indices_list (I n))).
  { rewrite <- H0. easy. }
  rewrite H1. apply WF_Matrix_matrix_column_permutation_indices_list_I_n.
  assert (@eq (Matrix n n)
            (@Mmult n (@length nat indices_list) n
               (@matrix_column_permutation n n indices_list (I n))
               (@transpose n (@length nat indices_list)
                  (@matrix_column_permutation n n indices_list (I n)))) 
            (I n) =
            @eq (Matrix n n)
              (@Mmult n n n (@matrix_column_permutation n n indices_list (I n))
                 (@transpose n n (@matrix_column_permutation n n indices_list (I n)))) 
              (I n)).
  { rewrite <- H0. easy. }
  rewrite <- H1.
  apply matrix_column_permutation_inverse_r'.
  easy.
Qed.

Lemma matrix_column_permutation_I_n_transpose_adjoint : forall (n : nat) (indices_list : list nat),
    (matrix_column_permutation indices_list (I n)) † =  (matrix_column_permutation indices_list (I n)) ⊤.
Proof. intros. unfold matrix_column_permutation.
  unfold list_vector_to_matrix.
  unfold transpose, adjoint.
  do 2 (apply functional_extensionality; intros).
  assert (Zero = get_vec n (I n)).
  { unfold get_vec.
    do 2 (apply functional_extensionality; intros).
    bdestruct_all; try easy.
    unfold I.
    bdestruct_all; try easy. }
    rewrite H0.
  rewrite map_nth with (d := n).
  unfold get_vec.
  bdestruct_all.
  unfold I.
  bdestruct_all; simpl; lca.
Qed.

Lemma matrix_column_permutation_inverse_r : forall (n : nat) (indices_list : list nat),
    Permutation (List.seq 0 n) indices_list ->
    (matrix_column_permutation indices_list (I n)) × (matrix_column_permutation indices_list (I n)) † = I n.
Proof. intros.
  rewrite matrix_column_permutation_I_n_transpose_adjoint.
  apply matrix_column_permutation_inverse_r'.
  easy.
Qed.

Lemma matrix_column_permutation_inverse_l : forall (n : nat) (indices_list : list nat),
    Permutation (List.seq 0 n) indices_list ->
    (matrix_column_permutation indices_list (I n)) † × (matrix_column_permutation indices_list (I n)) = I (length indices_list).
Proof. intros.
  rewrite matrix_column_permutation_I_n_transpose_adjoint.
  apply matrix_column_permutation_inverse_l'.
  easy.
Qed.

(** 
     0    1   0       0  1  0  0
     1    0   0       1  0  0  0
     0    0   1       0  0  1  0
     0    0   0
*)


Lemma matrix_column_permutation_app_smash : forall {n m} (list1 list2 : list nat) (M : Matrix n m), WF_Matrix M -> matrix_column_permutation (list1 ++ list2) M = smash (matrix_column_permutation list1 M) (matrix_column_permutation list2 M).
Proof. intros. unfold matrix_column_permutation. unfold smash.
  unfold list_vector_to_matrix.
  do 2 (apply functional_extensionality; intros).
  assert (Zero = get_vec m M).
  { unfold WF_Matrix in H0.
    unfold get_vec.
    do 2 (apply functional_extensionality; intros).
    bdestruct_all. 2: easy.
    specialize (H0 x1 m).
    assert ((x1 >= n)%nat \/ (m >= m)%nat). 1: right; lia.
    specialize (H0 H2).
    rewrite H0.
    easy. }
  rewrite ! H1.
  rewrite ! map_nth with (d := m).
  bdestruct_all.
  - f_equal. apply app_nth1; easy.
  - f_equal. apply app_nth2; easy.
Qed.


Lemma big_sum_permutation : forall (A : Type) (m : nat) (d : A) (l1 l2 : list A) (f : A -> C),
    Permutation l1 l2 -> (m >= length l1)%nat ->
    Σ (fun y : nat => f (nth y l1 d)) m = Σ (fun y : nat => f (nth y l2 d)) m.
Proof. intros.
  gen m.
  induction H0.
  - simpl. easy.
  - intros. simpl in *.
    destruct m; try easy.
    rewrite <- ! big_sum_extend_l.
    rewrite IHPermutation.
    easy. lia.
  - intros. 
    destruct m; try easy.
    destruct m.
    simpl in *.
    lia.
    rewrite <- ! big_sum_extend_l.
    simpl.
    lca.
  - intros.
    rewrite IHPermutation1; try easy.
    rewrite IHPermutation2; try easy.
    apply Permutation_length in H0_.
    rewrite H0_ in H1.
    easy.
Qed.  


Lemma matrix_column_permutation_vector_permutation_original : forall {n m} (indices_list : list nat) (M : Matrix n m) (v : Vector m),
    WF_Matrix M ->
    Permutation (List.seq 0 m) indices_list ->
    (matrix_column_permutation indices_list M)
      × (vector_permutation indices_list v) = M × v. (** = Σ_i M_i v_i **)
Proof. intros.
  unfold matrix_column_permutation.
  unfold list_vector_to_matrix.
  unfold vector_permutation.
  unfold Mmult.
  do 2 (apply functional_extensionality; intros).

  remember H1 as H2. clear HeqH2.
  apply Permutation_length in H2.
  rewrite seq_length in H2.
  symmetry in H2.
  rewrite H2.
  
  assert (Zero = get_vec m M).
  { unfold WF_Matrix in H0.
    unfold get_vec.
    do 2 (apply functional_extensionality; intros).
    bdestruct_all. 2: easy.
    specialize (H0 x1 m).
    assert ((x1 >= n)%nat \/ (m >= m)%nat). 1: right; lia.
    specialize (H0 H4).
    rewrite H0.
    easy. }
  rewrite H3.

  assert ((fun y : nat =>
             nth y (map (fun i0 : nat => get_vec i0 M) indices_list) (get_vec m M) x 0%nat *
               v (nth y indices_list m) x0) =
            (fun y : nat =>
                get_vec (nth y indices_list m) M x 0%nat * v (nth y indices_list m) x0)).
  { apply functional_extensionality; intros.
    rewrite map_nth with (d := m). easy. }
  rewrite H4.
  unfold get_vec.
  bdestruct_all.

  rewrite big_sum_permutation with (A := nat) (d := m) (l1 := indices_list) (f := (fun y : nat => M x y * v y x0)) (l2 := List.seq 0 m).

  - apply big_sum_eq_bounded.
    intros.
    rewrite seq_nth; easy.
  - apply Permutation_sym in H1. easy.
  - lia.
Qed.


Lemma matrix_column_permutation_assoc_square : forall {n} (indices_list : list nat) (M1 M2 : Square n), WF_Matrix M2 -> matrix_column_permutation indices_list (M1 × M2) = M1 × (matrix_column_permutation indices_list M2).
Proof. intros. rewrite <- matrix_column_permutation_assoc; auto with wf_db.
Qed.

Lemma matrix_column_permutation_assoc_square_id : forall {n} (indices_list : list nat) (M : Square n), WF_Matrix M -> matrix_column_permutation indices_list M = M × (matrix_column_permutation indices_list (I n)).
Proof. intros. rewrite <- matrix_column_permutation_assoc; auto with wf_db.
  rewrite Mmult_1_r; auto with wf_db.
Qed.

Lemma vector_permutation_matrix_column_permutation : forall (n : nat) (v : Vector n) (indices_list : list nat),
    WF_Matrix v ->
    (vector_permutation indices_list v) = (matrix_column_permutation indices_list (I n)) ⊤ × v.
Proof. intros. unfold vector_permutation.
  unfold matrix_column_permutation.
  unfold list_vector_to_matrix.
  unfold transpose, Mmult.
  do 2 (apply functional_extensionality; intros).

  assert (Zero = get_vec n (I n)).
  { unfold get_vec.
    do 2 (apply functional_extensionality; intros).
    bdestruct_all. 2: easy.
    unfold I.
    bdestruct_all; simpl; easy. }

  assert ((fun y : nat =>
     nth x (map (fun i0 : nat => get_vec i0 (I n)) indices_list) Zero y 0%nat *
     v y x0) = (fun y : nat => get_vec (nth x indices_list n) (I n) y 0%nat * v y x0)).
  { rewrite H1.
    rewrite map_nth with (d := n).
    easy. }
  rewrite H2.

  unfold get_vec.
  bdestruct_all.
  bdestruct ((nth x indices_list n) <? n).
  - rewrite big_sum_unique with (k := v (nth x indices_list n) x0); try easy.
    exists (nth x indices_list n). split; try easy.
    split.
    + unfold I. bdestruct_all. simpl. lca.
    + intros. unfold I. bdestruct_all. simpl. lca.
  - unfold WF_Matrix in H0.
    rewrite H0. 2: left; assumption.
    rewrite big_sum_0; try easy.
    intros.
    unfold I.
    bdestruct_all; simpl; lca.
Qed.

Definition is_in_nat_list (n : nat) (listN : list nat) : bool :=
  existsb (fun m : nat => Nat.eqb n m) listN.

Definition selective_diagonal (n : nat) (indices_list : list nat): Square n :=
  fun x y => if (x =? y)%nat && (x <? n) && (is_in_nat_list x indices_list) then C1 else 0.

Lemma diagonal_is_selective_diagonal : forall (n : nat) (indices_list : list nat),
    Permutation (List.seq 0 n) indices_list ->
    I n = selective_diagonal n indices_list.
Proof. intros. unfold I. unfold selective_diagonal.
  do 2 (apply functional_extensionality; intros).
  bdestruct_all; simpl; trivial.
  assert (0 <= x < 0 + n)%nat.
  { lia. }
  rewrite <- in_seq in H3.
  apply Permutation_in with (l := (List.seq 0 n)) (l' := indices_list) in H3; trivial.
  unfold is_in_nat_list.
  assert (exists y : nat, In y indices_list /\ ((fun m : nat => (x =? m)%nat) y = true)).
  { exists x. split; bdestruct_all; trivial. }
  rewrite <- existsb_exists with (f := (fun m : nat => (x =? m)%nat)) (l := indices_list) in H4.
  rewrite H4.
  reflexivity.
Qed.

Lemma matrix_column_permutation_selective_diagonal : forall (n : nat) (indices_list : list nat),
    NoDup indices_list ->
    (matrix_column_permutation indices_list (I n)) × (matrix_column_permutation indices_list (I n)) ⊤ = selective_diagonal n indices_list.
Proof. intros n indices_list H'.  unfold matrix_column_permutation. unfold list_vector_to_matrix.
  unfold selective_diagonal.
  unfold transpose, Mmult.
  do 2 (apply functional_extensionality; intros).
  assert (Zero = get_vec n (I n)).
  { unfold get_vec, I.
    do 2 (apply functional_extensionality; intros).
    bdestruct_all; simpl; lca. }
  rewrite ! H0.
  assert ((fun y : nat =>
             nth y (map (fun i0 : nat => get_vec i0 (I n)) indices_list) 
               (get_vec n (I n)) x 0%nat *
               nth y (map (fun i0 : nat => get_vec i0 (I n)) indices_list) 
                 (get_vec n (I n)) x0 0%nat) =
            (fun y : nat =>
               get_vec (nth y indices_list n) (I n) x 0%nat *
                 get_vec (nth y indices_list n) (I n) x0 0%nat)).
  { apply functional_extensionality; intros.
    rewrite map_nth with (d := n). easy. }
  rewrite H1.
  unfold get_vec.
  bdestruct (0 =? 0)%nat.
  2: contradiction.
  unfold I.
  bdestruct_all; simpl.
  - assert ((fun y : nat =>
               (if (x =? nth y indices_list n)%nat && true then C1 else 0) *
                 (if (x0 =? nth y indices_list n)%nat && true then C1 else 0)) =
              (fun y : nat =>
                 (if (x =? nth y indices_list n)%nat then C1 else 0))).
    { rewrite H5.
      apply functional_extensionality; intros.
      bdestruct_all; simpl; lca. }
    rewrite H6.
    unfold is_in_nat_list.
    clear - H'.
    destruct (existsb (fun m : nat => (x =? m)%nat) indices_list) eqn:E.
    + apply big_sum_unique.
      apply existsb_exists in E.
      destruct E. destruct H0.
      apply Nat.eqb_eq in H1.
      apply In_nth with (x := x0) (l := indices_list) (d := n) in H0; trivial.
      destruct H0. destruct H0.
      exists x1. split; trivial.
      split.
      * rewrite H1. bdestruct_all; easy.
      * intros.
        bdestruct_all; trivial.
        rewrite H1 in H5. symmetry in H5.
        rewrite NoDup_nth in H'.
        rewrite <- H5 in H2.
        specialize (H' x1 x' H0 H3 H2).
        contradiction.
    + assert (C0 =  Σ (fun _ : nat => 0) (length indices_list)).
      { rewrite big_sum_0; easy. }
      rewrite H0.
      apply big_sum_eq_bounded.
      intros.
      rewrite existsb_nth; trivial.
      setoid_rewrite H0 at 2.
      reflexivity.
  - assert ((fun y : nat =>
               (if (x =? nth y indices_list n)%nat && true then C1 else 0) *
                 (if (x0 =? nth y indices_list n)%nat && true then C1 else 0)) =
              (fun y : nat => 0)).
    { apply functional_extensionality; intros.
      bdestruct_all; simpl; lca. }
    rewrite H6.
    rewrite big_sum_0; easy.
  - assert ((fun y : nat =>
               (if (x =? nth y indices_list n)%nat && true then C1 else 0) *
                 (if (x0 =? nth y indices_list n)%nat && false then C1 else 0)) =
              (fun y : nat => 0)).
    { apply functional_extensionality; intros.
      bdestruct_all; simpl; lca. }
    rewrite H6.
    rewrite big_sum_0; easy.
  - assert ((fun y : nat =>
               (if (x =? nth y indices_list n)%nat && false then C1 else 0) *
                 (if (x0 =? nth y indices_list n)%nat && true then C1 else 0)) =
              (fun y : nat => 0)).
    { apply functional_extensionality; intros.
      bdestruct_all; simpl; lca. }
    rewrite H6.
    rewrite big_sum_0; easy.
  - assert ((fun y : nat =>
               (if (x =? nth y indices_list n)%nat && false then C1 else 0) *
                 (if (x0 =? nth y indices_list n)%nat && false then C1 else 0)) =
              (fun y : nat => 0)).
    { apply functional_extensionality; intros.
      bdestruct_all; simpl; lca. }
    rewrite H6.
    rewrite big_sum_0; easy.
  - assert ((fun y : nat =>
     (if (x =? nth y indices_list n)%nat && false then C1 else 0) *
     (if (x0 =? nth y indices_list n)%nat && false then C1 else 0)) =
              (fun y : nat => 0)).
    { apply functional_extensionality; intros.
      bdestruct_all; simpl; lca. }
    rewrite H6.
    rewrite big_sum_0; easy.
Qed.

(*
list1, list2 : list nat
  H0 : NoDup (list1 ++ list2)
  x, x0 : nat
  H1 : (x < n)%nat
  H2 : x = x0
  x1 : nat
  H3 : In x1 list1
 *)

Lemma NoDup_app_comm : forall (A : Type) (list1 list2 : list A),
    NoDup (list1 ++ list2) -> NoDup (list2 ++ list1).
Proof. intros. apply NoDup_incl_NoDup with (l := list1 ++ list2) (l' := list2 ++ list1); trivial.
  - rewrite ! app_length. lia.
  - apply incl_app.
    + apply incl_appr.
      apply incl_refl.
    + apply incl_appl.
      apply incl_refl.
Qed.

Lemma NoDup_app_in_neg_r : forall (A : Type) (a : A) (list1 list2 : list A),
    NoDup (list1 ++ list2) -> In a list1 -> ~ In a list2.
Proof. intros.
  gen a list1. induction list2.
  - intros. intro. inversion H2.
  - intros.
    apply NoDup_remove in H0.
    intro.
    simpl in *.
    destruct H0.
    destruct H2.
    + rewrite <- H2 in H1.
      assert (In a (list1 ++ list2)).
      { rewrite in_app_iff. left. easy. }
      apply H3 in H4.
      contradiction.
    + contradict H2.
      apply IHlist2 with (list1 := list1); trivial.
Qed.

Lemma NoDup_app_in_neg_l : forall (A : Type) (a : A) (list1 list2 : list A),
    NoDup (list1 ++ list2) -> In a list2 -> ~ In a list1.
Proof. intros. apply NoDup_app_comm in H0.
  apply NoDup_app_in_neg_r with (list1 := list2); trivial.
Qed.

Lemma selective_diagonal_app_split : forall (n : nat) (list1 list2 : list nat),
    NoDup (list1 ++ list2) ->
    selective_diagonal n (list1 ++ list2) = selective_diagonal n list1 .+ selective_diagonal n list2.
Proof. intros. unfold selective_diagonal.
  unfold Mplus.
  do 2 (apply functional_extensionality; intros).
  bdestruct_all; simpl; try lca.
  unfold is_in_nat_list.
  destruct (existsb (fun m : nat => (x =? m)%nat) (list1 ++ list2)) eqn:E.
  - rewrite existsb_app in E.
    rewrite orb_true_iff in E.
    destruct E.
    + rewrite H3.
      rewrite existsb_exists in H3.
      destruct H3. destruct H3.
      apply NoDup_app_in_neg_r with (a := x1) in H0; trivial.
      rewrite Nat.eqb_eq in H4.
      rewrite H4.
      destruct (existsb (fun m : nat => (x1 =? m)%nat) list2) eqn:E; try lca.
      rewrite existsb_exists in E.
      destruct E. destruct H5.
      rewrite Nat.eqb_eq in H6.
      rewrite H6 in H0.
      contradiction.
    + rewrite H3.
      rewrite existsb_exists in H3.
      destruct H3. destruct H3.
      apply NoDup_app_in_neg_l with (a := x1) in H0; trivial.
      rewrite Nat.eqb_eq in H4.
      rewrite H4.
      destruct (existsb (fun m : nat => (x1 =? m)%nat) list1) eqn:E; try lca.
      rewrite existsb_exists in E.
      destruct E. destruct H5.
      rewrite Nat.eqb_eq in H6.
      rewrite H6 in H0.
      contradiction.
  - rewrite existsb_app in E.
    rewrite orb_false_iff in E.
    destruct E.
    rewrite H3, H4.
    lca.
Qed.

Lemma matrix_column_permutation_I_n_app_split : forall (n : nat) (list1 list2 : list nat),
    NoDup (list1 ++ list2) ->
    (matrix_column_permutation (list1 ++ list2) (I n)) × (matrix_column_permutation (list1 ++ list2) (I n)) ⊤ = (matrix_column_permutation (list1) (I n)) × (matrix_column_permutation (list1) (I n)) ⊤ .+ (matrix_column_permutation (list2) (I n)) × (matrix_column_permutation (list2) (I n)) ⊤.
Proof. intros.
  remember H0. clear Heqn0.
  remember H0. clear Heqn1.
  apply NoDup_app_remove_l in n0.
  apply NoDup_app_remove_r in n1.
  rewrite ! matrix_column_permutation_selective_diagonal; trivial.
  rewrite selective_diagonal_app_split; trivial.
Qed.

(*** is there a good way to express v_is ?? *)
Lemma matrix_column_permutation_vector_permutation_app_split : forall {n} (list1 list2 : list nat) (M : Square n) (v : Vector n),
    WF_Matrix M -> WF_Matrix v -> NoDup (list1 ++ list2) ->
    Permutation (list1 ++ list2) (List.seq 0 n) ->
    (matrix_column_permutation (list1 ++ list2) M)
      × (vector_permutation (list1 ++ list2) v) =
      ((matrix_column_permutation list1 M)
         × (vector_permutation list1 v)) .+
        ((matrix_column_permutation list2 M)
           × (vector_permutation list2 v)).
Proof. intros.
  rewrite matrix_column_permutation_assoc_square_id.
  rewrite vector_permutation_matrix_column_permutation.
  assert (M × matrix_column_permutation (list1 ++ list2) (I n)
            × ((matrix_column_permutation (list1 ++ list2) (I n)) ⊤ × v) =
            M × (matrix_column_permutation (list1 ++ list2) (I n)
                   × (matrix_column_permutation (list1 ++ list2) (I n)) ⊤) × v).
  { rewrite ! Mmult_assoc. easy. }
  rewrite H4.
  rewrite matrix_column_permutation_I_n_app_split.
  rewrite Mmult_plus_distr_l.
  rewrite <- ! Mmult_assoc.
  rewrite <- ! matrix_column_permutation_assoc_square_id.
  rewrite Mmult_plus_distr_r.
  rewrite ! Mmult_assoc.
  rewrite <- ! vector_permutation_matrix_column_permutation.
  easy.
  all: assumption.
Qed.

         
(*
For both P and Q, the only eigenvalues are +1 and -1, and the dimension of +1-eigenstates equals that of the -1-eigenstates.

Let { v1, v2, ..., vn, w1, w2, ..., wn } be the eigenvectors of P where the vi's are the +1 eigenvectors and the wi's are the -1 eigenvectors.
Since there is a spectral decomposition for P, we can take { v1, v2, ..., vn, w1, w2, ..., wn } as an orthonormal basis that spans the whole space.

Consider { U v1, U v2, ..., U vn, U w1, U w2, ..., U wn }.
Since unitary matrices preserve innerproducts, { U v1, U v2, ..., U vn, U w1, U w2, ..., U wn } also forms an orthonormal basis.
(Let X=[v1 v2 ... vn w1 w2 ... wn]. Then UX is unitary.)

By the assertion {P} U {Q}, given any linear combination v = a1 v1 + ... + an vn, we have QUv = Uv.
Hence { U v1, U v2, ..., U vn } forms a basis for the +1 eigenspace of Q.
(?????)

Given a w such that Pw = -w we want to show that QUw = -Uw.
Since eigenvectors corresponding to distinct eigenvalues are orthogonal, the -1 eigenspace of Q is orthogonal to the +1 eigenspace of Q.
Since { U v1, U v2, ..., U vn, U w1, U w2, ..., U wn } forms an orthonormal basis, the -1 eigenspace of Q must be spanned by { U w1, U w2, ..., U wn }.
( Let u be a -1 eigenvector of Q. Then Q u = - u  and 
  u = a1 U v1 + ... + an U vn + b1 U w1 + ... + bn U wn  and
  Qu = - u = (a1 U v1 + ... + an U vn) + Q (b1 U w1 + ... + bn U wn).
  Then 0 = u - u = (b1 U w1 + ... + bn U wn) + Q (b1 U w1 + ... + bn U wn)  so
  Q (b1 U w1 + ... + bn U wn) = - (b1 U w1 + ... + bn U wn).
  Then u = - (a1 U v1 + ... + an U vn) + (b1 U w1 + ... + bn U wn)  and so
  2 u = 2 (b1 U w1 + ... + bn U wn)  which gives
  u = b1 U w1 + ... + bn U wn. )
Since { U w1, U w2, ..., U wn } is orthonormal, they form an orthonormal basis of the -1 eigenspace of Q.

Hence, given any linear combination w = a1 w1 + ... + an wn, we have QUw = - Uw.
 *)

(*
The salient point is that the “additive types” P and Q have the property that their +1 and -1 eigenspaces are precisely dimension n (where the underlying Hilbert space has dimension 2n). Then since U is invertible, the assertion {P} U {Q} implies that U maps the +1-eigenspace of P precisely onto the +1-eigenspace of Q. Now as U is unitary it preserves orthogonality, and so maps the -1-eigenspace of P precisely onto the -1-eigenspace of Q (as the -1-eigenspace is the orthogonal complement of the +1-eigenspace of each operator).
*)

(** *** here for reference
Lemma Unitary_Hermitian_trace_zero_eigenvalues_plus_minus_1 : 
forall {n} (A : Square n),
  WF_Unitary A -> A † = A -> trace A = 0 ->
  (exists U D, WF_Diagonal D /\ WF_Unitary U /\ A = U × D × U† /\ trace D = C0 /\
  (forall x, (x < n)%nat -> Eigenpair A (U × (e_i x), D x x) /\ (D x x = C1 \/ D x x = (Copp C1)))).

A = U × D × U† = ∑ U_i D_ii U_i† 

Lemma Unitary_Hermitian_trace_zero_index_split : forall {n} (A : Square n),
    WF_Unitary A -> A † = A -> trace A = 0 ->
    (exists l1 l2 U D, Permutation (l1 ++ l2) (List.seq 0 n) /\
                    length l1 = length l2 /\ 
                    WF_Diagonal D /\ WF_Unitary U /\
                    A = U × D × U† /\ trace D = 0 /\
                    (forall x, In x l1 -> Eigenpair A (U × (e_i x), C1)) /\
                    (forall x, In x l2 -> Eigenpair A (U × (e_i x), Copp C1))).
*)
(*** Admitted ***)
(** *** Heisenberg semantics should work for ATypes. *)
Lemma Eigenvector_Heisenberg_semantics' {n} (a b : AType n) (g : prog) :
  proper_length_AType_nil n a -> proper_length_AType_nil n b ->
  WF_Unitary (translateA a) -> (translateA a) † = translateA a -> trace (translateA a) = 0 ->
  WF_Unitary (translateA b) -> (translateA b) † = translateA b -> trace (translateA b) = 0 ->
  {{G a}} g {{G b}} ->
  ((translate_prog n g) × translateA a = translateA b × (translate_prog n g)).
Proof. intros Pa Pb Ua Ha Ta Ub Hb Tb Triple.
  unfold triple in Triple.
  unfold vecSatisfiesP in Triple.

  assert (WFU_g : WF_Unitary (translate_prog n g)).
  { apply unit_prog. }
  
  (*
  specialize (Unitary_Hermitian_trace_zero_eigenvalues_plus_minus_1 (translateA a) Ua Ha Ta); intros [UA [DA [WFDDA [WFUUA [SpecA [traceDA0 EigenA]]]]]].
  specialize (Unitary_Hermitian_trace_zero_eigenvalues_plus_minus_1 (translateA b) Ub Hb Tb); intros [UB [DB [WFDDB [WFUUB [SpecB [traceDB0 EigenB]]]]]].
  *)
  
  specialize (Unitary_Hermitian_trace_zero_index_split (translateA a) Ua Ha Ta);
    intros [plus1idxA [minus1idxA [UA [DA [PermA [equal_len_A [WFDDA [WFUUA [SpecA [traceDA0 [Eigen_plus1_A Eigen_minus1_A]]]]]]]]]]].
  (*
  specialize (Unitary_Hermitian_trace_zero_index_split (translateA b) Ub Hb Tb);
    intros [plus1idxB [minus1idxB [UB [DB [PermB [equal_len_B [WFDDB [WFUUB [SpecB [traceDB0 [Eigen_plus1_B Eigen_minus1_B]]]]]]]]]]].
   *)

  assert (plusA_Eigen : forall x : nat, In x plus1idxA -> Eigenpair (translateA b) (translate_prog n g × UA × e_i x, C1)).
  { intros.
    specialize (Eigen_plus1_A x H0).
    unfold vecSatisfies in Triple.
     assert (WF_Matrix (UA × e_i x) /\ Eigenpair (translateA a) (UA × e_i x, C1)).
    { destruct WFUUA. split; auto with wf_db. }
    specialize (Triple (UA × e_i x) H1).
    destruct Triple.
    rewrite Mmult_assoc.
    easy. }

(* U maps the -1-eigenspace of P precisely "onto" the -1-eigenspace of Q:
        1. since { U v1, U v2, ..., U vn } "spans" the +1 eigenspace of Q,
            and since the linear combination of +1 eigenspace and -1 eigenspace 
                    spans the 'whole' space
            and since { U v1, U v2, ..., U vn, U w1, U w2, ..., U wn } forms an orthonormal basis,
            { U w1, U w2, ..., U wn } "spans" the 'whole' -1 eigenspace of Q.

            ( Let u be a -1 eigenvector of Q. Then Q u = - u  and 
              u = a1 U v1 + ... + an U vn + b1 U w1 + ... + bn U wn  and
              Qu = - u = (a1 U v1 + ... + an U vn) + Q (b1 U w1 + ... + bn U wn).
              Then 0 = u - u = (b1 U w1 + ... + bn U wn) + Q (b1 U w1 + ... + bn U wn)  so
              Q (b1 U w1 + ... + bn U wn) = - (b1 U w1 + ... + bn U wn).
              Then u = - (a1 U v1 + ... + an U vn) + (b1 U w1 + ... + bn U wn)  and so
              2 u = 2 (b1 U w1 + ... + bn U wn)  which gives
              u = b1 U w1 + ... + bn U wn. )

              2. since { U w1, U w2, ..., U wn } "spans" the 'whole' -1 eigenspace
                  and since the dimension of { U w1, U w2, ..., U wn } and -1 eigenspace are equal
                  { U w1, U w2, ..., U wn } is a basis of the -1 eigenspace of Q
                  
               3. U wi is an -1 eigenvector of Q 
*)
  assert (total_length : length (plus1idxA ++ minus1idxA) = (2 ^ n)%nat).
  { apply Permutation_length in PermA.
    rewrite seq_length in PermA.
    assumption. }


  

(*  assert (spans_whole_space : forall (v : Vector n),
           exists coef_vec : Vector (length (plus1idxA ++ minus1idxA)),
             v = matrix_column_permutation
                   (plus1idxA ++ minus1idxA)
                   (translate_prog n g × UA)
                   × coef_vec). *)
  assert (spans_whole_space : forall (v : Vector n),
             @WF_Matrix (2 ^ n) 1 v ->
             v = matrix_column_permutation
                   (plus1idxA ++ minus1idxA)
                   (translate_prog n g × UA)
                   × (vector_permutation
                        (plus1idxA ++ minus1idxA)
                        ((translate_prog n g × UA)† × v))).
  { intros.
    rewrite matrix_column_permutation_vector_permutation_original.
    - rewrite Mmult_adjoint.
      assert ((@Mmult (Nat.pow (Datatypes.S (Datatypes.S O)) n)
       (Nat.pow (Datatypes.S (Datatypes.S O)) n) (Datatypes.S O)
       (@Mmult (Nat.pow (Datatypes.S (Datatypes.S O)) n)
          (Nat.pow (Datatypes.S (Datatypes.S O)) n)
          (Nat.pow (Datatypes.S (Datatypes.S O)) n) (translate_prog n g) UA)
       (@Mmult (Nat.pow (Datatypes.S (Datatypes.S O)) n)
          (Nat.pow (Datatypes.S (Datatypes.S O)) n) (Datatypes.S O)
          (@Mmult (Nat.pow (Datatypes.S (Datatypes.S O)) n)
             (Nat.pow (Datatypes.S (Datatypes.S O)) n)
             (Nat.pow (Datatypes.S (Datatypes.S O)) n)
             (@adjoint (Nat.pow (Datatypes.S (Datatypes.S O)) n)
                (Nat.pow (Datatypes.S (Datatypes.S O)) n) UA)
             (@adjoint (Nat.pow (Datatypes.S (Datatypes.S O)) n)
                (Nat.pow (Datatypes.S (Datatypes.S O)) n) 
                (translate_prog n g))) v)) =
                (translate_prog n g × (UA × (UA) †) × (translate_prog n g) †) × v).
      { rewrite ! Mmult_assoc. easy. }
      rewrite H1.
      destruct WFUUA as [WFUA UUA].
      destruct WFU_g as [WF_g U_g].
      apply Minv_flip in UUA; auto with wf_db.
      rewrite UUA.
      rewrite Mmult_1_r; auto with wf_db.
      apply Minv_flip in U_g; auto with wf_db.
      rewrite U_g.
      rewrite Mmult_1_l; auto with wf_db.
    - destruct WFUUA as [WFUA UUA].
      destruct WFU_g as [WF_g U_g].
      auto with wf_db.
    - apply Permutation_sym in PermA. easy. }
      
(*exists (vector_permutation (plus1idxA ++ minus1idxA) ((translate_prog n g × UA)† × v)).*)
    (** redundant if matrix_column_permutation_vector_permutation_original is proved.

    unfold matrix_column_permutation.
    unfold list_vector_to_matrix.
    unfold vector_permutation.

    unfold Mmult at 1.

    rewrite ! total_length.
    do 2 (apply functional_extensionality; intros).
    
     assert (Zero_equals : Zero = (fun i0 : nat => get_vec i0 (translate_prog n g × UA)) (2 ^ n)%nat).
      { simpl.
        remember WFU_g as WFg.  clear HeqWFg.
        remember WFUUA as WFUA. clear HeqWFUA.
        destruct WFg as [WFg Ug].
        destruct WFUA as [WFUA UUA].
        unfold WF_Matrix in WFg, WFUA.
        unfold Mmult. unfold get_vec.
        do 2 (apply functional_extensionality; intros).
        bdestruct_all. 2: easy.
        rewrite big_sum_0. 1: easy.
        intros x'. specialize (WFUA x' (2 ^ n)%nat).
        assert (precond : (x' >= 2 ^ n)%nat \/ (2 ^ n >= 2 ^ n)%nat). 1: right; lia.
        specialize (WFUA precond).
        rewrite WFUA.
        lca. }
      rewrite Zero_equals.

      assert (H' : (fun y : nat =>
                 nth y
                   (map
                      (fun i0 : nat => get_vec i0 (translate_prog n g × UA))
                      (plus1idxA ++ minus1idxA))
                   (get_vec (2 ^ n) (translate_prog n g × UA))
                   x 0%nat *
                   (@Mmult (2^n)%nat (2^n)%nat 1 (translate_prog n g × UA) † v)
                     (nth y (plus1idxA ++ minus1idxA) 0%nat) 0%nat) =
                (fun y : nat =>
                   get_vec
                     (nth y (plus1idxA ++ minus1idxA) (2 ^ n)%nat)
                     (translate_prog n g × UA)
                     x 0%nat *
                     (@Mmult (2^n)%nat (2^n)%nat 1 (translate_prog n g × UA) † v)
                       (nth y (plus1idxA ++ minus1idxA) 0%nat) 0%nat)).
      { apply functional_extensionality; intros.
        rewrite map_nth with (d := (2 ^ n)%nat) (f := (fun i0 : nat => get_vec i0 (translate_prog n g × UA))) (l := (plus1idxA ++ minus1idxA)).
        easy. }
      rewrite H'. admit. } *)
    
      (* 
      Search big_sum.
      
      remember PermA as P. clear HeqP.
      rewrite Permutation_nth in P.
      destruct P as [LenPerm [bijection [Bounded [Injective Mapping]]]].
      rewrite seq_length in LenPerm.
      Search Permutation. 
      unfold Mmult at 1.
      rewrite <- LenPerm. *)


      (** bijection: 0 1 2 3 |---> p p n n *)



      

        
   (** how about doing this as a matrix ***)
  (* u = a1 U v1 + ... + an U vn + b1 U w1 + ... + bn U wn *)
(*  assert (spans_whole_space : forall (v : Vector n),
           exists list_coef : list C,
             v =
               fold_left Mplus
                 (map (uncurry Matrix.scale)
                    (combine list_coef
                       (map (fun i : nat => @Mmult (2^n) (2^n) 1 (translate_prog n g × UA) (e_i i))
                          (plus1idxA ++ minus1idxA))))
                 Zero).
  { intros.
    pose (coef := map (fun (i:nat) => (@Mmult (2^n) (2^n) 1
                                   (@Mmult (2^n) (2^n) (2^n) (translate_prog n g) UA)†
                                   v) i 0%nat) 
                   (plus1idxA ++ minus1idxA)).
    exists coef. unfold coef.
    rewrite combine_map_list_app.
    rewrite map_app.
    rewrite fold_left_Mplus_app_Zero.
    
    admit. } *)

  

(** Definition col_append {n m} (T : Matrix n m) (v : Vector n) : Matrix n (S m)  

list_vector_to_matrix_indirect := fold_left col_append l (@Zero n 0)

l : list (Vector n)

list of vectors into matrix

list_vector_to_matrix_direct := (fun r c : nat => (nth c l (@Zero n 1)) r)
 *)


(** permutation of matrices:
 separate definition : list of indices -> list of column vectors -> permuted matrix *)




  
    (** u = b1 U w1 + ... + bn U wn
       = U A α

(U A)† u = α 
b1 = α [n]

     *)

  assert (half_length : length (minus1idxA) = (2 ^ (n-1))%nat).
  { rewrite app_length in total_length.
    rewrite equal_len_A in total_length.
    assert (H' : (2 ^ n = 2 * (2 ^ (n - 1)))%nat).
    { setoid_rewrite <- Nat.pow_1_r at 7.
      rewrite <- Nat.pow_add_r.
      assert (H' : (1 + (n - 1) = n)%nat).
      { simpl.
        rewrite Nat.sub_1_r.
        rewrite Nat.succ_pred; try easy.
        destruct Pa as [ | t a Pt Pa].
        - unfold translateA in Ua. simpl in Ua.
          apply zero_not_unitary in Ua. contradiction.
        - destruct Pt as [n_nonzero length_snd_t_is_n].
          replace (1 + (n - 1))%nat with ((n - 1) + 1)%nat by lia.
          assumption. }
      rewrite H'. reflexivity. }
    rewrite H' in total_length.
    lia. }


  (** here for reference **)
  (* <Q (U A α) = (U A α') :: use if then else to split the multiplication in the Matrix > *)
    (** spans_minus_one_space *)
    (* ( Let u be a -1 eigenvector of Q. Then Q u = - u  and 
              u = a1 U v1 + ... + an U vn + b1 U w1 + ... + bn U wn  and
<done>
              Qu = - u = (a1 U v1 + ... + an U vn) + Q (b1 U w1 + ... + bn U wn).
              Then 0 = u - u = (b1 U w1 + ... + bn U wn) + Q (b1 U w1 + ... + bn U wn)  so
              Q (b1 U w1 + ... + bn U wn) = - (b1 U w1 + ... + bn U wn).
              Then u = - (a1 U v1 + ... + an U vn) + (b1 U w1 + ... + bn U wn)  and so
              2 u = 2 (b1 U w1 + ... + bn U wn)  which gives
              u = b1 U w1 + ... + bn U wn. ) *)


(*  assert (spans_minus_one_space : forall (v : Vector n),
             Eigenpair (translateA b) (v, Copp C1) -> 
             exists coef_vec : Vector (length minus1idxA),
               v = matrix_column_permutation
                     minus1idxA
                     (translate_prog n g × UA)
                     × coef_vec). *)
  assert (spans_minus_one_space : forall (v : Vector n),
             Eigenpair (translateA b) (v, Copp C1) -> @WF_Matrix (2^n)%nat 1 v ->  
               v = matrix_column_permutation
                     minus1idxA
                     (translate_prog n g × UA)
                     × (vector_permutation minus1idxA ((translate_prog n g × UA)† × v))).
  { unfold Eigenpair. simpl. 
    intros.
   (* exists (vector_permutation minus1idxA ((translate_prog n g × UA)† × v)). *)

    specialize (spans_whole_space v H1).
    
    (* destruct spans_whole_space as [coef_vec_total v_is]. *)
    remember spans_whole_space as v_is. clear Heqv_is.
    
    apply @Mmult_inj_l with (i := (2^n)%nat) (j := (2^n)%nat) (m := translateA b) in v_is.
    rewrite H0 in v_is.
    rewrite <- Mmult_assoc in v_is.
    rewrite <- matrix_column_permutation_assoc_square in v_is.
    rewrite matrix_column_permutation_vector_permutation_app_split in v_is.
    2: destruct WFU_g as [WF_g U_g];
    destruct WFUUA as [WFUA UUA];
    auto with wf_db.

    rewrite matrix_column_permutation_vector_permutation_app_split in spans_whole_space.
    

    
    (*** is there a good way to express v_is ?? *)

    

    
    (** the following may be redundant if we can figure it out in the above *)
    
    unfold matrix_column_permutation.
    unfold list_vector_to_matrix.
    unfold vector_permutation.

    unfold Mmult at 1.

    rewrite ! half_length.
    do 2 (apply functional_extensionality; intros).
    
     assert (Zero_equals: Zero = (fun i0 : nat => get_vec i0 (translate_prog n g × UA)) (2 ^ n)%nat).
      { simpl.
        remember WFU_g as WFg.  clear HeqWFg.
        remember WFUUA as WFUA. clear HeqWFUA.
        destruct WFg as [WFg Ug].
        destruct WFUA as [WFUA UUA].
        unfold WF_Matrix in WFg, WFUA.
        unfold Mmult. unfold get_vec.
        do 2 (apply functional_extensionality; intros).
        bdestruct_all. 2: easy.
        rewrite big_sum_0. 1: easy.
        intros x'. specialize (WFUA x' (2 ^ n)%nat).
        assert (precond : (x' >= 2 ^ n)%nat \/ (2 ^ n >= 2 ^ n)%nat). 1: right; lia.
        specialize (WFUA precond).
        rewrite WFUA.
        lca. }
      rewrite Zero_equals.
      
      assert (H' : (fun y : nat =>
                 nth y
                   (map
                      (fun i0 : nat => get_vec i0 (translate_prog n g × UA))
                      minus1idxA)
                   (get_vec (2 ^ n) (translate_prog n g × UA))
                   x 0%nat *
                   (@Mmult (2^n)%nat (2^n)%nat 1 (translate_prog n g × UA) † v)
                     (nth y minus1idxA 0%nat) x0) =
                (fun y : nat =>
                   get_vec
                     (nth y minus1idxA (2 ^ n)%nat)
                     (translate_prog n g × UA)
                     x 0%nat *
                     (@Mmult (2^n)%nat (2^n)%nat 1 (translate_prog n g × UA) † v)
                       (nth y minus1idxA 0%nat) x0)).
      { apply functional_extensionality; intros.
        rewrite map_nth with (d := (2 ^ n)%nat) (f := (fun i0 : nat => get_vec i0 (translate_prog n g × UA))) (l := minus1idxA).
        easy. }
      rewrite H'.

      
      admit. }

(** here for reference **)
  (* <Q (U A α) = (U A α') :: use if then else to split the multiplication in the Matrix > *)
    (** spans_minus_one_space *)
    (* ( Let u be a -1 eigenvector of Q. Then Q u = - u  and 
              u = a1 U v1 + ... + an U vn + b1 U w1 + ... + bn U wn  and
              Qu = - u = (a1 U v1 + ... + an U vn) + Q (b1 U w1 + ... + bn U wn).
              Then 0 = u - u = (b1 U w1 + ... + bn U wn) + Q (b1 U w1 + ... + bn U wn)  so
              Q (b1 U w1 + ... + bn U wn) = - (b1 U w1 + ... + bn U wn).
              Then u = - (a1 U v1 + ... + an U vn) + (b1 U w1 + ... + bn U wn)  and so
              2 u = 2 (b1 U w1 + ... + bn U wn)  which gives
              u = b1 U w1 + ... + bn U wn. ) *)


  
(* assert (spans_minus_one_space : forall (v : Vector n),
             Eigenpair (translateA b) (v, Copp C1) -> 
             exists list_coef : list C,
             v =
               fold_left Mplus
                 (map (uncurry Matrix.scale)
                    (combine list_coef
                       (map (fun i : nat => @Mmult (2^n) (2^n) 1 (translate_prog n g × UA) (e_i i))
                          minus1idxA)))
                 Zero).
  { intros.
    pose (coef := map (fun (i:nat) => (@Mmult (2^n) (2^n) 1
                                   (@Mmult (2^n) (2^n) (2^n) (translate_prog n g) UA)†
                                   v) i 0%nat) 
                   minus1idxA).
    exists coef. unfold coef.
    
    admit. } *)


  
(** non-working old version
Lemma spans_whole_space {n} (P : Vector n -> Prop) (l : list (Vector n)) :
  forall v, P v -> exists list_coef, v = fold_left Mplus (map (uncurry Matrix.scale) (zipWith pair list_coef l)) Zero. Admitted. *)
  
  
  assert (minusA_Eigen: forall x : nat, In x minus1idxA -> Eigenpair (translateA b) (translate_prog n g × UA × e_i x, Copp C1)).
  { intros.
    unfold Eigenpair; simpl.
    unfold Eigenpair in Eigen_minus1_A; simpl in Eigen_minus1_A.
    unfold Eigenpair in *; simpl in *. 
    
    
    
    (* Since U is invertible, the assertion {P} U {Q} implies that 
        U maps the +1-eigenspace of P precisely "onto" the +1-eigenspace of Q:
        < every +1 eigenvector of Q is spanned by the image of the +1 eigenvectors of P >
        that is, forall x : nat, In x plus1idxA -> translate_prog n g × UA × e_i x 
                    "spans" the 'whole' +1 eigenspace*)

    (* Since eigenvectors corresponding to distinct eigenvalues are orthogonal, 
        +1 eigenspace is orthogonal to -1 eigenspace:
        that is, forall x : nat, (In x plus1idxA -> UA × e_i x) and (In x minus1idxA -> UA × e_i x)
                    are orthogonal *)
    
    (* U := (translate_prog n g) preserves orthogonality since it is unitary *)

    (* Since unitary matrices preserve innerproducts, 
        { U v1, U v2, ..., U vn, U w1, U w2, ..., U wn } also forms an orthonormal basis. *)

    (* U maps the -1-eigenspace of P precisely "onto" the -1-eigenspace of Q:
        1. since { U v1, U v2, ..., U vn } "spans" the +1 eigenspace of Q,
            and since the linear combination of +1 eigenspace and -1 eigenspace 
                    spans the 'whole' space
            and since { U v1, U v2, ..., U vn, U w1, U w2, ..., U wn } forms an orthonormal basis,
            { U w1, U w2, ..., U wn } "spans" the 'whole' -1 eigenspace of Q. *)


(* <Q (U A α) = (U A α') :: use if then else to split the multiplication in the Matrix > *)
    (** spans_minus_one_space *)
    (* ( Let u be a -1 eigenvector of Q. Then Q u = - u  and 
              u = a1 U v1 + ... + an U vn + b1 U w1 + ... + bn U wn  and
              Qu = - u = (a1 U v1 + ... + an U vn) + Q (b1 U w1 + ... + bn U wn).
              Then 0 = u - u = (b1 U w1 + ... + bn U wn) + Q (b1 U w1 + ... + bn U wn)  so
              Q (b1 U w1 + ... + bn U wn) = - (b1 U w1 + ... + bn U wn).
              Then u = - (a1 U v1 + ... + an U vn) + (b1 U w1 + ... + bn U wn)  and so
              2 u = 2 (b1 U w1 + ... + bn U wn)  which gives
              u = b1 U w1 + ... + bn U wn. )

              
              *)(*** 2 ?????? ***)(*
              2. since { U w1, U w2, ..., U wn } "spans" the 'whole' -1 eigenspace
                  and since the dimension of { U w1, U w2, ..., U wn } and -1 eigenspace are equal
                  { U w1, U w2, ..., U wn } is a basis of the -1 eigenspace of Q
               
               3. U wi is an -1 eigenvector of Q


UA × e_i x = get_vec x UA

Matrix & index -> col vec : get_vec

l : list of vectors, lx : list of indeces,
call vectors of index in lx from list of vectors l : map (fun n:nat => nth n l (e_i 0)) lx

span_l (l) : forall v, exists lc, v = fold_left Cplus (map (uncurry Matrix.scale) (zipWith pair lc l)) C0 
                  l : list of vectors
 
is_basis l := span_l l /\ length l = n

l := { U w1, U w2, ..., U wn } is a basis of the -1 eigenspace of Q : 
forall v,  v in -1 eigenspace -> span_l l v




     *)
    admit. } 

  unfold Eigenpair in plusA_Eigen, minusA_Eigen; simpl in *.

  assert (H': eq_eigs (translateA a) ((translate_prog n g)† × (translateA b) × (translate_prog n g))).
  { unfold eq_eigs. unfold Eigenpair. intros p H0 H1. destruct p. simpl in *.
    unfold Eigenpair in *. simpl in *. 
    (* 1. there exists only two eigenvalues: +1 or -1
--> eigenvalue norm is 1: https://books.physics.oregonstate.edu/LinAlg/eigenunitary.html
--> eigenvalue is real : ???

        2. for each eigenvalue, the corresponding eigenvector is spanned by (UA × e_i x). 


Since U is invertible, the assertion {P} U {Q} implies that 
        U maps the +1-eigenspace of P precisely "onto" the +1-eigenspace of Q:
        < every +1 eigenvector of Q is spanned by the image of the +1 eigenvectors of P >
        that is, forall x : nat, In x plus1idxA -> translate_prog n g × UA × e_i x 
                    "spans" the 'whole' +1 eigenspace


U maps the -1-eigenspace of P precisely "onto" the -1-eigenspace of Q:
        1. since { U v1, U v2, ..., U vn } "spans" the 'whole' +1 eigenspace of Q,
            and since the linear combination of +1 eigenspace and -1 eigenspace 
                    spans the 'whole' space
            and since +1 eigenspace is orthogonal to -1 eigenspace,
            and since { U v1, U v2, ..., U vn, U w1, U w2, ..., U wn } forms an orthonormal basis,
            { U w1, U w2, ..., U wn } "spans" the 'whole' -1 eigenspace.

            ( Let u be a -1 eigenvector of Q. Then Q u = - u  and 
              u = a1 U v1 + ... + an U vn + b1 U w1 + ... + bn U wn  and
              Qu = - u = (a1 U v1 + ... + an U vn) + Q (b1 U w1 + ... + bn U wn).
              Then 0 = u - u = (b1 U w1 + ... + bn U wn) + Q (b1 U w1 + ... + bn U wn)  so
              Q (b1 U w1 + ... + bn U wn) = - (b1 U w1 + ... + bn U wn).
              Then u = - (a1 U v1 + ... + an U vn) + (b1 U w1 + ... + bn U wn)  and so
              2 u = 2 (b1 U w1 + ... + bn U wn)  which gives
              u = b1 U w1 + ... + bn U wn. )


*)

  
  intros H0 H1 H2. 
  unfold vecSatisfiesP in *.
  unfold vecSatisfies in *.
  simpl in *.
  assert (H': eq_eigs (translateA a) ((translate_prog n g)† × (translateA b) × (translate_prog n g))).
  { unfold eq_eigs. intros p H3 H4.
    destruct p. simpl in *.
    apply eig_unit_conv; auto with unit_db. Admitted. (*
    specialize (H2 m).
    simpl in *.
    assert (WF_Matrix m /\ Eigenpair (translateA a) (m, c)). { auto. } *)
(*
    apply H2 in H5.
    destruct H5.
    assumption. }
  apply eq_eigs_implies_eq_unit in H'; auto with unit_db.
  rewrite H'.
  rewrite <- ! Mmult_assoc.
  assert (WF_Unitary (translate_prog n g)). { auto with unit_db. }
  unfold WF_Unitary in H3.
  destruct H3.
  apply Minv_flip in H4; auto with wf_db.
  rewrite H4.
  rewrite Mmult_1_l.
  reflexivity.
  destruct H1.
  assumption.
Qed.*)


  
Lemma Heisenberg_Eigenvector_semantics {n} (a b : AType n) (g : prog) : 
  ((translate_prog n g) × translateA a = translateA b × (translate_prog n g)) ->
  {{ G a }} g {{ G b }}.
Proof. 
  intros H0 v H1.
  unfold vecSatisfiesP in *.
  unfold vecSatisfies in *.
  simpl in *.
  destruct H1.
  split.
  - auto with wf_db.
  - unfold Eigenpair in *. simpl in *.
    rewrite <- Mmult_assoc.
    rewrite <- H0.
    rewrite Mmult_assoc.
    setoid_rewrite H2.
    distribute_scale.
    reflexivity.
Qed.
..



(** ** not needed?
(*** Admitted ***)
(** *** Heisenberg semantics should work for ATypes. *)
Lemma Eigenvector_Heisenberg_semantics' {n} (a b : AType n) (g : prog) : 
  WF_Unitary (translateA a) -> WF_Unitary (translateA b) ->
  (forall v : Vector (2^n), vecSatisfiesP' v (G a) -> vecSatisfiesP' ((translate_prog n g) × v) (G b)) -> ((translate_prog n g) × translateA a = translateA b × (translate_prog n g)).
Proof. 
  intros H0 H1 H2. 
  unfold vecSatisfiesP' in *.
  unfold vecSatisfies' in *.
  simpl in *.
  assert (H': eq_eigs (translateA a) ((translate_prog n g)† × (translateA b) × (translate_prog n g))).
  { unfold eq_eigs. intros p H3 H4.
    destruct p. simpl in *.
    apply eig_unit_conv; auto with unit_db.
    specialize (H2 m).
    simpl in *.
    assert (WF_Matrix m /\ Eigenpair (translateA a) (m, c)). { auto. }
(*
    apply H2 in H5.
    destruct H5.
    assumption. }
  apply eq_eigs_implies_eq_unit in H'; auto with unit_db.
  rewrite H'.
  rewrite <- ! Mmult_assoc.
  assert (WF_Unitary (translate_prog n g)). { auto with unit_db. }
  unfold WF_Unitary in H3.
  destruct H3.
  apply Minv_flip in H4; auto with wf_db.
  rewrite H4.
  rewrite Mmult_1_l.
  reflexivity.
  destruct H1.
  assumption.
Qed.*)
Admitted.


Lemma Heisenberg_Eigenvector_semantics' {n} (a b : AType n) (g : prog) : 
  ((translate_prog n g) × translateA a = translateA b × (translate_prog n g)) ->
  (forall v : Vector (2^n), vecSatisfiesP' v (G a) -> vecSatisfiesP' ((translate_prog n g) × v) (G b)).
Proof. 
  intros H0 v H1.
  unfold vecSatisfiesP' in *.
  unfold vecSatisfies' in *.
  simpl in *.
  destruct H1 as [H1 H2].
  split.
  - auto with wf_db.
  - unfold Eigenpair in *. simpl in *.
    rewrite <- Mmult_assoc.
    rewrite <- H0.
    rewrite Mmult_assoc.
    destruct H2 as [x H2].
    exists x.
    setoid_rewrite H2.
    distribute_scale.
    reflexivity.
Qed.
*)


(** ** rules ** **)


Definition ith_TType {n} (bit : nat) (T : TType n) : Pauli :=
  match T with
  | (c, l) => nth bit l gI
  end.

Compute @ith_TType 4 (0) (C1, [gI;gX;gY;gZ]).


Definition ith_switch_TType {n} (bit : nat) (T : TType n) (T' : TType 1) : TType n :=
  match T with
  | (c, l) => match T' with
              | (c', l') => ((c * c')%C, switch l (hd gI l') bit)
              end
  end.

Compute @ith_switch_TType 4 (0) (C1, [gI;gX;gY;gZ]) (C1, [gX]).


Local Open Scope nat_scope.

(** ** not needed?
Ltac unfold_triple  :=
  unfold triple in *;
  repeat (match goal with
          | H : _ /\ is_Heisenberg_triple _ _ _ |- _ => destruct H
          end;
          try match goal with
            | H : is_Heisenberg_triple (G _) _ (G _) |- _ => inversion H; clear H
            end;
          repeat match goal with
            | H : CPredicate (G _) |- _ => inversion H
            | H : APredicate (G _) |- _ => clear H
            | H : APredicate _ |- _ => inversion H; clear H; subst
            | H : translate_prog _ _ × translateP (G _) =
                    translateP (G _) × translate_prog _ _  |- _ => simpl in H
            end);
  try split; simpl;
  try(apply Heisenberg_neg_l; constructor);
  try(apply Heisenberg_neg_r; constructor);
  try(apply Heisenberg_Err_l);
  try(apply Heisenberg_Err_r);
  try(apply Heisenberg;
      match goal with
      | |- APredicate (G _) => constructor
      | |- translate_prog _ _ × translateP (G _) =
             translateP (G _) × translate_prog _ _  => simpl
      end).

Ltac unfold_triple  :=
  unfold triple in *;
  unfold tripleA in *;
  repeat (match goal with
          | H : _ /\ is_Heisenberg_triple _ _ _ |- _ => destruct H
          end;
          try match goal with
            | H : is_Heisenberg_triple _ _ _ |- _ => inversion H; clear H
            end;
          repeat match goal with
            | H : translate_prog _ _ × translateA _ =
                    translateA _ × translate_prog _ _  |- _ => simpl in H
            end);
  try split; simpl in *;
  try(apply Heisenberg;
      match goal with
      | |- translate_prog _ _ × translateA _ =
             translateA _ × translate_prog _ _  => simpl
      end).
*)

Lemma SCALE_Heisenberg : forall {n} (c : Coef) (a a' : AType n) (g : prog),
    {{ a }} g {{ a' }} -> {{ gScaleA c a }} g {{ gScaleA c a' }}.
Proof. 
  intros n c a a' g H0.
  unfold_triple.
  unfold triple_vecA.
  apply Heisenberg_Eigenvector_semantics.
Admitted.
  

Lemma MUL_Heisenberg : forall {n} (a b a' b' : AType n) (g : prog),
    {{ a }} g {{ b }} -> {{ a' }} g {{ b' }} -> {{ gMulA a a' }} g {{ gMulA b b' }}.
Proof.
  intros n a b a' b' g H0 H1.
  unfold_triple.
  unfold triple_vecA.
  apply Heisenberg_Eigenvector_semantics.
Admitted.



Lemma CAP_Heisenberg_PP : forall {n} (A A' B B' : Predicate n) (g : prog),
    {{{ A }}} g {{{ A' }}} -> {{{ B }}} g {{{ B' }}} -> {{{ A ∩ B }}} g {{{ A' ∩ B' }}}.
Proof.
  intros n A A' B B' g H0 H1.
  unfold_triple.
  all: unfold triple_vec in *.
  all: simpl in *.
  all: destruct H2.
  - specialize (H0 v H2). easy.
  - specialize (H1 v H3). easy.
Qed.

Lemma CAP_HeisenbergAA : forall {n} (A A' B B' : AType n) (g : prog),
    {{ A }} g {{ A' }} -> {{ B }} g {{ B' }} -> {{{ G A ∩ G B }}} g {{{ G A' ∩ G B' }}}.
Proof.
  intros n A A' B B' g H0 H1.
  unfold_triple; subst; unfold triple_vecA in *.
  all: destruct H2.
  - specialize (H0 v H2). easy.
  - specialize (H1 v H4). easy.
Qed.

Lemma CAP_HeisenbergPA : forall {n} (a a' : AType n) (B B' : Predicate n) (g : prog),
    {{ a }} g {{ a' }} -> {{{ B }}} g {{{ B' }}} -> {{{ G a ∩ B }}} g {{{ G a' ∩ B' }}}.
Proof.
  intros n a a' B B' g H0 H1.
  unfold_triple; subst; unfold triple_vecA in *; unfold triple_vec in *.
  all: destruct H2.
  - specialize (H0 v H2). easy.
  - specialize (H1 v H4). easy.
Qed.

Lemma CONS_HeisenbergA : forall {n} (A' A B B' : AType n) (g : prog),
    A' ⇒A A -> {{ A }} g {{ B }} -> B ⇒A B' -> {{ A' }} g {{ B' }}.
Proof.
  intros n A' A B B' g H0 H1 H2.
  unfold_triple; subst.
  all: unfold triple_vecA in *.
  intros v H3. 
  apply interpret_impliesA with (v := v) in H0; try easy.
  apply interpret_impliesA with (v := translate_prog n g × v) in H2; try easy.
  specialize (H1 v H0); try easy.
  
  destruct H0; 
    destruct H2; try easy.
Admitted.

Lemma CONS_HeisenbergP : forall {n} (A' A B B' : Predicate n) (g : prog),
    A' ⇒P A -> {{{ A }}} g {{{ B }}} -> B ⇒P B' -> {{{ A' }}} g {{{ B' }}}.
Proof.
  intros n A' A B B' g H0 H1 H2.
  unfold_triple.
  unfold triple_vec.
  intros v H4.
  apply interpret_impliesP with (v := v) in H0; try easy.
  apply interpret_impliesP with (v := translate_prog n g × v) in H2; try easy.
  specialize (H1 v H0); try easy.
Qed.

Lemma prog_simpl_inc_reduce : forall (p : nat -> prog) (prg_len bit : nat),
  simpl_prog p -> bit < prg_len ->
  translate_prog prg_len (p bit) = 
  (Matrix.I (2^bit)) ⊗ translate_prog 1 (p 0) ⊗ (Matrix.I (2^(prg_len - bit - 1))).
Proof. intros p prg_len bit H0 H1. 
       destruct H0; [ | destruct H0];
         do 2 (rewrite H0); 
         simpl;
         unfold prog_simpl_app;
         bdestruct_all;
         rewrite Nat.sub_0_r, Nat.sub_diag, 
                 Nat.pow_0_r, kron_1_l, kron_1_r; auto with wf_db.
Qed.


Lemma prog_ctrl_reduce : forall (prg_len ctrl targ : nat),
  translate_prog (s prg_len) (CNOT (s ctrl) (s targ)) = 
  (Matrix.I 2) ⊗ translate_prog prg_len (CNOT ctrl targ).
Proof. intros.    
       unfold translate_prog, prog_ctrl_app.
       bdestruct_all; simpl.
       all : try (rewrite id_kron, Nat.add_0_r, double_mult; easy).
       - replace (2 ^ ctrl + (2 ^ ctrl + 0)) with (2 * 2^ctrl) by lia. 
         rewrite <- id_kron.
         repeat rewrite kron_assoc; auto with wf_db.  
         repeat rewrite Nat.add_0_r. repeat rewrite double_mult.
         replace 2 with (2^1) by easy. 
         repeat rewrite <- Nat.pow_add_r. 
         replace (ctrl + ((1 + (targ - ctrl)) + (prg_len - targ - 1))) with prg_len by lia; 
         easy. 
       - replace (2 ^ targ + (2 ^ targ + 0)) with (2 * 2^targ) by lia. 
         rewrite <- id_kron.
         repeat rewrite kron_assoc; auto with wf_db.  
         repeat rewrite Nat.add_0_r. repeat rewrite double_mult.
         replace 2 with (2^1) by easy. 
         repeat rewrite <- Nat.pow_add_r. 
         replace (targ + (((ctrl - targ) + 1) + (prg_len - ctrl - 1))) with prg_len by lia;
         easy. 
Qed.

Lemma WF_helper : forall (l : list Pauli) (i : nat),
  WF_Matrix (nth i (map translate_P l) Zero).
Proof. intros. 
       destruct (nth_in_or_default i0 (map translate_P l) Zero).
       - apply in_map_iff in i1.
         destruct i1 as [x [H H0] ].
         rewrite <- H.
         apply WF_Matrix_Pauli.
       - rewrite e. easy. 
Qed.

Lemma WF_helper2 : forall {bit} (l : list Pauli), 
  length l = bit ->
  @WF_Matrix (2^ bit) (2^ bit) (⨂ map translate_P l).
Proof. intros; subst.
       assert (H' := (WF_big_kron _ _ (map translate_P l) Zero)).
       rewrite map_length in H'.
       apply H'.
       intros; apply WF_helper.
Qed.

Hint Resolve WF_helper WF_helper2 : wf_db.

Lemma kron_simplify : forall (n m o p : nat) (a b : Matrix n m) (c d : Matrix o p), 
    a = b -> c = d -> a ⊗ c = b ⊗ d.
Proof. intros n m o p a b c d H H0.
       rewrite H, H0.
       easy.
Qed.


(*** Admitted ***)
Lemma TEN1_HeisenbergA : forall (prg_len bit : nat) (c : Coef) (l : list Pauli) (c0 : Coef) (A : Pauli) (U : nat -> prog),
    bit < prg_len -> simpl_prog U -> (c0 * c0 ^* )%C = C1 -> length l = prg_len ->
    @tripleA 1 ( [ (C1, [nth bit l gI]) ] ) (U 0) ([ (c0, [A]) ] ) ->
    @tripleA prg_len ( [(c, l)] ) (U bit) ( [((c * c0)%C, switch l A bit)] ).
Proof. intros prg_len bit c l c0 A U i_lessthan_n simpl_prog_U c_unit length_l_is_n H0.
  unfold tripleA in *.
  unfold triple_vecA in *.
  destruct H0.
  inversion H1; subst.
  apply Heisenberg_Eigenvector_semantics.
  apply Eigenvector_Heisenberg_semantics_pair in H0.
  3:{ unfold translateA. unfold translate. simpl. rewrite Mplus_0_l.
      rewrite kron_1_r. apply unit_scale; try assumption. apply WF_Unitary_Pauli. }
  2:{ unfold translateA. unfold translate. simpl. rewrite Mplus_0_l.
      rewrite kron_1_r. rewrite Mscale_1_l. apply WF_Unitary_Pauli. }
  unfold translateA in *.
  unfold translate in *.
  simpl in *.
  rewrite ! Mplus_0_l in *.
  rewrite ! kron_1_r in *.
  rewrite Mscale_1_l in *.
  subst.
  rewrite (nth_inc bit l gI); auto.
  repeat rewrite map_app.  
  rewrite <- (nth_inc bit l gI); auto. 
  rewrite switch_inc; auto.
  repeat rewrite map_app.
  repeat rewrite big_kron_app; try (intros; try rewrite <- map_app; apply WF_helper).
  repeat rewrite app_length.
  repeat rewrite map_length.
  rewrite firstn_length_le, skipn_length; try lia.
  do 4 rewrite Nat.pow_add_r.
  do 2 rewrite <- Mscale_kron_dist_r, <- Mscale_kron_dist_l.
  subst.
  rewrite prog_simpl_inc_reduce; auto.
  rewrite kron_assoc; auto with wf_db.
  replace (length l - bit - 1) with (length l - s bit) by lia.
  repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ (2 ^ (length l))); 
    try (simpl; lia).
  apply kron_simplify.
  rewrite Mmult_1_l, Mmult_1_r; try easy; try apply WF_helper2.
  all : try (apply firstn_length_le; lia).
  repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ ((2^1) * (2^(length l - s bit)))); 
    try (simpl; lia).  
  apply kron_simplify. simpl.
  rewrite ! kron_1_r.
  rewrite Mscale_mult_dist_r.
  rewrite H0.
  rewrite ! Mscale_mult_dist_l.
  rewrite Mscale_assoc. 
  easy.
  all : try (left; try rewrite Mscale_1_l; easy).
  assert (H' := (WF_big_kron _ _ (map translate_P (skipn (s bit) l)))).
  rewrite map_length, skipn_length in H'; try lia. 
  rewrite Mmult_1_l, Mmult_1_r; try easy.
  all : try apply (H' Zero); intros. 
  all : try apply WF_helper.
  all : try (simpl length; do 2 rewrite <- Nat.pow_add_r; apply pow_components; lia).



       
  unfold triple in *.
  unfold triple_vec in *.
  intros v H1.
  unfold vecSatisfiesP in *.
  unfold vecSatisfies in *.
  unfold Eigenpair  in *.
  simpl in *.
  unfold translateA in *.
  simpl in *.
  rewrite ! Mplus_0_l in *.
  unfold translate in *.
  simpl in *.
  setoid_rewrite Mscale_1_l in H0.
  rewrite ! Mscale_1_l in *.
  rewrite ! kron_1_r in *.
  destruct H1.
  split; auto 15 with wf_db.

  rewrite prog_simpl_inc_reduce; auto.
  
  rewrite (nth_inc bit l gI) in H2; subst; auto.
  repeat rewrite map_app in H2.
  rewrite 2 big_kron_app in H2; try (intros; try rewrite <- map_app; apply WF_helper).
  repeat rewrite app_length in H2.
  repeat rewrite map_length in H2.
  rewrite firstn_length_le, skipn_length in H2; try lia.


  rewrite switch_inc; auto.
  repeat rewrite map_app.
  repeat rewrite big_kron_app; try (intros; try rewrite <- map_app; apply WF_helper).
  repeat rewrite app_length.
  repeat rewrite map_length.
  rewrite firstn_length_le, skipn_length; try lia.
  rewrite prog_simpl_inc_reduce; auto.
  rewrite ! kron_assoc; auto with wf_db.
  replace (length l - bit - 1) with (length l - s bit) by lia.
  Admitted. 




















































































































































(** triple_vec /\ is_Heisenberg_triple **)
Ltac compute_triple :=
  unfold triple in *;
  split; [idtac | 
           try (constructor; try easy; simpl;
                unfold translateA, prog_simpl_app, prog_ctrl_app, translate;
                bdestruct_all; simpl;
                try rewrite ! kron_1_l; try rewrite ! kron_1_r; try rewrite ! Mplus_0_l;
                try rewrite ! Cmult_1_l; try rewrite ! Mscale_1_l;
                auto with wf_db; try pauli_matrix_computation)];
  intros v vecSatisfiesPreCond;
  simpl in *;
  unfold translateA in *;
  simpl in *;
  try rewrite ! Mplus_0_l in *;
  unfold translate in *;
  simpl in *;
  try rewrite ! Cmult_1_l in *;
  try rewrite ! Cmult_1_r in *;
  try rewrite ! Mscale_1_l in *;
  try rewrite ! kron_1_r in *;
  unfold vecSatisfies in *;
  destruct vecSatisfiesPreCond as [WF_Matrixv C1Eigenpair];
  unfold prog_simpl_app;
  unfold prog_ctrl_app;
  simpl;
  split;
  auto 15 with wf_db;
  unfold Eigenpair in *;
  simpl in *;
  try rewrite ! kron_1_l;
  try rewrite ! kron_1_r;
  try rewrite Mscale_1_l in *;
  auto 15 with wf_db;
  try rewrite <- ! Mmult_assoc.

(* triple_vec *)
(*
Ltac compute_triple :=
  unfold triple in *;
  intros v vecSatisfiesPreCond;
  simpl in *;
  unfold translateA in *;
  simpl in *;
  try rewrite ! Mplus_0_l in *;
  unfold translate in *;
  simpl in *;
  try rewrite ! Cmult_1_l in *;
  try rewrite ! Cmult_1_r in *;
  try rewrite ! Mscale_1_l in *;
  try rewrite ! kron_1_r in *;
  unfold vecSatisfies in *;
  destruct vecSatisfiesPreCond as [WF_Matrixv C1Eigenpair];
  unfold prog_simpl_app;
  unfold prog_ctrl_app;
  simpl;
  split;
  auto 15 with wf_db;
  unfold Eigenpair in *;
  simpl in *;
  try rewrite ! kron_1_l;
  try rewrite ! kron_1_r;
  try rewrite Mscale_1_l in *;
  auto 15 with wf_db;
  try rewrite <- ! Mmult_assoc.
*)

(* triple_vec' *)
(* 
Ltac compute_triple :=
  unfold triple in *;
  intros v vecSatisfiesPreCond;
  simpl in *;
  unfold translateA in *;
  simpl in *;
  try rewrite ! Mplus_0_l in *;
  unfold translate in *;
  simpl in *;
  try rewrite ! Cmult_1_l in *;
  try rewrite ! Cmult_1_r in *;
  try rewrite ! Mscale_1_l in *;
  try rewrite ! kron_1_r in *;
  unfold vecSatisfies in *;
  destruct vecSatisfiesPreCond as [WF_Matrixv existsEigenpair];
  unfold prog_simpl_app;
  unfold prog_ctrl_app;
  simpl;
  split;
  auto 15 with wf_db;
  destruct existsEigenpair as [xx Eigenpairvxx];
  unfold Eigenpair in *;
  simpl in *;
  try rewrite ! kron_1_l;
  try rewrite ! kron_1_r;
  auto 15 with wf_db;
  try rewrite <- ! Mmult_assoc.
 *)

(* triple_pair *)
(*
Ltac compute_triple :=
  unfold triple in *;
  intros v pairSatisfiesPreCond;
  simpl in *;
  unfold translateA in *;
  simpl in *;
  try rewrite ! Mplus_0_l in *;
  unfold translate in *;
  simpl in *;
  try rewrite ! Cmult_1_l in *;
  try rewrite ! Cmult_1_r in *;
  try rewrite ! Mscale_1_l in *;
  try rewrite ! kron_1_r in *;
  unfold pairSatisfies in *;
  destruct pairSatisfiesPreCond as [WF_Matrixv isEigenpair];
  unfold prog_simpl_app;
  unfold prog_ctrl_app;
  simpl;
  split;
  auto 15 with wf_db;
  unfold Eigenpair in *;
  simpl in *;
  try rewrite ! kron_1_l;
  try rewrite ! kron_1_r;
  auto 15 with wf_db;
  try rewrite <- ! Mmult_assoc.
*)




Lemma iYHiY : {{ i pY }} H 0 {{ -i pY }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert (-C1 .* σy × hadamard = hadamard × σy). { lma'. }
  assert (- C1 * Ci = Ci * - C1)%C. { lca. }
  setoid_rewrite H1.
  rewrite <- Mscale_assoc.
  rewrite Mscale_mult_dist_l.
  setoid_rewrite H0.
  rewrite <- Mscale_mult_dist_r.
  rewrite Mmult_assoc.
  setoid_rewrite C1Eigenpair.
  reflexivity.
Qed.

Lemma YHY : {{ pY }} H 0 {{ - pY }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert (-C1 .* σy × hadamard = hadamard × σy). { lma'. }
  setoid_rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite C1Eigenpair.
  reflexivity.
Qed.

Lemma Y2H2Y : {{ C2 ·' pY }} H 0 {{ (- C2)%C ·' pY }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert (σy × hadamard = -C1 .* hadamard × σy). { lma'. }
  rewrite Mscale_mult_dist_l.
  setoid_rewrite H0.
  distribute_scale.
  rewrite Mmult_assoc.
  assert (- C2 * - C1 =  C2)%C. { lca. }
  rewrite H1.
  rewrite <- Mscale_mult_dist_r.
  setoid_rewrite <- Mscale_mult_dist_l.
  rewrite C1Eigenpair.
  reflexivity.
Qed.

Lemma XHZ : {{ pX }} H 0 {{ pZ }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert ( σz × hadamard = hadamard × σx ). { lma'. }
  rewrite H0.
  rewrite Mmult_assoc.
  rewrite C1Eigenpair.
  reflexivity.

  (** triple_vec' **)
  (* compute_triple.
  assert ( σz × hadamard = hadamard × σx ). { lma'. }
  rewrite H0.
  rewrite Mmult_assoc.
  rewrite Eigenpairvxx.
  rewrite Mscale_mult_dist_r.
  exists xx.
  reflexivity. *)

  (** triple_pair **)
  (* compute_triple.
  assert ( σz × hadamard = hadamard × σx ). { lma'. }
  rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite isEigenpair.
  rewrite Mscale_mult_dist_r.
  reflexivity. *)
Qed.


Lemma X2H2Z : {{ C2 ·' pX }} H 0 {{ C2 ·' pZ }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert ( σz × hadamard = hadamard × σx ). { lma'. }
  rewrite Mscale_mult_dist_l.
  setoid_rewrite H0.
  distribute_scale.
  rewrite Mmult_assoc.
  rewrite <- Mscale_mult_dist_r.
  setoid_rewrite <- Mscale_mult_dist_l.
  rewrite C1Eigenpair.
  reflexivity.
Qed.


Lemma ZHX : {{ pZ }} H 0 {{ pX }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert ( σx × hadamard = hadamard × σz ). { lma'. }
  rewrite H0.
  rewrite Mmult_assoc.
  rewrite C1Eigenpair.
  reflexivity.
  
  (** triple_vec' **)
  (* compute_triple.
  assert ( σx × hadamard = hadamard × σz ). { lma'. }
  rewrite H0.
  rewrite Mmult_assoc.
  rewrite Eigenpairvxx.
  rewrite Mscale_mult_dist_r.
  exists xx.
  reflexivity. *)

  (** triple_pair **)
  (* compute_triple.
  assert ( σx × hadamard = hadamard × σz ). { lma'. }
  rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite isEigenpair.
  rewrite Mscale_mult_dist_r.
  reflexivity. *)
Qed.

Lemma XSY : {{ pX }} S 0 {{ pY }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert ( σy × Phase = Phase × σx ). { pauli_matrix_computation. }
  rewrite H0.
  rewrite Mmult_assoc.
  rewrite C1Eigenpair.
  reflexivity.
  
  (** triple_vec' **)
  (* compute_triple.
  assert ( σy × Phase = Phase × σx ). { pauli_matrix_computation. }
  rewrite H0.
  rewrite Mmult_assoc.
  rewrite Eigenpairvxx.
  rewrite Mscale_mult_dist_r.
  exists xx.
  reflexivity. *)

  (** triple_pair **)
  (* compute_triple.
  assert ( σy × Phase = Phase × σx ). { pauli_matrix_computation. }
  rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite isEigenpair.
  rewrite Mscale_mult_dist_r.
  reflexivity. *)
Qed.

Lemma ZSZ : {{ pZ }} S 0 {{ pZ }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert ( σz × Phase = Phase × σz ). { lma'. }
  rewrite H0.
  rewrite Mmult_assoc.
  rewrite C1Eigenpair.
  reflexivity.
  
  (** triple_vec' **)
  (* compute_triple.
  assert ( σz × Phase = Phase × σz ). { lma'. }
  rewrite H0.
  rewrite Mmult_assoc.
  rewrite Eigenpairvxx.
  rewrite Mscale_mult_dist_r.
  exists xx.
  reflexivity. *)

  (** triple_pair **)
  (* compute_triple.
  assert ( σz × Phase = Phase × σz ). { lma'. }
  rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite isEigenpair.
  rewrite Mscale_mult_dist_r.
  reflexivity. *)
Qed.

Lemma ZTZ : {{ pZ }} T 0 {{ pZ }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert ( σz × phase_shift (PI / 4) = phase_shift (PI / 4) × σz ). { lma'. }
  rewrite H0.
  rewrite Mmult_assoc.
  rewrite C1Eigenpair.
  reflexivity.
  
  (** triple_vec' **)
  (* compute_triple.
  assert ( σz × phase_shift (PI / 4) = phase_shift (PI / 4) × σz ). { lma'. }
  rewrite H0.
  rewrite Mmult_assoc.
  rewrite Eigenpairvxx.
  rewrite Mscale_mult_dist_r.
  exists xx.
  reflexivity. *)

  (** triple_pair **)
  (* compute_triple.
  assert ( σz × phase_shift (PI / 4) = phase_shift (PI / 4) × σz ). { lma'. }
  rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite isEigenpair.
  rewrite Mscale_mult_dist_r.
  reflexivity. *)
Qed.

Lemma XTXY : {{ pX }} T 0 {{ (C1/√2)%C ·' (pX +' pY) }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert ( (C1 / √ 2 .* σx .+ C1 / √ 2 .* σy) × phase_shift (PI / 4) = phase_shift (PI / 4) × σx ). { pauli_matrix_computation. }
  rewrite H0.
  rewrite Mmult_assoc.
  rewrite C1Eigenpair.
  reflexivity.
  
  (** triple_vec' **)
  (* compute_triple.
  assert ( (C1 / √ 2 .* σx .+ C1 / √ 2 .* σy) × phase_shift (PI / 4) = phase_shift (PI / 4) × σx ). { pauli_matrix_computation. }
  rewrite H0.
  rewrite Mmult_assoc.
  rewrite Eigenpairvxx.
  rewrite Mscale_mult_dist_r.
  exists xx.
  reflexivity. *)

  (** triple_pair **)
  (* compute_triple.
  assert ( (C1 / √ 2 .* σx .+ C1 / √ 2 .* σy) × phase_shift (PI / 4) = phase_shift (PI / 4) × σx ). { pauli_matrix_computation. }
  rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite isEigenpair.
  rewrite Mscale_mult_dist_r.
  reflexivity. *)
Qed.

Lemma XICNOTXX : {{ pX ⊗' pI }} CNOT 0 1 {{ pX ⊗' pX }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert ( (σx ⊗ σx) × (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) = (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) × (σx ⊗ I 2) ). { lma'. }
  setoid_rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite C1Eigenpair.
  reflexivity.
  
  (** triple_vec' **)
  (* compute_triple.
  assert ( (σx ⊗ σx) × (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) = (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) × (σx ⊗ I 2) ). { lma'. }
  setoid_rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite Eigenpairvxx.
  rewrite Mscale_mult_dist_r.
  exists xx.
  reflexivity. *)

  (** triple_pair **)
  (* compute_triple.
  assert ( (σx ⊗ σx) × (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) = (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) × (σx ⊗ I 2) ). { lma'. }
  setoid_rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite isEigenpair.
  rewrite Mscale_mult_dist_r.
  reflexivity. *)
Qed.

Lemma IXCNOTIX : {{ pI ⊗' pX }} CNOT 0 1 {{ pI ⊗' pX }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert ( (I 2 ⊗ σx) × (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) = (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) × (I 2 ⊗ σx) ). { lma'. }
  setoid_rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite C1Eigenpair.
  reflexivity.
  
  (** triple_vec' **)
  (* compute_triple.
  assert ( (I 2 ⊗ σx) × (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) = (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) × (I 2 ⊗ σx) ). { lma'. }
  setoid_rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite Eigenpairvxx.
  rewrite Mscale_mult_dist_r.
  exists xx.
  reflexivity. *)

  (** triple_pair **)
  (* compute_triple.
  assert ( (I 2 ⊗ σx) × (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) = (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) × (I 2 ⊗ σx) ). { lma'. }
  setoid_rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite isEigenpair.
  rewrite Mscale_mult_dist_r.
  reflexivity. *)
Qed.

Lemma ZICNOTZI : {{ pZ ⊗' pI }} CNOT 0 1 {{ pZ ⊗' pI }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert ( (σz ⊗ I 2) × (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) = (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) × (σz ⊗ I 2) ). { lma'. }
  setoid_rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite C1Eigenpair.
  reflexivity.
  
  (** triple_vec' **)
  (* compute_triple.
  assert ( (σz ⊗ I 2) × (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) = (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) × (σz ⊗ I 2) ). { lma'. }
  setoid_rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite Eigenpairvxx.
  rewrite Mscale_mult_dist_r.
  exists xx.
  reflexivity. *)

  (** triple_pair **)
  (* compute_triple.
  assert ( (σz ⊗ I 2) × (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) = (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) × (σz ⊗ I 2) ). { lma'. }
  setoid_rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite isEigenpair.
  rewrite Mscale_mult_dist_r.
  reflexivity. *)
Qed.

Lemma IZCNOTZZ : {{ pI ⊗' pZ }} CNOT 0 1 {{ pZ ⊗' pZ }}.
Proof.
  (** triple_vec **)
  compute_triple.
  assert ( (σz ⊗ σz) × (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) = (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) × (I 2 ⊗ σz) ). { lma'. }
  setoid_rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite C1Eigenpair.
  reflexivity.
  
  (** triple_vec' **)
  (* compute_triple.
  assert ( (σz ⊗ σz) × (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) = (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) × (I 2 ⊗ σz) ). { lma'. }
  setoid_rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite Eigenpairvxx.
  rewrite Mscale_mult_dist_r.
  exists xx.
  reflexivity. *)

  (** triple_pair **)
  (* compute_triple.
  assert ( (σz ⊗ σz) × (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) = (∣0⟩⟨0∣ ⊗ I 2 .+ ∣1⟩⟨1∣ ⊗ σx) × (I 2 ⊗ σz) ). { lma'. }
  setoid_rewrite H0.
  rewrite Mmult_assoc.
  setoid_rewrite isEigenpair.
  rewrite Mscale_mult_dist_r.
  reflexivity. *)
Qed.


Lemma prog_simpl_inc_reduce : forall (p : nat -> prog) (prg_len bit : nat),
  simpl_prog p -> bit < prg_len ->
  translate_prog prg_len (p bit) = 
  (Matrix.I (2^bit)) ⊗ translate_prog 1 (p 0) ⊗ (Matrix.I (2^(prg_len - bit - 1))).
Proof. intros p prg_len bit H0 H1. 
       destruct H0; [ | destruct H0];
         do 2 (rewrite H0); 
         simpl;
         unfold prog_simpl_app;
         bdestruct_all;
         rewrite Nat.sub_0_r, Nat.sub_diag, 
                 Nat.pow_0_r, kron_1_l, kron_1_r; auto with wf_db.
Qed.


Lemma prog_ctrl_reduce : forall (prg_len ctrl targ : nat),
  translate_prog (s prg_len) (CNOT (s ctrl) (s targ)) = 
  (Matrix.I 2) ⊗ translate_prog prg_len (CNOT ctrl targ).
Proof. intros.    
       unfold translate_prog, prog_ctrl_app.
       bdestruct_all; simpl.
       all : try (rewrite id_kron, Nat.add_0_r, double_mult; easy).
       - replace (2 ^ ctrl + (2 ^ ctrl + 0)) with (2 * 2^ctrl) by lia. 
         rewrite <- id_kron.
         repeat rewrite kron_assoc; auto with wf_db.  
         repeat rewrite Nat.add_0_r. repeat rewrite double_mult.
         replace 2 with (2^1) by easy. 
         repeat rewrite <- Nat.pow_add_r. 
         replace (ctrl + ((1 + (targ - ctrl)) + (prg_len - targ - 1))) with prg_len by lia; 
         easy. 
       - replace (2 ^ targ + (2 ^ targ + 0)) with (2 * 2^targ) by lia. 
         rewrite <- id_kron.
         repeat rewrite kron_assoc; auto with wf_db.  
         repeat rewrite Nat.add_0_r. repeat rewrite double_mult.
         replace 2 with (2^1) by easy. 
         repeat rewrite <- Nat.pow_add_r. 
         replace (targ + (((ctrl - targ) + 1) + (prg_len - ctrl - 1))) with prg_len by lia;
         easy. 
Qed.

Lemma WF_helper : forall (l : list Pauli) (i : nat),
  WF_Matrix (nth i (map translate_P l) Zero).
Proof. intros. 
       destruct (nth_in_or_default i0 (map translate_P l) Zero).
       - apply in_map_iff in i1.
         destruct i1 as [x [H H0] ].
         rewrite <- H.
         apply WF_Matrix_Pauli.
       - rewrite e. easy. 
Qed.

Lemma WF_helper2 : forall {bit} (l : list Pauli), 
  length l = bit ->
  @WF_Matrix (2^ bit) (2^ bit) (⨂ map translate_P l).
Proof. intros; subst.
       assert (H' := (WF_big_kron _ _ (map translate_P l) Zero)).
       rewrite map_length in H'.
       apply H'.
       intros; apply WF_helper.
Qed.

Hint Resolve WF_helper WF_helper2 : wf_db.

Lemma kron_simplify : forall (n m o p : nat) (a b : Matrix n m) (c d : Matrix o p), 
    a = b -> c = d -> a ⊗ c = b ⊗ d.
Proof. intros n m o p a b c d H H0.
       rewrite H, H0.
       easy.
Qed.

Lemma TEN1_pair : forall (prg_len bit : nat) (c : Coef) (l : list Pauli) (c0 : Coef) (A : Pauli) (U : nat -> prog),
    bit < prg_len -> simpl_prog U -> (c0 * c0 ^* )%C = C1 -> length l = prg_len ->
    triple_pair (@G 1 [ (C1, [nth bit l gI]) ] ) (U 0) (@G 1 [ (c0, [A]) ] ) ->
    triple_pair (@G prg_len [(c, l)] ) (U bit) (@G prg_len [((c * c0)%C, switch l A bit)] ).
Proof. intros prg_len bit c l c0 A U i_lessthan_n simpl_prog_U c_unit length_l_is_n H0.
  unfold triple in *.
  unfold triple_pair in *.
  apply Heisenberg_Eigenvector_semantics_pair.
  apply Eigenvector_Heisenberg_semantics_pair in H0.
  3:{ unfold translateA. unfold translate. simpl. rewrite Mplus_0_l.
      rewrite kron_1_r. apply unit_scale; try assumption. apply WF_Unitary_Pauli. }
  2:{ unfold translateA. unfold translate. simpl. rewrite Mplus_0_l.
      rewrite kron_1_r. rewrite Mscale_1_l. apply WF_Unitary_Pauli. }
  unfold translateA in *.
  unfold translate in *.
  simpl in *.
  rewrite ! Mplus_0_l in *.
  rewrite ! kron_1_r in *.
  rewrite Mscale_1_l in *.
  subst.
  rewrite (nth_inc bit l gI); auto.
  repeat rewrite map_app.  
  rewrite <- (nth_inc bit l gI); auto. 
  rewrite switch_inc; auto.
  repeat rewrite map_app.
  repeat rewrite big_kron_app; try (intros; try rewrite <- map_app; apply WF_helper).
  repeat rewrite app_length.
  repeat rewrite map_length.
  rewrite firstn_length_le, skipn_length; try lia.
  do 4 rewrite Nat.pow_add_r.
  do 2 rewrite <- Mscale_kron_dist_r, <- Mscale_kron_dist_l.
  subst.
  rewrite prog_simpl_inc_reduce; auto.
  rewrite kron_assoc; auto with wf_db.
  replace (length l - bit - 1) with (length l - s bit) by lia.
  repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ (2 ^ (length l))); 
    try (simpl; lia).
  apply kron_simplify.
  rewrite Mmult_1_l, Mmult_1_r; try easy; try apply WF_helper2.
  all : try (apply firstn_length_le; lia).
  repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ ((2^1) * (2^(length l - s bit)))); 
    try (simpl; lia).  
  apply kron_simplify. simpl.
  rewrite ! kron_1_r.
  rewrite Mscale_mult_dist_r.
  rewrite H0.
  rewrite ! Mscale_mult_dist_l.
  rewrite Mscale_assoc. 
  easy.
  all : try (left; try rewrite Mscale_1_l; easy).
  assert (H' := (WF_big_kron _ _ (map translate_P (skipn (s bit) l)))).
  rewrite map_length, skipn_length in H'; try lia. 
  rewrite Mmult_1_l, Mmult_1_r; try easy.
  all : try apply (H' Zero); intros. 
  all : try apply WF_helper.
  all : try (simpl length; do 2 rewrite <- Nat.pow_add_r; apply pow_components; lia).
Qed.

(*** Admitted ***)
Lemma TEN1_vec : forall (prg_len bit : nat) (c : Coef) (l : list Pauli) (c0 : Coef) (A : Pauli) (U : nat -> prog),
    bit < prg_len -> simpl_prog U -> (c0 * c0 ^* )%C = C1 -> length l = prg_len ->
    triple_vec (@G 1 [ (C1, [nth bit l gI]) ] ) (U 0) (@G 1 [ (c0, [A]) ] ) ->
    triple_vec (@G prg_len [(c, l)] ) (U bit) (@G prg_len [((c * c0)%C, switch l A bit)] ).
Proof. intros prg_len bit c l c0 A U i_lessthan_n simpl_prog_U c_unit length_l_is_n H0.
  unfold triple in *.
  unfold triple_vec in *.
  intros v H1.
  unfold vecSatisfiesP in *.
  unfold vecSatisfies in *.
  unfold Eigenpair  in *.
  simpl in *.
  unfold translateA in *.
  simpl in *.
  rewrite ! Mplus_0_l in *.
  unfold translate in *.
  simpl in *.
  setoid_rewrite Mscale_1_l in H0.
  rewrite ! Mscale_1_l in *.
  rewrite ! kron_1_r in *.
  destruct H1.
  split; auto 15 with wf_db.

  rewrite prog_simpl_inc_reduce; auto.
  
  rewrite (nth_inc bit l gI) in H2; subst; auto.
  repeat rewrite map_app in H2.
  rewrite 2 big_kron_app in H2; try (intros; try rewrite <- map_app; apply WF_helper).
  repeat rewrite app_length in H2.
  repeat rewrite map_length in H2.
  rewrite firstn_length_le, skipn_length in H2; try lia.


  rewrite switch_inc; auto.
  repeat rewrite map_app.
  repeat rewrite big_kron_app; try (intros; try rewrite <- map_app; apply WF_helper).
  repeat rewrite app_length.
  repeat rewrite map_length.
  rewrite firstn_length_le, skipn_length; try lia.
  rewrite prog_simpl_inc_reduce; auto.
  rewrite ! kron_assoc; auto with wf_db.
  replace (length l - bit - 1) with (length l - s bit) by lia.
  Admitted. (*
  rewrite Mscale_mult_dist_l.
  
  setoid_rewrite kron_mixed_product. (kron_mixed_product' _ _ _ _ _ _ _ _ (2 ^ (length l))); 
  
    try (simpl; lia).
  apply kron_simplify.
  rewrite Mmult_1_l, Mmult_1_r; try easy; try apply WF_helper2.
  all : try (apply firstn_length_le; lia).
  repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ ((2^1) * (2^(length l - s bit)))); 
    try (simpl; lia).  
  apply kron_simplify. simpl.
  rewrite ! kron_1_r.
  rewrite Mscale_mult_dist_r.
  rewrite H0.
  rewrite ! Mscale_mult_dist_l.
  rewrite Mscale_assoc. 
  easy.
  all : try (left; try rewrite Mscale_1_l; easy).
  assert (H' := (WF_big_kron _ _ (map translate_P (skipn (s bit) l)))).
  rewrite map_length, skipn_length in H'; try lia. 
  rewrite Mmult_1_l, Mmult_1_r; try easy.
  all : try apply (H' Zero); intros. 
  all : try apply WF_helper.
  all : try (simpl length; do 2 rewrite <- Nat.pow_add_r; apply pow_components; lia).
Qed.
  
  
  apply Heisenberg_Eigenvector_semantics_pair.
  apply Eigenvector_Heisenberg_semantics_pair in H0.
  3:{ unfold translateA. unfold translate. simpl. rewrite Mplus_0_l.
      rewrite kron_1_r. apply unit_scale; try assumption. apply WF_Unitary_Pauli. }
  2:{ unfold translateA. unfold translate. simpl. rewrite Mplus_0_l.
      rewrite kron_1_r. rewrite Mscale_1_l. apply WF_Unitary_Pauli. }
  unfold translateA in *.
  unfold translate in *.
  simpl in *.
  rewrite ! Mplus_0_l in *.
  rewrite ! kron_1_r in *.
  rewrite Mscale_1_l in *.
  subst.
  rewrite (nth_inc bit l gI); auto.
  repeat rewrite map_app.  
  rewrite <- (nth_inc bit l gI); auto. 
  rewrite switch_inc; auto.
  repeat rewrite map_app.
  repeat rewrite big_kron_app; try (intros; try rewrite <- map_app; apply WF_helper).
  repeat rewrite app_length.
  repeat rewrite map_length.
  rewrite firstn_length_le, skipn_length; try lia.
  do 4 rewrite Nat.pow_add_r.
  do 2 rewrite <- Mscale_kron_dist_r, <- Mscale_kron_dist_l.
  subst.
  rewrite prog_simpl_inc_reduce; auto.
  rewrite kron_assoc; auto with wf_db.
  replace (length l - bit - 1) with (length l - s bit) by lia.
  repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ (2 ^ (length l))); 
    try (simpl; lia).
  apply kron_simplify.
  rewrite Mmult_1_l, Mmult_1_r; try easy; try apply WF_helper2.
  all : try (apply firstn_length_le; lia).
  repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ ((2^1) * (2^(length l - s bit)))); 
    try (simpl; lia).  
  apply kron_simplify. simpl.
  rewrite ! kron_1_r.
  rewrite Mscale_mult_dist_r.
  rewrite H0.
  rewrite ! Mscale_mult_dist_l.
  rewrite Mscale_assoc. 
  easy.
  all : try (left; try rewrite Mscale_1_l; easy).
  assert (H' := (WF_big_kron _ _ (map translate_P (skipn (s bit) l)))).
  rewrite map_length, skipn_length in H'; try lia. 
  rewrite Mmult_1_l, Mmult_1_r; try easy.
  all : try apply (H' Zero); intros. 
  all : try apply WF_helper.
  all : try (simpl length; do 2 rewrite <- Nat.pow_add_r; apply pow_components; lia).
Qed. *)


       
(*** Admitted ***)
Lemma tensor_ctrl_ground : forall (l : list Pauli) (prg_len ctrl targ : nat)
                                  (a b : Pauli) (c1 c2 : Coef),
    (c1 * c1 ^* )%C = C1 -> (c2 * c2 ^* )%C = C1 ->
    ctrl < prg_len -> targ < prg_len -> ctrl <> targ -> 
    prg_len = length l ->
    
    triple  (@G 2 ([(C1, (nth ctrl l gI) :: [nth targ l gI])])) (CNOT 0 1) (@G 2 ([(c2, a :: [b])]))  ->
    triple (@G prg_len ([(c1, l)])) (CNOT ctrl targ) 
                         (@G prg_len ([((c1*c2)%C, switch (switch l a ctrl) b targ)])).
Proof.
Admitted. (*
  induction l.
       - intros. subst. simpl in *. lia.
       - intros.
         destruct ctrl. try (apply tensor_ctrl_zero; auto).
         destruct targ. try (apply tensor_targ_zero; auto).
         apply cnot_flip; assumption.
         subst; simpl in *.
         apply tensor_ctrl_reduce; auto.
         replace  (c1 * c2 * (c1 * c2) ^* )%C with  ((c1 * c1 ^* ) * (c2 * c2 ^* ))%C by lca.
         rewrite H, H0; lca.
         lia.                                            
         do 2 rewrite switch_len; easy.
         apply IHl; auto; lia.
Qed.
*)

(*** Admitted ***)
  Lemma TEN2 : forall (prg_len ctrl targ : nat) (c : Coef) (l : list Pauli) (c0 : Coef) (A B : Pauli) (U : nat -> nat -> prog),
             (c * c ^* )%C = C1 -> (c0 * c0 ^* )%C = C1 ->
             ctrl < prg_len -> targ < prg_len -> ctrl <> targ -> 
             prg_len = length l -> ctrl_prog U ->
             triple (@G 2 [ (C1, [nth ctrl l gI; nth targ l gI]) ] ) (U 0 1) (@G 2 [ (c0, [A; B]) ] ) ->
             triple (@G prg_len [(c, l)] ) (U ctrl targ) (@G prg_len [((c*c0)%C, switch (switch l A ctrl) B targ)]).
Admitted.

  (*
Lemma TEN2 : forall {n} (i j : nat) (T : TType n) (A B : Pauli) (U : nat -> nat -> prog),
    i < n -> j < n -> ctrl_prog U -> 
    ( @triple 2 (G [ (C1, [ith_TType i T ; ith_TType j T]) ]) (U 0 1) (G [ (C1, [A ; B]) ]) ) ->
    {{ G [T] }} U i j {{ G [ith_switch_TType j (ith_switch_TType i T (C1, [A])) (C1, [B]) ] }}.
Proof. intros n i0 j0 T0 A B U ilessthann jlessthann ctrlprogU H0.
       destruct T0.
       rewrite ctrlprogU in *.
       unfold triple in *.
       unfold triple_pair in *.
       



       apply Heisenberg_Eigenvector_semantics_pair.
  apply Eigenvector_Heisenberg_semantics_pair in H0.
  3:{ unfold translateA. unfold translate. simpl. rewrite Mplus_0_l.
      rewrite kron_1_r. apply unit_scale; try assumption.
      replace (4) with (2 * 2) by lia.
      apply kron_unitary;
        apply WF_Unitary_Pauli.
      lca. }
  2:{ unfold translateA. unfold translate. simpl. rewrite Mplus_0_l.
      rewrite kron_1_r. rewrite Mscale_1_l.
      replace (4) with (2 * 2) by lia.
      apply kron_unitary;
        apply WF_Unitary_Pauli. }
  
  unfold translateA in *.
  unfold translate in *.
  simpl in *.
  rewrite ! Mplus_0_l in *.
  rewrite ! kron_1_r in *.
  rewrite Mscale_1_l in *.
  rewrite <- length_snd_T_is_n in ilessthann.
  rewrite (nth_inc i0 l gI); auto.
  repeat rewrite map_app.  
  rewrite <- (nth_inc i0 l gI); auto. 
  rewrite switch_inc; auto.
  repeat rewrite map_app.
  repeat rewrite big_kron_app; try (intros; try rewrite <- map_app; apply WF_helper).
  repeat rewrite app_length.
  repeat rewrite map_length.
  rewrite firstn_length_le, skipn_length; try lia.
  do 4 rewrite Nat.pow_add_r.
  do 2 rewrite <- Mscale_kron_dist_r, <- Mscale_kron_dist_l.
  subst.
  rewrite prog_simpl_inc_reduce; auto.
  rewrite kron_assoc; auto with wf_db.
  replace (length l - i0 - 1) with (length l - s i0) by lia.
  repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ (2 ^ (length l))); 
    try (simpl; lia).
  apply kron_simplify.
  rewrite Mmult_1_l, Mmult_1_r; try easy; try apply WF_helper2.
  all : try (apply firstn_length_le; lia).
  repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ ((2^1) * (2^(length l - s i0)))); 
    try (simpl; lia).  
  apply kron_simplify. simpl.
  rewrite ! kron_1_r.
  rewrite Mscale_mult_dist_r.
  rewrite H0.
  rewrite ! Mscale_mult_dist_l.
  rewrite Mscale_assoc.
  easy.
  all : try (left; try rewrite Mscale_1_l; easy).
  assert (H' := (WF_big_kron _ _ (map translate_P (skipn (s i0) l)))).
  rewrite map_length, skipn_length in H'; try lia. 
  rewrite Mmult_1_l, Mmult_1_r; try easy.
  all : try apply (H' Zero); intros. 
  all : try apply WF_helper.
  all : try (simpl length; do 2 rewrite <- Nat.pow_add_r; apply pow_components; lia).
Qed. *)





(*
  n : nat
  a, b, a', b' : AType n
  g : prog
  H0 : forall v : Vector (2 ^ n),
       WF_Matrix v /\ (exists c : C, translateA a × v = c .* v) ->
       WF_Matrix (translate_prog n g × v) /\
       (exists c : C,
          translateA b × (translate_prog n g × v) = c .* (translate_prog n g × v))
  H1 : forall v : Vector (2 ^ n),
       WF_Matrix v /\ (exists c : C, translateA a' × v = c .* v) ->
       WF_Matrix (translate_prog n g × v) /\
       (exists c : C,
          translateA b' × (translate_prog n g × v) = c .* (translate_prog n g × v))
  v : Vector (2 ^ n)
  H2 : WF_Matrix v
  x : C
  H3 : translateA (gMulA a a') × v = x .* v
 *)
(*** Admitted ***)
Lemma translateA_gMulA_exists : forall {n} (a a' : AType n) (x : C) (v : Vector (2^n)),
  translateA (gMulA a a') × v = x .* v -> WF_Matrix v ->
  (exists c : C, translateA a × v = c .* v) /\ (exists c : C, translateA a' × v = c .* v).
Proof. intros n a a' x v H0 H1. 
       split.
       - induction a; unfold translateA in *; simpl in *.
         + rewrite H0. exists x. reflexivity.
         + rewrite map_app in H0.
           rewrite map_map in H0.
           rewrite fold_left_Mplus_app_Zero in H0.
           rewrite fold_left_Mplus.
           rewrite Mmult_plus_distr_r.
Admitted.


Lemma translateA_gMulA_nil : forall {n} (a a' : AType n) (x : C) (v : Vector (2^n)),
    WF_AType_nil n a -> WF_AType_nil n a' ->
    translateA (gMulA a a') = translateA a × translateA a'.
Proof.
       induction a; intros.
       - simpl. unfold translateA. simpl. rewrite Mmult_0_l. reflexivity.
       - unfold translateA in *. simpl. rewrite map_app. rewrite map_map.
         rewrite fold_left_Mplus_app_Zero. rewrite fold_left_Mplus.
         rewrite Mmult_plus_distr_r. rewrite IHa; try easy.
         2: inversion H0; easy.
         rewrite Mplus_comm. f_equal.
         clear IHa. induction a'.
         + simpl. rewrite Mmult_0_r. reflexivity.
         + simpl. rewrite ! fold_left_Mplus. rewrite Mmult_plus_distr_l.
           rewrite IHa'.
           2: inversion H1; easy.
           f_equal. clear IHa'.
           destruct a, a1.
           setoid_rewrite translate_gMulT.
           2: inversion H0; inversion H1;
           inversion H4; inversion H8;
           simpl in H11, H13; subst; easy.
           unfold translate. simpl.
           rewrite <- Mscale_assoc.
           rewrite <- Mscale_mult_dist_r.
           rewrite <- Mscale_mult_dist_l.
           rewrite map_length.
           inversion H0; inversion H1.
           inversion H4; inversion H8.
           simpl in H11, H13.
           subst.
           reflexivity.
Qed.

Lemma translateA_gMulA : forall {n} (a a' : AType n) (x : C) (v : Vector (2^n)),
    WF_AType n a -> WF_AType n a' ->
    translateA (gMulA a a') = translateA a × translateA a'.
Proof.
  intros. apply WF_AType_implies_WF_AType_nil in H0, H1.
  apply translateA_gMulA_nil; try easy.
Qed.
           

Lemma MUL_Heisenberg : forall {n} (a b a' b' : AType n) (g : prog),
    {{ G a }} g {{ G b }} -> {{ G a' }} g {{ G b' }} -> {{ G a *' G a' }} g {{ G b *' G b' }}.
Proof. Admitted.

(*** Admitted ***)
Lemma MUL : forall {n} (a b a' b' : AType n) (g : prog),
    triple_vec (G a) g (G b) -> triple_vec (G a') g (G b') -> triple_vec (G a *' G a') g (G b *' G b').
Proof.
  intros n a b a' b' g H0 H1.
  unfold triple in *. unfold triple_vec in *.
  unfold vecSatisfiesP in *.
  unfold vecSatisfies in *.
  intros v H2.
  destruct H2.
  destruct H3.
  unfold Eigenpair in *.
  simpl in *.
  split; auto with wf_db.

  rewrite Mscale_1_l in *.
  setoid_rewrite Mscale_1_l in H0.
  setoid_rewrite Mscale_1_l in H1.
  rewrite translateA_gMulA; try easy.
  
  induction b.
  - simpl.
  
    unfold translateA in *.
    unfold translate in *.

    simpl.

  
  unfold gMulA in *.
  
Admitted.



Lemma translate_gScaleT_scale : forall {n} (c : Coef) (t : TType n),
    translate (gScaleT c t) = c .* translate t.
Proof.
  intros n c t.
  destruct t.
  unfold translate.
  simpl.
  symmetry.
  setoid_rewrite <- Mscale_assoc.
  reflexivity.
Qed.

Lemma fold_left_Mplus_map_scale : forall {n} (c : C) (l : list(Square n)),
    fold_left Mplus (map (fun x : Square n => c .* x) l) Zero =
      c .* fold_left Mplus l Zero.
Proof.
  intros n c l.
  induction l.
  - simpl. rewrite Mscale_0_r. reflexivity.
  - simpl. rewrite ! fold_left_Mplus. rewrite Mscale_plus_distr_r.
    rewrite IHl. reflexivity.
Qed.
  
Lemma translateA_gScaleA_scale : forall {n} (c : Coef) (a : AType n),
    translateA (gScaleA c a) = c .* translateA a.
Proof.
  intros n c a.
  unfold translateA.
  unfold gScaleA.
  rewrite map_map.
  assert ((fun x : TType n => translate (gScaleT c x)) =
            (fun x : TType n => c .* translate x ) ).
  { apply functional_extensionality.
    intros x.
    rewrite translate_gScaleT_scale.
    reflexivity. }
  rewrite H0.
  rewrite <- map_map with (g := (fun x : Square (2^n) => c .* x)).
  rewrite fold_left_Mplus_map_scale.
  reflexivity.
Qed.
  
Lemma translateA_gScaleA : forall {n} (c : Coef) (a a' : AType n) (x : C) (v : Vector (2^n)),
    c <> C0 -> translateA (gScaleA c a) × v = x .* v -> translateA a × v = (/ c * x) .* v.
Proof. intros n c a a' x v H0 H1.
       setoid_rewrite translateA_gScaleA_scale in H1.
       setoid_rewrite <- Mscale_1_l in H1 at 5.
       rewrite <- Cinv_r with (r := c) in H1.
       rewrite <- Mscale_assoc in H1.
       rewrite Mscale_mult_dist_l in H1.
       apply Mscale_inv with (c := c) in H1.
       rewrite Mscale_assoc in H1.
       all : assumption.
Qed.

Lemma translateA_gScaleA_C0 : forall {n} (a : AType n),
    translateA (gScaleA C0 a) = Zero.
Proof.
  intros n a.
  unfold translateA.
  induction a.
  - easy.
  - simpl. rewrite fold_left_Mplus. rewrite IHa.
    rewrite Mplus_0_l.
    destruct a. unfold translate. simpl.
    rewrite Cmult_0_l.
    rewrite Mscale_0_l.
    reflexivity.
Qed.


Lemma SCALE_vec' : forall {n} (c : Coef) (a a' : AType n) (g : prog),
    triple_vec' (G a) g (G a') -> triple_vec' (c ·' G a) g (c ·' G a').
Proof.
  intros n c a a' g H0.
  pose (Ceq_dec c C0).
  destruct s.
  - rewrite e.
    unfold triple_vec' in *. 
    simpl.
    rewrite ! translateA_gScaleA_C0.
    unfold vecSatisfiesP' in *.
    unfold vecSatisfies' in *.
    unfold Eigenpair in *.
    simpl in *.
    intros v [ H1 [x H2] ].
    split; auto with wf_db.
    rewrite <- Mmult_assoc.
    assert (Zero × translate_prog n g  = translate_prog n g × Zero).
    { pauli_matrix_computation;
      do 2 f_equal;
      apply functional_extensionality;
      intros;
      rewrite Cmult_0_l;
      rewrite Cmult_0_r;
        reflexivity. }
    rewrite H3.
    rewrite Mmult_assoc.
    rewrite H2.
    distribute_scale.
    exists x.
    reflexivity.
  - unfold triple_vec' in *.
    unfold vecSatisfiesP' in *.
    unfold vecSatisfies' in *.
    unfold Eigenpair in *.
    simpl in *.
    intros v [ H1 [x H2] ].
    split; auto with wf_db.
    rewrite translateA_gScaleA_scale.
    distribute_scale.
    apply translateA_gScaleA in H2; try easy.
    assert (WF_Matrix v /\ (exists c, translateA a × v = c .* v)).
    { split; try easy. exists (/c * x)%C. easy. }
    specialize (H0 v H3).
    destruct H0.
    destruct H4.
    rewrite H4.
    distribute_scale.
    exists (c * x0)%C.
    reflexivity.
Qed.

Lemma SCALE_vec_Heisenberg : forall {n} (c : Coef) (a a' : AType n) (g : prog),
    {{ G a }} g {{ G a' }} -> {{ c ·' G a }} g {{ c ·' G a' }}.
Proof.
  intros n c a a' g H0.
  unfold_triple.
  pose (Ceq_dec c C0).
  destruct s.
  - rewrite e.
    unfold triple_vec in *. 
    simpl.
    rewrite ! translateA_gScaleA_C0.
    unfold vecSatisfiesP in *.
    unfold vecSatisfies in *.
    unfold Eigenpair in *.
    simpl in *.
    intros v [ H1 H2].
    split; auto with wf_db.
    rewrite <- Mmult_assoc.
    assert (Zero × translate_prog n g  = translate_prog n g × Zero).
    { pauli_matrix_computation;
      do 2 f_equal;
      apply functional_extensionality;
      intros;
      rewrite Cmult_0_l;
      rewrite Cmult_0_r;
        reflexivity. }
    rewrite H3.
    rewrite Mmult_assoc.
    rewrite H2.
    distribute_scale.
    reflexivity.
  - unfold triple_vec in *.
    unfold vecSatisfiesP in *.
    unfold vecSatisfies in *.
    unfold Eigenpair in *.
    simpl in *.
    intros v [ H1 H2].
    split; auto with wf_db.
    rewrite translateA_gScaleA_scale.
    distribute_scale.
    apply translateA_gScaleA in H2; try easy.
    setoid_rewrite Mscale_1_l in H0.
    rewrite ! Mscale_1_l.
    rewrite Cmult_1_r in H2.
    
    assert (WF_Matrix v /\ (translateA a × v = /c .* v)).
    { split; easy. }
    
    specialize (H0 (v)).
    destruct H0.
    Admitted. (*
    destruct H4.
    rewrite H4.
    distribute_scale.
    exists (c * x0)%C.
    reflexivity.
Qed. *)


Lemma SCALE_vec : forall {n} (c : Coef) (a a' : AType n) (g : prog),
    triple_vec (G a) g (G a') -> triple_vec (c ·' G a) g (c ·' G a').
Proof.
  intros n c a a' g H0.
  pose (Ceq_dec c C0).
  destruct s.
  - rewrite e.
    unfold triple_vec in *. 
    simpl.
    rewrite ! translateA_gScaleA_C0.
    unfold vecSatisfiesP in *.
    unfold vecSatisfies in *.
    unfold Eigenpair in *.
    simpl in *.
    intros v [ H1 H2].
    split; auto with wf_db.
    rewrite <- Mmult_assoc.
    assert (Zero × translate_prog n g  = translate_prog n g × Zero).
    { pauli_matrix_computation;
      do 2 f_equal;
      apply functional_extensionality;
      intros;
      rewrite Cmult_0_l;
      rewrite Cmult_0_r;
        reflexivity. }
    rewrite H3.
    rewrite Mmult_assoc.
    rewrite H2.
    distribute_scale.
    reflexivity.
  - unfold triple_vec in *.
    unfold vecSatisfiesP in *.
    unfold vecSatisfies in *.
    unfold Eigenpair in *.
    simpl in *.
    intros v [ H1 H2].
    split; auto with wf_db.
    rewrite translateA_gScaleA_scale.
    distribute_scale.
    apply translateA_gScaleA in H2; try easy.
    setoid_rewrite Mscale_1_l in H0.
    rewrite ! Mscale_1_l.
    rewrite Cmult_1_r in H2.
    
    assert (WF_Matrix v /\ (translateA a × v = /c .* v)).
    { split; easy. }
    
    specialize (H0 (v)).
    destruct H0.
    Admitted. (*
    destruct H4.
    rewrite H4.
    distribute_scale.
    exists (c * x0)%C.
    reflexivity.
Qed. *)


Lemma SCALE_pair : forall {n} (c : Coef) (a a' : AType n) (g : prog),
    triple_pair (G a) g (G a') -> triple_pair (c ·' G a) g (c ·' G a').
Proof.
  intros n c a a' g H0.
  pose (Ceq_dec c C0).
  destruct s.
  - rewrite e.
    unfold triple_pair in *. 
    simpl.
    rewrite ! translateA_gScaleA_C0.
    unfold pairSatisfiesP in *.
    unfold pairSatisfies in *.
    unfold Eigenpair in *.
    simpl in *.
    intros p [ H1 H2].
    destruct p.
    simpl in *.
    split; auto with wf_db.
    rewrite <- Mmult_assoc.
    assert (Zero × translate_prog n g  = translate_prog n g × Zero).
    { pauli_matrix_computation;
      do 2 f_equal;
      apply functional_extensionality;
      intros;
      rewrite Cmult_0_l;
      rewrite Cmult_0_r;
        reflexivity. }
    rewrite H3.
    rewrite Mmult_assoc.
    rewrite H2.
    distribute_scale.
    reflexivity.
  - unfold triple_pair in *.
    unfold pairSatisfiesP in *.
    unfold pairSatisfies in *.
    unfold Eigenpair in *.
    simpl in *.
    intros p [ H1 H2].
    destruct p.
    simpl in *.
    split; auto with wf_db.
    rewrite translateA_gScaleA_scale.
    distribute_scale.
    apply translateA_gScaleA in H2; try easy.
    assert (WF_Matrix m /\ (translateA a × m = (/c * c0)%C .* m)).
    { split; easy. }
    specialize (H0 (m, /c * c0)%C H3).
    simpl in *.
    destruct H0.
    rewrite H4.
    distribute_scale.
    rewrite Cmult_assoc.
    rewrite Cinv_r; try easy.
    rewrite Cmult_1_l.
    reflexivity.
Qed.


Lemma SEQ : forall {n} (A B C : Predicate n) (g1 g2 : prog),
    {{ A }} g1 {{ B }} -> {{ B }} g2 {{ C }} ->  {{ A }} g1 ;; g2 {{ C }}.
Proof.
  intros n A B C g1 g2 H0 H1.
  unfold triple in *. unfold triple_vec in *.
  simpl.
  intros v H2.
  specialize (H0 v H2).
  specialize (H1 (translate_prog n g1 × v) H0).
  rewrite Mmult_assoc.
  assumption.
Qed.


Lemma CONS : forall {n} (A' A B B' : Predicate n) (g : prog),
    A' ⇒ A -> {{ A }} g {{ B }} -> B ⇒ B' -> {{ A' }} g {{ B' }}.
Proof.
  intros n A' A B B' g H0 H1 H2.
  unfold triple in *. unfold triple_vec in *.
  intros v H3.
  apply interpret_implies with (v := v) in H0; try easy.
  apply interpret_implies with (v := translate_prog n g × v) in H2; try easy.
  specialize (H1 v H0); try easy.
Qed.
  
  
  
Lemma CAP : forall {n} (A A' B B' : Predicate n) (g : prog),
    {{ A }} g {{ A' }} -> {{ B }} g {{ B' }} -> {{ A ∩ B }} g {{ A' ∩ B' }}.
Proof.
  intros n A A' B B' g H0 H1.
  unfold triple in *.
  intros v H2.
  simpl in *.
  destruct H2.
  split.
  - specialize (H0 v H2). easy.
  - specialize (H1 v H3). easy.
Qed.
  
Lemma CUP : forall {n} (A A' B B' : Predicate n) (g : prog),
    {{ A }} g {{ A' }} -> {{ B }} g {{ B' }} -> {{ A ⊍ B }} g {{ A' ⊍ B' }}.
Proof.
  intros n A A' B B' g H0 H1.
  unfold triple in *.
  intros v H2.
  simpl in *.
  destruct H2.
  - left. specialize (H0 v H2). easy.
  - right. specialize (H1 v H2). easy.
Qed.
(*** Admitted ***)
Lemma ADD : forall {n} (a b c d : AType n) (g : prog),
    {{ G a }} g {{ G c }} -> {{ G b }} g {{ G d }} -> {{ G a +' G b }} g {{ G c +' G d }}.
Proof.
  intros n a b c d g H0 H1.
  unfold triple in *.
Admitted.
(*** Admitted ***)
Lemma TENADD : forall {n} (i : nat) (T : TType n) (A : Pauli) (B C : TType 1) (U : nat -> prog),
    i < n -> simpl_prog U -> ith_TType i T = A ->
    ( @triple 1 (G [ (C1, [A]) ]) (U 0) (G [ B ; C ]) ) ->
    {{ G [T] }} U i {{ G [ith_switch_TType i T B] }}.
Proof.
  intros n i0 T0 A B C U H0 H1 H2 H3.
  destruct T0 as [ct lt].
  destruct B as [cb lb].
  destruct C as [cc lc].
  simpl.
  subst.
Admitted.


(** *** break these up into different things *** **) (*
Inductive conclude : Prop -> Prop :=
| XHZ : conclude ( {{ pX }} H 0 {{ pZ }} )
| ZHX : conclude ( {{ pZ }} H 0 {{ pX }} )
| XSY : conclude ( {{ pX }} S 0 {{ pY }} )
| ZSZ : conclude ( {{ pZ }} S 0 {{ pZ }} )
| ZTZ : conclude ( {{ pZ }} T 0 {{ pZ }} )
| XTXY : conclude ( {{ pX }} T 0 {{ (C1/√2)%C ·' (pX +' pY) }} )
| XICNOTXX : conclude ( {{ pX ⊗' pI }} CNOT 0 1 {{ pX ⊗' pX }} )
| IXCNOTIX : conclude ( {{ pI ⊗' pX }} CNOT 0 1 {{ pI ⊗' pX }} )
| ZICNOTZI : conclude ( {{ pZ ⊗' pI }} CNOT 0 1 {{ pZ ⊗' pI }} )
| IZCNOTZZ : conclude ( {{ pI ⊗' pZ }} CNOT 0 1 {{ pZ ⊗' pZ }} )
| TEN1 : forall {n} (i : nat) (T : TType n) (A B : Pauli) (U : nat -> prog),
    i < n -> simpl_prog U -> ith_TType i T = A ->
    ( @triple 1 (G [ (C1, [A]) ]) (U 0) (G [ (C1, [B]) ]) ) ->
    conclude ( {{ G [T] }} U i {{ G [ith_switch_TType i T (C1, [B])] }} )
| TEN2 : forall {n} (i j : nat) (T : TType n) (A B C D : Pauli) (U : nat -> nat -> prog),
    i < n -> j < n -> ctrl_prog U -> ith_TType i T = A -> ith_TType j T = B ->
    ( @triple 1 (G [ (C1, [A ; B]) ]) (U 0 1) (G [ (C1, [C ; D]) ]) ) ->
    conclude ( {{ G [T] }} U i j {{ G [ith_switch_TType j (ith_switch_TType i T (C1, [C])) (C1, [D]) ] }} )
| MUL : forall {n} (A B A' B' : Predicate n) (g : prog),
    {{ A }} g {{ B }} -> {{ A' }} g {{ B' }} -> conclude ( {{ A *' A' }} g {{ B *' B' }} )
| SCALE : forall {n} (c : Coef) (A A' : Predicate n) (g : prog),
    {{ A }} g {{ A' }} -> conclude ( {{ c ·' A }} g {{ c ·' A' }} )
| SEQ : forall {n} (A B C : Predicate n) (g1 g2 : prog),
    {{ A }} g1 {{ B }} -> {{ B }} g2 {{ C }} -> conclude ( {{ A }} g1 ;; g2 {{ C }} )
| CONS : forall {n} (A' A B B' : Predicate n) (g : prog),
    A' ⇒ A -> {{ A }} g {{ B }} -> B ⇒ B' -> conclude ( {{ A' }} g {{ B' }} )
| CAP : forall {n} (A A' B B' : Predicate n) (g : prog),
    {{ A }} g {{ A' }} -> {{ B }} g {{ B' }} -> conclude ( {{ A ∩ B }} g {{ A' ∩ B' }} )
| CUP : forall {n} (A A' B B' : Predicate n) (g : prog),
    {{ A }} g {{ A' }} -> {{ B }} g {{ B' }} -> conclude ( {{ A ⊍ B }} g {{ A' ⊍ B' }} )
| ADD : forall {n} (A B C D : Predicate n) (g : prog),
    {{ A }} g {{ C }} -> {{ B }} g {{ D }} -> conclude ( {{ A +' B }} g {{ C +' D }} )
| TENADD : forall {n} (i : nat) (T : TType n) (A : Pauli) (B C : TType 1) (U : nat -> prog),
    i < n -> simpl_prog U -> ith_TType i T = A ->
    ( @triple 1 (G [ (C1, [A]) ]) (U 0) (G [ B ; C ]) ) ->
    conclude ( {{ G [T] }} U i {{ G [ith_switch_TType i T B] }} ). *)











Inductive progHasSingType {prg_len : nat} : prog -> Predicate prg_len -> Predicate prg_len -> Prop :=
| PHST : forall p T1 T2, Cap_vt T1 -> Cap_vt T2 -> 
  (translate_prog prg_len p) ::' [(translateP T1, translateP T2)] -> 
  progHasSingType p T1 T2.
(* should use two cons for PHT, one for arrow one for cap *)

Inductive progHasType {prg_len : nat} : prog -> Predicate prg_len -> Prop :=
| Arrow_pht : forall p T1 T2, progHasSingType p T1 T2 -> progHasType p (Arrow T1 T2)
| Cap_pht : forall p T1 T2, progHasType p T1 -> progHasType p T2 -> progHasType p (Cap T1 T2).

Notation "p :' T" := (progHasType p T).



Lemma arrow_equiv : forall {n} (A A' B B' : Predicate n) (C : prog), A ≡ B -> A' ≡ B' -> C :' A → A' -> C :' B → B'.
Proof. intros n A A' B B' C H H' G. 
       inversion H; inversion H'; subst; try discriminate; try easy; inversion G; subst. 
       - inversion H4; subst. inversion H5; subst.
         repeat constructor. simpl in *. rewrite <- H0, <- H3. assumption.
       - inversion H3; subst. inversion H2; subst. inversion H4; subst.
         repeat constructor; try easy. simpl in *. rewrite <- H0. assumption.
       - inversion H3; subst. repeat constructor; try easy.
       - inversion H3; subst. inversion H2.
       - inversion H2; subst. inversion H0; subst. repeat constructor; try easy.
         simpl in *. inversion H3; subst. rewrite <- H4. assumption.
       - inversion H2; subst. repeat constructor; try easy.
       - inversion H3; subst. inversion H0.
Qed.

Lemma arrow_add_comm_l : forall {n} (A A' B : Predicate n) (c : Coef) (C : prog), C :' c .· (A .+ A') → B ->  C :' c .· (A' .+ A) → B.
Proof. intros n A A' B c C H.
       apply arrow_equiv with (A:=c .·(A .+ A')) (A':=B).
       apply add_comm. apply reflexivity.
       assumption.
Qed.

Lemma arrow_add_comm_r : forall {n} (A B B' : Predicate n) (c : Coef) (C : prog), C :' A → c .· (B .+ B') ->  C :' A → c .· (B' .+ B).
Proof. intros n A B B' c C H.
       apply arrow_equiv with (A:=A) (A':=c .· (B .+ B')).
       apply reflexivity. apply add_comm.
       assumption.
Qed.

Hint Resolve arrow_equiv arrow_add_comm_l arrow_add_comm_r : typing_db.



Definition types_equiv {n} (A B : Predicate n) := forall C,  C :' A <-> C :' B.

Lemma eq_types_equiv_refl : forall {n} (A : Predicate n), types_equiv A A.
Proof. intros n A. 
       easy.
Qed.

Lemma eq_types_equiv_sym : forall {n} (A B : Predicate n), types_equiv A B -> types_equiv B A.
Proof. intros n A B H. 
       easy. 
Qed.

Lemma eq_types_equiv_trans : forall {n} (A B C : Predicate n),
    types_equiv A B -> types_equiv B C -> types_equiv A C.
Proof.
  intros n A B C HAB HBC.
  unfold types_equiv in *.
  intros C0.
  split; intros.
  - rewrite HAB in H. rewrite HBC in H. easy.
  - rewrite HAB. rewrite HBC. easy.
Qed.

Add Parametric Relation n : (Predicate n) (@types_equiv n)
    reflexivity proved by eq_types_equiv_refl
    symmetry proved by eq_types_equiv_sym
    transitivity proved by eq_types_equiv_trans
    as eq_types_equiv_rel.

Add Parametric Morphism (n : nat) : Arrow
  with signature @eq_Predicate n ==> @eq_Predicate n ==> @types_equiv n as Predicate_Arr_mor.      Proof.
  intros.
  split; apply arrow_equiv; easy.
Qed.

(** rewrite H should work. **)
Lemma test : forall n (A A' A'' B : Predicate n) C, A ≡ A' -> A' ≡ A'' -> C :' A'' → B -> C :' A → B.
Proof. intros n A A' A'' B C H H0 H1. 
       eapply arrow_equiv.
       3:{ apply H1.}
         rewrite H, H0; easy.
       easy.
Qed.


(********************)
(* Base type lemmas *)
(********************)


Lemma Hsimp : prog_smpl_app 1 hadamard 0 = hadamard.
Proof. unfold prog_smpl_app. 
       rewrite kron_1_r.
       rewrite kron_1_l.
       reflexivity. 
       auto with wf_db.
Qed.

Lemma Ssimp : prog_smpl_app 1 Phase 0 = Phase.
Proof. unfold prog_smpl_app. 
       rewrite kron_1_r.
       rewrite kron_1_l.
       reflexivity. 
       auto with wf_db.
Qed.


Lemma Isimp : @translate 1 (C1, [gI]) = Matrix.I 2. 
Proof. unfold translate; simpl. 
       lma'. 
Qed.

Lemma Xsimp : @translate 1 (C1, [gX]) = σx. 
Proof. unfold translate; simpl. 
       lma'. 
Qed.

Lemma Zsimp : @translate 1 (C1, [gZ]) = σz. 
Proof. unfold translate; simpl. 
       lma'. 
Qed.

Lemma Ysimp : @translate 1 (C1, [gY]) = σy. 
Proof. unfold translate; simpl. 
       lma'. 
Qed.


Lemma kron_simp : forall (g1 g2 : Pauli), 
    @translate 2 (C1 * C1, g1 :: [g2]) = (translate_P g1) ⊗ (translate_P g2).  
Proof. intros. 
Qed.


Hint Rewrite Ssimp Hsimp Isimp Xsimp Zsimp Ysimp adj_ctrlX_is_cnot1 kron_simp : simp_db.


Ltac solve_ground_type :=  repeat (apply Cap_pht); try apply Arrow_pht;
                          try apply PHST; try apply G_cvt; simpl; 
                          autorewrite with simp_db;
                          repeat split;
                          try apply sgt_implies_sgt'; try easy; 
                          try apply singleton_simplify2;
                          unfold translateA; simpl;
                          unfold translate; simpl;
                          unfold prog_smpl_app;
                          unfold prog_ctrl_app;
                          bdestruct_all; simpl;
                          apply mat_equiv_eq;
                          unfold Heisenberg.seq;
                          repeat (auto 15 with wf_db;
                                  match goal with
                                  | |- WF_Matrix (Matrix.Mmult ?A ?B) => apply Matrix.WF_mult
                                  | |- WF_Matrix (Matrix.Mplus ?A ?B) => apply Matrix.WF_plus
                                  | |- WF_Matrix (Matrix.scale ?p ?B) => apply Matrix.WF_scale
                                  | |- WF_Matrix (Matrix.kron ?A ?B) => apply Matrix.WF_kron
                                  | |- WF_Matrix (Matrix.transpose ?A) => apply Matrix.WF_transpose
                                  | |- WF_Matrix (Matrix.adjoint ?A) => apply Matrix.WF_adjoint
                                  | |- WF_Matrix (Matrix.I _) => apply Matrix.WF_I
                                  end);
                           match goal with
                           | |- (?A ≡ ?B)%M => by_cell
                           end;
                           autounfold with U_db; simpl;
                           C_field_simplify; try nonzero;
                           autorewrite with Cexp_db C_db;
                           eapply c_proj_eq; simpl;
                           repeat (autorewrite with R_db; field_simplify_eq; simpl);
                           try easy.






Lemma HTypes : H' 0 :' (X → Z) ∩ (Z → X).
Proof. solve_ground_type. Qed.


Lemma HTypes_not : ~ (H' 0 :' (X → X)).
Proof. unfold not. 
       intros. 
       inversion H; inversion H2; subst. 
       simpl in H6.
       destruct H6 as [H6 _].
       apply sgt'_implies_sgt in H6.
       unfold singGateType in H6.
       assert (H' : hadamard × σx = σx × hadamard). 
       { autorewrite with simp_db in H6. 
         apply H6; left; unfold translateA; simpl; unfold translate; lma'; simpl; auto with wf_db. }
       assert (H'' : forall (m1 m2 : Square 2), m1 = m2 -> m1 1%nat 0%nat = m2 1%nat 0%nat). 
       { intros. rewrite H0. reflexivity. }
       apply H'' in H'. 
       unfold Mmult in H'. simpl in H'.
       replace (C0 + C1 * (C1 / √ 2) + C0 * (C1 / √ 2)) with (C1 / √ 2) in H' by lca. 
       replace (C0 + C1 / √ 2 * C0 + Copp (C1 / √ 2) * C1) with (Copp (C1 / √ 2)) in H' by lca. 
       unfold Cdiv in H'.
       rewrite Copp_mult_distr_l in H'.
       assert (H0 : forall c1 c2 , (c1 = c2 -> c1 * √ 2 = c2 * √ 2)%C). 
       { intros. rewrite H0. easy. }
       apply H0 in H'.
       do 2 (rewrite <- Cmult_assoc in H').
       rewrite (Cinv_l (√ 2)) in H'.
       do 2 (rewrite Cmult_1_r in H').
       assert (H1: forall {X} (p1 p2 : X * X), p1 = p2 -> fst p1 = fst p2). 
       { intros. rewrite H1. easy. }
       apply H1 in H'. simpl in H'.
       lra. 
       apply C0_fst_neq. simpl. 
       apply sqrt_neq_0_compat. 
       lra. 
       autorewrite with simp_db; auto with unit_db.
       auto with sing_db.
       simpl.
       unfold translateA; simpl.
       unfold translate; simpl.
       rewrite Mscale_1_l, kron_1_r, Mplus_0_l.
       replace [σx] with X' by easy. 
       auto with univ_db.
Qed.


Lemma CNOTTypes : CNOT' 0 1 :' (X .⊗ I → X .⊗ X) ∩ (I .⊗ X → I .⊗ X) ∩
                             (Z .⊗ I → Z .⊗ I) ∩ (I .⊗ Z → Z .⊗ Z).
Proof. solve_ground_type. Qed.



Notation CZ m n := (H' n ;; CNOT' m n ;; H' n).


Lemma TTypes : T' 0 :' (Z → Z) ∩ (X → ((1/√2) .· (X.+Y))) ∩ (Y → ((1/√2) .· (Y.+ -X))) .
Proof. solve_ground_type. Qed.
Lemma STypes : S' 0 :' (Z → Z) ∩ (X → Y) ∩ (Y → -X) .
Proof. solve_ground_type. Qed.
Lemma ZTypes : Z'' 0 :' (Z → Z) ∩ (X → -X) ∩ (Y → -Y) .
Proof. solve_ground_type. Qed.


(*************************)
(* Proving typing lemmas *)
(*************************)

Lemma SeqTypes : forall {n} (g1 g2 : prog) (A B C : Predicate n),
  g1 :' A → B ->
  g2 :' B → C ->
  (g1 ;; g2) :' A → C.
Proof. intros.
       inversion H; inversion H0.
       apply Arrow_pht.
       inversion H3; inversion H7.
       apply PHST; try easy.
       simpl translate_prog. 
       rewrite (@fgt_conv (2^n) _ _ _). 
       apply (Heisenberg.SeqTypes (translate_prog n g1) _  _ (translateP B) _);
       rewrite <- (@fgt_conv (2^n) _ _ _); try easy. 
Qed.


Lemma seq_assoc : forall {n} (g1 g2 g3 : prog) (T : Predicate n),
    g1 ;; (g2 ;; g3) :' T <-> (g1 ;; g2) ;; g3 :' T.
Proof. induction T as [| | |]; try easy. 
       - simpl. split. 
         all : intros; 
         inversion H;
         apply Cap_pht; try apply IHT1; try apply IHT2; easy.
       - split; intros; 
         inversion H; inversion H2; 
         apply Arrow_pht; apply PHST; 
         simpl translate_prog;
         try apply Heisenberg.seq_assoc;
         easy.  
Qed.


(* Note that this doesn't restrict # of qubits referenced by p. *)
Lemma TypesI : forall (p : prog), p :' I → I.
Proof. intros. 
       apply Arrow_pht; apply PHST; auto with wfpt_db. 
       rewrite Itrans.
       rewrite fgt_conv.
       apply Heisenberg.TypesI1.
       apply (unit_prog 1 p).
Qed.

  

Lemma TypesI2 : forall (p : prog), p :' I .⊗ I → I .⊗ I.
Proof. intros.  
       apply Arrow_pht; apply PHST; auto with wfpt_db.
       assert (H' : translateP (I .⊗ I) = I' ⊗' I').
       { simpl; unfold translateA; simpl. unfold translate; simpl. f_equal. lma'. }
       rewrite H'.
       apply Heisenberg.TypesI2.
       apply (unit_prog 2 p).
Qed.


Hint Resolve TypesI TypesI2 : base_types_db.


(** Structural rules *)

(* Subtyping rules *)
Lemma cap_elim_l : forall {n} (g : prog) (A B : Predicate n), g :' A ∩ B -> g :' A.
Proof. intros. inversion H; easy. Qed.

Lemma cap_elim_r : forall {n} (g : prog) (A B : Predicate n), g :' A ∩ B -> g :' B.
Proof. intros. inversion H; easy. Qed.

Lemma cap_intro : forall {n} (g : prog) (A B : Predicate n), g :' A -> g :' B -> g :' A ∩ B.
Proof. intros. apply Cap_pht; easy.
Qed.

Lemma cap_arrow : forall {n} (g : prog) (A B C : Predicate n),
  g :' (A → B) ∩ (A → C) ->
  g :' A → (B ∩ C).
Proof. intros. 
       inversion H; inversion H3; inversion H4.
       inversion H7; inversion H11.
       apply Arrow_pht. 
       apply PHST; try apply Cap_cvt; auto.
       rewrite fgt_conv in *.
       assert (H' : translateP (Cap B C) = 
                    (translateP B) ++ (translateP C)). 
       { simpl. 
         apply Cap_vt_conv in H14.
         apply Cap_vt_conv in H20.
         rewrite H14, H20; easy. }
       rewrite H'.
       apply Heisenberg.cap_arrow.
       simpl in *. split; auto.
       apply H15.
Qed.



Lemma arrow_sub : forall {n} g (A A' B B' : Predicate n),
  Cap_vt A' -> Cap_vt B' ->
  (forall l, l ;' A' -> l ;' A) ->
  (forall r, r ;' B -> r ;' B') ->
  g :' A → B ->
  g :' A' → B'.
Proof. intros. 
       apply Arrow_pht; apply PHST; auto. 
       inversion H3; inversion H6.
       apply (Heisenberg.arrow_sub _ (translateP A) _ (translateP B) _); try easy.
       all : intros; apply VHT in H14; auto. 
       apply H1 in H14; inversion H14; easy.
       apply H2 in H14; inversion H14; easy.
Qed.


Hint Resolve cap_elim_l cap_elim_r cap_intro cap_arrow arrow_sub : subtype_db.

Lemma cap_elim : forall {n} g (A B : Predicate n), g :' A ∩ B -> g :' A /\ g :' B.
Proof. eauto with subtype_db. Qed.


Lemma input_cap_l : forall {n} g (A A' B : Predicate n), 
  Cap_vt A' ->  g :' A → B -> g :' (A ∩ A') → B. 
Proof. intros. 
       inversion H0; inversion H3.
       apply (arrow_sub g A (A ∩ A') B B); auto. 
       apply Cap_cvt; auto.
       intros. 
       eauto with subtype_db.
Qed.

Lemma input_cap_r : forall {n} g (A A' B : Predicate n), 
  Cap_vt A' ->  g :' A → B -> g :' (A' ∩ A) → B. 
Proof. intros. 
       inversion H0; inversion H3.
       apply (arrow_sub g A (A' ∩ A) B B); auto. 
       apply Cap_cvt; auto.
       intros. 
       eauto with subtype_db.
Qed.

(* Full explicit proof (due to changes to arrow_sub) *)
Lemma cap_arrow_distributes : forall {n} g (A A' B B' : Predicate n),
  g :' (A → A') ∩ (B → B') ->
  g :' (A ∩ B) → (A' ∩ B').
Proof. intros.       
       inversion H.
       apply cap_arrow; apply Cap_pht. 
       - inversion H4; inversion H7.
         apply input_cap_l; easy. 
       - inversion H3; inversion H7.
         apply input_cap_r; easy. 
Qed.


Hint Resolve HTypes ZTypes STypes TTypes CNOTTypes : base_types_db.
Hint Resolve cap_intro cap_elim_l cap_elim_r : base_types_db.
Hint Resolve SeqTypes : base_types_db.

Hint Resolve HTypes ZTypes STypes TTypes CNOTTypes : typing_db.
Hint Resolve cap_intro cap_elim_l cap_elim_r : typing_db.
Hint Resolve SeqTypes : typing_db.



(***************)
(* Arrow rules *)
(***************)


Lemma arrow_add : forall {n} g (A A' B B' : Predicate n),
    uni_vecType (translateP A) ->
    uni_vecType (translateP A') ->
    uni_vecType (translateP B) ->
    uni_vecType (translateP B') ->
    proper_length_APredicate A -> proper_length_APredicate A' ->
    proper_length_APredicate B -> proper_length_APredicate B' ->
    g :' A → A' ->
    g :' B → B' ->
    g :' A .+ B → A' .+ B'.
Proof. intros n g A A' B B' G G0 G1 G2 H H0 H1 H2 H3 H4;  simpl in *.       
       inversion H3; inversion H4; inversion H7; inversion H11; 
       inversion H; inversion H0; inversion H1; inversion H2; subst. 
       apply Arrow_pht; apply PHST; auto with wfpt_db.
       destruct A; destruct B; try easy. constructor.
       destruct A'; destruct B'; try easy. constructor.
       destruct A; destruct B; try easy.
       do 2 (rewrite translateP_Add; try easy).
       rewrite fgt_conv.
       apply Heisenberg.arrow_add; 
       try (apply unit_prog);
         try (apply unit_Predicate); try easy.
Qed.

Lemma arrow_mul : forall {n} g (A A' B B' : Predicate n),
    uni_vecType (translateP A) ->
    uni_vecType (translateP A') ->
    uni_vecType (translateP B) ->
    uni_vecType (translateP B') ->
    proper_length_APredicate A -> proper_length_APredicate A' ->
    proper_length_APredicate B -> proper_length_APredicate B' ->
    g :' A → A' ->
    g :' B → B' ->
    g :' A .* B → A' .* B'.
Proof. intros n g A A' B B' G G0 G1 G2 H H0 H1 H2 H3 H4;  simpl in *.       
       inversion H3; inversion H4; inversion H7; inversion H11; 
       inversion H; inversion H0; inversion H1; inversion H2; subst. 
       apply Arrow_pht; apply PHST; auto with wfpt_db.
       destruct A; destruct A'; destruct B; destruct B'; try easy. 
       do 2 (rewrite translateP_mMult; try easy).
       rewrite fgt_conv.
       apply Heisenberg.arrow_mul; 
       try (apply unit_prog);
       try (apply unit_Predicate); try easy.
Qed. 
  

Lemma mul_simp : forall (a b : Pauli),
  @G 1 ([(gMul_Coef a b, [gMul_base a b])]) = @G 1 ([(C1, [a])]) .* @G 1 ([(C1, [b])]). 
Proof. intros. 
       simpl. unfold cBigMul, gMul_Coef, zipWith, gMul_base, uncurry; simpl. 
       destruct a; destruct b; simpl; do 3 f_equal; try lca. 
Qed.


Lemma arrow_mul_1 : forall g (a a' b b' : Pauli),
    g :' @G 1 ([(C1, [a])]) → @G 1 ([(C1, [a'])]) ->
    g :' @G 1 ([(C1, [b])]) → @G 1 ([(C1, [b'])]) ->
    g :' @G 1 ([(gMul_Coef a b, [gMul_base a b])]) → @G 1 ([(gMul_Coef a' b', [gMul_base a' b'])]).
Proof. intros. 
       do 2 rewrite mul_simp. 
       apply arrow_mul; try easy; try apply pl_ap; try apply G_apt; try apply WF_G; try apply WF_AP_Sing; unfold WF_TType; simpl; try lia;
         unfold translateP, translateA, translate, translate_P, uni_vecType; simpl; intros; try destruct H1; try contradiction; rewrite Mplus_0_l, Mscale_1_l, kron_1_r in H1; rewrite <- H1; [induction a | induction a' | induction b | induction b']; unfold WF_Unitary; split; auto with wf_db; lma'.
Qed.



Lemma arrow_scale : forall {n} (p : prog) (A A' : Predicate n) (c : Coef),
  c <> C0 -> p :' A → A' -> p :' (scale c A) → (scale c A').
Proof.  intros n p A A' c G H. 
       inversion H; inversion H2; subst.
       apply Cap_vt_conv in H4; apply Cap_vt_conv in H5.
       apply Arrow_pht; apply PHST; auto with wfpt_db. 
       all : try (apply Cap_vt_conv; rewrite Cap_vt_scale; easy).
       rewrite fgt_conv in *.
       do 2 (rewrite translateP_scale).
       apply Heisenberg.arrow_scale; try easy.
Qed.


Lemma arrow_scale_eq : forall n (p : prog) (A A' : Predicate n) (c : Coef),
  c <> C0 -> p :' A → A' <-> p :' (scale c A) → (scale c A').
Proof. intros n p A A' c G. split.
  - apply arrow_scale; assumption.
  - intros H. eapply arrow_scale with (c:= /c) in H;
      try (apply nonzero_div_nonzero; assumption).
    assert ( / c .· c .· A = A).
    { clear H.
      induction A; simpl; try rewrite IHA1, IHA2; try easy.
      f_equal. unfold gScaleA. rewrite map_map.
      unfold gScaleT. induction a; simpl; try easy.
      f_equal; try apply IHa.
      destruct a. f_equal. rewrite Cmult_assoc.
      unfold Cdiv.
      rewrite Cinv_l; try assumption; try lca. }
    assert ( / c .· c .· A' = A').
    { clear H. 
      induction A'; simpl; try rewrite IHA'1, IHA'2; try easy.
      f_equal. unfold gScaleA. rewrite map_map.
      unfold gScaleT. induction a; simpl; try easy.
      f_equal; try apply IHa.
      destruct a. f_equal. rewrite Cmult_assoc.
      unfold Cdiv.
      rewrite Cinv_l; try assumption; try lca. }
    rewrite H0 in H. rewrite H1 in H. assumption.
Qed.

Lemma arrow_scale_eq' : forall n (p : prog) (A A' : Predicate n) (c : Coef),
  c <> C0 -> p :' (scale c A) → A' <-> p :' A → (scale (/c) A').
Proof. intros n p A A' c G.
       rewrite arrow_scale_eq with (c:=/c); try apply nonzero_div_nonzero; try assumption.
       assert ( /c .· c .· A = A).
       { induction A; simpl; try rewrite IHA1, IHA2; try easy.
         f_equal. unfold gScaleA. rewrite map_map.
         unfold gScaleT. induction a; simpl; try easy.
         f_equal; try apply IHa.
         destruct a. f_equal. rewrite Cmult_assoc.
         rewrite Cinv_l; try assumption; try lca. }
       rewrite H; easy.
Qed.


Lemma arrow_i : forall {n} (p : prog) (A A' : Predicate n),
  p :' A → -i A' ->
  p :' i A → A'.
Proof. intros.
         eapply arrow_scale_eq with (c:=Copp Ci).
         try apply C0_snd_neq; simpl; try lra.
         assert ((- Ci)%C .· i A = A).
         { clear H. 
           induction A; unfold i in *; simpl in *; try rewrite IHA1, IHA2; try easy.
           f_equal. unfold gScaleA. rewrite map_map.
           unfold gScaleT. induction a; simpl; try easy.
           f_equal; try apply IHa.
           destruct a. f_equal. lca. }
         assert ((- Ci)%C .· A' = - i A').
         { clear H. 
           induction A'; unfold i in *; simpl in *; try rewrite IHA'1, IHA'2; try easy.
           f_equal. unfold gScaleA. rewrite map_map.
           unfold gScaleT. induction a; simpl; try easy.
           f_equal; try apply IHa.
           destruct a. f_equal. lca. }
         rewrite H0, H1; assumption.       
Qed.


Lemma arrow_neg : forall n (p : prog) (A A' : Predicate n),
  p :' A → - A' ->
  p :' -A → A'.
Proof. intros.
  eapply arrow_scale_eq with (c:=Copp C1);
    try apply C0_fst_neq; simpl; try lra.
  rewrite neg_inv; assumption.       
Qed.



Lemma arrow_neg_eq : forall n (p : prog) (A A' : Predicate n),
    p :' -A → A' <-> p :' A → -A'.
Proof. intros n p A A'. split; intros;
         rewrite arrow_scale_eq with (c := Copp C1);
         try rewrite neg_inv;
         try assumption;
         try apply C0_fst_neq; simpl; lra.
Qed.


Lemma arrow_neg_eq' : forall n (p : prog) (A A' : Predicate n),
    p :' A → A' <-> p :' -A → -A'.
Proof. intros n p A A'. split; intros;
    [apply arrow_scale | apply arrow_scale with (c := Copp C1) in H];
    try rewrite 2 neg_inv in H;
    try assumption;
    try apply C0_fst_neq; simpl; lra.
Qed.



(* basically just eq_type_conv_output but with different order hypotheses *)
Lemma eq_arrow_r : forall {n} (g : prog) (A B B' : Predicate n),
    g :' A → B ->
       B = B' ->
       g :' A → B'.
Proof. intros. subst; easy. Qed.

(*
Hint Resolve arrow_mul arrow_mul_1 arrow_scale arrow_scale_eq arrow_scale_eq' arrow_i arrow_neg arrow_neg_eq arrow_neg_eq' eq_arrow_r : typing_db.
 *)
Hint Resolve arrow_mul arrow_mul_1 arrow_scale arrow_scale_eq arrow_scale_eq' arrow_i arrow_neg arrow_neg_eq arrow_neg_eq' eq_arrow_r : typing_db.
Hint Rewrite mul_simp arrow_scale_eq' arrow_neg_eq : typing_db.






Notation Tdagger' n := (Z'' n ;; S' n ;; T' n).


(* Tdagger should be solvable by eauto *)
Lemma TdaggerTypes : Tdagger' 0 :' (Z → Z) ∩ (X → ((1/√2) .· (X.+ -Y))).
Proof. constructor;
         repeat eapply SeqTypes;
         eauto with typing_db;
         autorewrite with typing_db;
         eauto with typing_db.
Qed.

Hint Rewrite neg_inv neg_dist_add i_sqr i_neg_comm : typing_db.




Notation Toffoli' a b c := (H' c ;; CNOT' b c ;; Tdagger' c ;; CNOT' a c ;; T' c ;; CNOT' b c ;; Tdagger' c ;; CNOT' a c ;; T' b ;; T' c ;; H' c ;; CNOT' a b ;; T' a ;; Tdagger' b ;; CNOT' a b).



(*** toffoli ***)
(*
Lemma ToffoliTypes : Toffoli' 0 1 2 :' (Z .⊗ I .⊗ I → Z .⊗ I .⊗ I).
Proof. 
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
  solve_ground_type.
  solve_ground_type.
Qed.
*)

(*
Lemma ToffoliTypes' : Toffoli' 0 1 2 :' (I .⊗ I .⊗ Z → 1/2 .· (I .⊗ I .⊗ Z .+ Z .⊗ I .⊗ Z .+ I .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Z)).
Proof. eapply SeqTypes with (B:=I .⊗ I .⊗ X). solve_ground_type.
  eapply SeqTypes with (B:=I .⊗ I .⊗ X). solve_ground_type.
  eapply SeqTypes with (B:=1/√2 .· (I .⊗ I .⊗ X .+ I .⊗ I .⊗ -Y)).
  eapply SeqTypes with (B:=I .⊗ I .⊗ -X). solve_ground_type.
  eapply SeqTypes with (B:=I .⊗ I .⊗ -Y). solve_ground_type.
  solve_ground_type.
  eapply SeqTypes with (B:=1/√2 .· (I .⊗ I .⊗ X .+ Z .⊗ I .⊗ -Y)). solve_ground_type.
  eapply SeqTypes with (B:=1/2 .· (I .⊗ I .⊗ X .+ I .⊗ I .⊗ Y .+ Z .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ X)). solve_ground_type.
  eapply SeqTypes with (B:=1/2 .· (I .⊗ I .⊗ X .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -Y .+ Z .⊗ I .⊗ X)). solve_ground_type.
  eapply SeqTypes with (B:=1/(2 * √2) .· (I .⊗ I .⊗ X .+ I .⊗ I .⊗ -Y .+ I .⊗ Z .⊗ X .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -X .+ Z .⊗ Z .⊗ -Y .+ Z .⊗ I .⊗ X .+ Z .⊗ I .⊗ -Y)).
  eapply SeqTypes with (B:=1/2 .· (I .⊗ I .⊗ -X .+ I .⊗ Z .⊗ -Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ I .⊗ -X)). solve_ground_type.
  eapply SeqTypes with (B:=1/2 .· (I .⊗ I .⊗ -Y .+ I .⊗ Z .⊗ X .+ Z .⊗ Z .⊗ -X .+ Z .⊗ I .⊗ -Y)). solve_ground_type.
  solve_ground_type.
  eapply SeqTypes with (B:=1/(2 * √2) .· (I .⊗ I .⊗ X .+ Z .⊗ I .⊗ -Y .+ I .⊗ Z .⊗ X .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -X .+ I .⊗ Z .⊗ -Y .+ Z .⊗ I .⊗ X .+ I .⊗ I .⊗ -Y)). solve_ground_type.
  eapply SeqTypes with (B:=1/(2 * √2) .· (I .⊗ I .⊗ X .+ Z .⊗ I .⊗ -Y .+ I .⊗ Z .⊗ X .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -X .+ I .⊗ Z .⊗ -Y .+ Z .⊗ I .⊗ X .+ I .⊗ I .⊗ -Y)). solve_ground_type.
  eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ X .+ I .⊗ I .⊗ Y .+ Z .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ X .+ I .⊗ Z .⊗ X .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -X .+ Z .⊗ Z .⊗ -X .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ X .+ Z .⊗ I .⊗ X .+ Z .⊗ I .⊗ Y .+ I .⊗ I .⊗ -Y .+ I .⊗ I .⊗ X)). solve_ground_type.
  eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ I .⊗ Z .⊗ Z .+ I .⊗ Z .⊗ -Y .+ Z .⊗ Z .⊗ -Y .+ Z .⊗ Z .⊗ -Z .+ Z .⊗ Z .⊗ -Z .+ Z .⊗ Z .⊗ Y .+ I .⊗ Z .⊗ Y .+ I .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type.
  eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type.
  eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type. 
  eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)).
  eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type.
    eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type.
  solve_ground_type.
  solve_ground_type.
Qed.
*)


(*
Lemma ToffoliTypes : Toffoli' 0 1 2 :' (Z .⊗ I .⊗ I → Z .⊗ I .⊗ I) ∩ (I .⊗ Z .⊗ I → I .⊗ Z .⊗ I ) ∩ (I .⊗ I .⊗ X → I .⊗ I .⊗ X ) ∩ (I .⊗ I .⊗ Z → 1/2 .· (I .⊗ I .⊗ Z .+ Z .⊗ I .⊗ Z .+ I .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Z)).
Proof. repeat apply cap_intro.
       - eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I). solve_ground_type.
         solve_ground_type.
         solve_ground_type. (* 02m 28s / 02m 28s *)
       - eapply SeqTypes with (B:=I .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I). solve_ground_type.
         solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I). solve_ground_type.
         solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ I).
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ I). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ I). solve_ground_type.
         solve_ground_type.
         solve_ground_type. (* 02m 14s / 04m 43s *)
       - eapply SeqTypes with (B:=I .⊗ I .⊗ Z). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ Z). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ Z).
         eapply SeqTypes with (B:=I .⊗ Z .⊗ Z). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ Z). solve_ground_type.
         solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ Z). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ Z). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ Z). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ Z).
         eapply SeqTypes with (B:=Z .⊗ I .⊗ Z). solve_ground_type.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ Z). solve_ground_type.
         solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ I .⊗ Z). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ I .⊗ Z). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ I .⊗ Z). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ I .⊗ X). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ I .⊗ X). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ I .⊗ X). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ I .⊗ X).
         eapply SeqTypes with (B:=I .⊗ I .⊗ X). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ I .⊗ X). solve_ground_type.
         solve_ground_type.
         solve_ground_type. (* 01m 57s / 06m 41s *)
       - eapply SeqTypes with (B:=I .⊗ I .⊗ X). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ I .⊗ X). solve_ground_type.
         eapply SeqTypes with (B:=1/√2 .· (I .⊗ I .⊗ X .+ I .⊗ I .⊗ -Y)).
         eapply SeqTypes with (B:=I .⊗ I .⊗ -X). solve_ground_type.
         eapply SeqTypes with (B:=I .⊗ I .⊗ -Y). solve_ground_type.
         solve_ground_type.
         eapply SeqTypes with (B:=1/√2 .· (I .⊗ I .⊗ X .+ Z .⊗ I .⊗ -Y)). solve_ground_type.
         eapply SeqTypes with (B:=1/2 .· (I .⊗ I .⊗ X .+ I .⊗ I .⊗ Y .+ Z .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ X)). solve_ground_type.
         eapply SeqTypes with (B:=1/2 .· (I .⊗ I .⊗ X .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -Y .+ Z .⊗ I .⊗ X)). solve_ground_type.
         eapply SeqTypes with (B:=1/(2 * √2) .· (I .⊗ I .⊗ X .+ I .⊗ I .⊗ -Y .+ I .⊗ Z .⊗ X .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -X .+ Z .⊗ Z .⊗ -Y .+ Z .⊗ I .⊗ X .+ Z .⊗ I .⊗ -Y)).
         eapply SeqTypes with (B:=1/2 .· (I .⊗ I .⊗ -X .+ I .⊗ Z .⊗ -Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ I .⊗ -X)). solve_ground_type.
         eapply SeqTypes with (B:=1/2 .· (I .⊗ I .⊗ -Y .+ I .⊗ Z .⊗ X .+ Z .⊗ Z .⊗ -X .+ Z .⊗ I .⊗ -Y)). solve_ground_type.
         solve_ground_type.
         eapply SeqTypes with (B:=1/(2 * √2) .· (I .⊗ I .⊗ X .+ Z .⊗ I .⊗ -Y .+ I .⊗ Z .⊗ X .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -X .+ I .⊗ Z .⊗ -Y .+ Z .⊗ I .⊗ X .+ I .⊗ I .⊗ -Y)). solve_ground_type.
         eapply SeqTypes with (B:=1/(2 * √2) .· (I .⊗ I .⊗ X .+ Z .⊗ I .⊗ -Y .+ I .⊗ Z .⊗ X .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -X .+ I .⊗ Z .⊗ -Y .+ Z .⊗ I .⊗ X .+ I .⊗ I .⊗ -Y)). solve_ground_type.
         eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ X .+ I .⊗ I .⊗ Y .+ Z .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ X .+ I .⊗ Z .⊗ X .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -X .+ Z .⊗ Z .⊗ -X .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ X .+ Z .⊗ I .⊗ X .+ Z .⊗ I .⊗ Y .+ I .⊗ I .⊗ -Y .+ I .⊗ I .⊗ X)). solve_ground_type.
         eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ I .⊗ Z .⊗ Z .+ I .⊗ Z .⊗ -Y .+ Z .⊗ Z .⊗ -Y .+ Z .⊗ Z .⊗ -Z .+ Z .⊗ Z .⊗ -Z .+ Z .⊗ Z .⊗ Y .+ I .⊗ Z .⊗ Y .+ I .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type.
         eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type.
         eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type. 
         eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)).
         eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type.
         eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type.
         solve_ground_type.
         solve_ground_type. (* 12m 33s / 19m 14s *)
Qed. (* 03m 47s / 23m 01s *)
*)



(***************************************************)
(* Prelim lemmas for tensoring in the next section *)
(***************************************************)


Local Open Scope nat_scope. 

Notation s := Datatypes.S.


Definition smpl_prog_H (p : nat -> prog) : Prop := 
  (forall (n : nat), p n = H' n).
Definition smpl_prog_I (p : nat -> prog) : Prop := 
  (forall (n : nat), p n = I'' n).
Definition smpl_prog_X (p : nat -> prog) : Prop := 
  (forall (n : nat), p n = X'' n).
Definition smpl_prog_Y (p : nat -> prog) : Prop := 
  (forall (n : nat), p n = Y'' n).
Definition smpl_prog_Z (p : nat -> prog) : Prop := 
  (forall (n : nat), p n = Z'' n).
Definition smpl_prog_S (p : nat -> prog) : Prop := 
  (forall (n : nat), p n = S' n).
Definition smpl_prog_T (p : nat -> prog) : Prop := 
  (forall (n : nat), p n = T' n).

Definition smpl_prog (p : nat -> prog) : Prop := 
  smpl_prog_H p \/ smpl_prog_I p \/ smpl_prog_X p \/ smpl_prog_Y p \/ smpl_prog_Z p \/ smpl_prog_S p \/ smpl_prog_T p.

Definition ctrl_prog (p : prog) : Prop :=
  match p with 
  | CNOT' _ _ => True 
  | _ => False
  end.

Lemma smpl_prog_H_ver : smpl_prog H'. Proof. repeat (try (try left; easy); right). Qed.
Lemma smpl_prog_I_ver : smpl_prog I''. Proof. repeat (try (try left; easy); right). Qed.
Lemma smpl_prog_X_ver : smpl_prog X''. Proof. repeat (try (try left; easy); right). Qed.
Lemma smpl_prog_Y_ver : smpl_prog Y''. Proof. repeat (try (try left; easy); right). Qed.
Lemma smpl_prog_Z_ver : smpl_prog Z''. Proof. repeat (try (try left; easy); right). Qed.
Lemma smpl_prog_S_ver : smpl_prog S'. Proof. repeat (try (try left; easy); right). Qed.
Lemma smpl_prog_T_ver : smpl_prog T'. Proof. repeat (try (try left; easy); right). Qed.

Hint Resolve smpl_prog_H_ver smpl_prog_I_ver smpl_prog_X_ver smpl_prog_Y_ver smpl_prog_Z_ver smpl_prog_S_ver smpl_prog_T_ver : wfpt_db.


Lemma prog_smpl_inc_reduce : forall (p : nat -> prog) (prg_len bit : nat),
  smpl_prog p -> bit < prg_len ->
  translate_prog prg_len (p bit) =
  (Matrix.I (2^bit)) ⊗ translate_prog 1 (p 0) ⊗ (Matrix.I (2^(prg_len - bit - 1))).
Proof. intros.    
       destruct H; [ | destruct H; [ | destruct H; [ | destruct H; [ | destruct H; [ | destruct H]]]]];
         do 2 (rewrite H); 
         simpl;
         unfold prog_smpl_app;
         bdestruct_all;
         rewrite Nat.sub_0_r, Nat.sub_diag, 
                 Nat.pow_0_r, kron_1_l, kron_1_r; auto with wf_db.
Qed.


Lemma prog_ctrl_reduce : forall (prg_len ctrl targ : nat),
  translate_prog (s prg_len) (CNOT' (s ctrl) (s targ)) = 
  (Matrix.I 2) ⊗ translate_prog prg_len (CNOT' ctrl targ).
Proof. intros.    
       unfold translate_prog, prog_ctrl_app.
       bdestruct_all; simpl.
       all : try (rewrite id_kron, Nat.add_0_r, double_mult; easy).
       - replace (2 ^ ctrl + (2 ^ ctrl + 0)) with (2 * 2^ctrl) by lia. 
         rewrite <- id_kron.
         repeat rewrite kron_assoc; auto with wf_db.  
         repeat rewrite Nat.add_0_r. repeat rewrite double_mult.
         replace 2 with (2^1) by easy. 
         repeat rewrite <- Nat.pow_add_r. 
         replace (ctrl + ((1 + (targ - ctrl)) + (prg_len - targ - 1))) with prg_len by lia; 
         easy. 
       - replace (2 ^ targ + (2 ^ targ + 0)) with (2 * 2^targ) by lia. 
         rewrite <- id_kron.
         repeat rewrite kron_assoc; auto with wf_db.  
         repeat rewrite Nat.add_0_r. repeat rewrite double_mult.
         replace 2 with (2^1) by easy. 
         repeat rewrite <- Nat.pow_add_r. 
         replace (targ + (((ctrl - targ) + 1) + (prg_len - ctrl - 1))) with prg_len by lia;
         easy. 
Qed.



Lemma WF_helper : forall (l : list Pauli) (i : nat),
  WF_Matrix (nth i (map translate_P l) Zero).
Proof. intros. 
       destruct (nth_in_or_default i0 (map translate_P l) Zero).
       - apply in_map_iff in i1.
         destruct i1 as [x [H H0]].
         rewrite <- H.
         apply WF_Matrix_Pauli.
       - rewrite e. easy. 
Qed.

Lemma WF_helper2 : forall {bit} (l : list Pauli), 
  length l = bit ->
  @WF_Matrix (2^ bit) (2^ bit) (⨂ map translate_P l).
Proof. intros; subst.
       assert (H' := (WF_big_kron _ _ (map translate_P l) Zero)).
       rewrite map_length in H'.
       apply H'.
       intros; apply WF_helper.
Qed.

Hint Resolve WF_helper WF_helper2 : wf_db.



(** original  
Lemma tensor_smpl_ground : forall (prg_len bit : nat) (p : nat -> prog)
                             (l : list Pauli) (a : Pauli) (c1 c2 : Coef),
(*    (c2 * c2 ^* )%C = C1 -> *)
    smpl_prog p -> bit < prg_len ->
    prg_len = length l -> 
    (p 0) :' @G 1 ([(C1, [nth bit l gI])]) → @G 1 ([(c2, [a])])  -> 
    (p bit) :'  @G prg_len ([(c1, l)]) → @G prg_len ([((c1*c2)%C, switch l a bit)]).
Proof. intros prg_len bit p l a c1 c2 H H0 H1 H2. 
       inversion H2; inversion H5; subst.
       apply Arrow_pht; apply PHST; try apply G_cvt.
       simpl in *. destruct H9; split; try easy. 
       apply sgt_implies_sgt'; try easy. 
       apply sgt'_implies_sgt in H1; try easy. 
       unfold singGateType in *; intros; simpl in *.
       destruct H4; destruct H6; try easy. 
       rewrite <- H4, <- H6.
       unfold translateA in *; simpl in *.
       rewrite ! Mplus_0_l in *.
       unfold translate in *; simpl in *.  
       rewrite (nth_inc bit l gI); auto.
       repeat rewrite map_app.  
       rewrite <- (nth_inc bit l gI); auto. 
       rewrite switch_inc; auto.
       repeat rewrite map_app.
       repeat rewrite big_kron_app; try (intros; apply WF_helper).
       repeat rewrite app_length.
       repeat rewrite map_length.
       rewrite firstn_length_le, skipn_length; try lia.
       do 4 rewrite Nat.pow_add_r.
       do 2 rewrite <- Mscale_kron_dist_r, <- Mscale_kron_dist_l. 
       rewrite prog_smpl_inc_reduce; auto.
       rewrite kron_assoc; auto with wf_db.
       replace (length l - bit - 1) with (length l - s bit) by lia. 
       repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ (2 ^ (length l))); 
         try (simpl; lia).         
       apply kron_simplify.
       rewrite Mmult_1_l, Mmult_1_r; try easy; try apply WF_helper2.
       all : try (apply firstn_length_le; lia).
       repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ ((2^1) * (2^(length l - s bit)))); 
         try (simpl; lia).  
       apply kron_simplify. simpl. 
       rewrite Mscale_mult_dist_r, (H1 _  (c2 .* (translate_P a ⊗ Matrix.I 1))%M).
       rewrite Mscale_mult_dist_l, Mscale_assoc, Mscale_mult_dist_l; easy.
       all : try (left; try rewrite Mscale_1_l; easy).
       assert (H' := (WF_big_kron _ _ (map translate_P (skipn (s bit) l)))).
       rewrite map_length, skipn_length in H'; try lia. 
       rewrite Mmult_1_l, Mmult_1_r; try easy.
       all : try apply (H' Zero); intros. 
       all : try apply WF_helper.
       all : try (simpl length; do 2 rewrite <- Nat.pow_add_r; apply pow_components; lia).  
       apply unit_prog. 
       all : try (rewrite <- map_app; apply WF_helper). 
       rewrite <- (Nat.pow_1_r 2); apply unit_prog.
       simpl; split; unfold translateA; simpl; rewrite Mplus_0_l; apply (@univ_TType 1); simpl; try easy; try constructor; try lca.
Qed.
*)

Lemma tensor_smpl_ground : forall (prg_len bit : nat) (p : nat -> prog)
                             (l : list Pauli) (a : Pauli) (c1 c2 : Coef),
    (c2 * c2 ^* )%C = C1 -> 
    smpl_prog p -> bit < prg_len ->
    prg_len = length l -> 
    (p 0) :' @G 1 ([(C1, [nth bit l gI])]) → @G 1 ([(c2, [a])])  -> 
    (p bit) :'  @G prg_len ([(c1, l)]) → @G prg_len ([((c1*c2)%C, switch l a bit)]).
Proof. intros prg_len bit p l a c1 c2 H H0 H1 H2 H3. 
       inversion H3; inversion H6; subst.
       apply Arrow_pht; apply PHST; try apply G_cvt.
       simpl in *. destruct H10; split; try easy. 
       apply sgt_implies_sgt'; try easy. 
       apply sgt'_implies_sgt in H2; try easy. 
       unfold singGateType in *; intros; simpl in *.
       destruct H5; destruct H7; try easy. 
       rewrite <- H5, <- H7.
       unfold translateA in *; simpl in *.
       rewrite ! Mplus_0_l in *.
       unfold translate in *; simpl in *.  
       rewrite (nth_inc bit l gI); auto.
       repeat rewrite map_app.  
       rewrite <- (nth_inc bit l gI); auto. 
       rewrite switch_inc; auto.
       repeat rewrite map_app.
       repeat rewrite big_kron_app; try (intros; apply WF_helper).
       repeat rewrite app_length.
       repeat rewrite map_length.
       rewrite firstn_length_le, skipn_length; try lia.
       do 4 rewrite Nat.pow_add_r.
       do 2 rewrite <- Mscale_kron_dist_r, <- Mscale_kron_dist_l. 
       rewrite prog_smpl_inc_reduce; auto.
       rewrite kron_assoc; auto with wf_db.
       replace (length l - bit - 1) with (length l - s bit) by lia. 
       repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ (2 ^ (length l))); 
         try (simpl; lia).
       apply kron_simplify.
       rewrite Mmult_1_l, Mmult_1_r; try easy; try apply WF_helper2.
       all : try (apply firstn_length_le; lia).
       repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ ((2^1) * (2^(length l - s bit)))); 
         try (simpl; lia).  
       apply kron_simplify. simpl. 
       rewrite Mscale_mult_dist_r, (H2 _  (c2 .* (translate_P a ⊗ Matrix.I 1))%M).
       rewrite Mscale_mult_dist_l, Mscale_assoc, Mscale_mult_dist_l; easy.
       all : try (left; try rewrite Mscale_1_l; easy).
       assert (H' := (WF_big_kron _ _ (map translate_P (skipn (s bit) l)))).
       rewrite map_length, skipn_length in H'; try lia. 
       rewrite Mmult_1_l, Mmult_1_r; try easy.
       all : try apply (H' Zero); intros. 
       all : try apply WF_helper.
       all : try (simpl length; do 2 rewrite <- Nat.pow_add_r; apply pow_components; lia).  
       apply unit_prog. 
       all : try (rewrite <- map_app; apply WF_helper). 
       rewrite <- (Nat.pow_1_r 2); apply unit_prog.
       simpl; split; unfold translateA; simpl; rewrite Mplus_0_l; apply (@univ_TType 1); simpl; try easy; try constructor; try lca.
Qed.

(* Lemma TTypes : T' 0 :' (Z → Z) ∩ (X → ((1/√2) .· (X.+Y))) ∩ (Y → ((1/√2) .· (Y.+ -X))) . *)
Lemma tensor_smpl_ground_T : forall (prg_len bit : nat) (p : nat -> prog)
                             (l : list Pauli) (a b : Pauli) (c1 c2 c3 : Coef),
    (c2 = C1 / √2 /\ c3 = - C1 / √2)%C \/ (c2 = C1 / √2 /\ c3 = C1 / √2)%C \/ (c2 = - C1 / √2 /\ c3 = C1 / √2)%C -> a <> b -> a <> gI -> b <> gI ->
    smpl_prog_T p -> bit < prg_len ->
    prg_len = length l -> 
    (p 0) :' @G 1 ([(C1, [nth bit l gI])]) → @G 1 ( (c2, [a]) :: [ (c3, [b]) ])  -> 
    (p bit) :'  @G prg_len ([(c1, l)]) → @G prg_len ( ((c1*c2)%C, switch l a bit) :: [((c1*c3)%C, switch l b bit)] ).
Proof. intros prg_len bit p l a b c1 c2 c3 H NE1 NE2 NE3 H0 H1 H2 H3.
       inversion H3; inversion H6; subst.
       apply Arrow_pht; apply PHST; try apply G_cvt.
       simpl in *. destruct H10; split; try easy. 
       apply sgt_implies_sgt'; try easy. 
       apply sgt'_implies_sgt in H2; try easy. 
       unfold singGateType in *; intros; simpl in *.
       destruct H5; destruct H7; try easy. 
       rewrite <- H5, <- H7.
       unfold translateA in *; simpl in *.
       rewrite ! Mplus_0_l in *.
       unfold translate in *; simpl in *.  
       rewrite (nth_inc bit l gI); auto.
       repeat rewrite map_app.  
       rewrite <- (nth_inc bit l gI); auto. 
       rewrite ! switch_inc; auto.
       repeat rewrite map_app.
       repeat rewrite big_kron_app; try (intros; apply WF_helper).
       repeat rewrite app_length.
       repeat rewrite map_length.
       rewrite firstn_length_le, skipn_length; try lia.
       do 4 rewrite Nat.pow_add_r.
       setoid_rewrite <- Mscale_kron_dist_r. setoid_rewrite <- Mscale_kron_dist_l.
       setoid_rewrite <- kron_plus_distr_l. setoid_rewrite <- kron_plus_distr_r.       
       assert (smpl_prog p). { repeat (try (try left; easy); right). }
       rewrite prog_smpl_inc_reduce; auto.
       rewrite kron_assoc; auto with wf_db.
       replace (length l - bit - 1) with (length l - s bit) by lia. 
       repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ (2 ^ (length l))); 
         try (simpl; lia).
       apply kron_simplify.
       rewrite Mmult_1_l,  Mmult_1_r; try easy; try apply WF_helper2.
       all : try (apply firstn_length_le; lia).
       repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ ((2^1) * (2^(length l - s bit)))); 
         try (simpl; lia).
       apply kron_simplify. simpl. 
       rewrite Mscale_mult_dist_r, (H2 _  (c2 .* (translate_P a ⊗ Matrix.I 1) .+ c3 .* (translate_P b ⊗ Matrix.I 1))%M).
       rewrite <- Mscale_mult_dist_l,  Mscale_plus_distr_r, ! Mscale_assoc; easy.
       all : try (left; try rewrite Mscale_1_l; easy).
       assert (H' := (WF_big_kron _ _ (map translate_P (skipn (s bit) l)))).
       rewrite map_length, skipn_length in H'; try lia. 
       rewrite Mmult_1_l, Mmult_1_r; try easy.
       all : try apply (H' Zero); intros. 
       all : try apply WF_helper.
       all : try (simpl length; do 2 rewrite <- Nat.pow_add_r; apply pow_components; lia).  
       apply unit_prog. 
       all : try (rewrite <- map_app; apply WF_helper). 
       rewrite <- (Nat.pow_1_r 2); apply unit_prog.
       simpl; split; unfold translateA; simpl; rewrite Mplus_0_l.
       apply (@univ_TType 1); simpl; try easy; try constructor; try lca.
       unfold uni_vecType. unfold translate. simpl. rewrite ! kron_1_r.
       intros A H5. destruct H5; try easy. rewrite <- H5.
       destruct H. destruct H. rewrite H, H7.
       apply unitary_two_pauli; auto.
       destruct H. destruct H. rewrite H, H7.
       apply unitary_two_pauli; auto.
       destruct H. rewrite H, H7.
       apply unitary_two_pauli; auto.
Qed.


Lemma tensor_ctrl_zero : forall (l : list Pauli) (prg_len targ : nat)
                           (a b : Pauli) (c1 c2 : Coef),
    (c2 * c2 ^* )%C = C1 ->
    targ < prg_len -> 0 <> targ -> 
    prg_len = length l -> 
    (CNOT' 0 1) :' @G 2 ([(C1, (nth 0 l gI) :: [nth targ l gI])]) → @G 2 ([(c2, a :: [b])])  ->
    (CNOT' 0 targ) :'  @G prg_len ([(c1, l)]) → 
                         @G prg_len ([((c1*c2)%C, switch (switch l a 0) b targ)]).
Proof. intros. destruct targ; try easy.
       inversion H3; inversion H6; subst. 
       apply Arrow_pht; apply PHST; try apply G_cvt.
       destruct l; try easy.
       simpl in *. destruct H10; split; try easy.
       apply sgt_implies_sgt'; try easy. 
       apply sgt'_implies_sgt in H2; try easy. 
       unfold singGateType in *; intros; simpl in *.
       destruct H5; destruct H7; try easy. 
       rewrite <- H5, <- H7.
       unfold translateA in *; simpl in *.
       rewrite ! Mplus_0_l in *.
       unfold translate in *; simpl in *. 
       bdestruct (targ <? length l); try lia. 
       rewrite (nth_inc targ l gI); auto.
       repeat rewrite map_app.  
       rewrite <- (nth_inc targ l gI); auto.
       rewrite switch_inc; auto.
       repeat rewrite map_app.
       repeat rewrite big_kron_app; try (intros; apply WF_helper).
       repeat rewrite app_length.
       repeat rewrite map_length.
       rewrite firstn_length_le, skipn_length; try lia.
       do 4 rewrite Nat.pow_add_r.
       do 3 rewrite Nat.add_0_r, double_mult. 
       do 2 rewrite <- Mscale_kron_dist_l.
       unfold prog_ctrl_app; bdestruct_all; rewrite ite_conv.
       rewrite Nat.pow_0_r, mult_1_l, kron_1_l; auto with wf_db.
       repeat rewrite <- kron_assoc. 
       replace (length (cons (nth targ l gI) nil)) with 1 by easy. 
       replace (length (cons b nil)) with 1 by easy. 
       replace (s (length l) - s targ - 1) with (length l - s targ) by lia. 
       rewrite Nat.pow_1_r. 
       assert (H' : ((2 * 2^targ) * 2) = (2 * 2 ^ (S targ - 0))). 
       { rewrite <- (Nat.pow_1_r 2).
         repeat rewrite <- Nat.pow_add_r. 
         rewrite (Nat.pow_1_r 2).
         apply pow_components; try lia. } 
       rewrite H'. 
       assert (H'' : 2 * 2^(length l) = 
                   ((2 * 2^(s targ - 0))) * (2 ^ ((length l) - s targ))).
      { replace 2 with (2^1) by easy.
        repeat rewrite <- Nat.pow_add_r.
        apply pow_components; try lia. } 
      rewrite H''.
      do 2 rewrite (kron_mixed_product).
      rewrite Mmult_1_l, Mmult_1_r. 
      apply kron_simplify; try easy. 
      rewrite adj_ctrlX_is_cnot1 in H2.
      simpl; rewrite Nat.add_0_r, double_mult, Nat.sub_0_r, kron_1_r.
      rewrite Nat.add_0_r, double_mult.
      replace (2 * (2 * 2^targ)) with (2 * 2^targ * 2) by lia. 
      apply cnot_conv_inc; auto with wf_db.
      all : try (apply WF_helper2; apply firstn_length_le; lia).
      distribute_scale.
      rewrite (H2 _ ( c2 .* (translate_P a ⊗ (translate_P b ⊗ Matrix.I 1)))%M); 
        try left; try easy. 
      rewrite ! kron_1_r, Mscale_mult_dist_l, Mscale_assoc.
      distribute_scale; easy.
      rewrite kron_1_r, Mscale_1_l; easy. 
      all : try apply WF_kron; try lia. 
      all : try (apply WF_helper2); try easy. 
      all : try apply skipn_length.
      all : try apply WF_kron; try lia; auto with wf_db. 
      all : try (apply firstn_length_le; lia).
      all : intros; try (rewrite <- map_app; apply WF_helper). 
      rewrite adj_ctrlX_is_cnot1; auto with unit_db.
      simpl; split; unfold translateA; simpl; rewrite Mplus_0_l; apply (@univ_TType 2); simpl; try constructor; try easy; try lca. 
Qed.


(** original
Lemma tensor_targ_zero : forall (l : list Pauli) (prg_len ctrl : nat)
                             (a b : Pauli) (c1 c2 : Coef),
    (c2 * c2 ^* )%C = C1 ->
    ctrl < prg_len -> ctrl <> 0 -> 
    prg_len = length l -> 
    (CNOT' 0 1) :' @G 2 ([(C1, (nth ctrl l gI) :: [nth 0 l gI])]) → @G 2 ([(c2, a :: [b])])  ->
    (CNOT' ctrl 0) :'  @G prg_len ([(c1, l)]) → 
                         @G prg_len ([((c1*c2)%C, switch (switch l a ctrl) b 0)]).
Proof. intros. destruct ctrl; try easy.
       inversion H3; inversion H6; subst. 
       apply Arrow_pht; apply PHST; try apply G_cvt.
       destruct l; try easy.
       simpl in *. destruct H10; split; try easy.
       apply sgt_implies_sgt'; try easy. 
       apply sgt'_implies_sgt in H2; try easy. 
       unfold singGateType in *; intros; simpl in *.
       destruct H5; destruct H7; try easy. 
       rewrite <- H5, <- H7.
       unfold translateA in *; simpl in *.
       rewrite ! Mplus_0_l in *.
       unfold translate in *; simpl in *. 
       bdestruct (ctrl <? length l); try lia. 
       rewrite (nth_inc ctrl l gI); auto.
       repeat rewrite map_app.  
       rewrite <- (nth_inc ctrl l gI); auto.
       rewrite switch_inc; auto.
       repeat rewrite map_app.
       repeat rewrite big_kron_app; try (intros; apply WF_helper).
       repeat rewrite app_length.
       repeat rewrite map_length.
       rewrite firstn_length_le, skipn_length; try lia.
       do 4 rewrite Nat.pow_add_r.
       do 3 rewrite Nat.add_0_r, double_mult. 
       do 2 rewrite <- Mscale_kron_dist_l.
       unfold prog_ctrl_app; bdestruct_all; rewrite ite_conv.
       rewrite Nat.pow_0_r, mult_1_l, kron_1_l; auto with wf_db.
       repeat rewrite <- kron_assoc. 
       replace (length (cons (nth ctrl l gI) nil)) with 1 by easy. 
       replace (length (cons b nil)) with 1 by easy. 
       replace (s (length l) - s ctrl - 1) with (length l - s ctrl) by lia. 
       rewrite Nat.pow_1_r. 
       assert (H' : ((2 * 2^ctrl) * 2) = (2 * 2 ^ (S ctrl - 0))). 
       { rewrite <- (Nat.pow_1_r 2).
         repeat rewrite <- Nat.pow_add_r.
         rewrite (Nat.pow_1_r 2).
         apply pow_components; try lia. } 
       rewrite H'. 
       assert (H'' : 2 * 2^(length l) = 
                   ((2 * 2^(s ctrl - 0))) * (2 ^ ((length l) - s ctrl))).
      { replace 2 with (2^1) by easy.
        repeat rewrite <- Nat.pow_add_r.
        apply pow_components; try lia. } 
      rewrite H''.
      rewrite (mult_comm 2 _).
      do 2 rewrite (kron_mixed_product).
      rewrite Mmult_1_l, Mmult_1_r. 
      apply kron_simplify; try easy. 
      rewrite adj_ctrlX_is_cnot1 in H2.
      simpl; rewrite Nat.add_0_r, double_mult, Nat.sub_0_r, kron_1_r.
      rewrite Nat.add_0_r, double_mult.
      replace (2 * (2 * 2^ctrl)) with (2 * 2^ctrl * 2) by lia.
      apply notc_conv_inc; auto with wf_db.
      all : try (apply WF_helper2; apply firstn_length_le; lia).
      distribute_scale.
      rewrite (H2 _ (c2 .* (translate_P a ⊗ (translate_P b ⊗ Matrix.I 1)))%M); 
        try left; try easy. 
      rewrite ! kron_1_r,  Mscale_mult_dist_l, Mscale_assoc.
      distribute_scale; easy.
      rewrite kron_1_r, Mscale_1_l. easy. 
      all : try apply WF_kron; try lia. 
      all : try (apply WF_helper2); try easy. 
      all : try apply skipn_length.
      all : try apply WF_kron; try lia; auto with wf_db. 
      all : try (apply firstn_length_le; lia).
      all : intros; try (rewrite <- map_app; apply WF_helper). 
      rewrite adj_ctrlX_is_notc1; auto with unit_db.
      simpl; split; unfold translateA; simpl; rewrite Mplus_0_l; apply (@univ_TType 2); try constructor; simpl; try lca; easy. 
Qed. 
*)


Lemma tensor_targ_zero : forall (l : list Pauli) (prg_len ctrl : nat)
                             (a b : Pauli) (c1 c2 : Coef),
    (c2 * c2 ^* )%C = C1 ->
    ctrl < prg_len -> ctrl <> 0 -> 
    prg_len = length l -> 
    (CNOT' 1 0) :' @G 2 ([(C1, (nth 0 l gI) :: [nth ctrl l gI])]) → @G 2 ([(c2, a :: [b])])  ->
    (CNOT' ctrl 0) :'  @G prg_len ([(c1, l)]) → 
                         @G prg_len ([((c1*c2)%C, switch (switch l b ctrl) a 0)]).
Proof. intros. destruct ctrl; try easy.
       inversion H3; inversion H6; subst. 
       apply Arrow_pht; apply PHST; try apply G_cvt.
       destruct l; try easy.
       simpl in *. destruct H10; split; try easy.
       apply sgt_implies_sgt'; try easy. 
       apply sgt'_implies_sgt in H2; try easy. 
       unfold singGateType in *; intros; simpl in *.
       destruct H5; destruct H7; try easy. 
       rewrite <- H5, <- H7.
       unfold translateA in *; simpl in *.
       rewrite ! Mplus_0_l in *.
       unfold translate in *; simpl in *. 
       bdestruct (ctrl <? length l); try lia. 
       rewrite (nth_inc ctrl l gI); auto.
       repeat rewrite map_app.  
       rewrite <- (nth_inc ctrl l gI); auto.
       rewrite switch_inc; auto.
       repeat rewrite map_app.
       repeat rewrite big_kron_app; try (intros; apply WF_helper).
       repeat rewrite app_length.
       repeat rewrite map_length.
       rewrite firstn_length_le, skipn_length; try lia.
       do 4 rewrite Nat.pow_add_r.
       do 3 rewrite Nat.add_0_r, double_mult. 
       do 2 rewrite <- Mscale_kron_dist_l.
       unfold prog_ctrl_app; bdestruct_all; rewrite ite_conv.
       rewrite Nat.pow_0_r, mult_1_l, kron_1_l; auto with wf_db.
       repeat rewrite <- kron_assoc. 
       replace (length (cons (nth ctrl l gI) nil)) with 1 by easy. 
       replace (length (cons b nil)) with 1 by easy. 
       replace (s (length l) - s ctrl - 1) with (length l - s ctrl) by lia. 
       rewrite Nat.pow_1_r. 
       assert (H' : ((2 * 2^ctrl) * 2) = (2 * 2 ^ (S ctrl - 0))). 
       { rewrite <- (Nat.pow_1_r 2).
         repeat rewrite <- Nat.pow_add_r.
         rewrite (Nat.pow_1_r 2).
         apply pow_components; try lia. } 
       rewrite H'. 
       assert (H'' : 2 * 2^(length l) = 
                   ((2 * 2^(s ctrl - 0))) * (2 ^ ((length l) - s ctrl))).
      { replace 2 with (2^1) by easy.
        repeat rewrite <- Nat.pow_add_r.
        apply pow_components; try lia. } 
      rewrite H''.
      rewrite (mult_comm 2 _).
      do 2 rewrite (kron_mixed_product).
      rewrite Mmult_1_l, Mmult_1_r. 
      apply kron_simplify; try easy.
      
      rewrite adj_ctrlX_is_notc1 in H2.
      simpl; rewrite Nat.add_0_r, double_mult, Nat.sub_0_r, kron_1_r.
      rewrite Nat.add_0_r, double_mult.
      replace (2 * (2 * 2^ctrl)) with (2 * 2^ctrl * 2) by lia.
      apply notc_conv_inc; auto with wf_db.
      all : try (apply WF_helper2; apply firstn_length_le; lia).
      distribute_scale.
      rewrite (H2 _ (c2 .* (translate_P a ⊗ (translate_P b ⊗ Matrix.I 1)))%M); 
        try left; try easy. 
      rewrite ! kron_1_r,  Mscale_mult_dist_l, Mscale_assoc.
      
      distribute_scale; easy.

      rewrite kron_1_r, Mscale_1_l. easy. 
      all : try apply WF_kron; try lia. 
      all : try (apply WF_helper2); try easy. 
      all : try apply skipn_length.
      all : try apply WF_kron; try lia; auto with wf_db. 
      all : try (apply firstn_length_le; lia).
      all : intros; try (rewrite <- map_app; apply WF_helper). 
      rewrite adj_ctrlX_is_notc1; auto with unit_db.
      simpl; split; unfold translateA; simpl; rewrite Mplus_0_l; apply (@univ_TType 2); try constructor; simpl; try lca; easy. 
Qed.



(** original
Lemma tensor_ctrl_reduce : forall (l1 l2 : list Pauli) (prg_len ctrl targ : nat)
                                  (a : Pauli) (c1 c2 : Coef),
  (c1 * c1 ^* )%C = C1 -> (c2 * c2 ^* )%C = C1 ->
  prg_len = length l1 -> prg_len = length l2 -> 
  (CNOT' ctrl targ) :' @G prg_len ([(c1, l1)]) → @G prg_len ([(c2, l2)])  ->
  (CNOT' (s ctrl) (s targ)) :' @G (s prg_len) ([(c1, a :: l1)]) → @G (s prg_len) ([(c2, a :: l2)]).
Proof. intros. 
       inversion H3; inversion H6; subst. 
       apply Arrow_pht; apply PHST; try apply G_cvt.
       rewrite prog_ctrl_reduce.
       simpl in *. destruct H10; split; try easy.
       apply sgt_implies_sgt'; try easy. 
       apply sgt'_implies_sgt in H1; try easy. 
       unfold singGateType in *; intros; simpl in *.
       destruct H5; destruct H7; try easy. 
       rewrite <- H5, <- H7.
       unfold translateA in *; simpl in *.
       rewrite ! Mplus_0_l in *.
       unfold translate in *; simpl in *. 
       do 2 rewrite map_length, Nat.add_0_r, double_mult, <- Mscale_kron_dist_r.
       rewrite <- H2.
       do 2 rewrite kron_mixed_product. 
       rewrite (H1 _ (c2 .* (⨂ map translate_P l2))%M);
         try (left; easy). 
       rewrite Mmult_1_r, Mmult_1_l; auto with wf_db.
       apply unit_prog_ctrl_app; auto with unit_db.
       simpl; split; unfold translateA; simpl; rewrite ! Mplus_0_l; apply (@univ_TType (length l1)); try constructor; simpl; try lca; try easy.
Qed.
*)

Lemma tensor_ctrl_reduce : forall (l1 l2 : list Pauli) (prg_len ctrl targ : nat)
                                  (a : Pauli) (c1 c2 : Coef),
  (c1 * c1 ^* )%C = C1 -> (c2 * c2 ^* )%C = C1 -> prg_len <> 0 ->
  prg_len = length l1 -> prg_len = length l2 -> 
  (CNOT' ctrl targ) :' @G prg_len ([(c1, l1)]) → @G prg_len ([(c2, l2)])  ->
  (CNOT' (s ctrl) (s targ)) :' @G (s prg_len) ([(c1, a :: l1)]) → @G (s prg_len) ([(c2, a :: l2)]).
Proof. intros. 
       inversion H4; inversion H7; subst. 
       apply Arrow_pht; apply PHST; try apply G_cvt.
       rewrite prog_ctrl_reduce.
       simpl in *. destruct H11; split; try easy.
       apply sgt_implies_sgt'; try easy. 
       apply sgt'_implies_sgt in H2; try easy. 
       unfold singGateType in *; intros; simpl in *.
       destruct H6; destruct H8; try easy. 
       rewrite <- H6, <- H8.
       unfold translateA in *; simpl in *.
       rewrite ! Mplus_0_l in *.
       unfold translate in *; simpl in *. 
       do 2 rewrite map_length, Nat.add_0_r, double_mult, <- Mscale_kron_dist_r.
       rewrite <- H3.
       do 2 rewrite kron_mixed_product. 
       rewrite (H2 _ (c2 .* (⨂ map translate_P l2))%M);
         try (left; easy). 
       rewrite Mmult_1_r, Mmult_1_l; auto with wf_db.
       apply unit_prog_ctrl_app; auto with unit_db.
       simpl; split; unfold translateA; simpl; rewrite ! Mplus_0_l; apply (@univ_TType (length l1)); try constructor; simpl; try lca; easy. 
Qed.  



Lemma cnot_translate_P_notc_translate_P (p q a b : Pauli) (c : Coef) :
cnot × (translate_P p ⊗ translate_P q) =
       (c .* (translate_P a ⊗ translate_P b × cnot))%M
     -> notc × (translate_P q ⊗ translate_P p) =
  (c .* (translate_P b ⊗ translate_P a × notc))%M.
Proof.
  intros H.

  assert (H1 : cnot × (Matrix.I 2 ⊗ Matrix.I 2) = (Matrix.I 2 ⊗ Matrix.I 2) × cnot). { lma'. }
  assert (H2 : cnot × (σx ⊗ Matrix.I 2) = (σx  ⊗ σx) × cnot). { lma'. }
  assert (H3 : cnot × (Matrix.I 2 ⊗ σx) = (Matrix.I 2 ⊗ σx) × cnot). { lma'. }
  assert (H4 : cnot × (σy ⊗ Matrix.I 2) = (σy ⊗ σx) × cnot). { lma'. }
  assert (H5 : cnot × (Matrix.I 2 ⊗ σy) = (σz ⊗ σy) × cnot). { lma'. }
  assert (H6 : cnot × (σz ⊗ Matrix.I 2) = (σz ⊗ Matrix.I 2) × cnot). { lma'. }
  assert (H7 : cnot × (Matrix.I 2 ⊗ σz) = (σz ⊗ σz) × cnot). { lma'. }
  assert (H8 : cnot × (σx ⊗ σx) = (σx ⊗ Matrix.I 2) × cnot). { lma'. }
  assert (H9 : cnot × (σx ⊗ σy) = (σy ⊗ σz) × cnot). { lma'. }
  assert (H10 : (cnot × (σx ⊗ σz) = (Copp C1) .* (σy ⊗ σy) × cnot)%M). { lma'. }
  assert (H11 : cnot × (σy ⊗ σx) = (σy ⊗ Matrix.I 2) × cnot). { lma'. }
  assert (H12 : (cnot × (σy ⊗ σy) = (Copp C1) .* (σx ⊗ σz) × cnot)%M). { lma'. }
  assert (H13 : cnot × (σy ⊗ σz) = (σx ⊗ σy) × cnot). { lma'. }
  assert (H14 : cnot × (σz ⊗ σx) = (σz ⊗ σx) × cnot). { lma'. }
  assert (H15 : cnot × (σz ⊗ σy) = (Matrix.I 2 ⊗ σy) × cnot). { lma'. }
  assert (H16 : cnot × (σz ⊗ σz) = (Matrix.I 2 ⊗ σz) × cnot). { lma'. }
  
  assert (G1 : notc × (Matrix.I 2 ⊗ Matrix.I 2) = (Matrix.I 2 ⊗ Matrix.I 2) × notc). { lma'. }
  assert (G2 : notc × (Matrix.I 2 ⊗ σx) = (σx  ⊗ σx) × notc). { lma'. }
  assert (G3 : notc × (σx ⊗ Matrix.I 2) = (σx ⊗ Matrix.I 2) × notc). { lma'. }
  assert (G4 : notc × (Matrix.I 2 ⊗ σy) = (σx ⊗ σy) × notc). { lma'. }
  assert (G5 : notc × (σy ⊗ Matrix.I 2) = (σy ⊗ σz) × notc). { lma'. }
  assert (G6 : notc × (Matrix.I 2 ⊗ σz) = (Matrix.I 2 ⊗ σz) × notc). { lma'. }
  assert (G7 : notc × (σz ⊗ Matrix.I 2) = (σz ⊗ σz) × notc). { lma'. }
  assert (G8 : notc × (σx ⊗ σx) = (Matrix.I 2 ⊗ σx) × notc). { lma'. }
  assert (G9 : notc × (σy ⊗ σx) = (σz ⊗ σy) × notc). { lma'. }
  assert (G10 : (notc × (σz ⊗ σx) = (Copp C1) .* (σy ⊗ σy) × notc)%M). { lma'. }
  assert (G11 : notc × (σx ⊗ σy) = (Matrix.I 2 ⊗ σy) × notc). { lma'. }
  assert (G12 : (notc × (σy ⊗ σy) = (Copp C1) .* (σz ⊗ σx) × notc)%M). { lma'. }
  assert (G13 : notc × (σz ⊗ σy) = (σy ⊗ σx) × notc). { lma'. }
  assert (G14 : notc × (σx ⊗ σz) = (σx ⊗ σz) × notc). { lma'. }
  assert (G15 : notc × (σy ⊗ σz) = (σy ⊗ Matrix.I 2) × notc). { lma'. }
  assert (G16 : notc × (σz ⊗ σz) = (σz ⊗ Matrix.I 2) × notc). { lma'. }

  destruct p, q; simpl in *;

    (try rewrite G1;
     try rewrite G2;
     try rewrite G3;
     try rewrite G4;
     try rewrite G5;
     try rewrite G6;
     try rewrite G7;
     try rewrite G8;
     try rewrite G9;
     try rewrite G10;
     try rewrite G11;
     try rewrite G12;
     try rewrite G13;
     try rewrite G14;
     try rewrite G15;
     try rewrite G16;
  rewrite <- Mscale_mult_dist_l;
  apply Mmult_r; auto with wf_db;
  
  try setoid_rewrite H1 in H;
  try setoid_rewrite H2 in H;
  try setoid_rewrite H3 in H;
  try setoid_rewrite H4 in H;
  try setoid_rewrite H5 in H;
  try setoid_rewrite H6 in H;
  try setoid_rewrite H7 in H;
  try setoid_rewrite H8 in H;
  try setoid_rewrite H9 in H;
  try setoid_rewrite H10 in H;
  try setoid_rewrite H11 in H;
  try setoid_rewrite H12 in H;
  try setoid_rewrite H13 in H;
  try setoid_rewrite H14 in H;
  try setoid_rewrite H15 in H;
  try setoid_rewrite H16 in H;
  
     rewrite <- Mscale_mult_dist_l in *;
  apply Minvert_r in H; [auto | auto with wf_db | auto with wf_db | exists cnot; split; lma'];
  
  setoid_rewrite <- Mscale_kron_dist_l;
  setoid_rewrite <- Mscale_kron_dist_r in H;
  apply tensor_swap; auto with wf_db).
Qed.


Lemma cnot_flip (c : Coef) (p q a b : Pauli) :
  (c * c ^* )%C = C1 ->
  CNOT' 0 1 :' @G 2 ([(C1, (p :: [q]))]) → @G 2 ([(c, (a :: [b]))]) ->
  CNOT' 1 0 :' @G 2 ([(C1, (q :: [p]))]) → @G 2 ([(c, (b :: [a]))]).
Proof. intros G H.
       inversion H; inversion H2; inversion H6; subst.
       repeat constructor. simpl in *.
       rewrite adj_ctrlX_is_notc1 in *.
       rewrite adj_ctrlX_is_cnot1 in *.
       
       unfold translateA in *; simpl in *.
       rewrite ! Mplus_0_l in *.
       
       unfold translate in *; simpl in *.
       
       apply sgt_implies_sgt'; try easy.

       apply sgt'_implies_sgt in H10; try auto with *.
       2:{simpl; split;
          unfold uni_vecType; intros A H0; inversion H0;
          try inversion H1;
          try rewrite <- H1;
          apply unit_scale; try lca; try assumption; rewrite kron_1_r;
          replace (S (S (S (S O)))) with (Init.Nat.mul (S (S O)) (S (S O))) by lia;
          apply kron_unitary; apply unit_Pauli. }

       unfold singGateType in *.
       intros A B H0 H1.
       simpl in *. destruct H0, H1; try contradiction.
       rewrite ! kron_1_r in *. rewrite ! Mscale_1_l in *.
       rewrite <- H0, <- H1.
       assert (cnot × (translate_P p ⊗ translate_P q) = ((c .* (translate_P a ⊗ translate_P b))%M) × cnot). { apply (H10 (translate_P p ⊗ translate_P q) ((c .* (translate_P a ⊗ translate_P b))%M)); left; easy. }
       
       rewrite Mscale_mult_dist_l in *.
       apply cnot_translate_P_notc_translate_P in H3. assumption.
Qed.

       
Lemma tensor_ctrl_ground : forall (l : list Pauli) (prg_len ctrl targ : nat)
                                  (a b : Pauli) (c1 c2 : Coef),
    (c1 * c1 ^* )%C = C1 -> (c2 * c2 ^* )%C = C1 ->
    ctrl < prg_len -> targ < prg_len -> ctrl <> targ -> 
    prg_len = length l -> 
    (CNOT' 0 1) :' @G 2 ([(C1, (nth ctrl l gI) :: [nth targ l gI])]) → @G 2 ([(c2, a :: [b])])  ->
    (CNOT' ctrl targ) :'  @G prg_len ([(c1, l)]) → 
                         @G prg_len ([((c1*c2)%C, switch (switch l a ctrl) b targ)]).
Proof. induction l.
       - intros; subst; simpl in *; lia.
       - intros.
         destruct ctrl; try (apply tensor_ctrl_zero; auto).
         destruct targ. try (apply tensor_targ_zero; auto).
         apply cnot_flip; assumption.
         subst; simpl in *.
         apply tensor_ctrl_reduce; auto.
         replace  (c1 * c2 * (c1 * c2) ^* )%C with  ((c1 * c1 ^* ) * (c2 * c2 ^* ))%C by lca.
         rewrite H, H0; lca.
         lia.                                            
         do 2 rewrite switch_len; easy.
         apply IHl; auto; lia.
Qed.



(****************)
(* tensor rules *)
(****************)


(** old version lemma

Lemma WFS_nth_Predicate : forall {n} (A : Predicate n) (bit : nat),
  proper_length_TPredicate A -> proper_length_TPredicate (nth_Predicate bit A).
Proof. intros.
       inversion H; subst. 
       destruct A; try easy.
       apply WFS.
       apply G_tpt.
       apply WF_G; apply WF_tt.
       easy. 
Qed.       


Lemma WFS_switch_Predicate : forall {n} (A : Predicate n) (a : Predicate 1) (bit : nat),
  proper_length_TPredicate A -> proper_length_TPredicate a -> proper_length_TPredicate (switch_Predicate A a bit).
Proof. intros.
       inversion H; inversion H0; subst. 
       destruct A; destruct a; try easy.
       apply WFS.
       apply G_tpt.
       apply WF_G; apply WF_tt.
       simpl. rewrite switch_len.
       inversion H2; inversion H6; 
       easy. 
Qed.       


Hint Resolve WFS_nth_Predicate WFS_switch_Predicate : wfpt_db.



Lemma tensor_smpl : forall (prg_len bit : nat) (p : nat -> prog)
                           (A : Predicate prg_len) (a : Predicate 1),
    proper_length_TPredicate a -> proper_length_TPredicate A -> 
    smpl_prog p -> bit < prg_len ->
    (p 0) :' (nth_Predicate bit A) → a ->
    (p bit) :'  A → (switch_Predicate A a bit).
Proof. intros. 
       inversion H; inversion H0; subst. 
       inversion H5; inversion H8; subst; try easy. 
       destruct tt; destruct tt0; simpl. 
       inversion H6; inversion H10; subst.  
       apply tensor_smpl_ground; auto; simpl in *.
       do 2 (destruct l; try easy).
Qed.




Lemma tensor_ctrl : forall (prg_len ctrl targ : nat)   
                           (A : Predicate prg_len) (a b : Predicate 1),
  proper_length_TPredicate A -> proper_length_TPredicate a -> proper_length_TPredicate b -> 
  ctrl < prg_len -> targ < prg_len -> ctrl <> targ -> 
  (CNOT 0 1) :' (nth_Predicate ctrl A) .⊗ (nth_Predicate targ A) → a .⊗ b ->
  (CNOT ctrl targ) :'  A → switch_Predicate (switch_Predicate A a ctrl) b targ.
Proof. intros. 
       inversion H; inversion H0; inversion H1; subst.
       inversion H7; inversion H10; inversion H13; subst; try easy. 
       destruct tt; destruct tt0; destruct tt1; simpl. 
       inversion H8; inversion H14; inversion H16; subst. 
       rewrite cMul_assoc.
       apply tensor_ctrl_ground; auto; simpl in *.
       rewrite H17, H19 in H5; simpl in H5.
       do 2 (destruct l0; destruct l1; try easy).
Qed.

**)


                                                      

(*
Tensor : (This is tensor_smpl_ground)

U : P -> P' ->
nth n T = P ->
U n : T -> update_P n P' T

Additive:

(f : Pauli -> Pauli) ->
(forall P, U :: A -> f A) -> 
U n :: sum T -> sum (map (fun x => update_P n (f x)) T).

Define fH P =
match P with
X => Z
Z => X
I => I
Y => -Y (-Y is ill defined for Paulis: it only works for TTypes and above.) 
 *)


(** 
Definition nth_TType {n} (bit : nat) (T : TType n) := nth bit (snd T) gI.
Definition update_P {n} (c : Coef) (bit : nat) (P : Pauli) (T : TType n) := (c, switch (snd T) P bit).
Definition lengthT {n} (T : TType n) := length (snd T).
 **)
                                                      
(** this is basically tensor_smpl_ground !!
Lemma tensor_rule_simple : forall {n} (bit : nat) U (c : Coef) (P P' : Pauli) (T : TType n),
    (c * c ^* )%C = C1 ->
    smpl_prog U -> bit < lengthT T ->
    U 0 :' (@G 1 ([(C1, [P])])) → (@G 1 ([(c, [P'])])) ->
         nth_TType bit T = P ->
         U bit :' (@G (lengthT T) ([T])) → (@G (lengthT T) ([update_P ((fst T) * c)%C bit P' T])).
Proof. intros n bit U c P P' T H' H'0 H'1 H H0.
       unfold nth_TType in H0. unfold update_P. destruct T. simpl in *.
       apply tensor_smpl_ground; try easy. rewrite H0; easy.
Qed.
*)


Definition update_TType {n} (bit : nat) (f :Pauli -> TType 1) (T : TType n) :=
  (((fst T) * (fst (f (nth bit (snd T) gI))))%C, switch (snd T) (nth 0 (snd (f (nth bit (snd T) gI))) gI) bit).


(** U n :: sum T -> sum (map (fun x => update_P n (f x)) T).**)
(** U n :: A -> sum (map (fun x => update_P n (f x)) T).**)
(** sum (map (fun x => update_P n (f x)) T) = AType_update_P n f A **)
(* length of g must match with g0 *)
Fixpoint AType_update_P {n} (bit : nat) (f : Pauli -> TType 1) (A : AType n) : AType n := (* ** *** **** ***** **** *** ** *)
  match A with
  | [] => []
  | T :: t => (update_TType bit f T) :: (AType_update_P bit f t)
  end.


Definition fH P :=
  match P with
  | gX => (C1, Z)
  | gZ => (C1, X)
  | gI => (C1, I)
  | gY => ((-C1)%C, Y)
  end.




(*
(f : Pauli -> TType 1) ->
(forall P, U :: A -> f A) -> 
U n :: sum T -> sum (map (fun x => update_P n (f x)) T).
 *)
(*** how do I construct the lemma for additive types? ***)





(** 
Lemma testing0 : forall (f : Pauli -> Pauli) (c : Coef),
    (forall P, H' 0 :' (@G 1 ([(c, [P])])) → (@G 1 ([(c, [f P])]))) -> f gZ = gX.
Proof.
  intros f c H.
  apply (typing_determinism _ Z _ (H Z)); solve_ground_type.
**)



                                                      

Fixpoint nth_AType {n} (bit : nat) (A : AType n) : AType 1 :=
  match A with
  | nil => nil
  | t :: ts => (C1, [nth bit (snd t) gI]) :: (nth_AType bit ts)
  end.


Definition nth_Predicate {n} (bit : nat) (A : Predicate n) : Predicate 1 :=
  match A with 
  | G a => G (nth_AType bit a)
  | _ => Err
  end. 

(** original
Definition nth_Predicate {n} (bit : nat) (A : Predicate n) : Predicate 1 :=
  match A with 
  | G g => G ([ (C1, [nth bit (snd g) gI]) ])
  | _ => Err
  end. 
 **)


(*** is this the correct definition? ***)
(* length of g must match with g0 *)
Fixpoint switch_AType {n} (A : AType n) (a : AType 1) (bit : nat) {struct A} : AType n :=
  match A with 
  | x :: xs=>
    match a with
    | y :: ys => (((fst x) * (fst y))%C, switch (snd x) (hd gI (snd y))  bit) :: (switch_AType xs ys bit)
    | nil => nil
    end
  | nil => nil
  end.

(** is this even needed? 
(* length of g must match with g0 *)
Fixpoint switch_AType' {n} (A : AType n) (a : AType 1) (bit : nat) {struct a} : AType n :=
  match A with 
  | x :: xs=>
    match a with
    | y :: ys => (((fst x) * (fst y))%C, switch (snd x) (hd gI (snd y))  bit) :: (switch_AType' xs ys bit)
    | nil => nil
    end
  | nil => nil
  end.

(*** Admitted ***)
Lemma switch_AType_is_switch_AType' : forall (n : nat) (A : AType n) (a : AType 1) (bit : nat), length A = length a -> switch_AType A a bit = switch_AType' A a bit.
Proof.
  intros n A a bit H.
  induction A. simpl in *. symmetry in H. rewrite length_zero_iff_nil in H. rewrite H. easy.
  induction a. simpl in *. easy. simpl in *. inversion H.
Admitted.
*)


  
  

(* length of g must match with g0 *)
Definition switch_Predicate {n} (A : Predicate n) (a : Predicate 1) (bit : nat) : Predicate n :=
  match A with 
  | G g =>
    match a with
    | G g0 => G (switch_AType g g0 bit)
    | _ => Err
    end
  | _ => Err
  end.

(** original
Definition switch_Predicate {n} (A : Predicate n) (a : Predicate 1) (bit : nat) : Predicate n :=
  match A with 
  | G g =>
    match a with
    | G g0 => G (cMul (fst g) (fst g0), switch (snd g) (hd gI (snd g0))  bit)
    | _ => Err
    end
  | _ => Err
  end.
**)









Lemma WFS_nth_Predicate : forall {n} (A : Predicate n) (bit : nat),
  proper_length_TPredicate A -> proper_length_TPredicate (nth_Predicate bit A).
Proof. intros.
       inversion H; inversion H0; subst. 
       constructor.
       constructor.
       constructor.
       constructor.
       constructor.
       lia.
       simpl.
       easy. 
Qed.       


Lemma WFS_switch_Predicate : forall {n} (A : Predicate n) (a : Predicate 1) (bit : nat),
  proper_length_TPredicate A -> proper_length_TPredicate a -> proper_length_TPredicate (switch_Predicate A a bit).
Proof. intros.
  inversion H; inversion H0; inversion H1; inversion H4; subst.
  constructor.
  constructor.
  constructor.
  constructor.
  constructor.
  inversion H2; inversion H6; inversion H8. assumption.
  inversion H9. assumption.
  simpl. rewrite switch_len.
  inversion H2; inversion H6; inversion H8. assumption.
  inversion H9. assumption.
Qed.       


Hint Resolve WFS_nth_Predicate WFS_switch_Predicate : wfpt_db.


Inductive Norm_is_one {n} : Predicate n -> Prop :=
| NIO : forall (c : Coef) (l : list Pauli), (c * c ^* )%C = C1 -> Norm_is_one (G ([(c,l)])).


Lemma single_tensor_smpl' : forall (prg_len bit : nat) (p : nat -> prog)
                             (A : Predicate prg_len) (c : Coef) (x : Pauli),
    (c * c^* )%C = C1 ->
    proper_length_TPredicate A -> 
    smpl_prog p -> bit < prg_len ->
    (p 0) :' (nth_Predicate bit A) → (G ([(c, [x])])) ->
    (p bit) :'  A → (switch_Predicate A (G([(c,[x])])) bit).
Proof. intros prg_len bit p A c x H H0 H1 H2 H3.
       inversion H0. subst.
       inversion H4. subst.
       simpl.
       destruct t. simpl.
       apply tensor_smpl_ground; auto.
       inversion H5. inversion H7. inversion H9. simpl in H11. easy.
       inversion H10. simpl in H13. easy.
Qed.


(** 
Tensor : (This is tensor_smpl_ground)

U : P -> P' ->
nth n T = P ->
U n : T -> update_P n P' T

Additive: 


    (p 0) :' (nth_Predicate bit A) → a ->
    (p bit) :'  A → (switch_Predicate A a bit).


(f : Pauli -> Pauli) ->
(forall P, U :: A -> f A) -> 
U n :: sum T -> sum (map (fun x => update_P n (f x)) T).

Define fH P =
match P with
X => Z
Z => X
I => I
Y => -Y (-Y is ill defined for Paulis: it only works for TTypes and above.)
 *)
Check (H' 0 :' (X → Z) ∩ (Z → X)).

(*** typing determinism does not work for Predicates because Arithpauli types (additive types) are implemented as lists ***)
(**
(* This is probably too general and should be about Paulis only *)
Lemma typing_determinism : forall {n} U (A B B' : Predicate n),
  U :' A → B ->
  U :' A → B' ->
    translateP(B) = translateP(B').
Proof.  intros n U A B B' H H0.
        destruct B, B' ; try easy; simpl.
        destruct U. 
        
        unfold translateP.
        inversion H; inversion H0; subst. 
Admitted.
**)
(*
Lemma typing_determinism : forall U (c (*c1 c2*) : Coef) (l l1 l2 : list Pauli),
    length l = length l1 -> length l = length l2 ->
    U :' (@G (length l) ([(c, l)])) → (@G (length l) ([(c(*1*), l1)]))
       -> U :' (@G (length l) ([(c, l)])) → (@G (length l) ([(c(*2*), l2)]))
             -> (*c1 = c2 /\*) l1 = l2.
Proof. intros U c l l1 l2 H H0 H1 H2.
       induction l1.
       - simpl in *. rewrite H in *. symmetry in H0. rewrite length_zero_iff_nil in *. rewrite H0 in *. reflexivity.
       - (** Useless IH **)
Admitted.
 *)




Lemma WF_Unitary_translate_prog : forall (U : prog) (n : nat),
    WF_Unitary (translate_prog n U).
Proof. intros U n.
       induction U; simpl;
         unfold prog_smpl_app;
         unfold prog_ctrl_app;
         bdestruct_all; simpl;
         try auto with unit_db;
         unfold WF_Unitary.
       1-7: assert ((2 ^ n) = ((2 ^ n0)*2*(2 ^ (n - n0 - 1)))).
       1,3,5,7,9,11,13: setoid_rewrite <- Nat.pow_1_r at 13;
       rewrite <- ! Nat.pow_add_r;
       replace (n0 + 1 + (n - n0 - 1)) with n by lia;
       easy.
       1-7: rewrite H0; apply kron_unitary3; auto with unit_db.
       1-2: split; try auto 15 with wf_db.
       assert (H3: 2^n = 2^n1 * (2 ^ (n2 - n1) + (2 ^ (n2 - n1) + 0)) * 2^(n-n2-1)).
       { rewrite Nat.add_0_r.
         assert (H4: (2 ^ (n2 - n1) + 2 ^ (n2 - n1)) = (2 ^ (n2 - n1 + 1))).
         { rewrite Nat.add_1_r. simpl. rewrite Nat.add_0_r. easy. }
         rewrite H4.
         rewrite <- ! Nat.pow_add_r.
         replace (n1 + (n2 - n1 + 1) + (n - n2 - 1)) with n by lia.
         easy. }
       rewrite H3. apply kron_unitary3'; try auto with unit_db.
       apply cnot_unitary'. lia.
       assert (2^n = 2^n2 * (2 ^ (n1 - n2) * 2) * 2 ^ (n - n1 - 1)).
       { setoid_rewrite <- Nat.pow_1_r at 21.
         rewrite <- ! Nat.pow_add_r.
         replace (n2 + (n1 - n2 + 1) + (n - n1 - 1)) with n by lia.
         easy. }
       rewrite H3. apply kron_unitary3'; try auto with unit_db.
       apply notc_unitary'. lia.
Qed.
Hint Resolve WF_Unitary_translate_prog: unit_db.


(*** Admitted ***)
Lemma testing00 : forall {n} (f : Pauli -> TType 1) U c bit (A : AType n),
    (forall P, U 0 :' (@G 1 ([(c, [P])])) → (@G 1 ([( (c * (fst (f P)))%C , snd (f P))] ))) ->
    U bit :' G A → G (AType_update_P bit f A).
Proof. intros n f U c bit A H.
       constructor. constructor. constructor. constructor.
       induction A. simpl. unfold translateA. unfold translate. simpl. split. 2:{ easy. } apply sgt_implies_sgt'. simpl. easy. destruct (U bit) eqn: E; simpl; unfold singGateType; intros A B H0 H1; simpl in *; destruct H0, H1; try easy; rewrite <- H0, <- H1; rewrite Mmult_0_l, Mmult_0_r; easy.
simpl in *. unfold translateA in *. simpl in *. split. 2:{ easy. } destruct IHA. apply sgt_implies_sgt'. simpl. easy. apply sgt'_implies_sgt in H0; simpl. 3:{ easy. } 

 2:{ apply (WF_Unitary_translate_prog (U bit) n). }
 2: admit.
(*
destruct (U bit); simpl. unfold prog_smpl_app. bdestruct_all. pose (kron_unitary (Matrix.I (2 ^ n0) ⊗ hadamard) (Matrix.I (2 ^ (n - n0 - 1)))) as w. replace (2 ^ n0 * 2 * 2 ^ (n - n0 - 1)) with (2 ^ n) in w.

2:{  rewrite Nat.mul_comm. rewrite Nat.mul_assoc.  rewrite <- Nat.pow_add_r . rewrite Nat.mul_comm. rewrite <- Nat.pow_succ_r'. rewrite pow_inv with (c := s (n - n0 - 1 + n0)). lia. lia. }

apply w; clear w; try apply kron_unitary; auto with unit_db.
*)
Admitted.



Lemma WF_Unitary_translate : forall (c : Coef) (P : Pauli),
     (c * c ^* )%C = C1 ->
    WF_Unitary (@translate 1 (c, [P])).
Proof. intros c P H.
       destruct P; unfold translate; simpl;
         apply unit_scale; try assumption; rewrite kron_1_r;
         auto with unit_db.
Qed.

Lemma WF_Unitary_translateA: forall (c : Coef) (P : Pauli),
    (c * c ^* )%C = C1 ->
    WF_Unitary (@translateA 1 ([(c, [P])])).
Proof. intros c P H.
       unfold translateA. simpl. rewrite Mplus_0_l. apply WF_Unitary_translate. assumption.
Qed.

Lemma uni_vecType_translateA: forall (c : Coef) (P : Pauli),
      (c * c ^* )%C = C1 ->
      uni_vecType ([@translateA 1 ([(c, [P])])]).
Proof. intros c P H.
       unfold uni_vecType.
       intros H0 H1.
       inversion H1.
       - rewrite <- H2.
         apply WF_Unitary_translateA. assumption.
       - inversion H2.
Qed.



Lemma translate_P_equal : forall (P1 P2 : Pauli),
    translate_P P1 = translate_P P2 -> P1 = P2.
Proof. intros P1 P2 H.
       destruct P1, P2; try easy; simpl in *.
       1,2,4,6,7,9,12:specialize (matrix_equality_implies_element_equality _ _ 1 0 H);
       intros H'; contradict H'; unfold Matrix.I; simpl; try nonzero;
       intros H''; symmetry in H''; contradict H''; try nonzero.
       5:specialize (matrix_equality_implies_element_equality _ _ 0 0 H);
       intros H'; contradict H'; unfold Matrix.I; simpl; try nonzero;
       intros H''; symmetry in H''; contradict H''; try nonzero.
       1,4:specialize (matrix_equality_implies_element_equality _ _ 1 1 H);
       intros H'; contradict H'; unfold Matrix.I; simpl;
       intros H''; inversion H'';  contradict H1; lra. 
       1,2:specialize (matrix_equality_implies_element_equality _ _ 1 0 H);
       intros H'; contradict H'; unfold Matrix.I; simpl;
       intros H''; inversion H'';  contradict H1; lra.
Qed.


Locate C0_imp.
Check C0_imp.
Lemma translate_P_equal' : forall (c1 c2 : Coef) (P1 P2 : Pauli),
    c1 <> C0 -> c2 <> C0 ->
    (c1 .* translate_P P1 = c2 .* translate_P P2)%M -> c1 = c2 /\ P1 = P2.
Proof. intros c1 c2 P1 P2 NZ1 NZ2 H.
       destruct P1, P2;
       contradict_matrix_equalities.
       all: destruct c1, c2;
         extract_linear_system H;
       simpl in *;
       split; try easy.
Qed.

Lemma WF_Matrix_translate: forall (c : Coef) (P : Pauli), WF_Matrix (@translate 1 (c, [P])).
Proof. intros c P. destruct P; unfold translate; simpl; auto with wf_db. Qed.
Lemma WF_Matrix_translateA: forall (c : Coef) (P : Pauli), WF_Matrix (@translateA 1 ([(c, [P])])).
Proof. intros c P. unfold translateA. simpl. rewrite Mplus_0_l. apply WF_Matrix_translate. Qed.

Hint Resolve WF_Matrix_translate WF_Matrix_translateA : wf_db.

Lemma typing_determinism_Pauli : forall U (c c1 c2 : Coef) (P P1 P2 : Pauli),
    (c * c ^* )%C = C1 -> (c1 * c1 ^* )%C = C1 -> (c2 * c2 ^* )%C = C1 ->
    U :' (@G 1 ([(c, [P])])) → (@G 1 ([(c1, [P1])]))
       -> U :' (@G 1 ([(c, [P])])) → (@G 1 ([(c2, [P2])]))
             -> c1=c2 /\ P1 = P2.
Proof. intros U c c1 c2 P P1 P2 NormOne NormOne1 NormOne2 H H0.
       inversion H. inversion H3. subst.
       inversion H7; subst. simpl in *.
       apply sgt'_implies_sgt in H1; auto.
       3: simpl; split; apply uni_vecType_translateA; assumption. 
       2: apply (WF_Unitary_translate_prog U 1).
       unfold singGateType in H1. simpl in H1.
       specialize (H1 (@translateA 1 ([(c, [P])]) ) (@translateA 1 ([(c1, [P1])])) ).
       assert (@translateA 1 ([(c, [P])]) = @translateA 1 ([(c, [P])]) \/ False).
       { left. easy. }
       assert (@translateA 1 ([(c1, [P1])]) = @translateA 1 ([(c1, [P1])]) \/ False).
       { left. easy. }
       Search (_ /\ True). rewrite kill_true in *. rewrite ! kill_false in *.
       apply H1 in H4; try easy.
       clear H8. clear H2.
       specialize (WF_Unitary_translate_prog U 1) as WFU.
       destruct WFU.
       assert (translate_prog 1 U × translateA ([(c, [P])]) × (translate_prog 1 U)† = translateA ([(c1, [P1])])).
       {setoid_rewrite H4. rewrite Mmult_assoc.
       Search (?A × ?B = Matrix.I _).
       apply Minv_flip in H8; auto with wf_db.
       setoid_rewrite H8. rewrite Mmult_1_r; auto with wf_db. }

       inversion H0. inversion H12. subst.
       inversion H16; subst. simpl in *.
       apply sgt'_implies_sgt in H10; auto.
       3: simpl; split; apply uni_vecType_translateA; assumption.
       2: apply (WF_Unitary_translate_prog U 1).
       unfold singGateType in H10. simpl in H10.
       specialize (H10 (@translateA 1 ([(c, [P])])) (@translateA 1 ([(c2, [P2])]))).
      assert (@translateA 1 ([(c, [P])]) = @translateA 1 ([(c, [P])]) \/ False).
       { left. easy. }
       assert (@translateA 1 ([(c2, [P2])]) = @translateA 1 ([(c2, [P2])]) \/ False).
       { left. easy. }
       rewrite kill_true in *. rewrite ! kill_false in *.
       apply H10 in H13; try easy.
       clear H11. clear H17.
       assert (translate_prog 1 U × translateA ([(c, [P])]) × (translate_prog 1 U) † =
                 translateA ([(c2, [P2])])).
       { setoid_rewrite H13. rewrite Mmult_assoc.
       apply Minv_flip in H8; auto with wf_db.
       setoid_rewrite H8. rewrite Mmult_1_r; auto with wf_db. }

       setoid_rewrite H9 in H11.
       unfold translateA in H11. simpl in H11. rewrite 2 Mplus_0_l in H11.
       unfold translate in H11. simpl in H11. rewrite 2 kron_1_r in H11.
       apply translate_P_equal' in H11.
       3: { inversion NormOne2. destruct c2. simpl in *. rewrite H19. intro. inversion H17.
            rewrite H21, H22 in H18. contradict H18. lra. }
       2: { inversion NormOne1. destruct c1. simpl in *. rewrite H19. intro. inversion H17.
            rewrite H21, H22 in H18. contradict H18. lra. }
       clear -H11. easy.
Qed.

Lemma tensor_add : forall {n} U m (A B C : Predicate 1) (T : Predicate n),
    uni_vecType (translateP T) ->
    uni_vecType (translateP A) ->
    uni_vecType (translateP (B .+ C)) ->
    smpl_prog U -> m < n ->
    proper_length_TPredicate T -> proper_length_TPredicate A -> proper_length_TPredicate B -> proper_length_TPredicate C ->
    nth_Predicate m T = A ->
    (U 0) :' A → B .+ C ->
    (U m) :' T → (switch_Predicate T B m) .+ (switch_Predicate T C m).
Proof. intros n U m A B C T unitransT unitransA unitransBpC spU mn WFST WFSA WFSB WFSC nthTA H. 
       inversion WFSA; subst. inversion H0; subst. rewrite <- H3 in *.
       inversion WFSB; subst. inversion H2; subst.
       inversion WFSC; subst. inversion H5; subst.
       inversion WFST; subst. inversion H7; subst.
       simpl in *. destruct t2, t0, t1, t; simpl in *.
       inversion H1; subst. inversion H10; subst. inversion H11; subst. simpl in H12.
       destruct l2. inversion H12. 2:{ inversion H13. } inversion H12.
       rewrite length_zero_iff_nil in H14. subst.
       inversion H4; subst. inversion H14; subst. inversion H15; subst. simpl in H16.
       destruct l0. inversion H16. 2:{ inversion H17. } inversion H16.
       rewrite length_zero_iff_nil in H18. subst.
       inversion H6; subst. inversion H18; subst. inversion H19; subst. simpl in H20.
       destruct l1. inversion H20. 2:{ inversion H21. } inversion H20.
       rewrite length_zero_iff_nil in H22. subst.
       inversion H8; subst. inversion H22; subst. 2:{ inversion H25. } inversion H23; subst.
       simpl in *. inversion H3.
       clear H9. clear H12. clear H13. clear H16. clear H17. clear H20. clear H0. clear H1.
       clear H2. clear H4. clear H5. clear H6. clear H7. clear H8. clear H11. clear H10.
       clear H15. clear H14. clear H19. clear H18. clear H3. clear WFST. clear WFSA.
       clear WFSB. clear WFSC. clear H23. clear H22.
       constructor. constructor. constructor. constructor. constructor. 2:{ easy. } simpl.
       inversion H; subst. inversion H2; subst. simpl in *. rewrite kill_true in *.
       apply sgt_implies_sgt'. simpl. easy.
       apply sgt'_implies_sgt in H3. unfold singGateType in H3. simpl in H3.
       2:{ apply (WF_Unitary_translate_prog (U 0) 1). }
       2:{ easy. }
       2:{ simpl. split. simpl in *. assumption. assumption. }
       specialize (H3 (@translateA 1 ([(C1, [nth m l gI])])) (@translateA 1 ((c0, [p0]) :: [(c1, [p1])]))).
       assert (translate_prog 1 (U 0) × translateA ([(C1, [nth m l gI])]) =
                 translateA ((c0, [p0]) :: [(c1, [p1])]) × translate_prog 1 (U 0)).
       { apply H3. left; easy. left; easy. } clear H3. clear H0. clear H1.
       unfold singGateType. intros A B H0 H1. simpl in *. rewrite kill_false in *. subst.
       unfold translateA in *. simpl in *. rewrite ! Mplus_0_l in *.
       unfold translate in *. simpl in *.
       rewrite (nth_inc m l gI); auto.
       rewrite ! map_app.
       rewrite <- (nth_inc m l gI); auto.
       rewrite ! switch_inc; auto.
       rewrite ! map_app.
       rewrite ! big_kron_app; try (intros; apply WF_helper).
       rewrite ! app_length.
       rewrite ! map_length.
       rewrite firstn_length_le, skipn_length; try lia.
       rewrite ! Nat.pow_add_r.
       setoid_rewrite <- Mscale_kron_dist_r.
       setoid_rewrite <- Mscale_kron_dist_l.
       setoid_rewrite <- kron_plus_distr_l.
       setoid_rewrite <- kron_plus_distr_r.
       rewrite prog_smpl_inc_reduce; auto.
       rewrite kron_assoc; auto with wf_db.
       replace (length l - m - 1) with (length l - s m) by lia. 
       repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ (2 ^ (length l))); 
         try (simpl; lia).
       apply kron_simplify.
       rewrite Mmult_1_l, Mmult_1_r; try easy; try apply WF_helper2.
       all : try (apply firstn_length_le; lia).
       repeat rewrite (kron_mixed_product' _ _ _ _ _ _ _ _ ((2^1) * (2^(length l - s m)))); 
         try (simpl; lia).
       apply kron_simplify. simpl. 
       rewrite Mscale_mult_dist_r. rewrite Mscale_1_l in H4. rewrite H4.
       rewrite <- ! Mscale_assoc.
       rewrite <- ! Mscale_mult_dist_l.
       rewrite <- Mscale_plus_distr_r.
       easy.
       rewrite Mmult_1_l, Mmult_1_r; try easy;
       assert (H' := (WF_big_kron _ _ (map translate_P (skipn (s m) l))));
       rewrite map_length, skipn_length in H'; try lia;
       try apply (H' Zero); intros. 
       all : try apply WF_helper.
       all : try (simpl length; do 2 rewrite <- Nat.pow_add_r; apply pow_components; lia).  
       apply unit_prog. 
       all : try (rewrite <- map_app; apply WF_helper).
Qed.



(*** We don't have Pauli to Pauli functions or the similar sort, only the proposition that the program has some type. Is this the right way to go? ***)
(** 
Additive : 

    (p 0) :' (nth_Predicate bit A) → a ->
    (p bit) :'  A → (switch_Predicate A a bit).

(f : Pauli -> Pauli) ->
(forall P, U :: A -> f A) -> 
U n :: sum T -> sum (map (fun x => update_P n (f x)) T).
 **)
(* testing purposes
Lemma testing00 : forall {n} (f : Pauli -> TType 1) U c bit (A : AType n),
    (forall P, U 0 :' (@G 1 ([(c, [P])])) → (@G 1 ([( (c * (fst (f P)))%C , snd (f P))] ))) ->
    U bit :' G A → G (AType_update_P bit f A).
*)
(*** Admitted ***)
(** is this needed? **)
Lemma simpl_prog_preserves_norm : forall (p : nat -> prog) (c : Coef) (P P' : Pauli),
  smpl_prog p -> p 0 :' @G 1 ([(C1, [P])]) → @G 1 ([(c, [P'])]) ->
                      (c * c ^* )%C = C1.
Proof. intros p c P P' H H0.
       inversion H0; subst.
       inversion H3; subst.
       inversion H4; subst.
       simpl in *.

       unfold singGateType' in H5. simpl in H5.
       destruct p. simpl in H5.  unfold prog_smpl_app in H5. 

       (*
       apply sgt'_implies_sgt in H5; simpl.
       3: easy.
       2: apply (WF_Unitary_translate_prog (p 0) 1).
       2: split; apply uni_vecType_translateA; try lca.
       unfold singGateType in H5; simpl in H5;
       specialize (H5 (@translateA 1 ([(C1, [P])])) (@translateA 1 ([(c, [P'])])));
       assert (translate_prog 1 (p 0) × translateA ([(C1, [P])]) =
                 translateA ([(c, [P'])]) × translate_prog 1 (p 0));
         try apply H5; try left; try easy. *)
Admitted.
       
       


(*** how does this help us construct the tensor rule lemmas?? ***)
Lemma testing0 : forall (f : Pauli -> Pauli) (c : Coef),
     (c * c ^* )%C = C1 ->
    (forall P, H' 0 :' (@G 1 ([(C1, [P])])) → (@G 1 ([(c, [f P])]))) -> f gZ = gX.
Proof.
  intros f c NormOne H.
  specialize (H gZ).
  assert (H' 0 :' (@G 1 ([(C1, [gZ])])) → (@G 1 ([(C1, [gX])]))). { solve_ground_type. }
  apply (typing_determinism_Pauli (H' 0) C1 c C1 gZ _ _); auto; try lca; easy.
Qed.



(** bad with automation?, doesn't scale with AType types **) 
Lemma single_tensor_smpl : forall (prg_len bit : nat) (p : nat -> prog)
                             (A : Predicate prg_len) (a : Predicate 1),
    Norm_is_one a ->
    proper_length_TPredicate a -> proper_length_TPredicate A -> 
    smpl_prog p -> bit < prg_len ->
    (p 0) :' (nth_Predicate bit A) → a ->
    (p bit) :'  A → (switch_Predicate A a bit).
Proof. intros prg_len bit p A a G' H H0 H1 H2 H3.  
       inversion H; inversion H0; subst. 
       inversion H4; inversion H7; subst.
       simpl.
       destruct t, t0. simpl.
       apply tensor_smpl_ground; auto.
       3:{ simpl in H3. inversion H5; inversion H9.
           - inversion H11. simpl in H13. destruct l.
             + simpl in *. discriminate.
             + inversion H13. rewrite length_zero_iff_nil in H15. rewrite H15 in *. simpl.
               assumption.
           - inversion H12. simpl in H15. destruct l.
             + simpl in *. discriminate.
             + inversion H15. rewrite length_zero_iff_nil in H17. rewrite H17 in *. simpl.
               assumption. }
       2:{ inversion H8; inversion H9. inversion H11. simpl in H13. easy.
           inversion H12. simpl in H15. easy. }  
       1:{ inversion G'. assumption. }
Qed.

Lemma single_tensor_ctrl : forall (prg_len ctrl targ : nat)   
                             (A : Predicate prg_len) (a b : Predicate 1),
  Norm_is_one A -> Norm_is_one (a .⊗ b) ->
  proper_length_TPredicate A -> proper_length_TPredicate a -> proper_length_TPredicate b -> 
  ctrl < prg_len -> targ < prg_len -> ctrl <> targ -> 
  (CNOT' 0 1) :' (nth_Predicate ctrl A) .⊗ (nth_Predicate targ A) → a .⊗ b ->
  (CNOT' ctrl targ) :'  A → switch_Predicate (switch_Predicate A a ctrl) b targ.
Proof. intros prg_len ctrl targ A a b G' G'' H H0 H1 H2 H3 H4 H5. 
       inversion H; inversion H0; inversion H1; subst.
       inversion H6; inversion H9; inversion H12; subst.
       simpl. destruct t, t0, t1. simpl.
       rewrite <- Cmult_assoc.
       apply tensor_ctrl_ground; auto; simpl in *.
       4:{ rewrite Cmult_1_r in H5.
             inversion H10; inversion H13; subst. inversion H11; inversion H15; subst.
           - inversion H14; inversion H17; subst. simpl in *.
             destruct l0, l1; simpl in *; try discriminate.
             inversion H16; inversion H19; subst.
             rewrite length_zero_iff_nil in H21, H22. rewrite H21, H22 in *. simpl in *.
             assumption.
           - inversion H14; inversion H18; subst. simpl in *.
             destruct l0, l1; simpl in *; try discriminate.
             inversion H16; inversion H20; subst.
             rewrite length_zero_iff_nil in H22, H23. rewrite H22, H23 in *. simpl in *.
             assumption.
           - inversion H16; inversion H19; subst. simpl in *.
             destruct l0, l1; simpl in *; try discriminate.
             inversion H14; inversion H20; subst.
             rewrite length_zero_iff_nil in H22, H23. rewrite H22, H23 in *. simpl in *.
             assumption.
           - inversion H16; inversion H20; subst. simpl in *.
             destruct l0, l1; simpl in *; try discriminate.
             inversion H14; inversion H19; subst.
             rewrite length_zero_iff_nil in H23, H24. rewrite H23, H24 in *. simpl in *.
             assumption. }
       3:{ inversion H7. inversion H11. inversion H15. simpl in H17. easy.
           inversion H16. easy. }
       2:{ inversion G''. assumption. }
       1:{ inversion G'. assumption. }
Qed.




(* Lemma HTypes : H' 0 :' (X → Z) ∩ (Z → X). *)

Check (H' 0 :' (X → Z) ∩ (Z → X)).




Ltac solve_single_tensor_smpl prg_len bit p A a :=
  let H := fresh "H" in pose (single_tensor_smpl prg_len bit p A a) as H; simpl in *; rewrite ! Cmult_1_r in *; apply H; auto with *; repeat constructor; try lca; try lia; solve_ground_type.
(*** more automation? ***)
(*
Ltac solve_single_tensor_smpl' prg_len bit p A a :=
  match goal with
  | [H: ?p ?n :' ?A → ?B |- _] =>
      match A
  end *)
(** 
H' 2 :' I .⊗ I .⊗ Z → I .⊗ I .⊗ X
solve_single_tensor_smpl 3 2 H' (I .⊗ I .⊗ Z) X.
**)
Ltac solve_single_tensor_ctrl prg_len ctrl targ A a b :=
  let H := fresh "H" in pose (single_tensor_ctrl prg_len ctrl targ A a b) as H; simpl in *; rewrite ! Cmult_1_r in *; apply H; do 4 try constructor; try lca; try lia; solve_ground_type.


Lemma ToffoliTypes : Toffoli' 0 1 2 :' (Z .⊗ I .⊗ I → Z .⊗ I .⊗ I) ∩ (I .⊗ Z .⊗ I → I .⊗ Z .⊗ I ) ∩ (I .⊗ I .⊗ X → I .⊗ I .⊗ X ). 
Proof. repeat apply cap_intro.
       - eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_smpl 3 2 H' (Z .⊗ I .⊗ I ) I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_ctrl 3 1 2 (Z .⊗ I .⊗ I ) I I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_smpl 3 2 Z'' (Z .⊗ I .⊗ I ) I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_smpl 3 2 S' (Z .⊗ I .⊗ I) I.
         solve_single_tensor_smpl 3 2 T' (Z .⊗ I .⊗ I) I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_ctrl 3 0 2 (Z .⊗ I .⊗ I) Z I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_smpl 3 2 T' (Z .⊗ I .⊗ I) I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_ctrl 3 1 2 (Z .⊗ I .⊗ I) I I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_smpl 3 2 Z'' (Z .⊗ I .⊗ I) I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_smpl 3 2 S' (Z .⊗ I .⊗ I) I.
         solve_single_tensor_smpl 3 2 T' (Z .⊗ I .⊗ I) I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_ctrl 3 0 2 (Z .⊗ I .⊗ I) Z I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_smpl 3 1 T' (Z .⊗ I .⊗ I) I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_smpl 3 2 T' (Z .⊗ I .⊗ I) I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_smpl 3 2 H' (Z .⊗ I .⊗ I) I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_ctrl 3 0 1 (Z .⊗ I .⊗ I) Z I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_smpl 3 0 T' (Z .⊗ I .⊗ I) Z.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_smpl 3 1 Z'' (Z .⊗ I .⊗ I) I.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ I).
         solve_single_tensor_smpl 3 1 S' (Z .⊗ I .⊗ I) I.
         solve_single_tensor_smpl 3 1 T' (Z .⊗ I .⊗ I) I.
         solve_single_tensor_ctrl 3 0 1 (Z .⊗ I .⊗ I) Z I.
       - eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         solve_single_tensor_smpl 3 2 H' (I .⊗ Z .⊗ I) I.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         solve_single_tensor_ctrl 3 1 2 (I .⊗ Z .⊗ I) Z I.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         solve_single_tensor_smpl 3 2 Z'' (I .⊗ Z .⊗ I) I.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         solve_single_tensor_smpl 3 2 S' (I .⊗ Z .⊗ I) I.
         solve_single_tensor_smpl 3 2 T' (I .⊗ Z .⊗ I) I.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         solve_single_tensor_ctrl 3 0 2 (I .⊗ Z .⊗ I) I I.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         solve_single_tensor_smpl 3 2 T' (I .⊗ Z .⊗ I) I.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         solve_single_tensor_ctrl 3 1 2 (I .⊗ Z .⊗ I) Z I.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         solve_single_tensor_smpl 3 2 Z'' (I .⊗ Z .⊗ I) I.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         solve_single_tensor_smpl 3 2 S' (I .⊗ Z .⊗ I) I.
         solve_single_tensor_smpl 3 2 T' (I .⊗ Z .⊗ I) I.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         solve_single_tensor_ctrl 3 0 2 (I .⊗ Z .⊗ I) I I.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         solve_single_tensor_smpl 3 1 T' (I .⊗ Z .⊗ I) Z.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         solve_single_tensor_smpl 3 2 T' (I .⊗ Z .⊗ I) I.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ I).
         solve_single_tensor_smpl 3 2 H' (I .⊗ Z .⊗ I) I.
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ I). 
         solve_single_tensor_ctrl 3 0 1 (I .⊗ Z .⊗ I) Z Z.
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ I).
         solve_single_tensor_smpl 3 0 T' (Z .⊗ Z .⊗ I) Z.
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ I).
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ I).
         solve_single_tensor_smpl 3 1 Z'' (Z .⊗ Z .⊗ I) Z.
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ I).
         solve_single_tensor_smpl 3 1 S' (Z .⊗ Z .⊗ I) Z.
         solve_single_tensor_smpl 3 1 T' (Z .⊗ Z .⊗ I) Z.
         solve_single_tensor_ctrl 3 0 1 (Z .⊗ Z .⊗ I) I Z.
       - eapply SeqTypes with (B:=I .⊗ I .⊗ Z).
         solve_single_tensor_smpl 3 2 H' (I .⊗ I .⊗ X) Z.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ Z).
         solve_single_tensor_ctrl 3 1 2 (I .⊗ I .⊗ Z) Z Z.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ Z).
         eapply SeqTypes with (B:=I .⊗ Z .⊗ Z).
         solve_single_tensor_smpl 3 2 Z'' (I .⊗ Z .⊗ Z) Z.
         eapply SeqTypes with (B:=I .⊗ Z .⊗ Z).
         solve_single_tensor_smpl 3 2 S' (I .⊗ Z .⊗ Z) Z.
         solve_single_tensor_smpl 3 2 T' (I .⊗ Z .⊗ Z) Z.
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ Z).
         solve_single_tensor_ctrl 3 0 2 (I .⊗ Z .⊗ Z) Z Z.
         eapply SeqTypes with (B:=Z .⊗ Z .⊗ Z).
         solve_single_tensor_smpl 3 2 T' (Z .⊗ Z .⊗ Z) Z.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ Z).
         solve_single_tensor_ctrl 3 1 2 (Z .⊗ Z .⊗ Z) I Z.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ Z).
         eapply SeqTypes with (B:=Z .⊗ I .⊗ Z).
         solve_single_tensor_smpl 3 2 Z'' (Z .⊗ I .⊗ Z) Z.
         eapply SeqTypes with (B:=Z .⊗ I .⊗ Z).
         solve_single_tensor_smpl 3 2 S' (Z .⊗ I .⊗ Z) Z.
         solve_single_tensor_smpl 3 2 T' (Z .⊗ I .⊗ Z) Z.
         eapply SeqTypes with (B:=I .⊗ I .⊗ Z).
         solve_single_tensor_ctrl 3 0 2 (Z .⊗ I .⊗ Z) I Z.
         eapply SeqTypes with (B:=I .⊗ I .⊗ Z).
         solve_single_tensor_smpl 3 1 T' (I .⊗ I .⊗ Z) I.
         eapply SeqTypes with (B:=I .⊗ I .⊗ Z).
         solve_single_tensor_smpl 3 2 T' (I .⊗ I .⊗ Z) Z.
         eapply SeqTypes with (B:=I .⊗ I .⊗ X).
         solve_single_tensor_smpl 3 2 H' (I .⊗ I .⊗ Z) X.
         eapply SeqTypes with (B:=I .⊗ I .⊗ X).
         solve_single_tensor_ctrl 3 0 1 (I .⊗ I .⊗ X) I I.
         eapply SeqTypes with (B:=I .⊗ I .⊗ X).
         solve_single_tensor_smpl 3 0 T' (I .⊗ I .⊗ X) I.
         eapply SeqTypes with (B:=I .⊗ I .⊗ X).
         eapply SeqTypes with (B:=I .⊗ I .⊗ X).
         solve_single_tensor_smpl 3 1 Z'' (I .⊗ I .⊗ X) I.
         eapply SeqTypes with (B:=I .⊗ I .⊗ X).
         solve_single_tensor_smpl 3 1 S' (I .⊗ I .⊗ X) I.
         solve_single_tensor_smpl 3 1 T' (I .⊗ I .⊗ X) I.
         solve_single_tensor_ctrl 3 0 1 (I .⊗ I .⊗ X) I I.
Qed.








(** 
Lemma pl_ap_nth_Predicate : forall {n} (A : Predicate n) (bit : nat),
  proper_length_APredicate A -> proper_length_APredicate (nth_Predicate bit A).
Proof. intros.
       inversion H; subst. 
       destruct A; try easy.
       apply pl_ap.
       constructor.
       constructor.
       inversion H1; subst.
       clear H. clear H0. clear H1.
       induction H3.
       do 2 constructor. lia. simpl. easy.
       constructor. constructor. lia. simpl. easy.
       assumption.
Qed.       


Inductive equal_len {n m : nat} : Predicate n -> Predicate m -> Prop :=
| Eq_len : forall (A : AType n) (a : AType m), length A = length a -> equal_len (G A) (G a).

(*** Admitted ***)
Lemma pl_ap_switch_Predicate : forall {n} (A : Predicate n) (a : Predicate 1) (bit : nat),
  equal_len A a ->
  proper_length_APredicate A -> proper_length_APredicate a -> proper_length_APredicate (switch_Predicate A a bit).
Proof. intros n A a bit G H H0.

       inversion G; subst.
       
       clear G.
       inversion H; inversion H0; subst.
       do 2 constructor.
       inversion H3; inversion H6; subst.
       
       clear H. clear H0. clear H2. clear H5. clear H3. clear H6.

       induction H7; induction H9.
       - destruct a, a0. simpl. constructor. constructor.
         + inversion H. assumption.
         + simpl. rewrite switch_len. inversion H. simpl in H3. assumption.
       - inversion H1. symmetry in H3. rewrite length_zero_iff_nil in H3. rewrite H3 in *. simpl in *. destruct a, a0. simpl. constructor. constructor.
         + inversion H. assumption.
         + simpl. rewrite switch_len. inversion H. simpl in H4. assumption.
       - inversion H1. rewrite length_zero_iff_nil in H3. rewrite H3 in *. simpl in *. destruct a, a0. simpl. constructor. constructor.
         + inversion H. assumption.
         + simpl. rewrite switch_len. inversion H. simpl in H4. assumption.
       - inversion H1. 
       
(*
       destruct t, t0. simpl in *. constructor. constructor. inversion H7. inversion H2. assumption. inversion H3. assumption. simpl. Search switch. rewrite switch_len. inversion H7. inversion H2. simpl in H5. assumption. inversion H3. simpl in H6. assumption.
       *)
       

       
       destruct a, a0. simpl in *.

       constructor. constructor.  inversion H7. inversion H2. assumption. inversion H2. assumption. simpl. rewrite switch_len. inversion H. simpl in *. assumption.
(*** useless IH ***)

(*
       rewrite length_zero_iff_nil in H0. rewrite H0 in *. inversion H7. inversion H2. simpl.        
       inversion H9. inversion H1.
       inversion H1. *)

Admitted.

Hint Resolve pl_ap_nth_Predicate pl_ap_switch_Predicate : wfpt_db.
**)




(*
Inductive equal_len {n m : nat} : Predicate n -> Predicate m -> Prop :=
| Eq_len : forall (A : AType n) (a : AType m), length A = length a -> equal_len (G A) (G a).
(*** Admitted ***)
Lemma tensor_smpl : forall (prg_len bit : nat) (p : nat -> prog)
                      (A : Predicate prg_len) (a : Predicate 1),
   (* Norm_is_one a -> *) equal_len A a -> 
    proper_length_APredicate a -> proper_length_APredicate A -> 
    smpl_prog p -> bit < prg_len ->
    (p 0) :' (nth_Predicate bit A) → a ->
    (p bit) :' A → (switch_Predicate A a bit).
(* 

(p 0) :' (nth_Predicate bit A) → a ->
(H 0) :' (nth_Predicate 1 (X ⊗ X + Y ⊗ X)) → (Z + Z)
where (nth_Predicate 1 (X ⊗ X + Y ⊗ X)) = (X + X)


(p bit) :' A → (switch_Predicate A a bit).
(H 1) :' (X ⊗ X + Y ⊗ X) → (switch_Predicate (X ⊗ X + Y ⊗ X) (Z + Z) 1)
where (switch_Predicate (X ⊗ X + Y ⊗ X) (Z + Z) 1) = (X ⊗ Z + Y ⊗ Z) 



H 0 :' X -> Z

update 



*)


Proof. intros prg_len bit p A a (*G'*) E H H0 H1 H2 H3.
       (* inversion G'; subst. rename H4 into G'0. *)
       inversion H; inversion H0; subst. 
       inversion H5; inversion H8; subst; try easy.
       inversion E; subst.
       unfold switch_Predicate.
       simpl in *.
(*
       constructor.
       constructor.
       constructor. constructor.
       constructor. 2:{ constructor. }
                  simpl.
       *)
       inversion H3. inversion H13. inversion H17. subst. simpl in *.
       
       
       (* apply tensor_smpl_ground. *)
       induction H10.
       destruct a. simpl.
apply tensor_smpl_ground.

       simpl.

       induction H6.
       simpl. ubst.

       induction H10. subst.
       -  destruct a. destruct a0. simpl in *. 
     
     apply tensor_smpl_ground; simpl; auto. 
          2:{ inversion H9. simpl in *. symmetry. assumption. }
          inversion H3. inversion H13. inversion H17. subst.
       2:{ inversion H6; subst. simpl in H11. destruct l. discriminate. simpl in *. inversion H11.
           rewrite length_zero_iff_nil in H18. rewrite H18 in *. simpl in *. assumption. }
       (***  how to handle
 (c * c ^* )%C = C1 ***)

       (*** lemma: p 0 :' G [(C1, [nth bit l0 gI])] → G [(c, l)] -> WF_TType 1 (c, l)
-> smpl_prog p ->
(c * c ^* )%C = C1 ***)

       admit.

           - inversion H12. rewrite length_zero_iff_nil in H14. rewrite H14 in *. simpl in *. destruct a0; destruct a; simpl in *. 
             apply tensor_smpl_ground; auto; simpl in *.
             2:{ inversion H9; subst. simpl in *. easy. }
             2:{ destruct l0. inversion H6. discriminate. simpl in *. inversion H6. simpl in *. inversion H14. rewrite H14 in *. simpl in *. easy. }
                    (***  how to handle
 (c * c ^* )%C = C1 ***)
             admit.

           - (* inversion H12. symmetry in H14. rewrite length_zero_iff_nil in H14. rewrite H14 in *. simpl in *. destruct a0; destruct a; simpl in *. 
             apply tensor_smpl_ground; auto; simpl in *. 
           
             admit.
             2:{ inversion H9; subst. }
             2:{ destruct l0. inversion H6. discriminate. simpl in *. inversion H6. simpl in *. inversion H14.  rewrite H14 in *. simpl in *. easy. } *)
                    (***  how to handle
 (c * c ^* )%C = C1 ***)
             admit.
            

           - destruct a, a0. inversion H6. simpl in *. destruct l. discriminate. simpl in *.
             inversion H18. rewrite length_zero_iff_nil in H20. rewrite H20 in *. 
             (*** useless IH ***)
Admitted.


(* original
Lemma tensor_smpl : forall (prg_len bit : nat) (p : nat -> prog)
                           (A : Predicate prg_len) (a : Predicate 1),
    proper_length_APredicate a -> proper_length_APredicate A -> 
    smpl_prog p -> bit < prg_len ->
    (p 0) :' (nth_Predicate bit A) → a ->
    (p bit) :'  A → (switch_Predicate A a bit).
Proof. intros. 
       inversion H; inversion H0; subst. 
       inversion H5; inversion H8; subst; try easy. 
       destruct tt; destruct tt0; simpl. 
       inversion H6; inversion H10; subst.  
       apply tensor_smpl_ground; auto; simpl in *.
       do 2 (destruct l; try easy).
Qed.
*)

(*** Admitted ***)
Lemma tensor_ctrl : forall (prg_len ctrl targ : nat)   
                           (A : Predicate prg_len) (a b : Predicate 1),
  proper_length_APredicate A -> proper_length_APredicate a -> proper_length_APredicate b -> 
  ctrl < prg_len -> targ < prg_len -> ctrl <> targ -> 
  (CNOT' 0 1) :' (nth_Predicate ctrl A) .⊗ (nth_Predicate targ A) → a .⊗ b ->
  (CNOT' ctrl targ) :'  A → switch_Predicate (switch_Predicate A a ctrl) b targ.
Proof. intros. 
       inversion H; inversion H0; inversion H1; subst.
       inversion H7; inversion H10; inversion H13; subst; try easy. 
       (* destruct tt; destruct tt0; destruct tt1; simpl. *)
       inversion H8; inversion H14; inversion H16; subst.
       - 
       rewrite cMul_assoc.
       apply tensor_ctrl_ground; auto; simpl in *.
       rewrite H17, H19 in H5; simpl in H5.
       do 2 (destruct l0; destruct l1; try easy).
Qed.
*)



..
Lemma ToffoliTypes' : Toffoli' 0 1 2 :' (I .⊗ I .⊗ Z → 1/2 .· (I .⊗ I .⊗ Z .+ Z .⊗ I .⊗ Z .+ I .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Z)).
Proof. eapply SeqTypes with (B:=I .⊗ I .⊗ X). solve_ground_type.
  eapply SeqTypes with (B:=I .⊗ I .⊗ X). solve_ground_type.
  eapply SeqTypes with (B:=1/√2 .· (I .⊗ I .⊗ X .+ I .⊗ I .⊗ -Y)).
  eapply SeqTypes with (B:=I .⊗ I .⊗ -X). solve_ground_type.
  eapply SeqTypes with (B:=I .⊗ I .⊗ -Y). solve_ground_type.
  solve_ground_type.
  eapply SeqTypes with (B:=1/√2 .· (I .⊗ I .⊗ X .+ Z .⊗ I .⊗ -Y)). solve_ground_type.
  eapply SeqTypes with (B:=1/2 .· (I .⊗ I .⊗ X .+ I .⊗ I .⊗ Y .+ Z .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ X)). solve_ground_type.
  eapply SeqTypes with (B:=1/2 .· (I .⊗ I .⊗ X .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -Y .+ Z .⊗ I .⊗ X)). solve_ground_type.
  eapply SeqTypes with (B:=1/(2 * √2) .· (I .⊗ I .⊗ X .+ I .⊗ I .⊗ -Y .+ I .⊗ Z .⊗ X .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -X .+ Z .⊗ Z .⊗ -Y .+ Z .⊗ I .⊗ X .+ Z .⊗ I .⊗ -Y)).
  eapply SeqTypes with (B:=1/2 .· (I .⊗ I .⊗ -X .+ I .⊗ Z .⊗ -Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ I .⊗ -X)). solve_ground_type.
  eapply SeqTypes with (B:=1/2 .· (I .⊗ I .⊗ -Y .+ I .⊗ Z .⊗ X .+ Z .⊗ Z .⊗ -X .+ Z .⊗ I .⊗ -Y)). solve_ground_type.
  solve_ground_type.
  eapply SeqTypes with (B:=1/(2 * √2) .· (I .⊗ I .⊗ X .+ Z .⊗ I .⊗ -Y .+ I .⊗ Z .⊗ X .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -X .+ I .⊗ Z .⊗ -Y .+ Z .⊗ I .⊗ X .+ I .⊗ I .⊗ -Y)). solve_ground_type.
  eapply SeqTypes with (B:=1/(2 * √2) .· (I .⊗ I .⊗ X .+ Z .⊗ I .⊗ -Y .+ I .⊗ Z .⊗ X .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -X .+ I .⊗ Z .⊗ -Y .+ Z .⊗ I .⊗ X .+ I .⊗ I .⊗ -Y)). solve_ground_type.
  eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ X .+ I .⊗ I .⊗ Y .+ Z .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ X .+ I .⊗ Z .⊗ X .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ -X .+ Z .⊗ Z .⊗ -X .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ X .+ Z .⊗ I .⊗ X .+ Z .⊗ I .⊗ Y .+ I .⊗ I .⊗ -Y .+ I .⊗ I .⊗ X)). solve_ground_type.
  eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ I .⊗ Z .⊗ Z .+ I .⊗ Z .⊗ -Y .+ Z .⊗ Z .⊗ -Y .+ Z .⊗ Z .⊗ -Z .+ Z .⊗ Z .⊗ -Z .+ Z .⊗ Z .⊗ Y .+ I .⊗ Z .⊗ Y .+ I .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type.
  eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type.
  eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type. 
  eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)).
  eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type.
    eapply SeqTypes with (B:=1/4 .· (I .⊗ I .⊗ Z .+ I .⊗ I .⊗ -Y .+ Z .⊗ I .⊗ Y .+ Z .⊗ I .⊗ Z .+ Z .⊗ Z .⊗ Z .+ Z .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Y .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ -Z .+ I .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Y .+ Z .⊗ Z .⊗ Z .+ Z .⊗ I .⊗ Z .+ Z .⊗ I .⊗ -Y .+ I .⊗ I .⊗ Y .+ I .⊗ I .⊗ Z)). solve_ground_type.
  solve_ground_type.
  solve_ground_type.
Qed.











(*
(***************)
(* Arrow rules *)
(***************)


Lemma arrow_mul : forall {n} g (A A' B B' : Predicate n),
    proper_length_APredicate A -> proper_length_APredicate A' ->
    proper_length_APredicate B -> proper_length_APredicate B' ->
    g :' A → A' ->
    g :' B → B' ->
    g :' A .* B → A' .* B'.
Proof. intros; simpl in *.       
       inversion H3; inversion H4; inversion H7; inversion H11; 
       inversion H; inversion H0; inversion H1; inversion H2; subst. 
       apply Arrow_pht; apply PHST; auto with wfpt_db.
       destruct A; destruct A'; destruct B; destruct B'; try easy. 
       do 2 (rewrite translateP_mMult; try easy).
       rewrite fgt_conv.
       apply Heisenberg.arrow_mul; 
       try (apply unit_prog);
       try (apply unit_Predicate); try easy.
Qed. 
  

Lemma mul_simp : forall (a b : Pauli),
  @G 1 (gMul_Coef a b, [gMul_base a b]) = @G 1 (p_1, [a]) .* @G 1 (p_1, [b]). 
Proof. intros. 
       simpl. 
       destruct a; destruct b; try easy. 
Qed.


Lemma arrow_mul_1 : forall g (a a' b b' : Pauli),
    g :' @G 1 (p_1, [a]) → @G 1 (p_1, [a']) ->
    g :' @G 1 (p_1, [b]) → @G 1 (p_1, [b']) ->
    g :' @G 1 (gMul_Coef a b, [gMul_base a b]) → @G 1 (gMul_Coef a' b', [gMul_base a' b']).
Proof. intros. 
       do 2 rewrite mul_simp. 
       apply arrow_mul; try easy; apply pl_ap; try apply G_tpt. 
       all : apply WF_G; apply WF_tt; easy. 
Qed.



Lemma arrow_scale : forall {n} (p : prog) (A A' : Predicate n) (c : Coef),
  p :' A → A' -> p :' (scale c A) → (scale c A').
Proof. intros. 
       inversion H; inversion H2; subst.
       apply Cap_vt_conv in H4; apply Cap_vt_conv in H5.
       apply Arrow_pht; apply PHST; auto with wfpt_db. 
       all : try (apply Cap_vt_conv; rewrite Cap_vt_scale; easy).
       rewrite fgt_conv in *.
       do 2 (rewrite translateP_scale).
       apply Heisenberg.arrow_scale; try easy.
       apply translate_coef_nonzero.
Qed.


Lemma arrow_i : forall {n} (p : prog) (A A' : Predicate n),
  p :' A → A' ->
  p :' i A → i A'.
Proof. intros;
       apply arrow_scale;
       assumption.
Qed.


Lemma arrow_neg : forall {n} (p : prog) (A A' : Predicate n),
  p :' A → A' ->
  p :' -A → -A'.
Proof. intros;
       apply arrow_scale;
       assumption.
Qed.


(*
Hint Resolve HTypes ZTypes STypes TTypes CNOTTypes : base_types_db.
Hint Resolve cap_elim_l cap_elim_r : base_types_db.

Hint Resolve HTypes ZTypes STypes TTypes CNOTTypes : typing_db.
Hint Resolve cap_intro cap_elim_l cap_elim_r : typing_db.
Hint Resolve SeqTypes : typing_db.
*)


(* basically just eq_type_conv_output but with different order hypotheses *)
Lemma eq_arrow_r : forall {n} (g : prog) (A B B' : Predicate n),
    g :' A → B ->
    B = B' ->
    g :' A → B'.
Proof. intros. subst; easy. Qed.

*)







(* Tactics *)


Ltac is_I A :=
  match A with
  | I => idtac 
  end.

Ltac is_prog1 A :=
 match A with 
  | H' _ => idtac
  | S' _ => idtac
  | T' _ => idtac
  end.
              
Ltac is_prog2 A :=
  match A with
  | CNOT _ _ => idtac
  end.



Ltac expand_prog := match goal with
                    | |- ?p1 ;; ?p2 :' ?T => eapply SeqTypes
                    end.

(* Reduces to sequence of H, S and CNOT *)


Ltac  solve_smpl := apply tensor_smpl;
                    try (solve [eauto with base_types_db]); auto with wfpt_db.


Ltac  solve_ctrl := apply tensor_ctrl;
                    try (solve [eauto with base_types_db]); auto with wfpt_db.


Lemma CZTypes : CZ 0 1 :' (X .⊗ I → X .⊗ Z) ∩ (I .⊗ X → Z .⊗ X) ∩
                          (Z .⊗ I → Z .⊗ I) ∩ (I .⊗ Z → I .⊗ Z).
Proof. repeat apply cap_intro;
         repeat expand_prog.
       solve_smpl.
       solve_ctrl.
       eapply eq_arrow_r.
       solve_smpl.
       easy. 
       simpl.
       
       apply tensor_smpl; auto with wfpt_db.
       2 : solve [eauto with base_types_db].
       auto with wfpt_db.
       solve [eauto with base_types_db].
       eapply eq_arrow_r.
       apply tensor_smpl; auto with wfpt_db.
       2 : solve [eauto with base_types_db].
       auto with wfpt_db.
       easy. 
       apply tensor_smpl; auto with wfpt_db.
       2 : solve [eauto with base_types_db].
       auto with wfpt_db.

       


apply 
       




       rewrite (decompose_tensor) by (auto 50 with wfpt_db).
       eapply eq_arrow_r.
       apply arrow_mul.

       apply tensor_ctrl_base.
       solve [eauto with base_types_db].
       
Qed.



Ltac type_check_base :=
  repeat apply cap_intro;
  repeat expand_prog; (* will automatically unfold compound progs *)
  repeat match goal with
         | |- TPredicate ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_Predicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- proper_length_APredicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A .⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => rewrite decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => rewrite decompose_tensor_mult_r
         | |- CNOT' (s _) (s _) :' ?T => apply tensor_ctrl_inc
         | |- CNOT' 0 (s (s _)) :' ?T => apply tensor_ctrl_inc_r
         | |- CNOT' (s (s _)) 0 :' ?T => apply tensor_ctrl_inc_l
         | |- CNOT' 1 0 :' ?T       => apply tensor_ctrl_base_inv
         | |- CNOT' 0 1 :' ?T       => apply tensor_ctrl_base
         | |- CNOT' 1 0 :' ?T       => apply tensor_ctrl_comm
         | |- H' (s _) :' ?T     => apply tensor_smpl_inc
         | |- H' 0 :' ?T         => apply tensor_smpl_base
         | |- S' (s _) :' ?T     => apply tensor_smpl_inc
         | |- S' 0 :' ?T         => apply tensor_smpl_base
         | |- T' (s _) :' ?T     => apply tensor_smpl_inc
         | |- T' 0 :' ?T         => apply 4tensor_smpl_base
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             rewrite (decompose_tensor A B) by (auto 50 with wfpt_db)
         | |- ?g :' ?A → ?B      => tryif is_evar A then fail else
             solve [eauto with base_types_db]
         | |- ?A = ?B => tryif is_evar B then fail else
            (repeat rewrite mul_tensor_distapply tensor_smpl_ground.);
            (repeat normalize_mul);
            (repeat rewrite <- i_tensor_dist_l);
            (repeat rewrite <- neg_tensor_dist_l);
            autorewrite with mul_db;
            try reflexivity
         end; auto with wfpt_db; try easy.



Opaque progHasType.


Lemma CZTypes : CZ 0 1 :' (X .⊗ I → X .⊗ Z) ∩ (I .⊗ X → Z .⊗ X) ∩
                          (Z .⊗ I → Z .⊗ I) ∩ (I .⊗ Z → I .⊗ Z).
Proof. type_check_base.   
Qed.



Notation bell00 := ((H' 2);; (CNOT' 2 3)).

Notation encode := ((CZ 0 2);; (CNOT' 1 2)).

Notation decode := ((CNOT' 2 3);; (H' 2)).

Notation superdense := (bell00;; encode;; decode).



Lemma superdenseTypesQPL : superdense :' (Z .⊗ Z .⊗ Z .⊗ Z → I .⊗ I .⊗ Z .⊗ Z).
Proof. repeat expand_prog.
       type_check_base.
       type_check_base.
       type_check_base. 
       simpl. compute.
       rewrite mul_tensor_dist; auto with wfpt_db.
       type_check_base.
       type_check_base.
       type_check_base.
       type_check_base.
       type_check_base.
Qed.


       rewrite mul_tensor_dist; auto with wfpt_db.



match goal with
         | |- TPredicate ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_Predicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- proper_length_APredicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A .⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => rewrite decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => rewrite decompose_tensor_mult_r
         | |- CNOT (s _) (s _) :' ?T => apply tensor_ctrl_inc
         | |- CNOT 0 (s (s _)) :' ?T => apply tensor_ctrl_inc_r
         | |- CNOT (s (s _)) 0 :' ?T => apply tensor_ctrl_inc_l
         | |- CNOT 1 0 :' ?T       => apply tensor_ctrl_base_inv
         | |- CNOT 0 1 :' ?T       => apply tensor_ctrl_base
         | |- CNOT 1 0 :' ?T       => apply tensor_ctrl_comm
         | |- H' (s _) :' ?T     => apply tensor_smpl_inc
         | |- H' 0 :' ?T         => apply tensor_smpl_base
         | |- S' (s _) :' ?T     => apply tensor_smpl_inc
         | |- S' 0 :' ?T         => apply tensor_smpl_base
         | |- T' (s _) :' ?T     => apply tensor_smpl_inc
         | |- T' 0 :' ?T         => apply tensor_smpl_base
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             rewrite (decompose_tensor A B) by (auto 50 with wfpt_db)
         | |- ?g :' ?A → ?B      => tryif is_evar A then fail else
             solve [eauto with base_types_db]
         | |- ?A = ?B => tryif is_evar B then fail else
            (repeat rewrite mul_tensor_dist);
            (repeat normalize_mul);
            (repeat rewrite <- i_tensor_dist_l);
            (repeat rewrite <- neg_tensor_dist_l);
            autorewrite with mul_db;
            try reflexivity
         end.
6 : match goal with
         | |- TPredicate ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_Predicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- proper_length_APredicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A .⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => rewrite decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => rewrite decompose_tensor_mult_r
         | |- CNOT (s _) (s _) :' ?T => apply tensor_ctrl_inc
         | |- CNOT 0 (s (s _)) :' ?T => apply tensor_ctrl_inc_r
         | |- CNOT (s (s _)) 0 :' ?T => apply tensor_ctrl_inc_l
         | |- CNOT 1 0 :' ?T       => apply tensor_ctrl_base_inv
         | |- CNOT 0 1 :' ?T       => apply tensor_ctrl_base
         | |- CNOT 1 0 :' ?T       => apply tensor_ctrl_comm
         | |- H' (s _) :' ?T     => apply tensor_smpl_inc
         | |- H' 0 :' ?T         => apply tensor_smpl_base
         | |- S' (s _) :' ?T     => apply tensor_smpl_inc
         | |- S' 0 :' ?T         => apply tensor_smpl_base
         | |- T' (s _) :' ?T     => apply tensor_smpl_inc
         | |- T' 0 :' ?T         => apply tensor_smpl_base
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             rewrite (decompose_tensor A B) by (auto 50 with wfpt_db)
         | |- ?g :' ?A → ?B      => tryif is_evar A then fail else
             solve [eauto with base_types_db]
         | |- ?A = ?B => tryif is_evar B then fail else
            (repeat rewrite mul_tensor_dist);
            (repeat normalize_mul);
            (repeat rewrite <- i_tensor_dist_l);
            (repeat rewrite <- neg_tensor_dist_l);
            autorewrite with mul_db;
            try reflexivity
         end.


6 : match goal with
         | |- TPredicate ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_Predicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- proper_length_APredicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A .⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => rewrite decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => rewrite decompose_tensor_mult_r
         | |- CNOT (s _) (s _) :' ?T => apply tensor_ctrl_inc
         | |- CNOT 0 (s (s _)) :' ?T => apply tensor_ctrl_inc_r
         | |- CNOT (s (s _)) 0 :' ?T => apply tensor_ctrl_inc_l
         | |- CNOT 1 0 :' ?T       => apply tensor_ctrl_base_inv
         | |- CNOT 0 1 :' ?T       => apply tensor_ctrl_base
         | |- CNOT 1 0 :' ?T       => apply tensor_ctrl_comm
         | |- H' (s _) :' ?T     => apply tensor_smpl_inc
         | |- H' 0 :' ?T         => apply tensor_smpl_base
         | |- S' (s _) :' ?T     => apply tensor_smpl_inc
         | |- S' 0 :' ?T         => apply tensor_smpl_base
         | |- T' (s _) :' ?T     => apply tensor_smpl_inc
         | |- T' 0 :' ?T         => apply tensor_smpl_base
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             rewrite (decompose_tensor A B) by (auto 50 with wfpt_db)
         | |- ?g :' ?A → ?B      => tryif is_evar A then fail else
             solve [eauto with base_types_db]
         | |- ?A = ?B => tryif is_evar B then fail else
            (repeat rewrite mul_tensor_dist);
            (repeat normalize_mul);
            (repeat rewrite <- i_tensor_dist_l);
            (repeat rewrite <- neg_tensor_dist_l);
            autorewrite with mul_db;
            try reflexivity
         end.
       type_check_base. easy. 
       6 : {  rewrite mul_tensor_dist; auto with wfpt_db.
               rewrite mul_tensor_dist; auto with wfpt_db.
match goal with
         | |- TPredicate ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_Predicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- proper_length_APredicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A .⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => rewrite decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => rewrite decompose_tensor_mult_r
         | |- CNOT (s _) (s _) :' ?T => apply tensor_ctrl_inc
         | |- CNOT 0 (s (s _)) :' ?T => apply tensor_ctrl_inc_r
         | |- CNOT (s (s _)) 0 :' ?T => apply tensor_ctrl_inc_l
         | |- CNOT 1 0 :' ?T       => apply tensor_ctrl_base_inv
         | |- CNOT 0 1 :' ?T       => apply tensor_ctrl_base
         | |- CNOT 1 0 :' ?T       => apply tensor_ctrl_comm
         | |- H' (s _) :' ?T     => apply tensor_smpl_inc
         | |- H' 0 :' ?T         => apply tensor_smpl_base
         | |- S' (s _) :' ?T     => apply tensor_smpl_inc
         | |- S' 0 :' ?T         => apply tensor_smpl_base
         | |- T' (s _) :' ?T     => apply tensor_smpl_inc
         | |- T' 0 :' ?T         => apply tensor_smpl_base
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             rewrite (decompose_tensor A B) by (auto 50 with wfpt_db)
         | |- ?g :' ?A → ?B      => tryif is_evar A then fail else
             solve [eauto with base_types_db]
         | |- ?A = ?B => try easy
         end.

match goal with
         | |- TPredicate ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_Predicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- proper_length_APredicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A .⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => rewrite decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => idtac 4
                                           end.


rewrite decompose_tensor_mult_r.
             apply arrow_mul; type_check_base.
       3 : {


match goal with
         | |- TPredicate ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_Predicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- proper_length_APredicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A .⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => rewrite decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) -> _ => rewrite decompose_tensor_mult_r
         | |- CNOT (s _) (s _) :' ?T => apply tensor_ctrl_inc
         | |- CNOT 0 (s (s _)) :' ?T => apply tensor_ctrl_inc_r
         | |- CNOT (s (s _)) 0 :' ?T => apply tensor_ctrl_inc_l
         | |- CNOT 1 0 :' ?T       => apply tensor_ctrl_base_inv
         | |- CNOT 0 1 :' ?T       => apply tensor_ctrl_base
         | |- CNOT 1 0 :' ?T       => apply tensor_ctrl_comm
         | |- H' (s _) :' ?T     => apply tensor_smpl_inc
         | |- H' 0 :' ?T         => apply tensor_smpl_base
         | |- S' (s _) :' ?T     => apply tensor_smpl_inc
         | |- S' 0 :' ?T         => apply tensor_smpl_base
         | |- T' (s _) :' ?T     => apply tensor_smpl_inc
         | |- T' 0 :' ?T         => apply tensor_smpl_base
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             rewrite (decompose_tensor A B) by (auto 50 with wfpt_db)
         | |- ?g :' ?A → ?B      => tryif is_evar A then fail else
             solve [eauto with base_types_db]
         | |- ?A = ?B => try easy
         end.

match goal with
         | |- TPredicate ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_Predicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- proper_length_APredicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A .⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => rewrite decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) -> _ => rewrite decompose_tensor_mult_r
         | |- CNOT (s _) (s _) :' ?T => apply tensor_ctrl_inc
         | |- CNOT 0 (s (s _)) :' ?T => apply tensor_ctrl_inc_r
         | |- CNOT (s (s _)) 0 :' ?T => apply tensor_ctrl_inc_l
         | |- CNOT 1 0 :' ?T       => apply tensor_ctrl_base_inv
         | |- CNOT 0 1 :' ?T       => apply tensor_ctrl_base
         | |- CNOT 1 0 :' ?T       => apply tensor_ctrl_comm
         | |- H' (s _) :' ?T     => apply tensor_smpl_inc
         | |- H' 0 :' ?T         => apply tensor_smpl_base
         | |- S' (s _) :' ?T     => apply tensor_smpl_inc
         | |- S' 0 :' ?T         => apply tensor_smpl_base
         | |- T' (s _) :' ?T     => apply tensor_smpl_inc
         | |- T' 0 :' ?T         => apply tensor_smpl_base
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             rewrite (decompose_tensor A B) by (auto 50 with wfpt_db)
         | |- ?g :' ?A → ?B      => tryif is_evar A then fail else
             solve [eauto with base_types_db]
         | |- ?A = ?B => try easy
         end.

       3 : {

         match goal with
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             rewrite (decompose_tensor A B) by (auto 50 with wfpt_db)
         end; auto with wfpt_db; try easy.


       type_check_base'.       
       type_check_base'.
       type_check_base'.
       type_check_base'.
       type_check_base'.
       type_check_base'.
       kill_switch2.


       repeat (repeat (rewrite switch_Predicate_inc; auto with gt_db); 
         try rewrite switch_Predicate_base; try rewrite switch_Predicate_base_one;
           auto with gt_db).





       
       kill_

       
       type_check_base'.
       type_check_base'.
       


apply evSuper_ev; auto 50 with wfpt_db.
       unfold eq_Predicate; simpl.
       apply hd_inj; unfold uncurry; simpl. 
       apply TType_compare; auto; simpl.
       repeat (split; try lma').
       unfold translate






       

Check hd_inj.

       repeat (apply pl_ap_switch_Predicate'; auto 50 with wfpt_db).
       apply pl_ap_switch_Predicate'; auto 50 with wfpt_db.
       apply pl_ap_switch_Predicate'; auto with wfpt_db.


3 : {
         unfold eq_Predicate. simpl. 
         unfold translate. simpl. 
         unfold translateP


       type_check_base'.
       type_check_base'.
       type_check_base'.
       type_check_base'.      
       type_check_base'.
       type_check_base'.
       type_check_base'.

rewrite mul_tensor_dist; auto with wfpt_db.
             easy. 

type_check_base'.
       type_check_base'.
       3 : { rewrite mul_compat.
              try rewrite mul_tensor_dist;
              try easy; auto with wfpt_db.


pushA. 
       all : auto with gt_db.
       type_check_base'.
       type_check_base'.
       all : try pushA. 
       all : try pushA. 
       
        3 :  { pushA. 
               3 : pushA.
               all : auto with wfpt_db. }
        all : auto with gt_db.
        type_check_base'.
        3 : { pushA rewrite mul_compat;
             try rewrite mul_tensor_dist;
             try easy; auto with wfpt_db. 
              3 : { rewrite mul_compat;
                    try rewrite mul_tensor_dist;
                    try easy; auto with wfpt_db. 
                    3 : rewrite mul_compat;
                      try rewrite mul_tensor_dist;
                      try easy; auto with wfpt_db. 
                    all : auto with wfpt_db. }
              all : auto with wfpt_db. }
        all : auto with gt_db.
        type_check_base'.
        unfold eq_Predicate.
        simpl switch_Predicate'.
        unfold translate. simpl.
        apply hd_inj.
        crunch_matrix.
try easy.

       type_check_base'.

       2 : { simp_switch.


             rewrite nth_vswitch_hit. try easy; try lia; auto with gt_db).
       
  repeat (rewrite nth_vswitch_miss; try easy; try lia; auto with gt_db). 

match goal with
         | |- ?g :' nth_Predicate ?n (switch_Predicate' _ _ ?n) → _ => 
                rewrite nth_vswitch_hit; try easy; try lia; auto with gt_db 
         | |- ?g :' nth_Predicate ?n (switch_Predicate' _ _ ?m) → _ => 
                rewrite nth_vswitch_miss; try easy; try nia; auto with gt_db
end.
match goal with
         | |- ?g :' nth_Predicate ?n (switch_Predicate' _ _ ?n) → _ => 
                rewrite nth_vswitch_hit; try easy; try lia; auto with gt_db 
         | |- ?g :' nth_Predicate ?n (switch_Predicate' _ _ ?m) → _ => 
                rewrite nth_vswitch_miss; try easy; try nia; auto with gt_db
end.



nth_Predicate bit (switch_Predicate' A a bit) = a.


       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_Predicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A ⊗



       econstructor; reflexivity.


       rewrite nth_vswitch_miss; try easy; try nia; auto with gt_db.
       rewrite nth_vswitch_hit; [| nia | | |]. try easy; try nia; auto with gt_db. 
       


rewrite nth_vswitch_hit; try easy; try lia; auto with gt_db. 


       simpl nth_Predicate.
       apply arrow_mul_1.
       solve [eauto with base_types_db].  
       solve [eauto with base_types_db].
       eapply tensor_ctrl. 
       simpl nth_Predicate. 
       type_check_base'.

       2 : { simp_switch.


solve [eauto with base_types_db].  type_check_base'. }
       all : try type_check_base'
 try rewrite nth_vswitch_miss; try easy; try nia; auto with gt_db; 
         try rewrite nth_vswitch_hit; try easy; try nia; auto with gt_db. 
       2 : { type_check_base'. }
       type_check_base'.

       type_check_base'.


       3 : {  rewrite mul_tensor_dist. easy. 


       type_check_base.

       simpl nth_Predicate. 
       assert (H : G 1 (p_1, [gMul gX gZ]) = X .* Z). 
       { easy. }
       rewrite H.
       type_check_base.
       eapply tensor_ctrl.
       apply prog_decompose_tensor; auto with wfpt_db.
       eapply eq_arrow_r.
       apply arrow_mul; auto with wfpt_db; try solve [eauto with base_types_db].
       5 : { simpl nth_Predicate.

       type_check_base.

repeat match goal with
         | |- TPredicate ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_Predicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A ⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g 0 1 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI2)); 
             solve [eauto with base_types_db]
         | |- ?g 0 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI)); 
             solve [eauto with base_types_db]
         | |- ?g (S ?n) ?m :' ?T => eapply tensor_ctrl
         | |- H' (S ?n) :' ?T => eapply tensor_smpl; auto with wfpt_db
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => apply prog_decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => apply prog_decompose_tensor_mult_r
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             apply prog_decompose_tensor
         | |- ?A ≡ ?B => try easy
         end; auto with wfpt_db.





       match goal with
         | |- TPredicate _       => auto 50 with svt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A ⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r 
         | |- ?g 0 1 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI2)); 
             solve [eauto with base_types_db]
         | |- ?g 0 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI)); 
             solve [eauto with base_types_db]
         | |- ?g (S ?n) ?m :' ?T => eapply tensor_ctrl
         | |- H' (S ?n) :' ?T => eapply tensor_smpl; auto with wfpt_db
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => apply prog_decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => apply prog_decompose_tensor_mult_r
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             apply prog_decompose_tensor
         | |- ?A ≡ ?B => try easy
         end.
match goal with
         | |- TPredicate _       => auto 50 with svt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A ⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g 0 1 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI2)); 
             solve [eauto with base_types_db]
         | |- ?g 0 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI)); 
             solve [eauto with base_types_db]
         | |- ?g (S ?n) ?m :' ?T => eapply tensor_ctrl
         | |- H' (S ?n) :' ?T => eapply tensor_smpl; auto with wfpt_db
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => apply prog_decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => apply prog_decompose_tensor_mult_r
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             apply prog_decompose_tensor
         | |- ?A ≡ ?B => try easy
         end.



match goal with
         | |- TPredicate _       => auto 50 with svt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A ⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g 0 1 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI2)); 
             solve [eauto with base_types_db]
         | |- ?g 0 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI)); 
             solve [eauto with base_types_db]
         | |- ?g (S ?n) ?m :' ?T => eapply tensor_ctrl
         | |- H' (S ?n) :' ?T => eapply tensor_smpl; auto with wfpt_db
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => apply prog_decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => apply prog_decompose_tensor_mult_r
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             apply prog_decompose_tensor
         | |- ?A ≡ ?B => try easy
         end; auto with wfpt_db.
 

match goal with
         | |- TPredicate ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_Predicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A ⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g 0 1 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI2)); 
             solve [eauto with base_types_db]
         | |- ?g 0 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI)); 
             solve [eauto with base_types_db]
         | |- ?g (S ?n) ?m :' ?T => eapply tensor_ctrl
         | |- H' (S ?n) :' ?T => eapply tensor_smpl; auto with wfpt_db
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => apply prog_decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => apply prog_decompose_tensor_mult_r
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             apply prog_decompose_tensor
         | |- ?A ≡ ?B => try easy
         end;

try match goal with
         | |- TPredicate ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_Predicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A ⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g 0 1 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI2)); 
             solve [eauto with base_types_db]
         | |- ?g 0 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI)); 
             solve [eauto with base_types_db]
         | |- ?g (S ?n) ?m :' ?T => eapply tensor_ctrl
         | |- H' (S ?n) :' ?T => eapply tensor_smpl; auto with wfpt_db
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => apply prog_decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => apply prog_decompose_tensor_mult_r
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             apply prog_decompose_tensor
         | |- ?A ≡ ?B => try easy
         end; 

match goal with
         | |- TPredicate ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_Predicate ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A ⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g 0 1 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI2)); 
             solve [eauto with base_types_db]
         | |- ?g 0 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI)); 
             solve [eauto with base_types_db]
         | |- ?g (S ?n) ?m :' ?T => eapply tensor_ctrl
         | |- H' (S ?n) :' ?T => eapply tensor_smpl; auto with wfpt_db
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => apply prog_decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => apply prog_decompose_tensor_mult_r
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             apply prog_decompose_tensor
         | |- ?A ≡ ?B => try easy
         end.  easy.
 

match goal with
         | |- TPredicate _       => tryif is_evar A then fail else auto 50 with svt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A ⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g 0 1 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI2)); 
             solve [eauto with base_types_db]
         | |- ?g 0 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI)); 
             solve [eauto with base_types_db]
         | |- ?g (S ?n) ?m :' ?T => eapply tensor_ctrl
         | |- H' (S ?n) :' ?T => eapply tensor_smpl; auto with wfpt_db
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => apply prog_decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => apply prog_decompose_tensor_mult_r
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             apply prog_decompose_tensor
         | |- ?A ≡ ?B => try easy
         end.

        type_check_base.


Lemma superdenseTypesQPL' : superdense :' (Z .⊗ Z .⊗ Z .⊗ Z → I .⊗ I .⊗ Z .⊗ Z).
Proof. repeat expand_prog.
       type_check_base'.
       
       eapply tensor_ctrl'; try (apply prog_decompose_tensor); try easy;
         try (eapply eq_arrow_r; apply arrow_mul; try (solve [eauto with base_types_db])).
       
       3: { eapply eq_arrow_r. apply arrow_mul; try (solve [eauto with base_types_db]);
                                 try (auto with wfpt_db).
         rewrite mul_tensor_dist; 
         auto with wfpt_db; easy. }
         auto with gt_db.
       auto with gt_db.
         
         eapply tensor_smpl.
         simpl. easy.
         auto with wfpt_db.
         rewrite nth_vswitch_miss; try easy; try nia; auto with gt_db. 
         rewrite nth_vswitch_hit; try easy; try nia; auto with gt_db. 
         eapply eq_arrow_r.
         apply arrow_mul; try (solve [eauto with base_types_db]); try (auto with wfpt_db).
         easy. 
         solve [eauto with base_types_db].
         9: { solve [eauto with base_types_db]. }

Lemma superdenseTypesQPL' : superdense :' (Z .⊗ Z .⊗ Z .⊗ Z → I .⊗ I .⊗ Z .⊗ Z).
Proof. repeat expand_prog.
       type_check_base'.
       
       eapply tensor_ctrl'; try (apply prog_decompose_tensor); try easy;
         try (eapply eq_arrow_r; apply arrow_mul; try (solve [eauto with base_types_db])).
       
       3: { eapply eq_arrow_r. apply arrow_mul; try (solve [eauto with base_types_db]);
                                 try (auto with wfpt_db).
         rewrite mul_tensor_dist; 
         auto with wfpt_db; easy. }
         auto with gt_db.
       auto with gt_db.
         
         eapply tensor_smpl.
         simpl. easy.
         auto with wfpt_db.
         rewrite nth_vswitch_miss; try easy; try nia; auto with gt_db. 
         rewrite nth_vswitch_hit; try easy; try nia; auto with gt_db. 
         eapply eq_arrow_r.
         apply arrow_mul; try (solve [eauto with base_types_db]); try (auto with wfpt_db).
         easy. 
         solve [eauto with base_types_db].
         9: { solve [eauto with base_types_db]. }


       
  repeat expand_prog.
  repeat match goal with
         | |- TPredicate _       => auto 50 with svt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A ⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r 
         | |- ?g 0 1 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI2)); 
             solve [eauto with base_types_db]
         | |- ?g 0 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI)); 
             solve [eauto with base_types_db]
         | |- ?g (S ?n) ?m :' ?T => eapply (tensor_ctrl (S n) m _ _ _) 
         | |- ?g (S ?n) :' ?T => eapply (tensor_smpl (S n) _ _ _)
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => apply prog_decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => apply prog_decompose_tensor_mult_r
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             apply prog_decompose_tensor
         | |- ?A ≡ ?B => try easy
         end.
  eapply (tensor_ctrl 2 3 _ _ _). 
 match goal with
         | |- TPredicate _       => auto 50 with svt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A ⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r 
         | |- ?g 0 1 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI2)); 
             solve [eauto with base_types_db]
         | |- ?g 0 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI)); 
             solve [eauto with base_types_db]
         | |- ?g (S ?n) ?m :' ?T => eapply (tensor_ctrl (S n) m _ _ _) 
         | |- ?g (S ?n) :' ?T => idtac 4
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => apply prog_decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => apply prog_decompose_tensor_mult_r
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             apply prog_decompose_tensor
         | |- ?A ≡ ?B => try easy
         end.








repeat apply cap_intro;
  repeat expand_prog; (* will automatically unfold compound progs *)
  repeat match goal with
         | |- TPredicate _       => auto 50 with svt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A ⊗ ?B]  => progress (autorewrite with tensor_db)
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r 
         | |- ?g 0 1 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI2)); 
             solve [eauto with base_types_db]
         | |- ?g 0 :' ?A → ?B => tryif is_evar A then fail else
             (try (eapply TypesI)); 
             solve [eauto with base_types_db]
         | |- ?g (S ?n) ?m :' ?T => eapply (tensor_ctrl (S n) m _ _ _) 
         | |- ?g (S ?n) :' ?T => eapply (tensor_smpl (S n) _ _ _)
         | |- ?g :' ?A .* ?B → _ => apply arrow_mul
         | |- ?g :' (?A .* ?B) .⊗ I → _ => apply prog_decompose_tensor_mult_l
         | |- ?g :' I .⊗ (?A .* ?B) → _ => apply prog_decompose_tensor_mult_r
         | |- ?g :' ?A .⊗ ?B → _  => tryif (is_I A + is_I B) then fail else
             apply prog_decompose_tensor
         | |- ?A ≡ ?B => try easy
         end.


repeat match goal with
              | |- ?p1 ;; ?p2 :' ?T => eapply SeqTypes
              end.
       eapply (tensor_smpl 2 _ _ _).
       solve [eauto with base_types_db]. 
       eapply (tensor_ctrl 4 2 3 _ _ _).
       simpl nth_Predicate.
       apply prog_decompose_tensor; try easy.
       eapply eq_arrow_r.
       apply arrow_mul; 
         try (solve [eauto with base_types_db]);
         try easy.
       rewrite mul_tensor_dist; try easy.
       eapply (tensor_ctrl 2 _ _ _).
       simpl. 
       solve [eauto with base_types_db]. 



reflexivity. 
try easy.
       5: { solve [eauto with base_types_db]. }
       5: { solve [eauto with base_types_db]. }
       



    auto with univ_db.
       auto with univ_db.
       nia. 
       easy. 
       eapply (tensor_ctrl 4 2 3 _ _ _).
       rewrite CX_is_CNOT.
       rewrite decompose_tensor.
       eapply eq_arrow_r.
       apply arrow_mul.
       auto with sing_db.
       auto with sing_db.
       auto with unit_db.
       auto with univ_db.
       4: { solve [eauto with base_types_db]. }
       auto with univ_db.
       auto with univ_db.



emma prog_decompose_tensor : forall (p : prog) (A B : Predicate 1) (T : Predicate 2),
  TPredicate A -> WF_Predicate A ->
  TPredicate B -> WF_Predicate B ->
  p :' ((A .⊗ I) .* (I .⊗ B)) → T -> p :' (A .⊗ B) → T.
Proof. intros. 
       apply (eq_type_conv_input p ((A .⊗ I) .* (I .⊗ B)) (A .⊗ B) T); try easy.
       rewrite <- decompose_tensor; easy.
Qed.


       
       rewrite decompose_tensor.
       eapply eq_arrow_r.
       apply arrow_mul.
       auto with sing_db.
       auto with sing_db.
       auto with unit_db.
       auto with univ_db.



       assert (H : G 1 (p_1, [gX]) = X). { easy. }
       assert (H' : G 1 (p_1, [gZ]) = Z). { easy. }
       rewrite H, H'.
                                         

solve [eauto with base_types_db]. }
       auto with univ_db.
       auto with univ_db.
       2: { solve [eauto with base_types_db]. }
       auto with univ_db.
       rewrite mul_tensor_dist.
       reflexivity.
       auto with sing_db.
       auto with sing_db.
       auto with sing_db.
       auto with sing_db.
       eapply (tensor_ctrl 4 0 2 _ _ _).
       rewrite decompose_tensor.
       eapply eq_arrow_r.


Ltac is_I A :=
  match A with


Definition vecTypeT (len : nat) := (list (vecType 2)).

| tensor : GType -> GType -> GType
| cap : GType -> GType -> GType
| arrow : GType -> GType -> GType. 

Notation "- T" := (neg T).
Infix ".*" := mul (at level 40, left associativity).
Infix ".⊗" := tensor (at level 51, right associativity).
Infix "→" := arrow (at level 60, no associativity).
Infix "∩" := cap (at level 60, no associativity).

Notation Y := (i (X .* Z)).


Fixpoint singGType (g : GType) := 
  match g with
  | I => 
  | X => 
  | Z => 
  | i g => 
  | neg g => 
  | mul g1 g2 => 
  | tensor g1 g2 =>
  | 



Fixpoint translate (g : GType) :=
  match g with
  | gI => I''
  | gX => X''
  | gZ => Z''
  | gmul g1 g2 => mulT' (translate g1) (translate g2)
  | gtensor g1 g2 => tensorT (translate g1) (translate g2)
  | gi g => scaleT Ci (translate g)
  | gneg g => scaleT (Copp C1) (translate g)
  | _ => I''
  end. 



Parameter GType : Type.
Parameter I : GType.
Parameter X : GType.
Parameter Z : GType.
Parameter i : GType -> GType.
Parameter neg : GType -> GType.
Parameter mul : GType -> GType -> GType.
Parameter tensor : GType -> GType -> GType.
Parameter cap : GType -> GType -> GType.
Parameter arrow : GType -> GType -> GType.


(*
Parameter toGType : Matrix 2 2 -> GType.
Axiom ItoG : toGType (Matrix.I 2) = I.
Axiom XtoG : toGType σx  = X.
Axiom ZtoG : toGType σz  = Z.
*)


Notation "- T" := (neg T).
Infix "*" := mul (at level 40, left associativity).
Infix "⊗" := tensor (at level 51, right associativity).
Infix "→" := arrow (at level 60, no associativity).
Infix "∩" := cap (at level 60, no associativity).

Notation Y := (i (X * Z)).

(* Singleton Types *)
(* Could probably safely make this inductive. Can't do inversion on GTypes anyhow. *)

Parameter Singleton : GType -> Prop.
Axiom SI: Singleton I.
Axiom SX : Singleton X.
Axiom SZ : Singleton Z.
Axiom S_neg : forall A, Singleton A -> Singleton (neg A).
Axiom S_i : forall A, Singleton A -> Singleton (i A).
Axiom S_mul : forall A B, Singleton A -> Singleton B -> Singleton (A * B).

Hint Resolve SI SX SZ S_neg S_i S_mul : sing_db.

Lemma SY : Singleton Y.
Proof. auto with sing_db. Qed.

(* Multiplication laws *)

Axiom mul_assoc : forall A B C, A * (B * C) = A * B * C.
Axiom mul_I_l : forall A, I * A = A.
Axiom mul_I_r : forall A, A * I = A.
Axiom Xsqr : X * X = I.
Axiom Zsqr : Z * Z = I.
Axiom ZmulX : Z * X = - (X * Z).

Axiom neg_inv : forall A, - - A = A.
Axiom neg_dist_l : forall A B, -A * B = - (A * B).
Axiom neg_dist_r : forall A B, A * -B = - (A * B).

Axiom i_sqr : forall A, i (i A) = -A.
Axiom i_dist_l : forall A B, i A * B = i (A * B).
Axiom i_dist_r : forall A B, A * i B = i (A * B).

Axiom i_neg_comm : forall A, i (-A) = -i A.

Hint Rewrite mul_I_l mul_I_r Xsqr Zsqr ZmulX neg_inv neg_dist_l neg_dist_r i_sqr i_dist_l i_dist_r i_neg_comm : mul_db.

(** ** Tensor Laws *)

Axiom tensor_assoc : forall A B C, A ⊗ (B ⊗ C) = (A ⊗ B) ⊗ C.  

Axiom neg_tensor_dist_l : forall A B, -A ⊗ B = - (A ⊗ B).
Axiom neg_tensor_dist_r : forall A B, A ⊗ -B = - (A ⊗ B).
Axiom i_tensor_dist_l : forall A B, i A ⊗ B = i (A ⊗ B).
Axiom i_tensor_dist_r : forall A B, A ⊗ i B = i (A ⊗ B).

(** ** Multiplication & Tensor Laws *)

(* Appropriate restriction is that size A = size C and size B = size D,
   but axiomatization doesn't allow for that calculation. *)
(* This should be generalizable to the other, assuming we're multiplying
   valid types. *)
Axiom mul_tensor_dist : forall A B C D,
    Singleton A ->
    Singleton C ->
    (A ⊗ B) * (C ⊗ D) = (A * C) ⊗ (B * D).

Lemma decompose_tensor : forall A B,
    Singleton A ->
    Singleton B ->
    A ⊗ B = (A ⊗ I) * (I ⊗ B).
Proof.
  intros.
  rewrite mul_tensor_dist; auto with sing_db.
  rewrite mul_I_l, mul_I_r. 
  easy.
Qed.

Lemma decompose_tensor_mult_l : forall A B,
    Singleton A ->
    Singleton B ->
    (A * B) ⊗ I = (A ⊗ I) * (B ⊗ I).
Proof.
  intros.
  rewrite mul_tensor_dist; auto with sing_db.
  rewrite mul_I_l.
  easy.
Qed.

Lemma decompose_tensor_mult_r : forall A B,
    I ⊗ (A * B) = (I ⊗ A) * (I ⊗ B).
Proof.
  intros.
  rewrite mul_tensor_dist; auto with sing_db.
  rewrite mul_I_l.
  easy.
Qed.
  
Hint Rewrite neg_tensor_dist_l neg_tensor_dist_r i_tensor_dist_l i_tensor_dist_r : tensor_db.

(** ** Intersection Laws *)

Axiom cap_idem : forall A, A ∩ A = A.

Axiom cap_comm : forall A B, A ∩ B = B ∩ A.

Axiom cap_assoc : forall A B C, A ∩ (B ∩ C) = (A ∩ B) ∩ C.

Axiom cap_I_l : forall A,
  Singleton A ->
  I ∩ A = A.

Lemma cap_I_r : forall A,
  Singleton A ->
  A ∩ I = A.
Proof. intros; rewrite cap_comm, cap_I_l; easy. Qed.


(* Note: I haven't proven that this works or terminates.
   An anticommutative monoidal solver would be ideal here. *)
Ltac normalize_mul :=
  repeat match goal with
  | |- context[(?A ⊗ ?B) ⊗ ?C] => rewrite <- (tensor_assoc A B C)
  end;
  repeat (rewrite mul_tensor_dist by auto with sing_db);
  repeat rewrite mul_assoc;
  repeat (
      try rewrite <- (mul_assoc X Z _);
      autorewrite with mul_db tensor_db;
      try rewrite mul_assoc ).



Lemma Ysqr : Y * Y = I. Proof. 
autorewrite with mul_db.
try rewrite mul_assoc.
try rewrite <- (mul_assoc X Z _).
autorewrite with mul_db.
try rewrite mul_assoc.
try rewrite <- (mul_assoc X Z _).
autorewrite with mul_db.

  reflexivity. Qed.
Lemma XmulZ : X * Z = - Z * X. Proof. normalize_mul. reflexivity. Qed.
Lemma XmulY : X * Y = i Z. Proof. normalize_mul. reflexivity. Qed.
Lemma YmulX : Y * X = -i Z. Proof. normalize_mul. reflexivity. Qed.
Lemma ZmulY : Z * Y = -i X. Proof. normalize_mul. reflexivity. Qed.
Lemma YmulZ : Y * Z = i X. Proof. normalize_mul. reflexivity. Qed.



Fixpoint zipWith {X : Type} (f : X -> X -> X) (As Bs : list X) : list X :=
  match As with 
  | [] => Bs
  | a :: As' => 
    match Bs with
    | [] => As
    | b :: Bs' => f a b :: zipWith f As' Bs'
    end
  end.  


Lemma zipWith_len_pres : forall {X : Type} (f : X -> X -> X) (n : nat) 
                                (As : list X) (Bs : list X),
  length As = n -> length Bs = n -> length (zipWith f As Bs) = n.
Proof. induction n as [| n'].
       - intros. 
         destruct As; destruct Bs; easy. 
       - intros. 
         destruct As; destruct Bs; try easy.
         simpl in *.
         apply Nat.succ_inj in H; apply Nat.succ_inj in H0.
         rewrite IHn'; easy. 
Qed.


Lemma zipWith_app_product : forall {X : Type} (f : X -> X -> X) (n : nat) 
                               (l0s l2s : list X) (l1s l3s : list X),
  length l0s = n -> length l1s = n -> 
  (zipWith f l0s l1s) ++ (zipWith f l2s l3s) = zipWith f (l0s ++ l2s) (l1s ++ l3s).
Proof. induction n as [| n'].
       - intros. destruct l0s; destruct l1s; easy. 
       - intros. destruct l0s; destruct l1s; try easy.
         unfold zipWith in *.
         simpl in *. 
         rewrite <- IHn'; try nia. 
         reflexivity. 
Qed.



