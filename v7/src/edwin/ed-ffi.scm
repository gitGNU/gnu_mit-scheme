;;; -*- Scheme -*-

(declare (usual-integrations))

;; This list must be kept in alphabetical order by filename.

(standard-scheme-find-file-initialization
 '#(("argred"  (edwin command-argument)
	       edwin-syntax-table)
    ("autold"  (edwin)
	       edwin-syntax-table)
    ("autosv"  (edwin)
	       edwin-syntax-table)
    ("basic"   (edwin)
	       edwin-syntax-table)
    ("bufcom"  (edwin)
	       edwin-syntax-table)
    ("buffer"  (edwin)
	       edwin-syntax-table)
    ("buffrm"  (edwin window)
	       class-syntax-table)
    ("bufinp"  (edwin buffer-input-port)
	       syntax-table/system-internal)
    ("bufmnu"  (edwin buffer-menu)
	       edwin-syntax-table)
    ("bufout"  (edwin buffer-output-port)
	       syntax-table/system-internal)
    ("bufset"  (edwin)
	       edwin-syntax-table)
    ("bufwfs"  (edwin window)
	       class-syntax-table)
    ("bufwin"  (edwin window)
	       class-syntax-table)
    ("bufwiu"  (edwin window)
	       class-syntax-table)
    ("bufwmc"  (edwin window)
	       class-syntax-table)
    ("c-mode"  (edwin)
	       edwin-syntax-table)
    ("calias"  (edwin)
	       edwin-syntax-table)
    ("cinden"  (edwin c-indentation)
	       edwin-syntax-table)
    ("class"   (edwin)
	       syntax-table/system-internal)
    ("clscon"  (edwin class-constructor)
	       syntax-table/system-internal)
    ("clsmac"  (edwin class-macros)
	       syntax-table/system-internal)
    ("comint"  (edwin)
	       edwin-syntax-table)
    ("comman"  (edwin)
	       edwin-syntax-table)
    ("compile" (edwin)
	       edwin-syntax-table)
    ("comred"  (edwin command-reader)
	       edwin-syntax-table)
    ("comtab"  (edwin comtab)
	       edwin-syntax-table)
    ("comwin"  (edwin window combination)
	       class-syntax-table)
    ("curren"  (edwin)
	       edwin-syntax-table)
    ("debug"   (edwin debugger)
	       edwin-syntax-table)
    ("debuge"  (edwin)
	       edwin-syntax-table)
    ("dired"   (edwin dired)
	       edwin-syntax-table)
    ("display" (edwin display-type)
	       syntax-table/system-internal)
    ("ed-ffi"  (edwin)
	       edwin-syntax-table)
    ("editor"  (edwin)
	       edwin-syntax-table)
    ("edtfrm"  (edwin window)
	       class-syntax-table)
    ("edtstr"  (edwin)
	       edwin-syntax-table)
    ("evlcom"  (edwin)
	       edwin-syntax-table)
    ("filcom"  (edwin)
	       edwin-syntax-table)
    ("fileio"  (edwin)
	       edwin-syntax-table)
    ("fill"    (edwin)
	       edwin-syntax-table)
    ("grpops"  (edwin group-operations)
	       syntax-table/system-internal)
    ("hlpcom"  (edwin)
	       edwin-syntax-table)
    ("image"   (edwin)
	       syntax-table/system-internal)
    ("info"    (edwin info)
	       edwin-syntax-table)
    ("input"   (edwin keyboard)
	       edwin-syntax-table)
    ("intmod"  (edwin inferior-repl)
	       edwin-syntax-table)
    ("iserch"  (edwin incremental-search)
	       edwin-syntax-table)
    ("key"     (edwin keys)
	       edwin-syntax-table)
    ("keymap"  (edwin command-summary)
	       edwin-syntax-table)
    ("kilcom"  (edwin)
	       edwin-syntax-table)
    ("kmacro"  (edwin)
	       edwin-syntax-table)
    ("lincom"  (edwin)
	       edwin-syntax-table)
    ("linden"  (edwin lisp-indentation)
	       edwin-syntax-table)
    ("loadef"  (edwin)
	       edwin-syntax-table)
    ("lspcom"  (edwin)
	       edwin-syntax-table)
    ("macros"  (edwin macros)
	       syntax-table/system-internal)
    ("make"    ()
	       syntax-table/system-internal)
    ("malias"  (edwin mail-alias)
	       edwin-syntax-table)
    ("manual"  (edwin)
	       edwin-syntax-table)
    ("midas"   (edwin)
	       edwin-syntax-table)
    ("modefs"  (edwin)
	       edwin-syntax-table)
    ("modes"   (edwin)
	       edwin-syntax-table)
    ("modlin"  (edwin modeline-string)
	       edwin-syntax-table)
    ("modwin"  (edwin window)
	       class-syntax-table)
    ("motcom"  (edwin)
	       edwin-syntax-table)
    ("motion"  (edwin)
	       syntax-table/system-internal)
    ("notify"  (edwin)
	       edwin-syntax-table)
    ("nvector" (edwin)
	       syntax-table/system-internal)
    ("occur"   (edwin occurrence)
	       edwin-syntax-table)
    ("outline" (edwin)
	       edwin-syntax-table)
    ("pasmod"  (edwin)
	       edwin-syntax-table)
    ("paths"   (edwin)
	       syntax-table/system-internal)
    ("print"   (edwin)
	       edwin-syntax-table)
    ("process" (edwin process)
	       edwin-syntax-table)
    ("prompt"  (edwin prompt)
	       edwin-syntax-table)
    ("rcs"     (edwin rcs)
	       edwin-syntax-table)
    ("reccom"  (edwin rectangle)
	       edwin-syntax-table)
    ("regcom"  (edwin register-command)
	       edwin-syntax-table)
    ("regexp"  (edwin regular-expression)
	       edwin-syntax-table)
    ("regops"  (edwin)
	       syntax-table/system-internal)
    ("rename"  ()
	       syntax-table/system-internal)
    ("replaz"  (edwin)
	       edwin-syntax-table)
    ("rgxcmp"  (edwin regular-expression-compiler)
	       syntax-table/system-internal)
    ("ring"    (edwin)
	       syntax-table/system-internal)
    ("rmail"   (edwin rmail)
	       edwin-syntax-table)
    ("rmailsrt" (edwin rmail)
	       edwin-syntax-table)
    ("rmailsum" (edwin rmail)
	       edwin-syntax-table)
    ("schmod"  (edwin)
	       edwin-syntax-table)
    ("scrcom"  (edwin)
	       edwin-syntax-table)
    ("screen"  (edwin screen)
	       edwin-syntax-table)
    ("search"  (edwin)
	       syntax-table/system-internal)
    ("sendmail" (edwin sendmail)
		edwin-syntax-table)
    ("sercom"  (edwin)
	       edwin-syntax-table)
    ("shell"   (edwin)
	       edwin-syntax-table)
    ("simple"  (edwin)
	       syntax-table/system-internal)
    ("sort"    (edwin)
	       edwin-syntax-table)
    ("strpad"  (edwin)
	       syntax-table/system-internal)
    ("strtab"  (edwin)
	       syntax-table/system-internal)
    ("struct"  (edwin)
	       edwin-syntax-table)
    ("syntax"  (edwin)
	       edwin-syntax-table)
    ("tagutl"  (edwin tags)
	       edwin-syntax-table)
    ("techinfo"   (edwin)
	       edwin-syntax-table)
    ("telnet"   (edwin)
	       edwin-syntax-table)
    ("termcap" (edwin console-screen)
	       syntax-table/system-internal)
    ("texcom"  (edwin)
	       edwin-syntax-table)
    ("things"  (edwin)
	       edwin-syntax-table)
    ("tparse"  (edwin)
	       edwin-syntax-table)
    ("tterm"   (edwin console-screen)
	       syntax-table/system-internal)
    ("tximod"  (edwin)
	       edwin-syntax-table)
    ("undo"    (edwin undo)
	       edwin-syntax-table)
    ("unix"    (edwin)
	       edwin-syntax-table)
    ("utils"   (edwin)
	       syntax-table/system-internal)
    ("utlwin"  (edwin window)
	       class-syntax-table)
    ("wincom"  (edwin)
	       edwin-syntax-table)
    ("window"  (edwin window)
	       class-syntax-table)
    ("winout"  (edwin window-output-port)
	       syntax-table/system-internal)
    ("winren"  (edwin)
	       syntax-table/system-internal)
    ("xcom"    (edwin x-commands)
	       edwin-syntax-table)
    ("xform"   (edwin class-macros transform-instance-variables)
	       syntax-table/system-internal)
    ("xterm"   (edwin x-screen)
	       syntax-table/system-internal)))