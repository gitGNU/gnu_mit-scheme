#| -*-Scheme-*-

$Id: macros.scm,v 4.22.2.2 2002/01/18 03:29:06 cph Exp $

Copyright (c) 1988-1999, 2001, 2002 Massachusetts Institute of Technology

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
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
02111-1307, USA.
|#

;;;; Compiler Macros
;;; package: (compiler macros)

(declare (usual-integrations))

(define-syntax last-reference
  (non-hygienic-macro-transformer
   (lambda (name)
     (let ((x (generate-uninterned-symbol)))
       `(IF COMPILER:PRESERVE-DATA-STRUCTURES?
	    ,name
	    (LET ((,x ,name))
	      (SET! ,name)
	      ,x))))))

(define-syntax package
  (rsc-macro-transformer
   (lambda (form environment)
     (if (not (syntax-match? '((* IDENTIFIER) * EXPRESSION) (cdr form)))
	 (error "Ill-formed special form:" form))
     (let ((names (cadr form))
	   (body (cddr form)))
       `(,(make-syntactic-closure environment '() 'BEGIN)
	 ,@(map (let ((r-define
		       (make-syntactic-closure environment '() 'DEFINE)))
		  (lambda (name)
		    `(,r-define ,name)))
		names)
	 (,(make-syntactic-closure environment '() 'LET) () ,@body))))))

(define-syntax define-export
  (rsc-macro-transformer
   (lambda (form environment)
     (cond ((syntax-match? '(IDENTIFIER EXPRESSION) (cdr form))
	    `(,(make-syntactic-closure environment '() 'SET!)
	      ,@(cdr form)))
	   ((syntax-match? '((IDENTIFIER . MIT-BVL) EXPRESSION) (cdr form))
	    `(,(make-syntactic-closure environment '() 'SET!)
	      ,(caadr form)
	      (,(make-syntactic-closure environment '() 'NAMED-LAMBDA)
	       ,@(cdr form))))
	   (else
	    (error "Ill-formed special form:" form))))))

(define-syntax define-vector-slots
  (non-hygienic-macro-transformer
   (lambda (class index . slots)
     (define (loop slots n)
       (if (pair? slots)
	   (let ((make-defs
		  (lambda (slot)
		    (let ((ref-name (symbol-append class '- slot)))
		      `(BEGIN
			 (DEFINE-INTEGRABLE (,ref-name ,class)
			   (VECTOR-REF ,class ,n))
			 (DEFINE-INTEGRABLE (,(symbol-append 'SET- ref-name '!)
					     ,class ,slot)
			   (VECTOR-SET! ,class ,n ,slot))))))
		 (rest (loop (cdr slots) (1+ n))))
	     (if (pair? (car slots))
		 (map* rest make-defs (car slots))
		 (cons (make-defs (car slots)) rest)))
	   '()))
     (if (pair? slots)
	 `(BEGIN ,@(loop slots index))
	 'UNSPECIFIC))))

(define-syntax define-root-type
  (non-hygienic-macro-transformer
   (lambda (type . slots)
     (let ((tag-name (symbol-append type '-TAG)))
       `(BEGIN (DEFINE ,tag-name
		 (MAKE-VECTOR-TAG #F ',type #F))
	       (DEFINE ,(symbol-append type '?)
		 (TAGGED-VECTOR/SUBCLASS-PREDICATE ,tag-name))
	       (DEFINE-VECTOR-SLOTS ,type 1 ,@slots)
	       (SET-VECTOR-TAG-DESCRIPTION!
		,tag-name
		(LAMBDA (,type)
		  (DESCRIPTOR-LIST ,type ,@slots))))))))

(define-syntax descriptor-list
  (non-hygienic-macro-transformer
   (lambda (type . slots)
     (let ((ref-name (lambda (slot) (symbol-append type '- slot))))
       `(LIST ,@(map (lambda (slot)
		       (if (pair? slot)
			   (let ((ref-names (map ref-name slot)))
			     ``(,',ref-names ,(,(car ref-names) ,type)))
			   (let ((ref-name (ref-name slot)))
			     ``(,',ref-name ,(,ref-name ,type)))))
		     slots))))))

(let-syntax
    ((define-type-definition
       (non-hygienic-macro-transformer
	(lambda (name reserved enumeration)
	  (let ((parent (symbol-append name '-TAG)))
	    `(define-syntax ,(symbol-append 'DEFINE- name)
	       (non-hygienic-macro-transformer
		(lambda (type . slots)
		  (let ((tag-name (symbol-append type '-TAG)))
		    `(BEGIN
		       (DEFINE ,tag-name
			 (MAKE-VECTOR-TAG ,',parent ',type ,',enumeration))
		       (DEFINE ,(symbol-append type '?)
			 (TAGGED-VECTOR/PREDICATE ,tag-name))
		       (DEFINE-VECTOR-SLOTS ,type ,,reserved ,@slots)
		       (SET-VECTOR-TAG-DESCRIPTION!
			,tag-name
			(LAMBDA (,type)
			  (APPEND!
			   ((VECTOR-TAG-DESCRIPTION ,',parent) ,type)
			   (DESCRIPTOR-LIST ,type ,@slots))))))))))))))
  (define-type-definition snode 5 #f)
  (define-type-definition pnode 6 #f)
  (define-type-definition rvalue 2 rvalue-types)
  (define-type-definition lvalue 14 #f))

;;; Kludge to make these compile efficiently.

(define-syntax make-snode
  (non-hygienic-macro-transformer
   (lambda (tag . extra)
     `((ACCESS VECTOR ,system-global-environment)
       ,tag #F '() '() #F ,@extra))))

(define-syntax make-pnode
  (non-hygienic-macro-transformer
   (lambda (tag . extra)
     `((ACCESS VECTOR ,system-global-environment)
       ,tag #F '() '() #F #F ,@extra))))

(define-syntax make-rvalue
  (non-hygienic-macro-transformer
   (lambda (tag . extra)
     `((ACCESS VECTOR ,system-global-environment)
       ,tag #F ,@extra))))

(define-syntax make-lvalue
  (non-hygienic-macro-transformer
   (lambda (tag . extra)
     (let ((result (generate-uninterned-symbol)))
       `(let ((,result
	       ((ACCESS VECTOR ,system-global-environment)
		,tag #F '() '() '() '() '() '() 'NOT-CACHED
		#F '() #F #F '() ,@extra)))
	  (SET! *LVALUES* (CONS ,result *LVALUES*))
	  ,result)))))

(define-syntax define-rtl-expression
  (non-hygienic-macro-transformer
   (lambda (type prefix . components)
     (rtl-common type prefix components
		 identity-procedure
		 'RTL:EXPRESSION-TYPES))))

(define-syntax define-rtl-statement
  (non-hygienic-macro-transformer
   (lambda (type prefix . components)
     (rtl-common type prefix components
		 (lambda (expression) `(STATEMENT->SRTL ,expression))
		 'RTL:STATEMENT-TYPES))))

(define-syntax define-rtl-predicate
  (non-hygienic-macro-transformer
   (lambda (type prefix . components)
     (rtl-common type prefix components
		 (lambda (expression) `(PREDICATE->PRTL ,expression))
		 'RTL:PREDICATE-TYPES))))

(define (rtl-common type prefix components wrap-constructor types)
  `(BEGIN
     (SET! ,types (CONS ',type ,types))
     (DEFINE-INTEGRABLE
       (,(symbol-append prefix 'MAKE- type) ,@components)
       ,(wrap-constructor `(LIST ',type ,@components)))
     (DEFINE-INTEGRABLE (,(symbol-append 'RTL: type '?) EXPRESSION)
       (EQ? (CAR EXPRESSION) ',type))
     ,@(let loop ((components components)
		  (ref-index 6)
		  (set-index 2))
	 (if (pair? components)
	     (let* ((slot (car components))
		    (name (symbol-append type '- slot)))
	       `((DEFINE-INTEGRABLE (,(symbol-append 'RTL: name) ,type)
		   (GENERAL-CAR-CDR ,type ,ref-index))
		 ,(let ((slot (if (eq? slot type)
				  (symbol-append slot '-VALUE)
				  slot)))
		    `(DEFINE-INTEGRABLE
		       (,(symbol-append 'RTL:SET- name '!)
			,type ,slot)
		       (SET-CAR! (GENERAL-CAR-CDR ,type ,set-index)
				 ,slot)))
		 ,@(loop (cdr components)
			 (* ref-index 2)
			 (* set-index 2))))
	     '()))))

(define-syntax define-rule
  (non-hygienic-macro-transformer
   (lambda (type pattern . body)
     (parse-rule pattern body
       (lambda (pattern variables qualifier actions)
	 `(,(case type
	      ((STATEMENT) 'ADD-STATEMENT-RULE!)
	      ((PREDICATE) 'ADD-STATEMENT-RULE!)
	      ((REWRITING) 'ADD-REWRITING-RULE!)
	      (else type))
	   ',pattern
	   ,(rule-result-expression variables qualifier
				    `(BEGIN ,@actions))))))))

;;;; LAP instruction sequences.

(define-syntax lap
  (non-hygienic-macro-transformer
   (lambda some-instructions
     (list 'QUASIQUOTE some-instructions))))

(define-syntax inst-ea
  (non-hygienic-macro-transformer
   (lambda (ea)
     (list 'QUASIQUOTE ea))))

(define-syntax define-enumeration
  (non-hygienic-macro-transformer
   (lambda (name elements)
     (let ((enumeration (symbol-append name 'S)))
       `(BEGIN (DEFINE ,enumeration
		 (MAKE-ENUMERATION ',elements))
	       ,@(map (lambda (element)
			`(DEFINE ,(symbol-append name '/ element)
			   (ENUMERATION/NAME->INDEX ,enumeration ',element)))
		      elements))))))

(define (macros/case-macro expression clauses predicate default)
  (let ((need-temp? (not (symbol? expression))))
    (let ((expression*
	   (if need-temp?
	       (generate-uninterned-symbol)
	       expression)))
      (let ((body
	     `(COND
	       ,@(let loop ((clauses clauses))
		   (cond ((not (pair? clauses))
			  (default expression*))
			 ((eq? (caar clauses) 'ELSE)
			  (if (pair? (cdr clauses))
			      (error "ELSE clause not last" clauses))
			  clauses)
			 (else
			  `(((OR ,@(map (lambda (element)
					  (predicate expression* element))
					(caar clauses)))
			     ,@(cdar clauses))
			    ,@(loop (cdr clauses)))))))))
	(if need-temp?
	    `(LET ((,expression* ,expression))
	       ,body)
	    body)))))

(define-syntax enumeration-case
  (non-hygienic-macro-transformer
   (lambda (name expression . clauses)
     (macros/case-macro expression
			clauses
			(lambda (expression element)
			  `(EQ? ,expression ,(symbol-append name '/ element)))
			(lambda (expression)
			  expression
			  '())))))

(define-syntax cfg-node-case
  (non-hygienic-macro-transformer
   (lambda (expression . clauses)
     (macros/case-macro expression
			clauses
			(lambda (expression element)
			  `(EQ? ,expression ,(symbol-append element '-TAG)))
			(lambda (expression)
			  `((ELSE
			     (ERROR "Unknown node type" ,expression))))))))