/* -*-C-*-

$Id: uxfs.c,v 1.12 1996/04/23 20:50:46 cph Exp $

Copyright (c) 1990-96 Massachusetts Institute of Technology

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
#include "osfs.h"

#ifdef HAVE_STATFS
#include <sys/vfs.h>

#ifdef __linux
#include <linux/ext2_fs.h>
#include <linux/ext_fs.h>
#include <linux/hpfs_fs.h>
#include <linux/iso_fs.h>
#include <linux/minix_fs.h>
#include <linux/msdos_fs.h>
#include <linux/nfs_fs.h>
#if 0				/* Broken -- requires __KERNEL__ defined. */
#include <linux/proc_fs.h>
#endif
#include <linux/sysv_fs.h>
#include <linux/xia_fs.h>
#include <linux/version.h>
#if (LINUX_VERSION_CODE >= 66304) /* 1.3.0 (is this correct?) */
#include <linux/smb_fs.h>
#if (LINUX_VERSION_CODE >= 66387) /* 1.3.53 */
#include <linux/ncp_fs.h>
#endif
#endif
#endif /* __linux */

#endif /* HAVE_STATFS */

int
DEFUN (UX_read_file_status, (filename, s),
       CONST char * filename AND
       struct stat * s)
{
  while ((UX_lstat (filename, s)) < 0)
    {
      if (errno == EINTR)
	continue;
      if ((errno == ENOENT) || (errno == ENOTDIR))
	return (0);
      error_system_call (errno, syscall_lstat);
    }
  return (1);
}

int
DEFUN (UX_read_file_status_indirect, (filename, s),
       CONST char * filename AND
       struct stat * s)
{
  while ((UX_stat (filename, s)) < 0)
    {
      if (errno == EINTR)
	continue;
      if ((errno == ENOENT) || (errno == ENOTDIR))
	return (0);
      error_system_call (errno, syscall_stat);
    }
  return (1);
}

enum file_existence
DEFUN (OS_file_existence_test, (name), CONST char * name)
{
  struct stat s;
  return
    ((UX_read_file_status_indirect (name, (&s)))
     ? file_does_exist
     : (UX_read_file_status (name, (&s)))
     ? file_is_link
     : file_doesnt_exist);
}

CONST char *
DEFUN (UX_file_system_type, (name), CONST char * name)
{
#ifdef HAVE_STATFS
  struct statfs s;
  while ((UX_statfs (name, (&s))) < 0)
    {
      if ((errno == ENOENT) || (errno == ENOTDIR))
	return (0);
      if (errno != EINTR)
	error_system_call (errno, syscall_statfs);
    }

#ifdef __linux
  switch (s . f_type)
    {
#ifdef COH_SUPER_MAGIC
    case COH_SUPER_MAGIC:	return ("coherent");
#endif
    case EXT_SUPER_MAGIC:	return ("ext");
    case EXT2_SUPER_MAGIC:	return ("ext2");
    case HPFS_SUPER_MAGIC:	return ("hpfs");
    case ISOFS_SUPER_MAGIC:	return ("iso9660");
    case MINIX_SUPER_MAGIC:	return ("minix1");
    case MINIX_SUPER_MAGIC2:	return ("minix1-30");
#ifdef MINIX2_SUPER_MAGIC
    case MINIX2_SUPER_MAGIC:	return ("minix2");
#endif
#ifdef MINIX2_SUPER_MAGIC2
    case MINIX2_SUPER_MAGIC2:	return ("minix2-30");
#endif
    case MSDOS_SUPER_MAGIC:	return ("fat");
#ifdef NCP_SUPER_MAGIC
    case NCP_SUPER_MAGIC:	return ("ncp");
#endif
#ifdef NEW_MINIX_SUPER_MAGIC
    case NEW_MINIX_SUPER_MAGIC: return ("minix2");
#endif
    case NFS_SUPER_MAGIC:	return ("nfs");
#ifdef PROC_SUPER_MAGIC
    case PROC_SUPER_MAGIC:	return ("proc");
#endif
#ifdef SMB_SUPER_MAGIC
    case SMB_SUPER_MAGIC:	return ("smb");
#endif
#ifdef SYSV2_SUPER_MAGIC
    case SYSV2_SUPER_MAGIC:	return ("sysv2");
#endif
#ifdef SYSV4_SUPER_MAGIC
    case SYSV4_SUPER_MAGIC:	return ("sysv4");
#endif
#ifdef XENIX_SUPER_MAGIC
    case XENIX_SUPER_MAGIC:	return ("xenix");
#endif
    case _XIAFS_SUPER_MAGIC:	return ("xiafs");
    }
#endif /* __linux */

#ifdef _HPUX
  switch ((s . f_fsid) [1])
    {
    case MOUNT_UFS:		return ("ufs");
    case MOUNT_NFS:		return ("nfs");
    case MOUNT_CDFS:		return ("iso9660");
    }
#endif /* _HPUX */
#endif /* HAVE_STATFS */

  return (0);
}

int
DEFUN (OS_file_directory_p, (name), CONST char * name)
{
  struct stat s;
  return
    ((UX_read_file_status_indirect (name, (&s)))
     && (((s . st_mode) & S_IFMT) == S_IFDIR));
}

CONST char *
DEFUN (OS_file_soft_link_p, (name), CONST char * name)
{
#ifdef HAVE_SYMBOLIC_LINKS
  struct stat s;
  if (! ((UX_read_file_status (name, (&s)))
	 && (((s . st_mode) & S_IFMT) == S_IFLNK)))
    return (0);
  {
    int scr;
    int buffer_length = 100;
    char * buffer = (UX_malloc (buffer_length));
    if (buffer == 0)
      error_system_call (ENOMEM, syscall_malloc);
    while (1)
      {
	STD_UINT_SYSTEM_CALL
	  (syscall_readlink, scr, (UX_readlink (name, buffer, buffer_length)));
	if (scr < buffer_length)
	  break;
	buffer_length *= 2;
	buffer = (UX_realloc (buffer, buffer_length));
	if (buffer == 0)
	  error_system_call (ENOMEM, syscall_realloc);
      }
    (buffer[scr]) = '\0';
    return ((CONST char *) buffer);
  }
#else
  return (0);
#endif
}

int
DEFUN (OS_file_access, (name, mode), CONST char * name AND unsigned int mode)
{
  return ((UX_access (name, mode)) == 0);
}

void
DEFUN (OS_file_remove, (name), CONST char * name)
{
  STD_VOID_SYSTEM_CALL (syscall_unlink, (UX_unlink (name)));
}

void
DEFUN (OS_file_remove_link, (name), CONST char * name)
{
  struct stat s;
  if ((UX_read_file_status (name, (&s)))
      && ((((s . st_mode) & S_IFMT) == S_IFREG)
#ifdef HAVE_SYMBOLIC_LINKS
	  || (((s . st_mode) & S_IFMT) == S_IFLNK)
#endif
	  ))
    UX_unlink (name);
}

void
DEFUN (OS_file_link_hard, (from_name, to_name),
       CONST char * from_name AND
       CONST char * to_name)
{
  STD_VOID_SYSTEM_CALL (syscall_link, (UX_link (from_name, to_name)));
}

void
DEFUN (OS_file_link_soft, (from_name, to_name),
       CONST char * from_name AND
       CONST char * to_name)
{
#ifdef HAVE_SYMBOLIC_LINKS
  STD_VOID_SYSTEM_CALL (syscall_symlink, (UX_symlink (from_name, to_name)));
#else
  error_unimplemented_primitive ();
#endif
}

void
DEFUN (OS_file_rename, (from_name, to_name),
       CONST char * from_name AND
       CONST char * to_name)
{
  STD_VOID_SYSTEM_CALL (syscall_rename, (UX_rename (from_name, to_name)));
}

#ifndef FILE_COPY_BUFFER_LENGTH
#define FILE_COPY_BUFFER_LENGTH 8192
#endif

void
DEFUN (OS_file_copy, (from_name, to_name),
       CONST char * from_name AND
       CONST char * to_name)
{
  Tchannel src, dst;
  off_t src_len, len;
  char buffer [FILE_COPY_BUFFER_LENGTH];
  long nread, nwrite;

  src = (OS_open_input_file (from_name));
  OS_channel_close_on_abort (src);
  dst = (OS_open_output_file (to_name));
  OS_channel_close_on_abort (dst);
  src_len = (OS_file_length (src));
  len = (sizeof (buffer));
  while (src_len > 0)
    {
      if (src_len < len)
	len = src_len;
      nread = (OS_channel_read (src, buffer, len));
      if (nread < 0)
	error_system_call (errno, syscall_read);
      else if (nread == 0)
	break;
      nwrite = (OS_channel_write (dst, buffer, nread));
      if (nwrite < 0)
	error_system_call (errno, syscall_write);
      else if (nwrite < nread)
	error_system_call (ENOSPC, syscall_write);
      src_len -= nread;
    }
  OS_channel_close (src);
  OS_channel_close (dst);
}

void
DEFUN (OS_directory_make, (name), CONST char * name)
{
  STD_VOID_SYSTEM_CALL (syscall_mkdir, (UX_mkdir (name, MODE_DIR)));
}

void
DEFUN (OS_directory_delete, (name), CONST char * name)
{
  STD_VOID_SYSTEM_CALL (syscall_rmdir, (UX_rmdir (name)));
}

#if defined(HAVE_DIRENT) || defined(HAVE_DIR)

static DIR ** directory_pointers;
static unsigned int n_directory_pointers;

void
DEFUN_VOID (UX_initialize_directory_reader)
{
  directory_pointers = 0;
  n_directory_pointers = 0;
  return;
}

static unsigned int
DEFUN (allocate_directory_pointer, (pointer), DIR * pointer)
{
  if (n_directory_pointers == 0)
    {
      DIR ** pointers = ((DIR **) (UX_malloc ((sizeof (DIR *)) * 4)));
      if (pointers == 0)
	error_system_call (ENOMEM, syscall_malloc);
      directory_pointers = pointers;
      n_directory_pointers = 4;
      {
	DIR ** scan = directory_pointers;
	DIR ** end = (scan + n_directory_pointers);
	(*scan++) = pointer;
	while (scan < end)
	  (*scan++) = 0;
      }
      return (0);
    }
  {
    DIR ** scan = directory_pointers;
    DIR ** end = (scan + n_directory_pointers);
    while (scan < end)
      if ((*scan++) == 0)
	{
	  (*--scan) = pointer;
	  return (scan - directory_pointers);
	}
  }
  {
    unsigned int result = n_directory_pointers;
    unsigned int n_pointers = (2 * n_directory_pointers);
    DIR ** pointers =
      ((DIR **)
       (UX_realloc (((PTR) directory_pointers),
		    ((sizeof (DIR *)) * n_pointers))));
    if (pointers == 0)
      error_system_call (ENOMEM, syscall_realloc);
    {
      DIR ** scan = (pointers + result);
      DIR ** end = (pointers + n_pointers);
      (*scan++) = pointer;
      while (scan < end)
	(*scan++) = 0;
    }
    directory_pointers = pointers;
    n_directory_pointers = n_pointers;
    return (result);
  }
}

#define REFERENCE_DIRECTORY(index) (directory_pointers[(index)])
#define DEALLOCATE_DIRECTORY(index) ((directory_pointers[(index)]) = 0)

int
DEFUN (OS_directory_valid_p, (index), long index)
{
  return
    ((0 <= index)
     && (index < n_directory_pointers)
     && ((REFERENCE_DIRECTORY (index)) != 0));
}

unsigned int
DEFUN (OS_directory_open, (name), CONST char * name)
{
  /* Cast `name' to non-const because hp-ux 7.0 declaration incorrect. */
  DIR * pointer = (opendir ((char *) name));
  if (pointer == 0)
    error_system_call (errno, syscall_opendir);
  return (allocate_directory_pointer (pointer));
}

#ifndef HAVE_DIRENT
#define dirent direct
#endif

CONST char *
DEFUN (OS_directory_read, (index), unsigned int index)
{
  struct dirent * entry = (readdir (REFERENCE_DIRECTORY (index)));
  return ((entry == 0) ? 0 : (entry -> d_name));
}

CONST char *
DEFUN (OS_directory_read_matching, (index, prefix), 
       unsigned int index AND
       CONST char * prefix)
{
  DIR * pointer = (REFERENCE_DIRECTORY (index));
  unsigned int n = (strlen (prefix));
  while (1)
    {
      struct dirent * entry = (readdir (pointer));
      if (entry == 0)
	return (0);
      if ((strncmp (prefix, (entry -> d_name), n)) == 0)
	return (entry -> d_name);
    }
}

void
DEFUN (OS_directory_close, (index), unsigned int index)
{
  closedir (REFERENCE_DIRECTORY (index));
  DEALLOCATE_DIRECTORY (index);
}

#else /* not HAVE_DIRENT nor HAVE_DIR */

void
DEFUN_VOID (UX_initialize_directory_reader)
{
  return;
}

int
DEFUN (OS_directory_valid_p, (index), long index)
{
  return (0);
}

unsigned int
DEFUN (OS_directory_open, (name), CONST char * name)
{
  error_unimplemented_primitive ();
  /*NOTREACHED*/
}

#ifndef HAVE_DIRENT
#define dirent direct
#endif

CONST char *
DEFUN (OS_directory_read, (index), unsigned int index)
{
  error_unimplemented_primitive ();
  /*NOTREACHED*/
}

CONST char *
DEFUN (OS_directory_read_matching, (index, prefix), 
       unsigned int index AND
       CONST char * prefix)
{
  error_unimplemented_primitive ();
  /*NOTREACHED*/
}

void
DEFUN (OS_directory_close, (index), unsigned int index)
{
  error_unimplemented_primitive ();
  /*NOTREACHED*/
}

#endif /* HAVE_DIRENT */
