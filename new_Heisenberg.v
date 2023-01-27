Require Import Psatz.  
Require Import String. 
Require Import Program.
Require Import List.

 
Require Export Complex.
Require Export Matrix.
Require Export Quantum.
Require Export Eigenvectors.

Require Export new_Helper.



(**************************************)
(* defining Heisenberg representation *)
(**************************************)


Declare Scope heisenberg_scope.
Delimit Scope heisenberg_scope with H.
Open Scope heisenberg_scope.



Notation vecType n := (list (Square n)). 


Definition singVecType {n : nat} (v : Vector n) (U : Square n) : Prop :=
  WF_Matrix v /\ exists λ, Eigenpair U (v, λ).


Definition vecHasType {n : nat} (v : Vector n) (ts: vecType n) : Prop := 
  forall (A : Square n), In A ts -> singVecType v A.

(* an alternate definition which helps with singleton tactics later *)
Fixpoint vecHasType' {n : nat} (v : Vector n) (ts: vecType n) : Prop := 
  match ts with  
  | [] => True
  | (t :: ts') => (singVecType v t) /\ vecHasType' v ts'
  end.

Lemma vecHasType_is_vecHasType' : forall (n : nat) (v : Vector n) (A : vecType n),
  vecHasType v A <-> vecHasType' v A.
Proof. intros n v A. split.
       - induction A as [| h]. 
         * easy. 
         * intros H.  
           simpl. split.
           + unfold vecHasType in H.
             apply H. 
             simpl; left; reflexivity. 
           + apply IHA. 
             unfold vecHasType in H. 
             unfold vecHasType; intros.
             apply H; simpl; right; apply H0.
       - induction A as [| h]. 
         * easy. 
         * intros [H1 H2].
           unfold vecHasType; intros.
           apply IHA in H2. 
           unfold vecHasType in H2. 
           destruct H as [H3 | H4].
           rewrite <- H3; apply H1.
           apply H2; apply H4.
Qed.


Notation "v :' T" := (vecHasType v T) (at level 61) : heisenberg_scope. 


Definition intersection_vec{n} (A B : vecType n) := A ++ B.
Notation "A ∩ B" := (intersection_vec A B) (at level 60, no associativity) : heisenberg_scope.

Hint Unfold intersection_vec : sub_db.


(*****************************)
(* Basic vectType operations *)
(*****************************)


(* Singleton says if a vectType is able to be multiplied, scaled, or kronned  *)
Definition Singleton {n : nat} (A : vecType n) :=
  match A with
  | [a] => True
  | _ => False
  end. 


(* helper lemma to immediatly turn singleton vecType into [a] form *)
Lemma singleton_simplify : forall {n} (A : vecType n),
  Singleton A -> exists (a : Square n), A = [a].
Proof. intros; destruct A. 
       easy. 
       destruct A.
       exists m. 
       reflexivity. 
       easy.
Qed.



(* multiplies every combination of lists A and B *)
Fixpoint mul {n : nat} (A B : vecType n) := 
  match A with
  | [] => [] 
  | (a :: as') => List.map (fun b => a × b) B ++ mul as' B
  end.


(* adds every combination of lists A and B *)
Fixpoint add {n : nat} (A B : vecType n) := 
  match A with
  | [] => [] 
  | (a :: as') => List.map (fun b => a .+ b) B ++ add as' B
  end.



Definition scale {n : nat} (c : C) (A : vecType n) := 
  List.map (fun a => c .* a) A. 


Definition i {n : nat} (A : vecType n) :=
  scale Ci A.

Definition neg {n : nat} (A : vecType n) :=
  scale (-1) A.

(* tensor similar to mul *)
Fixpoint tensor {n m : nat} (A : vecType n) (B : vecType m) : vecType (n * m) := 
  match A with
  | [] => [] 
  | (a :: as') => List.map (fun b => a ⊗ b) B ++ tensor as' B
  end.


Fixpoint big_tensor {n} (As : list (vecType n)) : 
  vecType (n^(length As)) := 
  match As with
  | [] => [I 1]
  | A :: As' => tensor A (big_tensor As')
  end.


Fixpoint tensor_n n {m} (A : vecType m) :=
  match n with
  | 0    => [I 1]
  | S n' => tensor (tensor_n n' A) A
  end.



Notation "- T" := (neg T) : heisenberg_scope. 
Infix "*'" := mul (at level 40, left associativity) : heisenberg_scope. 
Infix "+'" := add (at level 56, left associativity) : heisenberg_scope. 
Infix "⊗'" := tensor (at level 51, right associativity) : heisenberg_scope. 
Infix "·" := scale (at level 45, left associativity) : heisenberg_scope. 
Notation "n ⨂' A" := (tensor_n n A) (at level 30, no associativity) : heisenberg_scope.
Notation "⨂' A" := (big_tensor A) (at level 60): heisenberg_scope.

(*****************************************************)
(* helper lemmas to extract from mult, tensor, scale *)
(*****************************************************)


Lemma in_mult : forall {n} (p : Square n) (A B : vecType n),
  In p (A *' B) -> exists a b, In a A /\ In b B /\ p = a × b.
Proof. intros. induction A as [| h].
       - simpl in H. easy.
       - simpl in H.
         apply in_app_or in H; destruct H as [H | H].
         * apply in_map_iff in H. destruct H.
           exists h, x. split.
           simpl. left. easy. destruct H as [H H']. 
           split. apply H'. rewrite H; reflexivity.
         * apply IHA in H. do 2 (destruct H). 
           exists x, x0. 
           destruct H as [H1 H2].
           split. simpl. right; apply H1.
           apply H2.
Qed.


Lemma in_add : forall {n} (p : Square n) (A B : vecType n),
  In p (A +' B) -> exists a b, In a A /\ In b B /\ p = a .+ b.
Proof. intros. induction A as [| h].
       - simpl in H. easy.
       - simpl in H.
         apply in_app_or in H; destruct H as [H | H].
         * apply in_map_iff in H. destruct H.
           exists h, x. split.
           simpl. left. easy. destruct H as [H H']. 
           split. apply H'. rewrite H; reflexivity.
         * apply IHA in H. do 2 (destruct H). 
           exists x, x0. 
           destruct H as [H1 H2].
           split. simpl. right; apply H1.
           apply H2.
Qed.


Lemma in_tensor : forall {n m} (p : Square (n*m)) (A : vecType n) (B : vecType m),
  In p (A ⊗' B) -> exists a b, In a A /\ In b B /\ p = a ⊗ b.
Proof. intros. induction A as [| h].
       - simpl in H. easy.
       - simpl in H.
         apply in_app_or in H; destruct H as [H | H].
         * apply in_map_iff in H. destruct H.
           exists h, x. split.
           simpl. left. easy. destruct H as [H H']. 
           split. apply H'. rewrite H; reflexivity.
         * apply IHA in H. do 2 (destruct H). 
           exists x, x0. 
           destruct H as [H1 H2].
           split. simpl. right; apply H1.
           apply H2.
Qed.


Lemma in_scale : forall {n} (p : Square n) (c : C) (A : vecType n),
  In p (c · A) -> exists a, In a A /\ p = c .* a.
Proof. intros. induction A as [| h].
       - simpl in H. easy.
       - simpl in H.
         destruct H as [H | H].
         * exists h. split.
           left. easy.
           rewrite H. reflexivity.
         * apply IHA in H. do 2 (destruct H). 
           exists x. split.
           right. apply H.
           apply H0. 
Qed.


Lemma in_scale_rev : forall {n} (p : Square n) (c : C) (A : vecType n),
  In p A -> In (c .* p) (c · A).
Proof. intros. induction A as [| h].
       - simpl in H. easy.
       - simpl in H.
         destruct H as [H0 | H0].
         * left. rewrite H0. reflexivity.
         * right. apply IHA. apply H0.
Qed.

(******************)
(* Singleton laws *)
(******************)

Definition X' : vecType 2 := [σx].
Definition Z' : vecType 2 := [σz].
Definition I' : vecType 2 := [I 2].
Definition Zero' : vecType 2 := [@Zero 2 2].

Definition I_n (n : nat) : vecType n := [I n].


Lemma SI : Singleton I'. Proof. easy. Qed.
Lemma SX : Singleton X'. Proof. easy. Qed.
Lemma SZ : Singleton Z'. Proof. easy. Qed.
Lemma SI_n : forall (n : nat), Singleton (I_n n). Proof. easy. Qed.

Lemma S_neg : forall (n : nat) (A : vecType n), Singleton A -> Singleton (neg A).
Proof. intros n A H. 
       apply singleton_simplify in H.
       destruct H; rewrite H.
       easy.
Qed.

Lemma S_i : forall (n : nat) (A : vecType n), Singleton A -> Singleton (i A).
Proof. intros n A H.
       apply singleton_simplify in H.
       destruct H; rewrite H.
       easy.
Qed.

Lemma S_mul : forall (n : nat) (A B : vecType n), 
  Singleton A -> Singleton B -> Singleton (A *' B).
Proof. intros n A B HA HB.
       apply singleton_simplify in HA;
       apply singleton_simplify in HB;
       destruct HA; destruct HB; rewrite H, H0. 
       easy.
Qed. 

Lemma S_add : forall (n : nat) (A B : vecType n), 
  Singleton A -> Singleton B -> Singleton (A +' B).
Proof. intros n A B HA HB.
       apply singleton_simplify in HA;
       apply singleton_simplify in HB;
       destruct HA; destruct HB; rewrite H, H0. 
       easy.
Qed.

Lemma S_tensor : forall (n m : nat) (A : vecType n) (B : vecType m), 
  Singleton A -> Singleton B -> Singleton (A  ⊗' B).
Proof. intros n m A B HA HB.
       apply singleton_simplify in HA;
       apply singleton_simplify in HB;
       destruct HA; destruct HB; rewrite H, H0. 
       easy.
Qed. 

Lemma tensor_nil_l : forall (n m : nat) (A : vecType n), @tensor n m [] A = []. 
Proof. induction A as [| h].
       - easy. 
       - simpl. apply IHA. 
Qed.

Lemma tensor_nil_r : forall (n m : nat) (A : vecType n), @tensor n m A [] = []. 
Proof. induction A as [| h].
       - easy. 
       - simpl. apply IHA. 
Qed.


Lemma S_tensor_conv : forall (n m : nat) (A : vecType n) (B : vecType m), 
  Singleton (A  ⊗' B) -> Singleton A /\ Singleton B.
Proof. intros n m A B H.
       destruct A. easy.  
       destruct B. rewrite tensor_nil_r in H. easy.
       destruct A. destruct B.
       easy. easy. destruct B.  
       easy. easy. 
Qed. 

Lemma S_big_tensor : forall (n : nat) (As : list (vecType n)),
  (forall a, In a As -> Singleton a) -> Singleton (⨂' As).
Proof. intros. induction As as [| h].
       - easy. 
       - simpl. apply S_tensor. 
         apply H; left; easy.
         apply IHAs.
         intros. 
         apply H; right; apply H0.
Qed.

Lemma S_big_tensor_conv : forall (n : nat) (As : list (vecType n)) (a : vecType n),
  Singleton (⨂' As) -> In a As -> Singleton a.
Proof. intros. induction As as [| h].
       - easy. 
       - destruct H0 as [Hh | Ha]. 
         + simpl in H.
           apply S_tensor_conv in H.
           rewrite <- Hh; easy. 
         + apply IHAs.
           simpl in H.
           apply S_tensor_conv in H.
           easy. 
           apply Ha.
Qed.


Lemma S_tensor_subset : forall (n : nat) (As Bs : list (vecType n)),
  Singleton (⨂' As) -> Bs ⊆ As -> Singleton (⨂' Bs).
Proof. intros.
       unfold subset_gen in H0.
       apply S_big_tensor. 
       intros. 
       apply H0 in H1. 
       apply (S_big_tensor_conv n As a) in H.
       apply H.
       apply H1.
Qed.


Hint Resolve SI SX SZ SI_n S_neg S_i S_mul S_add S_tensor : sing_db.

Notation Y' := (i (X' *' Z')).

Lemma SY : Singleton Y'.
Proof. auto with sing_db. Qed.

(****************)
(* Unitary laws *)
(****************)


Definition uni_vecType {n : nat} (vt : vecType n) : Prop :=
  forall A, In A vt -> WF_Unitary A.


Lemma uni_vecType_cons : forall {n : nat} (a : Square n) (A : vecType n),
  uni_vecType (a :: A) -> WF_Unitary a /\ uni_vecType A.
Proof. intros.
       split. 
       - apply H.
         left; easy.
       - unfold uni_vecType in *.
         intros.
         apply H.
         right; easy.
Qed.
  
Lemma univ_I : uni_vecType I'. 
Proof. unfold uni_vecType. intros. 
       apply in_simplify in H; rewrite H. 
       auto with unit_db.
Qed.

Lemma univ_X : uni_vecType X'.
Proof. unfold uni_vecType. intros. 
       apply in_simplify in H; rewrite H. 
       auto with unit_db.
Qed.


Lemma univ_Z : uni_vecType Z'. 
Proof. unfold uni_vecType. intros. 
       apply in_simplify in H; rewrite H. 
       apply σz_unitary.
Qed.

Lemma univ_I_n : forall (n : nat), uni_vecType (I_n n). 
Proof. unfold uni_vecType. intros. 
       apply in_simplify in H; rewrite H. 
       auto with unit_db.
Qed.

Lemma univ_neg : forall (n : nat) (A : vecType n), uni_vecType A -> uni_vecType (neg A).
Proof. unfold uni_vecType in *.
       intros n A H a H1. unfold neg in H1.
       apply in_scale in H1. destruct H1 as [x [H1 H2]].
       apply H in H1. 
       destruct H1 as [H1 H3].
       rewrite H2. split; auto with wf_db. 
       rewrite Mscale_adj.
       distribute_scale. rewrite H3.
       lma. 
Qed.

Lemma univ_i : forall (n : nat) (A : vecType n), uni_vecType A -> uni_vecType (i A).
Proof. unfold uni_vecType in *.
       intros n A H a H1. unfold neg in H1.
       apply in_scale in H1. destruct H1 as [x [H1 H2]].
       apply H in H1. 
       destruct H1 as [H1 H3].
       rewrite H2. split; auto with wf_db. 
       rewrite Mscale_adj.
       distribute_scale. rewrite H3.
       lma. 
Qed.


Lemma univ_mul : forall (n : nat) (A B : vecType n), 
  uni_vecType A -> uni_vecType B -> uni_vecType (A *' B).
Proof. unfold uni_vecType in *.
       intros n A B HA HB ab Hab.
       apply in_mult in Hab.
       destruct Hab as [a [b [Ha [Hb Hab]]]].
       rewrite Hab.
       auto with unit_db.
Qed.


Lemma univ_tensor : forall (n m : nat) (A : vecType n) (B : vecType m),
  uni_vecType A -> uni_vecType B -> uni_vecType (A ⊗' B).
Proof. unfold uni_vecType in *.
       intros n m A B HA HB ab Hab.
       apply in_tensor in Hab.
       destruct Hab as [a [b [Ha [Hb Hab]]]].
       rewrite Hab.
       auto with unit_db.
Qed.

Local Open Scope nat_scope. 


(* alternate version that is sometimes necessary *)
Lemma univ_tensor' : forall (n m o : nat) (A : vecType n) (B : vecType m),
  n * m = o -> uni_vecType A -> uni_vecType B -> @uni_vecType o (A ⊗' B).
Proof. unfold uni_vecType in *.
       intros n m o A B H HA HB ab Hab.
       rewrite <- H.
       apply in_tensor in Hab.
       destruct Hab as [a [b [Ha [Hb Hab]]]].
       rewrite Hab.
       auto with unit_db.
Qed.

Lemma univ_tensor_list : forall (n : nat) (A : list (vecType n)),
  (forall a, In a A -> uni_vecType a) -> uni_vecType (⨂' A).
Proof. intros. 
       induction A as [| h].
       - simpl.
         replace [I 1] with (I_n 1) by auto. 
         apply univ_I_n.
       - simpl. 
         apply univ_tensor.
         apply (H h); left; auto. 
         apply IHA; intros. 
         apply H; right; auto.
Qed.

Hint Resolve univ_I univ_X univ_Z univ_I_n univ_neg univ_i univ_mul univ_tensor : univ_db.


Lemma univ_Y : uni_vecType Y'.
Proof. auto with univ_db. Qed.


Local Close Scope nat_scope. 

(***********************)
(* Multiplication laws *)
(***********************)

(* some helper lemmas *)

Lemma mul_sing : forall (n : nat) (a b : Square n),
    [a] *' [b] = [a × b].
Proof. reflexivity.
Qed.

Lemma mul_nil_l : forall (n : nat) (A : vecType n), [] *' A = [].
Proof. simpl. reflexivity. 
Qed.

Lemma mul_nil_r : forall (n : nat) (A : vecType n), A *' [] = [].
Proof. intros n A. induction A as [| a].
       - simpl. reflexivity. 
       - simpl. apply IHA.
Qed.

Lemma cons_into_mul_l : forall (n : nat) (a : Square n) (A B : vecType n),
    (a :: A) *' B = ([a] *' B) ++ (A *' B). 
Proof. intros n a A B. simpl.
       rewrite <- app_nil_end.
       reflexivity.
Qed.       

Lemma concat_into_mul_l : forall (n : nat) (A B C : vecType n),
    (A ++ B) *' C = (A *' C) ++ (B *' C). 
Proof. intros n A B C. induction A as [| a].
       - simpl. reflexivity. 
       - rewrite cons_into_mul_l.
         rewrite cons_conc. rewrite app_ass.
         rewrite <- cons_conc.
         rewrite cons_into_mul_l.
         rewrite IHA. rewrite app_ass.
         reflexivity.
Qed.

Lemma sing_concat_into_mul_l : forall (n : nat) (a : Square n) (B C : vecType n),
     (B ++ C) *' [a] = (B *' [a]) ++ (C *' [a]).
Proof. intros n a B C.
  induction B as [| b].
  - reflexivity.
  - simpl. rewrite IHB.
    reflexivity.
Qed.

Lemma sing_concat_into_mul_r : forall (n : nat) (a : Square n) (B C : vecType n),
    [a] *' (B ++ C) = ([a] *' B) ++ ([a] *' C).
Proof. intros n a B C. simpl.
       do 3 (rewrite <- app_nil_end).
       rewrite map_app.
       reflexivity.
Qed.


Lemma sing_mul_assoc : forall (n : nat) (a b : Square n) (C : vecType n),
    [a] *' [b] *' C = [a] *' ([b] *' C). 
Proof. intros n a b C. induction C as [| c].
       - simpl. reflexivity. 
       - rewrite (cons_conc _ c C).
         rewrite (sing_concat_into_mul_r n b [c] C).
         do 2 (rewrite mul_sing).
         rewrite (sing_concat_into_mul_r n _ [c] C).
         rewrite (sing_concat_into_mul_r n a _ _).
         rewrite <- IHC.
         do 3 (rewrite mul_sing).
         rewrite Mmult_assoc.
         reflexivity.
Qed.

Lemma sing_mul_assoc2 : forall (n : nat) (a : Square n) (B C : vecType n),
    [a] *' B *' C = [a] *' (B *' C). 
Proof. intros n a B C. induction B as [| b].
       - simpl. reflexivity. 
       - rewrite (cons_conc _ b B).
         rewrite sing_concat_into_mul_r. 
         do 2 (rewrite concat_into_mul_l).
         rewrite sing_concat_into_mul_r.
         rewrite sing_mul_assoc.
         rewrite IHB.
         reflexivity.
Qed.         


Theorem mul_assoc : forall (n : nat) (A B C : vecType n), A *' (B *' C) = A *' B *' C.
Proof. intros n A B C. induction A as [| a].
       - simpl. reflexivity. 
       - rewrite cons_conc.
         do 3 (rewrite concat_into_mul_l). 
         rewrite IHA.
         rewrite sing_mul_assoc2.
         reflexivity.
Qed.

Lemma mul_I_l : forall (A : vecType 2), uni_vecType A -> I' *' A = A.
Proof. intros A H. unfold I'. induction A as [| a].
       - reflexivity.
       - rewrite (cons_conc _ a A). 
         rewrite sing_concat_into_mul_r.
         apply uni_vecType_cons in H.
         destruct H as [[H _] H0].
         rewrite IHA; try easy.
         simpl.
         rewrite Mmult_1_l; easy.
Qed.

Lemma mul_I_r : forall (A : vecType 2), uni_vecType A -> A *' I' = A.
Proof. intros A H. unfold I'. induction A as [| a].
       - reflexivity.
       - rewrite cons_into_mul_l.
         apply uni_vecType_cons in H.
         destruct H as [[H _] H0].
         rewrite IHA; try easy.
         simpl.
         rewrite Mmult_1_r; try easy.
Qed.

Lemma scale_1_l : forall (n : nat) (A : vecType n), 1 · A = A.
Proof. intros n A. induction A as [|a].
       - reflexivity.
       - simpl. rewrite IHA.
         rewrite Mscale_1_l.
         reflexivity. 
Qed.

Lemma scale_assoc : forall (n : nat) (a b : C) (A : vecType n),
    a · (b · A) = (a * b) · A.
Proof. intros n a b A. induction A as [| h].
       - reflexivity.
       - simpl. rewrite IHA.
         rewrite Mscale_assoc.
         reflexivity.
Qed.
         

Lemma neg_inv : forall (n : nat) (A : vecType n),  - - A = A.
Proof. intros n A. unfold neg.
       rewrite scale_assoc.
       assert (H: -1 * -1 = 1). { lca. }
       rewrite H. rewrite scale_1_l. 
       reflexivity.
Qed.                                    

Lemma concat_into_scale : forall (n : nat) (c : C) (A B : vecType n),
    c · (A ++ B) = (c · A) ++ (c · B).
Proof. intros n c A B. 
       unfold scale. 
       rewrite map_app.
       reflexivity.
Qed. 

Lemma scale_sing : forall (n : nat) (c : C) (a : Square n),
    c · [a] = [c .* a].
Proof. reflexivity.
Qed.

Lemma sing_scale_dist_l : forall (n : nat) (c : C) (a : Square n) (B : vecType n),
    (c · [a]) *' B = c · ([a] *' B).
Proof. intros n c a B. induction B as [|b].
       - reflexivity.
       - rewrite (cons_conc _ b B).
         rewrite sing_concat_into_mul_r.
         rewrite concat_into_scale.
         rewrite scale_sing.
         rewrite sing_concat_into_mul_r.
         rewrite <- IHB. rewrite scale_sing.
         do 2 (rewrite mul_sing).
         rewrite scale_sing.
         rewrite Mscale_mult_dist_l.
         reflexivity.
Qed.

 
Lemma scale_dist_l : forall (n : nat) (c : C) (A B : vecType n), (c · A) *' B = c · (A *' B).
Proof. intros n c A B. induction A as [|a].
       - reflexivity.
       - rewrite cons_into_mul_l. rewrite cons_conc.
         do 2 (rewrite concat_into_scale).
         rewrite concat_into_mul_l.
         rewrite IHA. rewrite sing_scale_dist_l.
         reflexivity.
Qed.


(* note that this is slightly different than what we would expect. *)
(* scaling is on right, but singleton is still left list *)
Lemma sing_scale_dist_r : forall (n : nat) (c : C) (a : Square n) (B : vecType n),
    [a] *' (c · B) = c · ([a] *' B).
Proof. intros n c a B. induction B as [| b].
       - reflexivity.
       - rewrite (cons_conc _ b B).
         rewrite sing_concat_into_mul_r.
         do 2 (rewrite concat_into_scale).
         rewrite sing_concat_into_mul_r.
         rewrite IHB.
         rewrite scale_sing.
         do 2 (rewrite mul_sing).
         rewrite scale_sing.
         rewrite Mscale_mult_dist_r.
         reflexivity.
Qed.

Lemma scale_dist_r : forall (n : nat) (c : C) (A B : vecType n), A *' (c · B) = c · (A *' B).
Proof. intros n c A B. induction A as [|a].
       - reflexivity.
       - rewrite cons_into_mul_l.
         rewrite (cons_into_mul_l n a A B).
         rewrite concat_into_scale.
         rewrite IHA.
         rewrite sing_scale_dist_r.
         reflexivity.
Qed.


Lemma neg_dist_l : forall (n : nat) (A B : vecType n), -A *' B = - (A *' B).
Proof. intros n A B.
       unfold neg.
       rewrite scale_dist_l. reflexivity.
Qed.       
       
Lemma neg_dist_r : forall (n : nat) (A B : vecType n), A *' -B = - (A *' B).
Proof. intros n A B.
       unfold neg.
       rewrite scale_dist_r. reflexivity.
Qed.

Lemma i_sqr : forall (n : nat) (A : vecType n), i (i A) = -A.
Proof. intros n A. unfold neg. unfold i.
       rewrite scale_assoc.
       assert (H: Ci * Ci = -1). { lca. }
       rewrite H. 
       reflexivity.
Qed. 


Lemma i_dist_l : forall (n : nat) (A B : vecType n), i A *' B = i (A *' B).
Proof. intros n A B.
       unfold i.
       rewrite scale_dist_l. reflexivity.
Qed.

Lemma i_dist_r : forall (n : nat) (A B : vecType n), A *' i B = i (A *' B).
Proof. intros n A B.
       unfold i.
       rewrite scale_dist_r. reflexivity.
Qed.

Lemma i_neg_comm : forall (n : nat) (A : vecType n), i (-A) = -i A.
Proof. intros n A. unfold neg; unfold i.
       do 2 (rewrite scale_assoc).
       assert (H: Ci * -1 = -1 * Ci). 
       { lca. } rewrite H. reflexivity.
Qed.

Hint Rewrite  mul_sing mul_nil_r mul_I_l mul_I_r neg_inv scale_dist_l scale_dist_r neg_dist_l neg_dist_r i_sqr i_dist_l i_dist_r i_neg_comm : mul_db.



(***********************)
(* Addition laws *)
(***********************)

(* some helper lemmas *)

Lemma add_sing : forall (n : nat) (a b : Square n),
    [a] +' [b] = [a .+ b].
Proof. reflexivity.
Qed.

Lemma add_nil_l : forall (n : nat) (A : vecType n), [] +' A = [].
Proof. simpl. reflexivity. 
Qed.

Lemma add_nil_r : forall (n : nat) (A : vecType n), A +' [] = [].
Proof. intros n A. induction A as [| a].
       - simpl. reflexivity. 
       - simpl. apply IHA.
Qed.

Lemma cons_into_add_l : forall (n : nat) (a : Square n) (A B : vecType n),
    (a :: A) +' B = ([a] +' B) ++ (A +' B). 
Proof. intros n a A B. simpl.
       rewrite <- app_nil_end.
       reflexivity.
Qed.       

Lemma concat_into_add_l : forall (n : nat) (A B C : vecType n),
    (A ++ B) +' C = (A +' C) ++ (B +' C). 
Proof. intros n A B C. induction A as [| a].
       - simpl. reflexivity. 
       - rewrite cons_into_add_l.
         rewrite cons_conc. rewrite app_ass.
         rewrite <- cons_conc.
         rewrite cons_into_add_l.
         rewrite IHA. rewrite app_ass.
         reflexivity.
Qed.


Lemma sing_concat_into_add_r : forall (n : nat) (a : Square n) (B C : vecType n),
    [a] +' (B ++ C) = ([a] +' B) ++ ([a] +' C).
Proof. intros n a B C. simpl.
       do 3 (rewrite <- app_nil_end).
       rewrite map_app.
       reflexivity.
Qed.


Lemma sing_add_assoc : forall (n : nat) (a b : Square n) (C : vecType n),
    [a] +' [b] +' C = [a] +' ([b] +' C). 
Proof. intros n a b C. induction C as [| c].
       - simpl. reflexivity. 
       - rewrite (cons_conc _ c C).
         rewrite (sing_concat_into_add_r n b [c] C).
         do 2 (rewrite add_sing).
         rewrite (sing_concat_into_add_r n _ [c] C).
         rewrite (sing_concat_into_add_r n a _ _).
         rewrite <- IHC.
         do 3 (rewrite add_sing).
         rewrite Mplus_assoc.
         reflexivity.
Qed.

Lemma sing_add_assoc2 : forall (n : nat) (a : Square n) (B C : vecType n),
    [a] +' B +' C = [a] +' (B +' C). 
Proof. intros n a B C. induction B as [| b].
       - simpl. reflexivity. 
       - rewrite (cons_conc _ b B).
         rewrite sing_concat_into_add_r. 
         do 2 (rewrite concat_into_add_l).
         rewrite sing_concat_into_add_r.
         rewrite sing_add_assoc.
         rewrite IHB.
         reflexivity.
Qed.         


Theorem add_assoc : forall (n : nat) (A B C : vecType n), A +' (B +' C) = A +' B +' C.
Proof. intros n A B C. induction A as [| a].
       - simpl. reflexivity. 
       - rewrite cons_conc.
         do 3 (rewrite concat_into_add_l). 
         rewrite IHA.
         rewrite sing_add_assoc2.
         reflexivity.
Qed.

Lemma sing_add_comm : forall (n : nat) (a b : Square n),
    [a] +' [b] = [b] +' [a].
Proof. intros n a b.
       simpl. rewrite Mplus_comm. reflexivity.
Qed.

Lemma sing_add_comm2 : forall (n : nat) (a : Square n) (B : vecType n),
    [a] +' B = B +' [a].
Proof. intros n a B.
       simpl. rewrite <- app_nil_end.
       induction B as [| b B IHB].
       - reflexivity.
       - simpl. rewrite IHB. rewrite Mplus_comm. reflexivity.
Qed.



(* Impossible to prove since list is not a set
Theorem add_comm : forall (n : nat) (A B : vecType n), A +' B = B +' A.
*)



Lemma add_Zero_l : forall (A : vecType 2), uni_vecType A -> Zero' +' A = A.
Proof. intros A H. unfold Zero'. induction A as [| a].
       - reflexivity.
       - rewrite (cons_conc _ a A).
         rewrite sing_concat_into_add_r.
         apply uni_vecType_cons in H.
         destruct H as [[H _] H0].
         apply IHA in H0.
         rewrite H0.
         simpl. 
         rewrite Mplus_0_l; easy.
Qed.

Lemma add_Zero_r : forall (A : vecType 2), uni_vecType A -> A +' Zero' = A.
Proof. intros A H. unfold Zero'. induction A as [| a].
       - reflexivity.
       - rewrite cons_into_add_l.
         apply uni_vecType_cons in H.
         destruct H as [[H _] H0].
         rewrite IHA; try easy.
         simpl.
         rewrite Mplus_0_r; try easy.
Qed.


Lemma map_scale_dist_add : forall (n : nat) (c : C) (A B : vecType n) (a : Square n) ,
    map (fun b : Square n => c .* a .+ b) (map (fun a1 : Square n => c .* a1) B)
    = map (fun a1 : Square n => c .* a1) (map (fun b : Square n => a .+ b) B).
Proof.
  intros n c A B a.
  induction B as [| b].
  - reflexivity.
  - simpl. rewrite IHB.
    rewrite Mscale_plus_distr_r.
    reflexivity.
Qed.


Lemma scale_dist_add : forall (n : nat) (c : C) (A B : vecType n),
    c · (A +' B) = (c · A) +' (c · B).
Proof. intros n c A B. 
       unfold scale.
       induction A.
       - reflexivity.
       - simpl.
         rewrite <- IHA.
         rewrite map_app.
         induction B.
         + reflexivity.
         + simpl. rewrite (cons_conc _ a0 B).
           rewrite Mscale_plus_distr_r.
           rewrite map_scale_dist_add; try easy.
Qed.

Lemma neg_dist_add : forall (n : nat) (A B : vecType n), -(A +' B) = (-A) +' (-B).
Proof. intros n A B.
       unfold neg.
       rewrite scale_dist_add.  reflexivity.
Qed.       


Lemma i_dist_add : forall (n : nat) (A B : vecType n), i (A +' B) = (i A) +' (i B).
Proof. intros n A B.
       unfold i.
       rewrite scale_dist_add. reflexivity.
Qed.

(* impossible?
Lemma mult_add_dist : forall (n : nat) (A B C : vecType n), A *' (B +' C) = A *' B +' A *' C.
*)


Lemma map_mult_add_dist_l : forall (n : nat) (C : vecType n) (a b : Square n),
map (fun b0 : Square n => a × b0) (map (fun b0 : Square n => b .+ b0) C)
= map (fun b0 : Square n => a × b .+ b0) (map (fun b0 : Square n => a × b0) C).
Proof. intros n C a b.
  induction C as [| c].
  - reflexivity.
  - simpl. rewrite IHC. rewrite Mmult_plus_distr_l.
    reflexivity.
Qed.

Lemma mult_add_dist_l : forall (n : nat) (B C : vecType n) (a : Square n), [a] *' (B +' C) = [a] *' B +' [a] *' C.
Proof. intros n B C a.
  simpl.
  rewrite <- 3 app_nil_end.
  induction B as [| b].
  - reflexivity.
  - simpl. 
    induction C as [| c].
    + rewrite <- IHB. reflexivity.
    + simpl. rewrite <- Mmult_plus_distr_l.  rewrite map_app.
      rewrite IHB. simpl. rewrite map_mult_add_dist_l.
      reflexivity.
Qed.

Lemma map_mult_add_dist_r : forall (n : nat) (C : vecType n) (a b : Square n),
         map (fun b0 : Square n => b × a .+ b0) (C *' [a]) = map (fun b0 : Square n => b .+ b0) C *' [a]. 
Proof. intros n C a b.
  induction C.
  - reflexivity.
  - simpl. rewrite Mmult_plus_distr_r. rewrite IHC.
    reflexivity.
Qed.

Lemma mult_add_dist_r : forall (n : nat) (B C : vecType n) (a : Square n),  (B +' C) *' [a] = B *' [a] +'  C *' [a].
Proof. intros n B C a.
  induction B as [| b].
  - reflexivity.
  - simpl.
    induction C as [| c].
    + simpl. rewrite add_nil_r. rewrite mul_nil_l. rewrite add_nil_r. reflexivity.
    + simpl. simpl in IHB. rewrite <- IHB. rewrite <- Mmult_plus_distr_r.
      rewrite  sing_concat_into_mul_l.
      rewrite map_mult_add_dist_r.
      reflexivity.
Qed.

Hint Rewrite  add_sing add_nil_r add_Zero_l add_Zero_r  : add_db.



(***************)
(* Tensor Laws *)
(***************)


Lemma tensor_1_l : forall (n : nat) (A : vecType n),
  uni_vecType A -> [I 1] ⊗' A = A. 
Proof. intros. induction A as [| h].
       - easy. 
       - simpl in *.
         apply uni_vecType_cons in H.
         destruct H as [[H _] H0].
         rewrite kron_1_l; try easy.
         rewrite IHA; try easy.
Qed.


Lemma big_tensor_1_l : forall (n m : nat) (A : vecType n),
  uni_vecType A -> (@big_tensor m []) ⊗' A = A.
Proof. intros.
       assert (H' : forall m, (@big_tensor m []) = [I 1]).
       { easy. }
       rewrite H'.
       apply tensor_1_l.
       easy.
Qed.

   
(* basically, we need the same helper lemmas for tensoring *)
(* should all WF conditions, but I will assume all gates are well formed *)
Lemma tensor_sing : forall (m n : nat) (a : Square n) (b : Square m),
    [a] ⊗' [b] = [a ⊗ b].
Proof. reflexivity.
Qed.


Lemma cons_into_tensor_l : forall (m n : nat) (a : Square n) (A : vecType n) (B : vecType m),
    (a :: A) ⊗' B = ([a] ⊗' B) ++ (A ⊗' B). 
Proof. intros m n a A B. simpl.
       rewrite <- app_nil_end.
       reflexivity.
Qed.       

Lemma concat_into_tensor_l : forall (m n : nat) (A B : vecType n) (C : vecType m),
    (A ++ B) ⊗' C = (A ⊗' C) ++ (B ⊗' C). 
Proof. intros m n A B C. induction A as [| a].
       - simpl. reflexivity. 
       - rewrite cons_into_tensor_l.
         rewrite cons_conc. rewrite app_ass.
         rewrite <- cons_conc.
         rewrite cons_into_tensor_l.
         rewrite IHA. rewrite app_ass.
         reflexivity.
Qed.


Lemma sing_concat_into_tensor_r : forall (m n : nat) (a : Square m) (B C : vecType n),
    [a] ⊗' (B ++ C) = ([a] ⊗' B) ++ ([a] ⊗' C).
Proof. intros m n a B C. simpl.
       do 3 (rewrite <- app_nil_end).
       rewrite map_app.
       reflexivity.
Qed.


Lemma sing_tensor_assoc : forall (m n o : nat) (a : Square m) (b : Square n) (C : vecType o),
   WF_Matrix a -> WF_Matrix b -> uni_vecType C ->
   ([a] ⊗' [b]) ⊗' C = [a] ⊗' ([b] ⊗' C). 
Proof. intros m n o a b C H H0 H1. induction C as [| c].
       - simpl. reflexivity. 
       - rewrite (cons_conc _ c C).
         apply uni_vecType_cons in H1.
         destruct H1 as [H1 H2].
         rewrite (sing_concat_into_tensor_r n o b [c] C).
         do 2 (rewrite tensor_sing).
         rewrite (sing_concat_into_tensor_r _ o _ [c] C).
         rewrite (sing_concat_into_tensor_r _ _ a _ _).
         rewrite <- IHC; auto.
         do 3 (rewrite tensor_sing).
         rewrite kron_assoc; auto.
         destruct H1; auto. 
Qed.


Lemma sing_tensor_assoc2 : forall (m n o: nat) (a : Square m) (B : vecType n) (C : vecType o),
  WF_Matrix a -> uni_vecType B -> uni_vecType C ->
  ([a] ⊗' B) ⊗' C = [a] ⊗' (B ⊗' C). 
Proof. intros m n o a B C H H0 H1. induction B as [| b].
       - simpl. reflexivity. 
       - rewrite (cons_conc _ b B).
         apply uni_vecType_cons in H0.
         destruct H0 as [[H0 _] H2].
         rewrite sing_concat_into_tensor_r. 
         do 2 (rewrite concat_into_tensor_l).
         rewrite sing_concat_into_tensor_r.
         rewrite sing_tensor_assoc; auto.
         rewrite IHB; auto. 
Qed.         


Theorem tensor_assoc : forall (m n o: nat) (A : vecType m) (B : vecType n) (C : vecType o),  
  uni_vecType A -> uni_vecType B -> uni_vecType C -> 
  A ⊗' (B ⊗' C) = (A ⊗' B) ⊗' C. 
Proof. intros m n o A B C H H0 H1. induction A as [| a].
       - simpl. reflexivity. 
       - rewrite cons_conc.
         apply uni_vecType_cons in H.
         destruct H as [[H _] H2].
         do 3 (rewrite concat_into_tensor_l); auto. 
         rewrite IHA; auto. 
         rewrite sing_tensor_assoc2; auto. 
Qed.



Lemma sing_scale_tensor_dist_l : forall (n m : nat) (c : C) (a : Square n) (B : vecType m),
    (c · [a]) ⊗' B = c · ([a] ⊗' B).
Proof. intros n m c a B. induction B as [|b].
       - reflexivity.
       - rewrite (cons_conc _ b B).
         rewrite sing_concat_into_tensor_r.
         rewrite concat_into_scale.
         rewrite scale_sing.
         rewrite sing_concat_into_tensor_r.
         rewrite <- IHB. rewrite scale_sing.
         do 2 (rewrite tensor_sing).
         rewrite scale_sing.
         rewrite Mscale_kron_dist_l.
         reflexivity.
Qed.

 
Lemma scale_tensor_dist_l : forall (n m : nat) (c : C) (A : vecType n) (B : vecType m),
    (c · A) ⊗' B = c · (A ⊗' B).
Proof. intros n m c A B. induction A as [|a].
       - reflexivity.
       - rewrite cons_into_tensor_l. rewrite cons_conc.
         do 2 (rewrite concat_into_scale).
         rewrite concat_into_tensor_l.
         rewrite IHA. rewrite sing_scale_tensor_dist_l.
         reflexivity.
Qed.


(* note that this is slightly different than what we would expect. *)
(* scaling is on right, but singleton is still left list *)
Lemma sing_scale_tensor_dist_r : forall (m n : nat) (c : C) (a : Square n) (B : vecType m),
    [a] ⊗' (c · B) = c · ([a] ⊗' B).
Proof. intros m n c a B. induction B as [| b].
       - reflexivity.
       - rewrite (cons_conc _ b B).
         rewrite sing_concat_into_tensor_r.
         do 2 (rewrite concat_into_scale).
         rewrite sing_concat_into_tensor_r.
         rewrite IHB.
         rewrite scale_sing.
         do 2 (rewrite tensor_sing).
         rewrite scale_sing.
         rewrite Mscale_kron_dist_r.
         reflexivity.
Qed.

Lemma scale_tensor_dist_r : forall (m n : nat) (c : C) (A : vecType n) (B : vecType m),
    A ⊗' (c · B) = c · (A ⊗' B).
Proof. intros m n c A B. induction A as [|a].
       - reflexivity.
       - rewrite cons_into_tensor_l.
         rewrite (cons_into_tensor_l m n a A B).
         rewrite concat_into_scale.
         rewrite IHA.
         rewrite sing_scale_tensor_dist_r.
         reflexivity.
Qed.



Lemma neg_tensor_dist_l : forall (m n : nat) (A : vecType n) (B : vecType m),
  -A ⊗' B = - (A ⊗' B).
Proof. intros m n A B. unfold neg.
       rewrite scale_tensor_dist_l.
       reflexivity.
Qed.

Lemma neg_tensor_dist_r : forall (m n : nat) (A : vecType n) (B : vecType m),
  A ⊗' -B = - (A ⊗' B).
Proof. intros m n A B. unfold neg.
       rewrite scale_tensor_dist_r.
       reflexivity.
Qed.

Lemma i_tensor_dist_l : forall (m n : nat) (A : vecType n) (B : vecType m),
  i A ⊗' B = i (A ⊗' B).
Proof. intros m n A B. unfold i.
       rewrite scale_tensor_dist_l.
       reflexivity.
Qed.

Lemma i_tensor_dist_r : forall (m n : nat) (A : vecType n) (B : vecType m), 
  A ⊗' i B = i (A ⊗' B).
Proof. intros m n A B. unfold i.
       rewrite scale_tensor_dist_r.
       reflexivity.
Qed.


Hint Rewrite concat_into_tensor_l scale_tensor_dist_r scale_tensor_dist_l  neg_tensor_dist_l neg_tensor_dist_r i_tensor_dist_l i_tensor_dist_r : tensor_db.


(********************************)
(* Multiplication & Tensor Laws *)
(********************************)

Lemma mul_tensor_dist_sing : forall (m n : nat) 
  (a : Square m) (b : Square n) (c : Square m) (D : vecType n),
    ([a] ⊗' [b]) *' ([c] ⊗' D) = ([a] *' [c]) ⊗' ([b] *' D).
Proof. intros m n a b c D. induction D as [| d].
       - reflexivity.
       - rewrite (cons_conc _ d D).
         rewrite sing_concat_into_tensor_r, sing_concat_into_mul_r.
         rewrite mul_sing, tensor_sing.
         rewrite sing_concat_into_tensor_r.
         rewrite sing_concat_into_mul_r.
         rewrite <- mul_sing. rewrite <- tensor_sing.
         assert (H: ([a] ⊗' [b]) *' ([c] ⊗' [d]) = [a] *' [c] ⊗' [b] *' [d]).
         { simpl. rewrite kron_mixed_product. reflexivity. }
         rewrite H, IHD.
         reflexivity. 
Qed.         


Lemma mul_tensor_dist_sing2 : forall (m n : nat) 
  (a : Square m) (B : vecType n) (c : Square m) (D : vecType n),
    ([a] ⊗' B) *' ([c] ⊗' D) = ([a] *' [c]) ⊗' (B *' D).
Proof. intros m n a B c D. induction B as [| b].
       - reflexivity.
       - rewrite (cons_conc _ b B).
         rewrite sing_concat_into_tensor_r.
         rewrite concat_into_mul_l.
         rewrite concat_into_mul_l.
         rewrite mul_sing.
         rewrite sing_concat_into_tensor_r.
         rewrite <- mul_sing.
         rewrite IHB, mul_tensor_dist_sing.
         reflexivity.
Qed.

         

Lemma mul_tensor_dist : forall (m n : nat) 
  (A : vecType m) (B : vecType n) (C : vecType m) (D : vecType n),
    Singleton A ->
    Singleton C ->
    (A ⊗' B) *' (C ⊗' D) = (A *' C) ⊗' (B *' D).
Proof. intros m n A B C D H1 H2. 
       apply singleton_simplify in H1; destruct H1;
       apply singleton_simplify in H2; destruct H2.
       rewrite H, H0. 
       rewrite mul_tensor_dist_sing2.
       reflexivity. 
Qed.


Lemma decompose_tensor : forall (A B : vecType 2),
    Singleton A -> uni_vecType A ->
    Singleton B -> uni_vecType B ->
    A ⊗' B = (A ⊗' I') *' (I' ⊗' B).
Proof.
  intros.
  rewrite mul_tensor_dist;  auto with sing_db.
  rewrite mul_I_l, mul_I_r. 
  all : easy.  
Qed.

Lemma decompose_tensor_mult_l : forall (A B : vecType 2),
    Singleton A -> 
    Singleton B -> 
    (A *' B) ⊗' I' = (A ⊗' I') *' (B ⊗' I').
Proof.
  intros.
  rewrite mul_tensor_dist; auto with sing_db.
  rewrite mul_I_l.
  easy.
  auto with univ_db.
Qed.

Lemma decompose_tensor_mult_r : forall (A B : vecType 2),
    I' ⊗' (A *' B) = (I' ⊗' A) *' (I' ⊗' B).
Proof.
  intros.
  rewrite mul_tensor_dist; auto with sing_db.
  rewrite mul_I_l.
  easy.
  auto with univ_db.
Qed.


(********************************)
(* Addition & Tensor Laws *)
(********************************)

                                                          
(*
Lemma add_tensor_dist_l : forall (m n : nat) (A B : vecType n) (C : vecType m),
    (A +' B) ⊗' C = (A ⊗' C) +' (B ⊗' C).
 *)

Lemma map_add_tensor_dist_sing_r : forall (m n : nat) (a : Square n) (B : vecType n) (c : Square m),
    map (fun b : Square n => a .+ b) B ⊗' [c] = map (fun b : Square (n * m) => a ⊗ c .+ b) (B ⊗' [c]).
Proof. intros m n a B c.
  induction B as [| b].
  - reflexivity.
  - simpl. rewrite IHB. rewrite kron_plus_distr_r. reflexivity.
Qed.

Lemma add_tensor_dist_sing_r : forall (m n : nat) (A B : vecType n) (c : Square m),
    (A +' B) ⊗' [c] = (A ⊗' [c]) +' (B ⊗' [c]).
Proof. intros m n A B c.
  induction A as [| a].
  - reflexivity.
  - simpl. rewrite concat_into_tensor_l. rewrite <- IHA.
    rewrite map_add_tensor_dist_sing_r. reflexivity.
Qed.

Lemma add_tensor_dist_r : forall (m n : nat) (A B : vecType n) (C : vecType m),
    Singleton C ->  (A +' B) ⊗' C = (A ⊗' C) +' (B ⊗' C).
Proof. intros m n A B C H.
  apply singleton_simplify in H.
  destruct H.
  rewrite H.
  apply add_tensor_dist_sing_r.
Qed.

Lemma map_add_tensor_dist_sing_l : forall (m n : nat) (a : Square n) (b : Square m) (C : vecType m),
    map (fun b0 : Square m => a ⊗ b0) (map (fun b0 : Square m => b .+ b0) C)
    = map (fun b0 : Square (n * m) => a ⊗ b .+ b0) (map (fun b0 : Square m => a ⊗ b0) C).
Proof. intros m n a b C.
  induction C as [| c].
  - reflexivity.
  - simpl. rewrite <- kron_plus_distr_l. rewrite IHC.
    reflexivity.
Qed.

Lemma add_tensor_dist_sing_l : forall (m n : nat) (a : Square n) (B C : vecType m),
    [a] ⊗' (B +' C) = ([a] ⊗' B) +' ([a] ⊗' C).
Proof. intros m n a B C.
  simpl.
  rewrite <- ! app_nil_end.
  induction B as [| b].
  - reflexivity.
  - simpl. 
    induction C as [| c].
    + simpl. rewrite ! add_nil_r. reflexivity.
    + simpl. rewrite <- kron_plus_distr_l.
      rewrite map_app.
      rewrite IHB. simpl.
      rewrite map_add_tensor_dist_sing_l.
      reflexivity.
Qed.

Lemma add_tensor_dist_l : forall (m n : nat) (A : vecType n) (B C : vecType m),
    Singleton A -> A ⊗' (B +' C) = (A ⊗' B) +' (A ⊗' C).
Proof. intros m n A B C H.
  apply singleton_simplify in H.
  destruct H.
  rewrite H.
  apply add_tensor_dist_sing_l.
Qed.





(********************)
(* Simplification Rules *)
(********************)


Ltac normalize_mul :=
  repeat match goal with
  | |- context[(?A ⊗ ?B) ⊗ ?C] => rewrite <- (tensor_assoc A B C)
  end;
  repeat (rewrite mul_tensor_dist by auto with sing_db);
  repeat rewrite mul_assoc;
  repeat (
      try rewrite <- (mul_assoc _ X' Z' _);
      autorewrite with mul_db tensor_db;
      try rewrite mul_assoc; auto with sing_db; auto with univ_db).

Lemma Xsqr : X' *' X' = I'.
Proof. simpl. unfold I'. rewrite XtimesXid. reflexivity.
Qed.

Lemma Ysqr : Y' *' Y' = I'.
Proof. simpl. unfold I'. f_equal. lma'. 
Qed.

Lemma Zsqr : Z' *' Z' = I'.
Proof. simpl. unfold I'. rewrite ZtimesZid. reflexivity.
Qed.

Lemma XmulI : X' *' I' = X'.
Proof. simpl. unfold I'. rewrite Mmult_1_r; auto with wf_db.
Qed.

Lemma YmulI : Y' *' I' = Y'.
Proof. simpl. unfold I'. rewrite Mmult_1_r; auto with wf_db.
Qed.

Lemma ZmulI : Z' *' I' = Z'.
Proof. simpl. unfold I'. rewrite Mmult_1_r; auto with wf_db.
Qed.

Lemma ImulX : I' *' X' = X'.
Proof. simpl. unfold I'. rewrite Mmult_1_l; auto with wf_db.
Qed.

Lemma ImulY : I' *' Y' = Y'.
Proof. simpl. unfold I'. rewrite Mmult_1_l; auto with wf_db.
Qed.

Lemma ImulZ : I' *' Z' = Z'.
Proof. simpl. unfold I'. rewrite Mmult_1_l; auto with wf_db.
Qed.

Lemma ZmulX : Z' *' X' = i Y'.
Proof. simpl. f_equal. lma'.
Qed.

Lemma XmulZ : X' *' Z' = -i Y'. Proof. normalize_mul. Qed.
Lemma XmulY : X' *' Y' = i Z'. Proof. simpl. f_equal. lma'. Qed.
Lemma YmulX : Y' *' X' = -i Z'. Proof. simpl. f_equal. lma'. Qed.
Lemma ZmulY : Z' *' Y' = -i X'. Proof. simpl. f_equal. lma'. Qed.
Lemma YmulZ : Y' *' Z' = i X'. Proof. simpl. f_equal. lma'. Qed.

Hint Rewrite Xsqr Ysqr Zsqr XmulI YmulI ZmulI ImulX ImulY ImulZ ZmulX XmulZ XmulY YmulX ZmulY YmulZ : mul_db.








(*********************)
(* Intersection Laws *)
(*********************)


Lemma has_type_subset : forall (n : nat) (v : Vector n) (t1s t2s : vecType n),
  (t1s ⊆ t2s) -> v :' t2s -> v :' t1s.
Proof. intros n v t1s t2s.
       unfold subset_gen; unfold vecHasType.
       intros H H0 A H1.
       apply H0; apply H; apply H1.
Qed.

(* 
(* converse of previous statement. Impossible to prove as long as list is multiset *)
Axiom has_type_subset_conv : forall {n} (t1s t2s : vecType n),
  (forall (v : Vector n), v :' t2s -> v :' t1s) -> t1s ⊆ t2s.
*)

Definition eq_vecType {n} (T1 T2 : vecType n) := 
  (forall v, WF_Matrix v -> (v :' T1 <-> v :' T2)).


Infix "≡" := eq_vecType (at level 70, no associativity) : heisenberg_scope.

(* will now show this is an equivalence relation *)
Lemma eq_vecType_refl : forall {n} (A : vecType n), A ≡ A.
Proof. intros n A. 
       unfold eq_vecType. easy.
Qed.

Lemma eq_vecType_sym : forall {n} (A B : vecType n), A ≡ B -> B ≡ A.
Proof. intros n A B H. 
       unfold eq_vecType in *; intros v.
       split. 
       all : apply H; easy. 
Qed.

Lemma eq_vecType_trans : forall {n} (A B C : vecType n),
    A ≡ B -> B ≡ C -> A ≡ C.
Proof.
  intros n A B C HAB HBC.
  unfold eq_vecType in *.
  split. 
  - intros. apply HBC; auto; apply HAB; auto; apply H.
  - intros. apply HAB; auto; apply HBC; auto; apply H.
Qed.


Add Parametric Relation n : (vecType n) (@eq_vecType n)
  reflexivity proved by eq_vecType_refl
  symmetry proved by eq_vecType_sym
  transitivity proved by eq_vecType_trans
    as eq_vecType_rel.



(* converse of this is true as well since matrices are unitary? *)
(* probably hard to prove on coq *) 
Lemma eq_types_same_type : forall (n : nat) (T1 T2 : vecType n),
  (T1 ⊆ T2 /\ T2 ⊆ T1) -> T1 ≡ T2.
Proof. intros n T1 T2 [S12 S21]. 
       unfold eq_vecType. 
       intros v; split.
       - apply has_type_subset. apply S21.
       - apply has_type_subset. apply S12. 
Qed.


Lemma cap_idem : forall (n : nat) (A : vecType n), A ∩ A ≡ A.
Proof. intros n A.
       apply eq_types_same_type.
       split. 
       - autounfold with sub_db. auto with sub_db.
       - autounfold with sub_db. auto with sub_db.
Qed. 

Lemma cap_comm : forall (n : nat) (A B : vecType n), A ∩ B ≡ B ∩ A.
Proof. intros n A B.
       apply eq_types_same_type.
       split.
       - autounfold with sub_db. auto with sub_db.
       - autounfold with sub_db. auto with sub_db.
Qed.

Lemma cap_assoc_eq : forall (n : nat) (A B C : vecType n), A ∩ (B ∩ C) = (A ∩ B) ∩ C.
Proof. intros n A B C. autounfold with sub_db. rewrite app_ass. reflexivity.
Qed.



Lemma cap_I_l : forall {n} (A : vecType n),
  (I_n n) ∩ A ≡ A.
Proof. intros n A.
       unfold eq_vecType.
       intros v; split.
       - apply has_type_subset.
         autounfold with sub_db.
         auto with sub_db.
       - intros H0.
         unfold vecHasType; intros A0.
         simpl.
         intros [H1 | H1'].
         + rewrite <- H1.
           unfold singVecType in *.
           split; auto.
           exists C1.
           auto with eig_db.
         + apply H0; apply H1'.
Qed.

       
Lemma cap_I_r : forall {n} A,
  A ∩ (I_n n) ≡ A.
Proof. intros.
       rewrite cap_comm.
       rewrite cap_I_l.
       reflexivity. 
Qed.

(* these were origionall for gates, but I provided versions for vectors as well *)
Lemma cap_elim_l : forall {n} (g : Vector n) (A B : vecType n),
  g :' A ∩ B -> g :' A.
Proof. intros n g A B H. 
       apply (has_type_subset _ _ A (A ∩ B)).
       autounfold with sub_db. 
       auto with sub_db.
       apply H.
Qed.

Lemma cap_elim_r : forall {n} (g : Vector n) (A B : vecType n),
  g :' A ∩ B -> g :' B.
Proof. intros n g A B H. 
       apply (has_type_subset _ _ B (A ∩ B)).
       autounfold with sub_db. 
       auto with sub_db. 
       apply H.
Qed.



(* another important lemma about ∩ *)
Lemma types_add : forall (n : nat) (v : Vector n) (A B : vecType n),
  v :' A -> v :' B -> v :' (A ∩ B).
Proof. intros n v A B.
       unfold vecHasType; intros H1 H2.
       intros A0 H.
       apply in_app_or in H.
       destruct H as [HA | HB].
       - apply H1; apply HA.
       - apply H2; apply HB.
Qed.



Ltac pauli_matrix_computation :=
  repeat
    (try apply mat_equiv_eq;
     match goal with
     | |- WF_Unitary ?A => unfold WF_Unitary
    | |- WF_Matrix ?A /\ _ => split
    | |- WF_Matrix ?A => auto 10 with wf_db;
                                        try (unfold WF_Matrix;
                                        (let x := fresh "x" in
                                         let y := fresh "y" in
                                         let H := fresh "H" in
                                         intros x y [H| H];
                                         apply le_plus_minus in H;
                                         rewrite H; compute; destruct_m_eq))
    | |- (?A ≡ ?B)%M => by_cell
    | |- _ => autounfold with U_db;
                  simpl;
                  autorewrite with Cexp_db C_db;
                  try (eapply c_proj_eq);
                  simpl;
                  repeat (autorewrite with R_db; field_simplify_eq; simpl);
                  try easy
    end).


Ltac pauli_matrix_addition_unitary :=
  unfold uni_vecType;
  intros A H; simpl in H;
  destruct H; try(exfalso; assumption);
  rewrite <- H;
  pauli_matrix_computation.

  
Lemma XplusY :  uni_vecType ((1/√2) · (X' +' Y') ).
Proof. pauli_matrix_addition_unitary. Qed.

Lemma XplusZ :  uni_vecType ((1/√2) · (X' +' Z') ).
Proof. pauli_matrix_addition_unitary. Qed.

Lemma YplusZ :  uni_vecType ((1/√2) · (Y' +' Z') ).
Proof. pauli_matrix_addition_unitary. Qed.

Lemma XplusYplusZ :  uni_vecType ( (1/√3) · (X' +'  Y' +' Z' )).
Proof.  pauli_matrix_addition_unitary. Qed.


(* some more lemmas about specific vectors *)


(* note that vecHasType_is_vecHasType' makes this nice since       *)
(* vecHasType' works well with singletons as opposed to vecHasType *)
Ltac solveType := apply vecHasType_is_vecHasType'; 
                  simpl; unfold singVecType; rewrite kill_true; repeat split; try (auto with wf_db); 
                  try (exists C1; try(unfold Eigenpair; lma'; easy); auto with eig_db; easy);
                  try (exists (Copp C1); auto with eig_db).

Lemma all_hastype_I : forall (v : Vector 2), WF_Matrix v -> v :' I'.
Proof. intros. solveType. 
Qed.
  
Lemma p_hastype_X : ∣+⟩ :' X'. Proof. solveType. Qed. 
Lemma m_hastype_X : ∣-⟩ :' X'. Proof. solveType. Qed.
Lemma O_hastype_Z : ∣0⟩ :' Z'. Proof. solveType. Qed.
Lemma i_hastype_Z : ∣1⟩ :' Z'. Proof. solveType. Qed.


Definition capHasType {n} (v : Vector n) (ts : vecType n) :=
  Forall (singVecType v) ts.

Notation "v ::: A" := (capHasType v A) (at level 80).

Lemma B_hastype_XXZZ : ∣Φ+⟩ ::: (X' ⊗' X') ∩ (Z' ⊗' Z').
Proof.
  unfold capHasType.
  repeat constructor; auto with wf_db; exists 1; lma'.
Qed.                                
                            
Lemma B_hastype_XXZZ' : ∣Φ+⟩ :' (X' ⊗' X') ∩ (Z' ⊗' Z').
Proof.
  unfold ":'".
  apply Forall_forall.
  apply B_hastype_XXZZ.
Qed.
                             
Lemma B_hastype_XXZZ'' : ∣Φ+⟩ :' (X' ⊗' X') ∩ (Z' ⊗' Z').
  Proof. solveType. Qed.
                             

Hint Resolve all_hastype_I p_hastype_X m_hastype_X O_hastype_Z i_hastype_Z B_hastype_XXZZ B_hastype_XXZZ' : vht_db.

(**************************************************************)
(* Defining pairHasType, which is a helper function for later *)
(**************************************************************)
 
Definition pairHasType {n : nat} (p : Vector n * C) (ts: vecType n) : Prop := 
  forall (A : Square n), In A ts -> Eigenpair A p.


Lemma has_type_subset_pair : forall (n : nat) (p : Vector n * C) (t1s t2s : vecType n),
  (t1s ⊆ t2s) -> pairHasType p t2s -> pairHasType p t1s.
Proof. intros n p t1s t2s.
       unfold subset_gen; unfold pairHasType.
       intros H H0 A H1.
       apply H0; apply H; apply H1.
Qed.


Lemma cap_elim_l_pair : forall {n} (g : Vector n * C) (A B : vecType n),
  pairHasType g (A ∩ B) -> pairHasType g A.
Proof. intros n g A B H. 
       apply (has_type_subset_pair _ _ A (A ∩ B)).
       autounfold with sub_db. 
       auto with sub_db.
       apply H.
Qed.

Lemma cap_elim_r_pair : forall {n} (g : Vector n * C) (A B : vecType n),
  pairHasType g (A ∩ B) -> pairHasType g B.
Proof. intros n g A B H. 
       apply (has_type_subset_pair _ _ B (A ∩ B)).
       autounfold with sub_db. 
       auto with sub_db. 
       apply H.
Qed.


(***************************)
(* Writing actual programs *)
(***************************)


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


(* lemmas about seq*)
Lemma app_comp : forall (n : nat) (U1 U2 A B C : Square n),
  U1[A] = B -> U2[B] = C -> (U2×U1) [A] = C.
Proof. unfold gateApp. intros n U1 U2 A B C H1 H2. rewrite <- H2. rewrite <- H1.
       rewrite Mmult_adjoint. do 3 rewrite <- Mmult_assoc. reflexivity. 
Qed.

Lemma SeqTypes : forall {n} (g1 g2 : Square n) (A B C : vecType n),
    {{ A }} g1 {{ B }} ->
    {{ B }} g2 {{ C }} ->
    {{ A }} g1 ;' g2 {{ C }}.
Proof. intros n g1 g2 A B C. 
       simpl. intros HAB HBC.
       unfold gateHasPair'; simpl; intros.
       unfold seq. rewrite (Mmult_assoc g2 g1 v).
       unfold gateHasPair' in *; simpl in *.
       apply HBC.
       apply HAB.
       apply H.
Qed.
       

Lemma seq_assoc : forall {n} (p1 p2 p3 : Square n) (A B : vecType n),
   {{ A }} p1 ;' (p2 ;' p3) {{ B }} <-> {{ A }} (p1 ;' p2) ;' p3 {{ B }}.
Proof. intros n p1 p2 p3 A. unfold seq. split.
       - rewrite Mmult_assoc. easy.
       - rewrite Mmult_assoc. easy.
Qed.


Lemma In_eq_Itensor : forall (n : nat),
  n ⨂' I' = [I (2^n)].
Proof. intros n. assert (H : n ⨂' I' = [n ⨂ I 2]).
       { induction n as [| n']. 
         - reflexivity.
         - simpl. rewrite IHn'. simpl. reflexivity. }
       rewrite H. rewrite kron_n_I.
       reflexivity.
Qed.


Lemma Types_I : forall {n} (p : Square n), WF_Matrix p -> {{ [I n] }} p {{ [I n] }}.
Proof. intros.
       apply ghp_implies_ghp'.
       easy.
       unfold gateHasPair. 
       intros.
       apply in_simplify in H0. 
       apply in_simplify in H1.
       rewrite H0, H1.
       rewrite Mmult_1_r, Mmult_1_l; auto.
Qed.

(* Note that this doesn't restrict # of qubits referenced by p. *)
Lemma TypesI1 : forall (p : Square 2), WF_Matrix p -> {{ I' }} p {{ I' }}.
Proof. intros p. unfold I'. 
       apply Types_I.
Qed.


Lemma TypesI2 : forall (p : Square 4), WF_Matrix p -> {{ I' ⊗' I' }} p {{ I' ⊗' I' }}.
Proof. intros p H.
       assert (H0 : I' ⊗' I' = [I 4]).
       { simpl. rewrite id_kron. easy. }
       rewrite H0.
       apply Types_I; auto.
Qed.


Lemma TypesIn : forall (n : nat) (p : Square (2^n)), WF_Matrix p -> {{ n ⨂' I' }} p {{ n ⨂' I' }}.
Proof. intros n p H. rewrite In_eq_Itensor. 
       apply (@Types_I (2^n) p); auto.
Qed.      


Hint Resolve TypesI1 TypesI2 TypesIn : base_types_db.


(* Formal statements of all the transformations listed in figure 1 of Gottesman*)



(*********************)
(** Structural rules *)
(*********************)

Lemma scale_rule : forall {n : nat} (g : Square n) (c : C) (A B : Square n),
    {{ [A] }} g {{ [B] }} -> {{ c · [A] }} g {{ c · [B] }}.
Proof. intros n g c A B H.
       destruct (Ceq_dec c 0).
       - rewrite e. simpl. rewrite ! Mscale_0_l.
         unfold gateHasPair'. simpl.
         intros v c0 H0.
         unfold pairHasType in *.
         assert (  Eigenpair Zero (v, c0) ).
         { apply H0. constructor. reflexivity. }
         clear H0; rename H1 into H0.
         intros A0 H1.
         inversion H1.
         2:{ inversion H2. }
         rewrite <- H2.
         unfold Eigenpair in *.
         simpl in *.
         rewrite !  Mmult_0_l in *.
         rewrite <- Mscale_mult_dist_r.
         rewrite <- H0.
         rewrite Mmult_0_r.
         reflexivity.
       - unfold gateHasPair' in *.
         simpl in *.
         unfold pairHasType in *.
         assert (  forall (v : Vector n) (c : C), Eigenpair A (v, c) -> Eigenpair B (g × v, c) ).
         { intros v c0 H0.
           specialize (H v c0).
           assert ( (forall A0 : Square n, In A0 ([A]) -> Eigenpair A0 (v, c0)) ).
           { intros A0 H1.
             inversion H1; subst; try assumption.
             inversion H2. }
           specialize (H H1).
           apply H.
           constructor.
           reflexivity. }
         clear H; rename H0 into H.
         intros v c0 H0 A0 H1.
         specialize (H v (/c*c0)).
         inversion H1; subst.
         2: { inversion H2. }
         clear H1.
         assert ( Eigenpair (c .* A) (v, c0) ).
         { apply H0.
           constructor.
           reflexivity. }
         clear H0; rename H1 into H0.
         unfold Eigenpair in *; simpl in *.
         apply Mscale_inj with (c:= /c) in H0.
         rewrite Mscale_mult_dist_l in H0.
         rewrite ! Mscale_assoc in H0.
         rewrite Cinv_l in H0; try assumption.
         rewrite Mscale_1_l in H0.
         apply H in H0.
         apply Mscale_inj with (c:=c) in H0.
         rewrite Mscale_mult_dist_l.
         rewrite Mscale_assoc in H0.
         rewrite Cmult_assoc in H0.
         rewrite Cinv_r in H0; try assumption.
         rewrite Cmult_1_l in H0.
         assumption.
Qed.


Lemma multiplication_rule : forall {n : nat} (g : Square n) (A A' B B' : Square n),
    {{ [A] }} g {{ [B] }} -> {{ [A'] }} g {{ [B'] }} -> {{ [A × A'] }} g {{ [B × B'] }}.
Proof. intros n g A A' B B' gAB gA'B'.
       unfold gateHasPair' in *.
       intros v c H.
       simpl in *.
       unfold pairHasType in *.
       intros A0 H0.
       inversion H0; subst.
       2:{ inversion H1. }
       clear H0.
       assert ( Eigenpair (A × A') (v, c) ).
       { apply H. constructor. reflexivity. }
       clear H; rename H0 into H.
       assert (eAB: forall (v : Vector n) (c : C),
                  Eigenpair A (v, c) -> Eigenpair B (g × v, c) ).
       { intros v0 c0 H0. apply gAB.
         - intros A0 H1. inversion H1; subst; try assumption. inversion H2.
         - constructor. reflexivity. }
       clear gAB.
       assert (eA'B': forall (v : Vector n) (c : C),
                  Eigenpair A' (v, c) -> Eigenpair B' (g × v, c) ).
       { intros v0 c0 H0. apply gA'B'.
         - intros A0 H1. inversion H1; subst; try assumption. inversion H2.
         - constructor. reflexivity. }
       clear gA'B'.
       
       specialize (eAB (A' × v) c).
       unfold Eigenpair in *. simpl in *.
     
       
















(* Subtyping rules *)

(* must prove same lemmas for predicatePairs as for vectTypes. *)
(* Could probably find way to get rid of repeated code... *)


Lemma has_type_subset_gate : forall (n : nat) (g : Square n) (t1s t2s : vecType n * vecType n),
  t1s ⊆ t2s -> g ::' t2s -> g ::' t1s.
Proof. intros n v t1s t2s H H0. 
       apply gateHasPair_is_gateHasPair'; unfold gateHasPair.
       apply gateHasPair_is_gateHasPair' in H0; unfold gateHasPair in H0.
       intros A H2.
       apply H0. 
       apply H; apply H2.
Qed.
       

Definition eq_predicatePair {n} (T1 T2 : vecType n * vecType n) := 
  (forall v, v ::' T1 <-> v ::' T2).


Infix "≡≡" := eq_predicatePair (at level 70, no associativity) : heisenberg_scope.

(* will now show this is an equivalence relation *)
Lemma eq_predicatePair_refl : forall {n} (A : vecType n * vecType n), A ≡≡ A.
Proof. intros n A. 
       easy.
Qed.

Lemma eq_predicatePair_sym : forall {n} (A B : vecType n * vecType n), A ≡≡ B -> B ≡≡ A.
Proof. intros n A B H. 
       unfold eq_predicatePair in *; intros v.
       split. apply H. apply H.
Qed.

Lemma eq_predicatePair_trans : forall {n} (A B C : vecType n * vecType n),
    A ≡≡ B -> B ≡≡ C -> A ≡≡ C.
Proof.
  intros n A B C HAB HBC.
  unfold eq_predicatePair in *.
  split. 
  - intros. apply HBC; apply HAB; apply H.
  - intros. apply HAB; apply HBC; apply H.
Qed.


Add Parametric Relation n : (vecType n * vecType n) (@eq_vecType n * vecType n)
  reflexivity proved by eq_predicatePair_refl
  symmetry proved by eq_predicatePair_sym
  transitivity proved by eq_predicatePair_trans
    as eq_predicatePair_rel.



 
Lemma eq_types_are_Eq_gate : forall (n : nat) (g : Square n) (T1 T2 : vecType n * vecType n),
  (T1 ⊆ T2 /\ T2 ⊆ T1) -> T1 ≡≡ T2.
Proof. intros n v T1 T2 [S12 S21].
       unfold eq_predicatePair. intros. split.
       - apply has_type_subset_gate; apply S21.
       - apply has_type_subset_gate; apply S12. 
Qed.


Lemma cap_elim_l_gate : forall {n} (g : Square n) (A B : vecType n * vecType n),
  g ::' (A ∩ B) -> g ::' A.
Proof. intros n g A B H. 
       apply (has_type_subset_gate _ _ A (A ∩ B)).
       autounfold with sub_db.
       auto with sub_db.
       apply H.
Qed.

Lemma cap_elim_r_gate : forall {n} (g : Square n) (A B : vecType n * vecType n),
  g ::' A ∩ B -> g ::' B.
Proof. intros n g A B H. 
       apply (has_type_subset_gate _ _ B (A ∩ B)).
       autounfold with sub_db.
       auto with sub_db. 
       apply H.
Qed.

Lemma cap_intro : forall {n} (g : Square n) (A B : vecType n * vecType n),
  g ::' A -> g ::' B -> g ::' A ∩ B.
Proof. intros n g A B. 
       induction A as [| a].
       - simpl; easy. 
       - simpl; intros [Ha Ha'] Hb; split. 
         * apply Ha.
         * apply IHA. 
           apply Ha'. 
           apply Hb.
Qed.

(* Note that both cap_elim_pair and cap_elim_gate are here. Both are necessary *)
Hint Resolve cap_elim_l_gate cap_elim_r_gate cap_elim_l_pair cap_elim_r_pair cap_intro : subtype_db.

Lemma cap_elim : forall {n} (g : Square n) (A B : vecType n * vecType n),
  g ::' A ∩ B -> g ::' A /\ g ::' B.
Proof. eauto with subtype_db. Qed.


Lemma cap_arrow : forall {n} (g : Square n) (A B C : vecType n),
  g ::' (A → B) ∩ (A → C) ->
  g ::' A → (B ∩ C)%H.
Proof. intros n g A B C [Ha [Hb _]].  
       apply kill_true.
       unfold gateHasPair' in *; simpl in *.
       intros v c H B' Hb'. 
       apply in_app_or in Hb'; destruct Hb' as [H3 | H3].
       - apply Ha. apply H. apply H3. 
       - apply Hb. apply H. apply H3. 
Qed.
 


Lemma arrow_sub : forall {n} (g : Square n) (A A' B B' : vecType n),
  (forall l, pairHasType l A' -> pairHasType l A) ->
  (forall r, pairHasType r B -> pairHasType r B') ->
  g ::' A → B ->
  g ::' A' → B'.
Proof. intros n g A A' B B' Ha Hb [H _]. simpl in *. 
       apply kill_true. 
       unfold gateHasPair' in *; simpl in *.
       intros.
       apply Hb.
       apply H.
       apply Ha.
       apply H0.
Qed.


Hint Resolve cap_elim cap_arrow arrow_sub : subtype_db.



(* this is killed by eauto with subtype_db *)
Lemma cap_arrow_distributes : forall {n} (g : Square n) (A A' B B' : vecType n),
  g ::' (A → A') ∩ (B → B') ->
  g ::' (A ∩ B)%H → (A' ∩ B')%H.
Proof.
  intros; apply cap_arrow.
  apply cap_intro; eauto with subtype_db. 
Qed.

(* "Full explicit proof", as in Programs.v *)
Lemma cap_arrow_distributes'' : forall {n} (g : Square n) (A A' B B' : vecType n),
  g ::' (A → A') ∩ (B → B') ->
  g ::' (A ∩ B)%H → (A' ∩ B')%H.
Proof.
  intros.
  apply cap_arrow.
  apply cap_intro.
  - eapply arrow_sub; intros.
    + apply cap_elim_l_pair in H0. apply H0.
    + apply H0.
    + eapply cap_elim_l_gate. apply H.
  - eapply arrow_sub; intros.
    + eapply cap_elim_r_pair. apply H0.
    + apply H0.
    + eapply cap_elim_r_gate. apply H.
Qed.

(***************)
(* Arrow rules *)
(***************)



Lemma arrow_mul : forall {n} (p : Square n) (A A' B B' : vecType n),
    Singleton A -> Singleton B ->
    WF_Unitary p ->
    uni_vecType A -> uni_vecType A' ->
    uni_vecType B -> uni_vecType B' ->
    p ::' A → A' ->
    p ::' B → B' ->
    p ::' A *' B → A' *' B'.
Proof. intros n p A A' B B' Hsa Hsb Hup Hua Hua' Hub Hub' [Ha _] [Hb _].
       assert (Hsa' : Singleton A). { apply Hsa. }
       assert (Hsb' : Singleton B). { apply Hsb. }
       apply singleton_simplify in Hsa; destruct Hsa;
       apply singleton_simplify in Hsb; destruct Hsb;
       apply kill_true.
       apply ghp_implies_ghp'.
       rewrite H, H0. simpl. easy.
       apply ghp'_implies_ghp in Ha.
       apply ghp'_implies_ghp in Hb.
       unfold gateHasPair in *.
       intros AB A'B' H1 H2. simpl in *.
       apply in_mult in H1.
       apply in_mult in H2.
       do 2 (destruct H1); destruct H1 as [H1 H1']; destruct H1' as [H1' H1''].
       do 2 (destruct H2); destruct H2 as [H2 H2']; destruct H2' as [H2' H2''].
       rewrite H1'', H2''.
       rewrite <- Mmult_assoc. 
       assert (H3: p × x1 = x3 × p).
       { apply Ha. apply H1. apply H2. }
       assert (H4: p × x2 = x4 × p).
       { apply Hb. apply H1'. apply H2'. }
       rewrite H3. rewrite Mmult_assoc. 
       rewrite H4. rewrite <- Mmult_assoc.
       reflexivity.
       apply Hup. apply Hsb'. 
       split. apply Hub. apply Hub'.
       apply Hup. apply Hsa'.
       split. apply Hua. apply Hua'.
Qed.


Lemma arrow_add : forall {n} (p : Square n) (A A' B B' : vecType n),
    Singleton A -> Singleton B ->
    WF_Unitary p ->
    uni_vecType A -> uni_vecType A' ->
    uni_vecType B -> uni_vecType B' ->
    p ::' A → A' ->
    p ::' B → B' ->
    p ::' A +' B → A' +' B'.
Proof. intros n p A A' B B' Hsa Hsb Hup Hua Hua' Hub Hub' [Ha _] [Hb _].
       assert (Hsaa : Singleton A). { apply Hsa. }
       assert (Hsbb : Singleton B). { apply Hsb. } 
       apply singleton_simplify in Hsa; destruct Hsa as [a Hsa];
       apply singleton_simplify in Hsb; destruct Hsb as [b Hsb].
       apply ghp'_implies_ghp in Ha, Hb; simpl; auto with wf_db.
       split; try easy.
       apply ghp_implies_ghp'; simpl; rewrite Hsa, Hsb; simpl; try easy.
       unfold gateHasPair in *.
       intros M M' H H'.
       rewrite Hsa, Hsb in *.
       simpl in *.
       rewrite kill_false in *.
       apply in_add in H'.
       destruct H' as [a' [b' [Ha' [Hb' H']]]].
       rewrite <- H, H'.
       rewrite Mmult_plus_distr_l, Mmult_plus_distr_r.
       rewrite (Ha a a'); try(rewrite kill_false; easy); try(assumption).
       rewrite (Hb b b'); try(rewrite kill_false; easy); try(assumption).
       reflexivity.
Qed.


Lemma arrow_scale : forall {n} (p : Square n) (A A' : vecType n) (c : C),
    c <> C0 -> p ::' A → A' -> p ::' c · A → c · A'.
Proof. intros n p A A' c H0 [H _]. 
       apply kill_true.
       unfold gateHasPair' in *.
       intros v x H1. simpl in *.
       intros A0 H2.
       unfold pairHasType in *.
       apply in_scale in H2.
       destruct H2 as [a' [H2 H2']].
       assert (H' : Eigenpair a' (p × v, x / c)). 
       { apply H. intros A1 H3. 
         apply (eigen_scale_div _ _ _ c).
         apply H0.
         assert (H' : c * (x / c) = x). 
         { C_field_simplify. reflexivity. apply H0. }
         rewrite H'. apply H1.
         apply in_scale_rev. apply H3.
         apply H2. }
       rewrite H2'.
       assert (H'' : x = (x / c) * c). 
       { C_field_simplify. reflexivity. apply H0. }
       rewrite H''.
       apply eigen_scale.
       apply H'.
Qed.           


Lemma arrow_i : forall {n} (p : Square n) (A A' : vecType n),
    p ::' A → A' ->
    p ::' i A → i A'.
Proof. unfold i. intros. 
       apply arrow_scale. 
       apply C0_snd_neq. simpl. easy. 
       apply H.
Qed.

Lemma arrow_neg : forall {n} (p : Square n) (A A' : vecType n),
    p ::' A → A' ->
    p ::' -A → -A'.
Proof. unfold neg. intros.
       apply arrow_scale.
       rewrite <- Cexp_PI.
       apply Cexp_nonzero.
       apply H.
Qed.



Lemma eq_arrow_r : forall {n} (g : Square n) (A B B' : vecType n),
    g ::' A → B ->
    B = B' ->
    g ::' A → B'.
Proof. intros; subst; easy. Qed.



(*****************************)
(** Typing Rules for Tensors *)
(*****************************)

Local Open Scope nat_scope.


Definition vecTypeT (len : nat) := (list (vecType 2)).

Definition vecTypeT' := (list (vecType 2)).


Definition X'' : vecTypeT 1 := [X'].
Definition Z'' : vecTypeT 1 := [Z'].
Definition I'' : vecTypeT 1 := [I'].


Definition tensorT {n m} (A : vecTypeT n) (B : vecTypeT m) : vecTypeT (n + m) := A ++ B.

Fixpoint mulT' (A B : vecTypeT') : vecTypeT' :=
  match A with
  | [] => B
  | (a :: As) => 
    match B with 
    | [] => A
    | (b :: Bs) => (a *' b :: mulT' As Bs)
    end
  end.


Definition mulT {n : nat} (A B : vecTypeT n) : vecTypeT n := mulT' A B.


Definition scaleT (c : C) {n : nat} (A : vecTypeT n) : vecTypeT n :=
  match A with
  | [] => []
  | (h :: t) => (c · h :: t)
  end.



Definition formGateTypeT {n : nat} (A B : vecTypeT n) : vecType n * vecType n := [(⨂' A, ⨂' B)].


Infix "'⊗'" := tensorT (at level 51, right associativity) : heisenberg_scope. 
Notation "A →' B" := (formGateTypeT A B) (at level 60, no associativity) : heisenberg_scope.


Definition WF_vtt {len : nat} (vt : vecTypeT len) := length vt = len.
       


Lemma big_tensor_simpl : forall {n m} (A : vecTypeT n) (B : vecTypeT m) (a : vecType 2),
  (forall a, In a A -> uni_vecType a) -> (forall b, In b B -> uni_vecType b) 
  -> uni_vecType a ->
  ⨂' (A ++ [a] ++ B) = (⨂' A) ⊗' a ⊗' (⨂' B).
Proof. induction A as [| h].
       - intros.
         apply univ_tensor_list in H0.
         rewrite big_tensor_1_l; auto with univ_db.
       - intros. simpl.  
         rewrite cons_conc. 
         rewrite IHA; auto with univ_db.
         assert (H': forall (n : nat), 2^n + (2^n + 0) = 2 * 2^n). { nia. }
         repeat (rewrite H'). 
         rewrite <- tensor_assoc; auto with univ_db.
         rewrite length_change.
         reflexivity.
         apply H; left; auto. 
         apply univ_tensor_list; auto.
         all : intros; try (apply H; right; easy). 
         apply univ_tensor_list in H0.
         auto with univ_db.
Qed.



Lemma nth_tensor_inc : forall (n len : nat) (A : vecTypeT len),
  (forall a, In a A -> uni_vecType a) -> 
  n < len -> WF_vtt A -> ⨂' A = (⨂' (firstn n A)) ⊗' (nth n A I') ⊗' (⨂' (skipn (S n) A)).
Proof. intros. 
       rewrite <- (@big_tensor_simpl n (len - n) (firstn n A) (skipn (S n) A) (nth n A I')).
       rewrite <- nth_inc.
       reflexivity. 
       rewrite H1.
       assumption. 
       all : intros; apply H.
       - rewrite <- (firstn_skipn n).
         apply in_or_app.
         auto. 
       - rewrite <- (firstn_skipn (S n)).
         apply in_or_app.
         auto. 
       - apply nth_In.
         rewrite H1; auto.
Qed.


Lemma switch_tensor_inc : forall (n len : nat) (A : vecTypeT len) (x : vecType 2),
  (forall a, In a A -> uni_vecType a) -> uni_vecType x ->
  n < len -> WF_vtt A -> ⨂' (switch A x n) = (⨂' (firstn n A)) ⊗' x ⊗' (⨂' (skipn (S n) A)).
Proof. intros. 
       rewrite <- (@big_tensor_simpl n (len - n) (firstn n A) (skipn (S n) A) x); auto.
       rewrite <- switch_inc.
       reflexivity. 
       rewrite H2.
       assumption. 
       all : intros; apply H.
       - rewrite <- (firstn_skipn n).
         apply in_or_app.
         auto. 
       - rewrite <- (firstn_skipn (S n)).
         apply in_or_app.
         auto. 
Qed.


Lemma sgt'_reduce_smpl : forall {n m : nat} (u : Square 2) (a b : vecType 2) 
                                (A : vecType n) (B : vecType m),
  Singleton A -> Singleton B -> Singleton a -> Singleton b ->
  WF_Unitary u -> uni_vecType a -> uni_vecType b ->
  uni_vecType A -> uni_vecType B ->
  gateHasPair' u (a, b) -> 
  gateHasPair' ((I n) ⊗ u ⊗ (I m)) (A ⊗' a ⊗' B, A ⊗' b ⊗' B).  
Proof. intros n m u a b A B HSA HSB HSa HSb Huu Hua Hub HuA HuB Hsgt.
       apply singleton_simplify in HSA;
       destruct HSA as [A' HSA];
       apply singleton_simplify in HSB;
       destruct HSB as [B' HSB];
       apply singleton_simplify in HSa;
       destruct HSa as [a' HSa];
       apply singleton_simplify in HSb;
       destruct HSb as [b' HSb];       
       rewrite HSA, HSB, HSa, HSb in *.    
       apply ghp_implies_ghp'; try easy. 
       apply ghp'_implies_ghp in Hsgt; try easy.
       unfold gateHasPair in *.
       intros.
       simpl in *;
       destruct H as [H | F];
       destruct H0 as [H0 | F0]; try easy.
       rewrite <- H, <- H0.
       rewrite kron_assoc. 
       assert (H' : m + (m + 0) = 2 * m). { nia. }
       assert (H'' : (n * 2) * m = n * (2 * m)). { nia. } 
       repeat (rewrite H'). repeat (rewrite H'').
       do 4 (rewrite kron_mixed_product).  
       repeat rewrite Mmult_1_l, Mmult_1_r.
       rewrite (Hsgt a' b'); 
       try easy; 
       try (left; easy).
       all : auto with wf_db; 
         try (apply HuB; left; auto); try (apply HuA; left; auto).
       apply Huu.
Qed.


Lemma tensor_smpl : forall (prg_len bit : nat) (g : Square 2) 
                           (A : vecTypeT prg_len) (a : vecType 2),
    (forall a : vecType 2, In a A -> uni_vecType a) ->
    Singleton (⨂' A) -> Singleton a ->
    WF_Unitary g -> uni_vecType (nth bit A I') -> uni_vecType a ->
    bit < prg_len -> WF_vtt A -> 
    g ::' ((nth bit A I') → a) ->
    (prog_smpl_app prg_len g bit) ::'  A →' (switch A a bit).
Proof. intros prg_len bit g A a Huvt SA Sa Hug Hunb Hua Hbpl Hwf H. 
       simpl. 
       rewrite (nth_tensor_inc bit prg_len A); try easy.
       rewrite (switch_tensor_inc bit prg_len A a); try easy. 
       unfold prog_smpl_app.
       apply kill_true.
       repeat (rewrite firstn_length_le).
       repeat (rewrite skipn_length').
       repeat (rewrite switch_len).
       unfold WF_vtt in Hwf. 
       rewrite Hwf in *.
       repeat (rewrite (easy_pow3 prg_len bit)); try easy.  
       bdestruct (bit <? prg_len); try lia. 
       apply sgt'_reduce_smpl; try easy.
       apply (S_tensor_subset _ A _). 
       apply SA. apply firstn_subset.
       apply (S_tensor_subset _ A _). 
       apply SA. apply skipn_subset.
       apply (S_big_tensor_conv _ A _).
       apply SA. apply nth_In.
       rewrite Hwf; assumption.
       destruct H as [H _].  
       - assert (H' : forall a : vecType 2, In a (firstn bit A) -> uni_vecType a).
         { intros; apply Huvt.
           rewrite <- (firstn_skipn bit).
           apply in_or_app; auto. }
         apply univ_tensor_list in H'.
         rewrite firstn_length_le in H'.
         auto. rewrite Hwf; nia. 
       - assert (H' : forall a : vecType 2, In a (skipn (S bit) A) -> uni_vecType a).
         { intros; apply Huvt.
           rewrite <- (firstn_skipn (S bit)).
           apply in_or_app; auto. }
         apply univ_tensor_list in H'.
         rewrite skipn_length, Hwf in H'.
         replace ((prg_len - bit) - 1) with (prg_len - (S bit)) by lia.
         auto.  
       - apply H.
       - rewrite Hwf; lia. 
Qed.

           

Ltac solve_gate_type :=
  repeat match goal with
    | |- gateHasPair' ?U ?g /\ _ => split
    | |- ?g <> [] => easy
    | |- gateHasPair' ?U ?g => apply ghp_implies_ghp' 
    | |- gateHasPair ?U ?g => simpl; apply singleton_simplify2; pauli_matrix_computation
    | |- _ => try easy
    end.


Lemma HTypes : H' ::' (Z' → X') ∩ (X' → Z').
Proof. simpl. unfold Z', X', prog_smpl_app. 
       solve_gate_type. 
Qed.
       
Lemma HTypes' : H' ::' (Z'' →' X'') ∩ (X'' →' Z'').
Proof. simpl.
       repeat (rewrite kron_1_r).  
       solve_gate_type. 
Qed.


Lemma STypes : (prog_smpl_app 1 S' 0) ::' (X' → Y') ∩ (Z' → Z').
Proof. simpl. unfold Z', X', prog_smpl_app. 
       solve_gate_type. 
Qed.

Lemma CNOTTypes : (prog_ctrl_app 2 σx 0 1) ::' (X' ⊗' I' → X' ⊗' X') ∩ (I' ⊗' X' → I' ⊗' X') ∩
                          (Z' ⊗' I' → Z' ⊗' I') ∩ (I' ⊗' Z' → Z' ⊗' Z').
Proof. rewrite adj_ctrlX_is_cnot1.
       simpl. unfold X', I', Z'. 
       solve_gate_type.
Qed.
      

Lemma CNOTTypes' : cnot ::' (X' ⊗' I' → X' ⊗' X') ∩ (I' ⊗' X' → I' ⊗' X') ∩
                          (Z' ⊗' I' → Z' ⊗' I') ∩ (I' ⊗' Z' → Z' ⊗' Z').
Proof. simpl. unfold X', I', Z'. 
       solve_gate_type.
Qed.

Lemma CZTypes' : CZ ::' (X' ⊗' I' → X' ⊗' Z') ∩ (I' ⊗' X' → Z' ⊗' X') ∩
                          (Z' ⊗' I' → Z' ⊗' I') ∩ (I' ⊗' Z' → I' ⊗' Z').
Proof. simpl. unfold X', I', Z'. 
       solve_gate_type.
Qed.



(* T only takes Z → Z *)
Lemma TTypes : T' ::' (Z' → Z').
Proof. simpl. unfold T', Z'. 
       solve_gate_type. 
Qed.

Lemma TTypes' : T' ::' (Z' → Z') ∩ (X' → (C1/√2) · (X' +' Y')) ∩ (Y' → (C1/√2) · (Y' +' - X')).
Proof. simpl. unfold T', Z'. 
       solve_gate_type.
Qed.

Lemma TdaggerTypes : T'dagger ::' (Z' → Z') ∩ (X' → (C1/√2) · (X' +' - Y')).
Proof. simpl; unfold T'dagger, Z', X'.
       solve_gate_type.
Qed.


Definition Toffoli : Matrix (2*2*2) (2*2*2) :=
  fun x y => match x, y with 
          | 0, 0 => C1
          | 1, 1 => C1
          | 2, 2 => C1
          | 3, 3 => C1
          | 4, 4 => C1
          | 5, 5 => C1
          | 6, 7 => C1
          | 7, 6 => C1
          | _, _ => C0
          end.

Lemma WF_Toffoli : WF_Matrix Toffoli.
Proof. unfold Toffoli.
  show_wf.
Qed.

Hint Resolve WF_Toffoli : wf_db.

Lemma ToffoliTypes :
  Toffoli ::' (Z' ⊗' I' ⊗' I' → Z' ⊗' I' ⊗' I') ∩
    (I' ⊗' Z' ⊗' I' → I' ⊗' Z' ⊗' I' ) ∩
    (I' ⊗' I' ⊗' Z' → (C1/ C2) · ( I' ⊗' I' ⊗' Z' +' Z' ⊗' I' ⊗' Z' +' I' ⊗' Z' ⊗' Z' +' Z' ⊗' Z' ⊗' (- Z' ) )) ∩
    (I' ⊗' I' ⊗' X' → I' ⊗' I' ⊗' X' ).
Proof. simpl. solve_gate_type. Qed.


Hint Resolve HTypes HTypes' STypes TTypes CNOTTypes CNOTTypes' CZTypes' : base_types_db.
Hint Resolve cap_elim_l_gate cap_elim_r_gate : base_types_db.

Hint Resolve HTypes STypes TTypes CNOTTypes : typing_db.
Hint Resolve cap_intro cap_elim_l cap_elim_r : typing_db.
Hint Resolve SeqTypes : typing_db.


Definition appH (len bit : nat) := prog_smpl_app len H' bit.
Definition appCNOT (len ctrl targ : nat) := prog_ctrl_app len σx ctrl targ.
Definition appCZ (len ctrl targ : nat) := appH len targ ; appCNOT len ctrl targ ; appH len targ.
 

Definition bell00 : Square 16 := (prog_smpl_app 4 H' 2); (prog_ctrl_app 4 σx 2 3).

Definition encode : Square 16 := (prog_ctrl_app 4 σz 0 2); (prog_ctrl_app 4 σx 1 2).

Definition decode : Square 16 := (prog_ctrl_app 4 σx 2 3); (prog_smpl_app 4 H' 2).

Definition superdense := bell00 ; encode; decode.


