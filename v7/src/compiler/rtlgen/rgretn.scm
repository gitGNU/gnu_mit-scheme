#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/rtlgen/rgretn.scm,v 4.8.1.2 1988/12/12 21:29:25 cph Exp $

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

;;;; RTL Generation: Return Statements

(declare (usual-integrations))

(define (generate/return return)
  (generate/return* (return/context return)
		    (return/operator return)
		    false
		    (trivial-return-operand (return/operand return))))

(define (generate/trivial-return context operator operand)
  (generate/return* context operator false (trivial-return-operand operand)))

(define (trivial-return-operand operand)
  (make-return-operand
   (lambda ()
     (make-null-cfg))
   (lambda (finish)
     (generate/rvalue operand scfg*scfg->scfg!
       (lambda (expression)
	 (finish (rtl:make-true-test expression)))))
   (lambda (finish)
     (generate/rvalue operand scfg*scfg->scfg! finish))
   (rvalue-known-value operand)))

(define-structure (return-operand (conc-name return-operand/))
  (effect-generator false read-only true)
  (predicate-generator false read-only true)
  (value-generator false read-only true)
  (known-value false read-only true))

(define-integrable (effect-prefix operand)
  ((return-operand/effect-generator operand)))

(define (generate/return* context operator not-on-stack? operand)
  (let ((continuation (rvalue-known-value operator)))
    (if continuation
	((method-table-lookup simple-methods (continuation/type continuation))
	 (if not-on-stack?
	     (return-operator/pop-frames context operator 0)
	     (scfg*scfg->scfg!
	      (return-operator/pop-frames
	       context
	       operator
	       (if (continuation/always-known-operator? continuation) 0 1))
	      (generate/continuation-entry/pop-extra continuation)))
	 operand
	 continuation)
	(scfg-append!
	 ((return-operand/value-generator operand)
	  (lambda (expression)
	    (rtl:make-assignment register:value expression)))
	 (return-operator/pop-frames context operator 0)
	 (rtl:make-pop-return)))))

(define simple-methods
  (make-method-table continuation-types false))

(define-method-table-entry 'EFFECT simple-methods
  (lambda (prefix operand continuation)
    (scfg-append!
     (effect-prefix operand)
     prefix
     (generate/node (continuation/entry-node continuation)))))

(define-method-table-entries '(REGISTER VALUE) simple-methods
  (lambda (prefix operand continuation)
    (scfg-append!
     (if (lvalue-integrated? (continuation/parameter continuation))
	 (effect-prefix operand)
	 ((return-operand/value-generator operand)
	  (lambda (expression)
	    (rtl:make-assignment (continuation/register continuation)
				 expression))))
     prefix
     (generate/node (continuation/entry-node continuation)))))

(define-method-table-entry 'PUSH simple-methods
  (lambda (prefix operand continuation)
    (scfg*scfg->scfg!
     (if (cfg-null? prefix)
	 ((return-operand/value-generator operand) rtl:make-push)
	 (use-temporary-register operand prefix rtl:make-push))
     (generate/node (continuation/entry-node continuation)))))

(define-method-table-entry 'PREDICATE simple-methods
  (lambda (prefix operand continuation)
    (let ((node (continuation/entry-node continuation))
	  (value (return-operand/known-value operand)))
      (if value
	  (scfg-append!
	   (effect-prefix operand)
	   prefix
	   (generate/node (if (and (rvalue/constant? value)
				   (false? (constant-value value)))
			      (pnode-alternative node)
			      (pnode-consequent node))))
	  (let ((finish
		 (lambda (pcfg)
		   (pcfg*scfg->scfg!
		    pcfg
		    (generate/node (pnode-consequent node))
		    (generate/node (pnode-alternative node))))))
	    (if (cfg-null? prefix)
		((return-operand/predicate-generator operand) finish)
		(use-temporary-register operand prefix
		  (lambda (expression)
		    (finish (rtl:make-true-test expression))))))))))

(define (use-temporary-register operand prefix finish)
  (let ((register (rtl:make-pseudo-register)))
    (let ((setup-register
	   ((return-operand/value-generator operand)
	    (lambda (expression)
	      (rtl:make-assignment register expression)))))
      (scfg-append!
       setup-register
       prefix
       (finish (rtl:make-fetch register))))))

(define (return-operator/pop-frames context operator extra)
  (let ((block (reference-context/block context))
	(pop-extra
	 (lambda ()
	   (if (zero? extra)
	       (make-null-cfg)
	       (rtl:make-assignment register:stack-pointer
				    (rtl:make-address
				     (stack-locative-offset
				      (rtl:make-fetch register:stack-pointer)
				      extra)))))))
    (if (or (ic-block? block)
	    (return-operator/subproblem? operator))
	(pop-extra)
	(let ((popping-limit (block-popping-limit block)))
	  (cond ((not popping-limit)
		 (scfg*scfg->scfg!
		  (rtl:make-link->stack-pointer)
		  (pop-extra)))
		((and (eq? popping-limit (reference-context/block context))
		      (zero? (block-frame-size popping-limit))
		      (zero? (reference-context/offset context))
		      (zero? extra))
		 (make-null-cfg))
		(else
		 (rtl:make-assignment register:stack-pointer
				      (popping-limit/locative context
							      popping-limit
							      0
							      extra))))))))