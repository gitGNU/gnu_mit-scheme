#| -*-Scheme-*-

$Id: rtlty1.scm,v 4.21.1.1 1994/03/30 21:21:26 gjr Exp $

Copyright (c) 1987-1994 Massachusetts Institute of Technology

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

;;;; Register Transfer Language Type Definitions
;;; package: (compiler)

(declare (usual-integrations))

;;; These three lists will be filled in by the type definitions that
;;; follow.  See those macros for details.
(define rtl:expression-types '())
(define rtl:statement-types '())
(define rtl:predicate-types '())

(define-rtl-expression register % number)

;;; Scheme object
(define-rtl-expression constant % value)

;;; Memory references that return Scheme objects
(define-rtl-expression offset rtl: base offset)
(define-rtl-expression pre-increment rtl: register number)
(define-rtl-expression post-increment rtl: register number)

;;; Memory reference that returns ASCII integer
(define-rtl-expression byte-offset rtl: base offset)
;;; Memory reference that returns a floating-point number
(define-rtl-expression float-offset rtl: base offset)

;;; Generic arithmetic operations on Scheme number objects
;;; (define-rtl-expression generic-unary rtl: operator operand)
;;; (define-rtl-expression generic-binary rtl: operator operand-1 operand-2)

;;; Code addresses
(define-rtl-expression entry:continuation rtl: continuation)
(define-rtl-expression entry:procedure rtl: procedure)

;;; Allocating a closure object (returns its address)
(define-rtl-expression cons-closure rtl: entry min max size)
;;; Allocating a multi-closure object
;;; (returns the address of first entry point)
(define-rtl-expression cons-multiclosure rtl: nentries size entries)

;;; Cache addresses
(define-rtl-expression assignment-cache rtl: name)
(define-rtl-expression variable-cache rtl: name)

;;; Get the address of a Scheme object
(define-rtl-expression object->address rtl: expression)

;;; Convert between a datum and an address
;;; (define-rtl-expression datum->address rtl: expression)
;;; (define-rtl-expression address->datum rtl: expression)

;;; Add a constant offset to an address
(define-rtl-expression offset-address rtl: base offset)
(define-rtl-expression byte-offset-address rtl: base offset)
(define-rtl-expression float-offset-address rtl: base offset)

;;; A machine constant (an integer, usually unsigned)
(define-rtl-expression machine-constant rtl: value)

;;; Destructuring Scheme objects
(define-rtl-expression object->datum rtl: expression)
(define-rtl-expression object->type rtl: expression)
(define-rtl-expression cons-pointer rtl: type datum)
(define-rtl-expression cons-non-pointer rtl: type datum)

;;; Convert a character object to an ASCII machine integer
(define-rtl-expression char->ascii rtl: expression)

;;; Conversion between fixnum objects and machine integers
(define-rtl-expression object->fixnum rtl: expression)
(define-rtl-expression object->unsigned-fixnum rtl: expression)
(define-rtl-expression fixnum->object rtl: expression)

;;; Conversion between machine integers and addresses
(define-rtl-expression fixnum->address rtl: expression)
(define-rtl-expression address->fixnum rtl: expression)

;;; Machine integer arithmetic operations
(define-rtl-expression fixnum-1-arg rtl:
  operator operand overflow?)
(define-rtl-expression fixnum-2-args rtl:
  operator operand-1 operand-2 overflow?)

;;; Conversion between flonums and machine floats
(define-rtl-expression float->object rtl: expression)
(define-rtl-expression object->float rtl: expression)

;;; Floating-point arithmetic operations
(define-rtl-expression flonum-1-arg rtl:
  operator operand overflow?)
(define-rtl-expression flonum-2-args rtl:
  operator operand-1 operand-2 overflow?)

;; Predicates whose inputs are fixnums
(define-rtl-predicate fixnum-pred-1-arg %
  predicate operand)
(define-rtl-predicate fixnum-pred-2-args %
  predicate operand-1 operand-2)

;; Predicates whose inputs are flonums
(define-rtl-predicate flonum-pred-1-arg %
  predicate operand)
(define-rtl-predicate flonum-pred-2-args %
  predicate operand-1 operand-2)

(define-rtl-predicate eq-test % expression-1 expression-2)

;; Type tests compare an extracted type field with a constant type
(define-rtl-predicate type-test % expression type)

;; General predicates
(define-rtl-predicate pred-1-arg % predicate operand)
(define-rtl-predicate pred-2-args % predicate operand-1 operand-2)

(define-rtl-predicate overflow-test rtl:)

(define-rtl-statement assign % address expression)

(define-rtl-statement pop-return rtl:)

(define-rtl-statement continuation-entry rtl: continuation)
(define-rtl-statement continuation-header rtl: continuation)
(define-rtl-statement ic-procedure-header rtl: procedure)
(define-rtl-statement open-procedure-header rtl: procedure)
(define-rtl-statement procedure-header rtl: procedure min max)
(define-rtl-statement closure-header rtl: procedure nentries entry)

(define-rtl-statement interpreter-call:access %
  continuation environment name)
(define-rtl-statement interpreter-call:define %
  continuation environment name value)
(define-rtl-statement interpreter-call:lookup %
  continuation environment name safe?)
(define-rtl-statement interpreter-call:set! %
  continuation environment name value)
(define-rtl-statement interpreter-call:unassigned? %
  continuation environment name)
(define-rtl-statement interpreter-call:unbound? %
  continuation environment name)

(define-rtl-statement interpreter-call:cache-assignment %
  continuation name value)
(define-rtl-statement interpreter-call:cache-reference %
  continuation name safe?)
(define-rtl-statement interpreter-call:cache-unassigned? %
  continuation name)

(define-rtl-statement invocation:apply rtl:
  pushed continuation)
(define-rtl-statement invocation:jump rtl:
  pushed continuation procedure)
(define-rtl-statement invocation:computed-jump rtl:
  pushed continuation)
(define-rtl-statement invocation:lexpr rtl:
  pushed continuation procedure)
(define-rtl-statement invocation:computed-lexpr rtl:
  pushed continuation)
(define-rtl-statement invocation:uuo-link rtl:
  pushed continuation name)
(define-rtl-statement invocation:global-link rtl:
  pushed continuation name)
(define-rtl-statement invocation:primitive rtl:
  pushed continuation procedure)
(define-rtl-statement invocation:special-primitive rtl:
  pushed continuation procedure)
(define-rtl-statement invocation:cache-reference rtl:
  pushed continuation name)
(define-rtl-statement invocation:lookup rtl:
  pushed continuation environment name)

(define-rtl-statement invocation-prefix:move-frame-up rtl:
  frame-size locative)
(define-rtl-statement invocation-prefix:dynamic-link rtl:
  frame-size locative register)

;;;; New RTL

(define-rtl-statement invocation:register rtl:
  pushed continuation destination cont-defined? nregs)
(define-rtl-statement invocation:procedure rtl:
  pushed continuation procedure nregs)
(define-rtl-statement invocation:new-apply rtl:
  pushed continuation destination nregs)

(define-rtl-statement return-address rtl: label frame-size nregs)
(define-rtl-statement procedure rtl: label frame-size)
(define-rtl-statement trivial-closure rtl: label min max)
(define-rtl-statement closure rtl: label frame-size)
(define-rtl-statement expression rtl: label)

(define-rtl-statement interrupt-check:procedure rtl:
  intrpt? heap? stack? label nregs)
(define-rtl-statement interrupt-check:continuation rtl:
  intrpt? heap? stack? label nregs)
(define-rtl-statement interrupt-check:closure rtl:
  intrpt? heap? stack? nregs)
(define-rtl-statement interrupt-check:simple-loop rtl:
  intrpt? heap? stack? loop-label header-label nregs)

(define-rtl-statement preserve rtl: register how)
(define-rtl-statement restore rtl: register value)

(define-rtl-expression static-cell rtl: name)
(define-rtl-expression align-float rtl: expression)
