#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/runtime/udata.scm,v 14.15 1990/09/11 20:45:26 cph Rel $

Copyright (c) 1988, 1989, 1990 Massachusetts Institute of Technology

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

;;;; Simple Microcode Data Structures
;;; package: ()

(declare (usual-integrations))

(define (return-address? object)
  (or (interpreter-return-address? object)
      (compiled-return-address? object)))

(define-integrable (interpreter-return-address? object)
  (object-type? (ucode-type return-address) object))

(define-integrable (make-return-address code)
  ((ucode-primitive map-code-to-machine-address 2) (ucode-type return-address)
						   code))

(define-integrable (return-address/code return-address)
  ((ucode-primitive map-machine-address-to-code 2) (ucode-type return-address)
						   return-address))

(define (return-address/name return-address)
  (microcode-return/code->name (return-address/code return-address)))

(define (microcode-error name)
  (or (microcode-error/name->code name)
      (error "MICROCODE-ERROR: Unknown name" name)))

(define (microcode-return name)
  (or (microcode-return/name->code name)
      (error "MICROCODE-RETURN: Unknown name" name)))

(define (microcode-termination name)
  (or (microcode-termination/name->code name)
      (error "MICROCODE-TERMINATION: Unknown name" name)))

(define (microcode-type name)
  (or (microcode-type/name->code name)
      (error "MICROCODE-TYPE: Unknown name" name)))

;;;; Compiled Code Entries

(define-integrable (compiled-code-address? object)
  (object-type? (ucode-type compiled-entry) object))

(define-integrable (stack-address? object)
  (object-type? (ucode-type stack-environment) object))

(define (compiled-expression? object)
  (and (compiled-code-address? object)
       (eq? (compiled-entry-type object) 'COMPILED-EXPRESSION)))

(define (compiled-return-address? object)
  (and (compiled-code-address? object)
       (eq? (compiled-entry-type object) 'COMPILED-RETURN-ADDRESS)))

(define-primitives
  (stack-address-offset 1)
  (compiled-code-address->block 1)
  (compiled-code-address->offset 1))

(define (discriminate-compiled-entry entry
				     if-procedure
				     if-return-address
				     if-expression
				     if-other)
  (case (system-hunk3-cxr0 ((ucode-primitive compiled-entry-kind 1) entry))
    ((0) (if-procedure))
    ((1) (if-return-address))
    ((2) (if-expression))
    (else (if-other))))

(define (compiled-entry-type entry)
  (case (system-hunk3-cxr0 ((ucode-primitive compiled-entry-kind 1) entry))
    ((0) 'COMPILED-PROCEDURE)
    ((1) 'COMPILED-RETURN-ADDRESS)
    ((2) 'COMPILED-EXPRESSION)
    (else 'COMPILED-ENTRY)))

(define (compiled-continuation/next-continuation-offset entry)
  (let ((offset
	 (system-hunk3-cxr2 ((ucode-primitive compiled-entry-kind 1) entry))))
    (and (not (negative? offset))
	 offset)))

(define-integrable (compiled-continuation/return-to-interpreter? entry)
  (= 2 (system-hunk3-cxr1 ((ucode-primitive compiled-entry-kind 1) entry))))

(define (stack-address->index address start-offset)
  (if (not (stack-address? address))
      (error "Not a stack address" address))
  (let ((index (- start-offset (stack-address-offset address))))
    (if (negative? index)
	(error "Stack address out of range" address start-offset))
    index))

;;;; Compiled Code Blocks

#|

Compiled code blocks contain both nonmarked code and marked constants.

Code positions are referred to as OFFSETS, which start from the
beginning of the block and are measured in bytes.  The positions of
constants are referred to as INDICES, and use the normal index
numbering for vectors.  The conversion between offsets and indices is
specified by COMPILED-CODE-BLOCK/BYTES-PER-OBJECT, which should be set
to the correct value before these operations are used.

Note: This code needs to be changed somewhat.  MANIFEST-CLOSURES are
compiled-code-blocks, but the format of them is completely different.
The constants block in a compiled-code-block often has a linkage section
that you cannot just vector-ref into.
|#

(define compiled-code-block/bytes-per-object)

(define-integrable (compiled-code-block? object)
  (object-type? (ucode-type compiled-code-block) object))

(define-integrable (compiled-code-block/read-file filename)
  (compiled-code-address->block (fasload filename)))

(define (compiled-code-block/manifest-closure? block)
  (object-type? 
   (ucode-type manifest-closure)
   ;; This combination returns an unsafe object, but since it
   ;; is used as an argument to a primitive, I can get away
   ;; with not turning off the garbage collector.
   ((ucode-primitive primitive-object-ref 2) block 0)))

(define (compiled-code-block/index->offset index)
  (* (1+ index) compiled-code-block/bytes-per-object))

(define (compiled-code-block/offset->index offset)
  (-1+ (quotient offset compiled-code-block/bytes-per-object)))

(define (compiled-code-block/code-length block)
  (* compiled-code-block/bytes-per-object
     (object-datum (system-vector-ref block 0))))

(define (compiled-code-block/code-start block)
  block
  (* compiled-code-block/bytes-per-object 2))

(define (compiled-code-block/code-end block)
  (+ (compiled-code-block/code-start block)
     (compiled-code-block/code-length block)))

(define (compiled-code-block/constants-start block)
  (1+ (object-datum (system-vector-ref block 0))))

(define (compiled-code-block/constants-end block)
  (- (system-vector-length block) 2))

(define (compiled-code-block/debugging-info? block)
  (not (memq (compiled-code-block/debugging-info block) '(#F DEBUGGING-INFO))))

(define (compiled-code-block/debugging-info block)
  (system-vector-ref block (- (system-vector-length block) 2)))

(define (set-compiled-code-block/debugging-info! block info)
  (system-vector-set! block (- (system-vector-length block) 2) info))

(define (compiled-code-block/environment block)
  (system-vector-ref block (-1+ (system-vector-length block))))

;;;; Environment Extensions

(define-integrable (environment-extension? object)
  (vector? object))

(define-integrable (environment-extension-parent extension)
  (vector-ref extension 0))

(define-integrable (set-environment-extension-parent! extension parent)
  (vector-set! extension 0 parent))

(define-integrable (environment-extension-procedure extension)
  (vector-ref extension 1))

(define (environment-extension-aux-list extension)
  (let filter-potentially-dangerous
      ((aux-list
	(let ((first-aux-slot 3))
	  (subvector->list
	   extension
	   first-aux-slot
	   (+ first-aux-slot (object-datum (vector-ref extension 2)))))))
    (cond ((null? aux-list) '())
	  ((unbound-reference-trap?
	    (map-reference-trap (lambda () (cdar aux-list))))
	   (filter-potentially-dangerous (cdr aux-list)))
	  (else
	   (cons (car aux-list)
		 (filter-potentially-dangerous (cdr aux-list)))))))

;;;; Promises

(define-integrable (promise? object)
  (object-type? (ucode-type delayed) object))

(define-integrable (promise-forced? promise)
  (eq? true (system-pair-car promise)))

(define-integrable (promise-non-expression? promise)
  (eqv? 0 (system-pair-car promise)))

(define (promise-value promise)
  (if (not (promise-forced? promise))
      (error "Promise not yet forced" promise))
  (system-pair-cdr promise))

(define (promise-expression promise)
  (if (promise-forced? promise)
      (error "Promise already forced" promise))
  (if (promise-non-expression? promise)
      (error "Promise has no expression" promise))
  (system-pair-cdr promise))

(define (promise-environment promise)
  (if (promise-forced? promise)
      (error "Promise already forced" promise))
  (if (promise-non-expression? promise)
      (error "Promise has no environment" promise))
  (system-pair-car promise))