;;; -*-Scheme-*-
;;;
;;;	$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/runtime/hash.scm,v 13.46.1.1 1987/07/29 05:02:02 cph Exp $
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

;;;; Object Hashing, populations, and 2D tables

;;; The hashing code, and the population code below, depend on weak
;;; conses supported by the microcode.  In particular, both pieces of
;;; code depend on the fact that the car of a weak cons becomes #F if
;;; the object is garbage collected.

;;; Important: This code must be rewritten for a parallel processor,
;;; since two processors may be updating the data structures
;;; simultaneously.

(declare (usual-integrations))

(add-event-receiver! event:after-restore gc-flip)

;;;; Object hashing

;;; How this works:

;;; There are two tables, the hash table and the unhash table:

;;; - The hash table associates objects to their hash numbers.  The
;;; entries are keyed according to the address (datum) of the object,
;;; and thus must be recomputed after every relocation (ie. band
;;; loading, garbage collection, etc.).

;;; - The unhash table associates the hash numbers with the
;;; corresponding objects.  It is keyed according to the numbers
;;; themselves.

;;; In order to make the hash and unhash tables weakly hold the
;;; objects hashed, the following mechanism is used:

;;; The hash table, a vector, has a SNMV header before all the
;;; buckets, and therefore the garbage collector will skip it and will
;;; not relocate its buckets.  It becomes invalid after a garbage
;;; collection and the first thing the daemon does is clear it.  Each
;;; bucket is a normal alist with the objects in the cars, and the
;;; numbers in the cdrs, thus assq can be used to find an object in
;;; the bucket.

;;; The unhash table, also a vector, holds the objects by means of
;;; weak conses.  These weak conses are the same as the pairs in the
;;; buckets in the hash table, but with their type codes changed.
;;; Each of the buckets in the unhash table is headed by an extra pair
;;; whose car is usually #T.  This pair is used by the splicing code.
;;; The daemon treats buckets headed by #F differently from buckets
;;; headed by #T.  A bucket headed by #T is compressed: Those pairs
;;; whose cars have disappeared are spliced out from the bucket.  On
;;; the other hand, buckets headed by #F are not compressed.  The
;;; intent is that while object-unhash is traversing a bucket, the
;;; bucket is locked so that the daemon will not splice it out behind
;;; object-unhash's back.  Then object-unhash does not need to be
;;; locked against garbage collection.

(define (hash x)
  (if (eq? x false)
      0
      (object-hash x)))

(define (unhash n)
  (if (zero? n)
      false
      (or (object-unhash n)
	  (error "unhash: Not a valid hash number" n))))

(define (valid-hash-number? n)
  (or (zero? n)
      (object-unhash n)))

(define object-hash)
(define object-unhash)

(let ((pair-type (microcode-type 'PAIR))
      (weak-cons-type (microcode-type 'WEAK-CONS))
      (snmv-type (microcode-type 'MANIFEST-SPECIAL-NM-VECTOR))
      (&make-object (make-primitive-procedure '&MAKE-OBJECT)))
  (declare (integrate-primitive-procedures &make-object))

(define next-hash-number)
(define hash-table-size)
(define unhash-table)
(define hash-table)

(define (initialize-object-hash! size)
  (set! next-hash-number 1)
  (set! hash-table-size size)
  (set! unhash-table (vector-cons size '()))
  (set! hash-table (vector-cons (1+ size) '()))
  (vector-set! hash-table 0 (&make-object snmv-type size))
  (let initialize ((n 0))
    (if (< n size)
	(begin (vector-set! unhash-table n (cons true '()))
	       (initialize (1+ n))))))

;; Primitive-datum may return negative fixnums.  Until fixed...

(define safe-primitive-datum
  (let ((smallest-positive-bignum
	 (let loop ((x 1) (y 2))
	   (if (primitive-type? (primitive-type x) y)
	       (loop y (* y 2))
	       (* y 2)))))
    (named-lambda (safe-primitive-datum object)
      (let ((n (primitive-datum object)))
	(if (not (negative? n))
	    n
	    (+ smallest-positive-bignum n))))))	

;;; This is not dangerous because assq is a primitive and does not
;;; cause consing.  The rest of the consing (including that by the
;;; interpreter) is a small bounded amount.

(set! object-hash
(named-lambda (object-hash object)
  (with-interrupt-mask interrupt-mask-none
   (lambda (ignore)
     (let* ((hash-index (1+ (modulo (safe-primitive-datum object) hash-table-size)))
	    (bucket (vector-ref hash-table hash-index))
	    (association (assq object bucket)))
       (if association
	   (cdr association)
	   (let ((pair (cons object next-hash-number))
		 (result next-hash-number)
		 (unhash-bucket
		  (vector-ref unhash-table
			      (modulo next-hash-number hash-table-size))))
	     (set! next-hash-number (1+ next-hash-number))
	     (vector-set! hash-table hash-index (cons pair bucket))
	     (set-cdr! unhash-bucket
		       (cons (primitive-set-type weak-cons-type pair)
			     (cdr unhash-bucket)))
	     result)))))))

;;; This is safe because it locks the garbage collector out only for a
;;; little time, enough to tag the bucket being searched, so that the
;;; daemon will not splice that bucket.

(set! object-unhash
(named-lambda (object-unhash number)
  (let ((index (modulo number hash-table-size)))
    (with-interrupt-mask interrupt-mask-none
     (lambda (ignore)
       (let ((bucket (vector-ref unhash-table index)))
	 (set-car! bucket false)
	 (let ((result
		(with-interrupt-mask interrupt-mask-gc-ok
		 (lambda (ignore)
		   (let loop ((l (cdr bucket)))
		     (cond ((null? l) false)
			   ((= number (system-pair-cdr (car l)))
			    (system-pair-car (car l)))
			   (else (loop (cdr l)))))))))
	   (set-car! bucket true)
	   result)))))))

;;;; Rehash daemon

;;; The following is dangerous because of the (unnecessary) consing
;;; done by the interpreter while it executes the loops.  It runs with
;;; interrupts turned off.  The (necessary) consing done by rehash is
;;; not dangerous because at least that much storage was freed by the
;;; garbage collector.  To understand this, notice that the hash table
;;; has a SNMV header, so the garbage collector does not trace the
;;; hash table buckets, therefore freeing their storage.  The header
;;; is SNM rather than NM to make the buckets be relocated at band
;;; load/restore time.

;;; Until this code is compiled, and therefore safe, it is replaced by
;;; a primitive.  See the installation code below.

#|
(define (rehash weak-pair)
  (let ((index (1+ (modulo (safe-primitive-datum (system-pair-car weak-pair))
			   hash-table-size))))
    (vector-set! hash-table
		 index
		 (cons (primitive-set-type pair-type weak-pair)
		       (vector-ref hash-table index)))))

(define (cleanup n)
  (if (zero? n)
      'DONE
      (begin (vector-set! hash-table n '())
	     (cleanup (-1+ n)))))

(define (rehash-gc-daemon)
  (cleanup hash-table-size)
  (let outer ((n (-1+ hash-table-size)))
    (if (negative? n)
	true
	(let ((bucket (vector-ref unhash-table n)))
	  (if (car bucket)
	      (let inner1 ((l1 bucket) (l2 (cdr bucket)))
		(cond ((null? l2) (outer (-1+ n)))
		      ((eq? (system-pair-car (car l2)) false)
		       (set-cdr! l1 (cdr l2))
		       (inner1 l1 (cdr l1)))
		      (else (rehash (car l2))
			    (inner1 l2 (cdr l2)))))
	      (let inner2 ((l (cdr bucket)))
		(cond ((null? l) (outer (-1+ n)))
		      ((eq? (system-pair-car (car l)) false)
		       (inner2 (cdr l)))
		      (else (rehash (car l))
			    (inner2 (cdr l))))))))))

(add-gc-daemon! rehash-gc-daemon)
|#

(add-gc-daemon!
 (let ((primitive (make-primitive-procedure 'REHASH)))
   (lambda ()
     (primitive unhash-table hash-table))))
