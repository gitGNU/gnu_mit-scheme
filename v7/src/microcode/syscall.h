/* -*-C-*-

$Id: syscall.h,v 1.6 1994/12/19 22:27:33 cph Exp $

Copyright (c) 1993-94 Massachusetts Institute of Technology

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

/* OS system calls and errors.
   Must match utabmd.scm
 */

#ifndef SCM_SYSCALL_H
#define  SCM_SYSCALL_H

#include "oscond.h"

#ifdef _OS2

enum syscall_names
{
  syscall_DosAsyncTimer,
  syscall_DosClose,
  syscall_DosCloseEventSem,
  syscall_DosCloseMutexSem,
  syscall_DosCloseQueue,
  syscall_DosCreateDir,
  syscall_DosCreateEventSem,
  syscall_DosCreateMutexSem,
  syscall_DosCreatePipe,
  syscall_DosCreateQueue,
  syscall_DosCreateThread,
  syscall_DosDelete,
  syscall_DosDeleteDir,
  syscall_DosExit,
  syscall_DosFindClose,
  syscall_DosFindFirst,
  syscall_DosFindNext,
  syscall_DosGetInfoBlocks,
  syscall_DosGetMessage,
  syscall_DosKillThread,
  syscall_DosMove,
  syscall_DosOpen,
  syscall_DosPostEventSem,
  syscall_DosQueryCurrentDir,
  syscall_DosQueryCurrentDisk,
  syscall_DosQueryFileInfo,
  syscall_DosQueryFSAttach,
  syscall_DosQueryFSInfo,
  syscall_DosQueryHType,
  syscall_DosQueryNPHState,
  syscall_DosQueryPathInfo,
  syscall_DosQuerySysInfo,
  syscall_DosRead,
  syscall_DosReadQueue,
  syscall_DosReleaseMutexSem,
  syscall_DosRequestMutexSem,
  syscall_DosResetEventSem,
  syscall_DosScanEnv,
  syscall_DosSetCurrentDir,
  syscall_DosSetDefaultDisk,
  syscall_DosSetFilePtr,
  syscall_DosSetFileSize,
  syscall_DosSetPathInfo,
  syscall_DosStartTimer,
  syscall_DosStopTimer,
  syscall_DosWaitEventSem,
  syscall_DosWrite,
  syscall_DosWriteQueue,
  syscall_beginthread,
  syscall_KbdCharIn,
  syscall_localtime,
  syscall_malloc,
  syscall_mktime,
  syscall_realloc,
  syscall_time,
  syscall_VioWrtTTY
};

/* Machine-generated table, do not edit: */
enum syserr_names
{
  syserr_invalid_function,
  syserr_file_not_found,
  syserr_path_not_found,
  syserr_too_many_open_files,
  syserr_access_denied,
  syserr_invalid_handle,
  syserr_arena_trashed,
  syserr_not_enough_memory,
  syserr_invalid_block,
  syserr_bad_environment,
  syserr_bad_format,
  syserr_invalid_access,
  syserr_invalid_data,
  syserr_invalid_drive,
  syserr_current_directory,
  syserr_not_same_device,
  syserr_no_more_files,
  syserr_write_protect,
  syserr_bad_unit,
  syserr_not_ready,
  syserr_bad_command,
  syserr_crc,
  syserr_bad_length,
  syserr_seek,
  syserr_not_dos_disk,
  syserr_sector_not_found,
  syserr_out_of_paper,
  syserr_write_fault,
  syserr_read_fault,
  syserr_gen_failure,
  syserr_sharing_violation,
  syserr_lock_violation,
  syserr_wrong_disk,
  syserr_fcb_unavailable,
  syserr_sharing_buffer_exceeded,
  syserr_code_page_mismatched,
  syserr_handle_eof,
  syserr_handle_disk_full,
  syserr_not_supported,
  syserr_rem_not_list,
  syserr_dup_name,
  syserr_bad_netpath,
  syserr_network_busy,
  syserr_dev_not_exist,
  syserr_too_many_cmds,
  syserr_adap_hdw_err,
  syserr_bad_net_resp,
  syserr_unexp_net_err,
  syserr_bad_rem_adap,
  syserr_printq_full,
  syserr_no_spool_space,
  syserr_print_cancelled,
  syserr_netname_deleted,
  syserr_network_access_denied,
  syserr_bad_dev_type,
  syserr_bad_net_name,
  syserr_too_many_names,
  syserr_too_many_sess,
  syserr_sharing_paused,
  syserr_req_not_accep,
  syserr_redir_paused,
  syserr_sbcs_att_write_prot,
  syserr_sbcs_general_failure,
  syserr_xga_out_memory,
  syserr_file_exists,
  syserr_dup_fcb,
  syserr_cannot_make,
  syserr_fail_i24,
  syserr_out_of_structures,
  syserr_already_assigned,
  syserr_invalid_password,
  syserr_invalid_parameter,
  syserr_net_write_fault,
  syserr_no_proc_slots,
  syserr_not_frozen,
  syserr_tstovfl,
  syserr_tstdup,
  syserr_no_items,
  syserr_interrupt,
  syserr_device_in_use,
  syserr_too_many_semaphores,
  syserr_excl_sem_already_owned,
  syserr_sem_is_set,
  syserr_too_many_sem_requests,
  syserr_invalid_at_interrupt_time,
  syserr_sem_owner_died,
  syserr_sem_user_limit,
  syserr_disk_change,
  syserr_drive_locked,
  syserr_broken_pipe,
  syserr_open_failed,
  syserr_buffer_overflow,
  syserr_disk_full,
  syserr_no_more_search_handles,
  syserr_invalid_target_handle,
  syserr_protection_violation,
  syserr_viokbd_request,
  syserr_invalid_category,
  syserr_invalid_verify_switch,
  syserr_bad_driver_level,
  syserr_call_not_implemented,
  syserr_sem_timeout,
  syserr_insufficient_buffer,
  syserr_invalid_name,
  syserr_invalid_level,
  syserr_no_volume_label,
  syserr_mod_not_found,
  syserr_proc_not_found,
  syserr_wait_no_children,
  syserr_child_not_complete,
  syserr_direct_access_handle,
  syserr_negative_seek,
  syserr_seek_on_device,
  syserr_is_join_target,
  syserr_is_joined,
  syserr_is_substed,
  syserr_not_joined,
  syserr_not_substed,
  syserr_join_to_join,
  syserr_subst_to_subst,
  syserr_join_to_subst,
  syserr_subst_to_join,
  syserr_busy_drive,
  syserr_same_drive,
  syserr_dir_not_root,
  syserr_dir_not_empty,
  syserr_is_subst_path,
  syserr_is_join_path,
  syserr_path_busy,
  syserr_is_subst_target,
  syserr_system_trace,
  syserr_invalid_event_count,
  syserr_too_many_muxwaiters,
  syserr_invalid_list_format,
  syserr_label_too_long,
  syserr_too_many_tcbs,
  syserr_signal_refused,
  syserr_discarded,
  syserr_not_locked,
  syserr_bad_threadid_addr,
  syserr_bad_arguments,
  syserr_bad_pathname,
  syserr_signal_pending,
  syserr_uncertain_media,
  syserr_max_thrds_reached,
  syserr_monitors_not_supported,
  syserr_unc_driver_not_installed,
  syserr_lock_failed,
  syserr_swapio_failed,
  syserr_swapin_failed,
  syserr_busy,
  syserr_cancel_violation,
  syserr_atomic_lock_not_supported,
  syserr_read_locks_not_supported,
  syserr_invalid_segment_number,
  syserr_invalid_callgate,
  syserr_invalid_ordinal,
  syserr_already_exists,
  syserr_no_child_process,
  syserr_child_alive_nowait,
  syserr_invalid_flag_number,
  syserr_sem_not_found,
  syserr_invalid_starting_codeseg,
  syserr_invalid_stackseg,
  syserr_invalid_moduletype,
  syserr_invalid_exe_signature,
  syserr_exe_marked_invalid,
  syserr_bad_exe_format,
  syserr_iterated_data_exceeds_64k,
  syserr_invalid_minallocsize,
  syserr_dynlink_from_invalid_ring,
  syserr_iopl_not_enabled,
  syserr_invalid_segdpl,
  syserr_autodataseg_exceeds_64k,
  syserr_ring2seg_must_be_movable,
  syserr_reloc_chain_xeeds_seglim,
  syserr_infloop_in_reloc_chain,
  syserr_envvar_not_found,
  syserr_not_current_ctry,
  syserr_no_signal_sent,
  syserr_filename_exced_range,
  syserr_ring2_stack_in_use,
  syserr_meta_expansion_too_long,
  syserr_invalid_signal_number,
  syserr_thread_1_inactive,
  syserr_info_not_avail,
  syserr_locked,
  syserr_bad_dynalink,
  syserr_too_many_modules,
  syserr_nesting_not_allowed,
  syserr_cannot_shrink,
  syserr_zombie_process,
  syserr_stack_in_high_memory,
  syserr_invalid_exitroutine_ring,
  syserr_getbuf_failed,
  syserr_flushbuf_failed,
  syserr_transfer_too_long,
  syserr_forcenoswap_failed,
  syserr_smg_no_target_window,
  syserr_no_children,
  syserr_invalid_screen_group,
  syserr_bad_pipe,
  syserr_pipe_busy,
  syserr_no_data,
  syserr_pipe_not_connected,
  syserr_more_data,
  syserr_vc_disconnected,
  syserr_circularity_requested,
  syserr_directory_in_cds,
  syserr_invalid_fsd_name,
  syserr_invalid_path,
  syserr_invalid_ea_name,
  syserr_ea_list_inconsistent,
  syserr_ea_list_too_long,
  syserr_no_meta_match,
  syserr_findnotify_timeout,
  syserr_no_more_items,
  syserr_search_struc_reused,
  syserr_char_not_found,
  syserr_too_much_stack,
  syserr_invalid_attr,
  syserr_invalid_starting_ring,
  syserr_invalid_dll_init_ring,
  syserr_cannot_copy,
  syserr_directory,
  syserr_oplocked_file,
  syserr_oplock_thread_exists,
  syserr_volume_changed,
  syserr_findnotify_handle_in_use,
  syserr_findnotify_handle_closed,
  syserr_notify_object_removed,
  syserr_already_shutdown,
  syserr_eas_didnt_fit,
  syserr_ea_file_corrupt,
  syserr_ea_table_full,
  syserr_invalid_ea_handle,
  syserr_no_cluster,
  syserr_create_ea_file,
  syserr_cannot_open_ea_file,
  syserr_eas_not_supported,
  syserr_need_eas_found,
  syserr_duplicate_handle,
  syserr_duplicate_name,
  syserr_empty_muxwait,
  syserr_mutex_owned,
  syserr_not_owner,
  syserr_param_too_small,
  syserr_too_many_handles,
  syserr_too_many_opens,
  syserr_wrong_type,
  syserr_unused_code,
  syserr_thread_not_terminated,
  syserr_init_routine_failed,
  syserr_module_in_use,
  syserr_not_enough_watchpoints,
  syserr_too_many_posts,
  syserr_already_posted,
  syserr_already_reset,
  syserr_sem_busy,
  syserr_invalid_procid,
  syserr_invalid_pdelta,
  syserr_not_descendant,
  syserr_not_session_manager,
  syserr_invalid_pclass,
  syserr_invalid_scope,
  syserr_invalid_threadid,
  syserr_dossub_shrink,
  syserr_dossub_nomem,
  syserr_dossub_overlap,
  syserr_dossub_badsize,
  syserr_dossub_badflag,
  syserr_dossub_badselector,
  syserr_mr_msg_too_long,
  syserr_mr_mid_not_found,
  syserr_mr_un_acc_msgf,
  syserr_mr_inv_msgf_format,
  syserr_mr_inv_ivcount,
  syserr_mr_un_perform,
  syserr_ts_wakeup,
  syserr_ts_semhandle,
  syserr_ts_notimer,
  syserr_ts_handle,
  syserr_ts_datetime,
  syserr_sys_internal,
  syserr_que_current_name,
  syserr_que_proc_not_owned,
  syserr_que_proc_owned,
  syserr_que_duplicate,
  syserr_que_element_not_exist,
  syserr_que_no_memory,
  syserr_que_invalid_name,
  syserr_que_invalid_priority,
  syserr_que_invalid_handle,
  syserr_que_link_not_found,
  syserr_que_memory_error,
  syserr_que_prev_at_end,
  syserr_que_proc_no_access,
  syserr_que_empty,
  syserr_que_name_not_exist,
  syserr_que_not_initialized,
  syserr_que_unable_to_access,
  syserr_que_unable_to_add,
  syserr_que_unable_to_init,
  syserr_vio_invalid_mask,
  syserr_vio_ptr,
  syserr_vio_aptr,
  syserr_vio_rptr,
  syserr_vio_cptr,
  syserr_vio_lptr,
  syserr_vio_mode,
  syserr_vio_width,
  syserr_vio_attr,
  syserr_vio_row,
  syserr_vio_col,
  syserr_vio_toprow,
  syserr_vio_botrow,
  syserr_vio_rightcol,
  syserr_vio_leftcol,
  syserr_scs_call,
  syserr_scs_value,
  syserr_vio_wait_flag,
  syserr_vio_unlock,
  syserr_sgs_not_session_mgr,
  syserr_smg_invalid_session_id,
  syserr_smg_no_sessions,
  syserr_smg_session_not_found,
  syserr_smg_set_title,
  syserr_kbd_parameter,
  syserr_kbd_no_device,
  syserr_kbd_invalid_iowait,
  syserr_kbd_invalid_length,
  syserr_kbd_invalid_echo_mask,
  syserr_kbd_invalid_input_mask,
  syserr_mon_invalid_parms,
  syserr_mon_invalid_devname,
  syserr_mon_invalid_handle,
  syserr_mon_buffer_too_small,
  syserr_mon_buffer_empty,
  syserr_mon_data_too_large,
  syserr_mouse_no_device,
  syserr_mouse_inv_handle,
  syserr_mouse_inv_parms,
  syserr_mouse_cant_reset,
  syserr_mouse_display_parms,
  syserr_mouse_inv_module,
  syserr_mouse_inv_entry_pt,
  syserr_mouse_inv_mask,
  syserr_mouse_no_data,
  syserr_mouse_ptr_drawn,
  syserr_invalid_frequency,
  syserr_nls_no_country_file,
  syserr_nls_open_failed,
  syserr_no_country_or_codepage,
  syserr_nls_table_truncated,
  syserr_nls_bad_type,
  syserr_nls_type_not_found,
  syserr_vio_smg_only,
  syserr_vio_invalid_asciiz,
  syserr_vio_deregister,
  syserr_vio_no_popup,
  syserr_vio_existing_popup,
  syserr_kbd_smg_only,
  syserr_kbd_invalid_asciiz,
  syserr_kbd_invalid_mask,
  syserr_kbd_register,
  syserr_kbd_deregister,
  syserr_mouse_smg_only,
  syserr_mouse_invalid_asciiz,
  syserr_mouse_invalid_mask,
  syserr_mouse_register,
  syserr_mouse_deregister,
  syserr_smg_bad_action,
  syserr_smg_invalid_call,
  syserr_scs_sg_notfound,
  syserr_scs_not_shell,
  syserr_vio_invalid_parms,
  syserr_vio_function_owned,
  syserr_vio_return,
  syserr_scs_invalid_function,
  syserr_scs_not_session_mgr,
  syserr_vio_register,
  syserr_vio_no_mode_thread,
  syserr_vio_no_save_restore_thd,
  syserr_vio_in_bg,
  syserr_vio_illegal_during_popup,
  syserr_smg_not_baseshell,
  syserr_smg_bad_statusreq,
  syserr_que_invalid_wait,
  syserr_vio_lock,
  syserr_mouse_invalid_iowait,
  syserr_vio_invalid_handle,
  syserr_vio_illegal_during_lock,
  syserr_vio_invalid_length,
  syserr_kbd_invalid_handle,
  syserr_kbd_no_more_handle,
  syserr_kbd_cannot_create_kcb,
  syserr_kbd_codepage_load_incompl,
  syserr_kbd_invalid_codepage_id,
  syserr_kbd_no_codepage_support,
  syserr_kbd_focus_required,
  syserr_kbd_focus_already_active,
  syserr_kbd_keyboard_busy,
  syserr_kbd_invalid_codepage,
  syserr_kbd_unable_to_focus,
  syserr_smg_session_non_select,
  syserr_smg_session_not_foregrnd,
  syserr_smg_session_not_parent,
  syserr_smg_invalid_start_mode,
  syserr_smg_invalid_related_opt,
  syserr_smg_invalid_bond_option,
  syserr_smg_invalid_select_opt,
  syserr_smg_start_in_background,
  syserr_smg_invalid_stop_option,
  syserr_smg_bad_reserve,
  syserr_smg_process_not_parent,
  syserr_smg_invalid_data_length,
  syserr_smg_not_bound,
  syserr_smg_retry_sub_alloc,
  syserr_kbd_detached,
  syserr_vio_detached,
  syserr_mou_detached,
  syserr_vio_font,
  syserr_vio_user_font,
  syserr_vio_bad_cp,
  syserr_vio_no_cp,
  syserr_vio_na_cp,
  syserr_invalid_code_page,
  syserr_cplist_too_small,
  syserr_cp_not_moved,
  syserr_mode_switch_init,
  syserr_code_page_not_found,
  syserr_unexpected_slot_returned,
  syserr_smg_invalid_trace_option,
  syserr_vio_internal_resource,
  syserr_vio_shell_init,
  syserr_smg_no_hard_errors,
  syserr_cp_switch_incomplete,
  syserr_vio_transparent_popup,
  syserr_critsec_overflow,
  syserr_critsec_underflow,
  syserr_vio_bad_reserve,
  syserr_invalid_address,
  syserr_zero_selectors_requested,
  syserr_not_enough_selectors_ava,
  syserr_invalid_selector,
  syserr_smg_invalid_program_type,
  syserr_smg_invalid_pgm_control,
  syserr_smg_invalid_inherit_opt,
  syserr_vio_extended_sg,
  syserr_vio_not_pres_mgr_sg,
  syserr_vio_shield_owned,
  syserr_vio_no_more_handles,
  syserr_vio_see_error_log,
  syserr_vio_associated_dc,
  syserr_kbd_no_console,
  syserr_mouse_no_console,
  syserr_mouse_invalid_handle,
  syserr_smg_invalid_debug_parms,
  syserr_kbd_extended_sg,
  syserr_mou_extended_sg,
  syserr_smg_invalid_icon_file,
  syserr_trc_pid_non_existent,
  syserr_trc_count_active,
  syserr_trc_suspended_by_count,
  syserr_trc_count_inactive,
  syserr_trc_count_reached,
  syserr_no_mc_trace,
  syserr_mc_trace,
  syserr_trc_count_zero,
  syserr_smg_too_many_dds,
  syserr_smg_invalid_notification,
  syserr_lf_invalid_function,
  syserr_lf_not_avail,
  syserr_lf_suspended,
  syserr_lf_buf_too_small,
  syserr_lf_buffer_full,
  syserr_lf_invalid_record,
  syserr_lf_invalid_service,
  syserr_lf_general_failure,
  syserr_lf_invalid_id,
  syserr_lf_invalid_handle,
  syserr_lf_no_id_avail,
  syserr_lf_template_area_full,
  syserr_lf_id_in_use,
  syserr_mou_not_initialized,
  syserr_mouinitreal_done,
  syserr_dossub_corrupted,
  syserr_mouse_caller_not_subsys,
  syserr_arithmetic_overflow,
  syserr_tmr_no_device,
  syserr_tmr_invalid_time,
  syserr_pvw_invalid_entity,
  syserr_pvw_invalid_entity_type,
  syserr_pvw_invalid_spec,
  syserr_pvw_invalid_range_type,
  syserr_pvw_invalid_counter_blk,
  syserr_pvw_invalid_text_blk,
  syserr_prf_not_initialized,
  syserr_prf_already_initialized,
  syserr_prf_not_started,
  syserr_prf_already_started,
  syserr_prf_timer_out_of_range,
  syserr_prf_timer_reset,
  syserr_vdd_lock_useage_denied,
  syserr_timeout,
  syserr_vdm_down,
  syserr_vdm_limit,
  syserr_vdd_not_found,
  syserr_invalid_caller,
  syserr_pid_mismatch,
  syserr_invalid_vdd_handle,
  syserr_vlpt_no_spooler,
  syserr_vcom_device_busy,
  syserr_vlpt_device_busy,
  syserr_nesting_too_deep,
  syserr_vdd_missing,
  syserr_bidi_invalid_length,
  syserr_bidi_invalid_increment,
  syserr_bidi_invalid_combination,
  syserr_bidi_invalid_reserved,
  syserr_bidi_invalid_effect,
  syserr_bidi_invalid_csdrec,
  syserr_bidi_invalid_csdstate,
  syserr_bidi_invalid_level,
  syserr_bidi_invalid_type_support,
  syserr_bidi_invalid_orientation,
  syserr_bidi_invalid_num_shape,
  syserr_bidi_invalid_csd,
  syserr_bidi_no_support,
  syserr_bidi_rw_incomplete,
  syserr_imp_invalid_parm,
  syserr_imp_invalid_length,
  syserr_hpfs_disk_error_warn,
  syserr_mon_bad_buffer,
  syserr_module_corrupted,
  syserr_sm_outof_swapfile,
  syserr_lf_timeout,
  syserr_lf_suspend_success,
  syserr_lf_resume_success,
  syserr_lf_redirect_success,
  syserr_lf_redirect_failure,
  syserr_swapper_not_active,
  syserr_invalid_swapid,
  syserr_ioerr_swap_file,
  syserr_swap_table_full,
  syserr_swap_file_full,
  syserr_cant_init_swapper,
  syserr_swapper_already_init,
  syserr_pmm_insufficient_memory,
  syserr_pmm_invalid_flags,
  syserr_pmm_invalid_address,
  syserr_pmm_lock_failed,
  syserr_pmm_unlock_failed,
  syserr_pmm_move_incomplete,
  syserr_ucom_drive_renamed,
  syserr_ucom_filename_truncated,
  syserr_ucom_buffer_length,
  syserr_mon_chain_handle,
  syserr_mon_not_registered,
  syserr_smg_already_top,
  syserr_pmm_arena_modified,
  syserr_smg_printer_open,
  syserr_pmm_set_flags_failed,
  syserr_invalid_dos_dd,
  syserr_blocked,
  syserr_noblock,
  syserr_instance_shared,
  syserr_no_object,
  syserr_partial_attach,
  syserr_incache,
  syserr_swap_io_problems,
  syserr_crosses_object_boundary,
  syserr_longlock,
  syserr_shortlock,
  syserr_uvirtlock,
  syserr_aliaslock,
  syserr_alias,
  syserr_no_more_handles,
  syserr_scan_terminated,
  syserr_terminator_not_found,
  syserr_not_direct_child,
  syserr_delay_free,
  syserr_guardpage,
  syserr_swaperror,
  syserr_ldrerror,
  syserr_nomemory,
  syserr_noaccess,
  syserr_no_dll_term,
  syserr_cpsio_code_page_invalid,
  syserr_cpsio_no_spooler,
  syserr_cpsio_font_id_invalid,
  syserr_cpsio_internal_error,
  syserr_cpsio_invalid_ptr_name,
  syserr_cpsio_not_active,
  syserr_cpsio_pid_full,
  syserr_cpsio_pid_not_found,
  syserr_cpsio_read_ctl_seq,
  syserr_cpsio_read_fnt_def,
  syserr_cpsio_write_error,
  syserr_cpsio_write_full_error,
  syserr_cpsio_write_handle_bad,
  syserr_cpsio_swit_load,
  syserr_cpsio_inv_command,
  syserr_cpsio_no_font_swit,
  syserr_entry_is_callgate,
  syserr_unknown
};

#define syserr_not_enough_space syserr_not_enough_memory

#else /* not _OS2 */

enum syscall_names
{
  syscall_accept,
  syscall_bind,
  syscall_chdir,
  syscall_chmod,
  syscall_close,
  syscall_connect,
  syscall_fcntl_GETFL,
  syscall_fcntl_SETFL,
  syscall_fork,
  syscall_fstat,
  syscall_ftruncate,
  syscall_getcwd,
  syscall_gethostname,
  syscall_gettimeofday,
  syscall_ioctl_TIOCGPGRP,
  syscall_ioctl_TIOCSIGSEND,
  syscall_kill,
  syscall_link,
  syscall_listen,
  syscall_localtime,
  syscall_lseek,
  syscall_malloc,
  syscall_mkdir,
  syscall_open,
  syscall_opendir,
  syscall_pause,
  syscall_pipe,
  syscall_read,
  syscall_readlink,
  syscall_realloc,
  syscall_rename,
  syscall_rmdir,
  syscall_select,
  syscall_setitimer,
  syscall_setpgid,
  syscall_sighold,
  syscall_sigprocmask,
  syscall_sigsuspend,
  syscall_sleep,
  syscall_socket,
  syscall_symlink,
  syscall_tcdrain,
  syscall_tcflush,
  syscall_tcgetpgrp,
  syscall_tcsetpgrp,
  syscall_terminal_get_state,
  syscall_terminal_set_state,
  syscall_time,
  syscall_times,
  syscall_unlink,
  syscall_utime,
  syscall_vfork,
  syscall_write,
  syscall_stat,
  syscall_lstat,
  syscall_mktime,
  syscall_dld
};

enum syserr_names
{
  syserr_unknown,
  syserr_arg_list_too_long,
  syserr_bad_address,
  syserr_bad_file_descriptor,
  syserr_broken_pipe,
  syserr_directory_not_empty,
  syserr_domain_error,
  syserr_exec_format_error,
  syserr_file_exists,
  syserr_file_too_large,
  syserr_filename_too_long,
  syserr_function_not_implemented,
  syserr_improper_link,
  syserr_inappropriate_io_control_operation,
  syserr_interrupted_function_call,
  syserr_invalid_argument,
  syserr_invalid_seek,
  syserr_io_error,
  syserr_is_a_directory,
  syserr_no_child_processes,
  syserr_no_locks_available,
  syserr_no_space_left_on_device,
  syserr_no_such_device,
  syserr_no_such_device_or_address,
  syserr_no_such_file_or_directory,
  syserr_no_such_process,
  syserr_not_a_directory,
  syserr_not_enough_space,
  syserr_operation_not_permitted,
  syserr_permission_denied,
  syserr_read_only_file_system,
  syserr_resource_busy,
  syserr_resource_deadlock_avoided,
  syserr_resource_temporarily_unavailable,
  syserr_result_too_large,
  syserr_too_many_links,
  syserr_too_many_open_files,
  syserr_too_many_open_files_in_system
};

#endif /* not _OS2 */

extern void EXFUN (error_in_system_call,
		   (enum syserr_names, enum syscall_names));
extern void EXFUN (error_system_call, (int, enum syscall_names name));
extern enum syserr_names EXFUN (OS_error_code_to_syserr, (int));

#endif /* SCM_SYSCALL_H */
