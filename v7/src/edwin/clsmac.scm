;;; -*-Scheme-*-
;;;
;;; $Id: clsmac.scm,v 1.7.2.2 2002/01/18 21:46:46 cph Exp $
;;;
;;; Copyright (c) 1986, 1989, 1999, 2001, 2002 Massachusetts Institute of Technology
;;;
;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundation; either version 2 of the
;;; License, or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; if not, write to the Free Software
;;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;;; 02111-1307, USA.

;;;; Class/Object System

(declare (usual-integrations))

;;; ******************************************************************
;;; This software is intended for use in the Edwin window system only.
;;; Don't think about using it for anything else, since it is not, and
;;; likely will not ever, be supported as a part of the Scheme system.
;;; ******************************************************************

(define-syntax define-class
  (rsc-macro-transformer
   (lambda (form environment)
     (if (and (syntax-match? '(IDENTIFIER DATUM (* SYMBOL)) (cdr form))
	      (or (identifier? (caddr form))
		  (null? (caddr form))))
	 (let ((name (cadr form))
	       (superclass (if (null? (caddr form)) #f (caddr form)))
	       (variables (cadddr form)))
	   ;; Compile-time definition.
	   (make-class (identifier->symbol name)
		       (and superclass
			    (name->class (identifier->symbol superclass)))
		       variables)
	   ;; Load-time definition.
	   `(,(make-syntactic-closure environment '() 'DEFINE)
	     ,name
	     (,(make-syntactic-closure environment '() 'MAKE-CLASS)
	      ',(identifier->symbol name)
	      ,superclass
	      ',variables)))
	 (ill-formed-syntax form)))))

(define-syntax define-method
  (rsc-macro-transformer
   (lambda (form environment)
     (let ((finish
	    (lambda (name operation expression)
	      `(,(make-syntactic-closure environment '() 'CLASS-METHOD-DEFINE)
		,name
		',operation
		,expression))))
       (cond ((syntax-match? '(IDENTIFIER SYMBOL EXPRESSION) (cdr form))
	      (finish (cadr form) (caddr form) (cadddr form)))
	     ((and (syntax-match? '(IDENTIFIER (SYMBOL . MIT-BVL) + EXPRESSION)
				  (cdr form))
		   (pair? (cdr (caddr form)))
		   (identifier? (cadr (caddr form))))
	      (finish (cadr form)
		      (car (caddr form))
		      `(,(make-syntactic-closure environment '() 'NAMED-LAMBDA)
			,(caddr form)
			(,(make-syntactic-closure environment '()
			    'WITH-INSTANCE-VARIABLES)
			 ,(cadr form)
			 ,(cadr (caddr form))
			 ()
			 ,@(cdddr form)))))
	     (else
	      (ill-formed-syntax form)))))))

(define with-instance-variables
  (make-macro-reference-trap
   (make-compiler-item
    (lambda (form environment history)
      (if (syntax-match? '(IDENTIFIER EXPRESSION (* IDENTIFIER) + EXPRESSION)
			 (cdr form))
	  (let ((class-name (cadr form))
		(self (caddr form))
		(free-names (cadddr form))
		(body (cddddr form)))
	    (transform-instance-variables
	     (class-instance-transforms
	      (name->class (identifier->symbol class-name)))
	     (compile/subexpression self environment history select-caddr)
	     free-names
	     (compile/subexpression
	      `(,(make-syntactic-closure system-global-environment '() 'BEGIN)
		,@body)
	      environment
	      history
	      select-cddddr)))
	  (ill-formed-syntax form))))))

(define-syntax ==>
  (syntax-rules ()
    ((==> object operation argument ...)
     (let ((temp object))
       ((object-method temp 'operation) temp argument ...)))))

(define-syntax usual==>
  (syntax-rules ()
    ((usual==> object operation argument ...)
     (let ((temp object))
       ((usual-method (object-class temp) 'operation) temp argument ...)))))