/* -*-C-*-

$Id: bchdmp.c,v 9.85.2.1.2.2 2000/12/04 06:15:26 cph Exp $

Copyright (c) 1987-2000 Massachusetts Institute of Technology

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
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

/* bchgcl, bchmmg, bchpur, and bchdmp can replace gcloop, memmag,
   purify, and fasdump, respectively, to provide garbage collection
   and related utilities to disk. */

#include "scheme.h"
#include "prims.h"
#include "osfile.h"
#include "osfs.h"
#include "trap.h"
#include "lookup.h"		/* UNCOMPILED_VARIABLE */
#define In_Fasdump
#include "fasl.h"
#include "bchgcc.h"

extern int EXFUN (OS_channel_copy, (off_t, Tchannel, Tchannel));

extern SCHEME_OBJECT EXFUN
  (dump_renumber_primitive, (SCHEME_OBJECT));
extern SCHEME_OBJECT * EXFUN
  (initialize_primitive_table, (SCHEME_OBJECT *, SCHEME_OBJECT *));
extern SCHEME_OBJECT * EXFUN
  (cons_primitive_table, (SCHEME_OBJECT *, SCHEME_OBJECT *, long *));
extern SCHEME_OBJECT * EXFUN
  (cons_whole_primitive_table, (SCHEME_OBJECT *, SCHEME_OBJECT *, long *));

extern SCHEME_OBJECT compiler_utilities;
extern SCHEME_OBJECT * EXFUN
  (cons_c_code_table, (SCHEME_OBJECT *, SCHEME_OBJECT *, long *));

#ifdef __unix__
#  include "ux.h"
#  include "uxio.h"
   static char FASDUMP_FILENAME[] = "/tmp/fasdumpXXXXXX";
#endif

#ifdef __WIN32__
#  include "nt.h"
#  include "ntio.h"
   static char FASDUMP_FILENAME[] = "\\tmp\\faXXXXXX";
#endif

#ifdef __OS2__
#  include "os2.h"
#  ifdef __EMX__
#    include <io.h>
#  endif
   static char FASDUMP_FILENAME[] = "\\tmp\\faXXXXXX";
#endif

#if defined(__IBMC__) || defined(__WATCOMC__)

#include <io.h>
#include <sys\stat.h>
#include <fcntl.h>

#ifndef F_OK
#  define F_OK 0
#  define X_OK 1
#  define W_OK 2
#  define R_OK 4
#endif

char *
DEFUN (mktemp, (fname), char * fname)
{
  /* This assumes that fname ends in at least 3 Xs.
     tmpname seems too random to use.
     This, of course, has a window in which another program can
     create the file.  */

  int posn = ((strlen (fname)) - 3);
  int counter;

  for (counter = 0; counter < 1000; counter++)
    {
      sprintf (&fname[posn], "%03d", counter);
      if ((access (fname, F_OK)) != 0)
	{
	  int fid = (open (fname,
			   (O_CREAT | O_EXCL | O_RDWR),
			   (S_IREAD | S_IWRITE)));
	  if (fid < 0)
	    continue;
	  close (fid);
	  break;
	}
    }
  return ((counter < 1000) ? fname : 0);
}

#endif /* __IBMC__ or __WATCOMC__ */

static Tchannel dump_channel;
static char * dump_file_name;
static int real_gc_file;
static int dump_file;
static SCHEME_OBJECT * saved_free;
static SCHEME_OBJECT * fixup_buffer = 0;
static SCHEME_OBJECT * fixup_buffer_end;
static SCHEME_OBJECT * fixup;
static int fixup_count = 0;
static Boolean compiled_code_present_p;

#define Write_Data(size, buffer)					\
  ((OS_channel_write_dump_file						\
    (dump_channel,							\
     ((char *) (buffer)),						\
     ((size) * (sizeof (SCHEME_OBJECT)))))				\
   / (sizeof (SCHEME_OBJECT)))

#include "dump.c"

static SCHEME_OBJECT EXFUN (dump_to_file, (SCHEME_OBJECT, char *));
static int EXFUN (fasdump_exit, (long length));
static int EXFUN (reset_fixes, (void));
static ssize_t EXFUN (eta_read, (int, char *, int));
static ssize_t EXFUN (eta_write, (int, char *, int));
static long EXFUN
  (dump_loop, (SCHEME_OBJECT *, SCHEME_OBJECT **, SCHEME_OBJECT **));

/* (PRIMITIVE-FASDUMP object-to-dump filename-or-channel flag)

   Dump an object into a file so that it can be loaded using
   BINARY-FASLOAD.  A spare heap is required for this operation.  The
   first argument is the object to be dumped.  The second is the
   filename or channel.  The third argument, FLAG, is currently
   ignored.  The primitive returns #T or #F indicating whether it
   successfully dumped the object (it can fail on an object that is
   too large).  It should signal an error rather than return false,
   but ... some other time.

   This version of fasdump can only handle files (actually lseek-able
   streams), since the header is written at the beginning of the
   output but its contents are only know after the rest of the output
   has been written.

   Thus, for arbitrary channels, a temporary file is allocated, and on
   completion, the file is copied to the channel.  */

DEFINE_PRIMITIVE ("PRIMITIVE-FASDUMP", Prim_prim_fasdump, 3, 3, 0)
{
  PRIMITIVE_HEADER (3);
  {
    SCHEME_OBJECT root = (ARG_REF (1));
    if (STRING_P (ARG_REF (2)))
      PRIMITIVE_RETURN (dump_to_file (root, (STRING_ARG (2))));
    {
      Tchannel channel = (arg_channel (2));
      char temp_name [(sizeof (FASDUMP_FILENAME)) + 1];
      {
	char * scan1 = (& (FASDUMP_FILENAME[0]));
	char * scan2 = temp_name;
	while (1)
	  {
	    char c = (*scan1++);
	    (*scan2++) = c;
	    if (c == '\0')
	      break;
	  }
      }
      {
	char * temp_file = (mktemp (temp_name));
	if ((temp_file == 0) || ((*temp_file) == '\0'))
	  signal_error_from_primitive (ERR_EXTERNAL_RETURN);
      }
      {
	SCHEME_OBJECT fasdump_result = (dump_to_file (root, (temp_name)));
	if (fasdump_result == SHARP_T)
	  {
	    Tchannel temp_channel = (OS_open_input_file (temp_name));
	    int copy_result
	      = (OS_channel_copy ((OS_file_length (temp_channel)),
				  temp_channel,
				  channel));
	    OS_channel_close (temp_channel);
	    OS_file_remove (temp_name);
	    if (copy_result < 0)
	      signal_error_from_primitive (ERR_IO_ERROR);
	  }
	PRIMITIVE_RETURN (fasdump_result);
      }
    }
  }
}

/* (DUMP-BAND PROCEDURE FILE-NAME)
   Saves all of the heap and pure space on FILE-NAME.  When the
   file is loaded back using BAND_LOAD, PROCEDURE is called with an
   argument of #F.  */

DEFINE_PRIMITIVE ("DUMP-BAND", Prim_band_dump, 2, 2, 0)
{
  SCHEME_OBJECT * saved_free;
  SCHEME_OBJECT * prim_table_start;
  SCHEME_OBJECT * prim_table_end;
  SCHEME_OBJECT * c_table_start;
  SCHEME_OBJECT * c_table_end;
  long prim_table_length;
  long c_table_length;
  int result = 0;
  PRIMITIVE_HEADER (2);

  Band_Dump_Permitted ();
  CHECK_ARG (1, INTERPRETER_APPLICABLE_P);
  CHECK_ARG (2, STRING_P);
  if (Unused_Heap_Bottom < Heap_Bottom)
    /* Cause the image to be in the low heap, to increase
       the probability that no relocation is needed on reload. */
    Primitive_GC (0);
  Primitive_GC_If_Needed (5);

  saved_free = Free;

  {
    SCHEME_OBJECT Combination;
    Combination = (MAKE_POINTER_OBJECT (TC_COMBINATION_1, Free));
    (Free[COMB_1_FN]) = (ARG_REF (1));
    (Free[COMB_1_ARG_1]) = SHARP_F;
    Free += 2;
    {
      SCHEME_OBJECT p = (MAKE_POINTER_OBJECT (TC_LIST, Free));
      (*Free++) = Combination;
      (*Free++) = compiler_utilities;
      (*Free++) = p;
    }
  }

  prim_table_start = Free;
  prim_table_end
    = (cons_whole_primitive_table (prim_table_start, Heap_Top,
				   (&prim_table_length)));
  if (prim_table_end >= Heap_Top)
    goto done;

  c_table_start = prim_table_end;
  c_table_end
    = (cons_c_code_table (c_table_start, Heap_Top,
			  (&c_table_length)));
  if (c_table_end >= Heap_Top)
    goto done;

  {
    CONST char * filename = ((CONST char *) (STRING_LOC ((ARG_REF (2)), 0)));
    SCHEME_OBJECT * faligned_heap = Heap_Bottom;
    SCHEME_OBJECT * faligned_constant = Constant_Space;

    BCH_ALIGN_FLOAT_ADDRESS (faligned_heap);
    BCH_ALIGN_FLOAT_ADDRESS (faligned_constant);

    OS_file_remove_link (filename);
    dump_channel = (OS_open_dump_file (filename));
    if (dump_channel == NO_CHANNEL)
      error_bad_range_arg (2);

    result
      = (Write_File ((Free - 1),
		     ((long) (Free - faligned_heap)),
		     faligned_heap,
		     ((long) (Free_Constant - faligned_constant)),
		     faligned_constant,
		     prim_table_start,
		     prim_table_length,
		     ((long) (prim_table_end - prim_table_start)),
		     c_table_start,
		     c_table_length,
		     ((long) (c_table_end - c_table_start)),
		     (compiler_utilities != SHARP_F),
		     1));

    OS_channel_close_noerror (dump_channel);
    if (!result)
      OS_file_remove (filename);
  }

 done:
  Band_Dump_Exit_Hook ();
  Free = saved_free;
  PRIMITIVE_RETURN (BOOLEAN_TO_OBJECT (result));
}

static SCHEME_OBJECT
DEFUN (dump_to_file, (root, fname),
       SCHEME_OBJECT root AND
       char * fname)
{
  Boolean success = 1;
  long value;
  long length;
  long hlength;
  long tlength;
  long tsize;
  SCHEME_OBJECT * dumped_object;
  SCHEME_OBJECT * free_buffer;
  SCHEME_OBJECT * dummy;
  SCHEME_OBJECT * table_start;
  SCHEME_OBJECT * table_end;
  SCHEME_OBJECT * table_top;
  SCHEME_OBJECT header [FASL_HEADER_LENGTH];

  if (fixup_buffer == 0)
    {
      fixup_buffer = ((SCHEME_OBJECT *) (malloc (gc_buffer_bytes)));
      if (fixup_buffer == 0)
	error_system_call (errno, syscall_malloc);
      fixup_buffer_end = (fixup_buffer + gc_buffer_size);
    }

  dump_file_name = fname;
  dump_file = (open (dump_file_name, GC_FILE_FLAGS, 0666));
  if (dump_file < 0)
    error_bad_range_arg (2);

  compiled_code_present_p = 0;
  real_gc_file = (swap_gc_file (dump_file));
  saved_free = Free;
  fixup = fixup_buffer_end;
  fixup_count = -1;

  table_top = (& (saved_free [Space_Before_GC ()]));
  table_start = (initialize_primitive_table (saved_free, table_top));
  if (table_start >= table_top)
    {
      fasdump_exit (0);
      Primitive_GC (table_start - saved_free);
    }

  free_buffer = (initialize_free_buffer ());
  Free = 0;
  free_buffer += FASL_HEADER_LENGTH;

  dummy = free_buffer;
  BCH_ALIGN_FLOAT (Free, dummy);

  (*free_buffer++) = root;
  dumped_object = (Free++);

  value
    = dump_loop (((initialize_scan_buffer (0)) + FASL_HEADER_LENGTH),
		 (&free_buffer), (&Free));
  if (value != PRIM_DONE)
    {
      fasdump_exit (0);
      if (value == PRIM_INTERRUPT)
	return (SHARP_F);
      else
	signal_error_from_primitive (value);
    }
  end_transport (&success);
  if (!success)
    {
      fasdump_exit (0);
      return (SHARP_F);
    }

  length = (Free - dumped_object);

  table_end = (cons_primitive_table (table_start, table_top, &tlength));
  if (table_end >= table_top)
    {
      fasdump_exit (0);
      Primitive_GC (table_end - saved_free);
    }

#ifdef NATIVE_CODE_IS_C
  /* Cannot dump C compiled code. */
  if (compiled_code_present_p)
    {
      fasdump_exit (0);
      signal_error_from_primitive (ERR_COMPILED_CODE_ERROR);
    }
#endif

  tsize = (table_end - table_start);
  hlength = ((sizeof (SCHEME_OBJECT)) * tsize);
  if (((lseek (dump_file,
	       ((sizeof (SCHEME_OBJECT)) * (length + FASL_HEADER_LENGTH)),
	       0))
       == -1)
      || ((write (dump_file, ((char *) (&table_start[0])), hlength))
	  != hlength))
    {
      fasdump_exit (0);
      return (SHARP_F);
    }

  hlength = ((sizeof (SCHEME_OBJECT)) * FASL_HEADER_LENGTH);
  prepare_dump_header
    (header, dumped_object, length, dumped_object,
     0, Constant_Space, tlength, tsize, 0, 0,
     compiled_code_present_p, 0);
  if (((lseek (dump_file, 0, 0)) == -1)
      || ((write (dump_file, ((char *) &header[0]), hlength)) != hlength))
    {
      fasdump_exit (0);
      return (SHARP_F);
    }
  return
    (BOOLEAN_TO_OBJECT
     (fasdump_exit (((sizeof (SCHEME_OBJECT)) * (length + tsize)) + hlength)));
}

static int
DEFUN (fasdump_exit, (length), long length)
{
  SCHEME_OBJECT * fixes, * fix_address;
  int result;

  Free = saved_free;
  restore_gc_file ();

#ifdef HAVE_FTRUNCATE
  ftruncate (dump_file, length);
#endif
  result = ((close (dump_file)) == 0);
#if defined(HAVE_TRUNCATE) && !defined(HAVE_FTRUNCATE)
  truncate (dump_file_name, length);
#endif

  if (length == 0)
    unlink (dump_file_name);
  dump_file_name = 0;

  fixes = fixup;

 next_buffer:

  while (fixes != fixup_buffer_end)
    {
      fix_address = ((SCHEME_OBJECT *) (*fixes++));
      (*fix_address) = (*fixes++);
    }

  if (fixup_count >= 0)
    {
      if ((retrying_file_operation
	   (eta_read,
	    real_gc_file,
	    ((char *) fixup_buffer),
	    (gc_file_start_position + (fixup_count << gc_buffer_byte_shift)),
	    gc_buffer_bytes,
	    "read",
	    "the fixup buffer",
	    (&gc_file_current_position),
	    io_error_retry_p))
	  != ((long) gc_buffer_bytes))
	{
	  gc_death
	    (TERM_EXIT,
	     "fasdump: Could not read back the fasdump fixup information",
	     0, 0);
	  /*NOTREACHED*/
	}
      fixup_count -= 1;
      fixes = fixup_buffer;
      goto next_buffer;
    }

  fixup = fixes;
  Fasdump_Exit_Hook ();
  return (result);
}

static int
DEFUN_VOID (reset_fixes)
{
  long start;

  fixup_count += 1;
  start = (gc_file_start_position + (fixup_count << gc_buffer_byte_shift));

  if (((start + ((long) gc_buffer_bytes)) > gc_file_end_position)
      || ((retrying_file_operation
	   (eta_write,
	    real_gc_file,
	    ((char *) fixup_buffer),
	    start,
	    gc_buffer_bytes,
	    "write",
	    "the fixup buffer",
	    (&gc_file_current_position),
	    io_error_always_abort))
	  != ((long) gc_buffer_bytes)))
    return (0);
  fixup = fixup_buffer_end;
  return (1);
}

static ssize_t
DEFUN (eta_read, (fid, buffer, size),
       int fid AND
       char * buffer AND
       int size)
{
  return (read (fid, buffer, size));
}

static ssize_t
DEFUN (eta_write, (fid, buffer, size),
       int fid AND
       char * buffer AND
       int size)
{
  return (write (fid, buffer, size));
}

/* Utility macros. */

#define fasdump_remember_to_fix(location, contents)			\
{									\
  if ((fixup == fixup_buffer) && (!reset_fixes ()))			\
    return (PRIM_INTERRUPT);						\
  (*--fixup) = contents;						\
  (*--fixup) = ((SCHEME_OBJECT) location);				\
}

#define fasdump_normal_setup()						\
{									\
  Old = (OBJECT_ADDRESS (Temp));					\
  if (BROKEN_HEART_P (*Old))						\
    {									\
      (*Scan) = (MAKE_OBJECT_FROM_OBJECTS (Temp, (*Old)));		\
      continue;								\
    }									\
  New_Address = (MAKE_BROKEN_HEART (To_Address));			\
  fasdump_remember_to_fix (Old, (*Old));				\
}

#define fasdump_transport_end(length)					\
{									\
  To_Address += (length);						\
  if (To >= free_buffer_top)						\
    {									\
      To = (dump_and_reset_free_buffer (To, (&success)));		\
      if (!success)							\
	return (PRIM_INTERRUPT);					\
    }									\
}

#define fasdump_normal_transport(copy_code, length)			\
{									\
  copy_code;								\
  fasdump_transport_end (length);					\
}

#define fasdump_normal_end()						\
{									\
  (* (OBJECT_ADDRESS (Temp))) = New_Address;				\
  (*Scan) = (MAKE_OBJECT_FROM_OBJECTS (Temp, New_Address));		\
  continue;								\
}

#define fasdump_typeless_setup()					\
{									\
  Old = (SCHEME_ADDR_TO_ADDR (Temp));					\
  if (BROKEN_HEART_P (*Old))						\
    {									\
      (*Scan) = (ADDR_TO_SCHEME_ADDR (OBJECT_ADDRESS (*Old)));		\
      continue;								\
    }									\
  New_Address = ((SCHEME_OBJECT) To_Address);				\
  fasdump_remember_to_fix (Old, (*Old));				\
}

#define fasdump_typeless_end()						\
{									\
  (* (SCHEME_ADDR_TO_ADDR (Temp)))					\
    = (MAKE_BROKEN_HEART ((SCHEME_OBJECT *) New_Address));		\
  (*Scan) = (ADDR_TO_SCHEME_ADDR (New_Address));			\
  continue;								\
}

#define fasdump_typeless_pointer(copy_code, length)			\
{									\
  fasdump_typeless_setup ();						\
  fasdump_normal_transport (copy_code, length);				\
  fasdump_typeless_end ();						\
}

#define fasdump_compiled_entry() do					\
{									\
  compiled_code_present_p = true;					\
  Old = (OBJECT_ADDRESS (Temp));					\
  Compiled_BH (false, continue);					\
  {									\
    SCHEME_OBJECT * Saved_Old = Old;					\
									\
    fasdump_remember_to_fix (Old, (* Old));				\
    BCH_ALIGN_FLOAT (To_Address, To);					\
    New_Address = (MAKE_BROKEN_HEART (To_Address));			\
    copy_vector (&success);						\
    if (!success)							\
      return (PRIM_INTERRUPT);						\
    (* Saved_Old) = New_Address;					\
    Temp = RELOCATE_COMPILED (Temp, (OBJECT_ADDRESS (New_Address)),	\
			      Saved_Old);				\
    continue;								\
  }									\
} while (0)

#define fasdump_linked_operator() do					\
{									\
  Scan = ((SCHEME_OBJECT *) (word_ptr));				\
  BCH_EXTRACT_OPERATOR_LINKAGE_ADDRESS (Temp, Scan);			\
  fasdump_compiled_entry ();						\
  BCH_STORE_OPERATOR_LINKAGE_ADDRESS (Temp, Scan);			\
} while (0)

#define fasdump_manifest_closure() do					\
{									\
  Scan = ((SCHEME_OBJECT *) (word_ptr));				\
  BCH_EXTRACT_CLOSURE_ENTRY_ADDRESS (Temp, Scan);			\
  fasdump_compiled_entry ();						\
  BCH_STORE_CLOSURE_ENTRY_ADDRESS (Temp, Scan);				\
} while (0)

#define copy_quadruple()						\
{									\
  *To++ = *Old++;							\
  *To++ = *Old++;							\
  *To++ = *Old++;							\
  *To++ = *Old;								\
}

/* Transporting vectors is done in 3 parts:
   - Finish filling the current free buffer, dump it, and get a new one.
   - Dump the middle of the vector directly by bufferfulls.
   - Copy the end of the vector to the new buffer.
   The last piece of code is the only one executed when the vector does
   not overflow the current buffer.
*/

#define copy_vector(success)						\
{									\
  SCHEME_OBJECT * Saved_Scan = Scan;					\
  unsigned long real_length = (1 + (OBJECT_DATUM (*Old)));		\
									\
  To_Address += real_length;						\
  Scan = (To + real_length);						\
  if (Scan >= free_buffer_top)						\
  {									\
    unsigned long overflow;						\
									\
    overflow = (Scan - free_buffer_top);				\
    while (To != free_buffer_top)					\
      *To++ = *Old++;							\
    To = (dump_and_reset_free_buffer (0, success));			\
    real_length = (overflow >> gc_buffer_shift);			\
    if (real_length > 0)						\
      To = dump_free_directly (Old, real_length, success);		\
    Old += (real_length << gc_buffer_shift);				\
    Scan = To + (overflow & gc_buffer_mask);				\
  }									\
  while (To != Scan)							\
    *To++ = *Old++;							\
  Scan = Saved_Scan;							\
}

#define TRANSPORT_VECTOR(new_address, free, old_start, n_words)		\
{									\
  SCHEME_OBJECT * old_ptr = old_start;					\
  SCHEME_OBJECT * free_end = (free + n_words);				\
  if (free_end < free_buffer_top)					\
    while (free < free_end)						\
      (*free++) = (*old_ptr++);						\
  else									\
    {									\
      while (free < free_buffer_top)					\
	(*free++) = (*old_ptr++);					\
      free = (transport_vector_tail (free, free_end, old_ptr));		\
      if (free == 0)							\
	return (PRIM_INTERRUPT);					\
    }									\
}

static SCHEME_OBJECT *
DEFUN (transport_vector_tail, (free, free_end, tail),
       SCHEME_OBJECT * free AND
       SCHEME_OBJECT * free_end AND
       SCHEME_OBJECT * tail)
{
  unsigned long n_words = (free_end - free);
  Boolean success = 1;
  free = (dump_and_reset_free_buffer (free, (&success)));
  if (!success)
    return (0);
  {
    unsigned long n_blocks = (n_words >> gc_buffer_shift);
    if (n_blocks > 0)
      {
	free = (dump_free_directly (tail, n_blocks, (&success)));
	if (!success)
	  return (0);
	tail += (n_blocks << gc_buffer_shift);
      }
  }
  {
    SCHEME_OBJECT * free_end = (free + (n_words & gc_buffer_mask));
    while (free < free_end)
      (*free++) = (*tail++);
  }
  return (free);
}


/* A copy of gc_loop, with minor modifications. */

static long
DEFUN (dump_loop, (Scan, To_ptr, To_Address_ptr),
       SCHEME_OBJECT * Scan AND
       SCHEME_OBJECT ** To_ptr AND
       SCHEME_OBJECT ** To_Address_ptr)
{
  SCHEME_OBJECT * To = (*To_ptr);
  SCHEME_OBJECT * To_Address = (*To_Address_ptr);
  Boolean success = true;
  SCHEME_OBJECT * Old;
  SCHEME_OBJECT Temp;
  SCHEME_OBJECT New_Address;

  for ( ; (Scan != To); Scan += 1)
    {
      Temp = (*Scan);
      switch (OBJECT_TYPE (Temp))
	{
	case TC_BROKEN_HEART:
	  if ((OBJECT_DATUM (Temp)) == 0)
	    break;
	  if (Temp != (MAKE_POINTER_OBJECT (TC_BROKEN_HEART, Scan)))
	    {
	      sprintf (gc_death_message_buffer,
		       "dump_loop: broken heart (0x%lx) in scan",
		       Temp);
	      gc_death (TERM_BROKEN_HEART, gc_death_message_buffer, Scan, To);
	      /*NOTREACHED*/
	    }
	  if (Scan != scan_buffer_top)
	    goto end_dump_loop;
	  Scan = (dump_and_reload_scan_buffer (Scan, (&success)));
	  if (!success)
	    return (PRIM_INTERRUPT);
	  /* The -1 is here because of the Scan++ in the for header. */
	  Scan -= 1;
	  continue;

	case TC_STACK_ENVIRONMENT:
	case_Fasload_Non_Pointer:
	  break;

	case TC_CELL:
	  {
	    SCHEME_OBJECT * old_start = (OBJECT_ADDRESS (Temp));
	    if (BROKEN_HEART_P (*old_start))
	      (*Scan) = (MAKE_OBJECT_FROM_OBJECTS (Temp, (*old_start)));
	    else
	      {
		if ((fixup == fixup_buffer) && (!reset_fixes ()))
		  return (PRIM_INTERRUPT);
		(*--fixup) = (*old_start);
		(*--fixup) = ((SCHEME_OBJECT) old_start);
		(*To++) = (old_start[0]);
		if (To >= free_buffer_top)
		  {
		    To = (dump_and_reset_free_buffer (To, (&success)));
		    if (!success)
		      return (PRIM_INTERRUPT);
		  }
		(*Scan) = (OBJECT_NEW_ADDRESS (Temp, To_Address));
		(*old_start) = (MAKE_BROKEN_HEART (To_Address));;
		To_Address += 1;
	      }
	  }
	  break;

	case TC_ACCESS:
	case TC_ASSIGNMENT:
	case TC_COMBINATION_1:
	case TC_COMMENT:
	case TC_COMPLEX:
	case TC_DEFINITION:
	case TC_DELAY:
	case TC_DELAYED:
	case TC_DISJUNCTION:
	case TC_ENTITY:
	case TC_EXTENDED_PROCEDURE:
	case TC_IN_PACKAGE:
	case TC_LAMBDA:
	case TC_LEXPR:
	case TC_LIST:
	case TC_PCOMB1:
	case TC_PROCEDURE:
	case TC_RATNUM:
	case TC_SCODE_QUOTE:
	case TC_SEQUENCE_2:
	case TC_WEAK_CONS:
	transport_pair:
	  {
	    SCHEME_OBJECT * old_start = (OBJECT_ADDRESS (Temp));
	    if (BROKEN_HEART_P (*old_start))
	      (*Scan) = (MAKE_OBJECT_FROM_OBJECTS (Temp, (*old_start)));
	    else
	      {
		if ((fixup == fixup_buffer) && (!reset_fixes ()))
		  return (PRIM_INTERRUPT);
		(*--fixup) = (*old_start);
		(*--fixup) = ((SCHEME_OBJECT) old_start);
		(*To++) = (old_start[0]);
		(*To++) = (old_start[1]);
		if (To >= free_buffer_top)
		  {
		    To = (dump_and_reset_free_buffer (To, (&success)));
		    if (!success)
		      return (PRIM_INTERRUPT);
		  }
		(*Scan) = (OBJECT_NEW_ADDRESS (Temp, To_Address));
		(*old_start) = (MAKE_BROKEN_HEART (To_Address));;
		To_Address += 2;
	      }
	  }
	  break;;

	case TC_COMBINATION_2:
	case TC_CONDITIONAL:
	case TC_EXTENDED_LAMBDA:
	case TC_HUNK3_A:
	case TC_HUNK3_B:
	case TC_PCOMB2:
	case TC_SEQUENCE_3:
	  {
	    SCHEME_OBJECT * old_start = (OBJECT_ADDRESS (Temp));
	    if (BROKEN_HEART_P (*old_start))
	      (*Scan) = (MAKE_OBJECT_FROM_OBJECTS (Temp, (*old_start)));
	    else
	      {
		if ((fixup == fixup_buffer) && (!reset_fixes ()))
		  return (PRIM_INTERRUPT);
		(*--fixup) = (*old_start);
		(*--fixup) = ((SCHEME_OBJECT) old_start);
		(*To++) = (old_start[0]);
		(*To++) = (old_start[1]);
		(*To++) = (old_start[2]);
		if (To >= free_buffer_top)
		  {
		    To = (dump_and_reset_free_buffer (To, (&success)));
		    if (!success)
		      return (PRIM_INTERRUPT);
		  }
		(*Scan) = (OBJECT_NEW_ADDRESS (Temp, To_Address));
		(*old_start) = (MAKE_BROKEN_HEART (To_Address));;
		To_Address += 3;
	      }
	  }
	  break;

	case TC_QUAD:
	  {
	    SCHEME_OBJECT * old_start = (OBJECT_ADDRESS (Temp));
	    if (BROKEN_HEART_P (*old_start))
	      (*Scan) = (MAKE_OBJECT_FROM_OBJECTS (Temp, (*old_start)));
	    else
	      {
		if ((fixup == fixup_buffer) && (!reset_fixes ()))
		  return (PRIM_INTERRUPT);
		(*--fixup) = (*old_start);
		(*--fixup) = ((SCHEME_OBJECT) old_start);
		(*To++) = (old_start[0]);
		(*To++) = (old_start[1]);
		(*To++) = (old_start[2]);
		(*To++) = (old_start[3]);
		if (To >= free_buffer_top)
		  {
		    To = (dump_and_reset_free_buffer (To, (&success)));
		    if (!success)
		      return (PRIM_INTERRUPT);
		  }
		(*Scan) = (OBJECT_NEW_ADDRESS (Temp, To_Address));
		(*old_start) = (MAKE_BROKEN_HEART (To_Address));;
		To_Address += 4;
	      }
	  }
	  break;

	case TC_BIG_FIXNUM:
	case TC_CHARACTER_STRING:
	case TC_COMBINATION:
	case TC_CONTROL_POINT:
	case TC_NON_MARKED_VECTOR:
	case TC_PCOMB3:
	case TC_RECORD:
	case TC_VECTOR:
	case TC_VECTOR_16B:
	case TC_VECTOR_1B:
	  {
	    SCHEME_OBJECT * old_start = (OBJECT_ADDRESS (Temp));
	    if (BROKEN_HEART_P (*old_start))
	      (*Scan) = (MAKE_OBJECT_FROM_OBJECTS (Temp, (*old_start)));
	    else
	      {
		if ((fixup == fixup_buffer) && (!reset_fixes ()))
		  return (PRIM_INTERRUPT);
		(*--fixup) = (*old_start);
		(*--fixup) = ((SCHEME_OBJECT) old_start);
		{
		  unsigned long n_words = (1 + (OBJECT_DATUM (*old_start)));
		  TRANSPORT_VECTOR (To_Address, To, old_start, n_words);
		  (*Scan) = (OBJECT_NEW_ADDRESS (Temp, To_Address));
		  (*old_start) = (MAKE_BROKEN_HEART (To_Address));
		  To_Address += n_words;
		}
	      }
	  }
	  break;

	case TC_COMPILED_CODE_BLOCK:
	case TC_BIG_FLONUM:
	  {
	    SCHEME_OBJECT * old_start = (OBJECT_ADDRESS (Temp));
	    if (BROKEN_HEART_P (*old_start))
	      (*Scan) = (MAKE_OBJECT_FROM_OBJECTS (Temp, (*old_start)));
	    else
	      {
		BCH_ALIGN_FLOAT (To_Address, To);
		if ((fixup == fixup_buffer) && (!reset_fixes ()))
		  return (PRIM_INTERRUPT);
		(*--fixup) = (*old_start);
		(*--fixup) = ((SCHEME_OBJECT) old_start);
		{
		  unsigned long n_words = (1 + (OBJECT_DATUM (*old_start)));
		  TRANSPORT_VECTOR (To_Address, To, old_start, n_words);
		  (*Scan) = (OBJECT_NEW_ADDRESS (Temp, To_Address));
		  (*old_start) = (MAKE_BROKEN_HEART (To_Address));
		  To_Address += n_words;
		}
	      }
	  }
	  break;

	case TC_MANIFEST_NM_VECTOR:
	case TC_MANIFEST_SPECIAL_NM_VECTOR:
	  Scan += (1 + (OBJECT_DATUM (Temp)));
	  if (Scan >= scan_buffer_top)
	    {
	      Scan = (dump_and_reload_scan_buffer (Scan, (&success)));
	      if (!success)
		return (PRIM_INTERRUPT);
	    }
	  Scan -= 1;
	  break;

	case TC_PRIMITIVE:
	case TC_PCOMB0:
	  (*Scan) = (dump_renumber_primitive (Temp));
	  break;

	case_compiled_entry_point:
	  fasdump_compiled_entry ();
	  (*Scan) = Temp;
	  break;

	case TC_LINKAGE_SECTION:
	  {
	    switch (READ_LINKAGE_KIND (Temp))
	      {
	      case REFERENCE_LINKAGE_KIND:
	      case ASSIGNMENT_LINKAGE_KIND:
		{
		  /* count typeless pointers to quads follow. */

		  long count;
		  long max_count, max_here;

		  Scan++;
		  max_here = (scan_buffer_top - Scan);
		  max_count = (READ_CACHE_LINKAGE_COUNT (Temp));
		  while (max_count != 0)
		    {
		      count = ((max_count > max_here) ? max_here : max_count);
		      max_count -= count;
		      for ( ; --count >= 0; Scan += 1)
			{
			  Temp = (* Scan);
			  fasdump_typeless_pointer (copy_quadruple (), 4);
			}
		      if (max_count != 0)
			{
			  /* We stopped because we needed to relocate too many. */
			  Scan = (dump_and_reload_scan_buffer (Scan, 0));
			  max_here = gc_buffer_size;
			}
		    }
		  /* The + & -1 are here because of the Scan++ in the for header. */
		  Scan -= 1;
		  break;
		}

	      case OPERATOR_LINKAGE_KIND:
	      case GLOBAL_OPERATOR_LINKAGE_KIND:
		{
		  /* Operator linkage */

		  long count;
		  char *word_ptr, *next_ptr;
		  long overflow;

		  word_ptr = (FIRST_OPERATOR_LINKAGE_ENTRY (Scan));
		  if (! (word_ptr > ((char *) scan_buffer_top)))
		    BCH_START_OPERATOR_RELOCATION (Scan);
		  else
		    {
		      overflow = (word_ptr - ((char *) Scan));
		      extend_scan_buffer (word_ptr, To);
		      BCH_START_OPERATOR_RELOCATION (Scan);
		      word_ptr = (end_scan_buffer_extension (word_ptr));
		      Scan = ((SCHEME_OBJECT *) (word_ptr - overflow));
		    }

		  count = (READ_OPERATOR_LINKAGE_COUNT (Temp));
		  overflow = ((END_OPERATOR_LINKAGE_AREA (Scan, count)) -
			      scan_buffer_top);

		  for (next_ptr = (NEXT_LINKAGE_OPERATOR_ENTRY (word_ptr));
		       (--count >= 0);
		       word_ptr = next_ptr,
		       next_ptr = (NEXT_LINKAGE_OPERATOR_ENTRY (word_ptr)))
		    {
		      if (! (next_ptr > ((char *) scan_buffer_top)))
			fasdump_linked_operator ();
		      else
			{
			  extend_scan_buffer (next_ptr, To);
			  fasdump_linked_operator ();
			  next_ptr = (end_scan_buffer_extension (next_ptr));
			  overflow -= gc_buffer_size;
			}
		    }
		  Scan = (scan_buffer_top + overflow);
		  BCH_END_OPERATOR_RELOCATION (Scan);
		  break;
		}

	      case CLOSURE_PATTERN_LINKAGE_KIND:
		Scan += (1 + (READ_CACHE_LINKAGE_COUNT (Temp)));
		if (Scan >= scan_buffer_top)
		  {
		    Scan = (dump_and_reload_scan_buffer (Scan, (&success)));
		    if (!success)
		      return (PRIM_INTERRUPT);
		  }
		Scan -= 1;
		break;

	      default:
		gc_death (TERM_EXIT,
			  "fasdump: Unknown compiler linkage kind.",
			  Scan, Free);
		/*NOTREACHED*/
	      }
	    break;
	  }

	case TC_MANIFEST_CLOSURE:
	  {
	    long count;
	    char * word_ptr;
	    char * end_ptr;

	    Scan += 1;

	    /* Is there enough space to read the count? */

	    end_ptr = (((char *) Scan) + (2 * (sizeof (format_word))));
	    if (end_ptr > ((char *) scan_buffer_top))
	      {
		long dw;

		extend_scan_buffer (end_ptr, To);
		BCH_START_CLOSURE_RELOCATION (Scan - 1);
		count = (MANIFEST_CLOSURE_COUNT (Scan));
		word_ptr = (FIRST_MANIFEST_CLOSURE_ENTRY (Scan));
		dw = (word_ptr - end_ptr);
		end_ptr = (end_scan_buffer_extension (end_ptr));
		word_ptr = (end_ptr + dw);
		Scan = ((SCHEME_OBJECT *) (end_ptr - (2 * (sizeof (format_word)))));
	      }
	    else
	      {
		BCH_START_CLOSURE_RELOCATION (Scan - 1);
		count = (MANIFEST_CLOSURE_COUNT (Scan));
		word_ptr = (FIRST_MANIFEST_CLOSURE_ENTRY (Scan));
	      }
	    end_ptr = ((char *) (MANIFEST_CLOSURE_END (Scan, count)));

	    for ( ; ((--count) >= 0);
		 (word_ptr = (NEXT_MANIFEST_CLOSURE_ENTRY (word_ptr))))
	      {
		if (! ((CLOSURE_ENTRY_END (word_ptr)) > ((char *) scan_buffer_top)))
		  fasdump_manifest_closure ();
		else
		  {
		    char * entry_end;
		    long de, dw;

		    entry_end = (CLOSURE_ENTRY_END (word_ptr));
		    de = (end_ptr - entry_end);
		    dw = (entry_end - word_ptr);
		    extend_scan_buffer (entry_end, To);
		    fasdump_manifest_closure ();
		    entry_end = (end_scan_buffer_extension (entry_end));
		    word_ptr = (entry_end - dw);
		    end_ptr = (entry_end + de);
		  }
	      }
	    Scan = ((SCHEME_OBJECT *) (end_ptr));
	    BCH_END_CLOSURE_RELOCATION (Scan);
	    break;
	  }

	case TC_REFERENCE_TRAP:
	  if ((OBJECT_DATUM (Temp)) <= TRAP_MAX_IMMEDIATE)
	    /* It is a non pointer. */
	    break;
	  goto transport_pair;
	  /* It is a pair, fall through. */

	case TC_INTERNED_SYMBOL:
	  {
	    fasdump_normal_setup ();
	    (* To++) = (* Old);
	    (* To++) = BROKEN_HEART_ZERO;
	    fasdump_transport_end (2);
	    fasdump_normal_end ();
	  }

	case TC_UNINTERNED_SYMBOL:
	  {
	    fasdump_normal_setup ();
	    (* To++) = (* Old);
	    (* To++) = UNBOUND_OBJECT;
	    fasdump_transport_end (2);
	    fasdump_normal_end ();
	  }

	case TC_VARIABLE:
	  {
	    fasdump_normal_setup ();
	    (* To++) = (* Old);
	    (* To++) = UNCOMPILED_VARIABLE;
	    (* To++) = SHARP_F;
	    fasdump_transport_end (3);
	    fasdump_normal_end ();
	  }

	case TC_ENVIRONMENT:
	  /* Make fasdump fail */
	  return (ERR_FASDUMP_ENVIRONMENT);

	case TC_FUTURE:
	  {
	    SCHEME_OBJECT * old_start = (OBJECT_ADDRESS (Temp));
	    if (BROKEN_HEART_P (*old_start))
	      (*Scan) = (MAKE_OBJECT_FROM_OBJECTS (Temp, (*old_start)));
	    else
	      {
		if ((fixup == fixup_buffer) && (!reset_fixes ()))
		  return (PRIM_INTERRUPT);
		(*--fixup) = (*old_start);
		(*--fixup) = ((SCHEME_OBJECT) old_start);
		if (Future_Spliceable (Temp))
		  {
		    (*Scan) = (Future_Value (Temp));
		    Scan -= 1;
		  }
		else
		  {
		    unsigned long n_words = (1 + (OBJECT_DATUM (*old_start)));
		    TRANSPORT_VECTOR (To_Address, To, old_start, n_words);
		    (*Scan) = (OBJECT_NEW_ADDRESS (Temp, To_Address));
		    (*old_start) = (MAKE_BROKEN_HEART (To_Address));
		    To_Address += n_words;
		  }
	      }
	  }
	  break;;

	default:
	  GC_BAD_TYPE ("dump_loop", Temp);
	  break;
	}
    }

 end_dump_loop:

  (*To_ptr) = To;
  (*To_Address_ptr) = To_Address;
  return (PRIM_DONE);
}
