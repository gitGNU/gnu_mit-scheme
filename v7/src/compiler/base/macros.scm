#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/base/macros.scm,v 1.58.1.1 1987/06/10 19:36:10 cph Exp $

Copyright (c) 1987 Massachusetts Institute of Technology

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

;;;; Compiler Macros

(declare (usual-integrations))

(define compiler-syntax-table
  (make-syntax-table system-global-syntax-table))

(define lap-generator-syntax-table
  (make-syntax-table compiler-syntax-table))

(define assembler-syntax-table
  (make-syntax-table compiler-syntax-table))

(syntax-table-define compiler-syntax-table 'PACKAGE
  (in-package system-global-environment
    (declare (usual-integrations))
    (lambda (expression)
      (apply (lambda (names . body)
	       (make-sequence
		`(,@(map (lambda (name)
			   (make-definition name (make-unassigned-object)))
			 names)
		  ,(make-combination
		    (let ((block (syntax* body)))
		      (if (open-block? block)
			  (open-block-components block
			    (lambda (names* declarations body)
			      (make-lambda lambda-tag:let '() '() false
					   (list-transform-negative names*
					     (lambda (name)
					       (memq name names)))
					   declarations
					   body)))
			  (make-lambda lambda-tag:let '() '() false '()
				       '() block)))
		    '()))))
	     (cdr expression)))))

(define enable-integration-declarations
  true)

(let ()

(define (parse-define-syntax pattern body if-variable if-lambda)
  (cond ((pair? pattern)
	 (let loop ((pattern pattern) (body body))
	   (cond ((pair? (car pattern))
		  (loop (car pattern) `((LAMBDA ,(cdr pattern) ,@body))))
		 ((symbol? (car pattern))
		  (if-lambda pattern body))
		 (else
		  (error "Illegal name" parse-define-syntax (car pattern))))))
	((symbol? pattern)
	 (if-variable pattern body))
	(else
	 (error "Illegal name" parse-define-syntax pattern))))

(define lambda-list->bound-names
  (let ((accumulate
	 (lambda (lambda-list)
	   (cons (let ((parameter (car lambda-list)))
		   (if (pair? parameter) (car parameter) parameter))
		 (lambda-list->bound-names (cdr lambda-list))))))
    (named-lambda (lambda-list->bound-names lambda-list)
      (cond ((symbol? lambda-list)
	     lambda-list)
	    ((null? lambda-list) '())
	    ((not (pair? lambda-list))
	     (error "Illegal rest variable" lambda-list))
	    ((eq? (car lambda-list)
		  (access lambda-optional-tag lambda-package))
	     (if (pair? (cdr lambda-list))
		 (accumulate (cdr lambda-list))
		 (error "Missing optional variable" lambda-list)))
	    (else
	     (accumulate lambda-list))))))

(syntax-table-define compiler-syntax-table 'DEFINE-EXPORT
  (macro (pattern . body)
    (parse-define-syntax pattern body
      (lambda (name body)
	`(SET! ,pattern ,@body))
      (lambda (pattern body)
	`(SET! ,(car pattern)
	       (NAMED-LAMBDA ,pattern ,@body))))))

(syntax-table-define compiler-syntax-table 'DEFINE-INTEGRABLE
  (macro (pattern . body)
    (if enable-integration-declarations
	(parse-define-syntax pattern body
	  (lambda (name body)
	    `(BEGIN (DECLARE (INTEGRATE ,pattern))
		    (DEFINE ,pattern ,@body)))
	  (lambda (pattern body)
	    `(BEGIN (DECLARE (INTEGRATE-OPERATOR ,(car pattern)))
		    (DEFINE ,pattern
		      ,@(if (list? (cdr pattern))
			    `((DECLARE
			       (INTEGRATE
				,@(lambda-list->bound-names (cdr pattern)))))
			    '())
		      ,@body))))
	`(DEFINE ,pattern ,@body))))

)

(syntax-table-define compiler-syntax-table 'DEFINE-VECTOR-SLOTS
  (macro (class index . slots)
    (define (loop slots n)
      (if (null? slots)
	  '()
	  (cons (let ((ref-name (symbol-append class '- (car slots))))
		  `(BEGIN
		    (DEFINE-INTEGRABLE (,ref-name ,class)
		      (VECTOR-REF ,class ,n))
		    (DEFINE-INTEGRABLE (,(symbol-append 'SET- ref-name '!)
					,class ,(car slots))
		      (VECTOR-SET! ,class ,n ,(car slots)))))
		(loop (cdr slots) (1+ n)))))
    (if (null? slots)
	'*THE-NON-PRINTING-OBJECT*
	`(BEGIN ,@(loop slots index)))))

(let-syntax
 ((define-type-definition
    (macro (name reserved)
      (let ((parent (symbol-append name '-TAG)))
	`(SYNTAX-TABLE-DEFINE COMPILER-SYNTAX-TABLE
			      ',(symbol-append 'DEFINE- name)
	   (macro (type . slots)
	     (let ((tag-name (symbol-append type '-TAG)))
	       `(BEGIN (DEFINE ,tag-name
			 (MAKE-VECTOR-TAG ,',parent ',type))
		       (DEFINE ,(symbol-append type '?)
			 (TAGGED-VECTOR-PREDICATE ,tag-name))
		       (DEFINE-VECTOR-SLOTS ,type ,,reserved ,@slots)
		       (DEFINE-VECTOR-METHOD ,tag-name ':DESCRIBE
			 (LAMBDA (,type)
			   (APPEND!
			    ((VECTOR-TAG-METHOD ,',parent ':DESCRIBE) ,type)
			    (DESCRIPTOR-LIST ,type ,@slots))))))))))))
 (define-type-definition snode 6)
 (define-type-definition pnode 7)
 (define-type-definition rvalue 1)
 (define-type-definition vnode 10))

(syntax-table-define compiler-syntax-table 'DESCRIPTOR-LIST
  (macro (type . slots)
    `(LIST ,@(map (lambda (slot)
		    (let ((ref-name (symbol-append type '- slot)))
		      ``(,',ref-name ,(,ref-name ,type))))
		  slots))))

(let ((rtl-common
       (lambda (type prefix components wrap-constructor)
	 `(BEGIN
	    (DEFINE-INTEGRABLE (,(symbol-append prefix 'MAKE- type) ,@components)
	      ,(wrap-constructor `(LIST ',type ,@components)))
	    (DEFINE-INTEGRABLE (,(symbol-append 'RTL: type '?) EXPRESSION)
	      (EQ? (CAR EXPRESSION) ',type))
	    ,@(let loop ((components components)
			 (ref-index 6)
			 (set-index 2))
		(if (null? components)
		    '()
		    (let* ((slot (car components))
			   (name (symbol-append type '- slot)))
		      `((DEFINE-INTEGRABLE (,(symbol-append 'RTL: name) ,type)
			  (GENERAL-CAR-CDR ,type ,ref-index))
			(DEFINE-INTEGRABLE (,(symbol-append 'RTL:SET- name '!)
					    ,type ,slot)
			  (SET-CAR! (GENERAL-CAR-CDR ,type ,set-index) ,slot))
			,@(loop (cdr components)
				(* ref-index 2)
				(* set-index 2))))))))))
  (syntax-table-define compiler-syntax-table 'DEFINE-RTL-EXPRESSION
    (macro (type prefix . components)
      (rtl-common type prefix components identity-procedure)))

  (syntax-table-define compiler-syntax-table 'DEFINE-RTL-STATEMENT
    (macro (type prefix . components)
      (rtl-common type prefix components
		  (lambda (expression) `(STATEMENT->SCFG ,expression)))))

  (syntax-table-define compiler-syntax-table 'DEFINE-RTL-PREDICATE
    (macro (type prefix . components)
      (rtl-common type prefix components
		  (lambda (expression) `(PREDICATE->PCFG ,expression))))))

(syntax-table-define compiler-syntax-table 'DEFINE-REGISTER-REFERENCES
  (macro (slot)
    (let ((name (symbol-append 'REGISTER- slot)))
      (let ((vector (symbol-append '* name '*)))
	`(BEGIN (DEFINE ,vector)
		(DEFINE-INTEGRABLE (,name REGISTER)
		  (VECTOR-REF ,vector REGISTER))
		(DEFINE-INTEGRABLE
		  (,(symbol-append 'SET- name '!) REGISTER VALUE)
		  (VECTOR-SET! ,vector REGISTER VALUE)))))))

(syntax-table-define compiler-syntax-table 'UCODE-TYPE
  (macro (name)
    (microcode-type name)))

(syntax-table-define compiler-syntax-table 'UCODE-PRIMITIVE
  (macro (name)
    (make-primitive-procedure name)))

(syntax-table-define lap-generator-syntax-table 'DEFINE-RULE
  (macro (type pattern . body)
    (parse-rule pattern body
      (lambda (pattern names transformer qualifier actions)
	`(,(case type
	     ((STATEMENT) 'ADD-STATEMENT-RULE!)
	     ((PREDICATE) 'ADD-STATEMENT-RULE!)
	     (else (error "Unknown rule type" type)))
	  ',pattern
	  ,(rule-result-expression names transformer qualifier
				   `(BEGIN ,@actions)))))))

;;;; Lap instruction sequences.  A NOP for now.

(syntax-table-define compiler-syntax-table 'INSTRUCTIONS
  (macro some-instructions
    (define (handle remaining)
      (cond ((null? remaining)
	     'lap:empty-instructions)
	    ((eq? (caar remaining) 'EVALUATE)
	     `(lap:cons-instruction
	       ,(cadar remaining)
	       ,(handle (cdr remaining))))
	    ((eq? (caar remaining) 'EVALUATE-SPLICE)
	     `(lap:append-instructions
	       ,(cadar remaining)
	       ,(handle (cdr remaining))))
	    (else
	     `(lap:cons-instruction
	       (INSTRUCTION ,(car remaining))
	       ,(handle (cdr remaining))))))
    (handle some-instructions)))

(syntax-table-define compiler-syntax-table 'INSTRUCTION
  (macro (the-instruction)
    (define (quoted? object)
      (and (pair? object)
	   (eq? (car object) 'QUOTE)))

    (define (walk tree)
      (cond ((not (pair? tree))
	     `(quote ,tree))
	    ((eq? (car tree) 'EVALUATE)
	     (cadr tree))
	    (else
	     (let ((the-car (walk (car tree)))
		   (the-cdr (walk (cdr tree))))
	       (if (and (quoted? the-car)
			(quoted? the-cdr))
		   `(quote (,(cadr the-car) . ,(cadr the-cdr)))
		   `(cons ,the-car ,the-cdr))))))
    (walk the-instruction)))
				   `(BEGIN ,@actions)))))))