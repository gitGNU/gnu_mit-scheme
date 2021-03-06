/* -*-C-*-

Copyright (c) 1987-1999 Massachusetts Institute of Technology

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

/* This file contains the fixnum multiplication procedure.  Returns
   SHARP_F if the result does not fit in a fixnum.  Note: The portable
   version has only been tried on machines with long = 32 bits.  This
   file is included in the appropriate os file. */

extern SCHEME_OBJECT
  EXFUN (Mul, (SCHEME_OBJECT, SCHEME_OBJECT));

#if (TYPE_CODE_LENGTH == 8)

#if defined(vax) && defined(_BSD)

#define MUL_HANDLED

/* Note that "register" is used here (not "fast") since the
   assembly code requires knowledge of the location of
   the variables and they therefore must be in registers.
   This is a kludge.  It depends on what register variables
   get assigned to what registers.  It should be entirely
   coded in assembly language.  -- JINX

   With gcc, we do have a half-way decent interface to assembly
   code, so the register-assignment dependency is removed.  -- KR
*/

SCHEME_OBJECT
DEFUN (Mul, (Arg1, Arg2),
       SCHEME_OBJECT Arg1
       AND SCHEME_OBJECT Arg2)
{
  register long A = (FIXNUM_TO_LONG (Arg1));
  register long B = (FIXNUM_TO_LONG (Arg2));
#if __GNUC__
#if FALSE
  /* GCC isn't yet efficient enough with `long long' -- KR.  */
  {
    register long long X;
    asm ("emul %1,%2,$0,%0" : "=g" (X) : "g" (A), "g" (B));
    return
      ((((X & (-1 << 23)) == 0) ||
	((X & (-1 << 23)) == (-1 << 23)))
       ? (LONG_TO_FIXNUM ((long) X))
       : SHARP_F);
  }
#else
  /* non-long-long version: */
  {
    register struct
      {
	long low;
	long high;
      } X;
    asm ("emul %1,%2,$0,%0" : "=g" (X) : "g" (A), "g" (B));
    B = (X . low);
    A = (X . high);
  }
#endif
#else /* not __GNUC__ */
  asm("	emul r11,r10,$0,r10");  /* A is in 11, B in 10 */
#endif
  /* A should have high order result, B low order */
  return
    ((((A == 0)  && (B & (-1 << 23)) == 0) ||
      ((A == -1) && (B & (-1 << 23)) == (-1 << 23)))
     ? (LONG_TO_FIXNUM (B))
     : SHARP_F);
}

#endif /* vax and _BSD */

/* 68k family code.  Uses hp9000s300 conventions for the new compiler. */

#if defined(hp9000s300) && !defined(old_cc) && !defined(__GNUC__)
#define MUL_HANDLED

/* The following constants are hard coded in the assembly language
 * code below.  The code assumes that d0 and d1 are scratch registers
 * for the compiler.
 */

#if (SHARP_F != 0) || (TC_FIXNUM != 0x1A)
#include "Error: types changed.  Change assembly language appropriately"
#endif

#ifndef MC68010 /* MC68020, MC68030, or MC68040 */

static long Fixnum_Range[2] = {SMALLEST_FIXNUM , BIGGEST_FIXNUM};

	asm("	text");
	asm("	global _Mul");
	asm("_Mul:");
	asm("	bfexts	4(%sp){&8:&24},%d0");
	asm("	bfexts	8(%sp){&8:&24},%d1");
	asm("	muls.l	%d1,%d0");
	asm("	bvs.b	result_is_nil");
	asm("	cmp2.l	%d0,_Fixnum_Range");
	asm("	bcs.b	result_is_nil");
	asm("	moveq	&0x1A,%d1");
	asm("	bfins	%d1,%d0{&0:&8}");
	asm("	rts");
	asm("result_is_nil:");
	asm("	clr.l	%d0");
	asm("	rts");
	asm("	data");

#else	/* MC68010 */

	/* 20(sp) = arg0; 24(sp) = arg1 because of movem */

	asm("	text");
	asm("	global _Mul");
	asm("_Mul:");
	asm("	movem.l	%d2-%d5,-(%sp)");
	asm("	clr.b	%d5");
	asm("	tst.b	21(%sp)");
	asm("	slt	20(%sp)");
	asm("	bge.b	coerce_1");
	asm("	moveq	&1,%d5");
	asm("	neg.l	20(%sp)");

	asm("coerce_1:");
	asm("	tst.b	25(%sp)");
	asm("	slt	24(%sp)");
	asm("	bge.b	after_coerce");
	asm("	eori.b	&1,%d5");
	asm("	neg.l	24(%sp)");
	asm("after_coerce:");
	asm("	move.l	20(%sp),%d0");
	asm("	move.l	24(%sp),%d1");
	asm("	move.w	%d0,%d2");
	asm("	mulu	%d1,%d2");
	asm("	move.w	%d1,%d4");
	asm("	swap	%d1");
	asm("	move.w	%d1,%d3");
	asm("	mulu	%d0,%d3");
	asm("	swap	%d0");
	asm("	mulu	%d0,%d4");
	asm("	add.l	%d4,%d3");
	asm("	bcs.b	result_is_nil");
	asm("	mulu	%d0,%d1");
	asm("	bne.b	result_is_nil");
	asm("	swap	%d2");
	asm("	add.w	%d3,%d2");
	asm("	bcs.b	result_is_nil");
	asm("	swap	%d3");
	asm("	tst.w	%d3");
	asm("	bne.b	result_is_nil");
	asm("	cmpi.w	%d2,&0x7F");
	asm("	bgt.b	result_is_nil");
	asm("	swap	%d2");
	asm("	tst.b	%d5");
	asm("	beq.b	sign_is_right");
	asm("	neg.l	%d2");
	asm("sign_is_right:");
	asm("	move.l	%d2,-(%sp)");
	asm("	move.b	&0x1A,(%sp)");
	asm("	move.l	(%sp)+,%d0");
	asm("	movem.l	(%sp)+,%d2-%d5");
	asm("	rts");
	asm("result_is_nil:");
	asm("	clr.l	%d0");
	asm("	movem.l	(%sp)+,%d2-%d5");
	asm("	rts");
	asm("	data");

#endif	/* MC68010 */
#endif  /* hp9000s300 */

#endif /* (TYPE_CODE_LENGTH == 8) */

#ifndef MUL_HANDLED

#define ONE		((unsigned long) 1)

#define HALF_WORD_SIZE	(((sizeof (long)) * CHAR_BIT) / 2)
#define HALF_WORD_MASK	((ONE << HALF_WORD_SIZE) - 1)
#define MAX_MIDDLE	((BIGGEST_FIXNUM + 1) >> HALF_WORD_SIZE)
#define	ABS(x)		(((x) < 0) ? -(x) : (x))

SCHEME_OBJECT
DEFUN (Mul, (Arg1, Arg2),
       SCHEME_OBJECT Arg1
       AND SCHEME_OBJECT Arg2)
{
  long A, B, C;
  fast unsigned long Hi_A, Hi_B, Lo_A, Lo_B, Lo_C, Middle_C;
  Boolean Sign;

  A = (FIXNUM_TO_LONG (Arg1));
  B = (FIXNUM_TO_LONG (Arg2));
  Sign = ((A < 0) == (B < 0));
  A = ABS(A);
  B = ABS(B);
  Hi_A = ((A >> HALF_WORD_SIZE) & HALF_WORD_MASK);
  Hi_B = ((B >> HALF_WORD_SIZE) & HALF_WORD_MASK);
  if ((Hi_A > 0) && (Hi_B > 0))
    return (SHARP_F);
  Lo_A = (A & HALF_WORD_MASK);
  Lo_B = (B & HALF_WORD_MASK);
  Lo_C = (Lo_A * Lo_B);
  if (Lo_C >= FIXNUM_SIGN_BIT)
    return (SHARP_F);
  Middle_C = (Lo_A * Hi_B) + (Hi_A * Lo_B);

  if (Middle_C >= MAX_MIDDLE)
    return (SHARP_F);
  C = Lo_C + (Middle_C << HALF_WORD_SIZE);
  if (LONG_TO_FIXNUM_P(C))
  {
    if (Sign || (C == 0))
      return (LONG_TO_UNSIGNED_FIXNUM(C));
    else
      return (LONG_TO_FIXNUM(-C));
  }
  return (SHARP_F);
}

#endif /* not MUL_HANDLED */
