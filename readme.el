(setq treesit-extra-load-path `(,(concat user-emacs-directory "var/tree-sitter-dist/")
                                ,(concat user-emacs-directory "tree-sitter")))
(setq load-prefer-newer t)
(use-package no-littering
  :ensure t)

(use-package quelpa :ensure t)
(use-package quelpa-use-package :ensure t)
(load-theme 'spacegray t)
;; Customize default emacs
(use-package emacs
  :ensure nil
  :defer
  :hook ((after-init . pending-delete-mode)
         (after-init . toggle-frame-maximized)
         (after-init . (lambda () (scroll-bar-mode -1)))
         (after-init . (lambda () (window-divider-mode -1)))
         (after-init . gopar/add-env-vars))
  :custom
  ;; flash the frame to represent a bell.
  (visible-bell t)
  (debugger-stack-frame-as-list t)
  (narrow-to-defun-include-comments t)
  (use-short-answers t)
  (confirm-nonexistent-file-or-buffer nil)
  ;; Treat manual switching of buffers the same as programatic
  (switch-to-buffer-obey-display-actions t)
  (switch-to-buffer-in-dedicated-window nil)
  (window-sides-slots '(3 0 3 1))
  ;; Sentences end with 1 space not 2
  (sentence-end-double-space nil)
  ;; make cursor the width of the character it is under
  ;; i.e. full width of a TAB
  (x-stretch-cursor t)
  ;; Stop cursor from going into minibuffer prompt text
  (minibuffer-prompt-properties '(read-only t point-entered minibuffer-avoid-prompt face minibuffer-prompt))
  (history-delete-duplicates t)
  ;; Completion stuff for consult
  (completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  (completion-cycle-threshold 3)
  (tab-always-indent 'complete)
  (use-dialog-box nil) ; Lets be consistent and use minibuffer for everyting
  (scroll-conservatively 100)
  (frame-inhibit-implied-resize t)
  (custom-file "~/.emacs.d/ignoreme.el")

  :config
  (load custom-file)
  (when (eq system-type 'darwin)
    (setq mac-option-key-is-meta nil
          mac-command-key-is-meta t
          mac-command-modifier 'meta
          mac-option-modifier 'none)
    )
  (setq-default c-basic-offset 4
                c-default-style "linux"
                indent-tabs-mode nil
                fill-column 120
                tab-width 4)
  ;; Replaced in favor for `use-short-answers`
  ;; (fset 'yes-or-no-p 'y-or-n-p)
  (prefer-coding-system 'utf-8)
  ;; Uppercase is same as lowercase
  (define-coding-system-alias 'UTF-8 'utf-8)
  ;; Enable some commands
  (put 'upcase-region 'disabled nil)
  (put 'downcase-region 'disabled nil)
  (put 'erase-buffer 'disabled nil)
  ;; C-x n <key> useful stuff
  (put 'narrow-to-region 'disabled nil)
  (tool-bar-mode -1)
  (menu-bar-mode -1)

  :bind (("C-z" . nil)
         ("C-x C-z" . nil)
         ("C-x C-k RET" . nil)
         ("RET" . newline-and-indent)
         ("C-j" . newline)
         ("M-\\" . cycle-spacing)
         ("C-x \\" . align-regexp)
         ("C-x C-b" . ibuffer)
         ("M-u" . upcase-dwim)
         ("M-l" . downcase-dwim)
         ("M-c" . capitalize-dwim)
         ("C-S-k" . gopar/delete-line-backward)
         ("C-k" . gopar/delete-line)
         ("M-d" . gopar/delete-word)
         ("<M-backspace>" . gopar/backward-delete-word)
         ("M-e" . gopar/next-sentence)
         ("M-a" . gopar/last-sentence)
         (";" . gopar/easy-underscore)
         ("C-x k" . (lambda () (interactive) (kill-buffer)))
         ("C-x C-k" . (lambda () (interactive) (bury-buffer))))

  :init
  ;; (defmacro k-time (&rest body)
  ;;   "Measure and return the time it takes evaluating BODY."
  ;;   `(let ((time (current-time)))
  ;;      ,@body
  ;;      (float-time (time-since time))))

  ;; ;; When idle for 15 mins run the GC no matter what.
  ;; (defvar k-gc-timer
  ;;   (run-with-idle-timer (* 15 60) t
  ;;                        (lambda ()
  ;;                          (message "Garbage Collector has run for %.06fsec"
  ;;                                   (k-time (garbage-collect))))))

  (defun gopar/copy-filename-to-kill-ring ()
    (interactive)
    (kill-new (buffer-file-name))
    (message "Copied to file name kill ring"))

  (defun gopar/easy-underscore (arg)
    "Convert all inputs of semicolon to an underscore.
If given ARG, then it will insert an acutal semicolon."
    (interactive "P")
    (if arg
        (insert ";")
      (insert "_")))

  (defun easy-camelcase (arg)
    (interactive "c")
    ;; arg is between a-z
    (cond ((and (>= arg 97) (<= arg 122))
           (insert (capitalize (char-to-string arg))))
          ;; If it's a new line
          ((= arg 13)
           (newline-and-indent))
          ((= arg 59)
           (insert ";"))
          ;; We probably meant a key command, so lets execute that
          (t (call-interactively
              (lookup-key (current-global-map) (char-to-string arg))))))

  (defun sudo-edit (&optional arg)
    "Edit currently visited file as root.
With a prefix ARG prompt for a file to visit.
Will also prompt for a file to visit if current
buffer is not visiting a file."
    (interactive "P")
    (if (or arg (not buffer-file-name))
        (find-file (concat "/sudo:root@localhost:"
                           (completing-read "Find file(as root): ")))
      (find-alternate-file (concat "/sudo:root@localhost:" buffer-file-name))))

  ;; Stolen from https://emacs.stackexchange.com/a/13096/8964
  (defun gopar/reload-dir-locals-for-current-buffer ()
    "Reload dir locals for the current buffer"
    (interactive)
    (let ((enable-local-variables :all))
      (hack-dir-local-variables-non-file-buffer)))

  (defun gopar/delete-word (arg)
    "Delete characters forward until encountering the end of a word.
With argument, do this that many times.
This command does not push text to `kill-ring'."
    (interactive "p")
    (delete-region
     (point)
     (progn
       (forward-word arg)
       (point))))

  (defun gopar/backward-delete-word (arg)
    "Delete characters backward until encountering the beginning of a word.
With argument, do this that many times.
This command does not push text to `kill-ring'."
    (interactive "p")
    (gopar/delete-word (- arg)))

  (defun gopar/delete-line ()
    "Delete text from current position to end of line char.
This command does not push text to `kill-ring'."
    (interactive)
    (delete-region
     (point)
     (progn (end-of-line 1) (point)))
    (delete-char 1))

  (defadvice gopar/delete-line (before kill-line-autoreindent activate)
    "Kill excess whitespace when joining lines.
If the next line is joined to the current line, kill the extra indent whitespace in front of the next line."
    (when (and (eolp) (not (bolp)))
      (save-excursion
        (forward-char 1)
        (just-one-space 1))))

  (defun gopar/delete-line-backward ()
    "Delete text between the beginning of the line to the cursor position.
This command does not push text to `kill-ring'."
    (interactive)
    (let (p1 p2)
      (setq p1 (point))
      (beginning-of-line 1)
      (setq p2 (point))
      (delete-region p1 p2)))

  (defun gopar/next-sentence ()
    "Move point forward to the next sentence.
Start by moving to the next period, question mark or exclamation.
If this punctuation is followed by one or more whitespace
characters followed by a capital letter, or a '\', stop there. If
not, assume we're at an abbreviation of some sort and move to the
next potential sentence end"
    (interactive)
    (re-search-forward "[.?!]")
    (if (looking-at "[    \n]+[A-Z]\\|\\\\")
        nil
      (gopar/next-sentence)))

  (defun gopar/last-sentence ()
    "Does the same as 'gopar/next-sentence' except it goes in reverse"
    (interactive)
    (re-search-backward "[.?!][   \n]+[A-Z]\\|\\.\\\\" nil t)
    (forward-char))

  (defvar gopar-ansi-escape-re
    (rx (or ?\233 (and ?\e ?\[))
        (zero-or-more (char (?0 . ?\?)))
        (zero-or-more (char ?\s ?- ?\/))
        (char (?@ . ?~))))

  (defun gopar/nuke-ansi-escapes (beg end)
    (save-excursion
      (goto-char beg)
      (while (re-search-forward gopar-ansi-escape-re end t)
        (replace-match ""))))

  (defun gopar/toggle-window-dedication ()
    "Toggles window dedication in the selected window."
    (interactive)
    (set-window-dedicated-p (selected-window)
                            (not (window-dedicated-p (selected-window)))))

  (defun gopar/add-env-vars ()
    "Setup environment variables that I will need."
    (load-file "~/.emacs.d/etc/eshell/set_env.el")
    (setq-default eshell-path-env (getenv "PATH"))

    (setq exec-path (append exec-path
                            `("/usr/local/bin"
                              "/usr/bin"
                              "/usr/sbin"
                              "/sbin"
                              "/bin"
                              "/Users/gopar/.nvm/versions/node/v16.14.2/bin/"
                              )
                            (split-string (getenv "PATH") ":")))))


;; org mode main configuration

;; https://stackoverflow.com/a/10091330/2178312
(use-package org
  :defer
  :custom
  (org-agenda-include-diary t)
  ;; Where the org files live
  (org-directory "~/.emacs.d/org/")
  ;; Where archives should go
  (org-archive-location (concat (expand-file-name "~/.emacs.d/org/private/org-roam/gtd/archives.org") "::"))
  ;; Make sure we see syntax highlighting
  (org-src-fontify-natively t)
  ;; I dont use it for subs/super scripts
  (org-use-sub-superscripts nil)
  ;; Should everything be hidden?
  (org-startup-folded 'content)
  (org-M-RET-may-split-line '((default . nil)))
  ;; Don't hide stars
  (org-hide-leading-stars nil)
  (org-hide-emphasis-markers nil)
  ;; Show as utf-8 chars
  (org-pretty-entities t)
  ;; put timestamp when finished a todo
  (org-log-done 'time)
  ;; timestamp when we reschedule
  (org-log-reschedule t)
  ;; Don't indent the stars
  (org-startup-indented nil)
  (org-list-allow-alphabetical t)
  (org-image-actual-width nil)
  ;; Save notes into log drawer
  (org-log-into-drawer t)
  ;;
  (org-fontify-whole-heading-line t)
  (org-fontify-done-headline t)
  ;;
  (org-fontify-quote-and-verse-blocks t)
  ;; See down arrow instead of "..." when we have subtrees
  ;; (org-ellipsis "⤵")
  ;; catch invisible edit
  ( org-catch-invisible-edits 'show-and-error)
  ;; Only useful for property searching only but can slow down search
  (org-use-property-inheritance t)
  ;; Count all children TODO's not just direct ones
  (org-hierarchical-todo-statistics nil)
  ;; Unchecked boxes will block switching the parent to DONE
  (org-enforce-todo-checkbox-dependencies t)
  ;; Don't allow TODO's to close without their dependencies done
  (org-enforce-todo-dependencies t)
  (org-track-ordered-property-with-tag t)
  ;; Where should notes go to? Dont even use them tho
  (org-default-notes-file (concat org-directory "notes.org"))
  ;; The right side of | indicates the DONE states
  (org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)" "IN-PROGRESS(i!)" "WAITING(w!)" "|" "DONE(d!)" "CANCELED(c!)" "DELEGATED(p!)")))
  ;; Needed to allow helm to compute all refile options in buffer
  (org-outline-path-complete-in-steps nil)
  (org-deadline-warning-days 2)
  (org-log-redeadline t)
  (org-log-reschedule t)
  ;; Repeat to previous todo state
  ;; If there was no todo state, then dont set a state
  (org-todo-repeat-to-state t)
  ;; Refile options
  (org-refile-use-outline-path 'file)
  (org-refile-allow-creating-parent-nodes 'confirm)
  (org-refile-targets '(("~/.emacs.d/org/private/org-roam/gtd/gtd.org" :maxlevel . 3)
                        ("~/.emacs.d/org/private/org-roam/gtd/someday.org" :level . 1)
                        ("~/.emacs.d/org/private/org-roam/gtd/tickler.org" :maxlevel . 1)
                        ("~/.emacs.d/org/private/org-roam/gtd/repeat.org" :maxlevel . 1)
                        ))
  ;; Lets customize which modules we load up
  (org-modules '(;; ol-eww
                 ;; Stuff I've enabled below
                 org-habit
                 ;; org-checklist
                 ))
  (org-special-ctrl-a/e t)
  (org-insert-heading-respect-content t)
  :hook ((org-mode . org-indent-mode)
         (org-mode . org-display-inline-images))
  :custom-face
  (org-scheduled-previously ((t (:foreground "orange"))))
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((sql . t)
     (sqlite . t)
     (python . t)
     (java . t)
     ;; (cpp . t)
     (C . t)
     (emacs-lisp . t)
     (shell . t)))
  ;; Save history throughout sessions
  (org-clock-persistence-insinuate))



;; org agenda 

(use-package org-agenda
  :after org
  :bind (("C-c a" . org-agenda))
  ;; :hook (org-agenda-finalize . org-agenda-entry-text-mode)
  :custom
  (org-agenda-current-time-string (if (and (display-graphic-p)
           (char-displayable-p ?←)
           (char-displayable-p ?─))
      "⬅️ now"
    "now - - - - - - - - - - - - - - - - - - - - - - - - -"))
  (org-agenda-timegrid-use-ampm t)
  (org-agenda-tags-column 0)
  (org-agenda-window-setup 'only-window)
  (org-agenda-restore-windows-after-quit t)
  (org-agenda-log-mode-items '(closed clock state))
  (org-agenda-time-grid '((daily today require-timed)
                          (600 800 1000 1200 1400 1600 1800 2000)
                          " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"))
  ;; (org-agenda-start-with-log-mode '(closed clock state))
  (org-agenda-files "~/.emacs.d/org/agenda-files.org")
  ;; (org-agenda-todo-ignore-scheduled 'future)
  ;; TODO entries that can't be marked as done b/c of children are shown as dimmed in agenda view
  (org-agenda-dim-blocked-tasks 'invisible)
  ;; Start the week view on whatever day im on
  (org-agenda-start-on-weekday nil)
  ;; How to identify stuck/non-stuck projects
  ;; Projects are identified by the 'project' tag and its always the first level
  ;; Next any of these todo keywords means it's not a stuck project
  ;; 3rd, theres no tags that I use to identify a stuck Project
  ;; Finally, theres no special text that signify a non-stuck project
  (org-stuck-projects
   '("+project+LEVEL=1"
     ("IN-PROGRESS" "WAITING" "DONE" "CANCELED" "DELEGATED")
     nil
     ""))
  (org-agenda-prefix-format
   '((agenda . " %-4e %i %-12:c%?-12t% s ")
     (todo . " %i %-10:c %-5e %(gopar/get-schedule-or-deadline-if-available)")
     (tags . " %i %-12:c")
     (search . " %i %-12:c")))
  ;; Lets define some custom cmds in agenda menu
  (org-agenda-custom-commands
   '(("h" "Agenda and Home tasks"
      ((agenda "" ((org-agenda-span 2)))
       (todo "WAITING|IN-PROGRESS")
       (tags-todo "inbox|break")
       (todo "NEXT"))
      ((org-agenda-sorting-strategy '(time-up habit-up priority-down category-up))))

     ("w" "Agenda and break|inbox tasks"
      ((agenda "" ((org-agenda-span 1)))
       (tags-todo "inbox|break"))
      ((org-agenda-sorting-strategy '(time-up habit-up priority-down category-up))))

     ("i" "In-Progress Tasks"
      ((todo "IN-PROGRESS|WAITING")
       (agenda ""))
      ((org-agenda-sorting-strategy '(time-up habit-up priority-down category-up))))

     ("g" "Goals: 12 Week Year"
      ((agenda "")
       (todo "IN-PROGRESS|WAITING"))
      ((org-agenda-sorting-strategy '(time-up habit-up priority-down category-up))
       (org-agenda-tag-filter-preset '("+12WY"))
       (org-agenda-start-with-log-mode '(closed clock state))
       (org-agenda-archives-mode t)
       ))

     ("r" "Weekly Review"
      ((agenda "")
       (todo))
      ((org-agenda-sorting-strategy '(time-up habit-up category-up priority-down ))
       (org-agenda-files "~/.emacs.d/org/weekly-reivew-agenda-files.org")
       (org-agenda-include-diary nil)))))
  :init
  ;; Originally from here: https://stackoverflow.com/a/59001859/2178312
  (defun gopar/get-schedule-or-deadline-if-available ()
    (let ((scheduled (org-get-scheduled-time (point)))
          (deadline (org-get-deadline-time (point))))
      (if (not (or scheduled deadline))
          (format "🗓️ ")
          ;; (format " ")
        "   "))))

;; org src block

(use-package org-src
  :after org
  :custom
  (org-src-preserve-indentation nil)
  ;; Don't ask if we already have an open Edit buffer
  (org-src-ask-before-returning-to-edit-buffer nil)
  (org-edit-src-content-indentation 0))


;; org intend

(use-package org-indent
  :ensure nil
  :diminish
  :custom
  (org-indent-mode-turns-on-hiding-stars nil))



(use-package org-roam
  :ensure t
  :defer
  :custom
  (org-roam-v2-ack t)
  (org-roam-directory (expand-file-name "~/.emacs.d/org/private/org-roam"))
  (org-roam-db-location (expand-file-name "~/.emacs.d/org/private/org-roam.db"))
  (org-roam-tag-sources '(prop))
  (org-roam-db-update-method 'immediate)
  (org-roam-graph-viewer 'browse-url-firefox)
  (org-roam-capture-templates
   '(("d" "default" plain "%?"
      :target (file+head "./references/${slug}.org" "#+title: ${title}\n")
      :unnarrowed t)))
  (org-roam-dailies-directory (expand-file-name "~/.emacs.d/org/private/journal/"))
  (org-roam-dailies-capture-templates
   `(("d" "daily" plain (file "/Users/gopar/.emacs.d/org/templates/dailies-daily.template")
      :target (file+head "daily/%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n"))

     ("w" "weekly" plain (file "/Users/gopar/.emacs.d/org/templates/dailies-weekly.template")
      :target (file+head "weekly/%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n"))

     ("m" "monthly" plain (file "/Users/gopar/.emacs.d/org/templates/dailies-monthly.template")
      :target (file+head "monthly/%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n"))))

  :bind (:map global-map
              (("C-c n i" . org-roam-node-insert)
               ("C-c n f" . org-roam-node-find)
               ("C-c n g" . org-roam-graph)
               ("C-c n n" . org-roam-capture)
               ("C-c n d" . org-roam-dailies-capture-today)
               ("C-c n s" . consult-org-roam-search)))
  :hook (after-init . org-roam-db-autosync-mode))


;; eshell

(use-package eshell
  :ensure nil
  :hook ((eshell-directory-change . gopar/sync-dir-in-buffer-name)
         (eshell-mode . gopar/eshell-specific-outline-regexp)
         (eshell-mode . gopar/eshell-setup-keybinding)
         (eshell-mode . (lambda () (setq-local completion-at-point-functions '(cape-file)))))
  :custom
  (eshell-buffer-maximum-lines 10000)
  (eshell-scroll-to-bottom-on-input t)
  (eshell-highlight-prompt nil)
  (eshell-history-size 1024)
  (eshell-hist-ignoredups t)
  (eshell-input-filter 'gopar/eshell-input-filter)
  (eshell-cd-on-directory t)
  (eshell-list-files-after-cd nil)
  (eshell-pushd-dunique t)
  (eshell-last-dir-unique t)
  (eshell-last-dir-ring-size 32)
  (eshell-list-files-after-cd nil)
  :init
  (defun gopar/eshell-setup-keybinding ()
    ;; Workaround since bind doesn't work w/ eshell??
    (define-key eshell-mode-map (kbd "C-c >") 'gopar/eshell-redirect-to-buffer)
    (define-key eshell-hist-mode-map (kbd "M-r") 'consult-history))

  (defun gopar/eshell-input-filter (input)
    "Do not save empty lines, commands that start with a space or 'l'/'ls'"
    (and
     (not (string-prefix-p "ls" input))
     (not (or (string-prefix-p "l " input) (string-equal "l" input)))
     (not (string-prefix-p "cd" input))
     (eshell-input-filter-default input)
     (eshell-input-filter-initial-space input)))

  (defun eshell/ff (&rest args)
    "Open files in emacs.
Stolen form aweshell"
    (if (null args)
        ;; If I just ran "emacs", I probably expect to be launching
        ;; Emacs, which is rather silly since I'm already in Emacs.
        ;; So just pretend to do what I ask.
        (bury-buffer)
      ;; We have to expand the file names or else naming a directory in an
      ;; argument causes later arguments to be looked for in that directory,
      ;; not the starting directory
      (mapc #'find-file (mapcar #'expand-file-name (eshell-flatten-list (reverse args)))))
    )

  (defun eshell/clear ()
    "Clear the eshell buffer.
This overrides the built in eshell/clear cmd in esh-mode."
    (interactive)
    (eshell/clear-scrollback))

  (defun eshell/z (&optional regexp)
    "Navigate to a previously visited directory in eshell.
Similar to `cd =`"
    (let ((eshell-dirs (delete-dups
                        (mapcar 'abbreviate-file-name
                                (ring-elements eshell-last-dir-ring)))))
      (eshell/cd (if regexp (eshell-find-previous-directory regexp)
                   (completing-read "cd: " eshell-dirs)))))

  (defun eshell/jj ()
    "Jumpt to Root."
    (eshell/cd (projectile-project-root)))

  (defun eshell/cat (filename)
    "Like cat(1) but with syntax highlighting.
Stole from aweshell"
    (let ((existing-buffer (get-file-buffer filename))
          (buffer (find-file-noselect filename)))
      (eshell-print
       (with-current-buffer buffer
         (if (fboundp 'font-lock-ensure)
             (font-lock-ensure)
           (with-no-warnings
             (font-lock-fontify-buffer)))
         (let ((contents (buffer-string)))
           (remove-text-properties 0 (length contents) '(read-only nil) contents)
           contents)))
      (unless existing-buffer
        (kill-buffer buffer))
      nil))

  (defun gopar/sync-dir-in-buffer-name ()
    "Update eshell buffer to show directory path.
Stolen from aweshell."
    (let* ((root (projectile-project-root))
           (root-name (projectile-project-name root)))
      (if root-name
          (rename-buffer (format "*eshell %s* %s" root-name (s-chop-prefix root default-directory)) t)
        (rename-buffer (format "*eshell %s*" default-directory) t))))

  (defun gopar/eshell-redirect-to-buffer (buffer)
    "Auto create command for redirecting to buffer."
    (interactive (list (read-buffer "Redirect to buffer: ")))
    (insert (format " >>> #<%s>" buffer)))

(defun gopar/eshell-specific-outline-regexp ()
  (setq-local outline-regexp eshell-prompt-regexp)))


(use-package eshell-syntax-highlighting
  :ensure t
  :config
  (eshell-syntax-highlighting-global-mode +1)
  :init
  (defface eshell-syntax-highlighting-invalid-face
    '((t :inherit diff-error))
    "Face used for invalid Eshell commands."
    :group 'eshell-syntax-highlighting))


(use-package eshell-git-prompt
  :after eshell
  :ensure t)

(use-package powerline-with-venv
  :ensure nil
  :after eshell-git-prompt
  :load-path "lisp/themes/powerline-with-venv"
  :config
  (add-to-list 'eshell-git-prompt-themes
               '(powerline-plus eshell-git-prompt-powerline-venv eshell-git-prompt-powerline-regexp))
  (eshell-git-prompt-use-theme 'powerline-plus))

;; (use-package powerline-with-pyvenv
;;   :ensure nil
;;   :after eshell-git-prompt
;;   :load-path "lisp/themes/powerline-with-venv"
;;   :config
;;   (add-to-list 'eshell-git-prompt-themes
;;                '(powerline-plus eshell-git-prompt-powerline-pyvenv eshell-git-prompt-powerline-regexp))
;;   (eshell-git-prompt-use-theme 'powerline-plus))

(use-package eshell-vterm
  :ensure
  :after eshell
  :bind (:map vterm-mode-map
         ("C-q" . vterm-send-next-key))
  :config
  (eshell-vterm-mode)
  :init
  (defalias 'eshell/v 'eshell-exec-visual))


(use-package eshell-info-banner
  :ensure t
  :defer t
  :hook (eshell-banner-load . eshell-info-banner-update-banner))


(use-package executable
  :ensure nil
  :hook (after-save . executable-make-buffer-file-executable-if-script-p))


;; It may also be wise to raise gc-cons-threshold while the minibuffer is active,
;; so the GC doesn't slow down expensive commands (or completion frameworks, like
;; helm and ivy. The following is taken from doom-emacs
(use-package minibuffer
  :ensure nil
  :custom
  (completion-styles '(initials partial-completion flex)))


(use-package projectile
  :ensure
  :load t
  :commands projectile-project-root
  :bind-keymap
  ("C-c p" . projectile-command-map)

  :custom
  (projectile-indexing-method 'hybrid)  ;; Not sure if this still needed?
  (projectile-per-project-compilation-buffer nil)
  :config
  (projectile-global-mode)
  (setq frame-title-format '(:eval (if (projectile-project-root) (projectile-project-root) "%b")))
  )

(use-package highlight-indentation
  :ensure t
  :defer
  :hook ((prog-mode . highlight-indentation-mode)
         (prog-mode . highlight-indentation-current-column-mode)))

(use-package hl-todo
  :ensure t
  :defer t
  :hook (prog-mode . hl-todo-mode))

(use-package all-the-icons
  :ensure t
  :defer
  :if (display-graphic-p))

(use-package all-the-icons-completion
  :ensure t
  :defer
  :hook (marginalia-mode . #'all-the-icons-completion-marginalia-setup)
  :init
  (all-the-icons-completion-mode))

(use-package magit
  :ensure t
  :commands magit-get-current-branch
  :defer
  :bind ("C-x g" . magit)
  :hook (magit-mode . magit-wip-mode)
  :custom
  (magit-diff-refine-hunk 'all)
  (magit-process-finish-apply-ansi-colors t)
  :init
  (defun magit/undo-last-commit (number-of-commits)
    "Undoes the latest commit or commits without loosing changes"
    (interactive "P")
    (let ((num (if (numberp number-of-commits)
                   number-of-commits
                 1)))
      (magit-reset-soft (format "HEAD^%d" num)))))

;; Part of magit
(use-package git-commit
  :after magit
  :hook (git-commit-setup . gopar/auto-insert-jira-ticket-in-commit-msg)
  :custom
  (git-commit-summary-max-length 80)
  :init
  (defun gopar/auto-insert-jira-ticket-in-commit-msg ()
    (let ((has-ticket-title (string-match "^[A-Z]+-[0-9]+" (magit-get-current-branch)))
          (has-ss-ticket (string-match "^[A-Za-Z]+/[A-Z]+-[0-9]+" (magit-get-current-branch)))
          (words (s-split-words (magit-get-current-branch))))
      (if has-ticket-title
          (insert (format "[%s-%s] " (car words) (car (cdr words)))))
      (if has-ss-ticket
          (insert (format "[%s-%s] " (nth 1 words) (nth 2 words)))))))

(use-package git-gutter
  :ensure t
  :hook (after-init . global-git-gutter-mode))

(use-package paren
  :ensure nil
  :hook (after-init . show-paren-mode)
  :custom
  (show-paren-style 'mixed)
  (show-paren-context-when-offscreen t))


(use-package battery
  :ensure nil
  :hook (after-init . display-battery-mode))

;; After adding or updating a snippet run:
;; =M-x yas-recompile-all=
;; =M-x yas-reload-all=
(use-package yasnippet
  :ensure t
  :defer
  :hook ((prog-mode . yas-minor-mode)
         (org-mode . yas-minor-mode)
         (fundamental-mode . yas-minor-mode)
         (text-mode . yas-minor-mode)
         (after-init . yas-reload-all))
  :bind (:map yas-minor-mode-map
              ("C-c C-SPC" . yas-insert-snippet)))

(use-package yasnippet-snippets
  :ensure t
  :defer)

(use-package dashboard
  :ensure t
  :custom
  (dashboard-startup-banner 'logo)
  (dashboard-center-content t)
  (dashboard-show-shortcuts nil)
  (dashboard-set-heading-icons t)
  (dashboard-icon-type 'all-the-icons)
  (dashboard-set-file-icons t)
  (dashboard-projects-backend 'projectile)
  ;; (dashboard-agenda-sort-strategy '(priority-down))
  (dashboard-items '(
                     (vocabulary)
                     (recents . 5)
                     ;; (projects . 5)
                     (bookmarks . 5)
                     (agenda . 5)
                     ))
  (dashboard-item-generators '(
                              (vocabulary . gopar/dashboard-insert-vocabulary)
                              (recents . dashboard-insert-recents)
                              (bookmarks . dashboard-insert-bookmarks)
                              (projects . dashboard-insert-projects)
                              (agenda . dashboard-insert-agenda)
                              (registers . dashboard-insert-registers)))
  :init
  (defun gopar/dashboard-insert-vocabulary (list-size)
    (dashboard-insert-heading "Word of the Day:"
                              nil
                              (all-the-icons-faicon "newspaper-o"
                                                    :height 1.2
                                                    :v-adjust 0.0
                                                    :face 'dashboard-heading))
    (insert "\n")
    (let ((random-line nil)
          (lines nil))
      (with-temp-buffer
        (insert-file-contents (concat user-emacs-directory "words"))
        (goto-char (point-min))
        (setq lines (split-string (buffer-string) "\n" t))
        (setq random-line (nth (random (length lines)) lines))
        (setq random-line (string-join (split-string random-line) " ")))
      (insert "    " random-line)))

  :config
  (dashboard-setup-startup-hook))


(use-package dired
  :ensure nil
  :defer
  :hook ((dired-mode . dired-hide-details-mode)
         (dired-mode . hl-line-mode))
  :custom
  (dired-do-revert-buffer t)
  (dired-auto-revert-buffer t)
  (delete-by-moving-to-trash t)
  (dired-mouse-drag-files t)
  (dired-dwim-target t)
  ;; (dired-guess-shell-alist-user)
  (dired-listing-switches "-AlhoF --group-directories-first"))

(use-package all-the-icons-dired
  :ensure t
  :defer
  :hook (dired-mode . all-the-icons-dired-mode)
  :custom
  (all-the-icons-dired-monochrome nil))

(use-package files
  :ensure nil
  :custom
  (insert-directory-program "gls") ; Will not work if system does not have GNU gls installed
  ;; Don't have backup
  (backup-inhibited t)
  ;; Don't save anything.
  (auto-save-default nil)
  ;; If file doesn't end with a newline on save, automatically add one.
  (require-final-newline t)
  :config
  (add-to-list 'auto-mode-alist '("Pipfile" . conf-toml-mode)))



(use-package dired-subtree
  :ensure t
  :after dired
  :bind (:map dired-mode-map
              ("<tab>" . dired-subtree-toggle)
              ("<C-tab>" . dired-subtree-cycle)
              ("<backtab>" . dired-subtree-remove) ;; Shift + Tab
              ))


(use-package window
  :ensure nil
  :defer
  :custom
  (recenter-positions '(middle top bottom)))


(use-package treemacs
  :ensure t
  :defer
  :bind ("<f5>" . treemacs)
  :custom
  (treemacs-is-never-other-window t)
  :hook
  (treemacs-mode . treemacs-project-follow-mode))


(use-package winner
  :ensure nil
  :hook after-init
  :commands (winner-undo winnner-redo)
  :custom
  (winner-boring-buffers '("*Completions*" "*Help*" "*Apropos*"
                           "*Buffer List*" "*info*" "*Compile-Log*")))

(use-package transient
  :ensure t
  :defer
  :bind ("C-M-o" . windows-transient-window)
  :init
  (transient-define-prefix windows-transient-window ()
   "Display a transient buffer showing useful window manipulation bindings."
    [["Resize"
     ("}" "h+" enlarge-window-horizontally :transient t)
     ("{" "h-" shrink-window-horizontally :transient t)
     ("^" "v+" enlarge-window :transient t)
     ("V" "v-" shrink-window :transient t)]
     ["Split"
    ("v" "vertical" (lambda ()
       (interactive)
       (split-window-right)
       (windmove-right)) :transient t)
    ("x" "horizontal" (lambda ()
       (interactive)
       (split-window-below)
       (windmove-down)) :transient t)
    ("wv" "win-vertical" (lambda ()
       (interactive)
       (select-window (split-window-right))
       (windows-transient-window)) :transient nil)
    ("wx" "win-horizontal" (lambda ()
       (interactive)
       (select-window (split-window-below))
       (windows-transient-window)) :transient nil)]
    ["Misc"
     ("B" "switch buffer" (lambda ()
                            (interactive)
                            (consult-buffer)
                            (windows-transient-window)))
     ("z" "undo" (lambda ()
                  (interactive)
                  (winner-undo)
                 (setq this-command 'winner-undo)) :transient t)
   ("Z" "redo" winner-redo :transient t)
 ]]
    [["Move"
    ("h" "←" windmove-left :transient t)
    ("j" "↓" windmove-down :transient t)
    ("l" "→" windmove-right :transient t)
    ("k" "↑" windmove-up :transient t)]
    ["Swap"
    ("sh" "←" windmove-swap-states-left :transient t)
    ("sj" "↓" windmove-swap-states-down :transient t)
    ("sl" "→" windmove-swap-states-right :transient t)
    ("sk" "↑" windmove-swap-states-up :transient t)]
    ["Delete"
    ("dh" "←" windmove-delete-left :transient t)
    ("dj" "↓" windmove-delete-down :transient t)
    ("dl" "→" windmove-delete-right :transient t)
    ("dk" "↑" windmove-delete-up :transient t)
    ("D" "This" delete-window :transient t)]
    ["Transpose"
    ("tt" "↜" (lambda ()
                (interactive)
                (transpose-frame)
                (windows-transient-window)) :transient nil)
    ("ti" "↕" (lambda ()
                (interactive)
                (flip-frame)
                (windows-transient-window)) :transient nil)
    ("to" "⟷" (lambda ()
                (interactive)
                (flop-frame)
                (windows-transient-window)) :transient nil)
    ("tc" "⟳" (lambda ()
                (interactive)
                (rotate-frame-clockwise)
                (windows-transient-window)) :transient nil)
    ("ta" "⟲" (lambda ()
                (interactive)
                (rotate-frame-anticlockwise)
                (windows-transient-window)) :transient nil)]]))


(use-package transpose-frame :after transient :ensure t)

(use-package vterm
  :ensure t
  :defer
  :custom
  (vterm-max-scrollback 100000))


(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :config (column-number-mode 1)
  :custom
  (doom-modeline-height 30)
  (doom-modeline-window-width-limit nil)
  (doom-modeline-buffer-file-name-style 'truncate-with-project)
  (doom-modeline-minor-modes nil)
  (doom-modeline-enable-word-count nil)
  (doom-modeline-buffer-encoding nil)
  (doom-modeline-buffer-modification-icon t)
  (doom-modeline-env-python-executable "python")
  ;; needs display-time-mode to be one
  (doom-modeline-time t)
  (doom-modeline-vcs-max-length 50)
  )


(use-package golden-ratio
  :ensure t
  :hook (after-init . golden-ratio-mode)
  :custom
  (golden-ratio-auto-scale t)
  (golden-ratio-exclude-modes '(treemacs-mode occur-mode)))

(use-package ssh-config-mode
  :ensure t
  :defer)


;; Minimal UI

(use-package org-modern :ensure t
  :defer)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; Choose some fonts
;;(set-face-attribute 'default nil :family "Iosevka")
;;(set-face-attribute 'variable-pitch nil :family "Iosevka Aile")
;(set-face-attribute 'org-modern-symbol nil :family "Iosevka")

;; Add frame borders and window dividers
(modify-all-frames-parameters
 '((right-divider-width . 40)
   (internal-border-width . 40)))
(dolist (face '(window-divider
                window-divider-first-pixel
                window-divider-last-pixel))
  (face-spec-reset-face face)
  (set-face-foreground face (face-attribute 'default :background)))
(set-face-background 'fringe (face-attribute 'default :background))

(setq
 ;; Edit settings
 org-auto-align-tags nil
 org-tags-column 0
 org-catch-invisible-edits 'show-and-error
 org-special-ctrl-a/e t
 org-insert-heading-respect-content t

 ;; Org styling, hide markup etc.
 org-hide-emphasis-markers t
 org-pretty-entities t
 org-ellipsis "…"

 ;; Agenda styling
 org-agenda-tags-column 0
 org-agenda-block-separator ?─
 org-agenda-time-grid
 '((daily today require-timed)
   (800 1000 1200 1400 1600 1800 2000)
   " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄")
 org-agenda-current-time-string
 "◀── now ─────────────────────────────────────────────────")

(global-org-modern-mode)

;; javascript support in org mode


(use-package ob-js)



(defun my-org-publish-buffer ()
  (interactive)
  (save-buffer)
  (save-excursion (org-publish-current-file))
  (let* ((proj (org-publish-get-project-from-filename buffer-file-name))
         (proj-plist (cdr proj))
         (rel (file-relative-name buffer-file-name
                                  (plist-get proj-plist :base-directory)))
         (dest (plist-get proj-plist :publishing-directory)))
    (browse-url (concat "file://"
                        (file-name-as-directory (expand-file-name dest))
                        (file-name-sans-extension rel)
                        ".html"))))

(setq org-babel-js-function-wrapper
      "process.stdout.write(require('util').inspect(function(){\n%s\n}(), { maxArrayLength: null, maxStringLength: null, breakLength: Infinity, compact: true }))")

(setenv "PATH" "/home/akshaya/.nvm/versions/node/v21.7.1/bin" "/usr/bin/git")
