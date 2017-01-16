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

;;;; File I/O Ports
;;; package: (runtime file-i/o-port)

(declare (usual-integrations))

(define input-file-type)
(define output-file-type)
(define i/o-file-type)
(define (initialize-package!)
  (let ((other-operations
	 `((LENGTH ,operation/length)
	   (PATHNAME ,operation/pathname)
	   (POSITION ,operation/position)
	   (SET-POSITION! ,operation/set-position!)
	   (TRUENAME ,operation/pathname)
	   (WRITE-SELF ,operation/write-self))))
    (let ((make-type
	   (lambda (source sink)
	     (make-textual-port-type other-operations
				     (generic-i/o-port-type source sink)))))
      (set! input-file-type (make-type 'CHANNEL #f))
      (set! output-file-type (make-type #f 'CHANNEL))
      (set! i/o-file-type (make-type 'CHANNEL 'CHANNEL))))
  unspecific)

(define (operation/pathname port)
  (port-property 'pathname))

(define (set-port-pathname! port pathname)
  (set-port-property! port 'pathname pathname))

(define (operation/length port)
  (channel-file-length
   (or (input-port-channel port)
       (output-port-channel port))))

(define (operation/write-self port output-port)
  (write-string " for file: " output-port)
  (write (->namestring (operation/pathname port)) output-port))

(define (operation/position port)
  (guarantee-positionable-port port 'OPERATION/POSITION)
  (if (output-port? port)
      (flush-output port))
  (if (input-port? port)
      (let ((input-buffer (port-input-buffer port)))
	(- (channel-file-position (input-port-channel port))
	   (input-buffer-free-bytes input-buffer)))
      (channel-file-position (output-port-channel port))))

(define (operation/set-position! port position)
  (guarantee-positionable-port port 'OPERATION/SET-POSITION!)
  (guarantee-exact-nonnegative-integer position 'OPERATION/SET-POSITION!)
  (if (output-port? port)
      (flush-output port))
  (if (input-port? port)
      (clear-input-buffer (port-input-buffer port)))
  (channel-file-set-position (if (input-port? port)
				 (input-port-channel port)
				 (output-port-channel port))
			     position))

(define (guarantee-positionable-port port caller)
  (guarantee textual-port? port caller)
  (if (and (i/o-port? port)
	   (not (eq? (input-port-channel port) (output-port-channel port))))
      (error:bad-range-argument port caller))
  (if (and (input-port? port)
	   (not (input-buffer-using-binary-normalizer?
		 (port-input-buffer port))))
      (error:bad-range-argument port caller))
  (if (and (output-port? port)
	   (not (output-buffer-using-binary-denormalizer?
		 (port-output-buffer port))))
      (error:bad-range-argument port caller)))

(define (input-file-opener caller make-port)
  (lambda (filename)
    (let* ((pathname (merge-pathnames filename))
	   (channel (file-open-input-channel (->namestring pathname))))
      (make-port channel #f pathname caller))))

(define (output-file-opener caller make-port)
  (lambda (filename #!optional append?)
    (let* ((pathname (merge-pathnames filename))
	   (filename (->namestring pathname))
	   (channel
	    (if (if (default-object? append?) #f append?)
		(file-open-append-channel filename)
		(file-open-output-channel filename))))
      (make-port #f channel pathname caller))))

(define (exclusive-output-file-opener caller make-port)
  (lambda (filename)
    (let* ((pathname (merge-pathnames filename))
	   (channel
	    (file-open-exclusive-output-channel (->namestring pathname))))
      (make-port #f channel pathname caller))))

(define (i/o-file-opener caller make-port)
  (lambda (filename)
    (let* ((pathname (merge-pathnames filename))
	   (channel (file-open-io-channel (->namestring pathname))))
      (make-port channel channel pathname caller))))

(define (make-textual-port input-channel output-channel pathname caller)
  caller
  (let ((port (%make-textual-port input-channel output-channel pathname)))
    (port/set-line-ending port (file-line-ending pathname))
    port))

(define (make-legacy-binary-port input-channel output-channel pathname caller)
  caller
  (let ((port (%make-textual-port input-channel output-channel pathname)))
    (port/set-coding port 'BINARY)
    (port/set-line-ending port 'BINARY)
    port))

(define (%make-textual-port input-channel output-channel pathname)
  (let ((port
	 (make-generic-i/o-port input-channel
				output-channel
				(cond ((not input-channel) output-file-type)
				      ((not output-channel) input-file-type)
				      (else i/o-file-type)))))
    ;; If both channels are set they are the same.
    (cond (input-channel (set-channel-port! input-channel port))
	  (output-channel (set-channel-port! output-channel port)))
    (set-port-pathname! port pathname)
    port))

(define open-input-file
  (input-file-opener 'open-input-file make-textual-port))

(define open-output-file
  (output-file-opener 'open-output-file make-textual-port))

(define open-exclusive-output-file
  (exclusive-output-file-opener 'open-exclusive-output-file make-textual-port))

(define open-i/o-file
  (i/o-file-opener 'open-i/o-file make-textual-port))

(define open-legacy-binary-input-file
  (input-file-opener 'open-legacy-binary-input-file make-legacy-binary-port))

(define open-legacy-binary-output-file
  (output-file-opener 'open-legacy-binary-output-file make-legacy-binary-port))

(define open-exclusive-legacy-binary-output-file
  (exclusive-output-file-opener 'open-exclusive-legacy-binary-output-file
				make-legacy-binary-port))

(define open-legacy-binary-i/o-file
  (i/o-file-opener 'open-legacy-binary-i/o-file make-legacy-binary-port))

(define (make-binary-port input-channel output-channel pathname caller)
  (let ((port (%make-binary-port input-channel output-channel caller)))
    (set-port-pathname! port pathname)
    port))

(define (%make-binary-port input-channel output-channel caller)
  (cond ((not input-channel)
	 (make-binary-output-port (make-channel-output-sink output-channel)
				  caller))
	((not output-channel)
	 (make-binary-input-port (make-channel-input-source input-channel)
				 caller))
	(else
	 (make-binary-i/o-port (make-channel-input-source input-channel)
			       (make-channel-output-sink output-channel)
			       caller))))

(define open-binary-input-file
  (input-file-opener 'open-binary-input-file make-binary-port))

(define open-binary-output-file
  (output-file-opener 'open-binary-output-file make-binary-port))

(define open-exclusive-binary-output-file
  (exclusive-output-file-opener 'open-exclusive-binary-output-file
				make-binary-port))

(define open-binary-i/o-file
  (i/o-file-opener 'open-binary-i/o-file make-binary-port))

(define ((make-call-with-file open) input-specifier receiver)
  (let ((port (open input-specifier)))
    (let ((value (receiver port)))
      (close-port port)
      value)))

(define call-with-input-file
  (make-call-with-file open-input-file))

(define call-with-output-file
  (make-call-with-file open-output-file))

(define call-with-exclusive-output-file
  (make-call-with-file open-exclusive-output-file))

(define call-with-append-file
  (make-call-with-file (lambda (filename) (open-output-file filename #t))))


(define call-with-binary-input-file
  (make-call-with-file open-binary-input-file))

(define call-with-binary-output-file
  (make-call-with-file open-binary-output-file))

(define call-with-exclusive-binary-output-file
  (make-call-with-file open-exclusive-binary-output-file))

(define call-with-binary-append-file
  (make-call-with-file
   (lambda (filename) (open-binary-output-file filename #t))))


(define call-with-legacy-binary-input-file
  (make-call-with-file open-legacy-binary-input-file))

(define call-with-legacy-binary-output-file
  (make-call-with-file open-legacy-binary-output-file))

(define call-with-exclusive-legacy-binary-output-file
  (make-call-with-file open-exclusive-legacy-binary-output-file))

(define call-with-legacy-binary-append-file
  (make-call-with-file
   (lambda (filename) (open-legacy-binary-output-file filename #t))))

(define ((make-with-input-from-file call) input-specifier thunk)
  (call input-specifier
    (lambda (port)
      (with-input-from-port port thunk))))

(define with-input-from-file
  (make-with-input-from-file call-with-input-file))

(define with-input-from-legacy-binary-file
  (make-with-input-from-file call-with-legacy-binary-input-file))

(define ((make-with-output-to-file call) output-specifier thunk)
  (call output-specifier
    (lambda (port)
      (with-output-to-port port thunk))))

(define with-output-to-file
  (make-with-output-to-file call-with-output-file))

(define with-output-to-exclusive-file
  (make-with-output-to-file call-with-exclusive-output-file))

(define with-output-to-legacy-binary-file
  (make-with-output-to-file call-with-legacy-binary-output-file))

(define with-output-to-exclusive-legacy-binary-file
  (make-with-output-to-file call-with-exclusive-legacy-binary-output-file))