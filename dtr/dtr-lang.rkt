#lang racket

(require redex)
(provide (all-defined-out))

(define-language λDTR
  [x y z ν ::= variable-not-otherwise-mentioned] ;; TODO ν for fresh vars!
  [i       ::= integer]
  [b       ::= boolean]
  [e       ::= (ann x τ) (e e) (λ (x : τ) e) (if e e e) op b i string
              (let (x e) e) (cons e e) (vec e ...) (vec-ref e e)]
  [op      ::= add1 zero? int? str? bool? proc? str-len vec-len 
              + <= (* i) error cons? vec? neg car cdr]
  [pe      ::= CAR CDR LEN]
  [π       ::= (pe ...)]
  [o       ::= i (π @ x) (* i o) (+ o o)]
  [Φ       ::= ((≤ o o) ...)]
  [oo      ::= o Ø]
  [τ σ     ::= Top #t #f Int Str (U τ ...) (x : σ → τ (ψ ψ oo)) 
              (τ × τ) (♯ τ) (x : τ where ψ)]
  [♢       ::= ~ ¬]
  [δ       ::= (o ♢ τ)]
  [ψ       ::= δ (ψ ∧ ψ) (ψ ∨ ψ) TT FF Φ]
  [δ*      ::= (δ ...)]
  [ψ*      ::= (ψ ...)]
  [Γ       ::= (env Φ δ* ψ*)])


;; Basic Constructors / Helpers

(define-metafunction λDTR
  empty-env : -> Γ
  [(empty-env) (env () () ())])

(define-metafunction λDTR
  env+Φ : Γ Φ -> Γ
  [(env+Φ (env Φ δ* ψ*) Φ_new) (env (app Φ Φ_new) δ* ψ*)])

(define-metafunction λDTR
  env+ψ* : Γ ψ ... -> Γ
  [(env+ψ* (env Φ δ* ψ*) ψ ...) (env Φ δ* (app ψ* (ψ ...)))])

(define-metafunction λDTR
  Φ-env: : ψ ... -> Γ
  [(Φ-env: Φ) (env Φ () ())])


(define-metafunction λDTR
  var-in-o : x o -> boolean
  [(var-in-o x i) #f]
  [(var-in-o x (π @ x)) #t]
  [(var-in-o x_!_1 (π @ x_!_1)) #f]
  [(var-in-o x (+ o_1 o_2)) #t
                            (where #t (var-in-o x o_1))]
  [(var-in-o x (+ o_1 o_2)) #t
                            (where #t (var-in-o x o_2))]
  [(var-in-o x (+ o_1 o_2)) #f
                            (where #f (var-in-o x o_1))
                            (where #f (var-in-o x o_2))]
  [(var-in-o x (* i o)) (var-in-o o)])


(define-judgment-form λDTR
  #:mode (is-U I)
  #:contract (is-U τ)
  [-------------- "IsUnion"
   (is-U (U τ ...))])

(define-judgment-form λDTR
  #:mode (is-Pair I)
  #:contract (is-Pair τ)
  [-------------- "IsPair"
   (is-Pair (τ × σ))])

(define-judgment-form λDTR
  #:mode (is-Vec I)
  #:contract (is-Vec τ)
  [-------------- "IsVec"
   (is-Vec (♯ τ))])

(define-judgment-form λDTR
  #:mode (not-U I)
  #:contract (not-U τ)
  [(where #f (is-U τ))
   -------------- "NonU"
   (not-U τ)])

(define-judgment-form λDTR
  #:mode (is-Refine I)
  #:contract (is-Refine τ)
  [-------------- "IsRefine"
   (is-Refine (x : τ where ψ))])

(define-judgment-form λDTR
  #:mode (not-Refine I)
  #:contract (not-Refine τ)
  [(where #f (is-Refine τ))
   -------------- "NonU"
   (not-Refine τ)])

(define-metafunction λDTR 
  app : (any ...) ... -> (any ...)
  [(app (any_1 ...)) (any_1 ...)]
  [(app (any_1 ...) (any_2 ...) ...) (app (any_1 ... any_2 ...) ...)])


(define-metafunction λDTR
  And: : ψ ψ -> ψ
  [(And: TT ψ) ψ]
  [(And: ψ TT) ψ]
  [(And: FF ψ) FF]
  [(And: ψ FF) FF]
  [(And: ψ_l ψ_r) (ψ_l ∧ ψ_r)
   (judgment-holds (<> TT ψ_l))
   (judgment-holds (<> TT ψ_r))
   (judgment-holds (<> FF ψ_l))
   (judgment-holds (<> FF ψ_r))])

(define-metafunction λDTR
  Or: : ψ ψ -> ψ
  [(Or: TT ψ) TT]
  [(Or: ψ TT) TT]
  [(Or: FF ψ) ψ]
  [(Or: ψ FF) ψ]
  [(Or: ψ_l ψ_r) (ψ_l ∨ ψ_r)
   (judgment-holds (<> TT ψ_l))
   (judgment-holds (<> TT ψ_r))
   (judgment-holds (<> FF ψ_l))
   (judgment-holds (<> FF ψ_r))])


(define-metafunction λDTR
  +: : oo oo -> oo
  [(+: Ø oo) Ø]
  [(+: oo Ø) Ø]
  [(+: 0 o) o]
  [(+: o 0) o]
  [(+: i_l i_r) ,(+ (term i_l) (term i_r))]
  [(+: o_l o_r) (+ o_l o_r)
   (side-condition (nand (exact-integer? (term o_l))
                         (exact-integer? (term o_r))))])

(define-metafunction λDTR
  *: : oo oo -> oo
  [(*: Ø oo) Ø]
  [(*: oo Ø) Ø]
  [(*: i_l i_r) ,(* (term i_l) (term i_r))]
  [(*: 0 o) 0]
  [(*: 1 o) o]
  [(*: i o) (* i o)
   (side-condition (nor (exact-integer? (term o))
                        (= 0 (term i))
                        (= 1 (term i))))]
  [(*: o i) (*: i o)
   (where #f (exact-integer? (term o)))]
  [(*: o_l o_r) Ø
   (side-condition (not (exact-integer? (term oo_l))))
   (side-condition (not (exact-integer? (term oo_r))))])



(define-metafunction λDTR 
  ≤: : oo oo -> Φ
  [(≤: Ø oo) []]
  [(≤: oo Ø) []]
  [(≤: o_1 o_2) [(≤ o_1 o_2)]])

(define-metafunction λDTR
  is : x τ -> δ
  [(is x τ) ((id x) ~ τ)])

(define-metafunction λDTR
  ! : x τ -> δ
  [(! x τ) ((id x) ¬ τ)])

(define-judgment-form λDTR
  #:mode (is-δ I)
  #:contract (is-δ ψ)
  [------------ "Is-δ"
   (is-δ δ)])


(define-judgment-form λDTR
  #:mode (flat-U I)
  #:contract (flat-U (U τ ...))
  [(not-U τ) ...
   --------------- "Flat-U"
   (flat-U (U τ ...))])

(define-metafunction λDTR
  flatten-U : (U τ ...) -> τ
  [(flatten-U (U τ ...)) (U τ ...)
                         (judgment-holds (flat-U (U τ ...)))]
  [(flatten-U (U τ_0 ... (U σ ...) τ_1 ...)) (flatten-U (U τ_0 ... σ ... τ_1 ...))
                                             (judgment-holds (flat-U (U τ_1 ...)))])

(define-metafunction λDTR
  flatten+dedupe-U : (U τ ...) -> τ
  [(flatten+dedupe-U (U τ ...)) 
   (U ,@(remove-duplicates (cdr (term (flatten-U (U τ ...))))))])


(define-metafunction λDTR
  U: : τ ... -> τ
  [(U: τ ...) σ
   (where (U σ) (flatten+dedupe-U (U τ ...)))]
  [(U: τ ...) (U)
   (where (U) (flatten+dedupe-U (U τ ...)))]
  [(U: τ ...) (U σ_0 σ_1 ...)
   (where (U σ_0 σ_1 ...) (flatten+dedupe-U (U τ ...)))])


(define-metafunction λDTR
  Int= : o -> τ
  [(Int= o) (ν : Int where [(≤ (id ν) o) (≤ o (id ν))])
   (where ν (fresh-var o))])

(define-metafunction λDTR
  Int< : o -> τ
  [(Int< o) (ν : Int where [(≤ (+ 1 (id ν)) o)])
   (where ν (fresh-var o))])

(define-metafunction λDTR
  Int> : o -> τ
  [(Int> o) (ν : Int where [(≤ (+ 1 o) (id ν))])
   (where ν (fresh-var o))])


(define-metafunction λDTR
  Int<= : o -> τ
  [(Int<= o) (ν : Int where [(≤ (id ν) o)])
   (where ν (fresh-var o))])

(define-metafunction λDTR
  Int>= : o -> τ
  [(Int>= o) (ν : Int where [(≤ o (id ν))])
   (where ν (fresh-var o))])

(define-metafunction λDTR
  IntRange : o o -> τ
  [(IntRange o_l o_h) (ν : Int where (Φin-range (id ν) o_l o_h))
   (where ν (fresh-var o_l o_h))])

(define-metafunction λDTR
  Φ= : o o -> Φ
  [(Φ= o_1 o_2) [(≤ o_1 o_2) (≤ o_2 o_1)]])

(define-metafunction λDTR
  Φ< : o o -> Φ
  [(Φ< o_1 o_2) [(≤ (+ 1 o_1) o_2)]])

(define-metafunction λDTR
  Φin-range : o o o -> Φ
  [(Φin-range o o_low o_high) [(≤ o o_high)
                               (≤ o_low o)]])


(define-metafunction λDTR
  id : x -> o
  [(id x) (() @ x)])

(define-metafunction λDTR
  fresh-var : any ... -> x
  [(fresh-var any ...) ,(gensym 'ν)])

(define-metafunction λDTR
  ext : any any ... -> any
  [(ext [any_1 ...] any_2 ...) [any_1 ... any_2 ...]])

(define-metafunction λDTR
  o-car : o -> o
  [(o-car i) i]
  [(o-car (* 1 o)) (o-car o)]
  [(o-car (+ o_1 o_2)) (+ o_1 o_2)]
  [(o-car ((pe ...) @ x)) ((CAR pe ...) @ x)])

(define-metafunction λDTR
  o-cdr : o -> o
  [(o-cdr i) i]
  [(o-cdr (* 1 o)) (o-cdr o)]
  [(o-cdr (+ o_1 o_2)) (+ o_1 o_2)]
  [(o-cdr ((pe ...) @ x)) ((CDR pe ...) @ x)])

(define-metafunction λDTR
  o-len : o -> o
  [(o-len i) i]
  [(o-len (* 1 o)) (o-len o)]
  [(o-len (+ o_1 o_2)) (+ o_1 o_2)]
  [(o-len ((pe ...) @ x)) ((LEN pe ...) @ x)])



(define-metafunction λDTR
  exists/pair-τ : τ -> τ
  [(exists/pair-τ (τ × σ)) (τ × σ)]
  [(exists/pair-τ (x : τ where ψ)) (exists/pair-τ τ)]
  [(exists/pair-τ σ) (U)
   (where #f (is-Refine σ))
   (where #f (is-Pair σ))])

(define-metafunction λDTR
  exists/vec-τ : τ -> τ
  [(exists/vec-τ (♯ τ)) (♯ τ)]
  [(exists/vec-τ (x : τ where ψ)) (exists/vec-τ τ)]
  [(exists/vec-τ σ) (U)
   (where #f (is-Refine σ))
   (where #f (is-Vec σ))])

(define-metafunction λDTR
  exists/fun-τ : τ -> τ
  [(exists/fun-τ (x : σ → τ (ψ_+ ψ_- oo))) (x : σ → τ (ψ_+ ψ_- oo))]
  [(exists/fun-τ (x : τ where ψ)) (exists/fun-τ τ)]
  [(exists/fun-τ σ) (U)
   (where #f (is-Refine σ))
   (where #f (is-Abs σ))])

(define-metafunction λDTR
  fresh-if-needed : oo any ... -> o
  [(fresh-if-needed o any ...) o]
  [(fresh-if-needed Ø any ...) (id (fresh-var any ...))])


(define-judgment-form λDTR
  #:mode (in I I)
  #:contract (in any any)
  [(side-condition ,(list? (member (term any_1) (term (any_2 ...)))))
   --------------------- "In"
   (in any_1 (any_2 ...))])

(define-judgment-form λDTR
  #:mode (not-in I I)
  #:contract (not-in any any) 
  [(side-condition ,(not (member (term any_1) (term (any_2 ...)))))
   ------------------------ "Not-In"
   (not-in any_1 (any_2 ...))])

(define-judgment-form λDTR
  #:mode (<> I I)
  #:contract (<> any any)
  [------------ "NotEqual"
   (<> any_!_1 any_!_1)])

(define-metafunction λDTR
  len : (any ...) -> integer
  [(len (any ...)) ,(length (term (any ...)))])
