#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/sf/emodel.scm,v 3.2.1.2 1987/07/01 16:53:38 jinx Exp $

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

;;;; SCode Optimizer: Environment Model

(declare (usual-integrations))

(define variable/assoc
  (association-procedure eq? variable/name))

(define (block/unsafe! block)
  (if (block/safe? block)
      (begin (block/set-safe?! block false)
	     (if (block/parent block)
		 (block/unsafe! (block/parent block))))))

(define (block/lookup-name block name intern?)
  (let search ((block block))
    (or (variable/assoc name (block/bound-variables block))
	(let ((parent (block/parent block)))
	  (cond ((not (null? parent))
		 (search parent))
		(intern?
		 (variable/make&bind! block name))
		(else #f))))))

(define (block/lookup-names block names intern?)
  (map (lambda (name)
	 (block/lookup-name block name intern?))
       names))