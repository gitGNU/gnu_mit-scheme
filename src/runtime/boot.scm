#| -*-Scheme-*-

Copyright (C) 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994,
    1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
    2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016,
    2017 Massachusetts Institute of Technology

This file is part of MIT/GNU Scheme.

MIT/GNU Scheme is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

MIT/GNU Scheme is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MIT/GNU Scheme; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301,
USA.

|#

;;;; Boot Time Definitions
;;; package: (runtime boot-definitions)

(declare (usual-integrations))

(define (standard-unparser-method name unparser)
  (make-method name unparser))

(define (simple-unparser-method name method)
  (standard-unparser-method name
    (and method
	 (lambda (object port)
	   (for-each (lambda (object)
		       (write-char #\space port)
		       (write object port))
		     (method object))))))

(define (simple-parser-method procedure)
  (lambda (objects lose)
    (or (and (pair? (cdr objects))
	     (procedure (cddr objects)))
	(lose))))

(define (make-method name unparser)
  (general-unparser-method
   (lambda (object port)
     (let ((hash-string (number->string (hash object))))
       (if (get-param:unparse-with-maximum-readability?)
	   (begin
	     (write-string "#@" port)
	     (write-string hash-string port))
	   (begin
	     (write-string "#[" port)
	     (let loop ((name name))
	       (cond ((string? name) (write-string name port))
		     ((procedure? name) (loop (name object)))
		     (else (write name port))))
	     (write-char #\space port)
	     (write-string hash-string port)
	     (if unparser (unparser object port))
	     (write-char #\] port)))))))

(define (general-unparser-method unparser)
  (lambda (state object)
    (with-current-unparser-state state
      (lambda (port)
	(unparser object port)))))

(define (bracketed-unparser-method unparser)
  (general-unparser-method
   (lambda (object port)
     (write-string "#[" port)
     (unparser object port)
     (write-char #\] port))))

(define (unparser-method? object)
  (and (procedure? object)
       (procedure-arity-valid? object 2)))

(define-guarantee unparser-method "unparser method")

(define-integrable interrupt-bit/stack     #x0001)
(define-integrable interrupt-bit/global-gc #x0002)
(define-integrable interrupt-bit/gc        #x0004)
(define-integrable interrupt-bit/global-1  #x0008)
(define-integrable interrupt-bit/kbd       #x0010)
(define-integrable interrupt-bit/after-gc  #x0020)
(define-integrable interrupt-bit/timer     #x0040)
(define-integrable interrupt-bit/global-3  #x0080)
(define-integrable interrupt-bit/suspend   #x0100)
;; Interrupt bits #x0200 through #x4000 inclusive are reserved
;; for the Descartes PC sampler.

;; GC & stack overflow only
(define-integrable interrupt-mask/gc-ok    #x0007)

;; GC, stack overflow, and timer only
(define-integrable interrupt-mask/timer-ok #x0047)

;; Absolutely everything off
(define-integrable interrupt-mask/none     #x0000)

;; Normal: all enabled
(define-integrable interrupt-mask/all      #xFFFF)

(define (with-absolutely-no-interrupts thunk)
  ((ucode-primitive with-interrupt-mask)
   interrupt-mask/none
   (lambda (interrupt-mask)
     interrupt-mask
     (thunk))))

(define (without-interrupts thunk)
  (with-limited-interrupts interrupt-mask/gc-ok
    (lambda (interrupt-mask)
      interrupt-mask
      (thunk))))

(define (with-limited-interrupts limit-mask procedure)
  ((ucode-primitive with-interrupt-mask)
   (fix:and limit-mask (get-interrupt-enables))
   procedure))

(define (object-constant? object)
  ((ucode-primitive constant?) object))

(define-integrable (gc-space-status)
  ((ucode-primitive gc-space-status)))

(define (bytes-per-object)
  (vector-ref (gc-space-status) 0))

(define (object-pure? object)
  object
  #f)

(define-integrable (default-object? object)
  (eq? object (default-object)))

(define-integrable (default-object)
  ((ucode-primitive object-set-type) (ucode-type constant) 7))

(define (init-boot-inits!)
  (set! boot-inits '())
  unspecific)

(define (add-boot-init! thunk)
  (if boot-inits
      (set! boot-inits (cons thunk boot-inits))
      (thunk))
  unspecific)

(define (save-boot-inits! environment)
  (if boot-inits
      (let ((inits (reverse! boot-inits)))
	(set! boot-inits #f)
	(let ((p (assq environment saved-boot-inits)))
	  (if p
	      (set-cdr! p (append! (cdr p) inits))
	      (begin
		(set! saved-boot-inits
		      (cons (cons environment inits)
			    saved-boot-inits))
		unspecific))))))

(define (get-boot-init-runner environment)
  (let ((p (assq environment saved-boot-inits)))
    (and p
	 (let ((inits (cdr p)))
	   (set! saved-boot-inits (delq! p saved-boot-inits))
	   (lambda ()
	     (for-each (lambda (init) (init))
		       inits))))))

(define boot-inits #f)
(define saved-boot-inits '())