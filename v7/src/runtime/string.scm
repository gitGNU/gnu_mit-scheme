#| -*-Scheme-*-

$Id: string.scm,v 14.42 2001/03/21 05:41:41 cph Exp $

Copyright (c) 1988-2001 Massachusetts Institute of Technology

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
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
02111-1307, USA.
|#

;;;; Character String Operations
;;; package: (runtime string)

;; NOTE
;;
;; This file is designed to be compiled with type and range checking
;; turned off. The advertised user-visible procedures all explicitly
;; check their arguments.
;;
;; Many of the procedures are split into several user versions that just
;; validate their arguments and pass them on to an internal version
;; (prefixed with `%') that assumes all arguments have been checked.
;; This avoids repeated argument checks.

(declare (usual-integrations))

;;;; Primitives

(define-primitives
  string-allocate string? string-ref string-set!
  string-length set-string-length!
  string-maximum-length set-string-maximum-length!
  substring=? substring-ci=? substring<?
  substring-move-right! substring-move-left!
  substring-find-next-char-in-set
  substring-find-previous-char-in-set
  substring-match-forward substring-match-backward
  substring-match-forward-ci substring-match-backward-ci
  substring-upcase! substring-downcase! string-hash string-hash-mod

  vector-8b-ref vector-8b-set! vector-8b-fill!
  vector-8b-find-next-char vector-8b-find-previous-char
  vector-8b-find-next-char-ci vector-8b-find-previous-char-ci)

;;; Character Covers

(define-integrable (substring-fill! string start end char)
  (vector-8b-fill! string start end (char->ascii char)))

(define-integrable (substring-find-next-char string start end char)
  (vector-8b-find-next-char string start end (char->ascii char)))

(define-integrable (substring-find-previous-char string start end char)
  (vector-8b-find-previous-char string start end (char->ascii char)))

(define-integrable (substring-find-next-char-ci string start end char)
  (vector-8b-find-next-char-ci string start end (char->ascii char)))

(define-integrable (substring-find-previous-char-ci string start end char)
  (vector-8b-find-previous-char-ci string start end (char->ascii char)))

;;; Special, not implemented in microcode.

(define (substring-ci<? string1 start1 end1 string2 start2 end2)
  (let ((match (substring-match-forward-ci string1 start1 end1
					   string2 start2 end2))
	(len1 (fix:- end1 start1))
	(len2 (fix:- end2 start2)))
    (and (not (fix:= match len2))
	 (or (fix:= match len1)
	     (char-ci<? (string-ref string1 (fix:+ match start1))
			(string-ref string2 (fix:+ match start2)))))))

;;; Substring Covers

(define (string=? string1 string2)
  (guarantee-2-strings string1 string2 'STRING=?)
  (substring=? string1 0 (string-length string1)
	       string2 0 (string-length string2)))

(define (string-ci=? string1 string2)
  (guarantee-2-strings string1 string2 'STRING-CI=?)
  (substring-ci=? string1 0 (string-length string1)
		  string2 0 (string-length string2)))

(define (string<? string1 string2)
  (guarantee-2-strings string1 string2 'STRING<?)
  (substring<? string1 0 (string-length string1)
	       string2 0 (string-length string2)))

(define (string-ci<? string1 string2)
  (guarantee-2-strings string1 string2 'STRING-ci<?)
  (substring-ci<? string1 0 (string-length string1)
		  string2 0 (string-length string2)))

(define (string>? string1 string2)
  (guarantee-2-strings string1 string2 'STRING>?)
  (substring<? string2 0 (string-length string2)
	       string1 0 (string-length string1)))

(define (string-ci>? string1 string2)
  (guarantee-2-strings string1 string2 'STRING-CI>?)
  (substring-ci<? string2 0 (string-length string2)
		  string1 0 (string-length string1)))

(define (string>=? string1 string2)
  (guarantee-2-strings string1 string2 'STRING-CI>=?)
  (not (substring<? string1 0 (string-length string1)
		    string2 0 (string-length string2))))

(define (string-ci>=? string1 string2)
  (guarantee-2-strings string1 string2 'STRING-CI>=?)
  (not (substring-ci<? string1 0 (string-length string1)
		       string2 0 (string-length string2))))

(define (string<=? string1 string2)
  (guarantee-2-strings string1 string2 'STRING<=?)
  (not (substring<? string2 0 (string-length string2)
		    string1 0 (string-length string1))))

(define (string-ci<=? string1 string2)
  (guarantee-2-strings string1 string2 'STRING-ci<=?)
  (not (substring-ci<? string2 0 (string-length string2)
		       string1 0 (string-length string1))))

(define (string-fill! string char)
  (guarantee-string string 'STRING-FILL!)
  (substring-fill! string 0 (string-length string) char))

(define (string-find-next-char string char)
  (guarantee-string string 'STRING-FIND-NEXT-CHAR)
  (substring-find-next-char string 0 (string-length string) char))

(define (string-find-previous-char string char)
  (guarantee-string string 'STRING-FIND-PREVIOUS-CHAR)
  (substring-find-previous-char string 0 (string-length string) char))

(define (string-find-next-char-ci string char)
  (guarantee-string string 'STRING-FIND-NEXT-CHAR-CI)
  (substring-find-next-char-ci string 0 (string-length string) char))

(define (string-find-previous-char-ci string char)
  (guarantee-string string 'STRING-FIND-PREVIOUS-CHAR-CI)
  (substring-find-previous-char-ci string 0 (string-length string) char))

(define (string-find-next-char-in-set string char-set)
  (guarantee-string string 'STRING-FIND-NEXT-CHAR-IN-SET)
  (substring-find-next-char-in-set string 0 (string-length string) char-set))

(define (string-find-previous-char-in-set string char-set)
  (guarantee-string string 'STRING-FIND-PREVIOUS-CHAR-IN-SET)
  (substring-find-previous-char-in-set string 0 (string-length string)
				       char-set))

(define (string-match-forward string1 string2)
  (guarantee-2-strings string1 string2 'STRING-MATCH-FORWARD)
  (substring-match-forward string1 0 (string-length string1)
			   string2 0 (string-length string2)))

(define (string-match-backward string1 string2)
  (guarantee-2-strings string1 string2 'STRING-MATCH-BACKWARD)
  (substring-match-backward string1 0 (string-length string1)
			    string2 0 (string-length string2)))

(define (string-match-forward-ci string1 string2)
  (guarantee-2-strings string1 string2 'STRING-MATCH-FORWARD-CI)
  (substring-match-forward-ci string1 0 (string-length string1)
			      string2 0 (string-length string2)))

(define (string-match-backward-ci string1 string2)
  (guarantee-2-strings string1 string2 'STRING-MATCH-BACKWARD-CI)
  (substring-match-backward-ci string1 0 (string-length string1)
			       string2 0 (string-length string2)))

;;;; Basic Operations

(define (make-string length #!optional char)
  (guarantee-index/string length 'MAKE-STRING)
  (if (default-object? char)
      (string-allocate length)
      (let ((result (string-allocate length)))
	(substring-fill! result 0 length char)
	result)))

(define (string-null? string)
  (guarantee-string string 'STRING-NULL?)
  (%string-null? string))

(define-integrable (%string-null? string)
  (fix:= 0 (string-length string)))

(declare (integrate-operator %substring))
(define (%substring string start end)
  (let ((result (string-allocate (fix:- end start))))
    (%substring-move! string start end result 0)
    result))

(define (substring string start end)
  (guarantee-substring string start end 'SUBSTRING)
  (%substring string start end))

(define (string-head string end)
  (guarantee-string string 'STRING-HEAD)
  (guarantee-index/string end 'STRING-HEAD)
  (%substring string 0 end))

(define (string-tail string start)
  (guarantee-string string 'STRING-TAIL)
  (guarantee-index/string start 'STRING-TAIL)
  (%substring string start (string-length string)))

(define (list->string chars)
  ;; This should check that each element of CHARS satisfies CHAR? but at
  ;; worst it will generate strings containing rubbish from the
  ;; addresses of the objects ...
  (let ((result (string-allocate (length chars))))
    (let loop ((index 0) (chars chars))
      (if (pair? chars)
	  ;; LENGTH would have barfed if input is not a proper list:
	  (begin
	    (string-set! result index (car chars))
	    (loop (fix:+ index 1) (cdr chars)))
	  result))))

(define (string . chars)
  (list->string chars))

(define char->string string)

(define (string->list string)
  (guarantee-string string 'STRING->LIST)
  (%substring->list string 0 (string-length string)))

(define (%substring->list string start end)
  (let loop ((index (fix:- end 1)) (list '()))
    (if (fix:>= index start)
	(loop (fix:- index 1)
	      (cons (string-ref string index) list))
	list)))

(define (substring->list string start end)
  (guarantee-substring string start end 'SUBSTRING->LIST)
  (%substring->list string start end))

(define (string-copy string)
  (guarantee-string string 'STRING-COPY)
  (let ((size (string-length string)))
    (let ((result (string-allocate size)))
      (%substring-move! string 0 size result 0)
      result)))

(define (string-move! string1 string2 start2)
  (guarantee-string string1 'STRING-MOVE!)
  (guarantee-string string2 'STRING-MOVE!)
  (guarantee-index/string start2 'STRING-MOVE!)
  (let ((end1 (string-length string1)))
    (if (not (fix:<= (fix:+ start2 end1) (string-length string2)))
	(error:bad-range-argument start2 'STRING-MOVE!))
    (%substring-move! string1 0 end1 string2 start2)))

(define (substring-move! string1 start1 end1 string2 start2)
  (guarantee-substring string1 start1 end1 'SUBSTRING-MOVE!)
  (guarantee-string string2 'SUBSTRING-MOVE!)
  (guarantee-index/string start2 'SUBSTRING-MOVE!)
  (if (not (fix:<= (fix:+ start2 (fix:- end1 start1)) (string-length string2)))
      (error:bad-range-argument start2 'SUBSTRING-MOVE!))
  (%substring-move! string1 start1 end1 string2 start2))

(define (%substring-move! string1 start1 end1 string2 start2)
  ;; Calling the primitive is expensive, so avoid it for small copies.
  (let-syntax
      ((unrolled-move-left
	(lambda (n)
	  `(BEGIN
	     (STRING-SET! STRING2 START2 (STRING-REF STRING1 START1))
	     ,@(let loop ((i 1))
		 (if (< i n)
		     `((STRING-SET! STRING2 (FIX:+ START2 ,i)
				    (STRING-REF STRING1 (FIX:+ START1 ,i)))
		       ,@(loop (+ i 1)))
		     '())))))
       (unrolled-move-right
	(lambda (n)
	  `(BEGIN
	     ,@(let loop ((i 1))
		 (if (< i n)
		     `(,@(loop (+ i 1))
		       (STRING-SET! STRING2 (FIX:+ START2 ,i)
				    (STRING-REF STRING1 (FIX:+ START1 ,i))))
		     '()))
	     (STRING-SET! STRING2 START2 (STRING-REF STRING1 START1))))))
    (let ((n (fix:- end1 start1)))
      (if (or (not (eq? string2 string1)) (fix:< start2 start1))
	  (cond ((fix:> n 4)
		 (if (fix:> n 32)
		     (substring-move-left! string1 start1 end1 string2 start2)
		     (let loop ((i1 start1) (i2 start2))
		       (if (fix:< i1 end1)
			   (begin
			     (string-set! string2 i2 (string-ref string1 i1))
			     (loop (fix:+ i1 1) (fix:+ i2 1)))))))
		((fix:= n 4) (unrolled-move-left 4))
		((fix:= n 3) (unrolled-move-left 3))
		((fix:= n 2) (unrolled-move-left 2))
		((fix:= n 1) (unrolled-move-left 1)))
	  (cond ((fix:> n 4)
		 (if (fix:> n 32)
		     (substring-move-right! string1 start1 end1 string2 start2)
		     (let loop ((i1 end1) (i2 (fix:+ start2 n)))
		       (if (fix:> i1 start1)
			   (let ((i1 (fix:- i1 1))
				 (i2 (fix:- i2 1)))
			     (string-set! string2 i2 (string-ref string1 i1))
			     (loop i1 i2))))))
		((fix:= n 4) (unrolled-move-right 4))
		((fix:= n 3) (unrolled-move-right 3))
		((fix:= n 2) (unrolled-move-right 2))
		((fix:= n 1) (unrolled-move-right 1))))
      (fix:+ start2 n))))

(define (string-append . strings)
  (%string-append strings))

(define (%string-append strings)
  (let ((result
	 (string-allocate
	  (let loop ((strings strings) (length 0))
	    (if (pair? strings)
		(begin
		  (guarantee-string (car strings) 'STRING-APPEND)
		  (loop (cdr strings)
			(fix:+ (string-length (car strings)) length)))
		length)))))
    (let loop ((strings strings) (index 0))
      (if (pair? strings)
	  (let ((size (string-length (car strings))))
	    (%substring-move! (car strings) 0 size result index)
	    (loop (cdr strings) (fix:+ index size)))
	  result))))

(define (decorated-string-append prefix infix suffix strings)
  (guarantee-string prefix 'DECORATED-STRING-APPEND)
  (guarantee-string infix 'DECORATED-STRING-APPEND)
  (guarantee-string suffix 'DECORATED-STRING-APPEND)
  (%decorated-string-append prefix infix suffix strings
			    'DECORATED-STRING-APPEND))

(define (%decorated-string-append prefix infix suffix strings procedure)
  (if (pair? strings)
      (let ((np (string-length prefix))
	    (ni (string-length infix))
	    (ns (string-length suffix)))
	(guarantee-string (car strings) procedure)
	(let ((string
	       (make-string
		(let ((ni* (fix:+ np (fix:+ ni ns))))
		  (do ((strings (cdr strings) (cdr strings))
		       (count (fix:+ np (string-length (car strings)))
			      (fix:+ count
				     (fix:+ ni*
					    (string-length (car strings))))))
		      ((not (pair? strings))
		       (fix:+ count ns))
		    (guarantee-string (car strings) procedure))))))
	  (let ((mp
		 (lambda (index)
		   (%substring-move! prefix 0 np string index)))
		(mi
		 (lambda (index)
		   (%substring-move! infix 0 ni string index)))
		(ms
		 (lambda (index)
		   (%substring-move! suffix 0 ns string index)))
		(mv
		 (lambda (s index)
		   (%substring-move! s 0 (string-length s) string index))))
	    (let loop
		((strings (cdr strings))
		 (index (mv (car strings) (mp 0))))
	      (if (pair? strings)
		  (loop (cdr strings)
			(mv (car strings) (mp (mi (ms index)))))
		  (ms index))))
	  string))
      (make-string 0)))

(define (burst-string string delimiter allow-runs?)
  (guarantee-string string 'BURST-STRING)
  (let ((end (string-length string)))
    (cond ((char? delimiter)
	   (let loop ((start 0) (index 0) (result '()))
	     (cond ((fix:= index end)
		    (reverse!
		     (if (and allow-runs? (fix:= start index))
			 result
			 (cons (substring string start index) result))))
		   ((char=? delimiter (string-ref string index))
		    (loop (fix:+ index 1)
			  (fix:+ index 1)
			  (if (and allow-runs? (fix:= start index))
			      result
			      (cons (substring string start index) result))))
		   (else
		    (loop start (fix:+ index 1) result)))))
	  ((char-set? delimiter)
	   (let loop ((start 0) (index 0) (result '()))
	     (cond ((fix:= index end)
		    (reverse!
		     (if (and allow-runs? (fix:= start index))
			 result
			 (cons (substring string start index) result))))
		   ((char-set-member? delimiter (string-ref string index))
		    (loop (fix:+ index 1)
			  (fix:+ index 1)
			  (if (and allow-runs? (fix:= start index))
			      result
			      (cons (substring string start index) result))))
		   (else
		    (loop start (fix:+ index 1) result)))))
	  (else
	   (error:wrong-type-argument delimiter "character or character set"
				      'BURST-STRING)))))

(define (reverse-string string)
  (guarantee-string string 'REVERSE-STRING)
  (%reverse-substring string 0 (string-length string)))

(define (reverse-substring string start end)
  (guarantee-substring string start end 'REVERSE-SUBSTRING)
  (%reverse-substring string start end))

(define (%reverse-substring string start end)
  (let ((result (make-string (fix:- end start)))
	(k (fix:- end 1)))
    (do ((i start (fix:+ i 1)))
	((fix:= i end))
      (string-set! result (fix:- k i) (string-ref string i)))
    result))

(define (reverse-string! string)
  (guarantee-string string 'REVERSE-STRING!)
  (%reverse-substring! string 0 (string-length string)))

(define (reverse-substring! string start end)
  (guarantee-substring string start end 'REVERSE-SUBSTRING!)
  (%reverse-substring! string start end))

(define (%reverse-substring! string start end)
  (let ((k (fix:+ start (fix:quotient (fix:- end start) 2))))
    (do ((i start (fix:+ i 1))
	 (j (fix:- end 1) (fix:- j 1)))
	((fix:= i k))
      (let ((char (string-ref string j)))
	(string-set! string j (string-ref string i))
	(string-set! string i char)))))

;;;; Case

(define (string-upper-case? string)
  (guarantee-string string 'STRING-UPPER-CASE?)
  (%substring-upper-case? string 0 (string-length string)))

(define (substring-upper-case? string start end)
  (guarantee-substring string start end 'SUBSTRING-UPPER-CASE?)
  (%substring-upper-case? string start end))

(define (%substring-upper-case? string start end)
  (let find-upper ((start start))
    (and (fix:< start end)
	 (let ((char (string-ref string start)))
	   (if (char-upper-case? char)
	       (let search-rest ((start (fix:+ start 1)))
		 (or (fix:= start end)
		     (and (not (char-lower-case? (string-ref string start)))
			  (search-rest (fix:+ start 1)))))
	       (and (not (char-lower-case? char))
		    (find-upper (fix:+ start 1))))))))

(define (string-upcase string)
  (let ((string (string-copy string)))
    (substring-upcase! string 0 (string-length string))
    string))

(define (string-upcase! string)
  (guarantee-string string 'STRING-UPCASE!)
  (substring-upcase! string 0 (string-length string)))

(define (string-lower-case? string)
  (guarantee-string string 'STRING-LOWER-CASE?)
  (%substring-lower-case? string 0 (string-length string)))

(define (substring-lower-case? string start end)
  (guarantee-substring string start end 'SUBSTRING-LOWER-CASE?)
  (%substring-lower-case? string start end))

(define (%substring-lower-case? string start end)
  (let find-lower ((start start))
    (and (fix:< start end)
	 (let ((char (string-ref string start)))
	   (if (char-lower-case? char)
	       (let search-rest ((start (fix:+ start 1)))
		 (or (fix:= start end)
		     (and (not (char-upper-case? (string-ref string start)))
			  (search-rest (fix:+ start 1)))))
	       (and (not (char-upper-case? char))
		    (find-lower (fix:+ start 1))))))))

(define (string-downcase string)
  (let ((string (string-copy string)))
    (substring-downcase! string 0 (string-length string))
    string))

(define (string-downcase! string)
  (guarantee-string string 'STRING-DOWNCASE!)
  (substring-downcase! string 0 (string-length string)))

(define (string-capitalized? string)
  (guarantee-string string 'STRING-CAPITALIZED?)
  (substring-capitalized? string 0 (string-length string)))

(define (substring-capitalized? string start end)
  (guarantee-substring string start end 'SUBSTRING-CAPITALIZED?)
  (%substring-capitalized? string start end))

(define (%substring-capitalized? string start end)
  ;; Testing for capitalization is somewhat more involved than testing
  ;; for upper or lower case.  This algorithm requires that the first
  ;; word be capitalized, and that the subsequent words be either
  ;; lower case or capitalized.  This is a very general definition of
  ;; capitalization; if you need something more specific you should
  ;; call this procedure on the individual words.
  (letrec
      ((find-first-word
	(lambda (start)
	  (and (fix:< start end)
	       (let ((char (string-ref string start)))
		 (if (char-upper-case? char)
		     (scan-word-tail (fix:+ start 1))
		     (and (not (char-lower-case? char))
			  (find-first-word (fix:+ start 1))))))))
       (scan-word-tail
	(lambda (start)
	  (or (fix:= start end)
	      (let ((char (string-ref string start)))
		(if (char-lower-case? char)
		    (scan-word-tail (fix:+ start 1))
		    (and (not (char-upper-case? char))
			 (find-subsequent-word (fix:+ start 1))))))))
       (find-subsequent-word
	(lambda (start)
	  (or (fix:= start end)
	      (let ((char (string-ref string start)))
		(if (char-alphabetic? char)
		    (scan-word-tail (fix:+ start 1))
		    (find-subsequent-word (fix:+ start 1))))))))
    (find-first-word start)))

(define (string-capitalize string)
  (let ((string (string-copy string)))
    (substring-capitalize! string 0 (string-length string))
    string))

(define (string-capitalize! string)
  (guarantee-string string 'STRING-CAPITALIZE!)
  (substring-capitalize! string 0 (string-length string)))

(define (substring-capitalize! string start end)
  ;; This algorithm capitalizes the first word in the substring and
  ;; downcases the subsequent words.  This is arbitrary, but seems
  ;; useful if the substring happens to be a sentence.  Again, if you
  ;; need finer control, parse the words yourself.
  (let ((index
	 (substring-find-next-char-in-set string start end
					  char-set:alphabetic)))
    (if index
	(begin
	  (substring-upcase! string index (fix:+ index 1))
	  (substring-downcase! string (fix:+ index 1) end)))))

;;;; Replace

(define (string-replace string char1 char2)
  (let ((string (string-copy string)))
    (string-replace! string char1 char2)
    string))

(define (substring-replace string start end char1 char2)
  (let ((string (string-copy string)))
    (substring-replace! string start end char1 char2)
    string))

(define (string-replace! string char1 char2)
  (guarantee-string string 'STRING-REPLACE!)
  (substring-replace! string 0 (string-length string) char1 char2))

(define (substring-replace! string start end char1 char2)
  (let loop ((start start))
    (let ((index (substring-find-next-char string start end char1)))
      (if index
	  (begin
	    (string-set! string index char2)
	    (loop (fix:+ index 1)))))))

;;;; Compare

(define (string-compare string1 string2 if= if< if>)
  (guarantee-2-strings string1 string2 'STRING-COMPARE)
  (let ((size1 (string-length string1))
	(size2 (string-length string2)))
    (let ((match (substring-match-forward string1 0 size1 string2 0 size2)))
      ((if (fix:= match size1)
	   (if (fix:= match size2) if= if<)
	   (if (fix:= match size2) if>
	       (if (char<? (string-ref string1 match)
			   (string-ref string2 match))
		   if< if>)))))))

(define (string-prefix? string1 string2)
  (guarantee-2-strings string1 string2 'STRING-PREFIX?)
  (%substring-prefix? string1 0 (string-length string1)
		      string2 0 (string-length string2)))

(define (substring-prefix? string1 start1 end1 string2 start2 end2)
  (guarantee-2-substrings string1 start1 end1
			  string2 start2 end2
			  'SUBSTRING-PREFIX?)
  (%substring-prefix? string1 start1 end1
		      string2 start2 end2))

(define (%substring-prefix? string1 start1 end1 string2 start2 end2)
  (let ((length (fix:- end1 start1)))
    (and (fix:<= length (fix:- end2 start2))
	 (fix:= (substring-match-forward string1 start1 end1
					 string2 start2 end2)
		length))))

(define (string-suffix? string1 string2)
  (guarantee-2-strings string1 string2 'STRING-SUFFIX?)
  (%substring-suffix? string1 0 (string-length string1)
		      string2 0 (string-length string2)))

(define (substring-suffix? string1 start1 end1 string2 start2 end2)
  (guarantee-2-substrings string1 start1 end1
			  string2 start2 end2
			  'SUBSTRING-SUFFIX?)
  (%substring-suffix? string1 start1 end1
		      string2 start2 end2))

(define (%substring-suffix? string1 start1 end1 string2 start2 end2)
  (let ((length (fix:- end1 start1)))
    (and (fix:<= length (fix:- end2 start2))
	 (fix:= (substring-match-backward string1 start1 end1
					  string2 start2 end2)
		length))))

(define (string-compare-ci string1 string2 if= if< if>)
  (guarantee-2-strings string1 string2 'STRING-COMPARE-CI)
  (let ((size1 (string-length string1))
	(size2 (string-length string2)))
    (let ((match (substring-match-forward-ci string1 0 size1 string2 0 size2)))
      ((if (fix:= match size1)
	   (if (fix:= match size2) if= if<)
	   (if (fix:= match size2) if>
	       (if (char-ci<? (string-ref string1 match)
			      (string-ref string2 match))
		   if< if>)))))))

(define (string-prefix-ci? string1 string2)
  (guarantee-2-strings string1 string2 'STRING-PREFIX-CI?)
  (%substring-prefix-ci? string1 0 (string-length string1)
			 string2 0 (string-length string2)))

(define (substring-prefix-ci? string1 start1 end1 string2 start2 end2)
  (guarantee-2-substrings string1 start1 end1
			  string2 start2 end2
			  'SUBSTRING-PREFIX-CI?)
  (%substring-prefix-ci? string1 start1 end1
			 string2 start2 end2))

(define (%substring-prefix-ci? string1 start1 end1 string2 start2 end2)
  (let ((length (fix:- end1 start1)))
    (and (fix:<= length (fix:- end2 start2))
	 (fix:= (substring-match-forward-ci string1 start1 end1
					    string2 start2 end2)
		length))))

(define (string-suffix-ci? string1 string2)
  (guarantee-2-strings string1 string2 'STRING-SUFFIX-CI?)
  (%substring-suffix-ci? string1 0 (string-length string1)
			 string2 0 (string-length string2)))

(define (substring-suffix-ci? string1 start1 end1 string2 start2 end2)
  (guarantee-2-substrings string1 start1 end1
			  string2 start2 end2
			  'SUBSTRING-SUFFIX-CI?)
  (%substring-suffix-ci? string1 start1 end1
			 string2 start2 end2))

(define (%substring-suffix-ci? string1 start1 end1 string2 start2 end2)
  (let ((length (fix:- end1 start1)))
    (and (fix:<= length (fix:- end2 start2))
	 (fix:= (substring-match-backward-ci string1 start1 end1
					     string2 start2 end2)
		length))))

;;;; Trim/Pad

(define (string-trim-left string #!optional char-set)
  (let ((index
	 (string-find-next-char-in-set string
				       (if (default-object? char-set)
					   char-set:not-whitespace
					   char-set)))
	(length (string-length string)))
    (if index
	(%substring string index length)
	"")))

(define (string-trim-right string #!optional char-set)
  (let ((index
	 (string-find-previous-char-in-set string
					   (if (default-object? char-set)
					       char-set:not-whitespace
					       char-set))))
    (if index
	(%substring string 0 (fix:+ index 1))
	"")))

(define (string-trim string #!optional char-set)
  (let ((char-set
	 (if (default-object? char-set) char-set:not-whitespace char-set)))
    (let ((index (string-find-next-char-in-set string char-set)))
      (if index
	  (%substring string
		      index
		      (fix:+ (string-find-previous-char-in-set string char-set)
			     1))
	  ""))))

(define (string-pad-right string n #!optional char)
  (guarantee-string string 'STRING-PAD-RIGHT)
  (guarantee-index/string n 'STRING-PAD-RIGHT)
  (let ((length (string-length string)))
    (if (fix:= length n)
	string
	(let ((result (string-allocate n)))
	  (if (fix:> length n)
	      (%substring-move! string 0 n result 0)
	      (begin
		(%substring-move! string 0 length result 0)
		(let ((char (if (default-object? char) #\space char)))
		  (substring-fill! result length n char))))
	  result))))

(define (string-pad-left string n #!optional char)
  (guarantee-string string 'STRING-PAD-LEFT)
  (guarantee-index/string n 'STRING-PAD-LEFT)
  (let ((length (string-length string)))
    (if (fix:= length n)
	string
	(let ((result (string-allocate n))
	      (i (fix:- n length)))
	  (if (fix:< i 0)
	      (%substring-move! string (fix:- 0 i) length result 0)
	      (begin
		(let ((char (if (default-object? char) #\space char)))
		  (substring-fill! result 0 i char))
		(%substring-move! string 0 length result i)))
	  result))))

;;;; String Search

(define (substring? pattern text)
  (and (string-search-forward pattern text) #t))

(define (string-search-forward pattern text)
  (guarantee-string pattern 'STRING-SEARCH-FORWARD)
  (guarantee-string text 'STRING-SEARCH-FORWARD)
  (%substring-search-forward text 0 (string-length text)
			     pattern 0 (string-length pattern)))

(define (substring-search-forward pattern text tstart tend)
  (guarantee-string pattern 'SUBSTRING-SEARCH-FORWARD)
  (guarantee-substring text tstart tend 'SUBSTRING-SEARCH-FORWARD)
  (%substring-search-forward text tstart tend
			     pattern 0 (string-length pattern)))

(define (string-search-backward pattern text)
  (guarantee-string pattern 'STRING-SEARCH-BACKWARD)
  (guarantee-string text 'STRING-SEARCH-BACKWARD)
  (%substring-search-backward text 0 (string-length text)
			      pattern 0 (string-length pattern)))

(define (substring-search-backward pattern text tstart tend)
  (guarantee-string pattern 'SUBSTRING-SEARCH-BACKWARD)
  (guarantee-substring text tstart tend 'SUBSTRING-SEARCH-BACKWARD)
  (%substring-search-backward text tstart tend
			      pattern 0 (string-length pattern)))

(define (string-search-all pattern text)
  (guarantee-string pattern 'STRING-SEARCH-ALL)
  (guarantee-string text 'STRING-SEARCH-ALL)
  (%bm-substring-search-all text 0 (string-length text)
			    pattern 0 (string-length pattern)))

(define (substring-search-all pattern text tstart tend)
  (guarantee-string pattern 'SUBSTRING-SEARCH-ALL)
  (guarantee-substring text tstart tend 'SUBSTRING-SEARCH-ALL)
  (%bm-substring-search-all text tstart tend
			    pattern 0 (string-length pattern)))

(define (%substring-search-forward text tstart tend pattern pstart pend)
  ;; Returns index of first matched char, or #F.
  (if (fix:< (fix:- pend pstart) 4)
      (%dumb-substring-search-forward text tstart tend pattern pstart pend)
      (%bm-substring-search-forward text tstart tend pattern pstart pend)))

(define (%dumb-substring-search-forward text tstart tend pattern pstart pend)
  (if (fix:= pstart pend)
      0
      (let* ((leader (string-ref pattern pstart))
	     (plen (fix:- pend pstart))
	     (tend (fix:- tend plen)))
	(let loop ((tstart tstart))
	  (let ((tstart
		 (let find-leader ((tstart tstart))
		   (and (fix:<= tstart tend)
			(if (char=? leader (string-ref text tstart))
			    tstart
			    (find-leader (fix:+ tstart 1)))))))
	    (and tstart
		 (if (substring=? text (fix:+ tstart 1) (fix:+ tstart plen)
				  pattern (fix:+ pstart 1) pend)
		     tstart
		     (loop (fix:+ tstart 1)))))))))

(define (%substring-search-backward text tstart tend pattern pstart pend)
  ;; Returns index following last matched char, or #F.
  (if (fix:< (fix:- pend pstart) 4)
      (%dumb-substring-search-backward text tstart tend pattern pstart pend)
      (%bm-substring-search-backward text tstart tend pattern pstart pend)))

(define (%dumb-substring-search-backward text tstart tend pattern pstart pend)
  (if (fix:= pstart pend)
      0
      (let* ((pend-1 (fix:- pend 1))
	     (trailer (string-ref pattern pend-1))
	     (plen (fix:- pend pstart))
	     (tstart+plen (fix:+ tstart plen)))
	(let loop ((tend tend))
	  (let ((tend
		 (let find-trailer ((tend tend))
		   (and (fix:<= tstart+plen tend)
			(if (char=? trailer (string-ref text (fix:- tend 1)))
			    tend
			    (find-trailer (fix:- tend 1)))))))
	    (and tend
		 (if (substring=? text (fix:- tend plen) (fix:- tend 1)
				  pattern pstart pend-1)
		     tend
		     (loop (fix:- tend 1)))))))))

;;;; Boyer-Moore String Search

;;; Cormen, Leiserson, and Rivest, "Introduction to Algorithms",
;;; Chapter 34, "String Matching".

(define (%bm-substring-search-forward text tstart tend pattern pstart pend)
  (let ((m (fix:- pend pstart))
	(pstart-1 (fix:- pstart 1))
	(pend-1 (fix:- pend 1))
	(lambda* (compute-last-occurrence-function pattern pstart pend))
	(gamma
	 (compute-good-suffix-function pattern pstart pend
				       (compute-gamma0 pattern pstart pend))))
    (let ((tend-m (fix:- tend m))
	  (m-1 (fix:- m 1)))
      (let outer ((s tstart))
	(and (fix:<= s tend-m)
	     (let inner ((pj pend-1) (tj (fix:+ s m-1)))
	       (if (fix:= (vector-8b-ref pattern pj) (vector-8b-ref text tj))
		   (if (fix:= pstart pj)
		       s
		       (inner (fix:- pj 1) (fix:- tj 1)))
		   (outer
		    (fix:+ s
			   (fix:max (fix:- (fix:- pj pstart-1)
					   (lambda* (vector-8b-ref text tj)))
				    (gamma (fix:- pj pstart))))))))))))

(define (%bm-substring-search-backward text tstart tend pattern pstart pend)
  (let ((m (fix:- pend pstart))
	(pend-1 (fix:- pend 1))
	(rpattern (reverse-substring pattern pstart pend)))
    (let ((tstart+m (fix:+ tstart m))
	  (lambda* (compute-last-occurrence-function rpattern 0 m))
	  (gamma
	   (compute-good-suffix-function rpattern 0 m
					 (compute-gamma0 rpattern 0 m))))
      (let outer ((s tend))
	(and (fix:>= s tstart+m)
	     (let inner ((pj pstart) (tj (fix:- s m)))
	       (if (fix:= (vector-8b-ref pattern pj) (vector-8b-ref text tj))
		   (if (fix:= pend-1 pj)
		       s
		       (inner (fix:+ pj 1) (fix:+ tj 1)))
		   (outer
		    (fix:- s
			   (fix:max (fix:- (fix:- pend pj)
					   (lambda* (vector-8b-ref text tj)))
				    (gamma (fix:- pend-1 pj))))))))))))

(define (%bm-substring-search-all text tstart tend pattern pstart pend)
  (let ((m (fix:- pend pstart))
	(pstart-1 (fix:- pstart 1))
	(pend-1 (fix:- pend 1))
	(lambda* (compute-last-occurrence-function pattern pstart pend))
	(gamma0 (compute-gamma0 pattern pstart pend)))
    (let ((gamma (compute-good-suffix-function pattern pstart pend gamma0))
	  (tend-m (fix:- tend m))
	  (m-1 (fix:- m 1)))
      (let outer ((s tstart) (occurrences '()))
	(if (fix:<= s tend-m)
	    (let inner ((pj pend-1) (tj (fix:+ s m-1)))
	      (if (fix:= (vector-8b-ref pattern pj) (vector-8b-ref text tj))
		  (if (fix:= pstart pj)
		      (outer (fix:+ s gamma0) (cons s occurrences))
		      (inner (fix:- pj 1) (fix:- tj 1)))
		  (outer (fix:+ s
				(fix:max (fix:- (fix:- pj pstart-1)
						(lambda*
						 (vector-8b-ref text tj)))
					 (gamma (fix:- pj pstart))))
			 occurrences)))
	    (reverse! occurrences))))))

(define (compute-last-occurrence-function pattern pstart pend)
  (let ((lam (make-vector 256 0)))
    (do ((j pstart (fix:+ j 1)))
	((fix:= j pend))
      (vector-set! lam
		   (vector-8b-ref pattern j)
		   (fix:+ (fix:- j pstart) 1)))
    (lambda (symbol)
      (vector-ref lam symbol))))

(define (compute-good-suffix-function pattern pstart pend gamma0)
  (let ((m (fix:- pend pstart)))
    (let ((pi
	   (compute-prefix-function (reverse-substring pattern pstart pend)
				    0 m))
	  (gamma (make-vector m gamma0))
	  (m-1 (fix:- m 1)))
      (do ((l 0 (fix:+ l 1)))
	  ((fix:= l m))
	(let ((j (fix:- m-1 (vector-ref pi l)))
	      (k (fix:- (fix:+ 1 l) (vector-ref pi l))))
	  (if (fix:< k (vector-ref gamma j))
	      (vector-set! gamma j k))))
      (lambda (index)
	(vector-ref gamma index)))))

(define (compute-gamma0 pattern pstart pend)
  (let ((m (fix:- pend pstart)))
    (fix:- m
	   (vector-ref (compute-prefix-function pattern pstart pend)
		       (fix:- m 1)))))

(define (compute-prefix-function pattern pstart pend)
  (let* ((m (fix:- pend pstart))
	 (pi (make-vector m)))
    (vector-set! pi 0 0)
    (let outer ((k 0) (q 1))
      (if (fix:< q m)
	  (let ((k
		 (let ((pq (vector-8b-ref pattern (fix:+ pstart q))))
		   (let inner ((k k))
		     (cond ((fix:= pq (vector-8b-ref pattern (fix:+ pstart k)))
			    (fix:+ k 1))
			   ((fix:= k 0)
			    k)
			   (else
			    (inner (vector-ref pi (fix:- k 1)))))))))
	    (vector-set! pi q k)
	    (outer k (fix:+ q 1)))))
    pi))

;;;; External Strings

(define external-strings)
(define (initialize-package!)
  (set! external-strings
	(make-gc-finalizer (ucode-primitive deallocate-external-string)))
  unspecific)

(define-structure external-string
  (descriptor #f read-only #t)
  (length #f read-only #t))

(define (allocate-external-string n-bytes)
  (without-interrupts
   (lambda ()
     (let ((descriptor ((ucode-primitive allocate-external-string) n-bytes)))
       (let ((xstring (make-external-string descriptor n-bytes)))
	 (add-to-gc-finalizer! external-strings xstring descriptor)
	 xstring)))))

(define (xstring? object)
  (or (string? object)
      (external-string? object)))

(define (xstring-length xstring)
  (cond ((string? xstring)
	 (string-length xstring))
	((external-string? xstring)
	 (external-string-length xstring))
	(else
	 (error:wrong-type-argument xstring "xstring" 'XSTRING-LENGTH))))

(define (xstring-move! xstring1 xstring2 start2)
  (xsubstring-move! xstring1 0 (xstring-length xstring1) xstring2 start2))

(define (xsubstring-move! xstring1 start1 end1 xstring2 start2)
  (let ((deref
	 (lambda (xstring)
	   (if (external-string? xstring)
	       (external-string-descriptor xstring)
	       xstring))))
    (cond ((or (not (eq? xstring2 xstring1)) (< start2 start1))
	   (substring-move-left! (deref xstring1) start1 end1
				 (deref xstring2) start2))
	  ((> start2 start1)
	   (substring-move-right! (deref xstring1) start1 end1
				  (deref xstring2) start2)))))

;;;; Guarantors
;;
;; The guarantors are integrated.  Most are structured as combination of
;; simple tests which the compiler can open-code, followed by a call to a
;; GUARANTEE-.../FAIL version which does the tests again to signal a
;; menaingful message. Structuring the code this way significantly
;; reduces code bloat from large integrated procedures.

(define-integrable (guarantee-string object procedure)
  (if (not (string? object))
      (error:wrong-type-argument object "string" procedure)))

(define-integrable (guarantee-2-strings object1 object2 procedure)
  (if (not (and (string? object1) (string? object2)))
      (guarantee-2-strings/fail object1 object2 procedure)))

(define (guarantee-2-strings/fail object1 object2 procedure)
  (cond ((not (string? object1))
	 (error:wrong-type-argument object1 "string" procedure))
	((not (string? object2))
	 (error:wrong-type-argument object2 "string" procedure))))

(define-integrable (guarantee-index/string object procedure)
  (if (not (index-fixnum? object))
      (guarantee-index/string/fail object procedure)))

(define (guarantee-index/string/fail object procedure)
  (error:wrong-type-argument object "valid string index"
			     procedure))

(define-integrable (guarantee-substring string start end procedure)
  (if (not (and (string? string)
		(index-fixnum? start)
		(index-fixnum? end)
		(fix:<= start end)
		(fix:<= end (string-length string))))
      (guarantee-substring/fail string start end procedure)))

(define-integrable (guarantee-2-substrings string1 start1 end1
					   string2 start2 end2
					   procedure)
  (guarantee-substring string1 start1 end1 procedure)
  (guarantee-substring string2 start2 end2 procedure))

(define (guarantee-substring/fail string start end procedure)
  (guarantee-string string procedure)
  (guarantee-index/string start procedure)
  (guarantee-index/string end procedure)
  (if (not (fix:<= end (string-length string)))
      (error:bad-range-argument end procedure))
  (if (not (fix:<= start end))
      (error:bad-range-argument start procedure)))