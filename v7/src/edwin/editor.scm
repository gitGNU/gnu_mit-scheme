;;; -*-Scheme-*-
;;;
;;;	$Id: editor.scm,v 1.240.1.1 1998/10/19 01:23:10 cph Exp $
;;;
;;;	Copyright (c) 1986, 1989-95 Massachusetts Institute of Technology
;;;
;;;	This material was developed by the Scheme project at the
;;;	Massachusetts Institute of Technology, Department of
;;;	Electrical Engineering and Computer Science.  Permission to
;;;	copy and modify this software, to redistribute either the
;;;	original software or a modified version, and to use this
;;;	software for any purpose is granted, subject to the following
;;;	restrictions and understandings.
;;;
;;;	1. Any copy made of this software must include this copyright
;;;	notice in full.
;;;
;;;	2. Users of this software agree to make their best efforts (a)
;;;	to return to the MIT Scheme project any improvements or
;;;	extensions that they make, so that these may be included in
;;;	future releases; and (b) to inform MIT of noteworthy uses of
;;;	this software.
;;;
;;;	3. All materials developed as a consequence of the use of this
;;;	software shall duly acknowledge such use, in accordance with
;;;	the usual standards of acknowledging credit in academic
;;;	research.
;;;
;;;	4. MIT has made no warrantee or representation that the
;;;	operation of this software will be error-free, and MIT is
;;;	under no obligation to provide any services, by way of
;;;	maintenance, update, or otherwise.
;;;
;;;	5. In conjunction with products arising from the use of this
;;;	material, there shall be no use of the name of the
;;;	Massachusetts Institute of Technology nor of any adaptation
;;;	thereof in any advertising, promotional, or sales literature
;;;	without prior written consent from MIT in each case.
;;;
;;; NOTE: Parts of this program (Edwin) were created by translation
;;; from corresponding parts of GNU Emacs.  Users should be aware that
;;; the GNU GENERAL PUBLIC LICENSE may apply to these parts.  A copy
;;; of that license should have been included along with this file.
;;;

;;;; Editor Top Level

(declare (usual-integrations))

(define (edit . args)
  (call-with-current-continuation
   (lambda (continuation)
     (cond (within-editor?
	    (error "edwin: Editor already running"))
	   ((not edwin-editor)
	    (apply create-editor args))
	   ((not (null? args))
	    (error "edwin: Arguments ignored when re-entering editor" args))
	   (edwin-continuation
	    => (lambda (restart)
		 (set! edwin-continuation false)
		 (within-continuation restart
		   (lambda ()
		     (set! editor-abort continuation)
		     unspecific)))))
     (fluid-let ((editor-abort continuation)
		 (current-editor edwin-editor)
		 (within-editor? true)
		 (editor-thread (current-thread))
		 (editor-thread-root-continuation)
		 (editor-initial-threads '())
		 (inferior-thread-changes? false)
		 (inferior-threads '())
		 (recursive-edit-continuation false)
		 (recursive-edit-level 0))
       (editor-grab-display edwin-editor
	 (lambda (with-editor-ungrabbed operations)
	   (let ((message (cmdl-message/null)))
	     (cmdl/start
	      (make-cmdl
	       (nearest-cmdl)
	       dummy-i/o-port
	       (lambda (cmdl)
		 cmdl		;ignore
		 (bind-condition-handler (list condition-type:error)
		     internal-error-handler
		   (lambda ()
		     (call-with-current-continuation
		      (lambda (root-continuation)
			(set! editor-thread-root-continuation
			      root-continuation)
			(with-notification-output-port null-output-port
			  (lambda ()
			    (do ((thunks (let ((thunks editor-initial-threads))
					   (set! editor-initial-threads '())
					   thunks)
					 (cdr thunks)))
				((null? thunks))
			      (create-thread root-continuation (car thunks)))
			    (top-level-command-reader
			     edwin-initialization)))))))
		 message)
	       false
	       `((START-CHILD ,(editor-start-child-cmdl with-editor-ungrabbed))
		 (CHILD-PORT ,(editor-child-cmdl-port (nearest-cmdl/port)))
		 ,@operations))
	      message))))))))

(define (edwin . args) (apply edit args))
(simple-option-parser "-edit" edit)

(define edwin-editor false)
(define editor-abort)
(define current-editor)
(define within-editor? false)
(define editor-thread)
(define editor-thread-root-continuation)
(define editor-initial-threads)
(define edwin-continuation)

;; Set this before entering the editor to get something done after the
;; editor's dynamic environment is initialized, but before the command
;; loop is started.
(define edwin-initialization false)

(define (queue-initial-thread thunk)
  (set! editor-initial-threads (cons thunk editor-initial-threads))
  unspecific)

(define create-editor-args
  '())

(define (create-editor . args)
  (let ((args
	 (if (null? args)
	     create-editor-args
	     (begin
	       (set! create-editor-args args)
	       args))))
    (reset-editor)
    (initialize-typein!)
    (initialize-typeout!)
    (initialize-command-reader!)
    (initialize-processes!)
    (initialize-inferior-repls!)
    (set! edwin-editor
	  (make-editor "Edwin"
		       (let ((name (and (not (null? args)) (car args))))
			 (if name
			     (let ((type (name->display-type name)))
			       (if (not type)
				   (error "Unknown display type name:" name))
			       (if (not (display-type/available? type))
				   (error "Requested display type unavailable:"
					  type))
			       type)
			     (default-display-type '())))
		       (if (null? args) '() (cdr args))))
    (set! edwin-initialization
	  (lambda ()
	    (set! edwin-initialization false)
	    (standard-editor-initialization)))
    (set! edwin-continuation false)
    unspecific))

(define (default-display-type preferences)
  (define (fail)
    (error "Can't find any usable display type"))

  (define (find-any)
    (let ((types (editor-display-types)))
      (if (null? types)
	  (fail)
	  (car types))))

  (define (find-preferred display-type-names)
    (if (null? display-type-names)
	(find-any)
	(let ((next (name->display-type (car display-type-names))))
	  (if (and next 
		   (display-type/available? next))
	      next
	      (find-preferred (cdr display-type-names))))))

  (find-preferred preferences))

(define (standard-editor-initialization)
  (with-editor-interrupts-disabled
   (lambda ()
     (if (and (not init-file-loaded?)
	      (not inhibit-editor-init-file?))
	 (begin
	   (let ((filename (os/init-file-name)))
	     (if (file-exists? filename)
		 (load-edwin-file filename '(EDWIN) #t)))
	   (set! init-file-loaded? #t)
	   unspecific))))
  (let ((buffer (find-buffer initial-buffer-name)))
    (if (and buffer
	     (not inhibit-initial-inferior-repl?))
	(start-inferior-repl!
	 buffer
	 (nearest-repl/environment)
	 (nearest-repl/syntax-table)
	 (and (not (ref-variable inhibit-startup-message))
	      (cmdl-message/append
	       (cmdl-message/active
		(lambda (port)
		  (identify-world port)
		  (newline port)
		  (newline port)))
	       (cmdl-message/strings
		"You are in an interaction window of the Edwin editor."
		"Type C-h for help.  C-h m will describe some commands.")))))))

(define inhibit-editor-init-file? #f)
(define init-file-loaded? #f)
(define inhibit-initial-inferior-repl? #f)

(define-variable inhibit-startup-message
  "True inhibits the initial startup messages.
This is for use in your personal init file, once you are familiar
with the contents of the startup message."
  #f
  boolean?)

(define (reset-editor)
  (without-interrupts
   (lambda ()
     (if edwin-editor
	 (begin
	   (for-each (lambda (screen)
		       (screen-discard! screen))
		     (editor-screens edwin-editor))
	   (set! edwin-editor false)
	   (set! edwin-continuation)
	   (set! init-file-loaded? false)
	   (weak-set-car! *previous-popped-up-window* #f)
	   (weak-set-car! *previous-popped-up-buffer* #f)
	   (weak-set-car! *minibuffer-scroll-window* #f)
	   unspecific)))))

(define (reset-editor-windows)
  (for-each (lambda (screen)
	      (send (screen-root-window screen) ':salvage!))
	    (editor-screens edwin-editor)))

(define (enter-recursive-edit)
  (let ((value
	 (call-with-current-continuation
	   (lambda (continuation)
	     (fluid-let ((recursive-edit-continuation continuation)
			 (recursive-edit-level (1+ recursive-edit-level)))
	       (let ((recursive-edit-event!
		      (lambda ()
			(for-each (lambda (window)
				    (window-modeline-event! window
							    'RECURSIVE-EDIT))
				  (window-list)))))
		 (dynamic-wind recursive-edit-event!
			       command-reader
			       recursive-edit-event!)))))))
    (if (eq? value 'ABORT)
	(abort-current-command)
	(begin
	  (reset-command-prompt!)
	  value))))

(define (exit-recursive-edit value)
  (if recursive-edit-continuation
      (recursive-edit-continuation value)
      (editor-error "No recursive edit is in progress")))

(define recursive-edit-continuation)
(define recursive-edit-level)

(define (editor-gc-daemon)
  (let ((editor edwin-editor))
    (if editor
	(do ((buffers (bufferset-buffer-list (editor-bufferset editor))
		      (cdr buffers)))
	    ((null? buffers))
	  (clean-group-marks! (buffer-group (car buffers)))))))

(add-gc-daemon!/no-restore editor-gc-daemon)
(add-event-receiver! event:after-restore editor-gc-daemon)

(define (internal-error-handler condition)
  (cond ((and (eq? condition-type:primitive-procedure-error
		   (condition/type condition))
	      (let ((operator (access-condition condition 'OPERATOR)))
		(or (eq? operator (ucode-primitive x-display-process-events 2))
		    (eq? operator (ucode-primitive x-display-flush 1)))))
	 ;; This error indicates that the connection to the X server
	 ;; has been broken.  The safest thing to do is to kill the
	 ;; editor.
	 (exit-editor))
	(debug-internal-errors?
	 (error condition))
	((ref-variable debug-on-internal-error)
	 (debug-scheme-error condition "internal"))
	(else
	 (editor-beep)
	 (message (condition/report-string condition))
	 (return-to-command-loop condition))))

(define-variable debug-on-internal-error
  "True means enter debugger if error is signalled while the editor is running.
This does not affect editor errors or evaluation errors."
  false)

(define debug-internal-errors? false)

(define condition-type:editor-error
  (make-condition-type 'EDITOR-ERROR condition-type:error '(STRINGS)
    (lambda (condition port)
      (write-string "Editor error: " port)
      (write-string (message-args->string (editor-error-strings condition))
		    port))))

(define editor-error
  (let ((signaller
	 (condition-signaller condition-type:editor-error
			      '(STRINGS)
			      standard-error-handler)))
    (lambda strings
      (signaller strings))))

(define editor-error-strings
  (condition-accessor condition-type:editor-error 'STRINGS))

(define (editor-error-handler condition)
  (if (ref-variable debug-on-editor-error)
      (debug-scheme-error condition "editor")
      (begin
	(editor-beep)
	(let ((strings (editor-error-strings condition)))
	  (if (not (null? strings))
	      (apply message strings)))
	(return-to-command-loop condition))))

(define-variable debug-on-editor-error
  "True means signal Scheme error when an editor error occurs."
  false)

(define condition-type:abort-current-command
  (make-condition-type 'ABORT-CURRENT-COMMAND #f '(INPUT)
    (lambda (condition port)
      (write-string "Abort current command" port)
      (let ((input (abort-current-command/input condition)))
	(if input
	    (begin
	      (write-string " with input: " port)
	      (write input port))))
      (write-string "." port))))

(define condition/abort-current-command?
  (condition-predicate condition-type:abort-current-command))

(define abort-current-command/input
  (condition-accessor condition-type:abort-current-command 'INPUT))

(define abort-current-command
  (let ((signaller
	 (condition-signaller condition-type:abort-current-command
			      '(INPUT)
			      standard-error-handler)))
    (lambda (#!optional input)
      (let ((input (if (default-object? input) #f input)))
	(if (not (or (not input) (input-event? input)))
	    (error:wrong-type-argument input "input event"
				       'ABORT-CURRENT-COMMAND))
	(keyboard-macro-disable)
	(signaller input)))))

(define-structure (input-event
		   (constructor make-input-event (type operator . operands))
		   (conc-name input-event/))
  (type false read-only true)
  (operator false read-only true)
  (operands false read-only true))

(define (apply-input-event input-event)
  (if (not (input-event? input-event))
      (error:wrong-type-argument input-event "input event" apply-input-event))
  (apply (input-event/operator input-event)
	 (input-event/operands input-event)))

(define condition-type:^G
  (make-condition-type '^G condition-type:abort-current-command '()
    (lambda (condition port)
      condition
      (write-string "Signal editor ^G." port))))

(define condition/^G?
  (condition-predicate condition-type:^G))

(define ^G-signal
  (let ((signaller
	 (condition-signaller condition-type:^G
			      '(INPUT)
			      standard-error-handler)))
    (lambda ()
      (signaller #f))))

(define (quit-editor-and-signal-error condition)
  (quit-editor-and (lambda () (error condition))))

(define (quit-editor)
  (quit-editor-and (lambda () *the-non-printing-object*)))

(define (quit-scheme)
  (let ((dir (buffer-default-directory (current-buffer))))
    (quit-editor-and (lambda () (os/quit dir) (edit)))))

(define (quit-editor-and thunk)
  (call-with-current-continuation
   (lambda (continuation)
     (within-continuation editor-abort
       (lambda ()
	 (set! edwin-continuation continuation)
	 (thunk))))))

(define (exit-editor)
  (within-continuation editor-abort reset-editor))

(define (exit-scheme)
  (within-continuation editor-abort %exit))

(define call-with-protected-continuation
  call-with-current-continuation)

(define (unwind-protect setup body cleanup)
  (dynamic-wind (or setup (lambda () unspecific)) body cleanup))

(define (editor-grab-display editor receiver)
  (display-type/with-display-grabbed (editor-display-type editor)
    (lambda (with-display-ungrabbed operations)
      (with-current-local-bindings!
	(lambda ()
	  (let ((enter
		 (lambda ()
		   (let ((screen (selected-screen)))
		     (screen-enter! screen)
		     (update-screen! screen true))))
		(exit
		 (lambda ()
		   (screen-exit! (selected-screen)))))
	    (dynamic-wind enter
			  (lambda ()
			    (receiver
			     (lambda (thunk)
			       (dynamic-wind exit
					     (lambda ()
					       (with-display-ungrabbed thunk))
					     enter))
			      operations))
			  exit)))))))

(define dummy-i/o-port
  (make-i/o-port
   (map (lambda (name)
	  (list name
		(lambda (port . ignore)
		  ignore
		  (error "Attempt to perform a"
			 name
			 (error-irritant/noise " operation on dummy I/O port:")
			 port))))
	'(CHAR-READY? READ-CHAR PEEK-CHAR WRITE-CHAR))
   #f))

(define null-output-port
  (make-output-port `((WRITE-CHAR ,(lambda (port char) port char unspecific)))
		    #f))

(define (editor-start-child-cmdl with-editor-ungrabbed)
  (lambda (cmdl thunk) cmdl (with-editor-ungrabbed thunk)))

(define (editor-child-cmdl-port port)
  (lambda (cmdl) cmdl port))

(define inferior-thread-changes?)
(define inferior-threads)

(define (register-inferior-thread! thread output-processor)
  (let ((flags (cons false output-processor)))
    (set! inferior-threads
	  (cons (system-pair-cons (ucode-type weak-cons) thread flags)
		inferior-threads))
    flags))

(define (deregister-inferior-thread! flags)
  (let loop ((threads inferior-threads))
    (if (pair? threads)
	(if (eq? flags (system-pair-cdr (car threads)))
	    (begin
	      (system-pair-set-car! (car threads) #f)
	      (system-pair-set-cdr! (car threads) #f))
	    (loop (cdr threads))))))

(define (inferior-thread-output! flags)
  (without-interrupts (lambda () (inferior-thread-output!/unsafe flags))))

(define-integrable (inferior-thread-output!/unsafe flags)
  (set-car! flags true)
  (set! inferior-thread-changes? true)
  (signal-thread-event editor-thread #f))

(define (accept-thread-output)
  (without-interrupts
   (lambda ()
     (and inferior-thread-changes?
	  (begin
	    (set! inferior-thread-changes? false)
	    (let loop ((threads inferior-threads) (prev false) (output? false))
	      (if (null? threads)
		  output?
		  (let ((record (car threads))
			(next (cdr threads)))
		    (let ((thread (system-pair-car record))
			  (flags (system-pair-cdr record)))
		      (if (and thread (not (thread-dead? thread)))
			  (loop next
				threads
				(if (car flags)
				    (begin
				      (set-car! flags false)
				      (let ((result ((cdr flags))))
					(if (eq? output? 'FORCE-RETURN)
					    output?
					    (or result output?))))
				    output?))
			  (begin
			    (if prev
				(set-cdr! prev next)
				(set! inferior-threads next))
			    (loop next prev output?))))))))))))