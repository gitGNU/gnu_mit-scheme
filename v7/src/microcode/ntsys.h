/* -*-C-*-

$Id: ntsys.h,v 1.10.2.1 2005/08/23 02:55:11 cph Exp $

Copyright (c) 1992-1999 Massachusetts Institute of Technology

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

*/

#ifndef SCM_NTSYS_H
#define SCM_NTSYS_H

/* Misc */

extern BOOL win32_under_win32s_p ();
extern int  nt_console_write (void * vbuffer, size_t nsize);
extern BOOL nt_pathname_as_filename (const char * name, char * buffer);

#endif /* SCM_NTSYS_H */
