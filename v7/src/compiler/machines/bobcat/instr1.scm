#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/machines/bobcat/instr1.scm,v 1.61.1.3 1987/06/25 10:38:05 jinx Exp $

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

;;;; 68000 Instruction Set Description
;;; Originally from GJS (who did the hard part).

(declare (usual-integrations))

;;;; Effective Address transformers and description database

(define-ea-database
  ((D (? r)) (DATA ALTERABLE) #b000 r)

  ((A (? r)) (ALTERABLE) #b001 r)

  ((@A (? r)) (DATA MEMORY CONTROL ALTERABLE) #b010 r)

  ((@D (? r))
   (DATA MEMORY CONTROL ALTERABLE) #b110 #b000
   (output-@D-indirect r))

  ((@A+ (? r)) (DATA MEMORY ALTERABLE) #b011 r)

  ((@-A (? r)) (DATA MEMORY ALTERABLE) #b100 r)

  ((@AO (? r) (? o))
   (DATA MEMORY CONTROL ALTERABLE) #b101 r
   (output-16bit-offset o))

  ((@AR (? r) (? l))
   (DATA MEMORY CONTROL ALTERABLE) #b101 r
   (output-16bit-relative l))

  ((@DO (? r) (? o))
   (DATA MEMORY CONTROL ALTERABLE) #b110 #b000
   (output-@DO-indirect r o))
  
  ((@AOX (? r) (? o) (? xtype da) (? xr) (? s wl))
   (DATA MEMORY CONTROL ALTERABLE) #b110 r
   (output-offset-index-register xtype xr s o))

  ((@ARX (? r) (? l) (? xtype da) (? xr) (? s wl))
   (DATA MEMORY CONTROL ALTERABLE) #b110 r
   (output-relative-index-register xtype xr s l))

  ((W (? a))
   (DATA MEMORY CONTROL ALTERABLE) #b111 #b000
   (output-16bit-address a))

  ((L (? a))
   (DATA MEMORY CONTROL ALTERABLE) #b111 #b001
   (output-32bit-address a))

  ((@PCO (? o))
   (DATA MEMORY CONTROL) #b111 #b010
   (output-16bit-offset o))

  ((@PCR (? l))
   (DATA MEMORY CONTROL) #b111 #b010
   (output-16bit-relative l))

  ((@PCOX (? o) (? xtype da) (? xr) (? s wl))
   (DATA MEMORY CONTROL) #b111 #b011
   (output-offset-index-register xtype xr s o))

  ((@PCRX (? l) (? xtype da) (? xr) (? s wl))
   (DATA MEMORY CONTROL) #b111 #b011
   (output-relative-index-register xtype xr s l))

  ((& (? i))
   (DATA MEMORY) #b111 #b100
   (output-immediate-data immediate-size i)))

(define-ea-transformer ea-all)

(define-ea-transformer ea-d (DATA))
(define-ea-transformer ea-a (ALTERABLE))
(define-ea-transformer ea-c (CONTROL))

(define-ea-transformer ea-d&a (DATA ALTERABLE))
(define-ea-transformer ea-c&a (CONTROL ALTERABLE))
(define-ea-transformer ea-m&a (MEMORY ALTERABLE))

(define-ea-transformer ea-d&-& (DATA) (&))
(define-ea-transformer ea-all-A () (A))

;;;; Special purpose transformers

(define-symbol-transformer da    (D . 0) (A . 1))
(define-symbol-transformer nwl   (N . 1) (W . 2) (L . 3))
(define-symbol-transformer bwlq  (B . 0) (W . 1) (L . 2) (Q . 3))
(define-symbol-transformer bwl-b (W . 1) (L . 2))
(define-symbol-transformer bwl   (B . 0) (W . 1) (L . 2))
(define-symbol-transformer bw    (B . 0) (W . 1))
(define-symbol-transformer wl    (W . 0) (L . 1))
(define-symbol-transformer lw    (W . 1) (L . 0))
(define-symbol-transformer rl    (R . 0) (L . 1))
(define-symbol-transformer us    (U . 0) (S . 1))
(define-symbol-transformer cc
  (T . 0) (F . 1) (HI . 2) (LS . 3) (HS . 4) (LO . 5)
  (CC . 4) (CS . 5) (NE . 6) (EQ . 7) (VC . 8) (VS . 9)
  (PL . 10) (MI . 11) (GE . 12) (LT . 13) (GT . 14) (LE . 15))

(define-reg-list-transformer @+reg-list
  (A7 . 0) (A6 . 1) (A5 . 2) (A4 . 3) (A3 . 4) (A2 . 5) (A1 . 6) (A0 . 7)
  (D7 . 8) (D6 . 9) (D5 . 10) (D4 . 11) (D3 . 12) (D2 . 13)
  (D1 . 14) (D0 . 15))

(define-reg-list-transformer @-reg-list
  (D0 . 0) (D1 . 1) (D2 . 2) (D3 . 3) (D4 . 4) (D5 . 5) (D6 . 6) (D7 . 7)
  (A0 . 8) (A1 . 9) (A2 . 10) (A3 . 11) (A4 . 12) (A5 . 13)
  (A6 . 14) (A7 . 15))