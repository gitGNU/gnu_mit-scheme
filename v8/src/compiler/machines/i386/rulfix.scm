#| -*-Scheme-*-

Copyright (c) 1992-1999 Massachusetts Institute of Technology

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
|#

;;;; LAP Generation Rules: Fixnum operations.
;;; package: (compiler lap-syntaxer)

(declare (usual-integrations))

;;;; Making and examining fixnums

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
  ((fixnum-2-args/operate operator) target source1 source2 overflow?))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FIXNUM-2-ARGS (? operator)
			 (REGISTER (? source))
			 (OBJECT->FIXNUM (CONSTANT (? constant)))
			 (? overflow?)))
  (QUALIFIER (or (and (not (eq? operator 'FIXNUM-QUOTIENT))
		      (not (eq? operator 'FIXNUM-REMAINDER)))
		 (integer-power-of-2? (abs constant))))
  (fixnum-2-args/register*constant operator target source constant overflow?))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FIXNUM-2-ARGS (? operator)
			 (OBJECT->FIXNUM (CONSTANT (? constant)))
			 (REGISTER (? source))
			 (? overflow?)))
  (QUALIFIER (fixnum-2-args/commutative? operator))
  (fixnum-2-args/register*constant operator target source constant overflow?))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FIXNUM-2-ARGS (? operator)
			 (OBJECT->FIXNUM (CONSTANT 0))
			 (REGISTER (? source))
			 (? overflow?)))
  (QUALIFIER (not (fixnum-2-args/commutative? operator)))
  overflow?				; ignored
  (if (eq? operator 'MINUS-FIXNUM)
      (fixnum-1-arg target source (fixnum-1-arg/operate 'FIXNUM-NEGATE))
      (load-fixnum-constant 0 (target-register-reference target))))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FIXNUM-2-ARGS MULTIPLY-FIXNUM
			 (OBJECT->FIXNUM (CONSTANT (? n)))
			 (OBJECT->FIXNUM (REGISTER (? source)))
			 #f))
  (fixnum-1-arg target source
   (lambda (target)
     (multiply-fixnum-constant target n false))))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FIXNUM-2-ARGS MULTIPLY-FIXNUM
			 (OBJECT->FIXNUM (REGISTER (? source)))
			 (OBJECT->FIXNUM (CONSTANT (? n)))
			 #f))
  (fixnum-1-arg target source
   (lambda (target)
     (multiply-fixnum-constant target n false))))

;;;; Fixnum Predicates

(define-rule predicate
  (FIXNUM-PRED-1-ARG (? predicate) (REGISTER (? register)))
  (fixnum-branch! (fixnum-predicate/unary->binary predicate))
  (LAP (CMP W ,(source-register-reference register) (& 0))))

(define-rule predicate
  (FIXNUM-PRED-1-ARG (? predicate) (OBJECT->FIXNUM (REGISTER (? register))))
  (QUALIFIER (or (eq? predicate 'NEGATIVE-FIXNUM?)
		 (eq? predicate 'ZERO-FIXNUM?)))
  (fixnum-branch! predicate)
  (object->fixnum (standard-move-to-temporary! register)))

(define-rule predicate
  (FIXNUM-PRED-1-ARG (? predicate) (? expression rtl:simple-offset?))
  (fixnum-branch! (fixnum-predicate/unary->binary predicate))
  (LAP (CMP W ,(offset->reference! expression) (& 0))))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate)
		      (REGISTER (? register-1))
		      (REGISTER (? register-2)))
  (fixnum-branch! predicate)
  (compare/register*register register-1 register-2))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate)
		      (REGISTER (? register))
		      (? expression rtl:simple-offset?))
  (fixnum-branch! predicate)
  (LAP (CMP W ,(source-register-reference register)
	    ,(offset->reference! expression))))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate)
		      (? expression rtl:simple-offset?)
		      (REGISTER (? register)))
  (fixnum-branch! predicate)
  (LAP (CMP W ,(offset->reference! expression)
	    ,(source-register-reference register))))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate)
		      (REGISTER (? register))
		      (OBJECT->FIXNUM (CONSTANT (? constant))))
  (fixnum-branch! predicate)
  (LAP (CMP W ,(source-register-reference register)
	    (& ,constant))))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate)
		      (OBJECT->FIXNUM (CONSTANT (? constant)))
		      (REGISTER (? register)))
  (fixnum-branch! (commute-fixnum-predicate predicate))
  (LAP (CMP W ,(source-register-reference register)
	    (& ,constant))))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate)
		      (? expression rtl:simple-offset?)
		      (OBJECT->FIXNUM (CONSTANT (? constant))))
  (fixnum-branch! predicate)
  (LAP (CMP W ,(offset->reference! expression)
	    (& ,constant))))

(define-rule predicate
  (FIXNUM-PRED-2-ARGS (? predicate)
		      (OBJECT->FIXNUM (CONSTANT (? constant)))
		      (? expression rtl:simple-offset?))
  (fixnum-branch! (commute-fixnum-predicate predicate))
  (LAP (CMP W ,(offset->reference! expression)
	    (& ,constant))))

;; This assumes that the immediately preceding instruction sets the
;; condition code bits correctly.

(define-rule predicate
  (OVERFLOW-TEST)
  (set-current-branches!
   (lambda (label)
     (LAP (JO (@PCR ,label))))
   (lambda (label)
     (LAP (JNO (@PCR ,label)))))
  (LAP))

;;;; Utilities

#| The following is now broken/obsolete in 8.x

 (define (object->fixnum target)
  (LAP (SAL W ,target (& ,scheme-type-width))))

;; Clearly wrong for the split typecodes:
;;(define (fixnum->object target)
;;  (LAP (OR W ,target (& ,(ucode-type fixnum)))
;;       (ROR W ,target (& ,scheme-type-width))))

(define (fixnum->object target)
  (LAP (OR W ,target (& ,(ucode-type positive-fixnum)))
       (ROR W ,target (& ,scheme-type-width))))

(define (address->fixnum target)
  (LAP (SAL W ,target (& ,scheme-type-width))))

(define (fixnum->address target)
  (LAP (SHR W ,target (& ,scheme-type-width))))

(define-integrable fixnum-1 64)		; (expt 2 scheme-type-width) ***

(define-integrable fixnum-bits-mask
  (-1+ fixnum-1))

(define (word->fixnum target)
  (LAP (AND W ,target (& ,(fix:not fixnum-bits-mask)))))

(define (integer-power-of-2? n)
  (let loop ((power 1) (exponent 0))
    (cond ((< n power) false)
	  ((= n power) exponent)
	  (else
	   (loop (* 2 power) (1+ exponent))))))

(define (load-fixnum-constant constant target)
  (if (zero? constant)
      (LAP (XOR W ,target ,target))
      (LAP (MOV W ,target (& ,constant)))))

(define (add-fixnum-constant target constant overflow?)
  (let ((value (* constant fixnum-1)))
    (cond ((and (zero? value) (not overflow?))
	   (LAP))
	  ((and (not (fits-in-signed-byte? value))
		(fits-in-signed-byte? (- value)))
	   (LAP (SUB W ,target (& ,(- value)))))
	  (else
	   (LAP (ADD W ,target (& ,value)))))))

(define (multiply-fixnum-constant target constant overflow?)
  (cond ((zero? constant)
	 (load-fixnum-constant 0 target))
	((= constant 1)
	 (if (not overflow?)
	     (LAP)
	     (add-fixnum-constant target 0 overflow?)))
	((= constant -1)
	 (LAP (NEG W ,target)))
	((and (not overflow?)
	      (integer-power-of-2? (abs constant)))
	 =>
	 (lambda (expt-of-2)
	   (if (negative? constant)
	       (LAP (SAL W ,target (& ,expt-of-2))
		    (NEG W ,target))
	       (LAP (SAL W ,target (& ,expt-of-2))))))
	(else
	 ;; target must be a register!
	 (LAP (IMUL W ,target ,target (& ,constant))))))
End of stuff broken during conversion to 8.x
|#


;;;; Operation tables

(define fixnum-methods/1-arg
  (list 'FIXNUM-METHODS/1-ARG))

(define-integrable (fixnum-1-arg/operate operator)
  (lookup-arithmetic-method operator fixnum-methods/1-arg))

(define-integrable (fixnum-1-arg target source operation)
  (operation (standard-move-to-target! source target)))

(define fixnum-methods/2-args
  (list 'FIXNUM-METHODS/2-ARGS))

(define-integrable (fixnum-2-args/operate operator)
  (lookup-arithmetic-method operator fixnum-methods/2-args))

(define fixnum-methods/2-args-constant
  (list 'FIXNUM-METHODS/2-ARGS-CONSTANT))

(define-integrable (fixnum-2-args/operate-constant operator)
  (lookup-arithmetic-method operator fixnum-methods/2-args-constant))

(define (fixnum-2-args/commutative? operator)
  (memq operator '(PLUS-FIXNUM
		   MULTIPLY-FIXNUM
		   FIXNUM-AND
		   FIXNUM-OR
		   FIXNUM-XOR)))
	     
(define ((fixnum-2-args/standard commutative? operate) target source1
						       source2 overflow?)
  overflow?				; ignored
  (two-arg-register-operation operate
			      commutative?
			      target
			      source1
			      source2))

(define (two-arg-register-operation operate commutative?
				    target source1 source2)
  (let* ((worst-case
	  (lambda (target source1 source2)
	    (if (and (equal? target source2)
		     (not (equal? target source1)))
		(error "two-arg-register-operation: about to overwrite source1 with source2"))
	    (LAP (MOV W ,target ,source1)
		 ,@(operate target source2))))
	 (new-target-alias!
	  (lambda ()
	    (let ((source1 (any-reference source1))
		  (source2 (any-reference source2)))
	      (delete-dead-registers!)
	      (worst-case (target-register-reference target)
			  source1
			  source2)))))
    (cond ((not (pseudo-register? target))
	   (if (not (eq? (register-type target) 'GENERAL))
	       (error "two-arg-register-operation: Wrong type register"
		      target 'GENERAL)
	       (begin
		 (require-register! target)
		 (worst-case (target-register-reference target)
			     (any-reference source1)
			     (any-reference source2)))))
	  ((register-copy-if-available source1 'GENERAL target)
	   =>
	   (lambda (get-alias-ref)
	     (if (= source2 source1)
		 (let ((ref (get-alias-ref)))
		   (operate ref ref))
		 (let ((source2 (any-reference source2)))
		   (operate (get-alias-ref) source2)))))
	  ((not commutative?)
	   (new-target-alias!))
	  ((register-copy-if-available source2 'GENERAL target)
	   =>
	   (lambda (get-alias-ref)
	     (let ((source1 (any-reference source1)))
	       (operate (get-alias-ref) source1))))
	  (else
	   (new-target-alias!)))))

(define (fixnum-2-args/register*constant operator target
					 source constant overflow?)
  (fixnum-1-arg
   target source
   (lambda (target)
     ((fixnum-2-args/operate-constant operator) target constant overflow?))))

;;;; Arithmetic operations

(define-arithmetic-method 'ONE-PLUS-FIXNUM fixnum-methods/1-arg
  (lambda (target)
    (add-fixnum-constant target 1 false)))

(define-arithmetic-method 'MINUS-ONE-PLUS-FIXNUM fixnum-methods/1-arg
  (lambda (target)
    (add-fixnum-constant target -1 false)))

(define-arithmetic-method 'FIXNUM-NOT fixnum-methods/1-arg
  (lambda (target)
    (LAP (NOT W ,target))))

(define-arithmetic-method 'FIXNUM-NEGATE fixnum-methods/1-arg
  (lambda (target)
    (LAP (NEG W ,target))))

(let-syntax
    ((binary-operation
      (macro (name instr commutative? idempotent?)
	`(define-arithmetic-method ',name fixnum-methods/2-args
	   (fixnum-2-args/standard
	    ,commutative?
	    (lambda (target source2)
	      (if (and ,idempotent? (equal? target source2))
		  (LAP)
		  (LAP (,instr W ,',target ,',source2)))))))))

  #| (binary-operation PLUS-FIXNUM ADD true false) |#
  (binary-operation MINUS-FIXNUM SUB false false)
  (binary-operation FIXNUM-AND AND true true)
  (binary-operation FIXNUM-OR OR true true)
  (binary-operation FIXNUM-XOR XOR true false))

(define-arithmetic-method 'PLUS-FIXNUM fixnum-methods/2-args
  (let* ((operate
	  (lambda (target source2)
	    (LAP (ADD W ,target ,source2))))
	 (standard (fixnum-2-args/standard true operate)))

  (lambda (target source1 source2 overflow?)
    (if overflow?
	(standard target source1 source2 overflow?)
	(let ((one (register-alias source1 'GENERAL))
	      (two (register-alias source2 'GENERAL)))
	  (cond ((not (and one two))
		 (standard target source1 source2 overflow?))
		((register-copy-if-available source1 'GENERAL target)
		 =>
		 (lambda (get-tgt)
		   (operate (get-tgt) (register-reference two))))
		((register-copy-if-available source2 'GENERAL target)
		 =>
		 (lambda (get-tgt)
		   (operate (get-tgt) (register-reference one))))
		(else
		 (let ((target (target-register-reference target)))
		   (LAP (LEA ,target (@RI ,one ,two 1)))))))))))

(define-arithmetic-method 'FIXNUM-ANDC fixnum-methods/2-args
  (fixnum-2-args/standard
   false
   (lambda (target source2)
     (if (equal? target source2)
	 (load-fixnum-constant 0 target)
	 (let ((temp (temporary-register-reference)))
	   (LAP ,@(if (equal? temp source2)
		      (LAP)
		      (LAP (MOV W ,temp ,source2)))
		(NOT W ,temp)
		(AND W ,target ,temp)))))))

(define-arithmetic-method 'MULTIPLY-FIXNUM fixnum-methods/2-args
  (fixnum-2-args/standard
   false
   (lambda (target source2)
     (cond ((not (equal? target source2))
	    (LAP (IMUL W ,target ,source2)))
	   ((even? scheme-type-width)
	    (display "fixnum test failed")
	    (display target)
	    (display source2)
	    (LAP (SAR W ,target (& ,(quotient scheme-type-width 2)))
		 (IMUL W ,target ,target)))
	   (else
	    (let ((temp (temporary-register-reference)))
	      (display "fixnum test failed")
	      (display target)
	      (display source2)
	      (LAP (MOV W ,temp ,target)
		   (SAR W ,target (& ,scheme-type-width))
		   (IMUL W ,target ,temp))))))))

(define-arithmetic-method 'FIXNUM-LSH fixnum-methods/2-args
  (let ((operate
	 (lambda (target source2)
	   ;; SOURCE2 is guaranteed not to be ECX because of the
	   ;; require-register! used below.
	   ;; TARGET can be ECX only if the rule has machine register
	   ;; ECX as the target, unlikely, but it must be handled!
	   (let ((with-target
		   (lambda (target)
		     (let ((jlabel (generate-label 'SHIFT-JOIN))
			   (slabel (generate-label 'SHIFT-NEGATIVE)))
		       (LAP (MOV W (R ,ecx) ,source2)
			    (OR W (R ,ecx) (R ,ecx))
			    (JS B (@PCR ,slabel))
			    (SHL W ,target (R ,ecx))
			    (JMP B (@PCR ,jlabel))
			    (LABEL ,slabel)
			    (NEG W (R ,ecx))
			    (SHR W ,target (R ,ecx))
			    (LABEL ,jlabel))))))

	     (if (not (equal? target (INST-EA (R ,ecx))))
		 (with-target target)
		 (let ((temp (temporary-register-reference)))
		   (LAP (MOV W ,temp ,target)
			,@(with-target temp)
			(MOV W ,target ,temp))))))))
    (lambda (target source1 source2 overflow?)
      overflow?				; ignored
      (require-register! ecx)
      (two-arg-register-operation operate
				  false
				  target
				  source1
				  source2))))

(define (do-division target source1 source2 result-reg)
  (prefix-instructions! (load-machine-register! source1 eax))
  (need-register! eax)
  (require-register! edx)
  (rtl-target:=machine-register! target result-reg)
  (let ((source2 (any-reference source2)))
    (LAP (MOV W (R ,edx) (R ,eax))
	 (SAR W (R ,edx) (& 31))
	 (IDIV W (R ,eax) ,source2))))

(define-arithmetic-method 'FIXNUM-QUOTIENT fixnum-methods/2-args
  (lambda (target source1 source2 overflow?)
    overflow?				; ignored
    (if (= source2 source1)
	(load-fixnum-constant 1 (target-register-reference target))
	(do-division target source1 source2 eax))))

(define-arithmetic-method 'FIXNUM-REMAINDER fixnum-methods/2-args
  (lambda (target source1 source2 overflow?)
    overflow?				; ignored
    (if (= source2 source1)
	(load-fixnum-constant 0 (target-register-reference target))
	(do-division target source1 source2 edx))))

(define-arithmetic-method 'PLUS-FIXNUM fixnum-methods/2-args-constant
  (lambda (target n overflow?)
    (add-fixnum-constant target n overflow?)))

(define-arithmetic-method 'MINUS-FIXNUM fixnum-methods/2-args-constant
  (lambda (target n overflow?)
    (add-fixnum-constant target (- 0 n) overflow?)))

(define-arithmetic-method 'FIXNUM-OR fixnum-methods/2-args-constant
  (lambda (target n overflow?)
    overflow?				; ignored
    (cond ((zero? n)
	   (LAP))
	  ((= n -1)
	   (load-fixnum-constant -1 target))
	  (else
	   (LAP (OR W ,target (& ,n)))))))

(define-arithmetic-method 'FIXNUM-XOR fixnum-methods/2-args-constant
  (lambda (target n overflow?)
    overflow?				; ignored
    (cond ((zero? n)
	   (LAP))
	  ((= n -1)
	   (LAP (NOT W ,target)))
	  ((<= 0 n 255)
	   (LAP (XOR B ,target (& ,n))))
	  (else
	   (LAP (XOR W ,target (& ,n)))))))

(define-arithmetic-method 'FIXNUM-AND fixnum-methods/2-args-constant
  (lambda (target n overflow?)
    overflow?				; ignored
    (cond ((zero? n)
	   (load-fixnum-constant 0 target))
	  ((= n -1)
	   (LAP))
	  (else
	   (LAP (AND W ,target (& ,n)))))))

(define-arithmetic-method 'FIXNUM-ANDC fixnum-methods/2-args-constant
  (lambda (target n overflow?)
    overflow?				; ignored
    (cond ((zero? n)
	   (LAP))
	  ((= n -1)
	   (load-fixnum-constant 0 target))
	  (else
	   (LAP (AND W ,target (& ,(fix:not n))))))))

(define-arithmetic-method 'FIXNUM-LSH fixnum-methods/2-args-constant
  (lambda (target n overflow?)
    overflow?				; ignored
    (cond ((zero? n)
	   (LAP))
	  ((not (<= (- 0 scheme-datum-width) n scheme-datum-width))
	   (load-fixnum-constant 0 target))
	  ((not (negative? n))
	   (LAP (SHL W ,target (& ,n))))
	  (else
	   (LAP (SHR W ,target (& ,(- 0 n))))))))

(define-arithmetic-method 'MULTIPLY-FIXNUM fixnum-methods/2-args-constant
  (lambda (target n overflow?)
    (multiply-fixnum-constant target n overflow?)))

(define-arithmetic-method 'FIXNUM-QUOTIENT fixnum-methods/2-args-constant
  (lambda (target n overflow?)
    overflow?				; ignored
    (cond ((= n 1)
	   (LAP))
	  ((= n -1)
	   (LAP (NEG W ,target)))
	  ((integer-power-of-2? (if (negative? n) (- 0 n) n))
	   =>
	   (lambda (expt-of-2)
	     (let ((label (generate-label 'QUO-SHIFT))
		   (absn (if (negative? n) (- 0 n) n)))
	       (LAP (CMP W ,target (& 0))
		    (JGE B (@PCR ,label))
		    (ADD W ,target (& ,(-1+ absn)))
		    (LABEL ,label)
		    (SAR W ,target (& ,expt-of-2))
		    ,@(if (negative? n)
			  (LAP (NEG W ,target))
			  (LAP))))))
	  (else
	   (error "Fixnum-quotient/constant: Bad value" n)))))

(define-arithmetic-method 'FIXNUM-REMAINDER fixnum-methods/2-args-constant
  (lambda (target n overflow?)
    ;; (remainder x y) is 0 or has the sign of x.
    ;; Thus we can always "divide" by (abs y) to make things simpler.
    overflow?				; ignored
    (let ((n (if (negative? n) (- 0 n) n)))
      (cond ((= n 1)
	     (load-fixnum-constant 0 target))
	    ((integer-power-of-2? n)
	     (let ((sign (temporary-register-reference))
		   (label (generate-label 'REM-MERGE)))
	       ;; This may produce a branch to a branch, but a
	       ;; peephole optimizer should be able to fix this.
	       (LAP (MOV W ,sign ,target)
		    (AND W ,target (& ,(-1+ n)))
		    (JZ B (@PCR ,label))
		    (SAR W ,sign (& ,scheme-object-width))
		    (AND W ,sign (& ,(- 0 n)))
		    (OR W ,target ,sign)
		    (LABEL ,label))))
	    (else
	     (error "Fixnum-remainder/constant: Bad value" n))))))

(define (fixnum-predicate/unary->binary predicate)
  (case predicate
    ((ZERO-FIXNUM?) 'EQUAL-FIXNUM?)
    ((NEGATIVE-FIXNUM?) 'LESS-THAN-FIXNUM?)
    ((POSITIVE-FIXNUM?) 'GREATER-THAN-FIXNUM?)
    (else
     (error "fixnum-predicate/unary->binary: Unknown unary predicate"
	    predicate))))

(define (commute-fixnum-predicate predicate)
  (case predicate
    ((EQUAL-FIXNUM?) 'EQUAL-FIXNUM?)
    ((LESS-THAN-FIXNUM?) 'GREATER-THAN-FIXNUM?)
    ((GREATER-THAN-FIXNUM?) 'LESS-THAN-FIXNUM?)
    (else
     (error "commute-fixnum-predicate: Unknown predicate"
	    predicate))))

(define (fixnum-branch! predicate)
  (case predicate
    ((EQUAL-FIXNUM? ZERO-FIXNUM?)
     (set-equal-branches!))
    ((LESS-THAN-FIXNUM?)
     (set-current-branches! (lambda (label)
			      (LAP (JL (@PCR ,label))))
			    (lambda (label)
			      (LAP (JGE (@PCR ,label))))))
    ((GREATER-THAN-FIXNUM?)
     (set-current-branches! (lambda (label)
			      (LAP (JG (@PCR ,label))))
			    (lambda (label)
			      (LAP (JLE (@PCR ,label))))))
    ((NEGATIVE-FIXNUM?)
     (set-current-branches! (lambda (label)
			      (LAP (JS (@PCR ,label))))
			    (lambda (label)
			      (LAP (JNS (@PCR ,label))))))
    ((POSITIVE-FIXNUM?)
     (error "fixnum-branch!: Cannot handle directly" predicate))
    (else
     (error "fixnum-branch!: Unknown predicate" predicate))))