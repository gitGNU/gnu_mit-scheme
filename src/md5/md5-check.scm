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

;;;; Test the MD5 option.

(let ((sample "Some text to hash."))
  (let ((hash (md5-sum->hexadecimal (md5-string sample))))
    (if (not (string=? hash "C8E89C4CBF3ABF9AA758D691CBE4B784"))
	(error "Bad hash for sample text:" hash)))
  (call-with-output-file "sample"
    (lambda (port) (write-string sample port) (newline port)))
  (let ((hash (md5-sum->hexadecimal (md5-file "sample"))))
    (if (not (string=? hash "43EB9ECCB88C329721925EFC04843AF1"))
	(error "Bad hash for sample file:" hash))))