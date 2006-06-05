#!/bin/sh
#
# $Id: Stage.sh,v 1.5 2003/02/14 18:48:11 cph Exp $
#
# Copyright 2000,2001 Massachusetts Institute of Technology
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

# Utility for MIT/GNU Scheme compiler staging.

if [ $# -ne 2 ]; then
    echo "usage: $0 <command> <tag>"
    exit 1
fi

SUBDIRS="back base fggen fgopt machine rtlbase rtlgen rtlopt"
S="STAGE${2}"

case "${1}" in
make)
    for D in ${SUBDIRS}; do
	(cd ${D} && mkdir "${S}" && mv -f *.com *.bci "${S}") || exit 1
    done
    ;;
unmake)
    for D in ${SUBDIRS}; do
	(cd ${D} && mv -f "${S}"/* . && rmdir "${S}") || exit 1
    done
    ;;
remove)
    for D in ${SUBDIRS}; do
	rm -rf "${D}/${S}"
    done
    ;;
copy)
    for D in ${SUBDIRS}; do
	(cd ${D} && cp "${S}"/* .) || exit 1
    done
    ;;
link)
    for D in ${SUBDIRS}; do
	(cd ${D} && ln "${S}"/* .) || exit 1
    done
    ;;
*)
    echo "$0: Unknown command ${1}"
    exit 1
    ;;
esac