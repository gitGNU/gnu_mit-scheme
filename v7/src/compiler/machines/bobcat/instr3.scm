#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/machines/bobcat/instr3.scm,v 1.9.1.1 1987/06/10 21:21:43 jinx Exp $

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

;;;; Control Transfer

(define-instruction B
  (((? c cc) S (@PCO (? o)))
   (WORD (4 #b0110)
	 (4 c)
	 (8 o SIGNED)))

  (((? c cc) S (@PCR (? l)))
   (WORD (4 #b0110)
	 (4 c)
	 (8 l SHORT-LABEL)))

  (((? c cc) L (@PCO (? o)))
   (WORD (4 #b0110)
	 (4 c)
	 (8 #b00000000))
   (immediate-word o))

  (((? c cc) L (@PCR (? l)))
   (WORD (4 #b0110)
	 (4 c)
	 (8 #b00000000))
   (relative-word l)))

(define-instruction BRA
  ((S (@PCO (? o)))
   (WORD (8 #b01100000)
	 (8 o SIGNED)))

  ((S (@PCR (? l)))
   (WORD (8 #b01100000)
	 (8 l SHORT-LABEL)))

  ((L (@PCO (? o)))
   (WORD (16 #b0110000000000000))
   (immediate-word o))

  ((L (@PCR (? l)))
   (WORD (16 #b0110000000000000))
   (relative-word l)))

(define-instruction BSR
  ((S (@PCO (? o)))
   (WORD (8 #b01100001)
	 (8 o SIGNED)))

  ((S (@PCR (? o)))
   (WORD (8 #b01100001)
	 (8 o SHORT-LABEL)))

  ((L (@PCO (? o)))
   (WORD (16 #b0110000100000000))
   (immediate-word o))

  ((L (@PCR (? l)))
   (WORD (16 #b0110000100000000))
   (relative-word l)))

(define-instruction DB
  (((? c cc) (D (? rx)) (@PCO (? o)))
   (WORD (4 #b0101)
	 (4 c)
	 (5 #b11001)
	 (3 rx))
   (immediate-word o))

  (((? c cc) (D (? rx)) (@PCR (? l)))
   (WORD (4 #b0101)
	 (4 c)
	 (5 #b11001)
	 (3 rx))
   (relative-word l)))

(define-instruction JMP
  (((? ea ea-c))
   (WORD (10 #b0100111011)
	 (6 ea DESTINATION-EA))))

(define-instruction JSR
  (((? ea ea-c))
   (WORD (10 #b0100111010)
	 (6 ea DESTINATION-EA))))

(define-instruction RTE
  (()
   (WORD (16 #b0100111001110011))))

(define-instruction RTR
  (()
   (WORD (16 #b0100111001110111))))

(define-instruction RTS
  (()
   (WORD (16 #b0100111001110101))))

(define-instruction TRAP
  (((& (? v)))
   (WORD (12 #b010011100100)
	 (4 v))))

(define-instruction TRAPV
  (()
   (WORD (16 #b0100111001110110))))

;;;; Randomness

(define-instruction CHK
  (((? ea ea-d) (D (? rx)))
   (WORD (4 #b0100)
	 (3 rx)
	 (3 #b110)
	 (6 ea SOURCE-EA 'W))))

(define-instruction LINK
  (((A (? rx)) (& (? d)))
   (WORD (13 #b0100111001010)
	 (3 rx))
   (immediate-word d)))

(define-instruction NOP
  (()
   (WORD (16 #b0100111001110001))))

(define-instruction RESET
  (()
   (WORD (16 #b0100111001110000))))

(define-instruction STOP
  (((& (? data)))
   (WORD (16 #b0100111001110010))
   (immediate-word data)))

(define-instruction SWAP
  (((D (? rx)))
   (WORD (13 #b0100100001000)
	 (3 rx))))

(define-instruction UNLK
  (((A (? rx)))
   (WORD (13 #b0100111001011)
	 (3 rx))))

;;;; Data Transfer

(define-instruction CLR
  (((? s bwl) (? ea ea-d&a))
   (WORD (8 #b01000010)
	 (2 s)
	 (6 ea DESTINATION-EA))))

(define-instruction EXG
  (((D (? rx)) (D (? ry)))
   (WORD (4 #b1100)
	 (3 rx)
	 (6 #b101000)
	 (3 ry)))

  (((A (? rx)) (A (? ry)))
   (WORD (4 #b1100)
	 (3 rx)
	 (6 #b101001)
	 (3 ry)))

  (((D (? rx)) (A (? ry)))
   (WORD (4 #b1100)
	 (3 rx)
	 (6 #b110001)
	 (3 ry)))

  (((A (? ry)) (D (? rx)))
   (WORD (4 #b1100)
	 (3 rx)
	 (6 #b110001)
	 (3 ry))))

(define-instruction LEA
  (((? ea ea-c) (A (? rx)))
   (WORD (4 #b0100)
	 (3 rx)
	 (3 #b111)
	 (6 ea DESTINATION-EA))))

(define-instruction PEA
  (((? cea ea-c))
   (WORD (10 #b0100100001)
	 (6 cea DESTINATION-EA))))

(define-instruction S
  (((? c cc) (? dea ea-d&a))
   (WORD (4 #b0101)
	 (4 c)
	 (2 #b11)
	 (6 dea DESTINATION-EA))))

(define-instruction TAS
  (((? dea ea-d&a))
   (WORD (10 #b0100101011)
	 (6 dea DESTINATION-EA))))

(define-instruction MOVEQ
  (((& (? data)) (D (? rx)))
   (WORD (4 #b0111)
	 (3 rx)
	 (1 #b0)
	 (8 data SIGNED))))

(define-instruction MOVE
  (((? s lw ssym) (? sea ea-all) (A (? rx)))	;MOVEA
   (WORD (3 #b001)
	 (1 s)
	 (3 rx)
	 (3 #b001)
	 (6 sea SOURCE-EA ssym)))

  ((B (? sea ea-all-A) (? dea ea-d&a))
   (WORD (2 #b00)
	 (2 #b01)
	 (6 dea DESTINATION-EA-REVERSED)
	 (6 sea SOURCE-EA 'B)))

  (((? s lw ssym) (? sea ea-all) (? dea ea-d&a))
   (WORD (2 #b00)
	 (1 #b1)
	 (1 s)
	 (6 dea DESTINATION-EA-REVERSED)
	 (6 sea SOURCE-EA ssym)))

  ((W (? ea ea-d) (CCR))		;MOVE to CCR
   (WORD (10 #b0100010011)
	 (6 ea SOURCE-EA 'W)))

  ((W (? ea ea-d) (SR))			;MOVE to SR
   (WORD (10 #b0100011011)
	 (6 ea SOURCE-EA 'W)))

  ((W (SR) (? ea ea-d&a))		;MOVE from SR
   (WORD (10 #b0100000011)
	 (6 ea DESTINATION-EA)))

  ((L (USP) (A (? rx)))			;MOVE from USP
   (WORD (13 #b0100111001101)
	 (3 rx)))

  ((L (A (? rx)) (USP))			;MOVE to USP
   (WORD (13 #b0100111001100)
	 (3 rx))))

(define-instruction MOVEM
  (((? s wl) (? r @+reg-list) (? dea ea-c&a))
   (WORD (9 #b010010001)
	 (1 s)
	 (6 dea DESTINATION-EA))
   (output-bit-string r))

  (((? s wl) (? r @-reg-list) (@-a (? rx)))
   (WORD (9 #b010010001)
	 (1 s)
	 (3 #b100)
	 (3 rx))
   (output-bit-string r))

  (((? s wl) (? sea ea-c) (? r @+reg-list))
   (WORD (9 #b010011001)
	 (1 s)
	 (6 sea SOURCE-EA s))
   (output-bit-string r))

  (((? s wl) (@A+ (? rx)) (? r @+reg-list))
   (WORD (9 #b010011001)
	 (1 s)
	 (3 #b011)
	 (3 rx))
   (output-bit-string r)))

(define-instruction MOVEP
  (((? s wl) (D (? rx)) (@AO (? ry) (? o)))
   (WORD (4 #b0000)
	 (3 rx)
	 (2 #b11)
	 (1 s)
	 (3 #b001)
	 (3 ry))
   (offset-word o))

  (((? s wl) (D (? rx)) (@AR (? ry) (? l)))
   (WORD (4 #b0000)
	 (3 rx)
	 (2 #b11)
	 (1 s)
	 (3 #b001)
	 (3 ry))
   (relative-word l))

  (((? s wl) (@AO (? ry) (? o)) (D (? rx)))
   (WORD (4 #b0000)
	 (3 rx)
	 (2 #b10)
	 (1 s)
	 (3 #b001)
	 (3 ry))
   (offset-word o))

  (((? s wl) (@AR (? ry) (? l)) (D (? rx)))
   (WORD (4 #b0000)
	 (3 rx)
	 (2 #b10)
	 (1 s)
	 (3 #b001)
	 (3 ry))
   (relative-word l)))
   (relative-word l)))