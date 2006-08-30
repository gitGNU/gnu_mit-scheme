/* -*-C-*-

$Id: gccode.h,v 9.60.2.6 2006/08/30 20:03:37 cph Exp $

Copyright 1986,1987,1988,1989,1991,1992 Massachusetts Institute of Technology
Copyright 1993,1995,1997,2000,2001,2002 Massachusetts Institute of Technology
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

/* This file contains the macros for use in code which does GC-like
   loops over memory.  It is only included in a few files, unlike
   gc.h which contains general purpose macros and constants. */

#ifndef SCM_GCCODE_H
#define SCM_GCCODE_H 1

#include "gc.h"
#include "cmpgc.h"

#ifdef ENABLE_DEBUGGING_TOOLS
#  ifndef ENABLE_GC_DEBUGGING_TOOLS
#    define ENABLE_GC_DEBUGGING_TOOLS
#  endif
#endif

typedef struct gc_table_s gc_table_t;

typedef struct
{
  gc_table_t * table;		/* gc dispatch table */
  SCHEME_OBJECT * from_start;	/* start of 'from' space */
  SCHEME_OBJECT * from_end;	/* end of 'from' space */
  SCHEME_OBJECT ** pto;		/* pointer to 'to' ptr */
  SCHEME_OBJECT ** pto_end;	/* ptr to end of 'to' space ptr */
  SCHEME_OBJECT * scan;		/* scan value where object found */
  SCHEME_OBJECT object;		/* original object being processed */
} gc_ctx_t;

#define GCTX_TABLE(ctx) ((ctx)->table)
#define GCTX_FROM_START(ctx) ((ctx)->from_start)
#define GCTX_FROM_END(ctx) ((ctx)->from_end)
#define GCTX_PTO(ctx) ((ctx)->pto)
#define GCTX_PTO_END(ctx) ((ctx)->pto_end)
#define GCTX_SCAN(ctx) ((ctx)->scan)
#define GCTX_OBJECT(ctx) ((ctx)->object)

typedef SCHEME_OBJECT * gc_handler_t
  (SCHEME_OBJECT *, SCHEME_OBJECT, gc_ctx_t *);

#define DEFINE_GC_HANDLER(handler_name)					\
SCHEME_OBJECT *								\
handler_name (SCHEME_OBJECT * scan, SCHEME_OBJECT object, gc_ctx_t * ctx)

typedef SCHEME_OBJECT gc_tuple_handler_t
  (SCHEME_OBJECT, unsigned int, gc_ctx_t *);

#define DEFINE_GC_TUPLE_HANDLER(handler_name)				\
SCHEME_OBJECT								\
handler_name (SCHEME_OBJECT tuple, unsigned int n_words, gc_ctx_t * ctx)

typedef SCHEME_OBJECT gc_vector_handler_t
  (SCHEME_OBJECT, bool, gc_ctx_t *);

#define DEFINE_GC_VECTOR_HANDLER(handler_name)				\
SCHEME_OBJECT								\
handler_name (SCHEME_OBJECT vector, bool align_p, gc_ctx_t * ctx)

typedef SCHEME_OBJECT gc_object_handler_t
  (SCHEME_OBJECT, gc_ctx_t *);

#define DEFINE_GC_OBJECT_HANDLER(handler_name)				\
SCHEME_OBJECT								\
handler_name (SCHEME_OBJECT object, gc_ctx_t * ctx)

typedef SCHEME_OBJECT * gc_precheck_from_t (SCHEME_OBJECT *, gc_ctx_t *);

struct gc_table_s
{
  gc_handler_t * handlers [N_TYPE_CODES];
  gc_tuple_handler_t * tuple_handler;
  gc_vector_handler_t * vector_handler;
  gc_object_handler_t * cc_entry_handler;
  gc_object_handler_t * weak_pair_handler;
  gc_precheck_from_t * precheck_from;
};

#define GCT_ENTRY(table, type) (((table)->handlers) [(type)])
#define GCT_TUPLE(table) ((table)->tuple_handler)
#define GCT_VECTOR(table) ((table)->vector_handler)
#define GCT_CC_ENTRY(table) ((table)->cc_entry_handler)
#define GCT_WEAK_PAIR(table) ((table)->weak_pair_handler)
#define GCT_PRECHECK_FROM(table) ((table)->precheck_from)

#define GC_HANDLE_TUPLE(object, n_words, ctx)				\
  ((* (GCT_TUPLE ((ctx)->table))) ((object), (n_words), (ctx)))

#define GC_HANDLE_VECTOR(object, align_p, ctx)				\
  ((* (GCT_VECTOR ((ctx)->table))) ((object), (align_p), (ctx)))

#define GC_HANDLE_CC_ENTRY(object, ctx)					\
  ((* (GCT_CC_ENTRY ((ctx)->table))) ((object), (ctx)))

#define GC_PRECHECK_FROM(from, ctx)					\
  ((* (GCT_PRECHECK_FROM ((ctx)->table))) ((from), (ctx)))

extern gc_handler_t gc_handle_non_pointer;
extern gc_handler_t gc_handle_cell;
extern gc_handler_t gc_handle_pair;
extern gc_handler_t gc_handle_triple;
extern gc_handler_t gc_handle_quadruple;
extern gc_handler_t gc_handle_cc_entry;
extern gc_handler_t gc_handle_aligned_vector;
extern gc_handler_t gc_handle_unaligned_vector;
extern gc_handler_t gc_handle_broken_heart;
extern gc_handler_t gc_handle_nmv;
extern gc_handler_t gc_handle_reference_trap;
extern gc_handler_t gc_handle_linkage_section;
extern gc_handler_t gc_handle_manifest_closure;
extern gc_handler_t gc_handle_undefined;
extern gc_precheck_from_t gc_precheck_from;

extern void initialize_gc_table
  (gc_table_t *, gc_tuple_handler_t *, gc_vector_handler_t *,
   gc_object_handler_t *, gc_object_handler_t *, gc_precheck_from_t *);

extern void initialize_weak_chain (void);
extern void update_weak_pointers (void);

extern void collect_gc_objects_referencing (SCHEME_OBJECT, SCHEME_OBJECT);
extern void initialize_gc_objects_referencing (void);
extern void scan_gc_objects_referencing (SCHEME_OBJECT *, SCHEME_OBJECT *);

extern void run_gc_loop (SCHEME_OBJECT *, SCHEME_OBJECT **, gc_ctx_t *);
extern bool address_in_from_space_p (void * addr, gc_ctx_t * ctx);

extern SCHEME_OBJECT * gc_transport_words
  (SCHEME_OBJECT *, unsigned long, bool, gc_ctx_t *);

extern SCHEME_OBJECT gc_transport_weak_pair (SCHEME_OBJECT, gc_ctx_t *);

extern void std_gc_loop
  (SCHEME_OBJECT *, SCHEME_OBJECT **,
   SCHEME_OBJECT **, SCHEME_OBJECT **,
   SCHEME_OBJECT *, SCHEME_OBJECT *);
extern void std_gc_scan (SCHEME_OBJECT *, SCHEME_OBJECT *, gc_ctx_t *);

typedef void gc_abort_handler_t (void);
extern gc_abort_handler_t * gc_abort_handler NORETURN;

extern void std_gc_death (gc_ctx_t * ctx, const char *, ...)
  ATTRIBUTE ((__noreturn__, __format__ (__printf__, 2, 3)));
extern void gc_no_cc_support (gc_ctx_t * ctx) NORETURN;
extern void gc_bad_type (SCHEME_OBJECT, gc_ctx_t * ctx) NORETURN;

#endif /* not SCM_GCCODE_H */
