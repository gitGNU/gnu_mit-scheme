;;; -*-Scheme-*-
;;;
;;;	$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/runtime/unpars.scm,v 13.51.1.1 1987/07/29 05:09:30 cph Exp $
;;;
;;;	Copyright (c) 1987 Massachusetts Institute of Technology
;;;
;;;	This material was developed by the Scheme project at the
;;;	Massachusetts Institute of Technology, Department of
;;;	Electrical Engineering and Computer Science.  Permission to
;;;	copy this software, to redistribute it, and to use it for any
;;;	purpose is granted, subject to the following restrictions and
;;;	understandings.
;;;
;;;	1. Any copy made of this software must include this copyright
;;;	notice in full.
;;;
;;;	2. Users of this software agree to make their best efforts (a)
;;;	to return to the MIT Scheme project any improvements or
;;;	extensions that they make, so that these may be included in
;;;	future releases; and (b) to inform MIT of noteworthy uses of
;;;	this software.
;;;
;;;	3. All materials developed as a consequence of the use of this
;;;	software shall duly acknowledge such use, in accordance with
;;;	the usual standards of acknowledging credit in academic
;;;	research.
;;;
;;;	4. MIT has made no warrantee or representation that the
;;;	operation of this software will be error-free, and MIT is
;;;	under no obligation to provide any services, by way of
;;;	maintenance, update, or otherwise.
;;;
;;;	5. In conjunction with products arising from the use of this
;;;	material, there shall be no use of the name of the
;;;	Massachusetts Institute of Technology nor of any adaptation
;;;	thereof in any advertising, promotional, or sales literature
;;;	without prior written consent from MIT in each case.
;;;

;;;; Unparser

(declare (usual-integrations))

;;; Control Variables

(define *unparser-radix* #d10)
(define *unparser-list-breadth-limit* false)
(define *unparser-list-depth-limit* false)

(define unparser-package
  (make-environment

(define *unparse-char)
(define *unparse-string)
(define *unparse-symbol)
(define *unparser-list-depth*)
(define *slashify*)

(define (unparse-with-brackets thunk)
  (*unparse-string "#[")
  (thunk)
  (*unparse-char #\]))

(define (unparse-object object port slashify)
  (fluid-let ((*unparse-char (access :write-char port))
	      (*unparse-string (access :write-string port))
	      (*unparser-list-depth* 0)
	      (*slashify* slashify)
	      (*unparse-symbol (if (unassigned? *unparse-symbol)
				   unparse-symbol
				   *unparse-symbol)))
    (*unparse-object-or-future object)))

(define (*unparse-object-or-future object)
  (if (future? object)
      (unparse-with-brackets
       (lambda ()
	 (*unparse-string "FUTURE ")
	 (unparse-datum object)))
      (*unparse-object object)))

(define (*unparse-object object)
  ((vector-ref dispatch-vector (primitive-type object)) object))

(define (*unparse-substring string start end)
  (*unparse-string (substring string start end)))

(define (unparse-default object)
  (unparse-with-brackets
   (lambda ()
     (*unparse-object (or (object-type object)
			  `(UNDEFINED-TYPE-CODE ,(primitive-type object))))
     (*unparse-char #\Space)
     (unparse-datum object))))

(define dispatch-vector
  (vector-cons number-of-microcode-types unparse-default))

(define (define-type type dispatcher)
  (vector-set! dispatch-vector (microcode-type type) dispatcher))

(define-type 'NULL
  (lambda (x)
    (if (eq? x '())
	(*unparse-string "()")
	(unparse-default x))))

(define-type 'TRUE
  (lambda (x)
    (if (eq? x true)
	(*unparse-string "#T")
	(unparse-default x))))

(define-type 'RETURN-ADDRESS
  (lambda (return-address)
    (unparse-with-brackets
     (lambda ()
       (*unparse-string "RETURN-ADDRESS ")
       (*unparse-object (return-address-name return-address))))))

(define (unparse-symbol symbol)
  (*unparse-string (symbol->string symbol)))

(define-type 'INTERNED-SYMBOL
  (lambda (symbol)
    (*unparse-symbol symbol)))

(define-type 'UNINTERNED-SYMBOL
  (lambda (symbol)
    (unparse-with-brackets
     (lambda ()
       (*unparse-string "UNINTERNED ")
       (unparse-symbol symbol)
       (*unparse-char #\Space)
       (*unparse-object (object-hash symbol))))))

(define-type 'CHARACTER
  (lambda (character)
    (if *slashify*
	(begin (*unparse-string "#\\")
	       (*unparse-string (char->name character true)))
	(*unparse-char character))))

(define-type 'STRING
  (let ((delimiters (char-set #\" #\\ #\Tab char:newline #\Page)))
    (lambda (string)
      (if *slashify*
	  (begin (*unparse-char #\")
		 (let ((end (string-length string)))
		   (define (loop start)
		     (let ((index (substring-find-next-char-in-set
				   string start end delimiters)))
		       (if index
			   (begin (*unparse-substring string start index)
				  (*unparse-char #\\)
				  (*unparse-char
				   (let ((char (string-ref string index)))
				     (cond ((char=? char #\Tab) #\t)
					   ((char=? char char:newline) #\n)
					   ((char=? char #\Page) #\f)
					   (else char))))
				  (loop (1+ index)))
			      (*unparse-substring string start end))))
		   (if (substring-find-next-char-in-set string 0 end
							delimiters)
		       (loop 0)
		       (*unparse-string string)))
		 (*unparse-char #\"))
	  (*unparse-string string)))))

(define-type 'VECTOR
  (let ((nmv-type (microcode-type 'manifest-nm-vector))
	(snmv-type  (microcode-type 'manifest-special-nm-vector)))
    (lambda (vector)
      (limit-unparse-depth
       (lambda ()
	 (let ((length (vector-length vector))
	       (element
		(lambda (index)
		  (if (with-interrupt-mask interrupt-mask-none
			(lambda (ie)
			  (or (primitive-type? nmv-type
					       (vector-ref vector index))
			      (primitive-type? snmv-type
					       (vector-ref vector index)))))
		      (error "Attempt to unparse partially marked vector" 0)
		      (vector-ref vector index)))))
	   (let ((normal
		  (lambda ()
		    (*unparse-string "#(")
		    (*unparse-object-or-future (element 0))
		    (let loop ((index 1))
		      (cond ((= index length)
			     (*unparse-char #\)))
			    ((and *unparser-list-breadth-limit*
				  (>= index *unparser-list-breadth-limit*))
			     (*unparse-string " ...)"))
			    (else
			     (*unparse-char #\Space)
			     (*unparse-object-or-future (element index))
			     (loop (1+ index))))))))
	     (cond ((zero? length)
		    (*unparse-string "#()"))
		   ((future? vector)
		    (normal))
		   (else
		    (let ((entry
			   (assq (element 0) *unparser-special-objects*)))
		      (if entry
			  ((cdr entry) vector)
			  (normal))))))))))))

(define *unparser-special-objects* '())

(define (add-unparser-special-object! key unparser)
  (set! *unparser-special-objects*
	(cons (cons key unparser)
	      *unparser-special-objects*))
  *the-non-printing-object*)

(define-type 'LIST
  (lambda (object)
    ((or (unparse-list/unparser object) unparse-list) object)))

(define (unparse-list list)
  (limit-unparse-depth
   (lambda ()
     (*unparse-char #\()
     (*unparse-object-or-future (car list))
     (unparse-tail (cdr list) 2)
     (*unparse-char #\)))))

(define (limit-unparse-depth kernel)
  (if *unparser-list-depth-limit*
      (fluid-let ((*unparser-list-depth* (1+ *unparser-list-depth*)))
	(if (> *unparser-list-depth* *unparser-list-depth-limit*)
	    (*unparse-string "...")
	    (kernel)))
      (kernel)))

(define (unparse-tail l n)
  (cond ((pair? l)
	 (let ((unparser (unparse-list/unparser l)))
	   (if unparser
	       (begin (*unparse-string " . ")
		      (unparser l))
	       (begin (*unparse-char #\Space)
		      (*unparse-object-or-future (car l))
		      (if (and *unparser-list-breadth-limit*
			       (>= n *unparser-list-breadth-limit*)
			       (not (null? (cdr l))))
			  (*unparse-string " ...")
			  (unparse-tail (cdr l) (1+ n)))))))
	((not (null? l))
	 (*unparse-string " . ")
	 (*unparse-object-or-future l))))

(define (unparse-list/unparser object)
  (cond ((future? (car object)) false)
	((unassigned-object? object) unparse-unassigned)
	((unbound-object? object) unparse-unbound)
	((reference-trap? object) unparse-reference-trap)
	((eq? (car object) 'QUOTE)
	 (and (pair? (cdr object))
	      (null? (cddr object))
	      unparse-quote-form))
	(else
	 (let ((entry (assq (car object) *unparser-special-pairs*)))
	   (and entry
		(cdr entry))))))

(define *unparser-special-pairs* '())

(define (add-unparser-special-pair! key unparser)
  (set! *unparser-special-pairs*
	(cons (cons key unparser)
	      *unparser-special-pairs*))
  *the-non-printing-object*)

(define (unparse-quote-form pair)
  (*unparse-char #\')
  (*unparse-object-or-future (cadr pair)))

(define (unparse-unassigned x)
  (unparse-with-brackets
   (lambda ()
     (*unparse-string "UNASSIGNED"))))

(define (unparse-unbound x)
  (unparse-with-brackets
   (lambda ()
     (*unparse-string "UNBOUND"))))

(define (unparse-reference-trap x)
  (unparse-with-brackets
   (lambda ()
     (*unparse-string "REFERENCE-TRAP ")
     (*unparse-object (reference-trap-kind x)))))

;;;; Procedures and Environments

(define (unparse-compound-procedure procedure)
  (unparse-with-brackets
   (lambda ()
     (*unparse-string "COMPOUND-PROCEDURE ")
     (lambda-components* (procedure-lambda procedure)
       (lambda (name required optional rest body)
	 (if (eq? name lambda-tag:unnamed)
	     (unparse-datum procedure)
	     (*unparse-object name)))))))

(define-type 'PROCEDURE unparse-compound-procedure)
(define-type 'EXTENDED-PROCEDURE unparse-compound-procedure)

(define (unparse-primitive-procedure proc)
  (unparse-with-brackets
   (lambda ()
     (*unparse-string "PRIMITIVE-PROCEDURE ")
     (*unparse-object (primitive-procedure-name proc)))))

(define-type 'PRIMITIVE unparse-primitive-procedure)
(define-type 'PRIMITIVE-EXTERNAL unparse-primitive-procedure)

(define-type 'ENVIRONMENT
  (lambda (environment)
    (if (lexical-unreferenceable? environment ':PRINT-SELF)
	(unparse-default environment)
	((access :print-self environment)))))

(define-type 'VARIABLE
  (lambda (variable)
    (unparse-with-brackets
     (lambda ()
       (*unparse-string "VARIABLE ")
       (*unparse-object (variable-name variable))))))

(define (unparse-datum object)
  (*unparse-string (number->string (primitive-datum object) 16)))

(define (unparse-number object)
  (*unparse-string (number->string object *unparser-radix*)))

(define-type 'FIXNUM unparse-number)
(define-type 'BIGNUM unparse-number)
(define-type 'FLONUM unparse-number)
(define-type 'COMPLEX unparse-number)

;;; end UNPARSER-PACKAGE.
))