#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/back/mermap.scm,v 1.4 1991/07/25 02:32:06 cph Exp $

Copyright (c) 1988-91 Massachusetts Institute of Technology

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

;;;; LAP Generator: Merge Register Maps

(declare (usual-integrations))

(define (merge-register-maps maps weights)
  ;; This plays merry hell with the map entry order.  An attempt has
  ;; been made to preserve the order in simple cases, but in general
  ;; there isn't enough information to do a really good job.
  (let ((entries
	 (reduce add-weighted-entries
		 '()
		 (if (not weights)
		     (map (lambda (map) (map->weighted-entries map 1)) maps)
		     (map map->weighted-entries maps weights)))))
    (for-each eliminate-unlikely-aliases! entries)
    (eliminate-conflicting-aliases! entries)
    (weighted-entries->map entries)))

(define (eliminate-unlikely-aliases! entry)
  (let ((home-weight (vector-ref entry 1))
	(alias-weights (vector-ref entry 2)))
    (let ((maximum (max home-weight (apply max (map cdr alias-weights)))))
      (if (not (= home-weight maximum))
	  (vector-set! entry 1 0))
      ;; Keep only the aliases with the maximum weights.  Furthermore,
      ;; keep only one alias of a given type.
      (vector-set! entry 2
		   (list-transform-positive alias-weights
		     (let ((types '()))
		       (lambda (alias-weight)
			 (and (= (cdr alias-weight) maximum)
			      (let ((type (register-type (car alias-weight))))
				(and (not (memq type types))
				     (begin (set! types (cons type types))
					    true)))))))))))

(define (eliminate-conflicting-aliases! entries)
  (for-each (lambda (conflicting-alias)
	      (let ((homes (cdr conflicting-alias)))
		(let ((maximum (apply max (map cdr homes))))
		  (let ((winner
			 (list-search-positive homes
			   (lambda (home)
			     (= (cdr home) maximum)))))
		    (for-each
		     (lambda (home)
		       (if (not (eq? home winner))
			   (let ((entry
				  (find-weighted-entry (car home) entries)))
			     (vector-set! entry 2
					  (del-assv! (car conflicting-alias)
						     (vector-ref entry 2))))))
		     homes)))))
	    (conflicting-aliases entries)))

(define (conflicting-aliases entries)
  (let ((alist '()))
    (for-each
     (lambda (entry)
       (let ((home (vector-ref entry 0)))
	 (for-each
	  (lambda (alias-weight)
	    (let ((alist-entry (assv (car alias-weight) alist))
		  (element (cons home (cdr alias-weight))))
	      (if alist-entry
		  (set-cdr! alist-entry (cons element (cdr alist-entry)))
		  (set! alist
			(cons (list (car alias-weight) element) alist)))))
	  (vector-ref entry 2))))
     entries)
    (list-transform-negative alist
      (lambda (alist-entry)
	(null? (cddr alist-entry))))))

(define (map->weighted-entries register-map weight)
  (map (lambda (entry)
	 (vector (map-entry-home entry)
		 (if (map-entry-saved-into-home? entry) weight 0)
		 (map (lambda (alias) (cons alias weight))
		      (map-entry-aliases entry))
		 (map-entry-label entry)))
       (map-entries register-map)))

(define (add-weighted-entries x-entries y-entries)
  (merge-entries x-entries y-entries
    (lambda (entry entries)
      (list-search-positive entries
	(let ((home (vector-ref entry 0)))
	  (lambda (entry)
	    (eqv? home (vector-ref entry 0))))))
    (lambda (x-entry y-entry)
      (vector (vector-ref x-entry 0)
	      (+ (vector-ref x-entry 1) (vector-ref y-entry 1))
	      (merge-entries (vector-ref x-entry 2) (vector-ref y-entry 2)
		(lambda (entry entries)
		  (assq (car entry) entries))
		(lambda (x-entry y-entry)
		  (cons (car x-entry) (+ (cdr x-entry) (cdr y-entry)))))
	      ;; If the labels don't match, or only one entry has a
	      ;; label, then the result shouldn't have a label.
	      (and (eqv? (vector-ref x-entry 3) (vector-ref y-entry 3))
		   (vector-ref x-entry 3))))))

(define (merge-entries x-entries y-entries find-entry merge-entry)
  (let loop
      ((x-entries x-entries)
       (y-entries (list-copy y-entries))
       (result '()))
    (if (null? x-entries)
	;; This (feebly) attempts to preserve the entry order.
	(append! (reverse! result) y-entries)
	(let ((x-entry (car x-entries))
	      (x-entries (cdr x-entries)))
	  (let ((y-entry (find-entry x-entry y-entries)))
	    (if y-entry
		(loop x-entries
		      (delq! y-entry y-entries)
		      (cons (merge-entry x-entry y-entry) result))
		(loop x-entries
		      y-entries
		      (cons x-entry result))))))))

(define find-weighted-entry
  (association-procedure eqv? (lambda (entry) (vector-ref entry 0))))

(define (weighted-entries->map entries)
  (let loop
      ((entries entries)
       (map-entries '())
       (map-registers available-machine-registers))
    (if (null? entries)
	(make-register-map (reverse! map-entries)
			   (sort-machine-registers map-registers))
	(let ((aliases (map car (vector-ref (car entries) 2))))
	  (if (null? aliases)
	      (loop (cdr entries) map-entries map-registers)
	      (loop (cdr entries)
		    (cons (make-map-entry
			   (vector-ref (car entries) 0)
			   (positive? (vector-ref (car entries) 1))
			   aliases
			   (vector-ref (car entries) 3))
			  map-entries)
		    (eqv-set-difference map-registers aliases)))))))