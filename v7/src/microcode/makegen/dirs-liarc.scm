#| -*-Scheme-*-

$Id: dirs-liarc.scm,v 1.1.2.1 2006/10/09 07:02:42 cph Exp $

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
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301,
USA.

|#

;;;; Directories holding statically-linked C files.

;;; Format is a list with the directory in the car and a list of
;;; exclusions in the cdr.

("../runtime")
("../sf")
("../cref")
("../compiler")
("../compiler/back")
("../compiler/base")
("../compiler/fggen")
("../compiler/fgopt")
("../compiler/machines/C")
("../compiler/rtlbase")
("../compiler/rtlgen")
("../compiler/rtlopt")
("../star-parser" "compile" "ed-ffi" "load" "test-parser")