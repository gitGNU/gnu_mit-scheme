#| -*-Scheme-*-

$Id: switch.scm,v 4.24.1.1 1994/03/30 21:16:29 gjr Exp $

Copyright (c) 1988-1994  Massachusetts Institute of Technology

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

;;;; Compiler Option Switches
;;; package: (compiler)

(declare (usual-integrations))

;;; Binary switches

(define compiler:enable-integration-declarations? true)
(define compiler:enable-expansion-declarations? false)
(define compiler:compile-by-procedures? true)
(define compiler:noisy? true)
(define compiler:show-time-reports? false)
(define compiler:show-procedures? true)
(define compiler:show-phases? false)
(define compiler:show-subphases? false)
(define compiler:preserve-data-structures? false)
(define compiler:code-compression? true)
(define compiler:cache-free-variables? true)
(define compiler:implicit-self-static? true)
(define compiler:optimize-environments? true)
(define compiler:analyze-side-effects? true)
(define compiler:cse? true)
(define compiler:open-code-primitives? true)
(define compiler:generate-kmp-files? true)
(define compiler:generate-rtl-files? true)
(define compiler:generate-lap-files? true)
(define compiler:intersperse-rtl-in-lap? true)
(define compiler:generate-range-checks? false)
(define compiler:generate-type-checks? false)
(define compiler:generate-stack-checks? true)
(define compiler:open-code-flonum-checks? false)
(define compiler:use-multiclosures? true)
(define compiler:coalescing-constant-warnings? true)
(define compiler:cross-compiling? false)
(define compiler:compress-top-level? false)
(define compiler:avoid-scode? true)

;; If true, the compiler is allowed to assume that fixnum operations
;; are only applied to inputs for which the operation is closed, i.e.
;; generates a valid fixnum.  If false, the compiler will ensure that
;; the result of a fixnum operation is a fixnum, although it may be an
;; incorrect result for screw cases.

(define compiler:assume-safe-fixnums? true)

;;
(define compiler:generate-trap-on-null-valued-conditional? false)


;; The switch COMPILER:OPEN-CODE-FLOATING-POINT-ARITHMETIC? is in machin.scm.

;;; Nary switches

(define compiler:package-optimization-level
  ;; Possible values: NONE LOW HYBRID HIGH
  'HYBRID)

(define compiler:default-top-level-declarations
  '((UUO-LINK ALL)))

;;; Hook: bind this to a procedure of one argument and it will receive
;;; each phase of the compiler as a thunk.  It is expected to call the
;;; thunk after any appropriate processing.
(define compiler:phase-wrapper
  false)