#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/rtlgen/fndblk.scm,v 4.9.1.1 1988/11/30 05:33:50 cph Exp $

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

;;;; RTL Generation: Environment Locatives

(declare (usual-integrations))

(define (find-variable start-block variable offset if-compiler if-ic if-cached)
  (if (variable/value-variable? variable)
      (if-compiler
       (let ((continuation (block-procedure start-block)))
	 (if (continuation/ever-known-operator? continuation)
	     (continuation/register continuation)
	     register:value)))
      (find-variable-internal start-block variable offset
	(lambda (locative)
	  (if-compiler
	   (if (variable-in-cell? variable)
	       (rtl:make-fetch locative)
	       locative)))
	(lambda (block locative)
	  (cond ((variable-in-known-location? start-block variable)
		 (if-compiler
		  (rtl:locative-offset locative
				       (variable-offset block variable))))
		((ic-block/use-lookup? block)
		 (if-ic locative (variable-name variable)))
		(else
		 (if-cached (variable-name variable))))))))

(define (find-known-variable block variable offset)
  (find-variable block variable offset identity-procedure
    (lambda (environment name)
      environment
      (error "Known variable found in IC frame" name))
    (lambda (name)
      (error "Known variable found in IC frame" name))))

(define (find-closure-variable block variable offset)
  (find-variable-internal block variable offset
    identity-procedure
    (lambda (block locative)
      block locative
      (error "Closure variable in IC frame" variable))))

(define (find-variable-internal block variable offset if-compiler if-ic)
  (let ((rvalue (lvalue-known-value variable)))
    (cond ((not
	    (and rvalue
		 (rvalue/procedure? rvalue)
		 (procedure/closure? rvalue)
		 (block-ancestor-or-self? block (procedure-block rvalue))))
	   (find-block/variable block variable offset
	    (lambda (offset-locative)
	      (lambda (block locative)
		(if-compiler
		 (offset-locative locative (variable-offset block variable)))))
	    if-ic))
	  ;; This is just for paranoia.
	  ((procedure/trivial-closure? rvalue)
	   (error "FIND-VARIABLE-INTERNAL: Trivial closure value encountered"))
	  (else
	   (if-compiler
	    (stack-locative-offset
	     (block-ancestor-or-self->locative block
					       (procedure-block rvalue)
					       offset)
	     (procedure-closure-offset rvalue)))))))

(define (find-definition-variable block lvalue offset)
  (find-block/variable block lvalue offset
    (lambda (offset-locative)
      offset-locative
      (lambda (block locative)
	block locative
	(error "Definition of compiled variable" lvalue)))
    (lambda (block locative)
      block
      (return-2 locative (variable-name lvalue)))))

(define (find-block/variable block variable offset if-known if-ic)
  (find-block block
	      offset
	      (lambda (block)
		(if block
		    (or (memq variable (block-bound-variables block))
			(and (not (block-parent block))
			     (memq variable (block-free-variables block))))
		    (error "Unable to find variable" variable)))
    (lambda (block locative)
      ((enumeration-case block-type (block-type block)
	 ((STACK) (if-known stack-locative-offset))
	 ((CLOSURE) (if-known rtl:locative-offset))
	 ((IC) if-ic)
	 (else (error "Illegal result type" block)))
       block locative))))

(define (nearest-ic-block-expression block offset)
  (find-block block offset (lambda (block) (not (block-parent block)))
    (lambda (block locative)
      (if (ic-block? block)
	  locative
	  (error "NEAREST-IC-BLOCK-EXPRESSION: No IC block")))))

(define (closure-ic-locative closure-block block offset)
  (find-block closure-block offset (lambda (block*) (eq? block* block))
    (lambda (block locative)
      (if (ic-block? block)
	  locative
	  (error "Closure parent not IC block")))))

(define (block-ancestor-or-self->locative block block* offset)
  (find-block block offset (lambda (block) (eq? block block*))
    (lambda (block locative)
      (if (eq? block block*)
	  locative
	  (error "Block is not an ancestor" block*)))))

(define (popping-limit/locative block offset block* extra)
  (rtl:make-address
   (stack-locative-offset (block-ancestor-or-self->locative block
							    block*
							    offset)
			  (+ extra (block-frame-size block*)))))

(define (block-closure-locative block offset)
  ;; BLOCK must be the invocation block of a closure.
  (stack-locative-offset (rtl:make-fetch register:stack-pointer)
			 (+ (procedure-closure-offset (block-procedure block))
			    offset)))

(package (find-block)

(define-export (find-block block offset end-block? receiver)
  (transmit-values
      (find-block/loop block end-block? (find-block/initial block offset))
    receiver))

(define (find-block/initial block offset)
  (if (null? block)
      (begin
	(error "find-block/initial: Null block!" block)
	(rtl:make-fetch register:environment))
      (enumeration-case block-type (block-type block)
       ((STACK)
	(stack-locative-offset (rtl:make-fetch register:stack-pointer) offset))
       ((IC)
	(rtl:make-fetch register:environment))
       (else
	(error "Illegal initial block type" block)))))

(define (find-block/loop block end-block? locative)
  (cond ((null? block)
	 (error "find-block/loop: Null block!" block)
	 (return-2 block locative))
	((or (end-block? block)
	     (ic-block? block))
	 (return-2 block locative))
	(else
	 (find-block/loop (block-parent block)
			  end-block?
			  ((find-block/parent-procedure block)
			   block locative)))))

(define (find-block/parent-procedure block)
  (enumeration-case block-type (block-type block)
    ((STACK)
     (let ((parent (block-parent block)))
       (cond ((not (procedure/closure? (block-procedure block)))
	      (if parent
		  (enumeration-case block-type (block-type parent)
		   ((STACK) internal-block/parent-locative)
		   ((IC) stack-block/static-link-locative)
		   ((CLOSURE) (error "Closure parent of open procedure" block))
		   (else (error "Illegal procedure parent" parent)))
		  (error "Block has no parent" block)))
	     ((procedure/trivial-closure? (block-procedure block))
#|
	      ;; This case cannot signal an error because of the way that
	      ;; find-block/loop is written.  The locative for the
	      ;; parent is needed, although it will be ignored by the
	      ;; receiver once it finds out that the block is
	      ;; ic/non-existent.  The references are found by using
	      ;; the variable caches.
	      (error "Block corresponds to trivial closure")
|#
	      trivial-closure/bogus-locative)
	     ((not parent)
	      (error "Block has no parent" block))
	     (else
	      (enumeration-case
	       block-type (block-type parent)
	       ((STACK) (error "Closure has a stack parent" block))
	       ((IC) stack-block/parent-of-dummy-closure-locative)
	       ((CLOSURE) stack-block/closure-parent-locative)
	       (else (error "Illegal procedure parent" parent)))))))
    ((CLOSURE) closure-block/parent-locative)
    ((CONTINUATION) continuation-block/parent-locative)
    (else (error "Illegal parent block type" block))))

(define (find-block/same-block? block)
  (lambda (block*)
    (eq? block block*)))

(define (find-block/specific start-block end-block locative)
  (transmit-values
      (find-block/loop start-block (find-block/same-block? end-block) locative)
    (lambda (end-block locative)
      end-block
      locative)))

(define (internal-block/parent-locative block locative)
  (let ((link (block-stack-link block)))
    (if link
	(find-block/specific
	 link
	 (block-parent block)
	 (stack-locative-offset locative (block-frame-size block)))
	(stack-block/static-link-locative block locative))))

(define (continuation-block/parent-locative block locative)
  (stack-locative-offset locative
			 (+ (block-frame-size block)
			    (continuation/offset (block-procedure block)))))

(define (stack-block/static-link-locative block locative)
  (rtl:make-fetch
   (stack-locative-offset locative (-1+ (block-frame-size block)))))

(define (stack-block/closure-parent-locative block locative)
  (rtl:make-fetch
   (stack-locative-offset
    locative
    (procedure-closure-offset (block-procedure block)))))

;; This value should make anyone trying to look at it crash.

(define (trivial-closure/bogus-locative block locative)
  block locative
  'TRIVIAL-CLOSURE-BOGUS-LOCATIVE)

(define (closure-block/parent-locative block locative)
  block
  (rtl:make-fetch
   (rtl:locative-offset locative
			closure-block-first-offset)))

(define (stack-block/parent-of-dummy-closure-locative block locative)
  (closure-block/parent-locative
   block
   (stack-block/closure-parent-locative block locative)))

)