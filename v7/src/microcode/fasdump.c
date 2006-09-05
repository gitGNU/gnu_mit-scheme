/* -*-C-*-

$Id: fasdump.c,v 9.68.2.9 2006/09/05 03:14:26 cph Exp $

Copyright 1986,1987,1988,1989,1990,1991 Massachusetts Institute of Technology
Copyright 1992,1993,1996,1997,2000,2001 Massachusetts Institute of Technology
Copyright 2005,2006 Massachusetts Institute of Technology

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

/* This file contains code for fasdump and dump-band. */

#include "scheme.h"
#include "prims.h"
#include "osscheme.h"
#include "osio.h"
#include "osfile.h"
#include "osfs.h"
#define In_Fasdump
#include "gccode.h"
#include "trap.h"
#include "lookup.h"
#include "fasl.h"
#include <setjmp.h>

typedef enum { FE_ERROR, FE_DUMP, FE_DROP_CC } env_mode_t;

typedef struct
{
  const char * filename;
  fasl_file_handle_t handle;
} fasl_file_info_t;

static void close_fasl_file (void *);

static fasl_header_t fasl_header;
static fasl_header_t * fh;
static env_mode_t current_env_mode;
static prim_renumber_t * current_pr;
static bool cc_seen_p;

static gc_table_t * fasdump_table (void);
static gc_handler_t handle_primitive;
static gc_handler_t handle_manifest_closure;
static gc_handler_t handle_linkage_section;
static gc_handler_t handle_symbol;
static gc_handler_t handle_broken_heart;
static gc_handler_t handle_variable;
static gc_handler_t handle_environment;

static gc_object_handler_t fasdump_cc_entry;
static gc_object_handler_t fasdump_weak_pair;
static gc_precheck_from_t fasdump_precheck_from;
static gc_transport_words_t fasdump_transport_words;

static void initialize_fixups (void);
static void add_fixup (SCHEME_OBJECT *);
static void run_fixups (void *);

static void initialize_fasl_header (bool);
static bool write_fasl_file (SCHEME_OBJECT *, fasl_file_handle_t);

/* FASDUMP:

   In order to dump an object it must be traced (as in a garbage
   collection), but with some significant differences.  First, the
   copy must have the global value cell of symbols set to UNBOUND.
   Second, and worse, all the broken hearts created during the process
   must be restored to their original values.  This last is done by
   growing the copy of the object in the bottom of spare heap, keeping
   track of the locations of broken hearts and original contents at
   the top of the spare heap.  */

DEFINE_PRIMITIVE ("PRIMITIVE-FASDUMP", Prim_prim_fasdump, 3, 3,
		  "(OBJECT NAMESTRING FLAG)\n\
Writes a binary representation of OBJECT to the file NAMESTRING.\n\
Returns #T if the operation is successful, or #F otherwise.\n\
\n\
FLAG specifies how to handle environment objects that OBJECT points\n\
to: #F means generate an error; #T means write them as ordinary\n\
objects; any other value is like #F except that environments pointed\n\
at by compiled code are ignored (and discarded).")
{
  fasl_file_info_t ff_info;
  SCHEME_OBJECT * new_heap_start;
  SCHEME_OBJECT * prim_table_start;
  unsigned long prim_table_length;
  bool ok;
  PRIMITIVE_HEADER (3);

  transaction_begin ();		/* 1 */
  (ff_info . filename) = (STRING_ARG (2));
  if (!open_fasl_output_file ((ff_info . filename), (& (ff_info . handle))))
    error_bad_range_arg (2);
  transaction_record_action (tat_always, close_fasl_file, (&ff_info));

  open_tospace (heap_start);
  initialize_fixups ();

  new_heap_start = (get_newspace_ptr ());
  add_to_tospace (ARG_REF (1));

  transaction_begin ();		/* 2 */

  current_gc_table = (fasdump_table ());
  current_env_mode
    = (((ARG_REF (3)) == SHARP_F)
       ? FE_ERROR
       : ((ARG_REF (3)) == SHARP_T)
       ? FE_DUMP
       : FE_DROP_CC);
  current_pr = (make_prim_renumber ());
  cc_seen_p = false;
  gc_scan_tospace (new_heap_start, 0);

  prim_table_start = (get_newspace_ptr ());
  prim_table_length = (renumbered_primitives_export_length (current_pr));
  increment_tospace_ptr (prim_table_length);
  export_renumbered_primitives
    ((newspace_to_tospace (prim_table_start)), current_pr);

  transaction_commit ();	/* 2 */

  initialize_fasl_header (cc_seen_p);
  (FASLHDR_BAND_P (fh)) = false;
  (FASLHDR_CONSTANT_START (fh)) = new_heap_start;
  (FASLHDR_CONSTANT_END (fh)) = new_heap_start;
  (FASLHDR_HEAP_START (fh)) = new_heap_start;
  (FASLHDR_HEAP_END (fh)) = prim_table_start;
  (FASLHDR_ROOT_POINTER (fh)) = new_heap_start;
  (FASLHDR_N_PRIMITIVES (fh)) = (current_pr->next_code);
  (FASLHDR_PRIMITIVE_TABLE_SIZE (fh)) = prim_table_length;

  ok = ((write_fasl_header (fh, (ff_info . handle)))
	&& (save_tospace_to_fasl_file (ff_info . handle)));
  transaction_commit ();	/* 1 */

  PRIMITIVE_RETURN (BOOLEAN_TO_OBJECT (ok));
}

static void
close_fasl_file (void * p)
{
  fasl_file_info_t * ff_info = p;
  if (!close_fasl_output_file (ff_info->handle))
    OS_file_remove (ff_info->filename);
}

static gc_table_t *
fasdump_table (void)
{
  static bool initialized_p = false;
  static gc_table_t table;

  if (!initialized_p)
    {
      initialize_gc_table ((&table), true);

      (GCT_CC_ENTRY ((&table))) = fasdump_cc_entry;
      (GCT_WEAK_PAIR ((&table))) = fasdump_weak_pair;
      (GCT_PRECHECK_FROM ((&table))) = fasdump_precheck_from;
      (GCT_TRANSPORT_WORDS ((&table))) = fasdump_transport_words;

      (GCT_ENTRY ((&table), TC_PRIMITIVE)) = handle_primitive;
      (GCT_ENTRY ((&table), TC_PCOMB0)) = handle_primitive;
      (GCT_ENTRY ((&table), TC_MANIFEST_CLOSURE)) = handle_manifest_closure;
      (GCT_ENTRY ((&table), TC_LINKAGE_SECTION)) = handle_linkage_section;
      (GCT_ENTRY ((&table), TC_INTERNED_SYMBOL)) = handle_symbol;
      (GCT_ENTRY ((&table), TC_BROKEN_HEART)) = handle_broken_heart;
      (GCT_ENTRY ((&table), TC_UNINTERNED_SYMBOL)) = handle_symbol;
      (GCT_ENTRY ((&table), TC_VARIABLE)) = handle_variable;
      (GCT_ENTRY ((&table), TC_ENVIRONMENT)) = handle_environment;

      initialized_p = true;
    }
  return (&table);
}

static
DEFINE_GC_OBJECT_HANDLER (fasdump_cc_entry)
{
#ifdef CC_SUPPORT_P
  SCHEME_OBJECT * old_addr;
  SCHEME_OBJECT * new_addr;
  unsigned long length;
  SCHEME_OBJECT * eptr;

  cc_seen_p = true;
  old_addr = (cc_entry_to_block_address (object));
  if (old_addr == (OBJECT_ADDRESS (compiler_utilities)))
    return (object);
  new_addr = (GC_PRECHECK_FROM (old_addr));
  if (new_addr == 0)
    {
      length = (OBJECT_DATUM (*old_addr));
      new_addr = (GC_TRANSPORT_WORDS (old_addr, (1 + length), true));
      eptr = (new_addr + length);
      if ((current_env_mode == FE_DROP_CC)
	  && ((OBJECT_TYPE (read_tospace (eptr))) == TC_ENVIRONMENT))
	write_tospace (eptr, SHARP_F);
    }
  return (CC_ENTRY_NEW_BLOCK (object, new_addr, old_addr));
#else
  gc_no_cc_support ();
  return (object);
#endif
}

static
DEFINE_GC_OBJECT_HANDLER (fasdump_weak_pair)
{
  return (GC_HANDLE_TUPLE (object, 2));
}

static
DEFINE_GC_PRECHECK_FROM (fasdump_precheck_from)
{
  return ((BROKEN_HEART_P (*from)) ? (OBJECT_ADDRESS (*from)) : 0);
}

static
DEFINE_GC_TRANSPORT_WORDS (fasdump_transport_words)
{
  /* Signal error here if insufficient space -- otherwise
     gc_transport_words() might terminate the microcode.  */
  if (!tospace_available_p (n_words))
    signal_error_from_primitive (ERR_FASDUMP_OBJECT_TOO_LARGE);
  add_fixup (from);
  return (gc_transport_words (from, n_words, align_p));
}

static
DEFINE_GC_HANDLER (handle_primitive)
{
  (*scan) = (renumber_primitive (object, current_pr));
  return (scan + 1);
}

static
DEFINE_GC_HANDLER (handle_manifest_closure)
{
  cc_seen_p = true;
  return (gc_handle_manifest_closure (scan, object));
}

static
DEFINE_GC_HANDLER (handle_linkage_section)
{
  cc_seen_p = true;
  return (gc_handle_linkage_section (scan, object));
}

static
DEFINE_GC_HANDLER (handle_symbol)
{
  SCHEME_OBJECT * from = (OBJECT_ADDRESS (object));
  SCHEME_OBJECT * new_address = (GC_PRECHECK_FROM (from));
  if (new_address == 0)
    {
      new_address = (GC_TRANSPORT_WORDS (from, 2, false));
      write_tospace ((new_address + SYMBOL_GLOBAL_VALUE),
		     (((OBJECT_TYPE (object)) == TC_INTERNED_SYMBOL)
		      ? BROKEN_HEART_ZERO
		      : UNBOUND_OBJECT));
    }
  (*scan) = (OBJECT_NEW_ADDRESS (object, new_address));
  return (scan + 1);
}

static
DEFINE_GC_HANDLER (handle_broken_heart)
{
  return
    (((OBJECT_DATUM (object)) == 0)
     ? (scan + 1)
     : (gc_handle_broken_heart (scan, object)));
}

static
DEFINE_GC_HANDLER (handle_variable)
{
  SCHEME_OBJECT * from = (OBJECT_ADDRESS (object));
  SCHEME_OBJECT * new_address = (GC_PRECHECK_FROM (from));
  if (new_address == 0)
    {
      new_address = (GC_TRANSPORT_WORDS (from, 3, false));
      write_tospace ((new_address + 1), UNCOMPILED_VARIABLE);
      write_tospace ((new_address + 2), SHARP_F);
    }
  (*scan) = (OBJECT_NEW_ADDRESS (object, new_address));
  return (scan + 1);
}

static
DEFINE_GC_HANDLER (handle_environment)
{
  if (current_env_mode != FE_DUMP)
    signal_error_from_primitive (ERR_FASDUMP_ENVIRONMENT);
  (*scan) = (GC_HANDLE_VECTOR (object, false));
  return (scan + 1);
}

typedef struct
{
  SCHEME_OBJECT * addr;
  SCHEME_OBJECT object;
} fixup_t;

static fixup_t * fixups_start;
static fixup_t * fixups_next;
static fixup_t * fixups_end;

static void
initialize_fixups (void)
{
  fixup_t * data = (OS_malloc (64 * (sizeof (fixup_t))));
  fixups_start = data;
  fixups_next = data;
  fixups_end = (data + 64);
  transaction_record_action (tat_always, run_fixups, 0);
}

static void
add_fixup (SCHEME_OBJECT * addr)
{
  if (fixups_next >= fixups_end)
    {
      unsigned long n = ((fixups_end - fixups_start) * 2);
      unsigned long m = (fixups_next - fixups_start);
      fixup_t * data = (OS_realloc (fixups_start, (n * (sizeof (fixup_t)))));
      fixups_start = data;
      fixups_next = (data + m);
      fixups_end = (data + n);
    }
  (fixups_next -> addr) = addr;
  (fixups_next -> object) = (*addr);
  fixups_next += 1;
}

static void
run_fixups (void * p)
{
  fixup_t * scan = fixups_start;
  while (scan < fixups_next)
    {
      (* (scan->addr)) = (scan->object);
      scan += 1;
    }
  OS_free (fixups_start);
}

DEFINE_PRIMITIVE ("DUMP-BAND", Prim_band_dump, 2, 2,
		  "(PROCEDURE NAMESTRING)\n\
Saves an image of the current world to the file NAMESTRING.\n\
When the file is reloaded, PROCEDURE is called with an argument of #F.")
{
  SCHEME_OBJECT * to = Free;
  SCHEME_OBJECT * prim_table_start;
  bool result;
  PRIMITIVE_HEADER (2);

  CHECK_ARG (1, INTERPRETER_APPLICABLE_P);
  CHECK_ARG (2, STRING_P);

  Primitive_GC_If_Needed (5);
  initialize_fasl_header (true);
  (FASLHDR_BAND_P (fh)) = true;
  {
    SCHEME_OBJECT comb;
    SCHEME_OBJECT root;

    comb = (MAKE_POINTER_OBJECT (TC_COMBINATION_1, to));
    (to[COMB_1_FN]) = (ARG_REF (1));
    (to[COMB_1_ARG_1]) = SHARP_F;
    to += 2;

    root = (MAKE_POINTER_OBJECT (TC_LIST, to));
    (*to++) = comb;
    (*to++) = compiler_utilities;

    (FASLHDR_ROOT_POINTER (fh)) = to;
    (*to++) = root;
  }

  prim_table_start = to;
  (FASLHDR_N_PRIMITIVES (fh)) = MAX_PRIMITIVE;
  (FASLHDR_PRIMITIVE_TABLE_SIZE (fh)) = (primitive_table_export_length ());
  to += (FASLHDR_PRIMITIVE_TABLE_SIZE (fh));
  if (to > heap_end)
    result = false;
  else
    {
      const char * filename = (STRING_POINTER (ARG_REF (2)));
      SCHEME_OBJECT * faligned_heap = heap_start;
      SCHEME_OBJECT * faligned_constant = constant_start;
      fasl_file_handle_t handle;

      export_primitive_table (prim_table_start);

      while (!FLOATING_ALIGNED_P (faligned_heap))
	faligned_heap += 1;

      while (!FLOATING_ALIGNED_P (faligned_constant))
	faligned_constant += 1;

      (FASLHDR_HEAP_START (fh)) = faligned_heap;
      (FASLHDR_HEAP_END (fh)) = to;
      (FASLHDR_CONSTANT_START (fh)) = faligned_constant;
      (FASLHDR_CONSTANT_END (fh)) = constant_alloc_next;

      OS_file_remove_link (filename);
      if (!open_fasl_output_file (filename, (&handle)))
	error_bad_range_arg (2);

      result = (write_fasl_file (prim_table_start, handle));

      if (!close_fasl_output_file (handle))
	OS_file_remove (filename);
    }
  PRIMITIVE_RETURN (BOOLEAN_TO_OBJECT (result));
}

static void
initialize_fasl_header (bool cc_p)
{
  fh = (&fasl_header);
  (FASLHDR_VERSION (fh)) = CURRENT_FASL_VERSION;
  (FASLHDR_ARCH (fh)) = CURRENT_FASL_ARCH;

#ifdef HEAP_IN_LOW_MEMORY
  (FASLHDR_MEMORY_BASE (fh)) = 0;
#else
  (FASLHDR_MEMORY_BASE (fh)) = memory_block_start;
#endif
  (FASLHDR_HEAP_RESERVED (fh)) = heap_reserved;

  (FASLHDR_STACK_START (fh)) = stack_start;
  (FASLHDR_STACK_END (fh)) = stack_end;

  if (cc_p)
    {
      (FASLHDR_CC_VERSION (fh)) = compiler_interface_version;
      (FASLHDR_CC_ARCH (fh)) = compiler_processor_type;
      (FASLHDR_UTILITIES_VECTOR (fh)) = compiler_utilities;
    }
  else
    {
      (FASLHDR_CC_VERSION (fh)) = 0;
      (FASLHDR_CC_ARCH (fh)) = COMPILER_NONE_TYPE;
      (FASLHDR_UTILITIES_VECTOR (fh)) = SHARP_F;
    }
}

static bool
write_fasl_file (SCHEME_OBJECT * prim_table_start, fasl_file_handle_t handle)
{
  return
    ((write_fasl_header (fh, handle))
     && (write_to_fasl_file ((FASLHDR_HEAP_START (fh)),
			     (FASLHDR_HEAP_SIZE (fh)),
			     handle))
     && (write_to_fasl_file ((FASLHDR_CONSTANT_START (fh)),
			     (FASLHDR_CONSTANT_SIZE (fh)),
			     handle))
     && (write_to_fasl_file (prim_table_start,
			     (FASLHDR_PRIMITIVE_TABLE_SIZE (fh)),
			     handle)));
}
