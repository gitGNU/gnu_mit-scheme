#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/machines/i386/rulfix.scm,v 1.3 1992/01/25 20:39:22 jinx Exp $
$MC68020-Header: /scheme/src/compiler/machines/bobcat/RCS/rules1.scm,v 4.36 1991/10/25 06:49:58 cph Exp $

Copyright (c) 1992 Massachusetts Institute of Technology

This material was developed by the Scheme project at the Massachusetts
Institute of Technology, Department of Electrical Engineering and
Computer Science.  Permission to copy this software, to redistribute
it, and to use it for any purpose is granted, subject to the following
restrictions and understandings.

1. Any copy made of this software must include this copyright notice
in full.

MOVB	vs.	MOVW
ADDB	vs.	ADDW
they make, so that these may be included in future releases; and (b)
The assembler assumes that it is always running in 32-bit mode.
It matters for immediate operands, displacements in addressing modes, and displacements in pc-relative jump  instructions.

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (ADDRESS->FIXNUM (OBJECT->ADDRESS (REGISTER (? source)))))
  (address->fixnum (standard-move-to-target! source target)))

(define-rule statement
  (ASSIGN (REGISTER (? target)) (OBJECT->FIXNUM (REGISTER (? source))))
  (object->fixnum (standard-move-to-target! source target)))

(define-rule statement
  (ASSIGN (REGISTER (? target)) (ADDRESS->FIXNUM (REGISTER (? source))))
  (address->fixnum (standard-move-to-target! source target)))

(define-rule statement
  (ASSIGN (REGISTER (? target)) (FIXNUM->OBJECT (REGISTER (? source))))
  (fixnum->object (standard-move-to-target! source target)))

(define-rule statement
  (ASSIGN (REGISTER (? target)) (FIXNUM->ADDRESS (REGISTER (? source))))
  (fixnum->address (standard-move-to-target! source target)))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (ADDRESS->FIXNUM (OBJECT->ADDRESS (CONSTANT (? constant)))))
  (convert-object/constant->register target constant address->fixnum))

(define-rule statement
  (ASSIGN (REGISTER (? target)) (OBJECT->FIXNUM (CONSTANT (? constant))))
  (load-fixnum-constant constant (target-register-reference target)))

;;;; Fixnum Operations

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FIXNUM-1-ARG (? operator) (REGISTER (? source)) (? overflow?)))
  overflow?				; ignored
  (fixnum-1-arg target source (fixnum-1-arg/operate operator)))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FIXNUM-2-ARGS (? operator)
			 (REGISTER (? source1))
			 (REGISTER (? source2))
			 (? overflow?)))
  overflow?				; ignored
  (case operator
    ((FIXNUM-LSH)
     (require-register! ecx))		; CL used as shift count
    ((FIXNUM-QUOTIENT FIXNUM-REMAINDER)
     (require-register! eax)		; dividend low/quotient
     (require-register! edx)))		; dividend high/remainder
  (fixnum-2-args target source1 source2 (fixnum-2-args/operate operator)))

(define (require-register! machine-reg)
  (flush-register! machine-reg)
  (need-register! machine-reg))

(define-integrable (flush-register! machine-reg)
  (prefix-instructions! (clear-registers! machine-reg)))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FIXNUM-2-ARGS (? operator)
			 (REGISTER (? source))
			 (OBJECT->FIXNUM (CONSTANT (? constant)))

(define-rule statement
  (fixnum-2-args/register*constant operator target source constant))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FIXNUM-2-ARGS MULTIPLY-FIXNUM
			 (OBJECT->FIXNUM (CONSTANT 4))
			 (OBJECT->FIXNUM (REGISTER (? source)))
			 (? overflow?)))
  overflow?				; ignored
  (convert-index->fixnum/register target source))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FIXNUM-2-ARGS MULTIPLY-FIXNUM
			 (OBJECT->FIXNUM (REGISTER (? source)))
			 (? overflow?)))
  (if (fixnum-2-args/commutative? operator)
      (fixnum-2-args/register*constant operator target source constant)
      (fixnum-2-args/constant*register operator target constant source)))
  (convert-index->fixnum/register target source))

;;;; Fixnum Predicates

(define-rule predicate
  (FIXNUM-PRED-1-ARG (? predicate) (REGISTER (? register)))
  (fixnum-branch! predicate)
  (LAP (CMP W ,(source-register-reference register) (& 0))))

(define-rule predicate
  (FIXNUM-PRED-1-ARG (? predicate) (OBJECT->FIXNUM (REGISTER (? register))))
  (fixnum-branch! predicate)
  (let ((temp (standard-move-to-temporary! register)))
    (object->fixnum temp)))

(define-rule predicate
  (FIXNUM-PRED-1-ARG (? predicate) (? memory))
  (QUALIFIER (predicate/memory-operand? memory))
  (fixnum-branch! predicate)
  (LAP (CMP W ,(predicate/memory-operand-reference memory) (& 0))))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate)
		      (REGISTER (? register-1))
		      (REGISTER (? register-2)))
  (fixnum-branch! predicate)
  (LAP (CMP W ,(source-register-reference register-1)
	     ,(source-register-reference register-2))))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate) (REGISTER (? register)) (? memory))
  (QUALIFIER (predicate/memory-operand? memory))
  (fixnum-branch! predicate)
  (LAP (CMP W ,(source-register-reference register)
	    ,(predicate/memory-operand-reference memory))))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate) (? memory) (REGISTER (? register)))
  (QUALIFIER (predicate/memory-operand? memory))
  (fixnum-branch! predicate)
  (LAP (CMP W ,(predicate/memory-operand-reference memory)
	    ,(source-register-reference register))))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate)
		      (REGISTER (? register))
		      (OBJECT->FIXNUM (CONSTANT (? constant))))
  (fixnum-branch! predicate)
  (LAP (CMP W ,(source-register-reference register)
	    (& ,(fixnum-object->fixnum-word constant)))))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate)
		      (OBJECT->FIXNUM (CONSTANT (? constant)))
		      (REGISTER (? register)))
  (fixnum-branch/commuted! predicate)
  (LAP (CMP W ,(source-register-reference register)
	    (& ,(fixnum-object->fixnum-word constant)))))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate)
		      (? memory)
		      (OBJECT->FIXNUM (CONSTANT (? constant))))
  (QUALIFIER (predicate/memory-operand? memory))
  (fixnum-branch! predicate)
  (LAP (CMP W ,(predicate/memory-operand-reference memory)
	    (& ,(fixnum-object->fixnum-word constant)))))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate)
		      (OBJECT->FIXNUM (CONSTANT (? constant)))
		      (? memory))
  (QUALIFIER (predicate/memory-operand? memory))
  (fixnum-branch/commuted! predicate)
  (LAP (CMP W ,(predicate/memory-operand-reference memory)
	    (& ,(fixnum-object->fixnum-word constant)))))

;; This assumes that the last instruction sets the condition code bits
;; correctly.

(define-rule predicate
  (OVERFLOW-TEST)
  (set-current-branches! (lambda (label) (LAP (JO (@PCR ,label))))
			 (lambda (label) (LAP (JNO (@PCR ,label)))))
  (LAP))

;;;; Utilities

(define (object->fixnum target)
  (SAL W ,target (& ,scheme-type-width)))

(define (fixnum->object target)
  (LAP (OR W ,target (& ,(ucode-type fixnum)))
       (ROR W ,target (& ,scheme-type-width))))

(define (address->fixnum target)
  (SAL W ,target (& ,scheme-type-width)))

(define (fixnum->address target)
  (SHR W ,target (& ,scheme-type-width)))

(define-integrable fixnum-1 64)		; (expt 2 scheme-type-width) ***

(define-integrable fixnum-bits-mask
  (-1+ fixnum-1))

(define (load-fixnum-constant constant target)
  (if (zero? constant)
      (LAP (XOR W ,target ,target))
      (LAP (MOV W ,target (& ,(* constant fixnum-1))))))

(define (convert-index->fixnum/register target source)
  (fixnum-1-arg target source
   (lambda (target)
     (LAP (SAL W ,target (& ,(+ scheme-type-width 2)))))))

;;;; Fixnum operation dispatch

(define (define-fixnum-method operator methods method)
  (let ((entry (assq operator (cdr methods))))
    (if entry
	(set-cdr! entry method)
	(set-cdr! methods (cons (cons operator method) (cdr methods)))))
  operator)

(define (lookup-fixnum-method operator methods)
  (cdr (or (assq operator (cdr methods))
	   (error "Unknown operator" operator))))

(define fixnum-methods/1-arg
  (list 'FIXNUM-METHODS/1-ARG))

(define-integrable (fixnum-1-arg/operate operator)
  (lookup-fixnum-method operator fixnum-methods/1-arg))

(define-integrable (fixnum-1-arg target source operation)
  (operation (standard-move-to-target! source)))

(define fixnum-methods/2-args
  (list 'FIXNUM-METHODS/2-ARGS))

(define-integrable (fixnum-2-args/operate operator)
  (lookup-fixnum-method operator fixnum-methods/2-args))

(define fixnum-methods/2-args-constant
  (list 'FIXNUM-METHODS/2-ARGS-CONSTANT))

(define-integrable (fixnum-2-args/operate-constant operator)
  (lookup-fixnum-method operator fixnum-methods/2-args-constant))

(define (fixnum-2-args/commutative? operator)
  (memq operator '(PLUS-FIXNUM
		   MULTIPLY-FIXNUM
		   FIXNUM-AND
		   FIXNUM-OR
		   FIXNUM-XOR)))
	     
(define (fixnum-2-args target source1 source2 operation)
  (two-arg-register-operation (fixnum-2-args/operate operator)
			      (fixnum-2-args/commutative? operator)
			      'GENERAL
			      any-reference
			      any-reference
			      target
			      source1
			      source2))

(define fixnum-methods/2-args-tnatsnoc
  (list 'FIXNUM-METHODS/2-ARGS-TNATSNOC))

(define-integrable (fixnum-2-args/operate-tnatsnoc operator)
  (lookup-fixnum-method operator fixnum-methods/2-args-tnatsnoc))

(define (two-arg-register-operation
	 operate commutative?
	 target-type source-reference alternate-source-reference
	 target source1 source2)
  (let ((worst-case
	 (lambda (target source1 source2)
	   (LAP ,@(if (eq? target-type 'FLOAT)
		      (load-float-register source1 target)
		      (LAP (MOV W ,target ,source1)))
		,@(operate target source2)))))
    (reuse-machine-target! target-type target
			      source-register-reference
	(reuse-pseudo-register-alias source1 target-type
	  (lambda (alias)
	    (let ((source2 (if (= source1 source2)
			       (register-reference alias)
			       (source-reference source2))))
	      (delete-register! alias)
	      (delete-dead-registers!)
	      (add-pseudo-register-alias! target alias)
	      (operate (register-reference alias) source2)))
	  (lambda ()
	    (let ((new-target-alias!
		   (lambda ()
		     (let ((source1 (alternate-source-reference source1))
			   (source2 (source-reference source2)))
		       (delete-dead-registers!)
		       (worst-case (reference-target-alias! target target-type)
				   source1
				   source2)))))
	      (if commutative?
		  (reuse-pseudo-register-alias source2 target-type
		    (lambda (alias2)
		      (let ((source1 (source-reference source1)))
			(delete-register! alias2)
			(delete-dead-registers!)
			(add-pseudo-register-alias! target alias2)
			(operate (register-reference alias2) source1)))
		    new-target-alias!)
		  (new-target-alias!))))))
      (lambda (target)
	(worst-case target
		    (alternate-source-reference source1)
		    (source-reference source2))))))

(define (fixnum-2-args/register*constant operator target source constant)
  (fixnum-1-arg
   target source
   (lambda (target)
     ((fixnum-2-args/operate-constant operator) target constant))))

;;;; Arithmetic operations

(define (integer-power-of-2? n)
  (let loop ((power 1) (exponent 0))
    (cond ((< n power) false)
	  ((= n power) exponent)
	  (else
	   (loop (* 2 power) (1+ exponent))))))

(define (word->fixnum target)
  (LAP (AND W ,target (& ,(fix:not fixnum-bits-mask)))))

(define (add-fixnum-constant target constant)
  (if (zero? constant)
      (LAP)
      (LAP (ADD W ,target (& ,(* constant fixnum-1))))))

(define (fixnum-2-args/constant*register operator target constant source)
  (fixnum-1-arg
   target source
   (lambda (target)
     ((fixnum-2-args/operate-tnatsnoc operator) target constant))))

(define-fixnum-method 'ONE-PLUS-FIXNUM fixnum-methods/1-arg
  (lambda (target)
    (add-fixnum-constant target 1)))

(define-fixnum-method 'MINUS-ONE-PLUS-FIXNUM fixnum-methods/1-arg
  (lambda (target)
    (add-fixnum-constant target -1)))

(define-fixnum-method 'FIXNUM-NOT fixnum-methods/1-arg
(define (word->fixnum/ea target)
    (LAP (NOT W ,target)
	 ,@(word->fixnum target))))

  (LAP (ADD W ,target (& ,(* constant fixnum-1)))))
	`(define-fixnum-method ',name fixnum-methods/2-args
	   (lambda (target source2)
	     (if (and ,idempotent? (equal? target source2))
		 (LAP)
		 (LAP (,instr W ,',target ,',source2))))))))

  (binary-operation PLUS-FIXNUM ADD false)
  (binary-operation MINUS-FIXNUM SUB false)
  (binary-operation FIXNUM-AND AND true)
  (binary-operation FIXNUM-OR OR true)
  (binary-operation FIXNUM-XOR XOR false))

(define-fixnum-method 'FIXNUM-ANDC fixnum-methods/2-args
  (lambda (target source2)
    (if (equal? target source2)
    ((binary/commutative
      (macro (name instr)
	  (LAP ,@(if (equal? temp source2)
		     (LAP)
	     (LAP (,instr W ,',target ,',source2))))))

     ;; **** Here ****

     (binary/noncommutative
      (macro (name instr)
	`(define-fixnum-method ',name fixnum-methods/2-args
	   (lambda (target source1 source2)
	     (cond ((ea/same? source1 source2)
		    (load-fixnum-constant 0 target))
		   ((eq? target source1)
		    (LAP (,instr L ,',source2 ,',target)))
		   (else
		    (LAP (,instr L ,',source2 ,',source1 ,',target)))))))))

  (binary/commutative PLUS-FIXNUM ADD)
  (binary/commutative FIXNUM-OR OR)
  (binary/commutative FIXNUM-XOR XOR)

  (binary/noncommutative MINUS-FIXNUM SUB)
  (binary/noncommutative FIXNUM-ANDC BIC))
	  ((even? scheme-type-width)
(define-fixnum-method 'FIXNUM-AND fixnum-methods/2-args
  (lambda (target source1 source2)
    (if (ea/same? source1 source2)
	(ea/copy source1 target)
	(let ((temp (standard-temporary-reference)))
	  (commute target source1 source2
		   (lambda (source*)
		     (LAP (MCOM L ,source* ,temp)
			  (BIC L ,temp ,target)))
		   (lambda ()
		     (LAP (MCOM L ,source1 ,temp)
			  (BIC L ,temp ,source2 ,target))))))))
    ;; SOURCE2 is guaranteed not to be ECX because of the
    ;; require-register! used in the rule.
  (let ((shift (- 0 scheme-type-width)))
    (lambda (target source1 source2)
      (if (not (effective-address/register? target))
	  (let ((temp (standard-temporary-reference)))
	    (commute target source1 source2
		     (lambda (source*)
		       (LAP (ASH L ,(make-immediate shift) ,source* ,temp)
			    (MUL L ,temp ,target)))
		     (lambda ()
		       (LAP (ASH L ,(make-immediate shift) ,source1 ,temp)
			    (MUL L ,temp ,source2 ,target)))))
	  (commute
	   target source1 source2
	   (lambda (source*)
	     (cond ((not (ea/same? target source*))
		    (LAP (ASH L ,(make-immediate shift) ,target ,target)
			 (MUL L ,source* ,target)))
		   ((even? scheme-type-width)
		    (let ((shift (quotient shift 2)))
		      (LAP (ASH L ,(make-immediate shift) ,target ,target)
			   (MUL L ,target ,target))))
		   (else
		    (let ((temp (standard-temporary-reference)))
		      (LAP (ASH L ,(make-immediate shift) ,target ,temp)
			   (MUL L ,temp ,target))))))
	   (lambda ()
	     (LAP (ASH L ,(make-immediate shift) ,source1 ,target)
		  (MUL L ,source2 ,target))))))))

(define (code-fixnum-shift target source1 source2)
  #|
  ;; This does arithmetic shifting, rather than logical!
  (let* ((rtarget (target-or-register target))
	 (temp (if (eq? rtarget target)
		   (standard-temporary-reference)
		   rtarget)))
    (LAP (ASH L ,(make-immediate (- 0 scheme-type-width))
	      ,source2 ,temp)
	 (ASH L ,temp ,source1 ,rtarget)
	 ,@(word->fixnum/ea rtarget target)))
  |#
  ;; This is a kludge that depends on the fact that there are
  ;; always scheme-type-width 0 bits at the bottom.
  (let* ((rtarget (target-or-register target))
	 (temp (standard-temporary-reference)))
    (LAP (ASH L ,(make-immediate (- 0 scheme-type-width))
	      ,source2 ,temp)
	 (ROTL (S 31) ,source1 ,rtarget) ; guarantee sign bit of 0.
	 (ASH L ,temp ,rtarget ,rtarget)
	 (ROTL (S 1) ,rtarget ,rtarget) ; undo effect of previous ROTL.
	 ,@(word->fixnum/ea rtarget target))))

		     (SHR W ,target (R ,ecx))
  code-fixnum-shift)
	      (LAP (MOV W (R ,eax) ,target)
  (lambda (target source1 source2)
  (lambda (target source1 source2)
    (if (ea/same? source1 source2)
	(LAP ,@(if (not (equal? target (INST-EA (R ,eax))))
	(code-fixnum-quotient target source1 source2))))
  (lambda (target n)
    (add-fixnum-constant target n)))

(define-fixnum-method 'MINUS-FIXNUM fixnum-methods/2-args-constant
  (lambda (target n)
	(code-fixnum-remainder target source1 source2))))

(define-fixnum-method 'FIXNUM-XOR fixnum-methods/2-args-constant
  (lambda (target source n)
    (add-fixnum-constant source n  target)))
	   (LAP))
	  ((= n -1)
  (lambda (target source n)
    (add-fixnum-constant source (- 0 n) target)))
	  (else
(define-fixnum-method 'MINUS-FIXNUM fixnum-methods/2-args-tnatsnoc
  (lambda (target n source)
    (if (zero? n)
	(LAP (MNEG L ,source ,target))
	(LAP (SUB L ,source ,(make-immediate (* n fixnum-1)) ,target)))))

(let-syntax
    ((binary-fixnum/constant
      (macro (name instr null ->constant identity?)
	`(define-fixnum-method ',name fixnum-methods/2-args-constant
	   (lambda (target source n)
	     (cond ((eqv? n ,null)
		    (load-fixnum-constant ,null target))
		   ((,identity? n)
		    (ea/copy source target))
		   (else
		    (let ((constant (* fixnum-1 (,->constant n))))
		      (if (ea/same? source target)
			  (LAP (,instr L ,',(make-immediate constant)
				       ,',target))
			  (LAP (,instr L ,',(make-immediate constant)
				       ,',source ,',target)))))))))))

  (binary-fixnum/constant FIXNUM-OR BIS -1 identity-procedure zero?)

  (binary-fixnum/constant FIXNUM-XOR XOR 'SELF identity-procedure zero?)

  (binary-fixnum/constant FIXNUM-AND BIC 0 fix:not
			  (lambda (n)
			    (= n -1))))
	   (LAP (SHL W ,target (& ,n))))
	  (else
  (lambda (target source n)
		,@(word->fixnum target))))))
	   (ea/copy source target))
;; **** Overflow not set by SAL instruction!
;; also (LAP) leaves condition codes as before, while they should
	  ((eq? target source)
	   (LAP (BIC L ,(make-immediate (* n fixnum-1)) ,target)))
;; clear the overflow flag! ****
	   (LAP (BIC L ,(make-immediate (* n fixnum-1)) ,source ,target))))))

(define-fixnum-method 'FIXNUM-ANDC fixnum-methods/2-args-tnatsnoc
  (lambda (target n source)
    (if (zero? n)
	(load-fixnum-constant 0 target)
	(LAP (BIC L ,source ,(make-immediate (* n fixnum-1)) ,target)))))

  (lambda (target n)
  (lambda (target source n)
	   (load-fixnum-constant 0 target))
	   (ea/copy source target))
	   (LAP))
	  ((= n -1)
	   (LAP (NEG W ,target)))
	   (LAP (ASH L ,(make-immediate n) ,source ,target)))
	  ;; The following two cases depend on having scheme-type-width
	  ;; 0 bits at the bottom.
	  ((>= n (- 0 scheme-type-width))
	   (let ((rtarget (target-or-register target)))
	     (LAP (ROTL (S ,(+ 32 n)) ,source ,rtarget)
		  ,@(word->fixnum/ea rtarget target))))
	   =>
	   (let ((rtarget (target-or-register target)))
	     (LAP (ROTL (S 31) ,source ,rtarget)
		  (ASH L ,(make-immediate (1+ n)) ,rtarget ,rtarget)
		  ,@(word->fixnum/ea rtarget target)))))))
		 (LAP (SAL W ,target (& ,expt-of-2))
(define-fixnum-method 'FIXNUM-LSH fixnum-methods/2-args-tnatsnoc
  (lambda (target n source)
    (if (zero? n)
	(load-fixnum-constant 0 target)
	(code-fixnum-shift target (make-immediate (* n fixnum-1)) source))))

		      (NEG W ,target))
  (lambda (target source n)
(define-fixnum-method 'FIXNUM-QUOTIENT fixnum-methods/2-args-constant
  (lambda (target n)
    (cond ((= n 1)
	   (ea/copy source target))
	  ((= n -1)
	   (LAP (MNEG L ,source ,target)))
	  ((integer-power-of-2? (if (negative? n) (- 0 n) n))
	   =>
	   (lambda (expt-of-2)
	     (let ((label (generate-label 'QUO-SHIFT))
		 (let ((rtarget (target-or-register target)))
		   (LAP (ASH L ,(make-immediate expt-of-2) ,source ,rtarget)
			(MNEG L ,rtarget ,target)))
		 (LAP (ASH L ,(make-immediate expt-of-2) ,source ,target)))))
	  ((eq? target source)
	   (LAP (MUL L ,(make-immediate n) ,target)))
		    (ADD W ,target (& ,(* (-1+ absn) fixnum-1)))
	   (LAP (MUL L ,(make-immediate n) ,source ,target))))))
		    ,@(if (negative? n)
			  (LAP (NEG W ,target))
			  (LAP))))))
	  (else
	   (error "Fixnum-quotient/constant: Bad value" n)))))

(define-fixnum-method 'FIXNUM-REMAINDER fixnum-methods/2-args-constant
  (lambda (target n)
    ;; (remainder x y) is 0 or has the sign of x.
    ;; Thus we can always "divide" by (abs y) to make things simpler.
    (let ((n (if (negative? n) (- 0 n) n)))
      (cond ((= n 1)
	     (load-fixnum-constant 0 target))
	    ((integer-power-of-2? n)
	     =>
	     (lambda (expt-of-2)
	       (let ((sign (temporary-register-reference))
		     (label (generate-label 'REM-MERGE))
		     (mask (-1+ (expt 2 nbits))))
		  ;; This may produce a branch to a branch, but a
		  ;; peephole optimizer should be able to fix this.
		 (LAP (MOV W ,sign ,target)
		      (SAR W ,sign (& ,(-1+ scheme-object-width)))
		      (XOR W ,sign (& ,mask))
		      (AND W ,target (& ,mask))
		      (JZ (@PCR ,label))
		      (OR W ,target ,sign)
		      (LABEL ,label)))))

(define-fixnum-method 'FIXNUM-QUOTIENT fixnum-methods/2-args-tnatsnoc
  (lambda (target n source)
    (if (zero? n)
	(load-fixnum-constant 0 target)
	(code-fixnum-quotient target (make-immediate (* n fixnum-1))
			      source))))
	    (else
	     (error "Fixnum-remainder/constant: Bad value" n))))))

;;;; Predicate utilities

;; **** Here ****

(define (signed-fixnum? n)
  (and (integer? n)
       (>= n signed-fixnum/lower-limit)
       (< n signed-fixnum/upper-limit)))

(define (unsigned-fixnum? n)
  (and (integer? n)
       (not (negative? n))
       (< n unsigned-fixnum/upper-limit)))

(define (guarantee-signed-fixnum n)
  (if (not (signed-fixnum? n)) (error "Not a signed fixnum" n))
  n)

(define (guarantee-unsigned-fixnum n)
  (if (not (unsigned-fixnum? n)) (error "Not a unsigned fixnum" n))
  n)

(define-fixnum-method 'FIXNUM-REMAINDER fixnum-methods/2-args-tnatsnoc
  (lambda (target n source)
    (if (zero? n)
	(load-fixnum-constant 0 target)
	(code-fixnum-remainder target (make-immediate (* n fixnum-1))
			       source))))

(define (fixnum-predicate->cc predicate)
  (case predicate
    ((EQUAL-FIXNUM? ZERO-FIXNUM?) 'EQL)
    ((LESS-THAN-FIXNUM? NEGATIVE-FIXNUM?) 'LSS)
    ((GREATER-THAN-FIXNUM? POSITIVE-FIXNUM?) 'GTR)
    (else
     (error "FIXNUM-PREDICATE->CC: Unknown predicate" predicate))))

(define-integrable (test-fixnum/ea ea)
  (LAP (TST L ,ea)))

(define (fixnum-predicate/register*constant register constant cc)
  (set-standard-branches! cc)
  (guarantee-signed-fixnum constant)
  (if (zero? constant)
      (test-fixnum/ea (any-register-reference register))
      (LAP (CMP L ,(any-register-reference register)
		,(make-immediate (* constant fixnum-1))))))

(define (fixnum-predicate/memory*constant memory constant cc)
  (set-standard-branches! cc)
  (guarantee-signed-fixnum constant)
  (if (zero? constant)
      (test-fixnum/ea memory)
      (LAP (CMP L ,memory ,(make-immediate (* constant fixnum-1))))))