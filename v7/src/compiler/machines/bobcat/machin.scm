#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/machines/bobcat/machin.scm,v 4.10.1.1 1988/08/25 19:48:00 markf Exp $

Copyright (c) 1988 Massachusetts Institute of Technology

This material was developed by the Scheme project at the Massachusetts
Institute of Technology, Department of Electrical Engineering and
Computer Science.  Permission to copy this software, to redistribute
it, and to use it for any purpose is granted, subject to the following
restrictions and understandings.

1. Any copy made of this software must include this copyright notice
in full.

2. Users of this software agree to make their best efforts (a) to
return to the MIT Scheme project any improvements or extensions that
they make, so that these may be included in future releases; and (b)
to inform MIT of noteworthy uses of this software.

3. All materials developed as a consequence of the use of this
software shall duly acknowledge such use, in accordance with the usual
standards of acknowledging credit in academic research.

4. MIT has made no warrantee or representation that the operation of
this software will be error-free, and MIT is under no obligation to
provide any services, by way of maintenance, update, or otherwise.

5. In conjunction with products arising from the use of this material,
there shall be no use of the name of the Massachusetts Institute of
Technology nor of any adaptation thereof in any advertising,
promotional, or sales literature without prior written consent from
MIT in each case. |#

;;;; Machine Model for 68020

(declare (usual-integrations))
;;; Size of words.  Some of the stuff in "assmd.scm" might want to
;;; come here.

(define-integrable addressing-granularity 8)
(define-integrable scheme-object-width 32)
(define-integrable scheme-datum-width 24)
(define-integrable scheme-type-width 8)
(define maximum-unsigned-fixnum
  (expt 2 scheme-datum-width))
(define maximum-positive-fixnum
  (-1+ (quotient maximum-unsigned-fixnum 2)))

(define-integrable (stack->memory-offset offset)
  offset)

(define ic-block-first-parameter-offset
  2)

(define closure-block-first-offset
  2)

(define (rtl:machine-register? rtl-register)
  (case rtl-register
    ((STACK-POINTER) (interpreter-stack-pointer))
    ((DYNAMIC-LINK) (interpreter-dynamic-link))
    ((INTERPRETER-CALL-RESULT:ACCESS) (interpreter-register:access))
    ((INTERPRETER-CALL-RESULT:CACHE-REFERENCE)
     (interpreter-register:cache-reference))
    ((INTERPRETER-CALL-RESULT:CACHE-UNASSIGNED?)
     (interpreter-register:cache-unassigned?))
    ((INTERPRETER-CALL-RESULT:LOOKUP) (interpreter-register:lookup))
    ((INTERPRETER-CALL-RESULT:UNASSIGNED?) (interpreter-register:unassigned?))
    ((INTERPRETER-CALL-RESULT:UNBOUND?) (interpreter-register:unbound?))
    (else false)))

(define (rtl:interpreter-register? rtl-register)
  (case rtl-register
    ((MEMORY-TOP) 0)
    ((STACK-GUARD) 1)
    ((VALUE) 2)
    ((ENVIRONMENT) 3)
    ((TEMPORARY) 4)
    ((INTERPRETER-CALL-RESULT:ENCLOSE) 5)
    (else false)))

(define (rtl:interpreter-register->offset locative)
  (or (rtl:interpreter-register? locative)
      (error "Unknown register type" locative)))

(define (rtl:expression-cost expression)
  ;; Returns an estimate of the cost of evaluating the expression.
  ;; For simplicity, we try to estimate the actual number of cycles
  ;; that a typical code sequence would produce.
  (case (rtl:expression-type expression)
    ((ASSIGNMENT-CACHE VARIABLE-CACHE) 16) ;move.l d(pc),reg
    ((CONS-POINTER)
     ;; Best case = 12 cycles, worst =  44
     ;; move.l reg,d(reg) = 16
     ;; move.b reg,d(reg) = 12
     ;; move.l d(reg),reg = 16
     (+ 30
	(rtl:expression-cost (rtl:cons-pointer-type expression))
	(rtl:expression-cost (rtl:cons-pointer-datum expression))))
    ((CONSTANT)
     (let ((value (cadr expression)))
       (cond ((false? value) 4)		;clr.l reg
	     ((or (eq? value true)
		  (char? value)
		  (and (integer? value)
		       (<= -#x80000000 value #x7FFFFFFF)))
	      12)			;move.l #...,reg
	     (else 16))))		;move.l d(pc),reg
    ;; lea d(pc),reg       =  8
    ;; move.l reg,d(reg)   = 16
    ;; move.b #type,d(reg) = 16
    ;; move.l d(reg),reg   = 16
    ((ENTRY:CONTINUATION ENTRY:PROCEDURE) 56)
    ((OBJECT->ADDRESS OBJECT->DATUM) 6)	;and.l d7,reg
    ;; move.l reg,d(reg) = 16
    ;; move.b d(reg),reg = 12
    ((OBJECT->TYPE) 28)
    ;; lsl.l #8,reg = 4
    ;; asr.l #8,reg = 6
    ((OBJECT->FIXNUM) 10)
    ;; and.l d7,reg         = 3
    ;; or.1  #x01AFFFFF,reg = 8
    ((FIXNUM->OBJECT) 11)		
    ((OFFSET) 16)			;move.l d(reg),reg
    ((OFFSET-ADDRESS) 8)		;lea d(an),reg
    ((POST-INCREMENT) 12)		;move.l (reg)+,reg
    ((PRE-INCREMENT) 14)		;move.l -(reg),reg
    ((REGISTER) 4)			;move.l reg,reg
    ((UNASSIGNED) 12)			;move.l #data,reg
    ((FIXNUM-2-ARGS)
     (case (rtl:fixnum-2-args-operator expression)
       ;; move.l reg,reg = 3
       ;; add.l  reg,reg = 3
       ((PLUS-FIXNUM) 6)
       ;; move.l reg,reg = 3
       ;; muls.l reg,reg = 49
       ((MULTIPLY-FIXNUM) 52)
       ;; move.l reg,reg = 3
       ;; sub.l  reg,reg = 3
       ((MINUS-FIXNUM) 6)
       (else
	(error "RTL:EXPRESSION-COST: unknown fixnum operator" expression))))
    ((FIXNUM-1-ARG)
     (case (rtl:fixnum-1-arg-operator expression)
       ;; move.l reg,reg = 3
       ;; addq.l #1,reg = 3
       ((ONE-PLUS-FIXNUM) 6)
       ;; move.l reg,reg = 3
       ;; subq.l #1,reg = 3
       ((MINUS-ONE-PLUS-FIXNUM) 6)
       (else
	(error "RTL:EXPRESSION-COST: unknown fixnum operator" expression))))
    ;; The numbers for generic ops are crocks. Depending on the types
    ;; of the operands we may do as little as two checks and a fixnum
    ;; operation or as much as a call to the runtime generic
    ;; procedure. All in all we will consider this to be very expensive.
    ((GENERIC-BINARY) 500)
    ((GENERIC-UNARY) 500)
    ;; The following are preliminary. Check with Jinx (mhwu)
    ;; The following are preliminary. Check with Jinx (mhwu)
    ((CHAR->ASCII) 4)
    ((BYTE-OFFSET) 12)
    (else (error "Unknown expression type" expression))))

(define-integrable d0 0)
(define-integrable d1 1)
(define-integrable d2 2)
(define-integrable d3 3)
(define-integrable d4 4)
(define-integrable d5 5)
(define-integrable d6 6)
(define-integrable d7 7)
(define-integrable a0 8)
(define-integrable a1 9)
(define-integrable a2 10)
(define-integrable a3 11)
(define-integrable a4 12)
(define-integrable a5 13)
(define-integrable a6 14)
(define-integrable a7 15)
(define number-of-machine-registers 16)
(define number-of-temporary-registers 50)

(define-integrable regnum:dynamic-link a4)
(define-integrable regnum:free-pointer a5)
(define-integrable regnum:regs-pointer a6)
(define-integrable regnum:stack-pointer a7)

(define-integrable (sort-machine-registers registers)
  registers)

(define available-machine-registers
  (list d0 d1 d2 d3 d4 d5 d6 a0 a1 a2 a3))

(define initial-address-registers
  (list a4 a5 a6 a7))

(define-integrable (pseudo-register=? x y)
  (= (register-renumber x) (register-renumber y)))

(define register-type
  (let ((types (make-vector 16)))
    (let loop ((i 0) (j 8))
      (if (< i 8)
	  (begin (vector-set! types i 'DATA)
		 (vector-set! types j 'ADDRESS)
		 (loop (1+ i) (1+ j)))))
    (lambda (register)
      (vector-ref types register))))

(define register-reference
  (let ((references (make-vector 16)))
    (let loop ((i 0) (j 8))
      (if (< i 8)
	  (begin (vector-set! references i (INST-EA (D ,i)))
		 (vector-set! references j (INST-EA (A ,i)))
		 (loop (1+ i) (1+ j)))))    (lambda (register)
      (vector-ref references register))))

(define mask-reference (INST-EA (D 7)))

(define-integrable (interpreter-register:access)
  (rtl:make-machine-register d0))

(define-integrable (interpreter-register:cache-reference)
  (rtl:make-machine-register d0))

(define-integrable (interpreter-register:cache-unassigned?)
  (rtl:make-machine-register d0))

(define-integrable (interpreter-register:enclose)
  (rtl:make-offset (interpreter-regs-pointer) 5))

(define-integrable (interpreter-register:lookup)
  (rtl:make-machine-register d0))

(define-integrable (interpreter-register:unassigned?)
  (rtl:make-machine-register d0))

(define-integrable (interpreter-register:unbound?)
  (rtl:make-machine-register d0))

(define-integrable (interpreter-free-pointer)
  (rtl:make-machine-register regnum:free-pointer))

(define-integrable (interpreter-free-pointer? register)
  (= (rtl:register-number register) regnum:free-pointer))

(define-integrable (interpreter-regs-pointer)
  (rtl:make-machine-register regnum:regs-pointer))

(define-integrable (interpreter-regs-pointer? register)
  (= (rtl:register-number register) regnum:regs-pointer))

(define-integrable (interpreter-stack-pointer)
  (rtl:make-machine-register regnum:stack-pointer))

(define-integrable (interpreter-stack-pointer? register)
  (= (rtl:register-number register) regnum:stack-pointer))

(define-integrable (interpreter-dynamic-link)
  (rtl:make-machine-register regnum:dynamic-link))

(define-integrable (interpreter-dynamic-link? register)
  (= (rtl:register-number register) regnum:dynamic-link))