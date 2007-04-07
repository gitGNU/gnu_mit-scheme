#!/bin/sh
#
# $Id: c-initial-bands.sh,v 1.1 2007/04/04 05:08:19 riastradh Exp $
#
# Copyright 2007 Massachusetts Institute of Technology
#
# This file is part of MIT/GNU Scheme.
#
# MIT/GNU Scheme is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# MIT/GNU Scheme is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with MIT/GNU Scheme; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

set -e

(
    cd runtime
    ../microcode/scheme --library ../lib --fasl runtime_make <<EOF
(disk-save "../lib/runtime.com")
EOF
)

microcode/scheme --library lib --large <<EOF
(load "microcode/sf+compiler.so")
(load-option 'SF)
(with-working-directory-pathname "compiler"
  (lambda ()
    (load "machines/C/make")))
(load-option '*PARSER)
(disk-save "lib/compiler.com")