/* -*-C-*-

$Id: uxio.c,v 1.33.1.1 1998/07/19 20:37:15 cph Exp $

Copyright (c) 1990-98 Massachusetts Institute of Technology

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

#include "ux.h"
#include "uxio.h"
#include "uxselect.h"

size_t OS_channel_table_size;
struct channel * channel_table;

#ifdef FD_SET
#define SELECT_TYPE fd_set
#else
#define SELECT_TYPE int
#define FD_SETSIZE ((sizeof (int)) * CHAR_BIT)
#define FD_SET(n, p) ((*(p)) |= (1 << (n)))
#define FD_CLR(n, p) ((*(p)) &= ~(1 << (n)))
#define FD_ISSET(n, p) (((*(p)) & (1 << (n))) != 0)
#define FD_ZERO(p) ((*(p)) = 0)
#endif

unsigned int OS_channels_registered;
static SELECT_TYPE input_descriptors;
#ifdef HAVE_SELECT
static struct timeval zero_timeout;
#endif

static void
DEFUN_VOID (UX_channel_close_all)
{
  Tchannel channel;
  for (channel = 0; (channel < OS_channel_table_size); channel += 1)
    if (CHANNEL_OPEN_P (channel))
      OS_channel_close_noerror (channel);
}

extern void EXFUN (add_reload_cleanup, (void (*) (void)));

void
DEFUN_VOID (UX_initialize_channels)
{
  OS_channel_table_size = (UX_SC_OPEN_MAX ());
  channel_table =
    (UX_malloc (OS_channel_table_size * (sizeof (struct channel))));
  if (channel_table == 0)
    {
      fprintf (stderr, "\nUnable to allocate channel table.\n");
      fflush (stderr);
      termination_init_error ();
    }
  {
    Tchannel channel;
    for (channel = 0; (channel < OS_channel_table_size); channel += 1)
      MARK_CHANNEL_CLOSED (channel);
  }
  add_reload_cleanup (UX_channel_close_all);
  FD_ZERO (&input_descriptors);
  OS_channels_registered = 0;
#ifdef HAVE_SELECT
  (zero_timeout . tv_sec) = 0;
  (zero_timeout . tv_usec) = 0;
#endif
}

void
DEFUN_VOID (UX_reset_channels)
{
  UX_free (channel_table);
  channel_table = 0;
  OS_channel_table_size = 0;
}

Tchannel
DEFUN_VOID (channel_allocate)
{
  Tchannel channel = 0;
  while (1)
    {
      if (channel == OS_channel_table_size)
	error_out_of_channels ();
      if (CHANNEL_CLOSED_P (channel))
	return (channel);
      channel += 1;
    }
}

int
DEFUN (UX_channel_descriptor, (channel), Tchannel channel)
{
  return (CHANNEL_DESCRIPTOR (channel));
}

int
DEFUN (OS_channel_open_p, (channel), Tchannel channel)
{
  return (CHANNEL_OPEN_P (channel));
}

void
DEFUN (OS_channel_close, (channel), Tchannel channel)
{
  if (! (CHANNEL_INTERNAL (channel)))
    {
      if (CHANNEL_REGISTERED (channel))
	OS_channel_unregister (channel);
      STD_VOID_SYSTEM_CALL
	(syscall_close, (UX_close (CHANNEL_DESCRIPTOR (channel))));
      MARK_CHANNEL_CLOSED (channel);
    }
}

void
DEFUN (OS_channel_close_noerror, (channel), Tchannel channel)
{
  if (! (CHANNEL_INTERNAL (channel)))
    {
      if (CHANNEL_REGISTERED (channel))
	OS_channel_unregister (channel);
      UX_close (CHANNEL_DESCRIPTOR (channel));
      MARK_CHANNEL_CLOSED (channel);
    }
}

static void
DEFUN (channel_close_on_abort_1, (cp), PTR cp)
{
  OS_channel_close (* ((Tchannel *) cp));
}

void
DEFUN (OS_channel_close_on_abort, (channel), Tchannel channel)
{
  Tchannel * cp = (dstack_alloc (sizeof (Tchannel)));
  (*cp) = (channel);
  transaction_record_action (tat_abort, channel_close_on_abort_1, cp);
}

enum channel_type
DEFUN (OS_channel_type, (channel), Tchannel channel)
{
  return (CHANNEL_TYPE (channel));
}

long
DEFUN (OS_channel_read, (channel, buffer, nbytes),
       Tchannel channel AND
       PTR buffer AND
       size_t nbytes)
{
  if (nbytes == 0)
    return (0);
  while (1)
    {
      long scr = (UX_read ((CHANNEL_DESCRIPTOR (channel)), buffer, nbytes));
      if (scr < 0)
	{
#ifdef _ULTRIX
	/* This is needed for non-POSIX-ified master pseudo-terminal
	   driver, which always returns EWOULDBLOCK, even to POSIX
	   applications. */
	if (CHANNEL_TYPE (channel) == channel_type_pty_master)
	  {
	    if (errno == EWOULDBLOCK)
	      return (-1);
	  }
	else
	  {
	    if (errno == EAGAIN)
	      return (-1);
	  }
#else
#ifdef ERRNO_NONBLOCK
	if (errno == ERRNO_NONBLOCK)
	  return (-1);
#endif
#endif /* not _ULTRIX */
	  UX_prim_check_errno (syscall_read);
	  continue;
	}
      if (scr > nbytes)
	error_external_return ();
#ifdef AMBIGUOUS_NONBLOCK
      return ((scr > 0) ? scr : (CHANNEL_NONBLOCKING (channel)) ? (-1) : 0);
#else
      return (scr);
#endif
    }
}

long
DEFUN (OS_channel_write, (channel, buffer, nbytes),
       Tchannel channel AND
       CONST PTR buffer AND
       size_t nbytes)
{
  if (nbytes == 0)
    return (0);
  while (1)
    {
      long scr = (UX_write ((CHANNEL_DESCRIPTOR (channel)), buffer, nbytes));
      if (scr < 0)
	{
#ifdef ERRNO_NONBLOCK
	  if (errno == ERRNO_NONBLOCK)
	    return (-1);
#endif
	  UX_prim_check_errno (syscall_write);
	  continue;
	}
      if (scr > nbytes)
	error_external_return ();
      return ((scr > 0) ? scr : (-1));
    }
}

size_t
DEFUN (OS_channel_read_load_file, (channel, buffer, nbytes),
       Tchannel channel AND PTR buffer AND size_t nbytes)
{
  int scr = (UX_read ((CHANNEL_DESCRIPTOR (channel)), buffer, nbytes));
  return ((scr < 0) ? 0 : scr);
}

size_t
DEFUN (OS_channel_write_dump_file, (channel, buffer, nbytes),
       Tchannel channel AND CONST PTR buffer AND size_t nbytes)
{
  int scr = (UX_write ((CHANNEL_DESCRIPTOR (channel)), buffer, nbytes));
  return ((scr < 0) ? 0 : scr);
}

#ifdef _POSIX
#include <string.h>
#else
extern int EXFUN (strlen, (CONST char *));
#endif

void
DEFUN (OS_channel_write_string, (channel, string),
       Tchannel channel AND
       CONST char * string)
{
  unsigned long length = (strlen (string));
  if ((OS_channel_write (channel, string, length)) != length)
    error_external_return ();
}

void
DEFUN (OS_make_pipe, (readerp, writerp),
       Tchannel * readerp AND
       Tchannel * writerp)
{
  int pv [2];
  transaction_begin ();
  STD_VOID_SYSTEM_CALL (syscall_pipe, (UX_pipe (pv)));
  MAKE_CHANNEL ((pv[0]), channel_type_pipe, (*readerp) =);
  OS_channel_close_on_abort (*readerp);
  MAKE_CHANNEL ((pv[1]), channel_type_pipe, (*writerp) =);
  transaction_commit ();
}

#ifdef FCNTL_NONBLOCK

static int
DEFUN (get_flags, (fd), int fd)
{
  int scr;
  STD_UINT_SYSTEM_CALL (syscall_fcntl_GETFL, scr, (UX_fcntl (fd, F_GETFL, 0)));
  return (scr);
}

static void
DEFUN (set_flags, (fd, flags), int fd AND int flags)
{
  STD_VOID_SYSTEM_CALL (syscall_fcntl_SETFL, (UX_fcntl (fd, F_SETFL, flags)));
}

int
DEFUN (OS_channel_nonblocking_p, (channel), Tchannel channel)
{
  return (CHANNEL_NONBLOCKING (channel));
}

void
DEFUN (OS_channel_nonblocking, (channel), Tchannel channel)
{
  int fd = (CHANNEL_DESCRIPTOR (channel));
  int flags = (get_flags (fd));
  if ((flags & FCNTL_NONBLOCK) == 0)
    set_flags (fd, (flags | FCNTL_NONBLOCK));
#ifdef _ULTRIX
  {
    /* This is needed for non-POSIX-ified pseudo-terminal driver.  fcntl
       sets driver's FIONBIO flag for FNDELAY, but not FNBLOCK.  Note that
       driver will return EWOULDBLOCK, rather than EAGAIN. */
    int true = 1;
    ioctl(fd,FIONBIO,&true);
  }
#endif
  (CHANNEL_NONBLOCKING (channel)) = 1;
}

void
DEFUN (OS_channel_blocking, (channel), Tchannel channel)
{
  int fd = (CHANNEL_DESCRIPTOR (channel));
  int flags = (get_flags (fd));
  if ((flags & FCNTL_NONBLOCK) != 0)
    set_flags (fd, (flags &~ FCNTL_NONBLOCK));
#ifdef _ULTRIX
  {
    /* This is needed for non-POSIX-ified pseudo-terminal driver.  fcntl
       sets driver's FIONBIO flag for FNDELAY, but not FNBLOCK. */
    int false = 0;
    ioctl(fd,FIONBIO,&false);
  }
#endif
  (CHANNEL_NONBLOCKING (channel)) = 0;
}

#else /* not FCNTL_NONBLOCK */

int
DEFUN (OS_channel_nonblocking_p, (channel), Tchannel channel)
{
  return (-1);
}

void
DEFUN (OS_channel_nonblocking, (channel), Tchannel channel)
{
  error_unimplemented_primitive ();
}

void
DEFUN (OS_channel_blocking, (channel), Tchannel channel)
{
}

#endif /* FCNTL_NONBLOCK */

/* select(2) system call */

#if (defined(_HPUX) && (_HPUX_VERSION >= 80)) || defined(_SUNOS4) || defined(_AIX)
#define SELECT_DECLARED
#endif

#ifdef HAVE_SELECT
CONST int OS_have_select_p = 1;
extern int EXFUN (UX_process_any_status_change, (void));
#ifndef SELECT_DECLARED
extern int EXFUN (UX_select,
		  (int, SELECT_TYPE *, SELECT_TYPE *, SELECT_TYPE *,
		   struct timeval *));
#endif /* not SELECT_DECLARED */
#else /* not HAVE_SELECT */
CONST int OS_have_select_p = 0;
#endif /* not HAVE_SELECT */

unsigned int
DEFUN_VOID (UX_select_registry_size)
{
  return (sizeof (SELECT_TYPE));
}

unsigned int
DEFUN_VOID (UX_select_registry_lub)
{
  return (FD_SETSIZE);
}

void
DEFUN (UX_select_registry_clear_all, (fds), PTR fds)
{
  FD_ZERO ((SELECT_TYPE *) fds);
}

void
DEFUN (UX_select_registry_set, (fds, fd), PTR fds AND unsigned int fd)
{
  FD_SET (fd, ((SELECT_TYPE *) fds));
}

void
DEFUN (UX_select_registry_clear, (fds, fd), PTR fds AND unsigned int fd)
{
  FD_CLR (fd, ((SELECT_TYPE *) fds));
}

int
DEFUN (UX_select_registry_is_set, (fds, fd), PTR fds AND unsigned int fd)
{
  return (FD_ISSET (fd, ((SELECT_TYPE *) fds)));
}

enum select_input
DEFUN (UX_select_registry_test, (input_fds, blockp, output_fds, output_nfds),
       PTR input_fds AND
       int blockp AND
       unsigned int * output_fds AND
       unsigned int * output_nfds)
{
#ifdef HAVE_SELECT
  while (1)
    {
      SELECT_TYPE readable;
      int nfds;
  
      readable = (* ((SELECT_TYPE *) input_fds));
      INTERRUPTABLE_EXTENT
	(nfds,
	 ((UX_process_any_status_change ())
	  ? ((errno = EINTR), (-1))
	  : (UX_select (FD_SETSIZE,
			(&readable),
			((SELECT_TYPE *) 0),
			((SELECT_TYPE *) 0),
			(blockp
			 ? ((struct timeval *) 0)
			 : (&zero_timeout))))));
      if (nfds > 0)
	{
	  unsigned int i = 0;
	  if (output_nfds != 0)
	    (*output_nfds) = nfds;
	  if (output_fds != 0)
	    while (1)
	      {
		if (FD_ISSET (i, (&readable)))
		  {
		    (*output_fds++) = i;
		    if ((--nfds) == 0)
		      break;
		  }
		i += 1;
	      }
	  return (select_input_argument);
	}
      else if (nfds == 0)
	{
	  if (!blockp)
	    return (select_input_none);
	}
      else if (errno != EINTR)
	error_system_call (errno, syscall_select);
      else if (UX_process_any_status_change ())
	return (select_input_process_status);
      if (pending_interrupts_p ())
	return (select_input_interrupt);
    }
#else
  error_system_call (ENOSYS, syscall_select);
  return (select_input_argument);
#endif
}

enum select_input
DEFUN (UX_select_descriptor, (fd, blockp),
       unsigned int fd AND
       int blockp)
{
#ifdef HAVE_SELECT
  SELECT_TYPE readable;

  FD_ZERO (&readable);
  FD_SET (fd, (&readable));
  return (UX_select_registry_test ((&readable), blockp, 0, 0));
#else
  error_system_call (ENOSYS, syscall_select);
  return (select_input_argument);
#endif
}

/* Old Global Registry Mechanism */

int
DEFUN (OS_channel_registered_p, (channel), Tchannel channel)
{
  return (CHANNEL_REGISTERED (channel));
}

void
DEFUN (OS_channel_register, (channel), Tchannel channel)
{
#ifdef HAVE_SELECT
  if (! (CHANNEL_REGISTERED (channel)))
    {
      FD_SET ((CHANNEL_DESCRIPTOR (channel)), (&input_descriptors));
      OS_channels_registered += 1;
      (CHANNEL_REGISTERED (channel)) = 1;
    }
#else
  error_unimplemented_primitive ();
#endif
}

void
DEFUN (OS_channel_unregister, (channel), Tchannel channel)
{
  if (CHANNEL_REGISTERED (channel))
    {
      FD_CLR ((CHANNEL_DESCRIPTOR (channel)), (&input_descriptors));
      OS_channels_registered -= 1;
      (CHANNEL_REGISTERED (channel)) = 0;
    }
}

enum select_input
DEFUN (UX_select_input, (fd, blockp), int fd AND int blockp)
{
  SELECT_TYPE readable;
  unsigned int fds [FD_SETSIZE];
  unsigned int nfds;

  readable = input_descriptors;
  FD_SET (fd, (&readable));
  {
    enum select_input s =
      (UX_select_registry_test ((&readable), blockp, fds, (&nfds)));
    if (s != select_input_argument)
      return (s);
  }
  {
    unsigned int * scan = fds;
    unsigned int * end = (scan + nfds);
    while (scan < end)
      if ((*scan++) == fd)
	return (select_input_argument);
  }
  return (select_input_other);
}
