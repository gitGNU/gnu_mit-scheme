;;; -*-Scheme-*-
;;;
;;;	$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/edwin/regexp.scm,v 1.52 1991/04/26 03:11:40 cph Exp $
;;;
;;;	Copyright (c) 1986, 1989-91 Massachusetts Institute of Technology
;;;
;;;	This material was developed by the Scheme project at the
;;;	Massachusetts Institute of Technology, Department of
;;;	Electrical Engineering and Computer Science.  Permission to
;;;	copy this software, to redistribute it, and to use it for any
;;;	purpose is granted, subject to the following restrictions and
;;;	understandings.
;;;
;;;	1. Any copy made of this software must include this copyright
;;;	notice in full.
;;;
;;;	2. Users of this software agree to make their best efforts (a)
;;;	to return to the MIT Scheme project any improvements or
;;;	extensions that they make, so that these may be included in
;;;	future releases; and (b) to inform MIT of noteworthy uses of
;;;	this software.
;;;
;;;	3. All materials developed as a consequence of the use of this
;;;	software shall duly acknowledge such use, in accordance with
;;;	the usual standards of acknowledging credit in academic
;;;	research.
;;;
;;;	4. MIT has made no warrantee or representation that the
;;;	operation of this software will be error-free, and MIT is
;;;	under no obligation to provide any services, by way of
;;;	maintenance, update, or otherwise.
;;;
;;;	5. In conjunction with products arising from the use of this
;;;	material, there shall be no use of the name of the
;;;	Massachusetts Institute of Technology nor of any adaptation
;;;	thereof in any advertising, promotional, or sales literature
;;;	without prior written consent from MIT in each case.
;;;
;;; NOTE: Parts of this program (Edwin) were created by translation
;;; from corresponding parts of GNU Emacs.  Users should be aware that
;;; the GNU GENERAL PUBLIC LICENSE may apply to these parts.  A copy
;;; of that license should have been included along with this file.
;;;

;;;; Regular Expressions

(declare (usual-integrations))

(define registers (make-vector 20))
(define match-group (object-hash false))
(define standard-syntax-table (make-syntax-table))

(define-integrable (re-match-start-index i)
  (vector-ref registers i))

(define-integrable (re-match-end-index i)
  (vector-ref registers (+ i 10)))

(define (re-match-start i)
  (guarantee-re-register i 'RE-MATCH-START)
  (let ((index (re-match-start-index i)))
    (and (not (negative? index))
	 (make-mark (re-match-group) index))))

(define (re-match-end i)
  (guarantee-re-register i 'RE-MATCH-END)
  (let ((index (re-match-end-index i)))
    (and (not (negative? index))
	 (make-mark (re-match-group) index))))

(define (guarantee-re-register i operator)
  (if (not (and (exact-nonnegative-integer? i) (< i 10)))
      (error:wrong-type-argument i "RE register" operator)))

(define (re-match-group)
  (let ((group (object-unhash match-group)))
    (if (not group)
	(error "No match group"))
    group))

(define (preserving-match-data thunk)
  (fluid-let ((registers (vector-copy registers))
	      (match-group match-group))
    (thunk)))

(define-integrable (syntax-table-argument syntax-table)
  (syntax-table/entries (or syntax-table standard-syntax-table)))

(define (replace-match replacement #!optional preserve-case? literal?)
  (let ((start (re-match-start 0))
	(end (re-match-end 0)))
    (let ((replacement
	   (let ((replacement
		  (if (and (not (default-object? literal?)) literal?)
		      replacement
		      (re-substitute-registers replacement))))
	     (if (and (not (default-object? preserve-case?) preserve-case?))
		 ;; Emacs uses a more complicated algorithm here,
		 ;; which breaks the replaced string into words,
		 ;; makes the decision based on examining all the
		 ;; words, and then changes each word in the
		 ;; replacement to match the pattern.
		 (let ((replaced (extract-string start end)))
		   (cond ((string-upper-case? replaced)
			  (string-upcase replacement))
			 ((string-capitalized? replaced)
			  (string-capitalize replacement))
			 (else replacement)))
		 replacement))))
      (delete-string start end)
      (insert-string replacement start))
    start))

(define (re-substitute-registers string)
  (let ((end (string-length string)))
    (if (substring-find-next-char string 0 end #\\)
	(apply
	 string-append
	 (let loop ((start 0))
	   (let ((slash (substring-find-next-char string start end #\\)))
	     (if slash
		 (cons (substring string start slash)
		       (let ((next (+ slash 1)))
			 (cons (let ((char
				      (if (< next end)
					  (string-ref string next)
					  #\\)))
				 (let ((n
					(if (char=? #\& char)
					    0
					    (char->digit char))))
				   (cond ((not n)
					  (string char))
					 ((negative? (re-match-start-index n))
					  (string #\\ char))
					 (else
					  (extract-string
					   (re-match-start n)
					   (re-match-end n))))))
			       (if (< next end)
				   (loop (+ next 1))
				   '()))))
		 (list (substring string start end))))))
	string)))

(define (delete-match)
  (let ((start (re-match-start 0)))
    (delete-string start (re-match-end 0))
    start))

(define (re-search-buffer-forward pattern case-fold-search syntax-table
				  group start end)
  (let ((index
	 ((ucode-primitive re-search-buffer-forward)
	  pattern
	  (re-translation-table case-fold-search)
	  (syntax-table-argument syntax-table)
	  registers
	  group start end)))
    (set! match-group (object-hash (and index group)))
    index))

(define (re-search-buffer-backward pattern case-fold-search syntax-table
				   group start end)
  (let ((index
	 ((ucode-primitive re-search-buffer-backward)
	  pattern
	  (re-translation-table case-fold-search)
	  (syntax-table-argument syntax-table)
	  registers
	  group start end)))
    (set! match-group (object-hash (and index group)))
    index))

(define (re-match-buffer-forward pattern case-fold-search syntax-table
				 group start end)
  (let ((index
	 ((ucode-primitive re-match-buffer)
	  pattern
	  (re-translation-table case-fold-search)
	  (syntax-table-argument syntax-table)
	  registers
	  group start end)))
    (set! match-group (object-hash (and index group)))
    index))

(define (re-match-string-forward pattern case-fold-search syntax-table string)
  (re-match-substring-forward pattern case-fold-search syntax-table
			      string 0 (string-length string)))

(define (re-match-substring-forward pattern case-fold-search syntax-table
				    string start end)
  (set! match-group (object-hash false))
  ((ucode-primitive re-match-substring)
   pattern
   (re-translation-table case-fold-search)
   (syntax-table-argument syntax-table)
   registers
   string start end))

(define (re-search-string-forward pattern case-fold-search syntax-table string)
  (re-search-substring-forward pattern case-fold-search syntax-table
			       string 0 (string-length string)))

(define (re-search-substring-forward pattern case-fold-search syntax-table
				     string start end)
  (set! match-group (object-hash false))
  ((ucode-primitive re-search-substring-forward)
   pattern
   (re-translation-table case-fold-search)
   (syntax-table-argument syntax-table)
   registers
   string start end))

(define (re-search-string-backward pattern case-fold-search syntax-table
				   string)
  (re-search-substring-backward pattern case-fold-search syntax-table
				string 0 (string-length string)))

(define (re-search-substring-backward pattern case-fold-search syntax-table
				      string start end)
  (set! match-group (object-hash false))
  ((ucode-primitive re-search-substring-backward)
   pattern
   (re-translation-table case-fold-search)
   (syntax-table-argument syntax-table)
   registers
   string start end))

(define (search-forward string start end #!optional case-fold-search)
  (%re-search string start end
	      (if (default-object? case-fold-search)
		  (group-case-fold-search (mark-group start))
		  case-fold-search)
	      re-compile-string
	      re-search-buffer-forward))

(define (search-backward string end start #!optional case-fold-search)
  (%re-search string start end
	      (if (default-object? case-fold-search)
		  (group-case-fold-search (mark-group start))
		  case-fold-search)
	      re-compile-string
	      re-search-buffer-backward))

(define (re-search-forward regexp start end #!optional case-fold-search)
  (%re-search regexp start end
	      (if (default-object? case-fold-search)
		  (group-case-fold-search (mark-group start))
		  case-fold-search)
	      re-compile-pattern
	      re-search-buffer-forward))

(define (re-search-backward regexp end start #!optional case-fold-search)
  (%re-search regexp start end
	      (if (default-object? case-fold-search)
		  (group-case-fold-search (mark-group start))
		  case-fold-search)
	      re-compile-pattern
	      re-search-buffer-backward))

(define (%re-search string start end case-fold-search compile-string search)
  (if (not (mark<= start end))
      (error "Marks incorrectly related:" start end))
  (let ((group (mark-group start)))
    (let ((index
	   (search (compile-string string case-fold-search)
		   case-fold-search
		   (group-syntax-table group)
		   group
		   (mark-index start)
		   (mark-index end))))
      (and index
	   (make-mark group index)))))

(define (re-match-forward regexp start #!optional end case-fold-search)
  (let ((group (mark-group start)))
    (let ((case-fold-search
	   (if (default-object? case-fold-search)
	       (group-case-fold-search group)
	       case-fold-search)))
      (let ((index
	     (re-match-buffer-forward
	      (re-compile-pattern regexp case-fold-search)
	      case-fold-search
	      (group-syntax-table group)
	      group
	      (mark-index start)
	      (mark-index
	       (if (default-object? end)
		   (group-end-mark group)
		   (begin
		     (if (not (mark<= start end))
			 (error "Marks incorrectly related:" start end))
		     end))))))
	(and index
	     (make-mark group index))))))