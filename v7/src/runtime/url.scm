#| -*-Scheme-*-

$Id: url.scm,v 1.19 2005/05/24 19:53:42 cph Exp $

Copyright 2000,2001,2003,2004,2005 Massachusetts Institute of Technology

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

;;;; URI Encoding
;;; package: (runtime uri)

;;; Based on RFC 2396 <http://ietf.org/rfc/rfc2396.txt>

(declare (usual-integrations))

(define-record-type <uri>
    (%make-uri scheme authority path-relative? path query fragment)
    uri?
  (scheme uri-scheme)
  (authority uri-authority)
  (path-relative? uri-path-relative?)
  (path uri-path)
  (query uri-query)
  (fragment uri-fragment))

(define (make-uri scheme authority path-relative? path query fragment)
  (if scheme (guarantee-uri-scheme scheme 'MAKE-URI))
  (if authority (guarantee-uri-authority authority 'MAKE-URI))
  (guarantee-uri-path path 'MAKE-URI)
  (if query (guarantee-utf8-string query 'MAKE-URI))
  (if fragment (guarantee-utf8-string fragment 'MAKE-URI))
  (if (string? path)
      (begin
	(if (not scheme) (error:bad-range-argument scheme 'MAKE-URI))
	(if authority (error:bad-range-argument authority 'MAKE-URI))
	(if path-relative? (error:bad-range-argument path-relative? 'MAKE-URI))
	(if query (error:bad-range-argument query 'MAKE-URI))))
  (if (and scheme path-relative?)
      (error:bad-range-argument path-relative? 'MAKE-URI))
  (if (and (null? path) (not authority))
      (error:bad-range-argument path 'MAKE-URI))
  (%make-uri scheme authority (if path-relative? #t #f) path query fragment))

(define-integrable (uri-path-absolute? uri)
  (not (uri-path-relative? uri)))

(define-integrable (uri-relative? uri)
  (if (uri-scheme uri) #f #t))

(define-integrable (uri-absolute? uri)
  (if (uri-scheme uri) #t #f))

(define-integrable (uri-opaque? uri)
  (string? (uri-path uri)))

(define-integrable (uri-heirarchical? uri)
  (not (uri-opaque? uri)))

(define (relative-uri? object)
  (and (uri? object)
       (uri-relative? object)))

(define (absolute-uri? object)
  (and (uri? object)
       (uri-absolute? object)))

(define (opaque-uri? object)
  (and (uri? object)
       (uri-opaque? object)))

(define (heirarchical-uri? object)
  (and (uri? object)
       (uri-heirarchical? object)))

(define-guarantee uri "URI")
(define-guarantee relative-uri "relative URI")
(define-guarantee absolute-uri "absolute URI")
(define-guarantee opaque-uri "opaque URI")
(define-guarantee heirarchical-uri "heirarchical URI")

(define (uri-scheme? object)
  (and (interned-symbol? object)
       (complete-match match-scheme (symbol-name object))))

(define (uri-path? object)
  (or (and (utf8-string? object)
	   (fix:> (string-length object) 0))
      (list-of-type? object
	(lambda (elt)
	  (or (utf8-string? elt)
	      (and (pair? elt)
		   (utf8-string? (car elt))
		   (list-of-type? (cdr elt) utf8-string?)))))))

(define (uri-authority? object)
  (or (uri-server? object)
      (uri-registry-name? object)))

(define (uri-registry-name? object)
  (and (utf8-string? object)
       (fix:> (string-length object) 0)))

(define-record-type <uri-server>
    (%make-uri-server host port userinfo)
    uri-server?
  (host uri-server-host)
  (port uri-server-port)
  (userinfo uri-server-userinfo))

(define (make-uri-server host port userinfo)
  (if host (guarantee-uri-host host 'MAKE-URI-SERVER))
  (if port (guarantee-uri-port port 'MAKE-URI-SERVER))
  (if userinfo (guarantee-utf8-string userinfo 'MAKE-URI-SERVER))
  (if (not host)
      (begin
	(if port (error:bad-range-argument port 'MAKE-URI-SERVER))
	(if userinfo (error:bad-range-argument userinfo 'MAKE-URI-SERVER))))
  (%make-uri-server host port userinfo))

(define (uri-host? object)
  (and (string? object)
       (complete-match match-host object)))

(define (uri-port? object)
  (exact-nonnegative-integer? object))

(define-guarantee uri-scheme "URI scheme")
(define-guarantee uri-path "URI path")
(define-guarantee uri-authority "URI authority")
(define-guarantee uri-registry-name "URI registry name")
(define-guarantee uri-server "URI server")
(define-guarantee uri-host "URI host")
(define-guarantee uri-port "URI port")

(define (->uri object #!optional caller)
  (cond ((uri? object) object)
	((string? object) (string->uri object))
	((symbol? object) (string->uri (symbol-name object)))
	(else
	 (error:not-uri object (if (default-object? caller) '->URI caller)))))

(define char-set:uri-alpha)
(define char-set:uri-digit)
(define char-set:uri-alphanum)
(define char-set:uri-alphanum-)
(define char-set:uri-hex)
(define char-set:uri-scheme)
(define char-set:uric)
(define char-set:uric-no-slash)
(define char-set:uri-reg-name)
(define char-set:uri-userinfo)
(define char-set:uri-rel-segment)
(define char-set:uri-pchar)

(define parse-fragment)
(define parse-query)
(define parse-reg-name)
(define parse-userinfo)
(define parse-rel-segment)
(define parse-pchar)

(define url:char-set:unreserved)
(define url:char-set:unescaped)

(define (initialize-package!)
  (set! char-set:uri-alpha
	(string->char-set
	 "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"))
  (set! char-set:uri-digit (string->char-set "0123456789"))
  (set! char-set:uri-alphanum
	(char-set-union char-set:uri-alpha char-set:uri-digit))
  (set! char-set:uri-alphanum-
	(char-set-union char-set:uri-alphanum (char-set #\-)))
  (set! char-set:uri-hex (string->char-set "0123456789abcdefABCDEF"))
  (set! char-set:uri-scheme
	(char-set-union char-set:uri-alphanum (string->char-set "+-.")))
  (set! char-set:uric
	(char-set-union char-set:uri-alphanum
			(string->char-set "!'()*-._~")	;mark
			(string->char-set "$&+,/:;=?@") ;reserved
			))
  (let ((component-chars
	 (lambda (free)
	   (char-set-difference char-set:uric (string->char-set free)))))
    (set! char-set:uric-no-slash	(component-chars "/"))
    (set! char-set:uri-reg-name		(component-chars "/?"))
    (set! char-set:uri-userinfo		(component-chars "/?@"))
    (set! char-set:uri-rel-segment	(component-chars "/:?"))
    (set! char-set:uri-pchar		(component-chars "/;?")))

  (set! parse-fragment (component-parser-* char-set:uric))
  (set! parse-query parse-fragment)
  (set! parse-reg-name (component-parser-+ char-set:uri-reg-name))
  (set! parse-userinfo (component-parser-* char-set:uri-userinfo))
  (set! parse-rel-segment (component-parser-+ char-set:uri-rel-segment))
  (set! parse-pchar (component-parser-* char-set:uri-pchar))

  ;; backwards compatibility:
  (set! url:char-set:unreserved
	(char-set-union char-set:uri-alphanum
			(string->char-set "!$'()*+,-._")))
  (set! url:char-set:unescaped
	(char-set-union url:char-set:unreserved
			(string->char-set ";/?:@&=")))
  unspecific)

;;;; Parser

(define (string->uri string #!optional start end)
  (let ((v (complete-parse parse-uri string start end)))
    (and v
	 (vector-ref v 0))))

(define parse-uri
  (*parser
   (top-level
    (seq (alt parse-absolute-uri
	      parse-relative-uri
	      (values #f))
	 (alt (seq "#" parse-fragment)
	      (values #f))))))

(define parse-absolute-uri
  (*parser
   (alt (encapsulate (lambda (v)
		       (let ((path (vector-ref v 1)))
			 (%make-uri (vector-ref v 0)
				    (vector-ref path 0)
				    (vector-ref path 1)
				    (vector-ref path 2)
				    (vector-ref v 2)
				    (vector-ref v 3))))
	  (seq parse-scheme
	       ":"
	       (alt parse-net-path parse-abs-path)
	       (alt (seq "?" parse-query)
		    (values #f))
	       (alt (seq "#" parse-fragment)
		    (values #f))))
	(encapsulate (lambda (v)
		       (%make-uri (vector-ref v 0)
				  #f
				  #f
				  (vector-ref v 1)
				  #f
				  (vector-ref v 2)))
	  (seq parse-scheme
	       ":"
	       (match (seq (char-set char-set:uric-no-slash)
			   (* (char-set char-set:uric))))
	       (alt (seq "#" parse-fragment)
		    (values #f)))))))

(define parse-scheme
  (*parser
   (map intern (match match-scheme))))

(define match-scheme
  (*matcher
   (seq (char-set char-set:uri-alpha)
	(* (char-set char-set:uri-scheme)))))

(define parse-relative-uri
  (*parser
   (encapsulate (lambda (v)
		  (let ((path (vector-ref v 0)))
		    (%make-uri #f
			       (vector-ref path 0)
			       (vector-ref path 1)
			       (vector-ref path 2)
			       (vector-ref v 1)
			       (vector-ref v 2))))
     (seq (alt parse-net-path
	       parse-abs-path
	       parse-rel-path)
	  (alt (seq "?" parse-query)
	       (values #f))
	  (alt (seq "#" parse-fragment)
	       (values #f))))))

(define parse-net-path
  (*parser
   (encapsulate (lambda (v) (vector (vector-ref v 0) #f (vector-ref v 1)))
     (seq "//"
	  parse-authority
	  (alt (encapsulate vector->list
		 (* (seq "/" parse-segment)))
	       (values '()))))))

(define parse-abs-path
  (*parser
   (map (lambda (p) (vector #f #f p))
	(encapsulate vector->list
	  (* (seq "/" parse-segment))))))

(define parse-rel-path
  (*parser
   (map (lambda (p) (vector #f #t p))
	(encapsulate vector->list
	  (seq parse-rel-segment
	       (* (seq "/" parse-segment)))))))

(define parse-segment
  (*parser
   (encapsulate (lambda (v)
		  (if (fix:> (vector-length v) 1)
		      (vector->list v)
		      (vector-ref v 0)))
     (seq parse-pchar
	  (* (seq ";" parse-pchar))))))

(define parse-authority
  (*parser
   (alt (encapsulate (lambda (v)
		       (%make-uri-server (vector-ref v 1)
					 (vector-ref v 2)
					 (vector-ref v 0)))
	  (seq (alt parse-userinfo
		    (values #f))
	       parse-hostport))
	parse-reg-name
	(values (%make-uri-server #f #f #f)))))

(define parse-hostport
  (*parser
   (seq (match match-host)
	(alt (seq (noise ":")
		  (alt (map string->number (match match-digits))
		       (values #f)))
	     (values #f)))))

(define match-host
  (*matcher (alt match-hostname match-ipv4-address)))

(define match-hostname
  (let ((match-tail
	 (*matcher
	  (? (seq (* (char-set char-set:uri-alphanum-))
		  (char-set char-set:uri-alphanum))))))
    (*matcher
     (seq (* (seq (char-set char-set:uri-alphanum)
		  match-tail
		  "."))
	  (char-set char-set:uri-alpha)
	  match-tail
	  (? ".")))))

(define match-ipv4-address
  (*matcher
   (seq match-digits "." match-digits "." match-digits "." match-digits)))

(define match-digits
  (*matcher (+ (char-set char-set:uri-digit))))

;;;; Output

(define (uri->string uri)
  (guarantee-uri uri 'URI->STRING)
  (call-with-output-string
    (lambda (port)
      (%write-uri uri port))))

(define (uri->symbol uri)
  (utf8-string->symbol (uri->string uri)))

(define (write-uri uri port)
  (guarantee-uri uri 'WRITE-URI)
  (guarantee-port port 'WRITE-URI)
  (%write-uri uri port))

(define (%write-uri uri port)
  (let ((scheme (uri-scheme uri))
	(authority (uri-authority uri))
	(path-relative? (uri-path-relative? uri))
	(path (uri-path uri))
	(query (uri-query uri))
	(fragment (uri-fragment uri)))
    (if scheme
	(begin
	  (write scheme port)
	  (write-char #\: port)))
    (cond ((string? path)
	   (write-escaped-substring path 0 1 char-set:uric-no-slash port)
	   (write-escaped-substring path 1 (string-length path) char-set:uric
				    port))
	  (authority
	   (write-string "//" port)
	   (write-authority authority port)
	   (write-abs-path path port))
	  (path-relative?
	   (write-escaped (car path) char-set:uri-rel-segment port)
	   (write-abs-path (cdr path) port))
	  (else
	   (write-abs-path path port)))
    (if query
	(begin
	  (write-char #\? port)
	  (write-escaped query char-set:uric port)))
    (if fragment
	(begin
	  (write-char #\# port)
	  (write-escaped fragment char-set:uric port)))))

(define (write-authority authority port)
  (if (uri-server? authority)
      (begin
	(if (uri-server-userinfo authority)
	    (begin
	      (write-escaped (uri-server-userinfo authority)
			     char-set:uri-userinfo
			     port)
	      (write-char #\@ port)))
	(if (uri-server-host authority)
	    (write-string (uri-server-host authority) port))
	(if (uri-server-port authority)
	    (begin
	      (write-char #\: port)
	      (write (uri-server-port authority) port))))
      (write-escaped authority char-set:uri-reg-name port)))

(define (write-abs-path path port)
  (let ((write-pchar
	 (lambda (string)
	   (write-escaped string char-set:uri-pchar port))))
    (for-each (lambda (segment)
		(write-char #\/ port)
		(if (string? segment)
		    (write-pchar segment)
		    (for-each write-pchar segment)))
	      path)))

;;;; Escape codecs

(define (component-parser-* cs)
  (*parser
   (map decode-component
	(match (* (alt (char-set cs) match-escape))))))

(define (component-parser-+ cs)
  (*parser
   (map decode-component
	(match (+ (alt (char-set cs) match-escape))))))

(define match-escape
  (*matcher
   (seq "%"
	(char-set char-set:uri-hex)
	(char-set char-set:uri-hex))))

(define (decode-component string)
  (if (string-find-next-char string #\%)
      (call-with-output-string
	(lambda (port)
	  (let ((end (string-length string)))
	    (let loop ((i 0))
	      (if (fix:< i end)
		  (if (char=? (string-ref string i) #\%)
		      (begin
			(write-char (integer->char
				     (substring->number string
							(fix:+ i 1)
							(fix:+ i 3)
							16
							#t))
				    port)
			(loop (fix:+ i 3)))
		      (begin
			(write-char (string-ref string i) port)
			(loop (fix:+ i 1)))))))))
      string))

(define (write-escaped string unescaped port)
  (write-escaped-substring string 0 (string-length string) unescaped port))

(define (write-escaped-substring string start end unescaped port)
  (do ((i start (fix:+ i 1)))
      ((not (fix:< i end)))
    (let ((char (string-ref string i)))
      (if (char-set-member? unescaped char)
	  (write-char char port)
	  (let ((s (number->string (char->integer char) 16)))
	    (write-char #\% port)
	    (if (fix:= (string-length s) 1)
		(write-char #\0 port))
	    (write-string s port))))))

(define (complete-match matcher string #!optional start end)
  (let ((buffer (string->parser-buffer string start end)))
    (and (matcher buffer)
	 (not (peek-parser-buffer-char buffer)))))

(define (complete-parse parser string #!optional start end)
  (let ((buffer (string->parser-buffer string start end)))
    (let ((v (parser buffer)))
      (and v
	   (not (peek-parser-buffer-char buffer))
	   v))))

;; backwards compatibility:
(define (url:encode-string string)
  (call-with-output-string
    (lambda (port)
      (write-escaped string url:char-set:unescaped port))))