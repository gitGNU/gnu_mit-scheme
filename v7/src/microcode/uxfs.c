/* -*-C-*-

$Id: uxfs.c,v 1.19.2.1 2000/11/27 05:57:58 cph Exp $

Copyright (c) 1990-2000 Massachusetts Institute of Technology

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

#include "ux.h"
#include "osfs.h"
#include "osfile.h"
#include "osio.h"

#ifdef HAVE_STATFS
#  ifdef HAVE_SYS_VFS_H
     /* GNU/Linux */
#    include <sys/vfs.h>
#  else
#    ifdef HAVE_SYS_MOUNT_H
       /* FreeBSD */
#      include <sys/param.h>
#      include <sys/mount.h>
#    endif
#  endif
#  ifdef __linux__
/* The following superblock magic constants are taken from the kernel
   headers for Linux 2.0.33.  We use these rather than reading the
   header files, because the Linux kernel header files have
   definitions that conflict with those of glibc2.  These constants
   are unlikely to be changed, so this ought to be safe.  */
#    ifndef AFFS_SUPER_MAGIC
#      define AFFS_SUPER_MAGIC 0xadff
#    endif
#    ifndef COH_SUPER_MAGIC
#      define COH_SUPER_MAGIC 0x012FF7B7
#    endif
#    ifndef EXT_SUPER_MAGIC
#      define EXT_SUPER_MAGIC 0x137D
#    endif
#    ifndef EXT2_SUPER_MAGIC
#      define EXT2_SUPER_MAGIC 0xEF53
#    endif
#    ifndef HPFS_SUPER_MAGIC
#      define HPFS_SUPER_MAGIC 0xf995e849
#    endif
#    ifndef ISOFS_SUPER_MAGIC
#      define ISOFS_SUPER_MAGIC 0x9660
#    endif
#    ifndef MINIX_SUPER_MAGIC
#      define MINIX_SUPER_MAGIC 0x137F
#    endif
#    ifndef MINIX_SUPER_MAGIC2
#      define MINIX_SUPER_MAGIC2 0x138F
#    endif
#    ifndef MINIX2_SUPER_MAGIC
#      define MINIX2_SUPER_MAGIC 0x2468
#    endif
#    ifndef MINIX2_SUPER_MAGIC2
#      define MINIX2_SUPER_MAGIC2 0x2478
#    endif
#    ifndef MSDOS_SUPER_MAGIC
#      define MSDOS_SUPER_MAGIC 0x4d44
#    endif
#    ifndef NCP_SUPER_MAGIC
#      define NCP_SUPER_MAGIC 0x564c
#    endif
#    ifndef NFS_SUPER_MAGIC
#      define NFS_SUPER_MAGIC 0x6969
#    endif
#    ifndef NTFS_SUPER_MAGIC
#      define NTFS_SUPER_MAGIC 0x5346544E
#    endif
#    ifndef PROC_SUPER_MAGIC
#      define PROC_SUPER_MAGIC 0x9fa0
#    endif
#    ifndef SMB_SUPER_MAGIC
#      define SMB_SUPER_MAGIC 0x517B
#    endif
#    ifndef SYSV2_SUPER_MAGIC
#      define SYSV2_SUPER_MAGIC 0x012FF7B6
#    endif
#    ifndef SYSV4_SUPER_MAGIC
#      define SYSV4_SUPER_MAGIC 0x012FF7B5
#    endif
#    ifndef XENIX_SUPER_MAGIC
#      define XENIX_SUPER_MAGIC 0x012FF7B4
#    endif
#    ifndef _XIAFS_SUPER_MAGIC
#      define _XIAFS_SUPER_MAGIC 0x012FD16D
#    endif
#  endif
#endif

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
  if (!UX_read_file_status (name, (&s)))
    return (file_doesnt_exist);
#ifdef HAVE_SYMLINK
  if (((s . st_mode) & S_IFMT) == S_IFLNK)
    {
      if (UX_read_file_status_indirect (name, (&s)))
	return (file_does_exist);
      else
	return (file_is_link);
    }
#endif
  return (file_does_exist);
}

enum file_existence
DEFUN (OS_file_existence_test_direct, (name), CONST char * name)
{
  struct stat s;
  if (!UX_read_file_status (name, (&s)))
    return (file_doesnt_exist);
#ifdef HAVE_SYMLINK
  if (((s . st_mode) & S_IFMT) == S_IFLNK)
    return (file_is_link);
#endif
  return (file_does_exist);
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

#ifdef __linux__
  switch (s . f_type)
    {
    case COH_SUPER_MAGIC:	return ("coherent");
    case EXT_SUPER_MAGIC:	return ("ext");
    case EXT2_SUPER_MAGIC:	return ("ext2");
    case HPFS_SUPER_MAGIC:	return ("hpfs");
    case ISOFS_SUPER_MAGIC:	return ("iso9660");
    case MINIX_SUPER_MAGIC:	return ("minix1");
    case MINIX_SUPER_MAGIC2:	return ("minix1-30");
    case MINIX2_SUPER_MAGIC:	return ("minix2");
    case MINIX2_SUPER_MAGIC2:	return ("minix2-30");
    case MSDOS_SUPER_MAGIC:	return ("fat");
    case NCP_SUPER_MAGIC:	return ("ncp");
    case NFS_SUPER_MAGIC:	return ("nfs");
    case NTFS_SUPER_MAGIC:	return ("ntfs");
    case PROC_SUPER_MAGIC:	return ("proc");
    case SMB_SUPER_MAGIC:	return ("smb");
    case SYSV2_SUPER_MAGIC:	return ("sysv2");
    case SYSV4_SUPER_MAGIC:	return ("sysv4");
    case XENIX_SUPER_MAGIC:	return ("xenix");
    case _XIAFS_SUPER_MAGIC:	return ("xiafs");
    }
#endif /* __linux__ */

#ifdef __HPUX__
  switch ((s . f_fsid) [1])
    {
    case MOUNT_UFS:		return ("ufs");
    case MOUNT_NFS:		return ("nfs");
    case MOUNT_CDFS:		return ("iso9660");
    }
#endif /* __HPUX__ */
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
#ifdef HAVE_SYMLINK
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
#ifdef HAVE_SYMLINK
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
#ifdef HAVE_SYMLINK
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
