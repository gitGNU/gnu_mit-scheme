#!/bin/sh

# $Id: makeinit.sh,v 1.1.2.1 2000/11/27 05:58:01 cph Exp $
#
# Copyright (c) 2000 Massachusetts Institute of Technology
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

autoheader
autoconf
if [ ! -f Makefile.in ]; then
  touch Makefile.in
fi
./configure
scheme -heap 2000 <<EOF
(load "makegen/makegen.scm")
(generate-makefile "makegen/Makefile.in.in"
		   "makegen/Makefile.deps"
		   "Makefile.in")
EOF
./config.status
