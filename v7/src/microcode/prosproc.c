/* -*-C-*-

$Id: prosproc.c,v 1.14 1995/01/05 23:48:27 cph Exp $

Copyright (c) 1990-95 Massachusetts Institute of Technology

This material was developed by the Scheme project at the Massachusetts
Institute of Technology, Department of Electrical Engineering and
Computer Science.  Permission to copy this software, to redistribute
it, and to use it for any purpose is granted, subject to the following
restrictions and understandings.

1. Any copy made of this software must include this copyright notice
in full.

2. Users of this software agree to make their best efforts (a) to
return to the MIT Scheme project any improvements or extensions that
they make, so that these may be included in future releases; and (b)
to inform MIT of noteworthy uses of this software.

3. All materials developed as a consequence of the use of this
software shall duly acknowledge such use, in accordance with the usual
standards of acknowledging credit in academic research.

4. MIT has made no warrantee or representation that the operation of
this software will be error-free, and MIT is under no obligation to
provide any services, by way of maintenance, update, or otherwise.

5. In conjunction with products arising from the use of this material,
there shall be no use of the name of the Massachusetts Institute of
Technology nor of any adaptation thereof in any advertising,
promotional, or sales literature without prior written consent from
MIT in each case. */

/* Primitives for subprocess control. */

#include "scheme.h"
#include "prims.h"
#include "osproc.h"

extern Tchannel EXFUN (arg_channel, (int));
static int EXFUN (string_vector_p, (SCHEME_OBJECT vector));
static char ** EXFUN (convert_string_vector, (SCHEME_OBJECT vector));

static Tprocess
DEFUN (arg_process, (argument_number), int argument_number)
{
  Tprocess process =
    (arg_index_integer (argument_number, OS_process_table_size));
  if (! (OS_process_valid_p (process)))
    error_bad_range_arg (argument_number);
  return (process);
}

#define PROCESS_CHANNEL_ARG(arg, type, channel)				\
{									\
  if ((ARG_REF (arg)) == SHARP_F)					\
    (type) = process_channel_type_none;					\
  else if ((ARG_REF (arg)) == (LONG_TO_FIXNUM (-1)))			\
    (type) = process_channel_type_inherit;				\
  else if ((ARG_REF (arg)) == (LONG_TO_FIXNUM (-2)))			\
    {									\
      if (ctty_type != process_ctty_type_explicit)			\
	error_bad_range_arg (arg);					\
      (type) = process_channel_type_ctty;				\
    }									\
  else									\
    {									\
      (type) = process_channel_type_explicit;				\
      (channel) = (arg_channel (arg));					\
    }									\
}

DEFINE_PRIMITIVE ("MAKE-SUBPROCESS", Prim_make_subprocess, 7, 7,
  "Create a subprocess.\n\
First arg FILENAME is the program to run.\n\
Second arg ARGV is a vector of strings to pass to the program as arguments.\n\
Third arg ENV is a vector of strings to pass as the program's environment;\n\
  #F means inherit Scheme's environment.\n\
Fourth arg CTTY specifies the program's controlling terminal:\n\
  #F means none;\n\
  -1 means use Scheme's controlling terminal in background;\n\
  -2 means use Scheme's controlling terminal in foreground;\n\
  string means open that terminal.\n\
Fifth arg STDIN is the input channel for the subprocess.\n\
Sixth arg STDOUT is the output channel for the subprocess.\n\
Seventh arg STDERR is the error channel for the subprocess.\n\
  Each channel arg can take these values:\n\
  #F means none;\n\
  -1 means use the corresponding channel from Scheme;\n\
  -2 means use the controlling terminal (valid only when CTTY is a string);\n\
  otherwise the argument must be a channel.")
{
  PRIMITIVE_HEADER (7);
  CHECK_ARG (2, string_vector_p);
  {
    PTR position = dstack_position;
    CONST char * filename = (STRING_ARG (1));
    char * CONST * argv =
      ((char * CONST *) (convert_string_vector (ARG_REF (2))));
    SCHEME_OBJECT env_object = (ARG_REF (3));
    char * CONST * env = 0;
    CONST char * working_directory = 0;
    enum process_ctty_type ctty_type;
    char * ctty_name = 0;
    enum process_channel_type channel_in_type;
    Tchannel channel_in;
    enum process_channel_type channel_out_type;
    Tchannel channel_out;
    enum process_channel_type channel_err_type;
    Tchannel channel_err;

    if ((PAIR_P (env_object)) && (STRING_P (PAIR_CDR (env_object))))
      {
	working_directory =
	  ((CONST char *) (STRING_LOC ((PAIR_CDR (env_object)), 0)));
	env_object = (PAIR_CAR (env_object));
      }
    if (env_object != SHARP_F)
      {
	if (! (string_vector_p (env_object)))
	  error_wrong_type_arg (3);
	env = ((char * CONST *) (convert_string_vector (env_object)));
      }
    if ((ARG_REF (4)) == SHARP_F)
      ctty_type = process_ctty_type_none;
    else if ((ARG_REF (4)) == (LONG_TO_FIXNUM (-1)))
      ctty_type = process_ctty_type_inherit_bg;
    else if ((ARG_REF (4)) == (LONG_TO_FIXNUM (-2)))
      ctty_type = process_ctty_type_inherit_fg;
    else
      {
	ctty_type = process_ctty_type_explicit;
	ctty_name = (STRING_ARG (4));
      }
    PROCESS_CHANNEL_ARG (5, channel_in_type, channel_in);
    PROCESS_CHANNEL_ARG (6, channel_out_type, channel_out);
    PROCESS_CHANNEL_ARG (7, channel_err_type, channel_err);
    {
      Tprocess process =
	(OS_make_subprocess
	 (filename, argv, env, working_directory,
	  ctty_type, ctty_name,
	  channel_in_type, channel_in,
	  channel_out_type, channel_out,
	  channel_err_type, channel_err));
      dstack_set_position (position);
      PRIMITIVE_RETURN (long_to_integer (process));
    }
  }
}

static int
DEFUN (string_vector_p, (vector), SCHEME_OBJECT vector)
{
  if (! (VECTOR_P (vector)))
    return (0);
  {
    unsigned long length = (VECTOR_LENGTH (vector));
    SCHEME_OBJECT * scan = (VECTOR_LOC (vector, 0));
    SCHEME_OBJECT * end = (scan + length);
    while (scan < end)
      if (! (STRING_P (*scan++)))
	return (0);
  }
  return (1);
}

static char **
DEFUN (convert_string_vector, (vector), SCHEME_OBJECT vector)
{
  unsigned long length = (VECTOR_LENGTH (vector));
  char ** result = (dstack_alloc ((length + 1) * (sizeof (char *))));
  SCHEME_OBJECT * scan = (VECTOR_LOC (vector, 0));
  SCHEME_OBJECT * end = (scan + length);
  char ** scan_result = result;
  while (scan < end)
    (*scan_result++) = ((char *) (STRING_LOC ((*scan++), 0)));
  (*scan_result) = 0;
  return (result);
}

#ifdef _OS2
#define environ _environ
#endif

DEFINE_PRIMITIVE ("SCHEME-ENVIRONMENT", Prim_scheme_environment, 0, 0, 0)
{
  PRIMITIVE_HEADER (0);
  {
    extern char ** environ;
    {
      char ** scan_environ = environ;
      char ** end_environ = scan_environ;
      while ((*end_environ++) != 0) ;
      end_environ -= 1;
      {
	SCHEME_OBJECT result =
	  (allocate_marked_vector (TC_VECTOR, (end_environ - environ), 1));
	SCHEME_OBJECT * scan_result = (VECTOR_LOC (result, 0));
	while (scan_environ < end_environ)
	  (*scan_result++) =
	    (char_pointer_to_string ((unsigned char *) (*scan_environ++)));
	PRIMITIVE_RETURN (result);
      }
    }
  }
}

DEFINE_PRIMITIVE ("PROCESS-DELETE", Prim_process_delete, 1, 1,
  "Delete process PROCESS-NUMBER from the process table.")
{
  PRIMITIVE_HEADER (1);
  OS_process_deallocate (arg_process (1));
  PRIMITIVE_RETURN (UNSPECIFIC);
}

DEFINE_PRIMITIVE ("PROCESS-TABLE", Prim_process_table, 0, 0,
  "Return a vector of all processes in the process table.")
{
  PRIMITIVE_HEADER (0);
  {
    Tprocess process;
    for (process = 0; (process < OS_process_table_size); process += 1)
      if (OS_process_valid_p (process))
	obstack_grow ((&scratch_obstack), (&process), (sizeof (Tprocess)));
  }
  {
    unsigned int n_processes =
      ((obstack_object_size ((&scratch_obstack))) / (sizeof (Tprocess)));
    if (n_processes == 0)
      PRIMITIVE_RETURN (SHARP_F);
    {
      Tprocess * processes = (obstack_finish (&scratch_obstack));
      Tprocess * scan_processes = processes;
      SCHEME_OBJECT vector =
	(allocate_marked_vector (TC_VECTOR, n_processes, 1));
      SCHEME_OBJECT * scan_vector = (VECTOR_LOC (vector, 0));
      SCHEME_OBJECT * end_vector = (scan_vector + n_processes);
      while (scan_vector < end_vector)
	(*scan_vector++) = (long_to_integer (*scan_processes++));
      obstack_free ((&scratch_obstack), processes);
      PRIMITIVE_RETURN (vector);
    }
  }
}

DEFINE_PRIMITIVE ("PROCESS-ID", Prim_process_id, 1, 1, 
  "Return the process ID of process PROCESS-NUMBER.")
{
  PRIMITIVE_HEADER (1);
  PRIMITIVE_RETURN (long_to_integer (OS_process_id (arg_process (1))));
}

DEFINE_PRIMITIVE ("PROCESS-JOB-CONTROL-STATUS", Prim_process_jc_status, 1, 1, 
  "Returns the job-control status of process PROCESS-NUMBER:\n\
  0 means this system doesn't support job control.\n\
  1 means the process doesn't have the same controlling terminal as Scheme.\n\
  2 means it's the same ctty but the OS doesn't have job control.\n\
  3 means it's the same ctty and the OS has job control.")
{
  PRIMITIVE_HEADER (1);
  switch (OS_process_jc_status (arg_process (1)))
    {
    case process_jc_status_no_ctty:
      PRIMITIVE_RETURN (LONG_TO_UNSIGNED_FIXNUM (0));
    case process_jc_status_unrelated:
      PRIMITIVE_RETURN (LONG_TO_UNSIGNED_FIXNUM (1));
    case process_jc_status_no_jc:
      PRIMITIVE_RETURN (LONG_TO_UNSIGNED_FIXNUM (2));
    case process_jc_status_jc:
      PRIMITIVE_RETURN (LONG_TO_UNSIGNED_FIXNUM (3));
    default:
      error_bad_range_arg (1);
      PRIMITIVE_RETURN (UNSPECIFIC);
    }
}

DEFINE_PRIMITIVE ("PROCESS-STATUS-SYNC", Prim_process_status_sync, 1, 1,
  "Synchronize the status of process PROCESS-NUMBER.\n\
Return #F if it was previously synchronized, #T if not.")
{
  PRIMITIVE_HEADER (1);
  PRIMITIVE_RETURN
    (BOOLEAN_TO_OBJECT (OS_process_status_sync (arg_process (1))));
}

DEFINE_PRIMITIVE ("PROCESS-STATUS-SYNC-ALL", Prim_process_status_sync_all, 0, 0, 0)
{
  PRIMITIVE_HEADER (0);
  PRIMITIVE_RETURN (BOOLEAN_TO_OBJECT (OS_process_status_sync_all ()));
}

DEFINE_PRIMITIVE ("PROCESS-STATUS", Prim_process_status, 1, 1,
  "Return the status of process PROCESS-NUMBER, a nonnegative integer:\n\
  0 = running; 1 = stopped; 2 = exited; 3 = signalled.\n\
The value is from the last synchronization.")
{
  PRIMITIVE_HEADER (1);
  switch (OS_process_status (arg_process (1)))
    {
    case process_status_running:
      PRIMITIVE_RETURN (LONG_TO_UNSIGNED_FIXNUM (0));
    case process_status_stopped:
      PRIMITIVE_RETURN (LONG_TO_UNSIGNED_FIXNUM (1));
    case process_status_exited:
      PRIMITIVE_RETURN (LONG_TO_UNSIGNED_FIXNUM (2));
    case process_status_signalled:
      PRIMITIVE_RETURN (LONG_TO_UNSIGNED_FIXNUM (3));
    default:
      error_external_return ();
      PRIMITIVE_RETURN (UNSPECIFIC);
    }
}

DEFINE_PRIMITIVE ("PROCESS-REASON", Prim_process_reason, 1, 1, 
  "Return the termination reason of process PROCESS-NUMBER.\n\
This is a nonnegative integer, which depends on the process's status:\n\
  running => zero;\n\
  stopped => the signal that stopped the process;\n\
  exited => the exit code returned by the process;\n\
  signalled => the signal that killed the process.\n\
The value is from the last synchronization.")
{
  PRIMITIVE_HEADER (1);
  PRIMITIVE_RETURN (long_to_integer (OS_process_reason (arg_process (1))));
}

DEFINE_PRIMITIVE ("PROCESS-SIGNAL", Prim_process_signal, 2, 2,
  "Send a signal to process PROCESS-NUMBER; second arg SIGNAL says which one.")
{
  PRIMITIVE_HEADER (2);
  OS_process_send_signal ((arg_process (1)), (arg_nonnegative_integer (2)));
  PRIMITIVE_RETURN (UNSPECIFIC);
}

#define PROCESS_SIGNALLING_PRIMITIVE(signaller)				\
{									\
  PRIMITIVE_HEADER (1);							\
  signaller (arg_process (1));						\
  PRIMITIVE_RETURN (UNSPECIFIC);					\
}

DEFINE_PRIMITIVE ("PROCESS-KILL", Prim_process_kill, 1, 1,
  "Kills process PROCESS-NUMBER (unix SIGKILL).")
     PROCESS_SIGNALLING_PRIMITIVE (OS_process_kill)

DEFINE_PRIMITIVE ("PROCESS-INTERRUPT", Prim_process_interrupt, 1, 1,
  "Interrupts process PROCESS-NUMBER (unix SIGINT).")
     PROCESS_SIGNALLING_PRIMITIVE (OS_process_interrupt)

DEFINE_PRIMITIVE ("PROCESS-QUIT", Prim_process_quit, 1, 1,
  "Sends the quit signal to process PROCESS-NUMBER (unix SIGQUIT).")
     PROCESS_SIGNALLING_PRIMITIVE (OS_process_quit)

DEFINE_PRIMITIVE ("PROCESS-HANGUP", Prim_process_hangup, 1, 1,
  "Sends the hangup signal to process PROCESS-NUMBER (unix SIGHUP).")
     PROCESS_SIGNALLING_PRIMITIVE (OS_process_hangup)

DEFINE_PRIMITIVE ("PROCESS-STOP", Prim_process_stop, 1, 1,
  "Stops process PROCESS-NUMBER (unix SIGTSTP).")
     PROCESS_SIGNALLING_PRIMITIVE (OS_process_stop)

DEFINE_PRIMITIVE ("PROCESS-CONTINUE-BACKGROUND", Prim_process_continue_background, 1, 1,
  "Continues process PROCESS-NUMBER in the background.")
{
  PRIMITIVE_HEADER (1);
  {
    Tprocess process = (arg_process (1));
    if (! (OS_process_continuable_p (process)))
      error_bad_range_arg (1);
    OS_process_continue_background (process);
  }
  PRIMITIVE_RETURN (UNSPECIFIC);
}

DEFINE_PRIMITIVE ("PROCESS-WAIT", Prim_process_wait, 1, 1,
  "Waits until process PROCESS-NUMBER is not running.")
{
  PRIMITIVE_HEADER (1);
  OS_process_wait (arg_process (1));
  PRIMITIVE_RETURN (UNSPECIFIC);
}

DEFINE_PRIMITIVE ("PROCESS-CONTINUE-FOREGROUND", Prim_process_continue_foreground, 1, 1,
  "Continues process PROCESS-NUMBER in the foreground.\n\
The process must have the same controlling terminal as Scheme.")
{
  PRIMITIVE_HEADER (1);
  {
    Tprocess process = (arg_process (1));
    if (! ((OS_process_foregroundable_p (process))
	   && (OS_process_continuable_p (process))))
      error_bad_range_arg (1);
    OS_process_continue_foreground (process);
    PRIMITIVE_RETURN (UNSPECIFIC);
  }
}
