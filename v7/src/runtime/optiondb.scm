#| -*-Scheme-*-

$Id: optiondb.scm,v 1.6 1999/01/29 22:47:08 cph Exp $

Copyright (c) 1994-1999 Massachusetts Institute of Technology

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
|#

(declare (usual-integrations))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This file contains Scheme code to define a set of load options.  Each
;; time a new (not-yet-loaded) load option is requested, this file is
;; loaded into a fresh environment which has the system global
;; environment as parent.
;;
;; Procedures used for defining load options:
;;
;; (DEFINE-LOAD-OPTION 'NAME loader loader ...)
;;   Defines a load option (NAME) which is loaded by the execution of its
;;   loaders.  Loaders are executed left to right.  Loaders are thunks.
;;
;; (STANDARD-OPTION-LOADER 'PACKAGE-NAME 'EXPR file file ...)
;;   Creates a loader that loads the files (strings relative to
;;   $MITSCHEME_LIBRARY_PATH/options) into the environment of the
;;   package named PACKAGE-NAME, and then evaluates EXPR in that load
;;   environment. If EXPR is #F of course evaluating it has no effect.
;; 
;; (FURTHER-LOAD-OPTIONS EXPR)
;;   EXPR is the place to look next for the load options.  Useful objects
;;   are STANDARD-LOAD-OPTIONS (load options supplied with the
;;   MIT-Scheme distribution) and LOCAL-LOAD-OPTIONS (load options
;;   supplied for every user of your architecture at your site).  If
;;   not specified, or is #F, then this file is the last options
;;   database that is searched.

;; Standard load options are defined like this:

(define-load-option 'ARITHMETIC-INTERFACE
  (standard-option-loader '(RUNTIME NUMBER INTERFACE) #F "numint"))

;; We can use programming to make the definitions less noisy and tedious:

(for-each
 (lambda (spec)
   (define-load-option (car spec) (apply standard-option-loader (cdr spec))))
 '((COMPRESS	(RUNTIME COMPRESS)	#F			"cpress")
   (FORMAT	(RUNTIME FORMAT)	(INITIALIZE-PACKAGE!)	"format")
   (GDBM	(RUNTIME GDBM)		(INITIALIZE-PACKAGE!)	"gdbm")
   (HASH-TABLE	(RUNTIME HASH-TABLE)	(INITIALIZE-PACKAGE!)	"hashtb")
   (ORDERED-VECTOR (RUNTIME ORDERED-VECTOR) #F			"ordvec")
   (RB-TREE	(RUNTIME RB-TREE)	#F			"rbtree")
   (STEPPER	(RUNTIME STEPPER)	#F			"ystep")
   (SUBPROCESS	(RUNTIME SUBPROCESS)	(INITIALIZE-PACKAGE!)	"process")
   (SYNCHRONOUS-SUBPROCESS (RUNTIME SYNCHRONOUS-SUBPROCESS) #F	"syncproc")
   (WT-TREE	(RUNTIME WT-TREE)	#F			"wttree")
   ))

(define-load-option 'DOSPROCESS
  (standard-option-loader '() #F "dosproc"))