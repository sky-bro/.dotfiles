;; Initialize package sources
(require 'package)

(let (;; tsinghua
      (archives '("http://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/"
                  "http://mirrors.tuna.tsinghua.edu.cn/elpa/org/"
                  "http://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/"))
      ;; ustc
      (archives '("http://mirrors.ustc.edu.cn/elpa/melpa/"
                  "http://mirrors.ustc.edu.cn/elpa/org/"
                  "http://mirrors.ustc.edu.cn/elpa/gnu/"))
      ;; official
      ;; (archives '("https://melpa.org/packages/"
      ;;             "http://orgmode.org/elpa/"
      ;;             "https://elpa.gnu.org/packages/"))
      )
  (setq package-archives `(("melpa" . ,(nth 0 archives))
                           ("org" . ,(nth 1 archives))
                           ("gnu" . ,(nth 2 archives)))))

(package-initialize)

;; https://www.reddit.com/r/emacs/comments/1rdstn/set_packageenableatstartup_to_nil_for_slightly/
(setq package-enable-at-startup nil)

(unless package-archive-contents
  (package-refresh-contents))

  ;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;; Produce backtraces when errors occur: can be helpful to diagnose startup issues
;; (setq debug-on-error t)
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-hook 'after-init-hook 'electric-pair-mode)
(add-hook 'after-init-hook 'electric-indent-mode)
(add-hook 'after-init-hook 'global-auto-revert-mode)
(use-package autorevert
  :diminish)
(setq global-auto-revert-non-file-buffers t
      auto-revert-verbose nil)

;; default values
(setq-default
 help-window-select t
 ;; only enable trailing whitespaces in some modes
 show-trailing-whitespace nil
 buffers-menu-max-size 30
 case-fold-search t
 column-number-mode t
 ediff-split-window-function 'split-window-horizontally
 ediff-window-setup-function 'ediff-setup-windows-plain
 indent-tabs-mode nil
 create-lockfiles nil
 auto-save-default nil
 make-backup-files nil
 mouse-yank-at-point t
 save-interprogram-paste-before-kill t
 scroll-preserve-screen-position 'always
 set-mark-command-repeat-pop t
 tooltip-delay 1.5
 truncate-lines nil
 truncate-partial-width-windows nil)

;; Adjust garbage collection thresholds during startup, and thereafter
(let ((normal-gc-cons-threshold (* 20 1024 1024))
      (init-gc-cons-threshold (* 128 1024 1024)))
  (setq gc-cons-threshold init-gc-cons-threshold)
  (add-hook 'emacs-startup-hook
            (lambda () (setq gc-cons-threshold (* 20 1024 1024)))))

(defun k4i/display-startup-time ()
  (message "init completed in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                    (time-subtract after-init-time before-init-time)))
           gcs-done))

(add-hook 'after-init-hook #'k4i/display-startup-time)

;; NOTE: If you want to move everything out of the ~/.emacs.d folder
;; reliably, set `user-emacs-directory` before loading no-littering!
;(setq user-emacs-directory "~/.cache/emacs")

(use-package no-littering)

;; no-littering doesn't set this by default so we must place
;; auto save files in the same path as it uses for sessions
(setq auto-save-file-name-transforms
      `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))

(global-set-key (kbd "C-x C-b") 'ibuffer)

;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(use-package undo-fu)
(use-package evil
  :init
  ;; set these variables before evil-mode is loaded
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-u-delete t)
  (setq evil-want-C-i-jump nil)
  (setq evil-undo-system 'undo-fu)
  :config
  (evil-mode 1)
  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)

  ;; Use visual line motions even outside of visual-line-mode buffers
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package general
  :after evil
  :config
  (general-create-definer my-space-leader
    :keymaps '(normal visual)
    :prefix "SPC")

  (my-space-leader
    "d" '(lambda () (interactive) (dired default-directory))
    "f"  '(:ignore t :which-key "file prefix")
    "fd" '(:ignore t :which-key "dotfiles prefix")
    "fde" '((lambda () (interactive) (find-file (expand-file-name "~/.dotfiles/.emacs.d/README.org"))) :which-key "emacs")
    "k" 'kill-this-buffer
    "o"  '(:ignore t :which-key "org prefix")
    "oa" 'org-agenda
    "oc" 'org-capture
    "r" 'resize-window
    "t"  '(:ignore t :which-key "toggles")
    "tt" '(counsel-load-theme :which-key "choose theme")
    "tf" 'treemacs
    "'" 'vterm-toggle-cd
    "=" 'format-all-buffer)

  (general-create-definer my-comma-leader
    :keymaps '(normal visual)
    :prefix ",")

  (my-comma-leader
    "k"  'kill-this-buffer))

(use-package which-key
  :init
  (which-key-mode)
  :diminish which-key-mode
  :custom
  (which-key-idle-delay 0.3)
  :diminish which-key-mode)

(use-package ivy
  :after counsel
  :diminish
  :bind (("C-s" . swiper)
         ("C-M-j" . ivy-switch-buffer)
         :map ivy-minibuffer-map
         ("TAB" . ivy-alt-done)
         ("C-l" . ivy-alt-done)
         ("C-j" . ivy-next-line)
         ("C-k" . ivy-previous-line)
         :map ivy-switch-buffer-map
         ("C-k" . ivy-previous-line)
         ("C-l" . ivy-done)
         ("C-d" . ivy-switch-buffer-kill)
         :map ivy-reverse-i-search-map
         ("C-k" . ivy-previous-line)
         ("C-d" . ivy-reverse-i-search-kill))
  :custom (ivy-use-virtual-buffers t)
  :config
  (ivy-mode 1))

(use-package ivy-rich
  :after ivy
  :init
  (ivy-rich-mode 1))

(use-package counsel
  :bind (:map minibuffer-local-map
         ("C-r" . 'counsel-minibuffer-history))
  :custom
  (counsel-linux-app-format-function #'counsel-linux-app-format-function-name-only)
  :config
  (counsel-mode 1))

(use-package ivy-prescient
  :after counsel
  :custom
  (ivy-prescient-enable-filtering nil)
  :config
  ;; Uncomment the following line to have sorting remembered across sessions!
  ;(prescient-persist-mode 1)
  (ivy-prescient-mode 1))

(use-package helpful
  :commands (helpful-callable helpful-variable helpful-command helpful-key)
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

(defvar enlarge-window-height-char ?k)
(defvar shrink-window-height-char ?j)
(defvar enlarge-window-width-char ?l)
(defvar shrink-window-width-char ?h)
(defun resize-window (&optional arg)
   "Interactively resize the selected window.
Repeatedly prompt whether to enlarge or shrink the window until the
response is neither `enlarge-window-char' or `shrink-window-char'.
When called with a prefix arg, resize the window by ARG lines."
   (interactive "p")
   ;; by default arg is 1, too slow to resize
   (setq arg 3)
   (let ((prompt (format "Enlarge/Shrink window (%c/%c/%c/%c)? "
                         enlarge-window-height-char shrink-window-height-char
                         enlarge-window-width-char shrink-window-width-char))
        response)
     (while (progn
             (setq response (read-event prompt))
             (cond ((equal response enlarge-window-height-char)
                    (enlarge-window arg)
                    t)
                   ((equal response shrink-window-height-char)
                    (enlarge-window (- arg))
                    t)
                   ((equal response enlarge-window-width-char)
                    (enlarge-window-horizontally arg)
                    t)
                   ((equal response shrink-window-width-char)
                    (enlarge-window-horizontally (- arg))
                    t)
                   (t nil))))
     (push response unread-command-events)))

;; adjust font size for your system
(defvar k4i/default-font-size 200)
(defvar k4i/default-variable-font-size 200)

;; Make frame transparency overridable
;; (defvar k4i/frame-transparency '(100 . 90))

(setq inhibit-startup-message t)

(scroll-bar-mode -1) ; Disable visible scrollbar
(tool-bar-mode -1) ; Disable the toolbar
(tooltip-mode -1) ; Disable tooltips
(set-fringe-mode 10) ; Give some breathing room

(menu-bar-mode -1) ; Disable the menu bar

;; Set up the visible bell
(setq visible-bell t)

;; Set frame transparency
;; (set-frame-parameter (selected-frame) 'alpha k4i/frame-transparency)
;; (add-to-list 'default-frame-alist `(alpha . ,k4i/frame-transparency))
(set-frame-parameter (selected-frame) 'fullscreen 'maximized)
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(global-display-line-numbers-mode t)
(column-number-mode) ; show column number
;; Disable line numbers for some modes
(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                eshell-mode-hook
                treemacs-mode-hook))
    (add-hook mode (lambda () (display-line-numbers-mode 0))))

(use-package beacon
  :custom
  (beacon-lighter "")
  (beacon-size 20)
  :config
  (beacon-mode 1))

(defun k4i/show-trailing-whitespace ()
  "Enable display of trailing whitespace in this buffer."
  (setq-local show-trailing-whitespace t))

(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook 'k4i/show-trailing-whitespace))

(add-hook 'before-save-hook
          'delete-trailing-whitespace)

;; M-SPC
(global-set-key [remap just-one-space] 'cycle-spacing)



(set-face-attribute 'default nil :font "DejaVu Sans Mono" :height k4i/default-font-size)

;; set the fixed pitch face
(set-face-attribute 'fixed-pitch nil :font "DejaVu Sans Mono" :height 0.9)

;; Set the variable pitch face
(set-face-attribute 'variable-pitch nil :font "Cantarell" :height 1.0 :weight 'regular)

(use-package all-the-icons)

(use-package rainbow-delimiters
  :hook
  (prog-mode . rainbow-delimiters-mode))

(add-hook 'after-init-hook 'show-paren-mode)

(use-package command-log-mode
  :commands command-log-mode)

(use-package doom-themes
  :init (load-theme 'doom-gruvbox-light t))

(use-package doom-modeline
  :custom
  (doom-modeline-height 15)
  :hook
  (after-init . doom-modeline-mode))

(use-package yasnippet
  :hook ((prog-mode conf-mode text-mode snippet-mode) . yas-minor-mode))

(use-package yasnippet-snippets
  :after (yasnippet))

;; (advice-add 'company-complete-common :before (lambda ()
;;                                 (setq my-company-point (point))))
;; (advice-add 'company-complete-common :after (lambda ()
;;                                 (when (equal my-company-point (point)) (yas-expand))))

(defun k4i/org-font-setup ()
  ;; Set faces for heading levels
  (dolist (face '((org-level-1 . 1.2)
                  (org-level-2 . 1.1)
                  (org-level-3 . 1.05)
                  (org-level-4 . 1.0)
                  (org-level-5 . 1.1)
                  (org-level-6 . 1.1)
                  (org-level-7 . 1.1)
                  (org-level-8 . 1.1)))
    (set-face-attribute (car face) nil :font "Cantarell" :weight 'bold :height (cdr face)))

  ;; Ensure that anything that should be fixed-pitch in Org files appears that way
  (set-face-attribute 'org-block nil    :foreground nil :inherit 'fixed-pitch)
  ;; (set-face-attribute 'org-table nil    :inherit 'fixed-pitch)
  (set-face-attribute 'org-formula nil  :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil     :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-table nil    :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox nil  :inherit 'fixed-pitch)
  (set-face-attribute 'line-number nil :inherit 'fixed-pitch)
  (set-face-attribute 'line-number-current-line nil :inherit 'fixed-pitch))

(defun k4i/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (visual-line-mode 1))

(use-package org
  :pin org
  :commands (org-capture org-agenda)
  :hook (org-mode . k4i/org-mode-setup)
  :custom
  (org-image-actual-width (/ (nth 3 (assq 'geometry (frame-monitor-attributes))) 3))
  (org-startup-folded t)
  (org-directory (expand-file-name "Org" (getenv "HOME")))
  (org-ellipsis " ▾")
  (org-agenda-start-with-log-mode t)
  ;; (org-hide-emphasis-markers t)
  (org-log-done 'time)
  (org-log-into-drawer t)
  ;; org-directory/GTD
  (org-agenda-files (list (expand-file-name "GTD" org-directory)))
  ;; tags: C-c C-q
  (org-tag-alist
   '((:startgroup)
     ("@notes" . ?n)
     ("@workspace_setup" . ?w)
     ("@Data_Structure_and_Algorithm" . ?d)
     (:endgroup)
     ("idea" . ?i)))
  :config
  (font-lock-add-keywords 'org-mode
                          '(("^ *\\([-]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

  ;; C-c C-t
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d!)")
          (sequence "BACKLOG(b)" "PLAN(p)" "READY(r)" "ACTIVE(a)" "REVIEW(v)" "WAIT(w@/!)" "HOLD(h)" "|" "COMPLETED(c)" "CANC(k@)")))

  (setq org-refile-targets
        '(("Archive.org" :maxlevel . 1)
          ("Tasks.org" :maxlevel . 1)))

  ;; Save Org buffers after refiling!
  (advice-add 'org-refile :after 'org-save-all-org-buffers)

  (k4i/org-font-setup))

(use-package org-bullets
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")))

(defun k4i/org-mode-visual-fill ()
  (setq visual-fill-column-width 100
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(use-package visual-fill-column
  :hook (org-mode . k4i/org-mode-visual-fill)
  :config
  (advice-add 'text-scale-adjust :after #'visual-fill-column-adjust))

(general-evil-define-key '(normal visual insert) org-mode-map
  "M-h" 'org-metaleft
  "M-H" 'org-shiftmetaleft
  "M-l" 'org-metaright
  "M-L" 'org-shiftmetaright
  "M-j" 'org-metadown
  "M-J" 'org-shiftmetadown
  "M-k" 'org-metaup
  "M-K" 'org-shiftmetaup)

;; Configure custom agenda views
(with-eval-after-load 'org-agenda
  (setq org-agenda-custom-commands
        '(("d" "Dashboard"
           ((agenda "" ((org-deadline-warning-days 14)))
            (todo "NEXT"
                  ((org-agenda-overriding-header "Next Tasks")))
            (tags-todo "agenda/ACTIVE" ((org-agenda-overriding-header "Active Projects")))))

          ("n" "Next Tasks"
           ((todo "NEXT"
                  ((org-agenda-overriding-header "Next Tasks")))))

          ("w" "Workflow Status"
           ((todo "WAIT"
                  ((org-agenda-overriding-header "Waiting on External")
                   (org-agenda-files org-agenda-files)))
            (todo "REVIEW"
                  ((org-agenda-overriding-header "In Review")
                   (org-agenda-files org-agenda-files)))
            (todo "PLAN"
                  ((org-agenda-overriding-header "In Planning")
                   (org-agenda-todo-list-sublevels nil)
                   (org-agenda-files org-agenda-files)))
            (todo "BACKLOG"
                  ((org-agenda-overriding-header "Project Backlog")
                   (org-agenda-todo-list-sublevels nil)
                   (org-agenda-files org-agenda-files)))
            (todo "READY"
                  ((org-agenda-overriding-header "Ready for Work")
                   (org-agenda-files org-agenda-files)))
            (todo "ACTIVE"
                  ((org-agenda-overriding-header "Active Projects")
                   (org-agenda-files org-agenda-files)))
            (todo "COMPLETED"
                  ((org-agenda-overriding-header "Completed Projects")
                   (org-agenda-files org-agenda-files)))
            (todo "CANC"
                  ((org-agenda-overriding-header "Cancelled Projects")
                   (org-agenda-files org-agenda-files))))))))

(with-eval-after-load 'org
  (require 'org-habit)
  (add-to-list 'org-modules 'org-habit)
  (setq org-habit-graph-column 60))

(use-package org-download
  :after org
  :hook ((org-mode dired-mode) . org-download-enable)
  :custom
  (org-download-image-dir "images")
  (org-dwnload-method 'directory)
  (org-download-heading-lvl nil)
  (org-download-timestamp "%Y%m%d-%H%M%S_")
  ;; (org-download-annotate-function (lambda (_link) ""))
  :bind
  ("C-M-y" .
   (lambda (&optional noask)
     (interactive "P")
     (let ((file
            (if (not noask)
                (read-string (format "Filename [%s]: " org-download-screenshot-basename)
                             nil nil org-download-screenshot-basename)
              nil)))
       (org-download-clipboard file))))
  :config
  (require 'org-download))

(use-package ox-reveal
  :after ox
  :custom
  ;; or use a online revealjs
  ;; #+REVEAL_ROOT: https://cdn.jsdelivr.net/npm/reveal.js
  (org-reveal-root (concat "file://" (expand-file-name "~/app/revealjs/reveal.js-master/"))))

(use-package ox-hugo
  :after ox)

(with-eval-after-load 'ox-latex
  ;; http://orgmode.org/worg/org-faq.html#using-xelatex-for-pdf-export
  ;; latexmk runs pdflatex/xelatex (whatever is specified) multiple times
  ;; automatically to resolve the cross-references.
  (setq org-latex-pdf-process '("latexmk -xelatex -quiet -shell-escape -f %f"))
  ;; (setq org-latex-pdf-process '("pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))
  (add-to-list 'org-latex-classes
               '("elegantpaper"
                 "\\documentclass[lang=cn]{elegantpaper}
               [NO-DEFAULT-PACKAGES]
               [PACKAGES]
               [EXTRA]"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
  (add-to-list 'org-latex-classes
               '("beamer"
                 "\\documentclass[presentation]{beamer}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))
  (setq org-latex-listings 'minted)
  (setq org-latex-minted-options
        '(("frame" "none")
          ("linenos" "false")
          ("breaklines" "true")
          ("bgcolor" "lightgray")))
  (add-to-list 'org-latex-packages-alist '("" "minted")))

(with-eval-after-load 'org
  (org-babel-do-load-languages
      'org-babel-load-languages
      '((emacs-lisp . t)
      (python . t)))

  (push '("conf-unix" . conf-unix) org-src-lang-modes))

;; Automatically tangle our org config file in the emacs directory when we save it
(defun k4i/org-babel-tangle-config ()
  "tangle any org-mode file inside user-emacs-directory"
  (when (string-equal (file-name-directory (buffer-file-name))

                      (let (
                            ;; (emacs-config-dir user-emacs-directory)
                            (emacs-config-dir "~/.dotfiles/.emacs.d/")
                            )
                        (expand-file-name emacs-config-dir))
                      )
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'k4i/org-babel-tangle-config)))

(with-eval-after-load 'org-capture
  (add-to-list 'org-capture-templates
               '("t" "Task"  entry
                 (file "GTD/Tasks.org")
                 "* TODO %?\nDEADLINE: %(format-time-string \"%<<%Y-%m-%d %a>>\")\n"
                 :unnarrowed t)))

(with-eval-after-load 'org-capture
  (add-to-list 'org-capture-templates
               '("c" "Contact"  entry
                 (file "GTD/Contacts.org")
                 "* %?\n:PROPERTIES:\n:ADDRESS:\n:PHONE:\n:BDAY: %(format-time-string \"%<<%Y-%m-%d %a +1y>>\")\n:EMAIL:\n:END:\n"
                 :unnarrowed t)))

(with-eval-after-load 'org-capture
  (add-to-list 'org-capture-templates
               '("h" "Habit"  entry
                 (file "GTD/Habits.org")
                 "* NEXT %?\nSCHEDULED: %(format-time-string \"%<<%Y-%m-%d %a .+1d/3d>>\")\n:PROPERTIES:\n:STYLE: habit\n:REPEAT_TO_STATE: NEXT\n:END:\n"
                 :unnarrowed t)))

(defun org-hugo-new-subtree-post-capture-template ()
  "Returns `org-capture' template string for new Hugo post.
 See `org-capture-templates' for more information."
  (let* (;; http://www.holgerschurig.de/en/emacs-blog-from-org-to-hugo/
         (date (format-time-string (org-time-stamp-format :long :inactive) (org-current-time)))
         (title (read-from-minibuffer "Post Title: ")) ;Prompt to enter the post title
         (fname (org-hugo-slug title)))
    (mapconcat #'identity
               `(
                 ,(concat "\n* TODO " title "  :@cat:tag:")
                 ":PROPERTIES:"
                 ,(concat ":EXPORT_HUGO_BUNDLE: " fname)
                 ":EXPORT_FILE_NAME: index"
                 ,(concat ":EXPORT_DATE: " date) ;Enter current date and time
                 ":EXPORT_HUGO_CUSTOM_FRONT_MATTER: :image \"/images/icons/tortoise.png\""
                 ":EXPORT_HUGO_CUSTOM_FRONT_MATTER+: :libraries '(mathjax)"
                 ":EXPORT_HUGO_CUSTOM_FRONT_MATTER+: :description \"this is a description\""
                 ":END:"
                 "%?\n")
               "\n")))

(with-eval-after-load 'org-capture
  (setq hugo-content-org-dir "~/git-repo/blog/blog-src/content-org")
  (add-to-list 'org-capture-templates
               `("pe"                ;`org-capture' binding + h
                 "Hugo Post (en)"
                 entry
                 ;; It is assumed that below file is present in `org-directory'
                 ;; and that it has a "Blog Ideas" heading. It can even be a
                 ;; symlink pointing to the actual location of all-posts.org!
                 (file ,(expand-file-name "all-posts.en.org" hugo-content-org-dir))
                 (function org-hugo-new-subtree-post-capture-template)))
  (add-to-list 'org-capture-templates
               `("pz"
                 "Hugo Post (zh)"
                 entry
                 (file ,(expand-file-name "all-posts.zh.org" hugo-content-org-dir))
                 (function org-hugo-new-subtree-post-capture-template)))
  (add-to-list 'org-capture-templates '("p" "Hugo Post")))

(use-package org-roam
  :after org
  :init
  (setq org-roam-v2-ack t)
  :custom
  (org-roam-directory (expand-file-name "Org-Roam" org-directory))
  (org-roam-complete-everywhere t)
  :config
  (org-roam-setup)
  :bind
  (("C-c n f" . org-roam-node-find)
   ("C-c n r" . org-roam-node-random)
   :map org-mode-map
   ("C-c n i" . org-roam-node-insert)
   ("C-c n o" . org-id-get-create)
   ("C-c n t" . org-roam-tag-add)
   ("C-c n a" . org-roam-alias-add)
   ("C-c n l" . org-roam-buffer-toggle)
   ("C-M-i" . completion-at-point)))

(use-package org-roam-ui
  :after org-roam
  :custom
  (org-roam-ui-sync-theme t)
  (org-roam-ui-follow t)
  (org-roam-ui-update-on-save t))

(use-package subword
  :hook (prog-mode . subword-mode)
  :diminish)

(use-package symbol-overlay
  :hook ((prog-mode html-mode yaml-mode conf-mode) . symbol-overlay-mode)
  :bind (:map symbol-overlay-mode-map
              ("M-i" . symbol-overlay-put)
              ("M-I" . symbol-overlay-remove-all)
              ("M-n" . symbol-overlay-jump-next)
              ("M-p" . symbol-overlay-jump-prev))
 :diminish)

(use-package flycheck
  :init (global-flycheck-mode)
  :custom
  (flycheck-display-errors-function #'flycheck-display-error-messages-unless-error-list))

(use-package company
  :init (global-company-mode)
  :bind (:map company-mode-map
              ("M-/" . company-complete)
              ;; not smart enough
              ;; ("<tab>" . company-indent-or-complete-common)
              :map company-active-map
              ("RET" . nil)
              ("<return>" . nil)
              ("<tab>" . company-complete-selection)
              ("M-/" . company-other-backend))
  :custom
  (company-global-modes '(not message-mode help-mode magit-mode))
  (company-minimum-prefix-length 1)
  (company-idle-delay 0.0)
  (company-tooltip-aligh-annotations t)
  ;; easy navigation to candidates with M-<n>
  (company-show-numbers t)
  (company-dabbrev-downcase nil)
  (company-backends '((company-files
                       company-yasnippet
                       company-keywords
                       company-capf)
                      (company-abbrev company-dabbrev)))
  :config
  (defun my-company-yasnippet-disable-inline (fun command &optional arg &rest _ignore)
    "Enable yasnippet but disable it inline."
    (if (eq command 'prefix)
        (when-let ((prefix (funcall fun 'prefix)))
          (unless (memq (char-before (- (point) (length prefix))) '(?. ?> ?\())
            prefix))
      (funcall fun command arg)))
  (advice-add #'company-yasnippet :around #'my-company-yasnippet-disable-inline)
  :diminish company-mode)

(use-package company-box
  :hook (company-mode . company-box-mode))

(use-package evil-nerd-commenter
  :bind ("C-/" . evilnc-comment-or-uncomment-lines))

(use-package format-all
  :hook
  (prog-mode . format-all-mode)
  (format-all-mode . format-all-ensure-formatter))

(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode)
  :custom ((projectile-completion-system 'ivy))
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :init
  ;; NOTE: Set this to the folder where you keep your Git repos!
  (when (file-directory-p "~/git-repo/")
    (setq projectile-project-search-path '("~/git-repo/")))
  (setq projectile-switch-project-action #'projectile-dired))

(use-package counsel-projectile
  :after projectile
  :config (counsel-projectile-mode))

(use-package magit
  :commands magit-status
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

;; NOTE: Make sure to configure a GitHub token before using this package!
;; - https://magit.vc/manual/forge/Token-Creation.html#Token-Creation
;; - https://magit.vc/manual/ghub/Getting-Started.html#Getting-Started
(use-package forge
  :after magit)

(defun k4i/lsp-mode-setup ()
  (setq lsp-headerline-breadcrumb-segments '(path-up-to-project file symbols))
  (lsp-headerline-breadcrumb-mode))

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :hook (lsp-mode . k4i/lsp-mode-setup)
  :init
  (setq lsp-keymap-prefix "C-c l")  ;; Or 'C-l', 's-l'
  :config
  (lsp-enable-which-key-integration t))

(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode)
  :custom
  (lsp-ui-doc-position 'bottom))

(use-package lsp-ivy
  :after lsp)

(use-package dap-mode
  :after lsp-mode
  ;; Uncomment the config below if you want all UI panes to be hidden by default!
  ;; :custom
  ;; (lsp-enable-dap-auto-configure nil)
  ;; :config
  ;; (dap-ui-mode 1)
  :commands dap-debug
  :config
  ;; Set up Node debugging
  (require 'dap-node)
  (dap-node-setup) ;; Automatically installs Node debug adapter if needed

  (require 'dap-python)

  ;; C/C++
  ;; lldb is a debugger that supports: C, C++, Objective-C, Swift
  (require 'dap-lldb)
  ;; set the debugger executable (c++), by default it looks for it under .emacs.d/..
  (setq dap-lldb-debug-program '("lldb-vscode"))

  ;; Bind `C-c l d` to `dap-hydra` for easy access
  (general-define-key
    :keymaps 'lsp-mode-map
    :prefix lsp-keymap-prefix
    "d" '(dap-hydra t :wk "debugger")))

(use-package typescript-mode
  :mode "\\.ts\\'"
  :hook (typescript-mode . lsp-deferred)
  :config
  (setq typescript-indent-level 2))

(use-package python-mode
  :ensure t
  :hook (python-mode . lsp-deferred)
  :custom
  ;; NOTE: Set these if Python 3 is called "python3" on your system!
  ;; (python-shell-interpreter "python3")
  ;; (dap-python-executable "python3")
  (dap-python-debugger 'debugpy)
  :config
  (require 'dap-python))

(use-package pyvenv
  :after python-mode
  :config
  (pyvenv-mode 1))

(use-package vterm
  :commands vterm
  :config
  (setq term-prompt-regexp "^[^#$%>❯\n]*[#$%>❯] *")  ;; Set this to match your custom shell prompt
  ;;(setq vterm-shell "zsh")                       ;; Set this to customize the shell to launch
  (setq vterm-max-scrollback 10000))

(use-package vterm-toggle
  :custom
  (vterm-toggle-hide-method 'delete-window)
  :hook
  (vterm-toggle-show . evil-insert-state)
  :config
  (setq vterm-toggle-fullscreen-p nil)
  (add-to-list 'display-buffer-alist
               '((lambda (bufname _)
                   (with-current-buffer bufname (equal major-mode 'vterm-mode)))
                (display-buffer-reuse-window display-buffer-in-direction)
                ;;display-buffer-in-direction/direction/dedicated is added in emacs27
                (direction . bottom)
                (dedicated . t) ;dedicated is supported in emacs27
                (reusable-frames . visible)
                (window-height . 0.3))))

(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :custom ((dired-listing-switches "-agho --group-directories-first"))
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "h" 'dired-single-up-directory
    "l" 'dired-single-buffer))

;; use single buffer
(use-package dired-single
  :commands (dired dired-jump))

;; use all-the-icons icon in dired
(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode))

(use-package dired-subtree
  :after dired
  :bind (:map dired-mode-map
              ("<tab>" . dired-subtree-toggle)
              ("<C-tab>" . dired-subtree-cycle)
              ("<S-iso-lefttab>" . dired-subtree-remove)))

(use-package dired-open
  :commands (dired dired-jump)
  :general
  ("C-c o" 'dired-open-xdg)
  :config
  ;; by default <Enter> does not use dired-open-xdg
  ;; (add-to-list 'dired-open-functions #'dired-open-xdg t)
  (setq dired-open-extensions '(("png" . "feh")
                                ("mkv" . "mpv"))))

(use-package dired-hide-dotfiles
  ;; :hook (dired-mode . dired-hide-dotfiles-mode)
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "H" 'dired-hide-dotfiles-mode))

(use-package lsp-treemacs
  :after lsp)

(use-package treemacs
  :custom
  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-project-follow-mode t)
  (treemacs-fringe-indicator-mode t))

(use-package treemacs-evil
  :after treemacs evil)

(defun proxy-socks-show ()
  "Show SOCKS proxy."
  (interactive)
  (when (fboundp 'cadddr)
    (if (bound-and-true-p socks-noproxy)
        (message "Current SOCKS%d proxy is %s:%d"
                 (cadddr socks-server) (cadr socks-server) (caddr socks-server))
      (message "No SOCKS proxy"))))

(defun proxy-socks-enable ()
  "Enable SOCKS proxy."
  (interactive)
  (require 'socks)
  (setq url-gateway-method 'socks
        socks-noproxy '("localhost")
        socks-server '("Default server" "127.0.0.1" 1081 5))
  (setenv "all_proxy" "socks5://127.0.0.1:1081")
  (proxy-socks-show))

(defun proxy-socks-disable ()
  "Disable SOCKS proxy."
  (interactive)
  (require 'socks)
  (setq url-gateway-method 'native
        socks-noproxy nil)
  (setenv "all_proxy" "")
  (proxy-socks-show))

(defun proxy-socks-toggle ()
  "Toggle SOCKS proxy."
  (interactive)
  (require 'socks)
  (if (bound-and-true-p socks-noproxy)
      (proxy-socks-disable)
    (proxy-socks-enable)))

;; Configure network proxy
(setq my-http-proxy "127.0.0.1:1080")
(defun proxy-http-show ()
  "Show http/https proxy."
  (interactive)
  (if url-proxy-services
      (message "Current proxy is \"%s\"" my-http-proxy)
    (message "No proxy")))

(defun proxy-http-enable ()
  "Set http/https proxy."
  (interactive)
  (setq url-proxy-services `(("http" . ,my-http-proxy)
                             ("https" . ,my-http-proxy)))
  (proxy-http-show))

(defun proxy-http-disable ()
  "Unset http/https proxy."
  (interactive)
  (setq url-proxy-services nil)
  (proxy-http-show))

(defun proxy-http-toggle ()
  "Toggle http/https proxy."
  (interactive)
  (if url-proxy-services
      (proxy-http-disable)
    (proxy-http-enable)))
