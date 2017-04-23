#| -*-Scheme-*-

Copyright (C) 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994,
    1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
    2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016,
    2017 Massachusetts Institute of Technology

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
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301,
USA.

|#

;;;; Unicode strings
;;; package: (runtime ustring)

;;; For simplicity, the implementation uses a 24-bit encoding for non-8-bit
;;; strings.  This is not a good long-term approach and should be revisited once
;;; the runtime system has been converted to this string abstraction.

(declare (usual-integrations))

(define-primitives
  (allocate-nm-vector 2)
  (legacy-string? string? 1)
  (legacy-string-allocate string-allocate 1)
  (primitive-byte-ref 2)
  (primitive-byte-set! 3)
  (primitive-datum-ref 2)
  (primitive-datum-set! 3)
  (primitive-type-ref 2)
  (primitive-type-set! 3))

(define-integrable (ustring? object)
  (object-type? (ucode-type unicode-string) object))

(define (mutable-string? object)
  (%string-mutable? object (lambda () #f)))

(define (string-mutable? string)
  (%string-mutable? string
		    (lambda ()
		      (error:not-a string? string 'string-mutable?))))

(define (%string-mutable? string fail)
  (cond ((legacy-string? string))
	((ustring? string) (%ustring-mutable? string))
	((slice? string) (slice-mutable? string))
	(else (fail))))

(define (immutable-string? object)
  (%string-immutable? object (lambda () #f)))

(define (string-immutable? string)
  (%string-immutable? string
		      (lambda ()
			(error:not-a string? string 'string-immutable?))))

(define (%string-immutable? string fail)
  (cond ((legacy-string? string) #f)
	((ustring? string) (not (%ustring-mutable? string)))
	((slice? string) (not (slice-mutable? string)))
	(else (fail))))

(define (register-ustring-predicates!)
  (register-predicate! string? 'string)
  (register-predicate! mutable-string? 'mutable-string '<= string?)
  (register-predicate! immutable-string? 'immutable-string '<= string?)
  (register-predicate! legacy-string? 'legacy-string
		       '<= string?
		       '<= mutable-string?)
  (register-predicate! ustring? 'unicode-string '<= string?)
  (register-predicate! slice? 'string-slice '<= string?)
  (register-predicate! 8-bit-string? '8-bit-string '<= string?))

;;;; Unicode string layout

(select-on-bytes-per-word
 ;; 32-bit words
 (begin
   (define-integrable byte->object-offset 3)
   (define-integrable byte->object-shift -2)
   (define-integrable byte0-index 8))
 ;; 64-bit words
 (begin
   (define-integrable byte->object-offset 7)
   (define-integrable byte->object-shift -3)
   (define-integrable byte0-index 16)))

(define (%ustring-allocate n-bytes length cp-size)
  (let ((string
	 (allocate-nm-vector (ucode-type unicode-string)
			     (fix:+ 1
				    (fix:lsh (fix:+ n-bytes byte->object-offset)
					     byte->object-shift)))))
    (%set-ustring-length! string length)
    (%set-ustring-flags! string cp-size) ;assumes cp-size in bottom bits
    string))

(define-integrable (ustring-length string)
  (primitive-datum-ref string 1))

(define-integrable (%set-ustring-length! string length)
  (primitive-datum-set! string 1 length))

(define-integrable (%ustring-flags string)
  (primitive-type-ref string 1))

(define-integrable (%set-ustring-flags! string flags)
  (primitive-type-set! string 1 flags))

(define (%ustring-cp-size string)
  (fix:and #x03 (%ustring-flags string)))

(define (%ustring-mutable? string)
  (fix:= 0 (%ustring-cp-size string)))

(define-integrable flag:nfc #x04)
(define-integrable flag:nfd #x08)

(define-integrable (%make-flag-tester flag)
  (lambda (string)
    (not (fix:= 0 (fix:and flag (%ustring-flags string))))))

(define-integrable (%make-flag-setter flag)
  (lambda (string)
    (%set-ustring-flags! string (fix:or flag (%ustring-flags string)))))

(define ustring-in-nfc? (%make-flag-tester flag:nfc))
(define ustring-in-nfc! (%make-flag-setter flag:nfc))
(define ustring-in-nfd? (%make-flag-tester flag:nfd))
(define ustring-in-nfd! (%make-flag-setter flag:nfd))

(define-integrable (ustring1-ref string index)
  (integer->char (cp1-ref string index)))

(define-integrable (ustring1-set! string index char)
  (cp1-set! string index (char->integer char)))

(define-integrable (cp1-ref string index)
  (primitive-byte-ref string (cp1-index index)))

(define-integrable (cp1-set! string index cp)
  (primitive-byte-set! string (cp1-index index) cp))

(define-integrable (cp1-index index)
  (fix:+ byte0-index index))

(define-integrable (ustring2-ref string index)
  (integer->char (cp2-ref string index)))

(define-integrable (ustring2-set! string index char)
  (cp2-set! string index (char->integer char)))

(define (cp2-ref string index)
  (let ((i (cp2-index index)))
    (fix:or (primitive-byte-ref string i)
	    (fix:lsh (primitive-byte-ref string (fix:+ i 1)) 8))))

(define (cp2-set! string index cp)
  (let ((i (cp2-index index)))
    (primitive-byte-set! string i (fix:and cp #xFF))
    (primitive-byte-set! string (fix:+ i 1) (fix:lsh cp -8))))

(define-integrable (cp2-index index)
  (fix:+ byte0-index (fix:* 2 index)))

(define-integrable (ustring3-ref string index)
  (integer->char (cp3-ref string index)))

(define-integrable (ustring3-set! string index char)
  (cp3-set! string index (char->integer char)))

(define (cp3-ref string index)
  (let ((i (cp3-index index)))
    (fix:or (primitive-byte-ref string i)
	    (fix:or (fix:lsh (primitive-byte-ref string (fix:+ i 1)) 8)
		    (fix:lsh (primitive-byte-ref string (fix:+ i 2)) 16)))))

(define (cp3-set! string index cp)
  (let ((i (cp3-index index)))
    (primitive-byte-set! string i (fix:and cp #xFF))
    (primitive-byte-set! string (fix:+ i 1) (fix:and (fix:lsh cp -8) #xFF))
    (primitive-byte-set! string (fix:+ i 2) (fix:lsh cp -16))))

(define-integrable (cp3-index index)
  (fix:+ byte0-index (fix:* 3 index)))

(define (mutable-ustring-allocate n)
  (%ustring-allocate (fix:* 3 n) n 0))

(define (immutable-ustring-allocate n max-cp)
  (cond ((fix:< max-cp #x100)
	 (let ((s (%ustring-allocate (fix:+ n 1) n 1)))
	   (ustring-in-nfc! s)
	   (if (fix:< max-cp #xC0)
	       (ustring-in-nfd! s))
	   (ustring1-set! s n #\null)	;zero-terminate for C
	   s))
	((fix:< max-cp #x10000)
	 (let ((s (%ustring-allocate (fix:* 2 n) n 2)))
	   (if (fix:< max-cp #x300)
	       (ustring-in-nfc! s))
	   s))
	(else
	 (%ustring-allocate (fix:* 3 n) n 3))))

(define (ustring-ref string index)
  (case (ustring-cp-size string)
    ((1) (ustring1-ref string index))
    ((2) (ustring2-ref string index))
    (else (ustring3-ref string index))))

(define (ustring-set! string index char)
  (case (ustring-cp-size string)
    ((1) (ustring1-set! string index char))
    ((2) (ustring2-set! string index char))
    (else (ustring3-set! string index char))))

(define (ustring-cp-size string)
  (if (legacy-string? string)
      1
      (%ustring-cp-size string)))

(define (mutable-ustring? object)
  (or (legacy-string? object)
      (and (ustring? object)
	   (%ustring-mutable? object))))

(define (ustring-mutable? string)
  (or (legacy-string? string)
      (%ustring-mutable? string)))

;;;; String slices

(define (slice? object)
  (and (%record? object)
       (fix:= 4 (%record-length object))
       (eq? %slice-tag (%record-ref object 0))))

(define-integrable (make-slice string start length)
  (%record %slice-tag string start length))

(define-integrable %slice-tag
  '|#[(runtime ustring)slice]|)

(define-integrable (slice-string slice) (%record-ref slice 1))
(define-integrable (slice-start slice) (%record-ref slice 2))
(define-integrable (slice-length slice) (%record-ref slice 3))

(define (slice-end slice)
  (fix:+ (slice-start slice) (slice-length slice)))

(define (slice-mutable? slice)
  (ustring-mutable? (slice-string slice)))

(define (unpack-slice string k)
  (if (slice? string)
      (k (slice-string string) (slice-start string) (slice-end string))
      (k string 0 (ustring-length string))))

(define (translate-slice string start end k)
  (if (slice? string)
      (k (slice-string string)
	 (fix:+ (slice-start string) start)
	 (fix:+ (slice-start string) end))
      (k string start end)))

;;;; Basic operations

(define (string? object)
  (or (legacy-string? object)
      (ustring? object)
      (slice? object)))

(define (make-string k #!optional char)
  (guarantee index-fixnum? k 'make-string)
  (let ((string (mutable-ustring-allocate k)))
    (if (not (default-object? char))
	(do ((i 0 (fix:+ i 1)))
	    ((not (fix:< i k)))
	  (ustring3-set! string i char)))
    string))

(define (string-length string)
  (cond ((or (legacy-string? string) (ustring? string)) (ustring-length string))
	((slice? string) (slice-length string))
	(else (error:not-a string? string 'string-length))))

(define (string-ref string index)
  (guarantee index-fixnum? index 'string-ref)
  (cond ((or (legacy-string? string) (ustring? string))
	 (if (not (fix:< index (ustring-length string)))
	     (error:bad-range-argument index 'string-ref))
	 (ustring-ref string index))
	((slice? string)
	 (if (not (fix:< index (slice-length string)))
	     (error:bad-range-argument index 'string-ref))
	 (ustring-ref (slice-string string)
		      (fix:+ (slice-start string) index)))
	(else
	 (error:not-a string? string 'string-ref))))

(define (string-set! string index char)
  (guarantee mutable-string? string 'string-set!)
  (guarantee index-fixnum? index 'string-set!)
  (guarantee bitless-char? char 'string-set!)
  (if (not (fix:< index (string-length string)))
      (error:bad-range-argument index 'string-set!))
  (if (slice? string)
      (ustring-set! (slice-string string)
		    (fix:+ (slice-start string) index)
		    char)
      (ustring-set! string index char)))

;;;; Slice/Copy

(define (string-slice string #!optional start end)
  (let* ((len (string-length string))
	 (end (fix:end-index end len 'string-slice))
	 (start (fix:start-index start end 'string-slice)))
    (cond ((and (fix:= start 0) (fix:= end len))
	   string)
	  ((slice? string)
	   (make-slice (slice-string string)
		       (fix:+ (slice-start string) start)
		       (fix:- end start)))
	  (else
	   (make-slice string
		       start
		       (fix:- end start))))))

(define (string-copy! to at from #!optional start end)
  (let* ((end (fix:end-index end (string-length from) 'string-copy!))
	 (start (fix:start-index start end 'string-copy!)))
    (guarantee index-fixnum? at 'string-copy!)
    (let ((final-at (fix:+ at (fix:- end start))))
      (if (not (fix:<= final-at (string-length to)))
	  (error:bad-range-argument at 'string-copy!))
      (if (not (string-mutable? to))
	  (error:bad-range-argument to 'string-copy!))
      (receive (to at)
	  (if (slice? to)
	      (values (slice-string to)
		      (fix:+ (slice-start to) at))
	      (values to at))
	(translate-slice from start end
	  (lambda (from start end)
	    (%general-copy! to at from start end))))
      final-at)))

(define (string-copy string #!optional start end)
  (let* ((end (fix:end-index end (string-length string) 'string-copy))
	 (start (fix:start-index start end 'string-copy)))
    (translate-slice string start end
      (lambda (string start end)
	(let* ((n (fix:- end start))
	       (to
		(if (legacy-string? string)
		    (legacy-string-allocate n)
		    (mutable-ustring-allocate n))))
	  (%general-copy! to 0 string start end)
	  to)))))

(define (string-head string end)
  (string-copy string 0 end))

(define (string-tail string start)
  (string-copy string start))

(define (%general-copy! to at from start end)

  (define-integrable (copy! j i o)
    (primitive-byte-set! to (fix:+ j o) (primitive-byte-ref from (fix:+ i o))))

  (define-integrable (zero! j o)
    (primitive-byte-set! to (fix:+ j o) 0))

  (case (ustring-cp-size from)
    ((1)
     (let ((start (cp1-index start))
	   (end (cp1-index end)))
       (case (ustring-cp-size to)
	 ((1)
	  (do ((i start (fix:+ i 1))
	       (j (cp1-index at) (fix:+ j 1)))
	      ((not (fix:< i end)))
	    (copy! j i 0)))
	 ((2)
	  (do ((i start (fix:+ i 1))
	       (j (cp2-index at) (fix:+ j 2)))
	      ((not (fix:< i end)))
	    (copy! j i 0)
	    (zero! j 1)))
	 (else
	  (do ((i start (fix:+ i 1))
	       (j (cp3-index at) (fix:+ j 3)))
	      ((not (fix:< i end)))
	    (copy! j i 0)
	    (zero! j 1)
	    (zero! j 2))))))
    ((2)
     (let ((start (cp2-index start))
	   (end (cp2-index end)))
       (case (ustring-cp-size to)
	 ((1)
	  (do ((i start (fix:+ i 2))
	       (j (cp1-index at) (fix:+ j 1)))
	      ((not (fix:< i end)))
	    (copy! j i 0)))
	 ((2)
	  (do ((i start (fix:+ i 2))
	       (j (cp2-index at) (fix:+ j 2)))
	      ((not (fix:< i end)))
	    (copy! j i 0)
	    (copy! j i 1)))
	 (else
	  (do ((i start (fix:+ i 2))
	       (j (cp3-index at) (fix:+ j 3)))
	      ((not (fix:< i end)))
	    (copy! j i 0)
	    (copy! j i 1)
	    (zero! j 2))))))
    (else
     (let ((start (cp3-index start))
	   (end (cp3-index end)))
       (case (ustring-cp-size to)
	 ((1)
	  (do ((i start (fix:+ i 3))
	       (j (cp1-index at) (fix:+ j 1)))
	      ((not (fix:< i end)))
	    (copy! j i 0)))
	 ((2)
	  (do ((i start (fix:+ i 3))
	       (j (cp2-index at) (fix:+ j 2)))
	      ((not (fix:< i end)))
	    (copy! j i 0)
	    (copy! j i 1)))
	 (else
	  (do ((i start (fix:+ i 3))
	       (j (cp3-index at) (fix:+ j 3)))
	      ((not (fix:< i end)))
	    (copy! j i 0)
	    (copy! j i 1)
	    (copy! j i 2))))))))

(define (%general-max-cp string start end)

  (define-integrable (max-loop cp-ref)
    (do ((i start (fix:+ i 1))
	 (max-cp 0
		 (let ((cp (cp-ref string i)))
		   (if (fix:> cp max-cp)
		       cp
		       max-cp))))
	((not (fix:< i end)) max-cp)))

  (case (ustring-cp-size string)
    ((1) (max-loop cp1-ref))
    ((2) (max-loop cp2-ref))
    (else (max-loop cp3-ref))))

(define (%string->immutable string)
  (unpack-slice string
    (lambda (string* start end)
      (let ((result
	     (immutable-ustring-allocate
	      (fix:- end start)
	      (%general-max-cp string* start end))))
	(%general-copy! result 0 string* start end)
	result))))

;;;; Streaming builder

(define (string-builder #!optional buffer-length)
  (let ((builder
	 (%make-string-builder
	  (if (default-object? buffer-length)
	      16
	      (begin
		(guarantee positive-fixnum? buffer-length 'string-builder)
		buffer-length)))))
    (let ((append-char! (builder 'append-char!))
	  (append-string! (builder 'append-string!))
	  (build (builder 'build)))
      (lambda (#!optional object)
	(cond ((bitless-char? object) (append-char! object))
	      ((string? object) (append-string! object))
	      (else
	       (case object
		 ((#!default immutable) (build build-string:immutable))
		 ((mutable) (build build-string:mutable))
		 ((legacy) (build build-string:legacy))
		 ((empty? count max-cp reset!) ((builder object)))
		 (else (error "Unsupported argument:" object)))))))))

(define (build-string:immutable strings count max-cp)
  (let ((result (immutable-ustring-allocate count max-cp)))
    (fill-result! strings result)
    result))

(define (build-string:mutable strings count max-cp)
  (declare (ignore max-cp))
  (let ((result (mutable-ustring-allocate count)))
    (fill-result! strings result)
    result))

(define (build-string:legacy strings count max-cp)
  (if (not (fix:< max-cp #x100))
      (error "Can't build legacy string:" max-cp))
  (let ((result (legacy-string-allocate count)))
    (fill-result! strings result)
    result))

(define (fill-result! strings result)
  (do ((strings strings (cdr strings))
       (i 0 (fix:+ i (string-length (car strings)))))
      ((not (pair? strings)))
    (unpack-slice (car strings)
      (lambda (string start end)
	(%general-copy! result i string start end)))))

(define (%make-string-builder buffer-length)
  (let ((buffers)
	(buffer)
	(start)
	(index)
	(count)
	(max-cp))

    (define (reset!)
      (set! buffers '())
      (set! buffer (mutable-ustring-allocate buffer-length))
      (set! start 0)
      (set! index 0)
      (set! count 0)
      (set! max-cp 0)
      unspecific)

    (define (get-partial)
      (string-slice buffer start index))

    (define (empty?)
      (and (fix:= start index)
	   (null? buffers)))

    (define (append-char! char)
      (ustring3-set! buffer index char)
      (set! index (fix:+ index 1))
      (set! count (fix:+ count 1))
      (set! max-cp (fix:max max-cp (char->integer char)))
      (if (not (fix:< index buffer-length))
	  (begin
	    (set! buffers (cons (get-partial) buffers))
	    (set! buffer (mutable-ustring-allocate buffer-length))
	    (set! start 0)
	    (set! index 0)
	    unspecific)))

    (define (append-string! string)
      (let ((length (string-length string)))
	(if (fix:> length 0)
	    (begin
	      (if (fix:> index start)
		  (begin
		    (set! buffers (cons (get-partial) buffers))
		    (set! start index)))
	      (set! buffers (cons string buffers))
	      (set! count (fix:+ count length))
	      (set! max-cp
		    (fix:max max-cp
			     (unpack-slice string %general-max-cp)))
	      unspecific))))

    (define (build finish)
      (finish (reverse
	       (if (fix:> index start)
		   (cons (get-partial) buffers)
		   buffers))
	      count
	      max-cp))

    (reset!)
    (lambda (operator)
      (case operator
	((append-char!) append-char!)
	((append-string!) append-string!)
	((build) build)
	((empty?) empty?)
	((count) (lambda () count))
	((max-cp) (lambda () max-cp))
	((reset!) reset!)
	(else (error "Unknown operator:" operator))))))

;;;; Compare

(define (string-compare string1 string2 if= if< if>)
  (%string-compare (string->nfc string1)
		   (string->nfc string2)
		   if= if< if>))

(define (string-compare-ci string1 string2 if= if< if>)
  (%string-compare (string->nfc-cf string1)
		   (string->nfc-cf string2)
		   if= if< if>))

;; Non-Unicode implementation, acceptable to R7RS.
(define-integrable (%string-compare string1 string2 if= if< if>)
  (let ((end1 (string-length string1))
	(end2 (string-length string2)))
    (let ((end (fix:min end1 end2)))
      (let loop ((i 0))
	(if (fix:< i end)
	    (let ((c1 (string-ref string1 i))
		  (c2 (string-ref string2 i)))
	      (cond ((char<? c1 c2) (if<))
		    ((char<? c2 c1) (if>))
		    (else (loop (fix:+ i 1)))))
	    (cond ((fix:< end1 end2) (if<))
		  ((fix:< end2 end1) (if>))
		  (else (if=))))))))

(define-integrable (true) #t)
(define-integrable (false) #f)

(define-integrable (%string-comparison-maker if= if< if>)
  (lambda (string1 string2)
    (%string-compare string1 string2 if= if< if>)))

(define %string=?  (%string-comparison-maker  true false false))
(define %string<?  (%string-comparison-maker false  true false))
(define %string<=? (%string-comparison-maker  true  true false))
(define %string>?  (%string-comparison-maker false false  true))
(define %string>=? (%string-comparison-maker  true false  true))

(define-integrable (string-comparison-maker preprocess compare)
  (lambda (string1 string2 . strings)
    (let loop
	((string1 (preprocess string1))
	 (string2 (preprocess string2))
	 (strings strings))
      (if (pair? strings)
	  (and (compare string1 string2)
	       (loop string2 (preprocess (car strings)) (cdr strings)))
	  (compare string1 string2)))))

(define string=? (string-comparison-maker string->nfc %string=?))
(define string<? (string-comparison-maker string->nfc %string<?))
(define string<=? (string-comparison-maker string->nfc %string<=?))
(define string>? (string-comparison-maker string->nfc %string>?))
(define string>=? (string-comparison-maker string->nfc %string>=?))

(define string-ci=? (string-comparison-maker string->nfc-cf %string=?))
(define string-ci<? (string-comparison-maker string->nfc-cf %string<?))
(define string-ci<=? (string-comparison-maker string->nfc-cf %string<=?))
(define string-ci>? (string-comparison-maker string->nfc-cf %string>?))
(define string-ci>=? (string-comparison-maker string->nfc-cf %string>=?))

;;;; Match

(define (string-match-forward string1 string2)
  (let ((end1 (string-length string1))
	(end2 (string-length string2)))
    (let ((end (fix:min end1 end2)))
      (let loop ((i 0))
	(if (and (fix:< i end)
		 (char=? (string-ref string1 i)
			 (string-ref string2 i)))
	    (loop (fix:+ i 1))
	    i)))))

(define (string-match-forward-ci string1 string2)
  (string-match-forward (string-foldcase string1)
			(string-foldcase string2)))

(define (string-match-backward string1 string2)
  (let ((s1 (fix:- (string-length string1) 1)))
    (let loop ((i s1) (j (fix:- (string-length string2) 1)))
      (if (and (fix:>= i 0)
	       (fix:>= j 0)
	       (char=? (string-ref string1 i)
		       (string-ref string2 j)))
	  (loop (fix:- i 1)
		(fix:- j 1))
	  (fix:- s1 i)))))

(define (string-match-backward-ci string1 string2)
  (string-match-backward (string-foldcase string1)
			 (string-foldcase string2)))

(define (string-prefix? prefix string #!optional start end)
  (%string-prefix? (string->nfc prefix)
		   (string->nfc (string-slice string start end))))

(define (string-prefix-ci? prefix string #!optional start end)
  (%string-prefix? (string->nfc-cf prefix)
		   (string->nfc-cf (string-slice string start end))))

(define (%string-prefix? prefix string)
  (let ((n (string-length prefix)))
    (and (fix:<= n (string-length string))
	 (let loop ((i 0) (j 0))
	   (if (fix:< i n)
	       (and (eq? (string-ref prefix i) (string-ref string j))
		    (loop (fix:+ i 1) (fix:+ j 1)))
	       #t)))))

(define (string-suffix? suffix string #!optional start end)
  (%string-suffix? (string->nfc suffix)
		   (string->nfc (string-slice string start end))))

(define (string-suffix-ci? suffix string #!optional start end)
  (%string-suffix? (string->nfc-cf suffix)
		   (string->nfc-cf (string-slice string start end))))

(define (%string-suffix? suffix string)
  (let ((n (string-length suffix))
	(n* (string-length string)))
    (and (fix:<= n n*)
	 (let loop ((i 0) (j (fix:- n* n)))
	   (if (fix:< i n)
	       (and (eq? (string-ref suffix i) (string-ref string j))
		    (loop (fix:+ i 1) (fix:+ j 1)))
	       #t)))))

;;;; Case

(define (string-downcase string)
  (case-transform ucd-lc-value string))

(define (string-foldcase string)
  (case-transform ucd-cf-value string))

(define (string-upcase string)
  (case-transform ucd-uc-value string))

(define (case-transform transform string)
  (let ((builder (string-builder))
	(end (string-length string)))
    (do ((index 0 (fix:+ index 1)))
	((not (fix:< index end)))
      (builder (transform (string-ref string index))))
    (builder)))

(define (string-titlecase string)
  (let ((builder (string-builder)))
    (find-word-breaks string 0
		      (lambda (end start)
			(maybe-titlecase string start end builder)
			end))
    (builder)))

(define (maybe-titlecase string start end builder)
  (let loop ((index start))
    (if (fix:< index end)
	(let ((char (string-ref string index)))
	  (if (char-cased? char)
	      (begin
		(builder (ucd-tc-value char))
		(do ((index (fix:+ index 1) (fix:+ index 1)))
		    ((not (fix:< index end)))
		  (builder (ucd-lc-value (string-ref string index)))))
	      (begin
		(builder char)
		(loop (fix:+ index 1))))))))

(define (string-lower-case? string)
  (nfd-string-lower-case? (string->nfd string)))

(define (string-upper-case? string)
  (nfd-string-upper-case? (string->nfd string)))

(define (nfd-string-lower-case? nfd)
  (let ((end (string-length nfd)))
    (let loop ((i 0))
      (if (fix:< i end)
	  (and (not (char-changes-when-lower-cased? (string-ref nfd i)))
	       (loop (fix:+ i 1)))
	  #t))))

(define (nfd-string-upper-case? nfd)
  (let ((end (string-length nfd)))
    (let loop ((i 0))
      (if (fix:< i end)
	  (and (not (char-changes-when-upper-cased? (string-ref nfd i)))
	       (loop (fix:+ i 1)))
	  #t))))

(define (nfd-string-case-folded? nfd)
  (let ((end (string-length nfd)))
    (let loop ((i 0))
      (if (fix:< i end)
	  (and (not (char-changes-when-case-folded? (string-ref nfd i)))
	       (loop (fix:+ i 1)))
	  #t))))

(define (string-canonical-foldcase string)
  (string->nfc
   (let ((nfd (string->nfd string)))
     (if (nfd-string-case-folded? nfd)
	 nfd
	 (string-foldcase string)))))

;;;; Normalization

(define (string-in-nfd? string)
  (cond ((or (legacy-string? string) (ustring? string))
	 (if (ustring-mutable? string)
	     (ustring-nfd-qc? string 0 (ustring-length string))
	     (ustring-in-nfd? string)))
	((slice? string)
	 (unpack-slice string ustring-nfd-qc?))
	(else
	 (error:not-a string? string 'string-in-nfd?))))

(define (string-in-nfc? string)
  (cond ((legacy-string? string)
	 #t)
	((ustring? string)
	 (if (ustring-mutable? string)
	     (ustring-nfc-qc? string 0 (ustring-length string))
	     (ustring-in-nfc? string)))
	((slice? string)
	 (unpack-slice string ustring-nfc-qc?))
	(else
	 (error:not-a string? string 'string-in-nfc?))))

(define (ustring-nfc-qc? string start end)
  (case (ustring-cp-size string)
    ((1) #t)
    ((2) (%ustring-nfc-qc? ustring2-ref string start end))
    (else (%ustring-nfc-qc? ustring3-ref string start end))))

(define (ustring-nfd-qc? string start end)
  (case (ustring-cp-size string)
    ((1) (%ustring-nfd-qc? ustring1-ref string start end))
    ((2) (%ustring-nfd-qc? ustring2-ref string start end))
    (else (%ustring-nfd-qc? ustring3-ref string start end))))

(define-integrable (string-nqc-loop cp-limit char-nqc?)
  (lambda (sref string start end)
    (let loop ((i start) (last-ccc 0))
      (if (fix:< i end)
	  (let ((char (sref string i)))
	    (if (fix:< (char->integer char) cp-limit)
		(loop (fix:+ i 1) 0)
		(let ((ccc (ucd-ccc-value char)))
		  (and (or (fix:= ccc 0) (fix:>= ccc last-ccc))
		       (char-nqc? char)
		       (loop (fix:+ i 1) ccc)))))
	  #t))))

(define %ustring-nfc-qc? (string-nqc-loop #x300 char-nfc-quick-check?))
(define %ustring-nfd-qc? (string-nqc-loop #xC0 char-nfd-quick-check?))

(define (string->nfd string)
  (cond ((and (ustring? string)
	      (ustring-in-nfd? string))
	 string)
	((string-in-nfd? string)
	 (let ((result (%string->immutable string)))
	   (ustring-in-nfd! result)
	   result))
	(else
	 (canonical-decomposition&ordering string
	   (lambda (string* n max-cp)
	     (let ((result (immutable-ustring-allocate n max-cp)))
	       (%general-copy! result 0 string* 0 n)
	       (ustring-in-nfd! result)
	       result))))))

(define (string->nfc string)
  (cond ((and (ustring? string)
	      (ustring-in-nfc? string))
	 string)
	((string-in-nfc? string)
	 (let ((result (%string->immutable string)))
	   (ustring-in-nfc! result)
	   result))
	(else
	 (let ((result
		(canonical-composition
		 (if (string-in-nfd? string)
		     string
		     (canonical-decomposition&ordering string
		       (lambda (string* n max-cp)
			 (declare (ignore n max-cp))
			 string*))))))
	   (ustring-in-nfc! result)
	   result))))

(define (string->nfc-cf string)
  (string->nfc (string-foldcase string)))

(define (canonical-decomposition&ordering string k)
  (let ((end (string-length string))
	(builder (string-builder)))
    (do ((i 0 (fix:+ i 1)))
	((not (fix:< i end)))
      (let loop ((char (string-ref string i)))
	(if (jamo-precomposed? char)
	    (jamo-decompose char builder)
	    (let ((dm (ucd-canonical-dm-value char)))
	      (cond ((eqv? dm char)
		     (builder char))
		    ;; Canonical decomposition always length 1 or 2.
		    ;; First char might need recursion, second doesn't:
		    ((char? dm)
		     (loop dm))
		    (else
		     (loop (string-ref dm 0))
		     (builder (string-ref dm 1))))))))
    (let* ((string (builder 'mutable))
	   (end (ustring-length string)))

      (define (scan-for-non-starter i)
	(if (fix:< i end)
	    (let ((ccc (ucd-ccc-value (ustring3-ref string i))))
	      (if (fix:= 0 ccc)
		  (scan-for-non-starter (fix:+ i 1))
		  (scan-for-non-starter-pair (list ccc) (fix:+ i 1))))))

      (define (scan-for-non-starter-pair previous i)
	(if (fix:< i end)
	    (let ((ccc (ucd-ccc-value (ustring3-ref string i))))
	      (if (fix:= 0 ccc)
		  (scan-for-non-starter (fix:+ i 1))
		  (scan-for-non-starter-pair (maybe-twiddle previous i ccc)
					     (fix:+ i 1))))))

      (define (maybe-twiddle previous i ccc)
	(if (and (pair? previous)
		 (fix:< ccc (car previous)))
	    (begin
	      (let ((char (ustring3-ref string (fix:- i 1))))
		(ustring3-set! string (fix:- i 1) (ustring3-ref string i))
		(ustring3-set! string i char))
	      (cons (car previous)
		    (maybe-twiddle (cdr previous) (fix:- i 1) ccc)))
	    (cons ccc previous)))

      (scan-for-non-starter 0)
      (k string end (builder 'max-cp)))))

(define (canonical-composition string)
  (let ((end (string-length string))
	(builder (string-builder))
	(sk ucd-canonical-cm-second-keys)
	(sv ucd-canonical-cm-second-values))

    (define (scan-for-first-char i)
      (if (fix:< i end)
	  (let ((fc (string-ref string i)))
	    (if (and (jamo-leading? fc)
		     (fix:< (fix:+ i 1) end)
		     (jamo-vowel? (string-ref string (fix:+ i 1))))
		(if (and (fix:< (fix:+ i 2) end)
			 (jamo-trailing? (string-ref string (fix:+ i 2))))
		    (begin
		      (builder
		       (jamo-compose fc
				     (string-ref string (fix:+ i 1))
				     (string-ref string (fix:+ i 2))))
		      (scan-for-first-char (fix:+ i 3)))
		    (begin
		      (builder
		       (jamo-compose fc
				     (string-ref string (fix:+ i 1))
				     #f))
		      (scan-for-first-char (fix:+ i 2))))
		(test-first-char (fix:+ i 1) fc)))))

    (define (test-first-char i+1 fc)
      (let ((fc-index (and (fix:< i+1 end) (ucd-canonical-cm-value fc))))
	(if fc-index
	    (let ((combiners (get-combiners i+1)))
	      (if (pair? combiners)
		  (let ((j (fix:+ i+1 (length combiners))))
		    (scan-combiners fc fc-index combiners)
		    (scan-for-first-char j))
		  (let ((fc* (match-second fc-index (string-ref string i+1))))
		    (if fc*
			(test-first-char (fix:+ i+1 1) fc*)
			(begin
			  (builder fc)
			  (scan-for-first-char i+1))))))
	    (begin
	      (builder fc)
	      (scan-for-first-char i+1)))))

    (define (get-combiners j)
      (if (fix:< j end)
	  (let* ((char (string-ref string j))
		 (ccc (ucd-ccc-value char)))
	    (if (fix:= 0 ccc)
		'()
		(cons (cons char ccc) (get-combiners (fix:+ j 1)))))
	  '()))

    (define (scan-combiners fc fc-index combiners)
      (let loop ((cs combiners) (last-ccc 0))
	(if (pair? cs)
	    (let* ((c (car cs))
		   (fc*
		    (and (fix:> (cdr c) last-ccc)
			 (match-second fc-index (car c)))))
	      (if fc*
		  (let ((fc-index* (ucd-canonical-cm-value fc*))
			(combiners* (remove-combiner! c combiners)))
		    (if fc-index*
			(scan-combiners fc* fc-index* combiners*)
			(done-matching fc* combiners*)))
		  (loop (cdr cs) (cdr c))))
	    (done-matching fc combiners))))

    (define (remove-combiner! combiner combiners)
      (if (eq? combiner (car combiners))
	  (cdr combiners)
	  (begin
	    (let loop ((this (cdr combiners)) (prev combiners))
	      (if (eq? combiner (car this))
		  (set-cdr! prev (cdr this))
		  (loop (cdr this) this)))
	    combiners)))

    (define (done-matching fc combiners)
      (builder fc)
      (for-each (lambda (combiner) (builder (car combiner)))
		combiners))

    (define (match-second fc-index sc)
      (let ((keys (vector-ref sk fc-index)))
	(let loop ((start 0) (end (string-length keys)))
	  (and (fix:< start end)
	       (let ((m (fix:quotient (fix:+ start end) 2)))
		 (let ((key (string-ref keys m)))
		   (cond ((char<? sc key) (loop start m))
			 ((char<? key sc) (loop (fix:+ m 1) end))
			 (else (string-ref (vector-ref sv fc-index) m)))))))))

    (scan-for-first-char 0)
    (builder)))

(define-integrable jamo-leading-start #x1100)
(define-integrable jamo-leading-end   #x1113)
(define-integrable jamo-vowel-start #x1161)
(define-integrable jamo-vowel-end   #x1176)
(define-integrable jamo-trailing-start #x11A8)
(define-integrable jamo-trailing-end   #x11C3)
(define-integrable jamo-precomposed-start #xAC00)
(define-integrable jamo-precomposed-end   #xD7A4)

(define-integrable jamo-vowel-size
  (fix:- jamo-vowel-end jamo-vowel-start))

(define-integrable jamo-trailing-size
  (fix:- jamo-trailing-end jamo-trailing-start))

(define-integrable jamo-tbase (fix:- jamo-trailing-start 1))

;;; These can be integrable after 9.3 is released.
;;; Otherwise they trip a bug in the 9.2 compiler.
(define jamo-tcount (fix:+ jamo-trailing-size 1))
(define jamo-ncount (fix:* jamo-vowel-size jamo-tcount))

(define (jamo-leading? char)
  (and (fix:>= (char->integer char) jamo-leading-start)
       (fix:< (char->integer char) jamo-leading-end)))

(define (jamo-vowel? char)
  (and (fix:>= (char->integer char) jamo-vowel-start)
       (fix:< (char->integer char) jamo-vowel-end)))

(define (jamo-trailing? char)
  (and (fix:>= (char->integer char) jamo-trailing-start)
       (fix:< (char->integer char) jamo-trailing-end)))

(define (jamo-precomposed? char)
  (and (fix:>= (char->integer char) jamo-precomposed-start)
       (fix:< (char->integer char) jamo-precomposed-end)))

(define (jamo-decompose precomposed builder)
  (let ((pi (fix:- (char->integer precomposed) jamo-precomposed-start)))
    (builder
     (integer->char (fix:+ jamo-leading-start (fix:quotient pi jamo-ncount))))
    (builder
     (integer->char
      (fix:+ jamo-vowel-start
	     (fix:quotient (fix:remainder pi jamo-ncount) jamo-tcount))))
    (let ((ti (fix:remainder pi jamo-tcount)))
      (if (fix:> ti 0)
	  (builder (integer->char (fix:+ jamo-tbase ti)))))))

(define (jamo-compose leading vowel trailing)
  (integer->char
   (fix:+ jamo-precomposed-start
	  (fix:+ (fix:+ (fix:* (fix:- (char->integer leading)
				      jamo-leading-start)
			       jamo-ncount)
			(fix:* (fix:- (char->integer vowel)
				      jamo-vowel-start)
			       jamo-tcount))
		 (if trailing
		     (fix:- (char->integer trailing) jamo-tbase)
		     0)))))

;;;; Grapheme clusters

(define (grapheme-cluster-length string)
  (let ((breaks
	 (find-grapheme-cluster-breaks string
				       0
				       (lambda (i count)
					 (declare (ignore i))
					 (fix:+ count 1)))))
    (if (fix:> breaks 0)
	(fix:- breaks 1)
	breaks)))

(define (grapheme-cluster-slice string start end)
  ;; START and END refer to the cluster breaks, they must be <= the number of
  ;; clusters in STRING.
  (guarantee index-fixnum? start 'grapheme-cluster-slice)
  (guarantee index-fixnum? end 'grapheme-cluster-slice)
  (if (not (fix:<= start end))
      (error:bad-range-argument start 'grapheme-cluster-slice))
  (let ((start-index #f)
	(end-index #f))
    (find-grapheme-cluster-breaks string
				  0
				  (lambda (index count)
				    (if (fix:= count start)
					(set! start-index index))
				    (if (fix:= count end)
					(set! end-index index))
				    (fix:+ count 1)))
    (if (not start-index)
	(error:bad-range-argument start 'grapheme-cluster-slice))
    (if (not end-index)
	(error:bad-range-argument end 'grapheme-cluster-slice))
    (string-slice string start-index end-index)))

(define (grapheme-cluster-breaks string)
  (reverse! (find-grapheme-cluster-breaks string '() cons)))

(define (find-grapheme-cluster-breaks string initial-ctx break)
  (let ((n (string-length string)))

    (define (get-gcb i)
      (ucd-gcb-value (string-ref string i)))

    (define (transition gcb i ctx)
      (let ((i* (fix:+ i 1)))
	(if (fix:< i* n)
	    ((vector-ref gcb-states gcb)
	     (get-gcb i*)
	     (lambda (gcb* break?)
	       (transition gcb* i* (if break? (break i* ctx) ctx))))
	    (break n ctx))))

    (if (fix:> n 0)
	(transition (get-gcb 0) 0 (break 0 initial-ctx))
	initial-ctx)))

(define gcb-names
  '#(control
     carriage-return
     emoji-base
     emoji-base-gaz
     emoji-modifier
     extend
     glue-after-zwj
     hst=l
     linefeed
     hst=lv
     hst=lvt
     prepend
     regional-indicator
     spacing-mark
     hst=t
     hst=v
     other
     zwj))

(define (name->code namev name)
  (let ((end (vector-length namev)))
    (let loop ((code 0))
      (if (not (fix:< code end))
	  (error "Unknown name:" name))
      (if (eq? (vector-ref namev code) name)
	  code
	  (loop (fix:+ code 1))))))

(define (make-!selector namev names)
  (let loop
      ((names names)
       (mask (fix:- (fix:lsh 1 (vector-length namev)) 1)))
    (if (pair? names)
	(loop (cdr names)
	      (fix:andc mask (fix:lsh 1 (name->code namev (car names)))))
	(lambda (code)
	  (not (fix:= 0 (fix:and mask (fix:lsh 1 code))))))))

(define (make-selector namev names)
  (let loop
      ((names names)
       (mask 0))
    (if (pair? names)
	(loop (cdr names)
	      (fix:or mask (fix:lsh 1 (name->code namev (car names)))))
	(lambda (code)
	  (not (fix:= 0 (fix:and mask (fix:lsh 1 code))))))))

(define gcb-states
  (let ((simple-state
	 (lambda (break?)
	   (lambda (gcb k)
	     (k gcb (break? gcb)))))
	(gcb-code
	 (lambda (name)
	   (name->code gcb-names name)))
	(make-no-breaks
	 (lambda (names)
	   (make-!selector gcb-names names)))
	(make-breaks
	 (lambda (names)
	   (make-selector gcb-names names))))
    (let ((state:control (simple-state (make-no-breaks '())))
	  (state:emoji-base
	   (let ((gcb:extend (gcb-code 'extend))
		 (gcb:emoji-base (gcb-code 'emoji-base))
		 (break?
		  (make-no-breaks '(emoji-modifier extend spacing-mark zwj))))
	     (lambda (gcb k)
	       (if (fix:= gcb gcb:extend)
		   (k gcb:emoji-base #f)
		   (k gcb (break? gcb))))))
	  (state:extend
	   (simple-state (make-no-breaks '(extend spacing-mark zwj))))
	  (state:hst=v
	   (simple-state
	    (make-no-breaks '(hst=t hst=v extend spacing-mark zwj))))
	  (state:hst=t
	   (simple-state (make-no-breaks '(hst=t extend spacing-mark zwj)))))
      (vector state:control
	      (simple-state (make-no-breaks '(linefeed)))
	      state:emoji-base
	      state:emoji-base
	      state:extend
	      state:extend
	      state:extend
	      (simple-state
	       (make-no-breaks
		'(hst=l hst=lv hst=lvt hst=v extend spacing-mark zwj)))
	      state:control
	      state:hst=v
	      state:hst=t
	      (simple-state (make-breaks '(control carriage-return linefeed)))
	      (let ((gcb:regional-indicator (gcb-code 'regional-indicator))
		    (gcb:extend (gcb-code 'extend))
		    (break? (make-no-breaks '(extend spacing-mark zwj))))
		(lambda (gcb k)
		  (let ((gcb
			 (if (fix:= gcb gcb:regional-indicator)
			     gcb:extend
			     gcb)))
		    (k gcb (break? gcb)))))
	      state:extend
	      state:hst=t
	      state:hst=v
	      state:extend
	      (simple-state
	       (make-no-breaks
		'(emoji-base-gaz glue-after-zwj extend spacing-mark zwj)))))))

;;;; Word breaks

(define (string-word-breaks string)
  (reverse! (find-word-breaks string '() cons)))

(define (find-word-breaks string initial-ctx break)
  (let ((n (string-length string)))

    (define (get-wb i)
      (ucd-wb-value (string-ref string i)))

    (define (t1 wb0 i0 ctx)
      (if (select:breaker wb0)
	  (t1-breaker wb0 i0 ctx)
	  (t1-!breaker wb0 i0 ctx)))

    (define (t1-breaker wb0 i0 ctx)
      (let ((i1 (fix:+ i0 1)))
	(if (fix:< i1 n)
	    (let ((wb1 (get-wb i1)))
	      ((vector-ref wb-states wb0)
	       wb1
	       #f
	       (lambda (wb1* break?)
		 (t1 wb1* i1 (if break? (break i1 ctx) ctx)))
	       k2-none))
	    ctx)))

    (define (t1-!breaker wb0 i0 ctx)
      (let ((i1 (fix:+ i0 1)))
	(if (fix:< i1 n)
	    (let ((wb1 (get-wb i1)))
	      (cond ((select:extender wb1)
		     (t1-!breaker (if (select:zwj wb0) wb1 wb0) i1 ctx))
		    ((select:breaker wb1)
		     (t1-breaker wb1 i1 (break i1 ctx)))
		    (else
		     (t2 wb0 wb1 i1 ctx))))
	    ctx)))

    (define (t2 wb0 wb1 i1 ctx)
      (let find-i2 ((i2 (fix:+ i1 1)))
	(if (fix:< i2 n)
	    (let ((wb2 (get-wb i2)))
	      (if (select:extender wb2)
		  (find-i2 (fix:+ i2 1))
		  ((vector-ref wb-states wb0)
		   wb1
		   wb2
		   (lambda (wb1* break?)
		     (t2 wb1* wb2 i2 (if break? (break i1 ctx) ctx)))
		   (lambda ()
		     (t1 wb2 i2 ctx)))))
	    ((vector-ref wb-states wb0)
	     wb1
	     #f
	     (lambda (wb1* break?)
	       (declare (ignore wb1*))
	       (if break? (break i1 ctx) ctx))
	     k2-none))))

    (define (k2-none)
      (error "Should never be called"))

    (if (fix:< 0 n)
	(break n (t1 (get-wb 0) 0 (break 0 initial-ctx)))
	initial-ctx)))

(define wb-names
  '#(carriage-return
     double-quote
     emoji-base
     emoji-base-gaz
     emoji-modifier
     extend-num-let
     extend
     format
     glue-after-zwj
     hebrew-letter
     katakana
     letter
     linefeed
     mid-num-let
     mid-letter
     mid-number
     newline
     numeric
     regional-indicator
     single-quote
     other
     zwj))

(define select:breaker
  (make-selector wb-names '(carriage-return linefeed newline)))

(define select:extender
  (make-selector wb-names '(extend format zwj)))

(define select:zwj
  (make-selector wb-names '(zwj)))

(define wb-states
  (make-vector (vector-length wb-names)
	       (lambda (wb1 wb2 k1 k2)
		 (declare (ignore wb2 k2))
		 (k1 wb1 #t))))

(let ((select:mb/ml/sq
       (make-selector wb-names '(mid-num-let mid-letter single-quote)))
      (select:mb/mn/sq
       (make-selector wb-names '(mid-num-let mid-number single-quote)))
      (select:hl/le (make-selector wb-names '(hebrew-letter letter)))
      (select:hl (make-selector wb-names '(hebrew-letter)))
      (select:numeric (make-selector wb-names '(numeric)))
      (select:dq (make-selector wb-names '(double-quote)))
      (select:ri (make-selector wb-names '(regional-indicator)))
      (break?:hl
       (make-!selector wb-names
		       '(extend-num-let hebrew-letter letter numeric
					single-quote)))
      (break?:alphanum
       (make-!selector wb-names
		       '(extend-num-let hebrew-letter letter numeric)))
      (wb:extend (name->code wb-names 'extend)))

  (define (define-state name state)
    (vector-set! wb-states (name->code wb-names name) state))

  (for-each
   (lambda (n.b)
     (define-state (car n.b)
       (let ((break? (make-!selector wb-names (cdr n.b))))
	 (lambda (wb1 wb2 k1 k2)
	   (declare (ignore wb2 k2))
	   (k1 wb1 (break? wb1))))))
   '((carriage-return linefeed)
     (emoji-base emoji-modifier)
     (emoji-base-gaz emoji-modifier)
     (katakana extend-num-let katakana)
     (zwj emoji-base-gaz glue-after-zwj)
     (extend-num-let extend-num-let hebrew-letter katakana letter numeric)))

  (define-state 'hebrew-letter
    (lambda (wb1 wb2 k1 k2)
      (if (and wb2
	       (or (and (select:mb/ml/sq wb1)
			(select:hl/le wb2))
		   (and (select:dq wb1)
			(select:hl wb2))))
	  (k2)
	  (k1 wb1 (break?:hl wb1)))))

  (define-state 'letter
    (lambda (wb1 wb2 k1 k2)
      (if (and wb2
	       (select:mb/ml/sq wb1)
	       (select:hl/le wb2))
	  (k2)
	  (k1 wb1 (break?:alphanum wb1)))))

  (define-state 'numeric
    (lambda (wb1 wb2 k1 k2)
      (if (and wb2
	       (select:mb/mn/sq wb1)
	       (select:numeric wb2))
	  (k2)
	  (k1 wb1 (break?:alphanum wb1)))))

  (define-state 'regional-indicator
    (let ()
      (lambda (wb1 wb2 k1 k2)
	(declare (ignore wb2 k2))
	(if (select:ri wb1)
	    (k1 wb:extend #f)
	    (k1 wb1 #t))))))

;;;; Search

(define-integrable (string-matcher caller matcher)
  (lambda (pattern text #!optional start end)
    (let ((pend (string-length pattern)))
      (if (fix:= 0 pend)
	  (error:bad-range-argument pend caller))
      (let* ((tend (fix:end-index end (string-length text) caller))
	     (tstart (fix:start-index start end caller)))
	(matcher pattern pend text tstart (fix:- tend pend))))))

(define string-search-forward
  (string-matcher 'string-search-forward
		  %dumb-string-search-forward))

(define string-search-backward
  (string-matcher 'string-search-backward
		  %dumb-string-search-backward))

(define string-search-all
  (string-matcher 'string-search-all
		  %dumb-string-search-all))

(define (substring? pattern text)
  (and (or (fix:= 0 (string-length pattern))
	   (string-search-forward pattern text))
       #t))

(define (%dumb-string-search-forward pattern pend text tstart tlast)
  (let find-match ((tindex tstart))
    (and (fix:<= tindex tlast)
	 (let match ((pi 0) (ti tindex))
	   (if (fix:< pi pend)
	       (if (char=? (string-ref pattern pi)
			   (string-ref text ti))
		   (match (fix:+ pi 1) (fix:+ ti 1))
		   (find-match (fix:+ tindex 1)))
	       tindex)))))

(define (%dumb-string-search-backward pattern pend text tstart tlast)
  (let find-match ((tindex tlast))
    (and (fix:>= tindex tstart)
	 (let match ((pi 0) (ti tindex))
	   (if (fix:< pi pend)
	       (if (char=? (string-ref pattern pi)
			   (string-ref text ti))
		   (match (fix:+ pi 1) (fix:+ ti 1))
		   (find-match (fix:- tindex 1)))
	       ti)))))

(define (%dumb-string-search-all pattern pend text tstart tlast)
  (let find-match ((tindex tlast) (matches '()))
    (if (fix:>= tindex tstart)
	(find-match (fix:- tindex 1)
		    (let match ((pi 0) (ti tindex))
		      (if (fix:< pi pend)
			  (if (char=? (string-ref pattern pi)
				      (string-ref text ti))
			      (match (fix:+ pi 1) (fix:+ ti 1))
			      matches)
			  (cons tindex matches))))
	matches)))

;;;; Sequence converters

(define (list->string chars)
  (let ((string
	 (immutable-ustring-allocate
	  (length chars)
	  (fold-left (lambda (max-cp char)
		       (fix:max max-cp (char->integer char)))
		     0
		     chars))))
    (do ((chars chars (cdr chars))
	 (i 0 (fix:+ i 1)))
	((not (pair? chars)))
      (ustring-set! string i (car chars)))
    string))

(define (string->list string #!optional start end)
  (let* ((end (fix:end-index end (string-length string) 'string->list))
	 (start (fix:start-index start end 'string->list)))
    (translate-slice string start end
      (lambda (string start end)

	(define-integrable (%string->list sref)
	  (do ((i (fix:- end 1) (fix:- i 1))
	       (chars '() (cons (sref string i) chars)))
	      ((not (fix:>= i start)) chars)))

	(case (ustring-cp-size string)
	  ((1) (%string->list ustring1-ref))
	  ((2) (%string->list ustring2-ref))
	  (else (%string->list ustring3-ref)))))))

(define (vector->string vector #!optional start end)
  (let* ((end (fix:end-index end (vector-length vector) 'vector->string))
	 (start (fix:start-index start end 'vector->string))
	 (to
	  (if (do ((i start (fix:+ i 1))
		   (8-bit? #t (and 8-bit? (char-8-bit? (vector-ref vector i)))))
		  ((not (fix:< i end)) 8-bit?))
	      (legacy-string-allocate (fix:- end start))
	      (mutable-ustring-allocate (fix:- end start)))))
    (copy-loop ustring-set! to 0
	       vector-ref vector start end)
    to))

(define (string->vector string #!optional start end)
  (let* ((end (fix:end-index end (string-length string) 'string->vector))
	 (start (fix:start-index start end 'string->vector)))
    (translate-slice string start end
      (lambda (string start end)
	(let ((to (make-vector (fix:- end start))))
	  (copy-loop vector-set! to 0
		     ustring-ref string start end)
	  to)))))

;;;; Append and general constructor

(define (string-append . strings)
  (string-append* strings))

(define (string-append* strings)
  (let ((builder (string-builder)))
    (for-each (lambda (string)
		(guarantee string? string 'string-append)
		(builder string))
	      strings)
    (builder)))

(define (string . objects)
  (string* objects))

(define (string* objects)
  (let ((builder (string-builder)))
    (for-each (lambda (object)
		(if object
		    (builder
		     (cond ((bitless-char? object) object)
			   ((string? object) object)
			   ((symbol? object) (symbol->string object))
			   ((pathname? object) (->namestring object))
			   ((number? object) (number->string object))
			   ((uri? object) (uri->string object))
			   (else (error "Unknown string component:" object))))))
	      objects)
    (builder)))

;;;; Mapping

(define (mapper-values proc string strings)
  (cond ((null? strings)
	 (values (string-length string)
		 (lambda (i)
		   (proc (string-ref string i)))))
	((null? (cdr strings))
	 (let* ((string2 (car strings))
		(n (fix:min (string-length string)
			    (string-length string2))))
	   (values n
		   (lambda (i)
		     (proc (string-ref string i)
			   (string-ref string2 i))))))
	(else
	 (let ((n (min-length string-length string strings)))
	   (values n
		   (lambda (i)
		     (apply proc
			    (string-ref string i)
			    (map (lambda (string)
				   (string-ref string i))
				 strings))))))))

(define (min-length string-length string strings)
  (do ((strings strings (cdr strings))
       (n (string-length string)
	  (fix:min n (string-length (car strings)))))
      ((null? strings) n)))

(define (string-for-each proc string . strings)
  (receive (n proc) (mapper-values proc string strings)
    (do ((i 0 (fix:+ i 1)))
	((not (fix:< i n)))
      (proc i))))

(define (string-map proc string . strings)
  (receive (n proc) (mapper-values proc string strings)
    (let ((builder (string-builder)))
      (do ((i 0 (fix:+ i 1)))
	  ((not (fix:< i n)))
	(builder (proc i)))
      (builder))))

(define (string-count proc string . strings)
  (receive (n proc) (mapper-values proc string strings)
    (let loop ((i 0) (count 0))
      (if (fix:< i n)
	  (loop (fix:+ i 1)
		(if (proc i)
		    (fix:+ count 1)
		    count))
	  count))))

(define (string-any proc string . strings)
  (receive (n proc) (mapper-values proc string strings)
    (let loop ((i 0))
      (and (fix:< i n)
	   (if (proc i)
	       #t
	       (loop (fix:+ i 1)))))))

(define (string-every proc string . strings)
  (receive (n proc) (mapper-values proc string strings)
    (let loop ((i 0))
      (if (fix:< i n)
	  (and (proc i)
	       (loop (fix:+ i 1)))
	  #t))))

(define (string-find-first-index proc string . strings)
  (receive (n proc) (mapper-values proc string strings)
    (let loop ((i 0))
      (and (fix:< i n)
	   (if (proc i)
	       i
	       (loop (fix:+ i 1)))))))

(define (string-find-last-index proc string . strings)
  (receive (n proc) (mapper-values proc string strings)
    (let loop ((i (fix:- n 1)))
      (and (fix:>= i 0)
	   (if (proc i)
	       i
	       (loop (fix:- i 1)))))))

;;;; Joiner

(define (string-joiner . options)
  (let ((joiner (%string-joiner options 'string-joiner)))
    (lambda strings
      (joiner strings))))

(define (string-joiner* . options)
  (%string-joiner options 'string-joiner*))

(define (%string-joiner options caller)
  (receive (infix prefix suffix) (string-joiner-options options caller)
    (let ((infix (string-append suffix infix prefix)))
      (lambda (strings)
	(if (pair? strings)
	    (let ((builder (string-builder)))
	      (builder prefix)
	      (builder (car strings))
	      (for-each (lambda (string)
			  (builder infix)
			  (builder string))
			(cdr strings))
	      (builder suffix)
	      (builder))
	    "")))))

(define-deferred string-joiner-options
  (keyword-option-parser
   (list (list 'infix string? "")
	 (list 'prefix string? "")
	 (list 'suffix string? ""))))

;;;; Splitter

(define (string-splitter . options)
  (receive (delimiter allow-runs? copy?)
      (string-splitter-options options 'string-splitter)
    (let ((predicate (splitter-delimiter->predicate delimiter))
	  (get-part (if copy? string-copy string-slice)))

      (lambda (string #!optional start end)
	(let* ((end (fix:end-index end (string-length string) 'string-splitter))
	       (start (fix:start-index start end 'string-splitter)))

	  (define (find-start start)
	    (if allow-runs?
		(let loop ((index start))
		  (if (fix:< index end)
		      (if (predicate (string-ref string index))
			  (loop (fix:+ index 1))
			  (find-end index (fix:+ index 1)))
		      '()))
		(find-end start start)))

	  (define (find-end start index)
	    (let loop ((index index))
	      (if (fix:< index end)
		  (if (predicate (string-ref string index))
		      (cons (get-part string start index)
			    (find-start (fix:+ index 1)))
		      (loop (fix:+ index 1)))
		  (list (get-part string start end)))))

	  (find-start start))))))

(define-deferred string-splitter-options
  (keyword-option-parser
   (list (list 'delimiter splitter-delimiter? char-whitespace?)
	 (list 'allow-runs? boolean? #t)
	 (list 'copy? boolean? #f))))

(define (splitter-delimiter->predicate delimiter)
  (cond ((char? delimiter) (char=-predicate delimiter))
	((char-set? delimiter) (char-set-predicate delimiter))
	((unary-procedure? delimiter) delimiter)
	(else (error:not-a splitter-delimiter? delimiter 'string-splitter))))

(define (splitter-delimiter? object)
  (or (char? object)
      (char-set? object)
      (unary-procedure? object)))

;;;; Trimmer/Padder

(define (string-trimmer . options)
  (receive (where copy? trim-char?)
      (string-trimmer-options options 'string-trimmer)
    (let ((get-trimmed (if copy? string-copy string-slice)))
      (lambda (string)
	(let ((end (string-length string)))
	  (get-trimmed
	   string
	   (if (eq? where 'trailing)
	       0
	       (let loop ((index 0))
		 (if (and (fix:< index end)
			  (trim-char? (string-ref string index)))
		     (loop (fix:+ index 1))
		     index)))
	   (if (eq? where 'leading)
	       end
	       (let loop ((index end))
		 (if (and (fix:> index 0)
			  (trim-char? (string-ref string (fix:- index 1))))
		     (loop (fix:- index 1))
		     index)))))))))

(define-deferred string-trimmer-options
  (keyword-option-parser
   (list (list 'where '(leading trailing both) 'both)
	 (list 'copy? boolean? #f)
	 (list 'trim-char? unary-procedure? char-whitespace?))))

(define (string-padder . options)
  (receive (where fill-with clip?)
      (string-padder-options options 'string-padder)
    (lambda (string n)
      (guarantee index-fixnum? n 'string-padder)
      (let ((cluster-length (grapheme-cluster-length string)))
	(cond ((fix:= n cluster-length)
	       string)
	      ((fix:< n cluster-length)
	       (if clip?
		   (if (eq? where 'leading)
		       (grapheme-cluster-slice string
					       (fix:- cluster-length n)
					       cluster-length)
		       (grapheme-cluster-slice string 0 n))
		   string))
	      (else
	       (let ((builder (string-builder)))
		 (if (eq? where 'trailing)
		     (builder string))
		 (do ((i cluster-length (fix:+ i 1)))
		     ((not (fix:< i n)))
		   (builder fill-with))
		 (if (eq? where 'leading)
		     (builder string))
		 (builder))))))))

(define (grapheme-cluster-string? object)
  (and (string? object)
       (fix:= 1 (grapheme-cluster-length object))))

(define-deferred string-padder-options
  (keyword-option-parser
   (list (list 'where '(leading trailing) 'leading)
	 (list 'fill-with grapheme-cluster-string? " ")
	 (list 'clip? boolean? #t))))

;;;; Miscellaneous

(define (string-fill! string char #!optional start end)
  (guarantee mutable-string? string 'string-fill)
  (guarantee bitless-char? char 'string-fill!)
  (let* ((end (fix:end-index end (string-length string) 'string-fill!))
	 (start (fix:start-index start end 'string-fill!)))
    (translate-slice string start end
      (lambda (string start end)
	(do ((index start (fix:+ index 1)))
	    ((not (fix:< index end)) unspecific)
	  (ustring-set! string index char))))))

(define (string-replace string char1 char2)
  (guarantee bitless-char? char1 'string-replace)
  (guarantee bitless-char? char2 'string-replace)
  (string-map (lambda (char)
		(if (char=? char char1) char2 char))
	      string))

(define (string-hash string #!optional modulus)
  (let ((string* (string-for-primitive (string->nfd string))))
    (if (default-object? modulus)
	((ucode-primitive string-hash) string*)
	((ucode-primitive string-hash-mod) string* modulus))))

(define (string-hash-ci string #!optional modulus)
  (string-hash (string-foldcase string) modulus))

(define (8-bit-string? object)
  (and (string? object)
       (string-8-bit? object)))

(define (string-8-bit? string)
  (unpack-slice string
    (lambda (string start end)
      (case (ustring-cp-size string)
	((1) #t)
	((2) (every-loop char-8-bit? ustring2-ref string start end))
	(else (every-loop char-8-bit? ustring3-ref string start end))))))

(define (string-for-primitive string)
  (if (and (not (slice? string))
	   (let ((end (string-length string)))
	     (case (ustring-cp-size string)
	       ((1) (every-loop char-ascii? ustring1-ref string 0 end))
	       ((2) (every-loop char-ascii? ustring2-ref string 0 end))
	       (else (every-loop char-ascii? ustring3-ref string 0 end)))))
      string
      (string->utf8 string)))

(define-integrable (copy-loop to-set! to at from-ref from start end)
  (do ((i start (fix:+ i 1))
       (j at (fix:+ j 1)))
      ((not (fix:< i end)))
    (to-set! to j (from-ref from i))))

(define-integrable (every-loop proc ref string start end)
  (let loop ((i start))
    (if (fix:< i end)
	(and (proc (ref string i))
	     (loop (fix:+ i 1)))
	#t)))

;;;;Backwards compatibility

(define-integrable (string-find-maker finder key->predicate)
  (lambda (string key #!optional start end)
    (let* ((start (if (default-object? start) 0 start))
	   (index
	    (finder (key->predicate key)
		    (string-slice string start end))))
      (and index
	   (fix:+ start index)))))

(define string-find-next-char
  (string-find-maker string-find-first-index char=-predicate))

(define string-find-next-char-ci
  (string-find-maker string-find-first-index char-ci=-predicate))

(define string-find-next-char-in-set
  (string-find-maker string-find-first-index char-set-predicate))

(define string-find-previous-char
  (string-find-maker string-find-last-index char=-predicate))

(define string-find-previous-char-ci
  (string-find-maker string-find-last-index char-ci=-predicate))

(define string-find-previous-char-in-set
  (string-find-maker string-find-last-index char-set-predicate))

(define-integrable (substring-find-maker string-find)
  (lambda (string start end key)
    (string-find string key start end)))

(define substring-find-next-char
  (substring-find-maker string-find-next-char))

(define substring-find-next-char-ci
  (substring-find-maker string-find-next-char-ci))

(define substring-find-next-char-in-set
  (substring-find-maker string-find-next-char-in-set))

(define substring-find-previous-char
  (substring-find-maker string-find-previous-char))

(define substring-find-previous-char-ci
  (substring-find-maker string-find-previous-char-ci))

(define substring-find-previous-char-in-set
  (substring-find-maker string-find-previous-char-in-set))

(define (string-move! string1 string2 start2)
  (string-copy! string2 start2 string1))

(define (substring-move! string1 start1 end1 string2 start2)
  (string-copy! string2 start2 string1 start1 end1))

(define (substring-ci<? string1 start1 end1 string2 start2 end2)
  (string-ci<? (string-slice string1 start1 end1)
	       (string-slice string2 start2 end2)))

(define (substring-ci=? string1 start1 end1 string2 start2 end2)
  (string-ci=? (string-slice string1 start1 end1)
	       (string-slice string2 start2 end2)))

(define (substring<? string1 start1 end1 string2 start2 end2)
  (string<? (string-slice string1 start1 end1)
	    (string-slice string2 start2 end2)))

(define (substring=? string1 start1 end1 string2 start2 end2)
  (string=? (string-slice string1 start1 end1)
	    (string-slice string2 start2 end2)))

(define (substring-prefix? string1 start1 end1 string2 start2 end2)
  (string-prefix? (string-slice string1 start1 end1)
		  (string-slice string2 start2 end2)))

(define (substring-prefix-ci? string1 start1 end1 string2 start2 end2)
  (string-prefix-ci? (string-slice string1 start1 end1)
		     (string-slice string2 start2 end2)))

(define (substring-suffix? string1 start1 end1 string2 start2 end2)
  (string-suffix? (string-slice string1 start1 end1)
		  (string-slice string2 start2 end2)))

(define (substring-suffix-ci? string1 start1 end1 string2 start2 end2)
  (string-suffix-ci? (string-slice string1 start1 end1)
		     (string-slice string2 start2 end2)))

(define (substring-fill! string start end char)
  (string-fill! string char start end))

(define (substring-lower-case? string start end)
  (string-lower-case? (string-slice string start end)))

(define (substring-upper-case? string start end)
  (string-upper-case? (string-slice string start end)))

(define (string-null? string)
  (fix:= 0 (string-length string)))

(define (char->string char)
  (guarantee bitless-char? char 'char->string)
  (let ((s (immutable-ustring-allocate 1 (char->integer char))))
    (ustring-set! s 0 char)
    s))

(define (legacy-string-trimmer where)
  (lambda (string #!optional char-set)
    ((string-trimmer 'where where
		     'copy? #t
		     'trim-char?
		     (char-set-predicate
		      (if (default-object? char-set)
			  char-set:whitespace
			  (char-set-invert char-set))))
     string)))

(define string-trim-left (legacy-string-trimmer 'leading))
(define string-trim-right (legacy-string-trimmer 'trailing))
(define string-trim (legacy-string-trimmer 'both))

(define (legacy-string-padder where)
  (lambda (string n #!optional char)
    ((string-padder 'where where
		    'fill-with (if (default-object? char)
				   char
				   (char->string char)))
     string n)))

(define string-pad-left (legacy-string-padder 'leading))
(define string-pad-right (legacy-string-padder 'trailing))

(define (decorated-string-append prefix infix suffix strings)
  ((string-joiner* 'prefix prefix
		   'infix infix
		   'suffix suffix)
   strings))

(define (burst-string string delimiter allow-runs?)
  ((string-splitter 'delimiter delimiter
		    'allow-runs? allow-runs?
		    'copy? #t)
   string))