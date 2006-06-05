#| -*-Scheme-*-

$Id: gconst.scm,v 4.33 2006/02/26 04:26:37 cph Exp $

Copyright 1987,1988,1989,1990,1991,1992 Massachusetts Institute of Technology
Copyright 1993,1994,1997,2001,2004,2005 Massachusetts Institute of Technology
Copyright 2006 Massachusetts Institute of Technology

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
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
USA.

|#

;;;; SCode Optimizer: Global Constants List
;;; package: (scode-optimizer)

(declare (usual-integrations))

;;; This is a list of names that are bound in the global environment.
;;; Normally the compiler will replace references to one of these
;;; names with the value of that name, which is a constant.

(define global-constant-objects
  '(
    %RECORD
    %RECORD-LENGTH
    %RECORD-REF
    %RECORD-SET!
    %RECORD?
    *THE-NON-PRINTING-OBJECT*
    BIT-STRING->UNSIGNED-INTEGER
    BIT-STRING-ALLOCATE
    BIT-STRING-AND!
    BIT-STRING-ANDC!
    BIT-STRING-CLEAR!
    BIT-STRING-FILL!
    BIT-STRING-LENGTH
    BIT-STRING-MOVE!
    BIT-STRING-MOVEC!
    BIT-STRING-OR!
    BIT-STRING-REF
    BIT-STRING-SET!
    BIT-STRING-XOR!
    BIT-STRING-ZERO?
    BIT-STRING=?
    BIT-STRING?
    BIT-SUBSTRING-FIND-NEXT-SET-BIT
    BIT-SUBSTRING-MOVE-RIGHT!
    CAR
    CDR
    CHAR->INTEGER
    CHAR-BITS-LIMIT
    CHAR-CODE-LIMIT
    CHAR-INTEGER-LIMIT
    CHAR:NEWLINE
    CHAR?
    COMPILED-CODE-ADDRESS->BLOCK
    COMPILED-CODE-ADDRESS->OFFSET
    CONS
    EQ?
    ERROR-PROCEDURE
    FALSE
    FALSE?
    FIX:*
    FIX:+
    FIX:-
    FIX:-1+
    FIX:1+
    FIX:<
    FIX:=
    FIX:>
    FIX:AND
    FIX:ANDC
    FIX:DIVIDE
    FIX:FIXNUM?
    FIX:GCD
    FIX:LSH
    FIX:NEGATIVE?
    FIX:NOT
    FIX:OR
    FIX:POSITIVE?
    FIX:QUOTIENT
    FIX:REMAINDER
    FIX:XOR
    FIX:ZERO?
    FLO:*
    FLO:+
    FLO:-
    FLO:/
    FLO:<
    FLO:=
    FLO:>
    FLO:ABS
    FLO:ACOS
    FLO:ASIN
    FLO:ATAN
    FLO:ATAN2
    FLO:CEILING
    FLO:CEILING->EXACT
    FLO:COS
    FLO:EXP
    FLO:EXPT
    FLO:FLONUM?
    FLO:FLOOR
    FLO:FLOOR->EXACT
    FLO:LOG
    FLO:NEGATE
    FLO:NEGATIVE?
    FLO:POSITIVE?
    FLO:ROUND
    FLO:ROUND->EXACT
    FLO:SIN
    FLO:SQRT
    FLO:TAN
    FLO:TRUNCATE
    FLO:TRUNCATE->EXACT
    FLO:VECTOR-CONS
    FLO:VECTOR-LENGTH
    FLO:VECTOR-REF
    FLO:VECTOR-SET!
    FLO:ZERO?
    GENERAL-CAR-CDR
    GET-FIXED-OBJECTS-VECTOR
    GET-INTERRUPT-ENABLES
    HUNK3-CONS
    INDEX-FIXNUM?
    INT:*
    INT:+
    INT:-
    INT:-1+
    INT:1+
    INT:<
    INT:=
    INT:>
    INT:DIVIDE
    INT:NEGATE
    INT:NEGATIVE?
    INT:POSITIVE?
    INT:QUOTIENT
    INT:REMAINDER
    INT:ZERO?
    INTEGER->CHAR
    INTEGER-DIVIDE-QUOTIENT
    INTEGER-DIVIDE-REMAINDER
    INTERRUPT-BIT/AFTER-GC
    INTERRUPT-BIT/GC
    INTERRUPT-BIT/GLOBAL-1
    INTERRUPT-BIT/GLOBAL-3
    INTERRUPT-BIT/GLOBAL-GC
    INTERRUPT-BIT/KBD
    INTERRUPT-BIT/STACK
    INTERRUPT-BIT/SUSPEND
    INTERRUPT-BIT/TIMER
    INTERRUPT-MASK/ALL
    INTERRUPT-MASK/GC-OK
    INTERRUPT-MASK/NONE
    INTERRUPT-MASK/TIMER-OK
    LAMBDA-TAG:FLUID-LET
    LAMBDA-TAG:LET
    LAMBDA-TAG:UNNAMED
    LEXICAL-ASSIGNMENT
    LEXICAL-REFERENCE
    LEXICAL-UNASSIGNED?
    LEXICAL-UNBOUND?
    LEXICAL-UNREFERENCEABLE?
    LIST->VECTOR
    LOCAL-ASSIGNMENT
    MAKE-NON-POINTER-OBJECT
    NOT
    NULL?
    OBJECT-CONSTANT?
    OBJECT-DATUM
    OBJECT-NEW-TYPE
    OBJECT-PURE?
    OBJECT-TYPE
    OBJECT-TYPE?
    PAIR?
    PRIMITIVE-PROCEDURE-ARITY
    SET-CAR!
    SET-CDR!
    SET-INTERRUPT-ENABLES!
    SET-STRING-LENGTH!
    STRING-ALLOCATE
    STRING-HASH-MOD
    STRING-LENGTH
    STRING-MAXIMUM-LENGTH
    STRING-REF
    STRING-SET!
    STRING?
    SUBSTRING-MOVE-LEFT!
    SUBSTRING-MOVE-RIGHT!
    SUBVECTOR->LIST
    SUBVECTOR-FILL!
    SUBVECTOR-MOVE-LEFT!
    SUBVECTOR-MOVE-RIGHT!
    SYSTEM-GLOBAL-ENVIRONMENT
    SYSTEM-HUNK3-CXR0
    SYSTEM-HUNK3-CXR1
    SYSTEM-HUNK3-CXR2
    SYSTEM-HUNK3-SET-CXR0!
    SYSTEM-HUNK3-SET-CXR1!
    SYSTEM-HUNK3-SET-CXR2!
    SYSTEM-LIST->VECTOR
    SYSTEM-PAIR-CAR
    SYSTEM-PAIR-CDR
    SYSTEM-PAIR-CONS
    SYSTEM-PAIR-SET-CAR!
    SYSTEM-PAIR-SET-CDR!
    SYSTEM-PAIR?
    SYSTEM-SUBVECTOR->LIST
    SYSTEM-VECTOR-LENGTH
    SYSTEM-VECTOR-REF
    SYSTEM-VECTOR-SET!
    SYSTEM-VECTOR?
    THE-EMPTY-STREAM
    TRUE
    UNDEFINED-CONDITIONAL-BRANCH
    UNSIGNED-INTEGER->BIT-STRING
    UNSPECIFIC
    VECTOR
    VECTOR-8B-REF
    VECTOR-8B-SET!
    VECTOR-LENGTH
    VECTOR-REF
    VECTOR-SET!
    VECTOR?
    WITH-HISTORY-DISABLED
    WITH-INTERRUPT-MASK
    ))