#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/rtlopt/rcse2.scm,v 4.12 1989/10/26 07:39:27 cph Exp $

Copyright (c) 1988, 1989 Massachusetts Institute of Technology

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

;;;; RTL Common Subexpression Elimination
;;;  Based on the GNU C Compiler

(declare (usual-integrations))

;;;; Canonicalization

(define (expression-replace! statement-expression set-statement-expression!
			     statement receiver)
  ;; Replace the expression by its cheapest equivalent.  Returns two
  ;; values: (1) a flag which is true iff the expression is volatile;
  ;; and (2) a thunk which, when called, will insert the expression in
  ;; the hash table, returning the element.  Do not call the thunk if
  ;; the expression is volatile.
  (let ((expression
	 (expression-canonicalize (statement-expression statement))))
    (full-expression-hash expression
      (lambda (hash volatile? in-memory?)
	(let ((element
	       (find-cheapest-valid-element expression hash volatile?)))
	  (let ((finish
		 (lambda (expression hash volatile? in-memory?)
		   (set-statement-expression! statement expression)
		   (receiver volatile?
			     (expression-inserter expression
						  element
						  hash
						  in-memory?)))))
	    (if element
		(let ((expression (element-expression element)))
		  (full-expression-hash expression
		    (lambda (hash volatile? in-memory?)
		      (finish expression hash volatile? in-memory?))))
		(finish expression hash volatile? in-memory?))))))))

(define ((expression-inserter expression element hash in-memory?))
  (or element
      (begin
	(if (rtl:register? expression)
	    (set-register-expression! (rtl:register-number expression)
				      expression)
	    (mention-registers! expression))
	(let ((element* (hash-table-insert! hash expression false)))
	  (set-element-in-memory?! element* in-memory?)
	  (element-first-value element*)))))

(define (expression-canonicalize expression)
  (cond ((rtl:register? expression)
	 (or (register-expression
	      (quantity-first-register
	       (get-register-quantity (rtl:register-number expression))))
	     expression))
	((stack-reference? expression)
	 (let ((register
		(quantity-first-register
		 (stack-reference-quantity expression))))
	   (or (and register (register-expression register))
	       expression)))
	(else
	 (rtl:map-subexpressions expression expression-canonicalize))))

;;;; Hash

(define (expression-hash expression)
  (full-expression-hash expression
    (lambda (hash do-not-record? hash-arg-in-memory?)
      do-not-record? hash-arg-in-memory?
      hash)))

(define (full-expression-hash expression receiver)
  (let ((do-not-record? false)
	(hash-arg-in-memory? false))
    (define (loop expression)
      (let ((type (rtl:expression-type expression)))
	(+ (symbol-hash type)
	   (case type
	     ((REGISTER)
	      (quantity-number
	       (get-register-quantity (rtl:register-number expression))))
	     ((OFFSET)
	      ;; Note that stack-references do not get treated as
	      ;; memory for purposes of invalidation.  This is because
	      ;; (supposedly) no one ever accesses the stack directly
	      ;; except the compiler's output, which is explicit.
	      (if (interpreter-stack-pointer? (rtl:offset-register expression))
		  (quantity-number (stack-reference-quantity expression))
		  (begin
		    (set! hash-arg-in-memory? true)
		    (continue expression))))
	     ((BYTE-OFFSET)
	      (set! hash-arg-in-memory? true)
	      (continue expression))
	     ((PRE-INCREMENT POST-INCREMENT)
	      (set! hash-arg-in-memory? true)
	      (set! do-not-record? true)
	      0)
	     (else
	      (continue expression))))))

    (define (continue expression)
      (rtl:reduce-subparts expression + 0 loop
	(lambda (object)
	  (cond ((integer? object) (inexact->exact object))
		((symbol? object) (symbol-hash object))
		((string? object) (string-hash object))
		(else (hash object))))))

    (let ((hash (loop expression)))
      (receiver (modulo hash (hash-table-size))
		do-not-record?
		hash-arg-in-memory?))))

;;;; Table Search

(define (find-cheapest-expression expression hash volatile?)
  ;; Find the cheapest equivalent expression for EXPRESSION.
  (let ((element (find-cheapest-valid-element expression hash volatile?)))
    (if element
	(element-expression element)
	expression)))

(define (find-cheapest-valid-element expression hash volatile?)
  ;; Find the cheapest valid hash table element for EXPRESSION.
  ;; Returns false if no such element exists or if EXPRESSION is
  ;; VOLATILE?.
  (and (not volatile?)
       (let ((element (hash-table-lookup hash expression)))
	 (and element
	      (let ((element* (element-first-value element)))
		(if (eq? element element*)
		    element
		    (let loop ((element element*))
		      (and element
			   (let ((expression (element-expression element)))
			     (if (or (rtl:register? expression)
				     (expression-valid? expression))
				 element
				 (loop (element-next-value element))))))))))))

(define (expression-valid? expression)
  ;; True iff all registers mentioned in EXPRESSION have valid values
  ;; in the hash table.
  (if (rtl:register? expression)
      (let ((register (rtl:register-number expression)))
	(= (register-in-table register) (register-tick register)))
      (rtl:all-subexpressions? expression expression-valid?)))

(define (element->class element)
  ;; Return the cheapest element in the hash table which has the same
  ;; value as `element'.  This is necessary because `element' may have
  ;; been deleted due to register or memory invalidation.
  (and element
       ;; If `element' has been deleted from the hash table,
       ;; `element-first-value' will be false.  [ref crock-1]
       (or (element-first-value element)
	   (element->class (element-next-value element)))))

;;;; Insertion

(define (insert-register-destination! expression element)
  ;; Insert EXPRESSION, which should be a register expression, into
  ;; the hash table as the destination of an assignment.  ELEMENT is
  ;; the hash table element for the value being assigned to
  ;; EXPRESSION.
  (let ((register (rtl:register-number expression)))
    (set-register-expression! register expression)
    (let ((quantity (get-element-quantity element)))
      (if quantity
	  (begin
	    (set-register-quantity! register quantity)
	    (let ((last (quantity-last-register quantity)))
	      (cond ((not last)
		     (set-quantity-first-register! quantity register)
		     (set-register-next-equivalent! register false))
		    (else
		     (set-register-next-equivalent! last register)
		     (set-register-previous-equivalent! register last))))
	    (set-quantity-last-register! quantity register)))))
  (set-element-in-memory?! (hash-table-insert! (expression-hash expression)
					       expression
					       (element->class element))
			   false))

(define (insert-stack-destination! expression element)
  (let ((quantity (get-element-quantity element)))
    (if quantity
	(set-stack-reference-quantity! expression quantity)))
  (set-element-in-memory?! (hash-table-insert! (expression-hash expression)
					       expression
					       (element->class element))
			   false))

(define (get-element-quantity element)
  (let loop ((element (element->class element)))
    (and element
	 (let ((expression (element-expression element)))
	   (cond ((rtl:register? expression)
		  (get-register-quantity (rtl:register-number expression)))
		 ((stack-reference? expression)
		  (stack-reference-quantity expression))
		 (else
		  (loop (element-next-value element))))))))

(define (insert-memory-destination! expression element hash)
  (let ((class (element->class element)))
    (mention-registers! expression)
    ;; Optimization: if class and hash are both false, hash-table-insert!
    ;; makes an element which is not connected to the rest of the table.
    ;; In that case, there is no need to make an element at all.
    (if (or class hash)
	(set-element-in-memory?! (hash-table-insert! hash expression class)
				 true))))

(define (mention-registers! expression)
  (if (rtl:register? expression)
      (let ((register (rtl:register-number expression)))
	(remove-invalid-references! register)
	(set-register-in-table! register (register-tick register)))
      (rtl:for-each-subexpression expression mention-registers!)))

(define (remove-invalid-references! register)
  ;; If REGISTER is invalid, delete from the hash table all
  ;; expressions which refer to it.
  (if (let ((in-table (register-in-table register)))
	(and (not (negative? in-table))
	     (not (= in-table (register-tick register)))))
      (let ((expression (register-expression register)))
	(hash-table-delete-class!
	 (lambda (element)
	   (let ((expression* (element-expression element)))
	     (and (not (rtl:register? expression*))
		  (expression-refers-to? expression* expression)))))))
  unspecific)

;;;; Invalidation

(define (non-object-invalidate!)
  (hash-table-delete-class!
   (lambda (element)
     (rtl:non-object-valued-expression? (element-expression element)))))

(define (varying-address-invalidate!)
  (hash-table-delete-class!
   (lambda (element)
     (and (element-in-memory? element)
	  (expression-address-varies? (element-expression element))))))

(define (expression-invalidate! expression)
  ;; Delete from the table any expression which refers to this
  ;; expression.
  (if (rtl:register? expression)
      (register-expression-invalidate! expression)
      (hash-table-delete-class!
       (lambda (element)
	 (expression-refers-to? (element-expression element) expression)))))

(define (register-expression-invalidate! expression)
  ;; Invalidate a register expression.  These expressions are handled
  ;; specially for efficiency -- the register is marked invalid but we
  ;; delay searching the hash table for relevant expressions.
  (let ((register (rtl:register-number expression))
	(hash (expression-hash expression)))
    (register-invalidate! register)
    ;; If we're invalidating the stack pointer, delete its entries
    ;; immediately.
    (if (interpreter-stack-pointer? expression)
	(mention-registers! expression)
	(hash-table-delete! hash (hash-table-lookup hash expression)))))

(define (register-invalidate! register)
  (let ((next (register-next-equivalent register))
	(previous (register-previous-equivalent register))
	(quantity (get-register-quantity register)))
    (set-register-tick! register (1+ (register-tick register)))
    (if next
	(set-register-previous-equivalent! next previous)
	(set-quantity-last-register! quantity previous))
    (if previous
	(set-register-next-equivalent! previous next)
	(set-quantity-first-register! quantity next))
    (set-register-quantity! register (new-quantity register))
    (set-register-next-equivalent! register false)
    (set-register-previous-equivalent! register false))
  unspecific)