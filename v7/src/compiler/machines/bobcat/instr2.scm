#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/machines/bobcat/instr2.scm,v 1.9.1.1 1987/06/10 21:21:06 jinx Exp $

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

;;;; Pseudo ops

(define-instruction DC
  ((W (? expression))
   (WORD (16 expression SIGNED))))

;;;; BCD Arithmetic

(let-syntax ((define-BCD-addition
	      (macro (keyword opcode)
		`(define-instruction ,keyword
		   (((D (? ry)) (D (? rx)))
		    (WORD (4 ,opcode)
			  (3 rx)
			  (6 #b100000)
			  (3 ry)))

		   (((@-A (? ry)) (@-A (? rx)))
		    (WORD (4 ,opcode)
			  (3 rx)
			  (6 #b100001)
			  (3 ry)))))))
  (define-BCD-addition ABCD #b1100)
  (define-BCD-addition SBCD #b1000))

(define-instruction NBCD
  ((? dea ea-d&a)
   (WORD (10 #b0100100000)
	 (6 dea DESTINATION-EA))))

;;;; Binary Arithmetic

(let-syntax ((define-binary-addition
	      (macro (keyword Qkeyword Xkeyword opcode Qbit Iopcode)
		`(BEGIN
		  (define-instruction ,Qkeyword				;ADDQ
		    ((B (& (? data)) (? ea ea-all-A))
		     (WORD (4 #b0101)
			   (3 data QUICK)
			   (1 ,Qbit)
			   (2 #b00)
			   (6 ea DESTINATION-EA)))

		    (((? s bwl-b) (& (? data)) (? ea ea-all))
		     (WORD (4 #b0101)
			   (3 data QUICK)
			   (1 ,Qbit)
			   (2 s)
			   (6 ea DESTINATION-EA))))

		  (define-instruction ,keyword
		    (((? s bwl ssym) (& (? data)) (? ea ea-d&a))	;ADDI
		     (WORD (4 #b0000)
			   (4 ,Iopcode)
			   (2 s)
			   (6 ea DESTINATION-EA))
		     (immediate-words data ssym))

		    ((B (? ea ea-all-A) (D (? rx)))
		     (WORD (4 ,opcode)
			   (3 rx)
			   (1 #b0)
			   (2 #b00)
			   (6 ea SOURCE-EA 'B)))

		    (((? s bwl-b ssym) (? ea ea-all) (D (? rx)))
		     (WORD (4 ,opcode)
			   (3 rx)
			   (1 #b0)
			   (2 s)
			   (6 ea SOURCE-EA ssym)))

		    (((? s bwl) (D (? rx)) (? ea ea-m&a))
		     (WORD (4 ,opcode)
			   (3 rx)
			   (1 #b1)
			   (2 s)
			   (6 ea DESTINATION-EA)))

		    (((? s wl ssym) (? ea ea-all) (A (? rx)))	;ADDA
		     (WORD (4 ,opcode)
			   (3 rx)
			   (1 s)
			   (2 #b11)
			   (6 ea SOURCE-EA ssym))))

		  (define-instruction ,Xkeyword
		    (((? s bwl) (D (? ry)) (D (? rx)))
		     (WORD (4 ,opcode)
			   (3 rx)
			   (1 #b1)
			   (2 s)
			   (3 #b000)
			   (3 ry)))

		    (((? s bwl) (@-A (? ry)) (@-A (? rx)))
		     (WORD (4 ,opcode)
			   (3 rx)
			   (1 #b1)
			   (2 s)
			   (3 #b001)
			   (3 ry))))))))
  (define-binary-addition ADD ADDQ ADDX #b1101 #b0 #b0110)
  (define-binary-addition SUB SUBQ SUBX #b1001 #b1 #b0100))

(define-instruction DIV
  (((? sgn us) (D (? rx)) (? ea ea-d))
   (WORD (4 #b1000)
	 (3 rx)
	 (1 sgn)
	 (2 #b11)
	 (6 ea SOURCE-EA 'W))))

(define-instruction EXT
  (((? s wl) (D (? rx)))
   (WORD (9 #b010010001)
	 (1 s)
	 (3 #b000)
	 (3 rx))))

(define-instruction MUL
  (((? sgn us) (? ea ea-d) (D (? rx)))
   (WORD (4 #b1100)
	 (3 rx)
	 (1 sgn)
	 (2 #b11)
	 (6 ea SOURCE-EA 'W))))

(define-instruction NEG
  (((? s bwl) (? dea ea-d&a))
   (WORD (8 #b01000100)
	 (2 s)
	 (6 dea DESTINATION-EA))))

(define-instruction NEGX
  (((? s bwl) (? dea ea-d&a))
   (WORD (8 #b01000000)
	 (2 s)
	 (6 dea DESTINATION-EA))))

;;;; Comparisons

(define-instruction CMP
  ((B (? ea ea-all-A) (D (? rx)))
   (WORD (4 #b1011)
	 (3 rx)
	 (1 #b0)
	 (2 #b00)
	 (6 ea SOURCE-EA 'B)))

  (((? s bwl-b ssym) (? ea ea-all) (D (? rx)))
   (WORD (4 #b1011)
	 (3 rx)
	 (1 #b0)
	 (2 s)
	 (6 ea SOURCE-EA ssym)))

  (((? s wl ssym) (? ea ea-all) (A (? rx)))	;CMPA
   (WORD (4 #b1011)
	 (3 rx)
	 (1 s)
	 (2 #b11)
	 (6 ea SOURCE-EA ssym)))

  (((? s bwl ssym) (& (? data)) (? ea ea-d&a))	;CMPI
   (WORD (8 #b00001100)
	 (2 s)
	 (6 ea DESTINATION-EA))
   (immediate-words data ssym))

  (((? s bwl) (@A+ (? ry)) (@A+ (? rx)))	;CMPM
   (WORD (4 #b1011)
	 (3 rx)
	 (1 #b1)
	 (2 s)
	 (3 #b001)
	 (3 ry))))

(define-instruction TST
  (((? s bwl) (? dea ea-d&a))
   (WORD (8 #b01001010)
	 (2 s)
	 (6 dea DESTINATION-EA))))

;;;; Bitwise Logical

(let-syntax ((define-bitwise-logical
	      (macro (keyword opcode Iopcode)
		`(define-instruction ,keyword
		   (((? s bwl ssym) (? ea ea-d) (D (? rx)))
		    (WORD (4 ,opcode)
			  (3 rx)
			  (1 #b0)
			  (2 s)
			  (6 ea SOURCE-EA ssym)))

		   (((? s bwl) (D (? rx)) (? ea ea-m&a))
		    (WORD (4 ,opcode)
			  (3 rx)
			  (1 #b1)
			  (2 s)
			  (6 ea DESTINATION-EA)))

		   (((? s bwl ssym) (& (? data)) (? ea ea-d&a))	;fooI
		    (WORD (4 #b0000)
			  (4 ,Iopcode)
			  (2 s)
			  (6 ea DESTINATION-EA))
		    (immediate-words data ssym))

		   (((? s bwl ssym) (& (? data)) (SR))		;fooI to CCR/SR
		    (WORD (4 #b0000)
			  (4 ,Iopcode)
			  (2 s)
			  (6 #b111100))
		    (immediate-words data ssym))))))
  (define-bitwise-logical AND #b1100 #b0010)
  (define-bitwise-logical OR  #b1000 #b0000))

(define-instruction EOR
  (((? s bwl) (D (? rx)) (? ea ea-d&a))
   (WORD (4 #b1011)
	 (3 rx)
	 (1 #b1)
	 (2 s)
	 (6 ea DESTINATION-EA)))

  (((? s bwl ssym) (& (? data)) (? ea ea-d&a))	;EORI
   (WORD (8 #b00001010)
	 (2 s)
	 (6 ea DESTINATION-EA))
   (immediate-words data ssym))

  (((? s bw ssym) (& (? data)) (SR))		;EORI to CCR/SR
   (WORD (8 #b00001010)
	 (2 s)
	 (6 #b111100))
   (immediate-words data ssym)))

(define-instruction NOT
  (((? s bwl) (? dea ea-d&a))
   (WORD (8 #b01000110)
	 (2 s)
	 (6 dea DESTINATION-EA))))

;;;; Shift

(let-syntax ((define-shift-instruction
	      (macro (keyword bits)
		`(define-instruction ,keyword
		   (((? d rl) (? s bwl) (D (? ry)) (D (? rx)))
		    (WORD (4 #b1110)
			  (3 rx)
			  (1 d)
			  (2 s)
			  (1 #b1)
			  (2 ,bits)
			  (3 ry)))

		   (((? d rl) (? s bwl) (& (? data)) (D (? ry)))
		    (WORD (4 #b1110)
			  (3 data SHIFT-NUMBER)
			  (1 d)
			  (2 s)
			  (1 #b0)
			  (2 ,bits)
			  (3 ry)))

		   (((? d rl) (? ea ea-m&a))
		    (WORD (5 #b11100)
			  (2 ,bits)
			  (1 d)
			  (2 #b11)
			  (6 ea DESTINATION-EA)))))))
  (define-shift-instruction AS  #b00)
  (define-shift-instruction LS  #b01)
  (define-shift-instruction ROX #b10)
  (define-shift-instruction RO  #b11))

;;;; Bit Manipulation

(let-syntax ((define-bit-manipulation
	      (macro (keyword bits ea-register-target ea-immediate-target)
		`(define-instruction ,keyword
		   (((D (? rx)) (? ea ,ea-register-target))
		    (WORD (4 #b0000)
			  (3 rx)
			  (1 #b1)
			  (2 ,bits)
			  (6 ea DESTINATION-EA)))

		   (((& (? bitnum)) (? ea ,ea-immediate-target))
		    (WORD (8 #b00001000)
			  (2 ,bits)
			  (6 ea DESTINATION-EA))
		    (immediate-byte bitnum))))))
  (define-bit-manipulation BTST #b00 ea-d   ea-d&-&)
  (define-bit-manipulation BCHG #b01 ea-d&a ea-d&a)
  (define-bit-manipulation BCLR #b10 ea-d&a ea-d&a)
  (define-bit-manipulation BSET #b11 ea-d&a ea-d&a))
  (define-bit-manipulation BSET #b11 ea-d&a ea-d&a))