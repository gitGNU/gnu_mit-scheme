d3 1
a4 1
$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/rtlgen/rgrval.scm,v 4.11.1.2 1988/12/12 21:29:31 cph Exp $
#| -*-Scheme-*-
Copyright (c) 1988 Massachusetts Institute of Technology
$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/rtlgen/rgrval.scm,v 4.11.1.2 1988/12/12 21:29:31 cph Exp $

Copyright (c) 1988, 1990 Massachusetts Institute of Technology

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

;;;; RTL Generation: RValues
;;; package: (compiler rtl-generator generate/rvalue)
(define (generate/rvalue operand scfg*cfg->cfg! generator)
  (with-values (lambda () (generate/rvalue* operand))

(define (generate/rvalue operand scfg*cfg->cfg! generator)
  (with-values (lambda () (generate/rvalue* operand))
(define (generate/rvalue* operand)
  ((method-table-lookup rvalue-methods (tagged-vector/index operand)) operand))

(define (generate/rvalue* operand)
  ((method-table-lookup rvalue-methods (tagged-vector/index operand)) operand))

(define rvalue-methods
  (values (make-null-cfg) expression))

(define-integrable (expression-value/simple expression)
  (values (make-null-cfg) expression))

     (values (scfg*scfg->scfg! prefix assignment) reference))
  (load-temporary-register
   (lambda (assignment reference)
     (values (scfg*scfg->scfg! prefix assignment) reference))
   result
  (lambda (constant)
    (expression-value/simple (rtl:make-constant (constant-value constant)))))
(define-method-table-entry 'CONSTANT rvalue-methods
  (lambda (constant)
  (lambda (block)
    block ;; ignored
(define-method-table-entry 'BLOCK rvalue-methods

    block ;; ignored
  (lambda (reference)
    (let ((context (reference-context reference))
(define-method-table-entry 'REFERENCE rvalue-methods
  (lambda (reference)
    (let ((context (reference-context reference))
	  (safe? (reference-safe? reference)))
	     (lambda ()
	       (find-variable context lvalue
		(lambda (locative)
		  (expression-value/simple (rtl:make-fetch locative)))
		(lambda (environment name)
		  (expression-value/temporary
		   (rtl:make-interpreter-call:lookup
		    environment
		    (intern-scode-variable! (reference-context/block context)
					    name)
		    safe?)
		   (rtl:interpreter-call-result:lookup)))
		(lambda (name)
		  (if (memq 'IGNORE-REFERENCE-TRAPS
			    (variable-declarations lvalue))
		      (load-temporary-register values
					       (rtl:make-variable-cache name)
					       rtl:make-fetch)
		      (generate/cached-reference name safe?)))))))
	(cond ((not value) (perform-fetch))
			  lvalue))
	       (generate/rvalue* value))
	      ((not (rvalue/procedure? value))
	       (generate/rvalue* value))
	      (else (perform-fetch)))))))

(define (generate/cached-reference name safe?)
	       (perform-fetch #| lvalue |#)))))))
    (values
     (load-temporary-register scfg*scfg->scfg! (rtl:make-variable-cache name)
  (let ((result (rtl:make-pseudo-register)))
    (values
     (load-temporary-register scfg*scfg->scfg! (rtl:make-variable-cache name)
       (lambda (cell)
	 (let ((reference (rtl:make-fetch cell)))
		 (n4 (rtl:make-interpreter-call:cache-reference cell safe?))
		  (wrap-with-continuation-entry
		   context
		   (rtl:make-interpreter-call:cache-reference cell safe?)))
		 (n5
		  (rtl:make-assignment
		   result
		   (rtl:interpreter-call-result:cache-reference))))
	     (pcfg-alternative-connect! n2 n3)
	     (scfg-next-connect! n4 n5)
	     (if safe?
		 (let ((n6 (rtl:make-unassigned-test reference))
		       ;; Make new copy of n3 to keep CSE happy.
		       ;; Otherwise control merge will confuse it.
		       (n7 (rtl:make-assignment result reference)))
		   (pcfg-consequent-connect! n2 n6)
		   (pcfg-consequent-connect! n6 n7)
		   (pcfg-alternative-connect! n6 n4)
		   (make-scfg (cfg-entry-node n2)
			      (hooks-union
			       (scfg-next-hooks n3)
			       (hooks-union (scfg-next-hooks n5)
					    (scfg-next-hooks n7)))))
		 (begin
		   (pcfg-consequent-connect! n2 n4)
		   (make-scfg (cfg-entry-node n2)
			      (hooks-union (scfg-next-hooks n3)
					   (scfg-next-hooks n5)))))))))
  (lambda (procedure)

(define-method-table-entry 'PROCEDURE rvalue-methods
      ((TRIVIAL-CLOSURE)
       (expression-value/simple (make-trivial-closure-cons procedure)))
    (case (procedure/type procedure)
       (load-temporary-register
	(lambda (assignment reference)
	  (values
	   (scfg*scfg->scfg!
	    assignment
	    (load-closure-environment procedure reference))
	   reference))
	(make-non-trivial-closure-cons procedure)
	identity-procedure))
	 (else
       (make-ic-cons procedure))
	   (make-cons-closure-indirection procedure)))))
      ((IC)
       (make-ic-cons procedure))
      ((OPEN-EXTERNAL OPEN-INTERNAL)
       (if (not (procedure-virtual-closure? procedure))
	   (error "Reference to open procedure" procedure))

(define (make-trivial-closure-cons procedure)
  (enqueue-procedure! procedure)
  (rtl:make-cons-pointer
   (rtl:make-constant type-code:compiled-entry)
   (rtl:make-entry:procedure (procedure-label procedure))))

(define (make-ic-cons procedure)
  ;; IC procedures have their entry points linked into their headers
  ;; at load time by the linker.
  (let ((header
	  (scode/make-lambda (procedure-name procedure)
			     (map variable-name
				  (procedure-required-arguments procedure))
			     (map variable-name (procedure-optional procedure))
			     (let ((rest (procedure-rest procedure)))
			       (and rest (variable-name rest)))
			     (map variable-name (procedure-names procedure))
			     '()
			     false)))
    (let ((kernel
	   (lambda (scfg expression)
	     (values scfg
		     (rtl:make-typed-cons:pair
		      (rtl:make-constant (scode/procedure-type-code header))
		      (rtl:make-constant header)
		      expression)))))
      (set! *ic-procedure-headers*
	    (cons (cons header (procedure-label procedure))
		  *ic-procedure-headers*))
      (let ((context (procedure-closure-context procedure)))
	(if (reference? context)
	    (with-values (lambda () (generate/rvalue* context))
	      kernel)
	    ;; Is this right if the procedure is being closed
	    ;; inside another IC procedure?
	    (kernel (make-null-cfg)
		    (rtl:make-fetch register:environment)))))))
	    ;; inside another IC procedure?
(define (make-non-trivial-closure-cons procedure)
  (rtl:make-cons-pointer
   (rtl:make-constant type-code:compiled-entry)
   (with-values (lambda () (procedure-arity-encoding procedure))
     (lambda (min max)
       (rtl:make-cons-closure
	(rtl:make-entry:procedure (procedure-label procedure))
	min
	max
	(procedure-closure-size procedure))))))

(define (load-closure-environment procedure closure-locative)
  (define (load-closure-parent block force?)
    (if (and (not force?)
	     (or (not block)
		 (not (ic-block/use-lookup? block))))
	(make-null-cfg)
	(rtl:make-assignment
	 (rtl:locative-offset closure-locative closure-block-first-offset)
	 (if (not (ic-block/use-lookup? block))
	     (rtl:make-constant false)
	     (let ((context (procedure-closure-context procedure)))
	       (if (not (reference-context? context))
		   (error "load-closure-environment: bad closure context"
			  procedure))
	       (if (ic-block? (reference-context/block context))
		   (rtl:make-fetch register:environment)
		   (closure-ic-locative context block)))))))
  (enqueue-procedure! procedure)
  (let ((block (procedure-closing-block procedure)))
(define (make-non-trivial-closure-cons procedure block**)
	   (make-null-cfg))
	  ((ic-block? block)
	   (load-closure-parent block true))
	  ((closure-block? block)
	   (let ((context (procedure-closure-context procedure)))
	     (let loop
		 ((entries (block-closure-offsets block))
		  (code (load-closure-parent (block-parent block) false)))
	     (let loop
		 ((entries (block-closure-offsets block))
		  (code (load-closure-parent (block-parent block) false)))
	       (if (null? entries)
		   code
				    (reference-context/procedure context))
		   (loop (cdr entries)
			 (scfg*scfg->scfg!
			  (rtl:make-assignment
			   (rtl:locative-offset closure-locative
						(cdar entries))
			   (let* ((variable (caar entries))
				  (value (lvalue-known-value variable)))
			     (cond
			      ;; Paranoia.
			      ((and value
				    (rvalue/procedure? value)
			      ((eq? value
				    (reference-context/procedure context))
					   value variable))
				(block-closure-locative context)))
			      ((eq? value
			       (rtl:make-fetch
				(find-closure-variable context variable))))))
			  code))))))
	  (else
	   (error "Unknown block type" block)))))			       (find-closure-variable context variable)))))
			  code)))))
	     (error "Unknown block type" block))))))
	     (error "Unknown block type" block))))))
