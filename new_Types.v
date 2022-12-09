Require Import Psatz.
Require Import Reals.

Require Export Complex.
Require Export Matrix.
Require Export Quantum.
Require Export Eigenvectors.
(* Require Export Heisenberg. *)
Require Import Setoid.
Require Import Permutation.

Require Export new_Helper.



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

Hint Resolve WF_Matrix_Pauli WF_Matrix_Big_Pauli : wf_db.
Hint Resolve WF_Unitary_Pauli : unit_db.


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

Definition translate {n} (A : TType n) : Square (2^n) := 
  (fst A) .* ⨂ (map translate_P (snd A)).




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
  | h :: t => map (fun x : TType n => gTensorT x h) a ++ gTensorA a t
  end.

Fixpoint gMulA {n : nat} (a b : AType n) {struct a} : AType n :=
  match a with
  | [] => []
  | h :: t => map (fun x : TType n => gMulT h x) b ++ gMulA t b
  end.

Fixpoint gMulA' {n : nat} (a b : AType n) {struct b} : AType n :=
  match b with
  | [] => []
  | h :: t => map (fun x : TType n => gMulT x h) a ++ gMulA a t
  end.

Definition gScaleA {n : nat} (c : Coef) (a : AType n) :=
  map (fun a' => gScaleT c a') a .

Definition gAddA {n : nat} (a b : AType n) : AType n :=  a ++ b.

Definition translateA {n} (a : AType n) : Square (2^n) :=
  fold_left Mplus (map translate a) Zero.


Inductive PType (n : nat) : Type :=
| G : AType n -> PType n
| Cap : PType n -> PType n -> PType n
| Cup : PType n -> PType n -> PType n
| Err : PType n.

Arguments G {n}.
Arguments Cap {n}.
Arguments Cup {n}.
Arguments Err {n}.


(* you cannot multiply cap or cup types 
   so any of these options returns Err *)
Definition mul {n} (A B : PType n) : PType n :=
  match A with
  | G a =>
    match B with
    | G b => G (gMulA a b)
    | _ => Err
    end
  | _ => Err
  end.

Definition add {n} (A B : PType n) : PType n :=
  match A with
  | G a =>
    match B with
    | G b => G (gAddA a b)
    | _ => Err
    end
  | _ => Err
  end.

Definition tensor {n m} (A : PType n) (B : PType m): PType (n + m) :=
  match A with
  | G a =>
      match B with
      | G b => G (gTensorA a b)
      | _ => Err
      end
  | _ => Err
  end.

Definition scale {n} (c : Coef) (A : PType n) : PType n :=
  match A with
  | G a => G (gScaleA c a)
  | _ => Err
  end.

Lemma gScaleT_1 : forall n (A : TType n), gScaleT C1 A = A.
Proof. intros n A. destruct A. simpl. rewrite Cmult_1_l. reflexivity. Qed.

Lemma gScaleA_1 : forall n (A : AType n), gScaleA C1 A = A.
Proof. intros n A. induction A; simpl; try easy. rewrite gScaleT_1. rewrite IHA. reflexivity. Qed. 


Hint Rewrite gScaleT_1 gScaleA_1 : typing_db.


Definition i {n} (A : PType n) := scale Ci A.
Notation "- A" := (scale (Copp C1) A)  (at level 35, right associativity).

Infix ".⊗" := tensor (at level 39, left associativity).
Infix ".*" := mul (at level 40, left associativity).
Infix ".·" := scale (at level 43, left associativity).
Infix ".+" := add (at level 50, left associativity).

Notation "A ∩ B" := (Cap A B) (at level 60, no associativity).
Notation "A ⊍ B" := (Cup A B) (at level 60, no associativity).



(****************************)
(* Semantical Definition *)
(****************************)

(*** direct definition ***)
Inductive PType_trans (n : nat) : Type :=
| G_t : Square n -> PType_trans n
| Cap_t : PType_trans n -> PType_trans n -> PType_trans n
| Cup_t : PType_trans n -> PType_trans n -> PType_trans n
| Err_t : PType_trans n.

Arguments G_t {n}.
Arguments Cap_t {n}.
Arguments Cup_t {n}.
Arguments Err_t {n}.

(* you cannot multiply cap or cup types 
   so any of these options returns Err *)
Definition mul_trans {n} (A B : PType_trans n) : PType_trans n :=
  match A with
  | G_t a =>
    match B with
    | G_t b => G_t (a × b)
    | _ => Err_t
    end
  | _ => Err_t
  end.

Definition add_trans {n} (A B : PType_trans n) : PType_trans n :=
  match A with
  | G_t a =>
    match B with
    | G_t b => G_t (a .+ b)%M
    | _ => Err_t
    end
  | _ => Err_t
  end.

Definition tensor_trans {n m} (A : PType_trans n) (B : PType_trans m): PType_trans (n * m) :=
  match A with
  | G_t a =>
      match B with
      | G_t b => G_t (a ⊗ b)
      | _ => Err_t
      end
  | _ => Err_t
  end.

Definition scale_trans {n} (c : Coef) (A : PType_trans n) : PType_trans n :=
  match A with
  | G_t a => G_t (c .* a)%M
  | _ => Err_t
  end.


Definition i' {n} (A : PType_trans n) := scale_trans Ci A.
Notation "-' A" := (scale_trans (Copp C1) A) (at level 35, right associativity).

Infix "⊗'" := tensor_trans (at level 39, left associativity).
Infix "*'" := mul_trans (at level 40, left associativity).
Infix "·'" := scale_trans (at level 43, left associativity).
Infix "+'" := add_trans (at level 50, left associativity).

Notation "A ∩' B" := (Cap_t A B) (at level 60, no associativity).
Notation "A ⊍' B" := (Cup_t A B) (at level 60, no associativity).

Fixpoint translateP {n} (A : PType n) :=
  match A with
  | G a => G_t (translateA a)
  | Cap a b => Cap_t (translateP a) (translateP b)
  | Cup a b => Cup_t (translateP a) (translateP b)
  | Err => Err_t
  end.

Fixpoint uni_PType_trans {n} (A : PType_trans n) :=
  match A with
  | G_t a => WF_Unitary a
  | Cap_t a b => (uni_PType_trans a) /\ (uni_PType_trans b)
  | Cup_t a b => (uni_PType_trans a) /\ (uni_PType_trans b)
  | Err_t => False
  end.


(*****************************************)
(* Defining Eigenvector Semantics *)  (** may want to move this after defining consequence rule and implication rules **)
(*****************************************)

Definition vecSatisfies {n} (v : Vector n) (U : Square n) : Prop :=
  WF_Matrix v /\ exists c, Eigenpair U (v, c).

(*** direct definition ***)
(*
Fixpoint vecSatisfiesP {n} (v : Vector n) (P : PType_trans n) : Prop :=
  match P with
  | G_t U => vecSatisfies v U
  | Cap_t a b => (vecSatisfiesP v a) /\ (vecSatisfiesP v b)
  | Cup_t a b => (vecSatisfiesP v a) \/ (vecSatisfiesP v b)
  | Err_t => False
  end. *)


Fixpoint vecSatisfiesP {n} (v : Vector n) (P : PType n) : Prop :=
  match P with
  | G A => vecSatisfies v (translateA A)
  | Cap a b => (vecSatisfiesP v a) /\ (vecSatisfiesP v b)
  | Cup a b => (vecSatisfiesP v a) \/ (vecSatisfiesP v b)
  | Err => False
  end. 

P_S1
exists v1 v2,
v = v1 ⊗ v2 /\ P1 v1

P_S2 
exists v1 v2,
v = v1 ⊗ v2 /\ P2 v2


                 
Definition vecPair (prg_len : nat) := (Vector (2^prg_len) * C)%type.
  
(** 

Definition pairHasType {n : nat} (p : Vector n * C) (ts: vecType n) : Prop := 
  forall (A : Square n), In A ts -> Eigenpair A p.


Definition gateHasPair {n : nat} (U : Square n) (p : vecType n * vecType n) : Prop :=
  forall (A B : Square n), In A (fst p) -> In B (snd p) -> U × A = B × U.

(* alternate, less powerful but more accurate definition *)
(* {{A}} U {{B}} -> U sends eigs of A to eigs of B *)
Definition gateHasPair' {n : nat} (U : Square n) (p : vecType n * vecType n) : Prop :=
  forall v c, pairHasType (v, c) (fst p) -> pairHasType (U × v, c) (snd p). 

Lemma ghp_implies_ghp' : forall {n} (U : Square n) (g : vecType n * vecType n),
  fst g <> [] -> gateHasPair U g -> gateHasPair' U g.
Proof. intros. 
       unfold gateHasPair in H0. 
       unfold gateHasPair'. intros v c Ha B Hb.   
       unfold Eigenpair; simpl.
       destruct (fst g) as [| A].
       - easy.
       - assert (H1 : U × A = B × U).
       { apply H0. left. easy. apply Hb. }
       rewrite <- Mmult_assoc.
       rewrite <- H1.
       rewrite Mmult_assoc.
       unfold pairHasType in Ha. 
       unfold Eigenpair in Ha. simpl in Ha.
       assert (H'' : A × v = c .* v).
       { apply Ha. left. easy. }
       rewrite H''.
       rewrite Mscale_mult_dist_r.
       reflexivity.
Qed.


Lemma ghp'_implies_ghp : forall {n} (U : Square n) (g : vecType n * vecType n),
  WF_Unitary U -> Singleton (fst g) -> (uni_vecType (fst g) /\ uni_vecType (snd g)) ->
  gateHasPair' U g -> gateHasPair U g.
Proof. intros n U g H H0 [Hf Hs] H1. 
       apply singleton_simplify in H0; destruct H0.
       unfold gateHasPair' in H1. 
       unfold gateHasPair. intros A B HA HB.  
       unfold uni_vecType in *.
       assert (H': eq_eigs A (U† × B × U)). 
       { intros p H2 H3. destruct p.
         apply eig_unit_conv; try easy.  
         unfold pairHasType in H1.
         rewrite H0 in *.
         apply (H1 m c). 
         unfold pairHasType.
         intros. 
         apply in_simplify in H4. 
         apply in_simplify in HA. 
         rewrite H4, <- HA.
         apply H3.
         apply HB. }
       apply eq_eigs_implies_eq_unit in H'.
       rewrite H'.
       do 2 (rewrite <- Mmult_assoc).
       destruct H as [Hwf Hu].
       apply Minv_flip in Hu; auto with wf_db. 
       rewrite Hu, Mmult_1_l.
       reflexivity.
       destruct (Hs B) as [Haa _]; auto. 
       apply Hf; auto.
       apply Mmult_unitary; auto. 
       apply Mmult_unitary; auto.
       apply transpose_unitary; auto.  
Qed.


Definition gateApp {n : nat} (U A : Square n) : Square n :=
  U × A × U†.

Notation "{{ A }} U {{ B }}" := (gateHasPair' U (A, B)) (at level 61, no associativity) : heisenberg_scope.
Notation "U [ A ]" := (gateApp U A) (at level 0) : heisenberg_scope. 


Lemma type_is_app : forall (n: nat) (U A B : Square n),
  WF_Unitary U -> WF_Unitary A -> WF_Unitary B ->
  {{ [A] }} U {{ [B] }} <-> U[A] = B.
Proof. intros n U A B [Huwf Hu] [Hawf Ha] [Hbwf Hb]. split.
       - simpl. intros H. 
         apply ghp'_implies_ghp in H.
         unfold gateHasPair in H; unfold gateApp. 
         simpl in H. rewrite (H A B). 
         rewrite Mmult_assoc.
         apply Minv_flip in Hu; try easy.
         rewrite Hu. apply Mmult_1_r; auto.
         apply transpose_unitary; auto.
         split; auto. 
         left. easy. left. easy.
         split; auto. 
         easy.
         unfold uni_vecType.
         simpl. split.
         + intros A' [Ha' | F].
           rewrite <- Ha'. split; auto. 
           easy.
         + intros B' [Hb' | F].
           rewrite <- Hb'. split; auto. 
           easy.
       - intros. 
         apply ghp_implies_ghp'.
         easy.
         unfold gateHasPair; unfold gateApp in H.
         intros. 
         apply in_simplify in H0. 
         apply in_simplify in H1.
         rewrite H0, H1.
         rewrite <- H.
         rewrite Mmult_assoc.
         rewrite Hu.
         rewrite Mmult_assoc. 
         rewrite Mmult_1_r; 
         auto. 
Qed.


(* Gate definitions *)

Definition H' := hadamard.
Definition S' := Phase'.
Definition T' := phase_shift (PI / 4).
Definition CNOT :=  cnot.
Definition T'dagger := phase_shift (7 * PI / 4).


Definition seq {n : nat} (U1 U2 : Square n) := U2 × U1. 

Infix ";'" := seq (at level 52, right associativity).


Lemma singleton_simplify2 : forall {n} (U A B : Square n),
  gateHasPair U ([A], [B]) <-> U × A = B × U.
Proof. intros. 
       unfold gateHasPair. split.
       - intros. apply (H A B). 
         simpl. left. easy.
         simpl. left. easy. 
       - intros. simpl in *.
         destruct H0 as [H0 | F].
         destruct H1 as [H1 | F'].
         rewrite <- H0, <- H1; apply H.
         easy. easy.
Qed.       
**)


(*
Inductive vecHasType {prg_len : nat} : vecPair prg_len -> PType prg_len -> Prop :=
| VHT : forall vp T, Cap_vt T -> pairHasType vp (translateP T) ->
                vecHasType vp T.
  

Notation "p ;' T" := (vecHasType p T) (at level 61, no associativity).



Lemma cap_elim_l_vec : forall {n} (v : vecPair n) (A B : PType n), v ;' (A ∩ B) -> v ;' A.
Proof. intros. 
       inversion H; inversion H0.
       apply VHT; try easy.
       simpl translateP in *.
       apply Cap_vt_conv in H6;
         apply Cap_vt_conv in H7.
       rewrite H6, H7 in H1.
       simpl in H1.
       apply (Heisenberg.cap_elim_l_pair _ _ (translateP B)).
       assumption.
Qed.       


Lemma cap_elim_r_vec : forall {n} (v : vecPair n) (A B : PType n), v ;' A ∩ B -> v ;' B.
Proof. intros. 
       inversion H; inversion H0.
       apply VHT; try easy.
       simpl translateP in *.
       apply Cap_vt_conv in H6;
         apply Cap_vt_conv in H7.
       rewrite H6, H7 in H1.
       simpl in H1.
       apply (Heisenberg.cap_elim_r_pair _ (translateP A) _).
       assumption.
Qed.      


Hint Resolve cap_elim_l_vec cap_elim_r_vec : implication_db.

*)


(******************************************************************************)
(* Defining different types of PTypes to ensure WF(Well-formedness) and translations *)
(******************************************************************************)

Inductive TPType {n} : PType n -> Prop :=
| G_tpt : forall t : TType n, TPType (G [t]). 

Inductive APType {n} : PType n -> Prop :=
| G_apt : forall a : AType n, APType (G a). 

Lemma TPType_implies_APType : forall {n} (T : PType n),
    TPType T -> APType T.
Proof. intros. inversion H; apply G_apt. Qed.



Inductive TPType_trans {n} : PType_trans (2^n)%nat -> Prop :=
| G_tpt_trans : forall t : TType n, TPType_trans (G_t (translate t)). 

Inductive APType_trans {n} : PType_trans (2^n)%nat -> Prop :=
| G_apt_trans : forall a : AType n, APType_trans (G_t (translateA a)). 

Lemma TPType_trans_implies_APType_trans : forall {n} (T : PType_trans (2^n)%nat),
    TPType_trans T -> APType_trans T.
Proof. intros. inversion H; subst.
       assert ( translate t = translateA [t] ).
       { unfold translateA. simpl. rewrite Mplus_0_l. reflexivity. }
       rewrite H0.
       apply G_apt_trans.
Qed.


Lemma APType_APType_trans : forall {n} (A : PType n), 
  APType A -> APType_trans (translateP A).
Proof. intros. destruct A; easy. 
Qed.

Lemma TPType_TPType_trans : forall {n} (A : PType n), 
  APType A -> APType_trans (translateP A).
Proof. intros. destruct A; easy. 
Qed.


Lemma APType_simplify : forall {n} (A : PType n),
  APType A -> (exists a, A = G a).
Proof. intros. destruct A; try easy.
       - exists a. reflexivity. 
Qed.

Hint Resolve TPType_implies_APType TPType_trans_implies_APType_trans APType_APType_trans TPType_TPType_trans APType_simplify : wfpt_db.



Definition pI : PType 1 := G [ (C1, [gI]) ].
Definition pX : PType 1 := G [ (C1, [gX]) ].
Definition pY : PType 1 := G [ (C1, [gY]) ].
Definition pZ : PType 1 := G [ (C1, [gZ]) ].

Lemma Itrans : translateP pI = G_t (I 2).
Proof. simpl.
  unfold translateA; simpl.
  unfold translate; simpl.
  rewrite Mscale_1_l, kron_1_r, Mplus_0_l. 
  reflexivity. 
Qed.

Lemma Xtrans : translateP pX = G_t σx.
Proof. simpl. 
  unfold translateA; simpl.
  unfold translate; simpl.
  rewrite Mscale_1_l, kron_1_r, Mplus_0_l. 
  reflexivity. 
Qed.

Lemma Ytrans : translateP pY = G_t σy.
Proof. simpl.
  unfold translateA; simpl.
  unfold translate; simpl. 
  rewrite Mscale_1_l, kron_1_r, Mplus_0_l, Y_eq_iXZ.
  distribute_scale.
  reflexivity. 
Qed.

Lemma Ztrans : translateP pZ = G_t σz.
Proof. simpl. 
  unfold translateA; simpl.
  unfold translate; simpl.
  rewrite Mscale_1_l, kron_1_r, Mplus_0_l. 
  reflexivity. 
Qed.

Lemma Y_is_iXZ : pY = (i (pX .* pZ)).
Proof. simpl.
  unfold gMulA; simpl. unfold pY. compute.
  autorewrite with R_db.
  assert (R0 = (-R0)%R). { lra. }
  rewrite <- H.
  constructor.
Qed.

Hint Resolve Y_is_iXZ : wfpt_db.

(***************)
(* TPType Lemmas *)
(***************)
Lemma TI : TPType pI. Proof. easy. Qed.
Lemma TX : TPType pX. Proof. easy. Qed.
Lemma TZ : TPType pZ. Proof. easy. Qed.

Lemma T_scale : forall {n} (A : PType n) (c : Coef), TPType A -> (TPType (scale c A)).  
Proof. intros. inversion H. simpl. easy. Qed. 

Lemma T_neg : forall {n} (A : PType n), TPType A -> TPType (- A).
Proof. intros. inversion H. simpl. easy. Qed. 
 
Lemma T_i : forall {n} (A : PType n), TPType A -> TPType (i A).
Proof. intros. inversion H. simpl. easy. Qed. 

Lemma T_mul : forall {n} (A B : PType n), TPType A -> TPType B -> TPType (A .* B).
Proof. intros. inversion H. inversion H0. simpl. easy. Qed.

Lemma T_tensor : forall {n m} (A : PType n) (B : PType m), TPType A -> TPType B -> TPType (A .⊗ B).
Proof. intros. inversion H. inversion H0. simpl. constructor. Qed.

Lemma TY : TPType pY.
Proof. easy. Qed.

Hint Resolve TI TX TZ TY T_scale T_neg T_i T_mul T_tensor : wfpt_db.




(***************)
(* APType Lemmas *)
(***************)

Lemma AI : APType pI. Proof. easy. Qed.
Lemma AX : APType pX. Proof. easy. Qed.
Lemma AZ : APType pZ. Proof. easy. Qed.

Lemma A_scale : forall {n} (A : PType n) (c : Coef), APType A -> (APType (scale c A)).  
Proof. intros. destruct A; easy. Qed.
Locate "-".

Lemma A_neg : forall {n} (A : PType n), APType A -> APType (- A).
Proof. intros. destruct A; easy. Qed. 
 
Lemma A_i : forall {n} (A : PType n), APType A -> APType (i A).
Proof. intros. destruct A; easy. Qed. 

Lemma A_mul : forall {n} (A B : PType n), APType A -> APType B -> APType (A .* B).
Proof. intros.
       destruct A; destruct B; easy.
Qed.

Lemma A_tensor : forall {n m} (A : PType n) (B : PType m), APType A -> APType B -> APType (A .⊗ B).
Proof. intros.
       destruct A; destruct B; easy.
Qed.

Lemma AY : APType pY.
Proof. easy. Qed.

Hint Resolve AI AX AZ AY A_scale A_neg A_i A_mul A_tensor : wfpt_db.



(**************************)
(* Well Formedness Lemmas *)
(**************************)

Definition WF_TType (n : nat) (a : TType n) : Prop := n <> O /\ length (snd a) = n.

Lemma WF_ErrT : ~ WF_TType 0 ErrT.
Proof. intros H. unfold WF_TType in H. destruct H. contradiction.
Qed.
Lemma WF_ErrT_n : forall n : nat, ~ WF_TType n ErrT.
Proof. intros n H. unfold WF_TType in H. destruct H. unfold ErrT in H0.
  simpl in H0. rewrite <- H0 in H. contradiction.
Qed.


Inductive WF_AType (n : nat) : AType n -> Prop :=
| WF_AP_Sing (a : TType n) : WF_TType n a -> WF_AType n (cons a nil)
| WF_AP_Cons (a : TType n) (b : AType n) : WF_TType n a -> WF_AType n b -> WF_AType n (a :: b).

Inductive WF_PType {n} : PType n -> Prop :=
| WF_G : forall a : AType n, WF_AType n a -> WF_PType (G a)
| WF_Cap : forall T1 T2 : PType n, WF_PType T1 -> WF_PType T2 -> WF_PType (Cap T1 T2)
| WF_Cup : forall T1 T2 : PType n, WF_PType T1 -> WF_PType T2 -> WF_PType (Cup T1 T2).

Inductive WF_PType_trans {n} : PType_trans n -> Prop :=
| WF_G_t : forall a : Square n, WF_PType_trans (G_t a)
| WF_Cap_t : forall T1 T2 : PType_trans n, WF_PType_trans T1 -> WF_PType_trans T2 -> WF_PType_trans (Cap_t T1 T2)
| WF_Cup_t : forall T1 T2 : PType_trans n, WF_PType_trans T1 -> WF_PType_trans T2 -> WF_PType_trans (Cup_t T1 T2).


Lemma WF_I : WF_PType pI. Proof. do 3 constructor; easy. Qed. 
Lemma WF_X : WF_PType pX. Proof. do 3 constructor; easy. Qed.
Lemma WF_Z : WF_PType pZ. Proof. do 3 constructor; easy. Qed.


Lemma WF_TType_scale : forall {n} (a : TType n) (c : Coef),
    WF_TType n a -> WF_TType n (gScaleT c a).
Proof. intros n a c H. unfold WF_TType in *. destruct a. simpl in *. easy.
Qed.

Lemma WF_AType_scale : forall {n} (A : AType n) (c : Coef),
    WF_AType n A -> WF_AType n (gScaleA c A).
Proof. intros n A c H. induction H.
  - constructor. apply WF_TType_scale; easy.
  - unfold gScaleA in *. simpl in *. constructor; try assumption.
    apply WF_TType_scale; easy.
Qed.

Lemma WF_scale : forall {n} (A : PType n) (c : Coef), 
    APType A -> 
    WF_PType A -> (WF_PType (scale c A)).  
Proof. intros n A c H H0. 
  induction H; simpl. constructor. inversion H0; subst.
  apply WF_AType_scale; easy.
Qed.


Lemma WF_AType_app : forall {n} (a b : AType n), WF_AType n a -> WF_AType n b -> WF_AType n (a ++ b).
Proof. intros n a b H H0.
  induction H.
  - simpl. constructor; easy.
  - simpl. constructor; easy.
Qed.


Lemma WF_TType_mul : forall {n} (a b : TType n), WF_TType n a -> WF_TType n b -> WF_TType n (gMulT a b).
Proof. intros n a b H H0.
  unfold gMulT. unfold WF_TType. destruct a, b. simpl.
  rewrite zipWith_len_pres with (n:=n).
  inversion H. split; easy.
  inversion H. simpl in H2. easy.
  inversion H0. simpl in H2. easy.
Qed.

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

Lemma WF_mul : forall {n} (A B : PType n),
    APType A -> APType B -> 
  WF_PType A -> WF_PType B ->
  WF_PType (A .* B). 
Proof. intros n A B H H0 H1 H2.
  induction H, H0. inversion H1; inversion H2; subst.
  constructor. apply WF_AType_mul; easy.
Qed.


Lemma WF_TType_tensor : forall {n m} (a : TType n) (b : TType m), WF_TType n a -> WF_TType m b -> WF_TType (n+m) (gTensorT a b).
Proof. intros n m a b H H0.
  unfold WF_TType. unfold gTensorT. destruct a, b. simpl.
  inversion H. inversion H0. simpl in *. split.
  - intros H5. apply n_plus_m_zero_n_zero in H5. contradiction.
  - rewrite app_length. rewrite H2, H4. reflexivity.
Qed.

Lemma WF_AType_map_gTensorT : forall {n m} (a : TType n) (B : AType m),
    WF_TType n a -> WF_AType m B -> WF_AType (n+m) (map (fun x : TType m => gTensorT a x) B).
Proof. intros n m a B0 H H0. 
  induction H0; simpl.
  - apply (WF_AP_Sing (n+m)).
    apply (WF_TType_tensor a a0); easy.
  - apply (WF_AP_Cons (n+m)).
    + apply (WF_TType_tensor a a0); easy.
    + assumption.
Qed.

Lemma WF_AType_tensor : forall {n m} (A : AType n) (B : AType m),
    WF_AType n A -> WF_AType m B -> WF_AType (n+m) (gTensorA A B).
Proof. intros n m A0 B0 H H0.
  induction H.
  - unfold gTensorA. rewrite <- app_nil_end. apply WF_AType_map_gTensorT; easy.
  - simpl. apply (@WF_AType_app (n+m)).
    + apply WF_AType_map_gTensorT; easy.
    + easy.
Qed.

Lemma WF_tensor : forall {n m} (A : PType n) (B : PType m),
  APType A -> APType B -> 
  WF_PType A -> WF_PType B ->
  WF_PType (A .⊗ B). 
Proof. intros n m A B H H0 H1 H2. 
  induction H, H0. inversion H1; inversion H2; subst.
  constructor. apply WF_AType_tensor; easy.
Qed.


Lemma WF_AType_add : forall {n} (A B : AType n),
    WF_AType n A -> WF_AType n B -> WF_AType n (gAddA A B).
Proof. intros n A B H H0.
  unfold gAddA. apply WF_AType_app; easy.
Qed. 

Lemma WF_add : forall {n} (A : PType n) (B : PType n),
  APType A -> APType B -> 
  WF_PType A -> WF_PType B ->
  WF_PType (A .+ B). 
Proof. intros n A B H H0 H1 H2.
  induction H, H0. inversion H1; inversion H2; subst.
  constructor. apply WF_AType_add; easy.
Qed.
      

Lemma WF_AType_neg : forall {n} (A : AType n),
    WF_AType n A -> WF_AType n (gScaleA (Copp C1) A).
Proof. intros n A H.  apply WF_AType_scale; easy. Qed.

Lemma WF_neg : forall {n} (A : PType n),
    APType A -> 
    WF_PType A ->  WF_PType (- A). 
Proof. intros n A H H0.
  induction H. inversion H0; subst.
  constructor. apply WF_AType_neg; easy.
Qed.


Lemma WF_AType_i : forall {n} (A : AType n),
    WF_AType n A -> WF_AType n (gScaleA Ci A).
Proof. intros n A H.  apply WF_AType_scale; easy. Qed.

Lemma WF_i : forall {n} (A : PType n),
    APType A -> 
    WF_PType A ->  WF_PType (i A). 
Proof. intros n A H H0.
  induction H. inversion H0; subst.
  constructor. apply WF_AType_i; easy.
Qed.

Lemma WF_Y : WF_PType pY.
Proof. rewrite Y_is_iXZ. apply WF_i. easy. apply WF_mul. easy. easy. apply WF_X. apply WF_Z. Qed.


Hint Resolve WF_I WF_X WF_Z WF_Y WF_AType_mul WF_mul WF_AType_scale WF_scale WF_AType_tensor WF_tensor WF_AType_neg WF_neg WF_AType_i WF_i : wfpt_db.


Lemma fold_left_WF_Matrix_AType : forall {n} (a : TType n) (A : list (TType n)),  
    fold_left Mplus (map translate A) (Zero .+ translate a)%M
    =  (fold_left Mplus (map translate A) (Zero) .+  translate a)%M.
Proof. intros n a A. apply (fold_left_Mplus (translate a) Zero (map translate A)).
Qed.

Lemma WF_Matrix_AType : forall {n} (A : AType n), WF_AType n A -> WF_Matrix (translateA A). 
Proof. intros. induction H.
  - unfold translateA; simpl. rewrite Mplus_0_l. induction a. induction b.
    + inversion H. simpl in H1. symmetry in H1. contradiction.
    + unfold translate. simpl. apply (@Matrix.WF_scale (2^n) (2^n) a _).
      apply (Matrix.WF_kron _ _).
      * inversion H. simpl in H1. rewrite <- H1. simpl. clear H IHb H1. induction b.
        -- simpl. reflexivity.
        -- simpl. rewrite IHb. reflexivity.
      * inversion H. simpl in H1. rewrite <- H1. simpl. clear H IHb H1. induction b.
        -- simpl. reflexivity.
        -- simpl. rewrite IHb. reflexivity.
      * induction a0; auto with wf_db.
      * apply (@Matrix.WF_big_kron 2 2 _ (translate_P gI)).
        intros i0.
        rewrite map_nth.
        apply WF_Matrix_Pauli.
  - unfold translateA in *. simpl. rewrite fold_left_WF_Matrix_AType.
    apply Matrix.WF_plus; try assumption.
    unfold translate. induction a. simpl. apply (@Matrix.WF_scale (2^n) (2^n) a _).
    pose (@Matrix.WF_big_kron 2 2 (map translate_P b0) (translate_P gI)) as w.
    pose (@length (Square 2) (@map Pauli (Square 2) translate_P b0)) as l.
    rewrite map_length in *. inversion H; subst.
    apply w. intros i0. rewrite (map_nth translate_P b0 _ i0). apply WF_Matrix_Pauli.
Qed.

Hint Resolve WF_Matrix_AType : wf_db.

(*************)
(* WFT types *)
(*************)

Inductive WF_TPType {n} : PType n -> Prop :=
| WFT : forall T : PType n, TPType T -> WF_PType T -> WF_TPType T.

Lemma WFT_all : forall (c : Coef) (l : list Pauli),
    length l <> 0%nat -> @WF_TPType (length l) (G ([(c,l)])).
Proof. intros c l. do 4 constructor. assumption. simpl. reflexivity. Qed.
 
Lemma WFT_I : WF_TPType pI. Proof. apply WFT; auto with wfpt_db. Qed.
Lemma WFT_X : WF_TPType pX. Proof. apply WFT; auto with wfpt_db. Qed.
Lemma WFT_Z : WF_TPType pZ. Proof. apply WFT; auto with wfpt_db. Qed.
Lemma WFT_Y : WF_TPType pY. Proof. rewrite Y_is_iXZ. apply WFT; auto with wfpt_db. Qed.


Lemma WFT_mul : forall {n} (A B : PType n),
  WF_TPType A -> WF_TPType B -> 
  WF_TPType (A .* B). 
Proof. intros n A B H H0. 
       inversion H; inversion H0.
       apply WFT; auto with wfpt_db.
Qed.


Lemma WFT_tensor : forall {n m} (A : PType n) (B : PType m),
  WF_TPType A -> WF_TPType B ->
  WF_TPType (A .⊗ B). 
Proof. intros n m A B H H0. 
       inversion H; inversion H0.
       apply WFT; auto with wfpt_db.
Qed.


Lemma WFT_scale : forall {n} (A : PType n) (c : Coef),
  WF_TPType A ->  WF_TPType (scale c A). 
Proof. intros n A c H.
       inversion H.
       apply WFT; auto with wfpt_db.
Qed.

Lemma WFT_neg : forall {n} (A : PType n),
  WF_TPType A ->  WF_TPType (- A). 
Proof. intros n A [H H0]. 
       apply WFT_scale; easy. 
Qed.
   
Lemma WFT_i : forall {n} (A : PType n),
  WF_TPType A ->  WF_TPType (i A). 
Proof. intros n A H.
       unfold i. 
       apply WFT_scale; easy. 
Qed.


Hint Resolve WFT_all WFT_I WFT_X WFT_Z WFT_Y WFT_scale WFT_mul WFT_tensor WFT_neg WFT_i : wfpt_db.

(*************)
(* WFA types *)
(*************)

Inductive WF_APType {n} : PType n -> Prop :=
| WFA : forall T : PType n, APType T -> WF_PType T -> WF_APType T.

Lemma WFT_implies_WFA : forall {n} (A : PType n),
    WF_TPType A -> WF_APType A.
Proof. intros n A H. inversion H. inversion H0. subst. constructor. easy. easy. Qed.


Lemma WFA_I : WF_APType pI. Proof. apply WFA; auto with wfpt_db. Qed.
Lemma WFA_X : WF_APType pX. Proof. apply WFA; auto with wfpt_db. Qed.
Lemma WFA_Z : WF_APType pZ. Proof. apply WFA; auto with wfpt_db. Qed.
Lemma WFA_Y : WF_APType pY. Proof. rewrite Y_is_iXZ.  apply WFA; auto with wfpt_db. Qed.

Lemma WFA_mul : forall {n} (A B : PType n),
  WF_APType A -> WF_APType B -> 
  WF_APType (A .* B). 
Proof. intros n A B H H0. 
       inversion H; inversion H0.
       apply WFA; auto with wfpt_db.
Qed.


Lemma WFA_tensor : forall {n m} (A : PType n) (B : PType m),
  WF_APType A -> WF_APType B ->
  WF_APType (A .⊗ B). 
Proof. intros n m A B H H0. 
       inversion H; inversion H0.
       apply WFA; auto with wfpt_db.
Qed.


Lemma WFA_scale : forall {n} (A : PType n) (c : Coef),
  WF_APType A ->  WF_APType (scale c A). 
Proof. intros n A c H.
       inversion H.
       apply WFA; auto with wfpt_db.
Qed.

Lemma WFA_neg : forall {n} (A : PType n),
  WF_APType A ->  WF_APType (- A). 
Proof. intros n A [H H0]. 
       apply WFA_scale; easy. 
Qed.
   
Lemma WFA_i : forall {n} (A : PType n),
  WF_APType A ->  WF_APType (i A). 
Proof. intros n A H.
       unfold i. 
       apply WFA_scale; easy. 
Qed.


Lemma WFA_G_sing : forall {n} (a : TType n) (A : AType n),
    WF_APType (G (a :: A)) -> WF_APType (G ([a])).
Proof. intros n a A H.
       inversion H; subst.
       inversion H1; subst.
       do 3 constructor.
       inversion H3; subst; easy.
Qed.

Lemma WFA_G_cons : forall {n} (a : TType n) (A : AType n),
    A <> [] -> WF_APType (G (a :: A)) -> WF_APType (G (A)).
Proof. intros n a A G H. 
       inversion H; subst.
       inversion H1; subst.
       do 2 constructor.
       inversion H3; subst; easy.
Qed.

Lemma WFA_G_cons' : forall {n} (a : TType n) (A : AType n),
    WF_AType n A -> WF_APType (G (a :: A)) -> WF_APType (G (A)).
Proof. intros n a A G H. 
       inversion H; subst.
       inversion H1; subst.
       do 2 constructor.
       inversion H3; subst; easy.
Qed.


Hint Resolve WFA_I WFA_X WFA_Z  WFA_Y WFT_implies_WFA WFA_scale WFA_mul WFA_tensor WFA_neg WFA_i WFA_G_sing WFA_G_cons WFA_G_cons' : wfpt_db.


(******************)
(* unitary lemmas *)
(******************)


Lemma unit_Pauli : forall (p : Pauli), WF_Unitary (translate_P p).
Proof. intros. 
       destruct p; simpl; auto with unit_db.
Qed.

Lemma unit_list_Pauli : forall (l : list Pauli), WF_Unitary (⨂ map translate_P l).
Proof. intros.
  apply unit_big_kron.
  intros a H.
  rewrite in_map_iff in H.
  do 2 destruct H.
  rewrite <- H.
  apply unit_Pauli.
Qed.

Hint Resolve unit_Pauli unit_list_Pauli : unit_db.


(* norm of coeff = 1, precondition *)
Lemma uni_TType : forall {n} (A : TType n), fst A * fst A ^* = C1 -> WF_TType n A -> WF_Unitary (translate A). 
Proof. intros n A H H0. 
  unfold translate. pose (unit_scale (fst A) (⨂ map translate_P (snd A))) as w.
  destruct A. inversion H0; subst. 
  unfold translate. simpl in *.
  rewrite map_length in *.
  apply w.
  - pose (unit_big_kron 2 (map translate_P l)) as w0.
    rewrite map_length in *.
    apply w0.
    intros a H2. 
    apply in_map_iff in H2.
    do 2 destruct H2.
    rewrite <- H2.
    apply unit_Pauli.
  - assumption.
Qed.


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


Lemma Pauli_comm_anticomm : forall (p p0 : Pauli) (l l0 : list Pauli),
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
  - intros H1.  destruct p, p0; simpl in H1; inversion H1; try (contradict H1; lra);
      unfold cBigMul, gMul_Coef, zipWith, uncurry in *; simpl in *;
      rewrite ! fold_left_Cmult in H0; rewrite ! Cmult_1_l in H0; easy.
Qed.


Inductive Anticommutative {n} : TType n -> TType n -> Prop :=
| AC : forall t1 t2 : TType n, cBigMul (zipWith gMul_Coef (snd t1) (snd t2)) = Copp (cBigMul (zipWith gMul_Coef (snd t2) (snd t1))) -> Anticommutative t1 t2.


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
  

Lemma zipWith_gMul_base_symmetric : forall (l l0 : list Pauli), length l = length l0 -> zipWith gMul_base l l0 = zipWith gMul_base l0 l.
Proof. intros l. unfold zipWith, gMul_base, uncurry. induction l.
  - intros. rewrite combine_nil. simpl. easy.
  - intros. destruct l0; try discriminate. simpl. f_equal. destruct a, p; simpl; try easy. apply IHl. inversion H. easy.
Qed.


Lemma translate_gMulT: forall (l l0 : list Pauli) (a b : Coef), length l0 = length l -> (translate (gMulT (a, l) (b, l0)) = a * b .* ((⨂ map translate_P l) × (⨂ map translate_P l0)))%M.
Proof. induction l.
    - intros. simpl in *. rewrite length_zero_iff_nil in H. rewrite H. simpl. unfold translate, cBigMul, gMul_Coef, zipWith. simpl. lma'.
    - intros. simpl in *. destruct l0; try discriminate.
      simpl in *. inversion H.
      rewrite ! map_length. 
      assert (2 ^ length l + (2 ^ length l + 0) = 2 ^ (S (length l)))%nat. { simpl. easy. }
      rewrite H0.
      assert (@Mmult (2 ^ S (length l)) (2 ^ S (length l)) (2 ^ S (length l)) (translate_P a ⊗ (⨂ map translate_P l)) (translate_P p ⊗ (⨂ map translate_P l0)) =  (@Mmult 2 2 2 (translate_P a) (translate_P p)) ⊗ (@Mmult (2 ^ length l) (2 ^ length l) (2 ^ length l) (⨂ map translate_P l) (⨂ map translate_P l0))).
      { rewrite ! map_length. rewrite ! H1.
        apply kron_mixed_product' with (A:= translate_P a) (B:= big_kron (map translate_P l)) (C:= translate_P p) (D:= big_kron (map translate_P l0)); easy. }
      rewrite ! map_length in H2.
      rewrite H2.
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

Lemma unitary_two_tensored_paulis : forall {n} (t1 t2 : TType n), 
    WF_TType n t1 -> WF_TType n t2 -> (fst t1 = 1/√2) -> (fst t2 = 1/√2) ->
    Anticommutative t1 t2 ->
    WF_Unitary (@translateA n (t1 :: t2 :: nil)). 
Proof. intros. destruct t1, t2. simpl in H1, H2, H3.
  destruct H, H0. simpl in H4, H5.
  rewrite H1, H2 in *. clear H1. clear H2.
  inversion H3; subst.
  unfold translateA.
  simpl. rewrite Mplus_0_l.
  unfold translate. simpl  in *.
  setoid_rewrite <- Mscale_plus_distr_r with (x:=C1 / √ 2) (A:=⨂ map translate_P l) (B:=⨂ map translate_P l0).
  
  rewrite map_length.
  apply unitary_hermitian_anticommute_unitary.
  rewrite <- map_length with (f:=translate_P).
  apply unit_list_Pauli.
  rewrite <- H5.
  rewrite <- map_length with (f:=translate_P).
  apply unit_list_Pauli.
  apply list_Pauli_hermitian.
  apply list_Pauli_hermitian.

  apply Mscale_inv with (c:=C1/C2).
  - intros G. apply C_inj_r with (c:=C2) in G. unfold Cdiv in G. rewrite <- Cmult_assoc in G. rewrite Cinv_l in G; try nonzero. rewrite Cmult_0_l in G. rewrite Cmult_1_l in G. contradict G. nonzero.
  - rewrite Mscale_assoc. rewrite Cmult_comm. rewrite <- Mscale_assoc.
    replace (C1 / C2) with ((C1/√2) * (C1/√2)) by C_field.
    rewrite Mscale_assoc. rewrite Cmult_assoc. symmetry. rewrite Cmult_comm. symmetry.
    assert ((C1 / √ 2 * (C1 / √ 2) .* ((⨂ map translate_P l) × (⨂ map translate_P l0)))%M
            = (translate (gMulT  (C1 / √ 2, l) (C1 / √ 2, l0)))%M).
    { rewrite <- translate_gMulT; easy. }
      rewrite <- map_length with (f:=translate_P).
    rewrite H2.
    assert ((C1 / √ 2 * (-C1 * (C1 / √ 2)) .* ((⨂ map translate_P l0) × (⨂ map translate_P l)))%M
            = (translate (gMulT  (C1 / √ 2, l0) (-C1 * (C1 / √ 2), l)))%M).
    { rewrite <- translate_gMulT; easy. }
    show_dimensions.
    rewrite map_length.
    rewrite <- H5.
    rewrite <- map_length with (f:=translate_P).
    rewrite H4.
    simpl. rewrite H1.
    assert (C1 / √ 2 * (C1 / √ 2) * - cBigMul (zipWith gMul_Coef l0 l)
            = C1 / √ 2 * (-C1 * (C1 / √ 2)) * cBigMul (zipWith gMul_Coef l0 l)).
    { rewrite <- ! Cmult_assoc. apply C_inj_l. symmetry. 
      rewrite Cmult_comm. rewrite <- ! Cmult_assoc. apply C_inj_l.
      lca. }
    rewrite H6.
    rewrite zipWith_gMul_base_symmetric; easy.
Qed.

(* same as unitary_two_tensored_paulis except that (fst t2 = - C1/√2). *)
Lemma unitary_two_tensored_paulis' : forall {n} (t1 t2 : TType n), 
    WF_TType n t1 -> WF_TType n t2 -> (fst t1 = C1/√2) -> (fst t2 = - C1/√2) ->
    Anticommutative t1 t2 ->
    WF_Unitary (@translateA n (t1 :: t2 :: nil)). 
Proof. intros. destruct t1, t2. simpl in H1, H2, H3.
  destruct H, H0. simpl in H4, H5.
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
  rewrite map_length.
  apply unitary_hermitian_anticommute_unitary.
  rewrite <- map_length with (f:=translate_P).
  apply unit_list_Pauli.
  rewrite <- H5.
  rewrite <- map_length with (f:=translate_P).
  apply unit_scale; try lca.
  apply unit_list_Pauli.
  apply list_Pauli_hermitian.
  setoid_rewrite Mscale_adj with (x := (-C1)%C) (A := (⨂ map translate_P l0)).
  replace ((- C1) ^* )%C with (-C1)%C by lca.
  rewrite map_length.
  rewrite H5.
  apply Mscale_inj with (c:= (-C1)%C).
  apply list_Pauli_hermitian.
  apply Mscale_inv with (c:= (-C1)%C).
  intro. inversion H2. lra.
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
    rewrite H2.
    assert ((C1 / √ 2 * (-1 * (C1 / √ 2)) .* ((⨂ map translate_P l0) × (⨂ map translate_P l)))%M
            = (translate (gMulT  (C1 / √ 2, l0) (-1 * (C1 / √ 2), l)))%M).
    { rewrite <- translate_gMulT; easy. }
    show_dimensions.
    rewrite map_length.
    rewrite <- H5.
    rewrite <- map_length with (f:=translate_P).
    rewrite H4.
    simpl. rewrite H1.
    assert (C1 / √ 2 * (C1 / √ 2) * - cBigMul (zipWith gMul_Coef l0 l)
            = C1 / √ 2 * (-1 * (C1 / √ 2)) * cBigMul (zipWith gMul_Coef l0 l)).
    { rewrite <- ! Cmult_assoc. apply C_inj_l. symmetry. 
      rewrite Cmult_comm. rewrite <- ! Cmult_assoc. apply C_inj_l.
      lca. }
    rewrite H6.
    rewrite zipWith_gMul_base_symmetric; easy.
Qed.


Lemma uni_vec_I : uni_PType_trans (translateP pI).
Proof. simpl. unfold translateA, translate, translate_P. simpl.
       rewrite Mplus_0_l, Mscale_1_l, kron_1_r. unfold WF_Unitary.
       split. auto with wf_db. lma'.
Qed.
  
Lemma uni_vec_X : uni_PType_trans (translateP pX).
Proof. simpl. unfold translateA, translate, translate_P. simpl.
       rewrite Mplus_0_l, Mscale_1_l, kron_1_r. unfold WF_Unitary.
       split. auto with wf_db. lma'.
Qed.

Lemma uni_vec_Y : uni_PType_trans (translateP pY).
Proof.  simpl. unfold translateA, translate, translate_P. simpl.
       rewrite Mplus_0_l, Mscale_1_l, kron_1_r. unfold WF_Unitary.
       split. auto with wf_db. lma'.
Qed.

  Lemma uni_vec_Z : uni_PType_trans (translateP pZ).
Proof.  simpl. unfold translateA, translate, translate_P. simpl.
       rewrite Mplus_0_l, Mscale_1_l, kron_1_r. unfold WF_Unitary.
       split. auto with wf_db. lma'.
Qed.


Hint Resolve unit_Pauli uni_vec_I uni_vec_X uni_vec_Y uni_vec_Z : wfpt_db.


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
             destruct H1 as [x [H3 H4]].
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
 length (snd a) = n -> WF_AType m B ->
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
    WF_AType n a -> WF_AType m b ->
    translateA (gTensorA a b) = (translateA a) ⊗ (translateA b).
Proof. intros n m a b H H0. induction H.
  - simpl. rewrite <- app_nil_end. unfold translateA. simpl. rewrite Mplus_0_l. rewrite <- fold_left_translateA_kron; inversion H; try assumption. rewrite map_map; reflexivity.
  - simpl. unfold translateA. simpl. rewrite fold_left_Mplus.
    unfold translateA in IHWF_AType. rewrite kron_plus_distr_r.  rewrite <- IHWF_AType.
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
    WF_TType n a -> WF_AType n B ->
    fold_left Mplus (map (fun x : TType n => translate (gMulT a x)) B) Zero =
      translate a × fold_left Mplus (map translate B) Zero.
Proof. intros n a B H H0.
  induction H0.
  - simpl. rewrite 2 Mplus_0_l. inversion H; inversion H0; rewrite translate_Mmult; easy.
  - simpl. rewrite 2 fold_left_Mplus. rewrite Mmult_plus_distr_l. rewrite <- translate_Mmult.
    rewrite IHWF_AType. reflexivity.
    + inversion H. assumption.
    + inversion H0. assumption.
Qed. 

Lemma translateA_Mmult : forall {n} (a b : AType n),
    WF_AType n a -> WF_AType n b ->
    translateA (gMulA a b) = (translateA a) × (translateA b).
Proof. intros n a b H H0.
  unfold translateA. induction H.
  - simpl. rewrite <- app_nil_end. rewrite map_map. rewrite Mplus_0_l.
    apply fold_left_translateA_Mmult; assumption.
  - simpl. rewrite map_app. rewrite map_map. rewrite fold_left_Mplus_app_Zero.
    rewrite fold_left_Mplus. rewrite Mmult_plus_distr_r. rewrite <- IHWF_AType.
    rewrite fold_left_translateA_Mmult; try assumption. rewrite Mplus_comm. reflexivity.
Qed.

Lemma translateP_mMult : forall {n} (A B : PType n),
  WF_APType A -> WF_APType B -> 
  translateP (A .* B) = (translateP A) *' (translateP B).
Proof. intros n A B H H0.  
       inversion H; inversion H0.
       destruct A; destruct B; try easy.
       simpl.
       inversion H2; inversion H5.
       inversion H8; inversion H10;
         rewrite translateA_Mmult; constructor; try easy.
Qed.

Lemma map_translate_gAddA : forall {n} (a b : AType n),
    WF_AType n a -> WF_AType n b ->
    map translate (gAddA a b) = ((map translate a) ++ (map translate b))%M.
Proof. intros n a b H H0.
       unfold gAddA. induction H.
       - simpl. reflexivity.
       - simpl. rewrite IHWF_AType. reflexivity.
Qed.

Lemma translateA_Add : forall {n} (a b : AType n),
    WF_AType n a -> WF_AType n b ->
    translateA (gAddA a b) = (translateA a .+ translateA b)%M.
Proof. intros n a b H H0.
       unfold translateA. induction H.
       - simpl. rewrite fold_left_Mplus. rewrite Mplus_0_l. rewrite Mplus_comm. reflexivity.
       - simpl. rewrite map_translate_gAddA; auto.
         rewrite ! fold_left_Mplus. rewrite fold_left_Mplus_app_Zero. rewrite ! Mplus_assoc. f_equal. rewrite Mplus_comm. reflexivity.
Qed. 

  
Lemma translateP_Add : forall {n} (A B : PType n),
  WF_APType A -> WF_APType B -> 
  translateP (A .+ B) = (translateP A) +' (translateP B).
Proof. intros n A B H H0.  
       inversion H; inversion H0.
       destruct A; destruct B; try easy.
       simpl.
       inversion H2; inversion H5.
       inversion H8; inversion H10;
         rewrite translateA_Add; constructor; try easy.
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


Lemma translateP_scale : forall {n} (A : PType n) (c : Coef),
  translateP (scale c A) =  c ·' (translateP A).
Proof. intros. induction A; try easy.
       - simpl. rewrite translateA_scale.
         reflexivity.
Qed.


Declare Scope AType_scope.
Delimit Scope AType_scope with A.
Open Scope AType_scope.
Bind Scope AType_scope with AType.

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

Lemma translateA_app : forall {n} (a b c : AType n),
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
  intros n a b. unfold gMulA, gMulA'.
  induction a.
  - induction b.
    + reflexivity.
    + simpl. reflexivity.
  - rewrite translateA_app.
    rewrite IHa. clear IHa.
    induction b.
    + compute. autorewrite with R_db. reflexivity.
    + simpl.
      unfold translateA. simpl. rewrite ! map_app. rewrite ! map_map.
      rewrite ! fold_left_Mplus. rewrite Mplus_assoc.
      assert ((translate (gMulT a a1)
                 .+ fold_left Mplus
                 (map (fun x : TType n => translate (gMulT x a1)) a0 ++
                    map translate (gMulA a0 b)) Zero)
              =
                (fold_left Mplus
                  (map (fun x : TType n => translate (gMulT x a1)) a0 ++
                     map translate (gMulA a0 b)) Zero) .+  translate (gMulT a a1) )%M.
      { rewrite Mplus_comm. easy. }
      rewrite H.
      rewrite ! fold_left_Mplus_app_Zero.
      rewrite <- ! Mplus_assoc.
      assert (fold_left Mplus (map (fun x : TType n => translate (gMulT a x)) b) Zero
                .+ fold_left Mplus (map (fun x : TType n => translate (gMulT x a1)) a0) Zero
              =
                fold_left Mplus (map (fun x : TType n => translate (gMulT x a1)) a0) Zero
                  .+ fold_left Mplus (map (fun x : TType n => translate (gMulT a x)) b) Zero)%M.
      { rewrite Mplus_comm. easy. }
      rewrite H0. reflexivity.
Qed.

Lemma gTensorA_is_gTensorA' : forall {n m} (a : AType n) (b : AType m),
    gTensorA a b ≡ gTensorA' a b.
Proof. intros n m a b. 
  induction a.
  - induction b.
    + reflexivity.
    + simpl. reflexivity.
  - simpl.
    rewrite translateA_app with (a:=map (fun x : TType n => gTensorT a x) b) (b:=gTensorA a0 b) (c:=gTensorA' (a :: a0) b). unfold "≡" in IHa. rewrite IHa at 1. clear IHa.
    induction b.
    + compute. autorewrite with R_db. reflexivity.
    + simpl.
      unfold translateA. simpl. rewrite ! map_app. rewrite ! map_map.
      rewrite ! fold_left_Mplus. rewrite Mplus_assoc.
      assert ((translate (gTensorT a a1)
                 .+ fold_left Mplus
            (map (fun x : TType n => translate (gTensorT x a1)) a0 ++
                map translate (gTensorA a0 b)) Zero)
             =
               (fold_left Mplus
            (map (fun x : TType n => translate (gTensorT x a1)) a0 ++
               map translate (gTensorA a0 b)) Zero)
                 .+ translate (gTensorT a a1))%M.
      { rewrite Mplus_comm. easy. }
      rewrite H at 1.
      rewrite ! fold_left_Mplus_app_Zero.
      rewrite <- Mplus_assoc.
      assert (fold_left Mplus (map (fun x : TType n => translate (gTensorT x a1)) a0) Zero
                .+ fold_left Mplus (map (fun x : TType n => translate (gTensorT a x)) b) Zero
              =
                fold_left Mplus (map (fun x : TType n => translate (gTensorT a x)) b) Zero
                  .+ fold_left Mplus (map (fun x : TType n => translate (gTensorT x a1)) a0) Zero)%M.
      { rewrite Mplus_comm. easy. }
      rewrite H0 at 1.
      rewrite -> ! Mplus_assoc.
      reflexivity.
Qed.



(*
(** G : equivalently, Cap&Cup: pointwise **)
Inductive eq_PType {n} : PType n -> PType n -> Prop :=
| G_eq : forall a b : AType n, translateA a = translateA b -> eq_PType (G a) (G b)
| Cap_eq : forall T1 T'1 T2 T'2 : PType n, T1 = T'1 -> T2 = T'2 -> eq_PType (Cap T1 T2) (Cap T'1 T'2)
| Arr_eq : forall T1 T'1 T2 T'2 : PType n, T1 = T'1 -> T2 = T'2 -> eq_PType (Cup T1 T2) (Cup T'1 T'2)
| Err_eq : eq_PType Err Err.
 *)
Definition eq_PType {n} (A1 A2 : PType n) := translateP A1 = translateP A2.


Declare Scope PType_scope.
Delimit Scope PType_scope with P.
Open Scope PType_scope.
Bind Scope PType_scope with PType.
Infix "≡" := eq_PType (at level 70, no associativity): PType_scope.
Open Scope PType_scope.

(* will now show this is an equivalence relation *)
Lemma eq_PType_refl : forall {n} (A : PType n), A ≡ A.
Proof. intros n A. destruct A; constructor; easy.
Qed.

Lemma eq_PType_sym : forall {n} (A B : PType n), A ≡ B -> B ≡ A.
Proof. intros n A B H. destruct A, B; inversion H; try discriminate; try constructor; try easy.
Qed.

Lemma eq_PType_trans : forall {n} (A B C : PType n),
    A ≡ B -> B ≡ C -> A ≡ C.
Proof.
  intros n A B C HAB HBC.
  destruct A, B, C; inversion HAB; inversion HBC; subst;
    try discriminate; try constructor; try easy;
    unfold "≡"; simpl; f_equal;
    try (transitivity (translateA a0); easy);
    try (transitivity (translateP B1); easy);
    try (transitivity (translateP B2); easy).
Qed.


Add Parametric Relation n : (PType n) (@eq_PType n)
  reflexivity proved by eq_PType_refl
  symmetry proved by eq_PType_sym
  transitivity proved by eq_PType_trans
    as eq_PType_rel.





Lemma AType_PType_equiv_compat : forall{n} (A A' : AType n),
    (A ≡ A')%A -> (G A ≡ G A')%P.
Proof. intros n A A' H.
       unfold "≡"%A in *. 
       unfold "≡"%P in *. 
       simpl. f_equal. easy.
Qed.
       
Add Parametric Morphism (n : nat) : G
  with signature @eq_AType n ==> @eq_PType n as AType_PType_mor.
Proof.
  intros.
  apply AType_PType_equiv_compat; easy.
Qed.


Lemma add_comm : forall {n} (A A' : PType n) c, c .· (A .+ A') ≡ c .· (A' .+ A).
Proof. intros n A A' c.    
  destruct A, A'; simpl; try easy.
  unfold "≡". simpl. f_equal. apply gAddA_comm.
Qed.



Hint Resolve add_comm : base_types_db.
Hint Resolve add_comm : typing_db.
















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
                    counterparts on the PType level *)
(***************************************************************************)


Lemma gMulT_gTensorT_dist : forall {n m : nat} (t1 t2 : TType n) (t3 t4 : TType m),
  WF_TType n t1 -> WF_TType n t2 -> WF_TType m t3 -> WF_TType m t4 ->
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
  WF_TType n t1 -> WF_TType n t2 -> WF_TType n t3 ->
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
    WF_AType n b -> WF_TType n a -> WF_TType n a0 ->
    map (fun x : TType n => gMulT (gMulT a a0) x) b = map (fun x : TType n => gMulT a (gMulT a0 x)) b.
Proof. intros n a a0 b H H0 H1.
  induction H.
  - simpl. rewrite gMulT_assoc; try easy.
  - simpl. rewrite gMulT_assoc; try easy. rewrite IHWF_AType; easy.
Qed.


Lemma gMulA_map_app : forall {n} (b b0 b1 b2 : AType n) (a : TType n),
    WF_AType n b -> WF_AType n b0 -> WF_AType n b1 -> WF_AType n b2 ->
    WF_TType n a ->
    gMulA (map (fun x : TType n => gMulT a x) b0 ++ gMulA b b1) b2
    = (map (fun x : TType n => gMulT a x) (gMulA b0 b2) ++ gMulA (gMulA b b1) b2).
Proof. intros n b b0 b1 b2 a H H0 H1 H2 H3. 
  induction H0.
  - simpl. rewrite <- app_nil_end. rewrite map_map.
    rewrite gMulT_assoc_map; try easy.
  - simpl. rewrite map_app. rewrite map_map. rewrite IHWF_AType. rewrite app_assoc.
    rewrite gMulT_assoc_map; try easy.
Qed. 

Lemma gMulA_assoc : forall (n : nat) (a1 a2 a3 : AType n),
  WF_AType n a1 -> WF_AType n a2 -> WF_AType n a3 ->
  gMulA (gMulA a1 a2) a3 = gMulA a1 (gMulA a2 a3).
Proof. intros n a1 a2 a3 H H0 H1.
  induction H; induction H0; induction H1; simpl in *; rewrite gMulT_assoc; try rewrite IHWF_AType; try easy. 
  + rewrite map_app. rewrite map_map. rewrite <- 2 app_nil_end.
    rewrite gMulT_assoc_map; try easy.
  + rewrite <- app_nil_end in *. rewrite map_map.
    rewrite gMulT_assoc_map; try easy.
  + rewrite <- IHWF_AType.
    rewrite gMulA_map_app; try easy; try constructor; try easy.
  + rewrite <- IHWF_AType. rewrite gMulA_map_app; try easy; try constructor; try easy. 
    rewrite map_app. rewrite map_map. rewrite app_assoc. rewrite gMulT_assoc_map; try easy.
Qed.


(* Multiplication laws *)

Lemma mul_assoc : forall {n} (A B C : PType n), 
  WF_APType A -> WF_APType B -> WF_APType C -> 
  A .* (B .* C) = A .* B .* C. 
Proof. intros. 
       destruct A; destruct B; destruct C; try easy.
       inversion H; inversion H0; inversion H1.
       unfold mul.
       inversion H3; inversion H6; inversion H9.
       rewrite gMulA_assoc; easy. 
Qed.


Lemma mul_I_l : forall (A : PType 1), WF_APType A -> pI .* A = A.
Proof. intros A H.
  inversion H. 
  destruct A; try easy.
  inversion H0; inversion H1; subst.
  clear H. clear H0. clear H1.  
  simpl. f_equal. rewrite <- app_nil_end.
  induction H5.
  - simpl. destruct a. do 3 f_equal.
    + unfold zipWith, cBigMul, gMul_Coef, uncurry. simpl.
      induction l;  simpl; lca.
    + unfold zipWith, gMul_base, uncurry.
      induction l; simpl; try easy.
      inversion H. inversion H1. rewrite length_zero_iff_nil in H3. rewrite H3. easy.
  - simpl. destruct a. do 3 f_equal.
    + unfold zipWith, cBigMul, gMul_Coef, uncurry. simpl.
      induction l; simpl; lca.
    + unfold zipWith, gMul_base, uncurry.
      induction l; simpl; try easy.
      inversion H. inversion H1. rewrite length_zero_iff_nil in H3. rewrite H3. easy.
    + simpl in IHWF_AType. rewrite IHWF_AType. easy.
Qed.

Lemma mul_I_r : forall (A : PType 1), WF_APType A -> A .* pI = A.
Proof. intros A H.
  inversion H. 
  destruct A; try easy.
  inversion H0; inversion H1; subst.
  clear H. clear H0. clear H1.  
  simpl. f_equal.
  induction H5.
  - destruct a. simpl. do 2 f_equal. 
    + unfold zipWith, cBigMul, gMul_Coef, uncurry.
      induction l.
      * simpl. lca.
      * inversion H. inversion H1. rewrite length_zero_iff_nil in H3. rewrite H3. simpl.
        induction a; lca.
    + unfold zipWith, gMul_base, uncurry.
      induction l; simpl; try easy.
      inversion H. inversion H1. rewrite length_zero_iff_nil in H3. rewrite H3. simpl.
      induction a; easy.
  - simpl. rewrite IHWF_AType. unfold gMulT. destruct a. do 2 f_equal.
    + unfold zipWith, cBigMul, gMul_Coef, uncurry.
      induction l; simpl; autorewrite with C_db; try easy.
      inversion H. inversion H1. rewrite length_zero_iff_nil in H3. rewrite H3. simpl.
      induction a; lca.
    + unfold zipWith, gMul_base, uncurry.
      induction l; simpl; try easy.
      inversion H. inversion H1. rewrite length_zero_iff_nil in H3. rewrite H3. simpl.
      induction a; easy.
Qed.

Lemma Xsqr : pX .* pX = pI.
Proof. simpl. unfold zipWith, cBigMul, gMul_Coef, uncurry. simpl. unfold I.
  do 3 f_equal. unfold pI. repeat f_equal. lca. Qed.       

Lemma Zsqr : pZ .* pZ = pI.
Proof. simpl. unfold zipWith, cBigMul, gMul_Coef, uncurry. simpl. unfold I.
  do 3 f_equal. unfold pI. repeat f_equal. lca. Qed.

Lemma ZmulX : pZ .* pX = - (pX .* pZ).
Proof. simpl. do 3 f_equal.
  unfold zipWith, cBigMul, gMul_Coef, uncurry.  simpl. lca. Qed.



Lemma switch_neg : forall n (A : PType n) (c : Coef), - (c .· A) = c .· (- A).
  intros n A c.
  induction A; simpl; try rewrite IHA1, IHA2; try easy.
  f_equal. unfold gScaleA. rewrite 2 map_map. f_equal.
  apply functional_extensionality. intros x. destruct x.
  simpl. f_equal. lca.
Qed.


Lemma neg_inv : forall (n : nat) (A : PType n), WF_APType A -> - - A = A.
Proof. intros n A H.
       induction A; simpl; try easy.
       2,3: inversion H; inversion H0.
       f_equal. unfold gScaleA, gScaleT.
       rewrite map_map.
       clear H.
       induction a.
       - simpl. easy.
       - simpl in *. f_equal.
         + destruct a. f_equal. lca.
         + apply IHa.
Qed.


Lemma gMulT_gScaleT_map : forall {n} (a : TType n) (b : AType n),
    WF_TType n a -> WF_AType n b ->
    (map (fun x : TType n => gMulT (gScaleT (- C1)%C a) x) b)
    = (map (fun x : TType n => gScaleT (- C1)%C (gMulT a x)) b).
Proof. intros n a b H H0. induction H0.
  - simpl. f_equal. destruct a, a0. simpl. f_equal. lca.
  - simpl. rewrite IHWF_AType. f_equal. destruct a, a0. simpl. f_equal. lca.
Qed.

Lemma neg_dist_l : forall (n : nat) (A B : PType n), 
  WF_APType A -> WF_APType B -> 
  -A .* B = - (A .* B).
Proof. intros. 
  inversion H; inversion H0; subst.
  destruct A; destruct B; try easy.
  inversion H2; inversion H5; subst.
  clear H. clear H0. clear H1. clear H4. clear H2. clear H5.
  simpl. f_equal.
  induction H6; induction H8.
  - simpl. f_equal. destruct a, a0.
    simpl. f_equal. lca.
  - simpl in *. rewrite IHWF_AType.
    f_equal. destruct a, a0. simpl.
    f_equal. lca.
  - simpl in *. rewrite IHWF_AType.
    f_equal. destruct a, a0. simpl.
    f_equal. lca.
  - simpl in *. rewrite IHWF_AType. unfold gScaleA in *. rewrite map_app in *.
    rewrite map_map in *.
    assert ((map (fun x : TType n => gMulT (gScaleT (- C1)%C a) x) b0)
            = (map (fun x : TType n => gScaleT (- C1)%C (gMulT a x)) b0)).
    { clear IHWF_AType. clear IHWF_AType0. induction H8.
      - simpl. f_equal. destruct a, a1. simpl. f_equal. lca.
      - simpl. rewrite IHWF_AType. f_equal. destruct a, a1. simpl. f_equal. lca. }
    rewrite H1. f_equal.
    destruct a, a0. simpl. f_equal. lca.
Qed.


Lemma neg_dist_r : forall (n : nat) (A B : PType n), 
  WF_APType A -> WF_APType B -> 
  A .* (-B) = - (A .* B).
Proof. intros. 
  inversion H; inversion H0; subst.
  destruct A; destruct B; try easy.
  inversion H2; inversion H5; subst.
  clear H. clear H0. clear H1. clear H4. clear H2. clear H5.
  simpl. f_equal.
  induction H6; induction H8.
  - simpl. f_equal. destruct a, a0.
    simpl. f_equal. lca.
  - simpl in *. rewrite IHWF_AType.
    f_equal. destruct a, a0. simpl.
    f_equal. lca.
  - simpl in *. rewrite IHWF_AType.
    f_equal. destruct a, a0. simpl.
    f_equal. lca.
  - simpl in *. rewrite IHWF_AType. unfold gScaleA in *. rewrite map_app in *.
    rewrite 2 map_map in *.
    assert ((map (fun x : TType n => gMulT a (gScaleT (- C1)%C x)) b0)
            = (map (fun x : TType n => gScaleT (- C1)%C (gMulT a x)) b0)).
    { clear IHWF_AType. clear IHWF_AType0. induction H8.
      - simpl. f_equal. destruct a, a1. simpl. f_equal. lca.
      - simpl. rewrite IHWF_AType. f_equal. destruct a, a1. simpl. f_equal. lca. }
    rewrite H1. f_equal.
    destruct a, a0. simpl. f_equal. lca.
Qed.

Lemma neg_dist_add : forall (n : nat) (A B : PType n), - (A .+ B) = -A .+ -B.
Proof. intros n A B.
  induction A; induction B; simpl; try easy.
  f_equal. unfold gScaleA, gAddA.
  rewrite <- map_app. f_equal.
Qed. 

Lemma i_sqr : forall (n : nat) (A : PType n), i (i A) = -A.
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

Lemma i_dist_l : forall (n : nat) (A B : PType n), 
  WF_APType A -> WF_APType B -> 
  i A .* B = i (A .* B).
Proof. intros. 
  inversion H; inversion H0; subst.
  destruct A; destruct B; try easy.
  inversion H2; inversion H5; subst.
  clear H. clear H0. clear H1. clear H2. clear H4. clear H5.
  unfold i. simpl. f_equal.
  induction H6; induction H8.
  - simpl. f_equal. destruct a, a0. simpl. f_equal. lca.
  - unfold gScaleA, gMulA in *. simpl in *. rewrite <- ! app_nil_end in *. rewrite map_map in *.
    rewrite IHWF_AType. f_equal. destruct a, a0. simpl. f_equal. lca.
  -  simpl in *. rewrite IHWF_AType. f_equal. destruct a, a0. simpl. f_equal. lca.
  - simpl in *. unfold gScaleA, gMulA in *. rewrite IHWF_AType. rewrite map_app. rewrite map_map.
    assert ((map (fun x : TType n => gMulT (gScaleT Ci a) x) b0) = (map (fun x : TType n => gScaleT Ci (gMulT a x)) b0)).
    { clear IHWF_AType. clear IHWF_AType0. induction H8.
      - simpl. f_equal. destruct a, a1. simpl. f_equal. lca.
      - simpl. rewrite IHWF_AType. f_equal. destruct a, a1. simpl. f_equal. lca. }
    rewrite H1. f_equal. destruct a, a0. simpl. f_equal. lca.
Qed.


Lemma i_dist_r : forall (n : nat) (A B : PType n), 
  WF_APType A -> WF_APType B -> 
  A .* i B = i (A .* B).
Proof. intros. 
  inversion H; inversion H0; subst.
  destruct A; destruct B; try easy.
  inversion H2; inversion H5; subst.
  clear H. clear H0. clear H1. clear H2. clear H4. clear H5.
  unfold i. simpl. f_equal.
  induction H6; induction H8.
  - simpl. f_equal. destruct a, a0. simpl. f_equal. lca.
  - unfold gScaleA, gMulA in *. simpl in *. rewrite <- ! app_nil_end in *. rewrite map_map in *.
    rewrite IHWF_AType. f_equal. destruct a, a0. simpl. f_equal. lca.
  -  simpl in *. rewrite IHWF_AType. f_equal. destruct a, a0. simpl. f_equal. lca.
  - simpl in *. unfold gScaleA, gMulA in *. rewrite IHWF_AType. rewrite map_app. rewrite ! map_map.
    assert ((map (fun x : TType n => gMulT a (gScaleT Ci x)) b0) = (map (fun x : TType n => gScaleT Ci (gMulT a x)) b0)).
    { clear IHWF_AType. clear IHWF_AType0. induction H8.
      - simpl. f_equal. destruct a, a1. simpl. f_equal. lca.
      - simpl. rewrite IHWF_AType. f_equal. destruct a, a1. simpl. f_equal. lca. }
    rewrite H1. f_equal. destruct a, a0. simpl. f_equal. lca.
Qed.

Lemma i_neg_comm : forall (n : nat) (A : PType n), i (-A) = -i A.
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


Hint Resolve switch_neg neg_inv neg_dist_add i_sqr i_neg_comm : typing_db.
Hint Rewrite switch_neg neg_inv neg_dist_add i_sqr i_neg_comm : typing_db.



(** ** Tensor Laws *)


Lemma gTensorT_assoc : forall {n : nat} (t1 t2 t3 : TType n),
  WF_TType n t1 -> WF_TType n t2 -> WF_TType n t3 ->
  gTensorT (gTensorT t1 t2) t3 = gTensorT t1 (gTensorT t2 t3).
Proof. intros n t1 t2 t3 H H0 H1.
  unfold gTensorT. destruct t1, t2, t3. f_equal. lca. rewrite app_assoc. easy.
Qed.


Lemma gTensorA_assoc_map : forall {n} (a : TType n) (b b0 b1 b2 : AType n),
    WF_TType n a -> WF_AType n b  -> WF_AType n b0  -> WF_AType n b1  -> WF_AType n b2 ->
    gTensorA (map (fun x : TType n => gTensorT a x) b0 ++ gTensorA b b1) b2 =
      (map (fun x : TType n => gTensorT a x) (gTensorA b0 b2) ++ gTensorA (gTensorA b b1) b2).
Proof. intros n a b b0 b1 b2 H H0 H1 H2 H3.
  induction H1; simpl.
  - rewrite <- app_nil_end. f_equal. rewrite map_map. induction H3; simpl; try rewrite IHWF_AType; f_equal; destruct a, a0, a1; simpl; f_equal; try lca; rewrite app_assoc; easy.
  - rewrite map_app, map_map. rewrite IHWF_AType, <- app_assoc. f_equal.
    clear IHWF_AType. induction H3; simpl; try rewrite IHWF_AType; f_equal; destruct a, a0, a1; simpl; f_equal; try lca; rewrite app_assoc; easy.
Qed.


Lemma gTensorA_assoc : forall (n : nat) (a1 a2 a3 : AType n),
  WF_AType n a1 -> WF_AType n a2 -> WF_AType n a3 ->
  gTensorA (gTensorA a1 a2) a3 = gTensorA a1 (gTensorA a2 a3).
Proof. intros n a1 a2 a3 H H0 H1. 
  induction H; induction H0; induction H1; simpl in *; f_equal; try apply (gTensorT_assoc a a0 a1); try rewrite IHWF_AType; try easy; repeat rewrite <- app_nil_end in *; try rewrite map_app; try rewrite map_map.
  1,2: f_equal; clear IHWF_AType; clear IHWF_AType0; induction H3; simpl; try rewrite IHWF_AType; f_equal; destruct a, a0, a2; simpl; f_equal; try lca; rewrite app_assoc; easy.
  + rewrite <- IHWF_AType. rewrite gTensorA_assoc_map; try easy; constructor; easy.
  + clear IHWF_AType1. clear IHWF_AType0.
    rewrite <- IHWF_AType. rewrite <- app_assoc. f_equal.
    * clear IHWF_AType; induction H4; simpl; try rewrite IHWF_AType; f_equal; destruct a, a0, a2; simpl; f_equal; try lca; rewrite app_assoc; easy.
    * rewrite gTensorA_assoc_map; try easy; constructor; easy.
Qed.


Lemma neg_tensor_dist_l : forall {n m} (A : PType n) (B : PType m), 
  WF_APType A -> WF_APType B -> 
  -A .⊗ B = - (A .⊗ B).
Proof. intros.
       inversion H; inversion H0; subst.
       destruct A; destruct B; try easy.
       inversion H2; inversion H5; subst.
       clear H. clear H0. clear H1. clear H4. clear H2. clear H5.
       simpl. f_equal.
       induction H6; induction H8; simpl in *; f_equal; try rewrite IHWF_AType; try easy.
       1 - 4 : destruct a, a0; simpl; f_equal; lca.
       unfold gScaleA. rewrite map_app, map_map. f_equal.
       clear IHWF_AType. clear IHWF_AType0. induction H8; simpl; f_equal.
       1, 2 : destruct a, a1; simpl; f_equal; lca.
       easy.
Qed.


Lemma neg_tensor_dist_r : forall {n m} (A : PType n) (B : PType m), 
  WF_APType A -> WF_APType B -> 
  A .⊗ (-B) = - (A .⊗ B).
Proof. intros. 
       inversion H; inversion H0; subst.
       destruct A; destruct B; try easy.
       inversion H2; inversion H5; subst.
       clear H. clear H0. clear H1. clear H4. clear H2. clear H5.
       simpl. f_equal.
       induction H6; induction H8; simpl in *; f_equal; try rewrite IHWF_AType; try easy.
       1 - 4 : destruct a, a0; simpl; f_equal; lca.
       unfold gScaleA. rewrite map_app, map_map. f_equal.
       clear IHWF_AType. clear IHWF_AType0. induction H8; simpl; f_equal.
       1, 2 : destruct a, a1; simpl; f_equal; lca.
       easy.
Qed.


Lemma i_tensor_dist_l : forall {n m} (A : PType n) (B : PType m), 
  WF_APType A -> WF_APType B -> 
  i A .⊗ B = i (A .⊗ B).
Proof. intros.
       inversion H; inversion H0; subst.
       destruct A; destruct B; try easy.
       inversion H2; inversion H5; subst.
       clear H. clear H0. clear H1. clear H4. clear H2. clear H5.
       unfold i. simpl. f_equal.
       induction H6; induction H8; simpl in *; f_equal; try rewrite IHWF_AType; try easy.
       1 - 4 : destruct a, a0; simpl; f_equal; lca.
       unfold gScaleA. rewrite map_app, map_map. f_equal.
       clear IHWF_AType. clear IHWF_AType0. induction H8; simpl; f_equal.
       1, 2 : destruct a, a1; simpl; f_equal; lca.
       easy.
Qed.


Lemma i_tensor_dist_r : forall {n m} (A : PType n) (B : PType m), 
  WF_APType A -> WF_APType B -> 
  A .⊗ i B = i (A .⊗ B).
Proof. intros.
       inversion H; inversion H0; subst.
       destruct A; destruct B; try easy.
       inversion H2; inversion H5; subst.
       clear H. clear H0. clear H1. clear H4. clear H2. clear H5.
       unfold i. simpl. f_equal.
       induction H6; induction H8; simpl in *; f_equal; try rewrite IHWF_AType; try easy.
       1 - 4 : destruct a, a0; simpl; f_equal; lca.
       unfold gScaleA. rewrite map_app, map_map. f_equal.
       clear IHWF_AType. clear IHWF_AType0. induction H8; simpl; f_equal.
       1, 2 : destruct a, a1; simpl; f_equal; lca.
       easy.
Qed.



(*
(** **Multiplication & Tensor Laws *)

(* Appropriate restriction is that size A = size C and size B = size D,
   but axiomatization doesn't allow for that calculation. *)
(* This should be generalizable to the other, assuming we're multiplying
   valid types. *)
Lemma mul_tensor_dist : forall {n m} (A C : PType n) (B D : PType m),
  WF_APType A -> WF_APType B -> WF_APType C -> WF_APType D ->
  (A .⊗ B) .* (C .⊗ D) = (A .* C) .⊗ (B .* D).
Proof. intros.
       destruct A; destruct B; destruct C; destruct D; try easy;
       inversion H; inversion H0; inversion H1; inversion H2;
       inversion H4; inversion H7; inversion H10; inversion H13;       
       inversion H16; inversion H18; inversion H20; inversion H22; subst;
       unfold mul, tensor; f_equal.
       rewrite gMulT_gTensorT_dist; easy. 
Qed.



Lemma decompose_tensor : forall (A B : PType 1),
  WF_APType A -> WF_APType B ->
  A .⊗ B = (A .⊗ I) .* (I .⊗ B).
Proof.
  intros A B H H0.  
  rewrite mul_tensor_dist; auto with wfpt_db.
  rewrite mul_I_r, mul_I_l; easy.
Qed.


Lemma decompose_tensor_mult_l : forall (A B : PType 1),
  WF_APType A -> WF_APType B ->
  (A .* B) .⊗ I = (A .⊗ I) .* (B .⊗ I).
Proof.
  intros. 
  rewrite mul_tensor_dist; auto with wfpt_db.
Qed.


Lemma decompose_tensor_mult_r : forall (A B : PType 1),
  WF_APType A -> WF_APType B ->
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

(*** Paulis can be derived ***)
(*
Inductive prog :=
| H (n : nat)
| I (n : nat)
| X (n : nat)
| Y (n : nat)
| Z (n : nat)
| S (n : nat)
| T (n : nat)
| CNOT (n1 n2 : nat)
| seq (p1 p2 : prog).
 *)

Infix ";;" := seq (at level 51, right associativity).

Fixpoint translate_prog (prg_len : nat) (p : prog) : Square (2^prg_len) :=
  match p with 
  | H' n => (prog_smpl_app prg_len hadamard n)
  | I'' n => (prog_smpl_app prg_len (Matrix.I 2) n)
  | X'' n => (prog_smpl_app prg_len σx n)
  | Y'' n => (prog_smpl_app prg_len σy n)
  | Z'' n => (prog_smpl_app prg_len σz n)
  | S' n => (prog_smpl_app prg_len Phase n)
  | T' n => (prog_smpl_app prg_len (phase_shift (PI / 4)) n)
  | CNOT' n1 n2 => (prog_ctrl_app prg_len σx n1 n2)
  | seq p1 p2 => (translate_prog prg_len p2) × (translate_prog prg_len p1)
  end.

Lemma unit_prog : forall (prg_len : nat) (p : prog), 
  WF_Unitary (translate_prog prg_len p).
Proof. intros. induction p as [ | | | | | | | | ];
       try (apply unit_prog_smpl_app; auto with unit_db);
       try (apply unit_prog_ctrl_app; auto with unit_db);
       simpl. apply Mmult_unitary; easy.
Qed.


Inductive progHasSingType {prg_len : nat} : prog -> PType prg_len -> PType prg_len -> Prop :=
| PHST : forall p T1 T2, Cap_vt T1 -> Cap_vt T2 -> 
  (translate_prog prg_len p) ::' [(translateP T1, translateP T2)] -> 
  progHasSingType p T1 T2.
(* should use two cons for PHT, one for arrow one for cap *)

Inductive progHasType {prg_len : nat} : prog -> PType prg_len -> Prop :=
| Arrow_pht : forall p T1 T2, progHasSingType p T1 T2 -> progHasType p (Arrow T1 T2)
| Cap_pht : forall p T1 T2, progHasType p T1 -> progHasType p T2 -> progHasType p (Cap T1 T2).

Notation "p :' T" := (progHasType p T).



Lemma arrow_equiv : forall {n} (A A' B B' : PType n) (C : prog), A ≡ B -> A' ≡ B' -> C :' A → A' -> C :' B → B'.
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

Lemma arrow_add_comm_l : forall {n} (A A' B : PType n) (c : Coef) (C : prog), C :' c .· (A .+ A') → B ->  C :' c .· (A' .+ A) → B.
Proof. intros n A A' B c C H.
       apply arrow_equiv with (A:=c .·(A .+ A')) (A':=B).
       apply add_comm. apply reflexivity.
       assumption.
Qed.

Lemma arrow_add_comm_r : forall {n} (A B B' : PType n) (c : Coef) (C : prog), C :' A → c .· (B .+ B') ->  C :' A → c .· (B' .+ B).
Proof. intros n A B B' c C H.
       apply arrow_equiv with (A:=A) (A':=c .· (B .+ B')).
       apply reflexivity. apply add_comm.
       assumption.
Qed.

Hint Resolve arrow_equiv arrow_add_comm_l arrow_add_comm_r : typing_db.



Definition types_equiv {n} (A B : PType n) := forall C,  C :' A <-> C :' B.

Lemma eq_types_equiv_refl : forall {n} (A : PType n), types_equiv A A.
Proof. intros n A. 
       easy.
Qed.

Lemma eq_types_equiv_sym : forall {n} (A B : PType n), types_equiv A B -> types_equiv B A.
Proof. intros n A B H. 
       easy. 
Qed.

Lemma eq_types_equiv_trans : forall {n} (A B C : PType n),
    types_equiv A B -> types_equiv B C -> types_equiv A C.
Proof.
  intros n A B C HAB HBC.
  unfold types_equiv in *.
  intros C0.
  split; intros.
  - rewrite HAB in H. rewrite HBC in H. easy.
  - rewrite HAB. rewrite HBC. easy.
Qed.

Add Parametric Relation n : (PType n) (@types_equiv n)
    reflexivity proved by eq_types_equiv_refl
    symmetry proved by eq_types_equiv_sym
    transitivity proved by eq_types_equiv_trans
    as eq_types_equiv_rel.

Add Parametric Morphism (n : nat) : Arrow
  with signature @eq_PType n ==> @eq_PType n ==> @types_equiv n as PType_Arr_mor.      Proof.
  intros.
  split; apply arrow_equiv; easy.
Qed.

(** rewrite H should work. **)
Lemma test : forall n (A A' A'' B : PType n) C, A ≡ A' -> A' ≡ A'' -> C :' A'' → B -> C :' A → B.
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

Lemma SeqTypes : forall {n} (g1 g2 : prog) (A B C : PType n),
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


Lemma seq_assoc : forall {n} (g1 g2 g3 : prog) (T : PType n),
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
Lemma cap_elim_l : forall {n} (g : prog) (A B : PType n), g :' A ∩ B -> g :' A.
Proof. intros. inversion H; easy. Qed.

Lemma cap_elim_r : forall {n} (g : prog) (A B : PType n), g :' A ∩ B -> g :' B.
Proof. intros. inversion H; easy. Qed.

Lemma cap_intro : forall {n} (g : prog) (A B : PType n), g :' A -> g :' B -> g :' A ∩ B.
Proof. intros. apply Cap_pht; easy.
Qed.

Lemma cap_arrow : forall {n} (g : prog) (A B C : PType n),
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



Lemma arrow_sub : forall {n} g (A A' B B' : PType n),
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

Lemma cap_elim : forall {n} g (A B : PType n), g :' A ∩ B -> g :' A /\ g :' B.
Proof. eauto with subtype_db. Qed.


Lemma input_cap_l : forall {n} g (A A' B : PType n), 
  Cap_vt A' ->  g :' A → B -> g :' (A ∩ A') → B. 
Proof. intros. 
       inversion H0; inversion H3.
       apply (arrow_sub g A (A ∩ A') B B); auto. 
       apply Cap_cvt; auto.
       intros. 
       eauto with subtype_db.
Qed.

Lemma input_cap_r : forall {n} g (A A' B : PType n), 
  Cap_vt A' ->  g :' A → B -> g :' (A' ∩ A) → B. 
Proof. intros. 
       inversion H0; inversion H3.
       apply (arrow_sub g A (A' ∩ A) B B); auto. 
       apply Cap_cvt; auto.
       intros. 
       eauto with subtype_db.
Qed.

(* Full explicit proof (due to changes to arrow_sub) *)
Lemma cap_arrow_distributes : forall {n} g (A A' B B' : PType n),
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


Lemma arrow_add : forall {n} g (A A' B B' : PType n),
    uni_vecType (translateP A) ->
    uni_vecType (translateP A') ->
    uni_vecType (translateP B) ->
    uni_vecType (translateP B') ->
    WF_APType A -> WF_APType A' ->
    WF_APType B -> WF_APType B' ->
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
         try (apply unit_PType); try easy.
Qed.

Lemma arrow_mul : forall {n} g (A A' B B' : PType n),
    uni_vecType (translateP A) ->
    uni_vecType (translateP A') ->
    uni_vecType (translateP B) ->
    uni_vecType (translateP B') ->
    WF_APType A -> WF_APType A' ->
    WF_APType B -> WF_APType B' ->
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
       try (apply unit_PType); try easy.
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
       apply arrow_mul; try easy; try apply WFA; try apply G_apt; try apply WF_G; try apply WF_AP_Sing; unfold WF_TType; simpl; try lia;
         unfold translateP, translateA, translate, translate_P, uni_vecType; simpl; intros; try destruct H1; try contradiction; rewrite Mplus_0_l, Mscale_1_l, kron_1_r in H1; rewrite <- H1; [induction a | induction a' | induction b | induction b']; unfold WF_Unitary; split; auto with wf_db; lma'.
Qed.



Lemma arrow_scale : forall {n} (p : prog) (A A' : PType n) (c : Coef),
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


Lemma arrow_scale_eq : forall n (p : prog) (A A' : PType n) (c : Coef),
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

Lemma arrow_scale_eq' : forall n (p : prog) (A A' : PType n) (c : Coef),
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


Lemma arrow_i : forall {n} (p : prog) (A A' : PType n),
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


Lemma arrow_neg : forall n (p : prog) (A A' : PType n),
  p :' A → - A' ->
  p :' -A → A'.
Proof. intros.
  eapply arrow_scale_eq with (c:=Copp C1);
    try apply C0_fst_neq; simpl; try lra.
  rewrite neg_inv; assumption.       
Qed.



Lemma arrow_neg_eq : forall n (p : prog) (A A' : PType n),
    p :' -A → A' <-> p :' A → -A'.
Proof. intros n p A A'. split; intros;
         rewrite arrow_scale_eq with (c := Copp C1);
         try rewrite neg_inv;
         try assumption;
         try apply C0_fst_neq; simpl; lra.
Qed.


Lemma arrow_neg_eq' : forall n (p : prog) (A A' : PType n),
    p :' A → A' <-> p :' -A → -A'.
Proof. intros n p A A'. split; intros;
    [apply arrow_scale | apply arrow_scale with (c := Copp C1) in H];
    try rewrite 2 neg_inv in H;
    try assumption;
    try apply C0_fst_neq; simpl; lra.
Qed.



(* basically just eq_type_conv_output but with different order hypotheses *)
Lemma eq_arrow_r : forall {n} (g : prog) (A B B' : PType n),
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
  (c1 * c1 ^*)%C = C1 -> (c2 * c2 ^*)%C = C1 -> prg_len <> 0 ->
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
         replace  (c1 * c2 * (c1 * c2) ^* )%C with  ((c1 * c1 ^*) * (c2 * c2 ^*))%C by lca.
         rewrite H, H0; lca.
         lia.                                            
         do 2 rewrite switch_len; easy.
         apply IHl; auto; lia.
Qed.



(****************)
(* tensor rules *)
(****************)


(** old version lemma

Lemma WFS_nth_PType : forall {n} (A : PType n) (bit : nat),
  WF_TPType A -> WF_TPType (nth_PType bit A).
Proof. intros.
       inversion H; subst. 
       destruct A; try easy.
       apply WFS.
       apply G_tpt.
       apply WF_G; apply WF_tt.
       easy. 
Qed.       


Lemma WFS_switch_PType : forall {n} (A : PType n) (a : PType 1) (bit : nat),
  WF_TPType A -> WF_TPType a -> WF_TPType (switch_PType A a bit).
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


Hint Resolve WFS_nth_PType WFS_switch_PType : wfpt_db.



Lemma tensor_smpl : forall (prg_len bit : nat) (p : nat -> prog)
                           (A : PType prg_len) (a : PType 1),
    WF_TPType a -> WF_TPType A -> 
    smpl_prog p -> bit < prg_len ->
    (p 0) :' (nth_PType bit A) → a ->
    (p bit) :'  A → (switch_PType A a bit).
Proof. intros. 
       inversion H; inversion H0; subst. 
       inversion H5; inversion H8; subst; try easy. 
       destruct tt; destruct tt0; simpl. 
       inversion H6; inversion H10; subst.  
       apply tensor_smpl_ground; auto; simpl in *.
       do 2 (destruct l; try easy).
Qed.




Lemma tensor_ctrl : forall (prg_len ctrl targ : nat)   
                           (A : PType prg_len) (a b : PType 1),
  WF_TPType A -> WF_TPType a -> WF_TPType b -> 
  ctrl < prg_len -> targ < prg_len -> ctrl <> targ -> 
  (CNOT 0 1) :' (nth_PType ctrl A) .⊗ (nth_PType targ A) → a .⊗ b ->
  (CNOT ctrl targ) :'  A → switch_PType (switch_PType A a ctrl) b targ.
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
                                                     

Definition nth_PType {n} (bit : nat) (A : PType n) : PType 1 :=
  match A with 
  | G a => G (nth_AType bit a)
  | _ => Err
  end. 
                                                     
(** original
Definition nth_PType {n} (bit : nat) (A : PType n) : PType 1 :=
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
Definition switch_PType {n} (A : PType n) (a : PType 1) (bit : nat) : PType n :=
  match A with 
  | G g =>
    match a with
    | G g0 => G (switch_AType g g0 bit)
    | _ => Err
    end
  | _ => Err
  end.

(** original
Definition switch_PType {n} (A : PType n) (a : PType 1) (bit : nat) : PType n :=
  match A with 
  | G g =>
    match a with
    | G g0 => G (cMul (fst g) (fst g0), switch (snd g) (hd gI (snd g0))  bit)
    | _ => Err
    end
  | _ => Err
  end.
**)









Lemma WFS_nth_PType : forall {n} (A : PType n) (bit : nat),
  WF_TPType A -> WF_TPType (nth_PType bit A).
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


Lemma WFS_switch_PType : forall {n} (A : PType n) (a : PType 1) (bit : nat),
  WF_TPType A -> WF_TPType a -> WF_TPType (switch_PType A a bit).
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


Hint Resolve WFS_nth_PType WFS_switch_PType : wfpt_db.


Inductive Norm_is_one {n} : PType n -> Prop :=
| NIO : forall (c : Coef) (l : list Pauli), (c * c ^* )%C = C1 -> Norm_is_one (G ([(c,l)])).


Lemma single_tensor_smpl' : forall (prg_len bit : nat) (p : nat -> prog)
                             (A : PType prg_len) (c : Coef) (x : Pauli),
    (c * c^* )%C = C1 ->
    WF_TPType A -> 
    smpl_prog p -> bit < prg_len ->
    (p 0) :' (nth_PType bit A) → (G ([(c, [x])])) ->
    (p bit) :'  A → (switch_PType A (G([(c,[x])])) bit).
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


    (p 0) :' (nth_PType bit A) → a ->
    (p bit) :'  A → (switch_PType A a bit).


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

(*** typing determinism does not work for PTypes because Arithpauli types (additive types) are implemented as lists ***)
(**
(* This is probably too general and should be about Paulis only *)
Lemma typing_determinism : forall {n} U (A B B' : PType n),
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
     (c * c ^*)%C = C1 ->
    WF_Unitary (@translate 1 (c, [P])).
Proof. intros c P H.
       destruct P; unfold translate; simpl;
         apply unit_scale; try assumption; rewrite kron_1_r;
         auto with unit_db.
Qed.

Lemma WF_Unitary_translateA: forall (c : Coef) (P : Pauli),
    (c * c ^*)%C = C1 ->
    WF_Unitary (@translateA 1 ([(c, [P])])).
Proof. intros c P H.
       unfold translateA. simpl. rewrite Mplus_0_l. apply WF_Unitary_translate. assumption.
Qed.

Lemma uni_vecType_translateA: forall (c : Coef) (P : Pauli),
      (c * c ^*)%C = C1 ->
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
    (c * c ^*)%C = C1 -> (c1 * c1 ^*)%C = C1 -> (c2 * c2 ^*)%C = C1 ->
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

Lemma tensor_add : forall {n} U m (A B C : PType 1) (T : PType n),
    uni_vecType (translateP T) ->
    uni_vecType (translateP A) ->
    uni_vecType (translateP (B .+ C)) ->
    smpl_prog U -> m < n ->
    WF_TPType T -> WF_TPType A -> WF_TPType B -> WF_TPType C ->
    nth_PType m T = A ->
    (U 0) :' A → B .+ C ->
    (U m) :' T → (switch_PType T B m) .+ (switch_PType T C m).
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

    (p 0) :' (nth_PType bit A) → a ->
    (p bit) :'  A → (switch_PType A a bit).

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
     (c * c ^*)%C = C1 ->
    (forall P, H' 0 :' (@G 1 ([(C1, [P])])) → (@G 1 ([(c, [f P])]))) -> f gZ = gX.
Proof.
  intros f c NormOne H.
  specialize (H gZ).
  assert (H' 0 :' (@G 1 ([(C1, [gZ])])) → (@G 1 ([(C1, [gX])]))). { solve_ground_type. }
  apply (typing_determinism_Pauli (H' 0) C1 c C1 gZ _ _); auto; try lca; easy.
Qed.



(** bad with automation?, doesn't scale with AType types **) 
Lemma single_tensor_smpl : forall (prg_len bit : nat) (p : nat -> prog)
                             (A : PType prg_len) (a : PType 1),
    Norm_is_one a ->
    WF_TPType a -> WF_TPType A -> 
    smpl_prog p -> bit < prg_len ->
    (p 0) :' (nth_PType bit A) → a ->
    (p bit) :'  A → (switch_PType A a bit).
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
                             (A : PType prg_len) (a b : PType 1),
  Norm_is_one A -> Norm_is_one (a .⊗ b) ->
  WF_TPType A -> WF_TPType a -> WF_TPType b -> 
  ctrl < prg_len -> targ < prg_len -> ctrl <> targ -> 
  (CNOT' 0 1) :' (nth_PType ctrl A) .⊗ (nth_PType targ A) → a .⊗ b ->
  (CNOT' ctrl targ) :'  A → switch_PType (switch_PType A a ctrl) b targ.
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
Lemma WFA_nth_PType : forall {n} (A : PType n) (bit : nat),
  WF_APType A -> WF_APType (nth_PType bit A).
Proof. intros.
       inversion H; subst. 
       destruct A; try easy.
       apply WFA.
       constructor.
       constructor.
       inversion H1; subst.
       clear H. clear H0. clear H1.
       induction H3.
       do 2 constructor. lia. simpl. easy.
       constructor. constructor. lia. simpl. easy.
       assumption.
Qed.       


Inductive equal_len {n m : nat} : PType n -> PType m -> Prop :=
| Eq_len : forall (A : AType n) (a : AType m), length A = length a -> equal_len (G A) (G a).

(*** Admitted ***)
Lemma WFA_switch_PType : forall {n} (A : PType n) (a : PType 1) (bit : nat),
  equal_len A a ->
  WF_APType A -> WF_APType a -> WF_APType (switch_PType A a bit).
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

Hint Resolve WFA_nth_PType WFA_switch_PType : wfpt_db.
**)




(*
Inductive equal_len {n m : nat} : PType n -> PType m -> Prop :=
| Eq_len : forall (A : AType n) (a : AType m), length A = length a -> equal_len (G A) (G a).
(*** Admitted ***)
Lemma tensor_smpl : forall (prg_len bit : nat) (p : nat -> prog)
                      (A : PType prg_len) (a : PType 1),
   (* Norm_is_one a -> *) equal_len A a -> 
    WF_APType a -> WF_APType A -> 
    smpl_prog p -> bit < prg_len ->
    (p 0) :' (nth_PType bit A) → a ->
    (p bit) :' A → (switch_PType A a bit).
(* 

(p 0) :' (nth_PType bit A) → a ->
(H 0) :' (nth_PType 1 (X ⊗ X + Y ⊗ X)) → (Z + Z)
where (nth_PType 1 (X ⊗ X + Y ⊗ X)) = (X + X)


(p bit) :' A → (switch_PType A a bit).
(H 1) :' (X ⊗ X + Y ⊗ X) → (switch_PType (X ⊗ X + Y ⊗ X) (Z + Z) 1)
where (switch_PType (X ⊗ X + Y ⊗ X) (Z + Z) 1) = (X ⊗ Z + Y ⊗ Z) 



H 0 :' X -> Z

update 



*)


Proof. intros prg_len bit p A a (*G'*) E H H0 H1 H2 H3.
       (* inversion G'; subst. rename H4 into G'0. *)
       inversion H; inversion H0; subst. 
       inversion H5; inversion H8; subst; try easy.
       inversion E; subst.
       unfold switch_PType.
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
                           (A : PType prg_len) (a : PType 1),
    WF_APType a -> WF_APType A -> 
    smpl_prog p -> bit < prg_len ->
    (p 0) :' (nth_PType bit A) → a ->
    (p bit) :'  A → (switch_PType A a bit).
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
                           (A : PType prg_len) (a b : PType 1),
  WF_APType A -> WF_APType a -> WF_APType b -> 
  ctrl < prg_len -> targ < prg_len -> ctrl <> targ -> 
  (CNOT' 0 1) :' (nth_PType ctrl A) .⊗ (nth_PType targ A) → a .⊗ b ->
  (CNOT' ctrl targ) :'  A → switch_PType (switch_PType A a ctrl) b targ.
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


Lemma arrow_mul : forall {n} g (A A' B B' : PType n),
    WF_APType A -> WF_APType A' ->
    WF_APType B -> WF_APType B' ->
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
       try (apply unit_PType); try easy.
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
       apply arrow_mul; try easy; apply WFA; try apply G_tpt. 
       all : apply WF_G; apply WF_tt; easy. 
Qed.



Lemma arrow_scale : forall {n} (p : prog) (A A' : PType n) (c : Coef),
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


Lemma arrow_i : forall {n} (p : prog) (A A' : PType n),
  p :' A → A' ->
  p :' i A → i A'.
Proof. intros;
       apply arrow_scale;
       assumption.
Qed.


Lemma arrow_neg : forall {n} (p : prog) (A A' : PType n),
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
Lemma eq_arrow_r : forall {n} (g : prog) (A B B' : PType n),
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
         | |- TPType ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_PType ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- WF_APType ?A       => tryif is_evar A then fail else auto with wfpt_db
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
         | |- TPType ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_PType ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- WF_APType ?A       => tryif is_evar A then fail else auto with wfpt_db
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
         | |- TPType ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_PType ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- WF_APType ?A       => tryif is_evar A then fail else auto with wfpt_db
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
         | |- TPType ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_PType ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- WF_APType ?A       => tryif is_evar A then fail else auto with wfpt_db
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
         | |- TPType ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_PType ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- WF_APType ?A       => tryif is_evar A then fail else auto with wfpt_db
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
         | |- TPType ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_PType ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- WF_APType ?A       => tryif is_evar A then fail else auto with wfpt_db
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
         | |- TPType ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_PType ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- WF_APType ?A       => tryif is_evar A then fail else auto with wfpt_db
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
         | |- TPType ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_PType ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- WF_APType ?A       => tryif is_evar A then fail else auto with wfpt_db
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


       repeat (repeat (rewrite switch_PType_inc; auto with gt_db); 
         try rewrite switch_PType_base; try rewrite switch_PType_base_one;
           auto with gt_db).





       
       kill_

       
       type_check_base'.
       type_check_base'.
       


apply evSuper_ev; auto 50 with wfpt_db.
       unfold eq_PType; simpl.
       apply hd_inj; unfold uncurry; simpl. 
       apply TType_compare; auto; simpl.
       repeat (split; try lma').
       unfold translate






       

Check hd_inj.

       repeat (apply WFA_switch_PType'; auto 50 with wfpt_db).
       apply WFA_switch_PType'; auto 50 with wfpt_db.
       apply WFA_switch_PType'; auto with wfpt_db.


3 : {
         unfold eq_PType. simpl. 
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
        unfold eq_PType.
        simpl switch_PType'.
        unfold translate. simpl.
        apply hd_inj.
        crunch_matrix.
try easy.

       type_check_base'.

       2 : { simp_switch.


rewrite nth_vswitch_hit. try easy; try lia; auto with gt_db).
  repeat (rewrite nth_vswitch_miss; try easy; try lia; auto with gt_db). 

match goal with
         | |- ?g :' nth_PType ?n (switch_PType' _ _ ?n) → _ => 
                rewrite nth_vswitch_hit; try easy; try lia; auto with gt_db 
         | |- ?g :' nth_PType ?n (switch_PType' _ _ ?m) → _ => 
                rewrite nth_vswitch_miss; try easy; try nia; auto with gt_db
end.
match goal with
         | |- ?g :' nth_PType ?n (switch_PType' _ _ ?n) → _ => 
                rewrite nth_vswitch_hit; try easy; try lia; auto with gt_db 
         | |- ?g :' nth_PType ?n (switch_PType' _ _ ?m) → _ => 
                rewrite nth_vswitch_miss; try easy; try nia; auto with gt_db
end.



nth_PType bit (switch_PType' A a bit) = a.


       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_PType ?A       => tryif is_evar A then fail else auto with wfpt_db
         | |- ?g :' ?A → ?B      => tryif is_evar B then fail else eapply eq_arrow_r
         | |- ?g :' - ?A → ?B    => apply arrow_neg
         | |- ?g :' i ?A → ?B    => apply arrow_i
         | |- context[?A ⊗



       econstructor; reflexivity.


       rewrite nth_vswitch_miss; try easy; try nia; auto with gt_db.
       rewrite nth_vswitch_hit; [| nia | | |]. try easy; try nia; auto with gt_db. 
       


rewrite nth_vswitch_hit; try easy; try lia; auto with gt_db. 


       simpl nth_PType.
       apply arrow_mul_1.
       solve [eauto with base_types_db].  
       solve [eauto with base_types_db].
       eapply tensor_ctrl. 
       simpl nth_PType. 
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

       simpl nth_PType. 
       assert (H : G 1 (p_1, [gMul gX gZ]) = X .* Z). 
       { easy. }
       rewrite H.
       type_check_base.
       eapply tensor_ctrl.
       apply prog_decompose_tensor; auto with wfpt_db.
       eapply eq_arrow_r.
       apply arrow_mul; auto with wfpt_db; try solve [eauto with base_types_db].
       5 : { simpl nth_PType.

       type_check_base.

repeat match goal with
         | |- TPType ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_PType ?A       => tryif is_evar A then fail else auto with wfpt_db
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
         | |- TPType _       => auto 50 with svt_db
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
         | |- TPType _       => auto 50 with svt_db
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
         | |- TPType _       => auto 50 with svt_db
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
         | |- TPType ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_PType ?A       => tryif is_evar A then fail else auto with wfpt_db
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
         | |- TPType ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_PType ?A       => tryif is_evar A then fail else auto with wfpt_db
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
         | |- TPType ?A       => tryif is_evar A then fail else auto 50 with svt_db
         | |- WF_PType ?A       => tryif is_evar A then fail else auto with wfpt_db
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
         | |- TPType _       => tryif is_evar A then fail else auto 50 with svt_db
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
         | |- TPType _       => auto 50 with svt_db
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
         | |- TPType _       => auto 50 with svt_db
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
         | |- TPType _       => auto 50 with svt_db
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
       simpl nth_PType.
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



emma prog_decompose_tensor : forall (p : prog) (A B : PType 1) (T : PType 2),
  TPType A -> WF_PType A ->
  TPType B -> WF_PType B ->
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



