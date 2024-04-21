(let ((normal-gc-cons-threshold (* 20 1024 1024))
      (init-gc-cons-threshold (* 128 1024 1024)))
  (setq gc-cons-threshold init-gc-cons-threshold)
  (add-hook 'emacs-startup-hook
            `(lambda () (setq gc-cons-threshold ,normal-gc-cons-threshold))))

(defun k4i/display-startup-time ()
  (message "init completed in %.2f seconds with %d garbage collections."
           (float-time (time-subtract after-init-time before-init-time))
           gcs-done))

(add-hook 'after-init-hook #'k4i/display-startup-time)

(require 'server)
(unless (server-running-p) (server-start))

(when (>= emacs-major-version 24)
  (progn
    ;; load emacs 24's package system. Add MELPA repository.
    (require 'package)
    (let (;; tsinghua
          (archives '("http://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/"
                      "http://mirrors.tuna.tsinghua.edu.cn/elpa/org/"
                      "http://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/"))
          ;; ustc
          ;; (archives '("http://mirrors.ustc.edu.cn/elpa/melpa/"
          ;;             "http://mirrors.ustc.edu.cn/elpa/org/"
          ;;             "http://mirrors.ustc.edu.cn/elpa/gnu/"))
          ;; official
          ;; (archives '("https://melpa.org/packages/"
          ;;             "http://orgmode.org/elpa/"
          ;;             "https://elpa.gnu.org/packages/"))
          )
      (setq package-archives `(("melpa" . ,(nth 0 archives))
                               ("org" . ,(nth 1 archives))
                               ("gnu" . ,(nth 2 archives)))))
    )

  ;; does not eagerly load installed packages, just add their directories to `load-path` and evaluate their `autoloads`
  ;; (when (< emacs-major-version 27) (package-initialize))
  (package-initialize)
  )

(unless package-archive-contents
  (package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

(use-package async
  :config (setq async-bytecomp-package-mode 1))

;; add .emacs.d/lisp to load-path
(add-to-list 'load-path (locate-user-emacs-file "lisp"))

(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

;; Produce backtraces when errors occur: can be helpful to diagnose startup issues
;; you can turn it on and off with toggle-debug-on-error
;; (setq debug-on-error t)

(advice-add 'risky-local-variable-p :override #'ignore)

(use-package wgrep)

(use-package ivy
  :after counsel
  :diminish
  :bind (("C-s" . swiper)
         ("C-M-j" . ivy-switch-buffer)
         ("C-M-S-j" . ivy-switch-tab)
         :map ivy-minibuffer-map
         ("TAB" . ivy-partial)
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
  :config
  (ivy-rich-mode 1))

;; ivy will show recently selected candidates first
(use-package ivy-prescient
  :after counsel
  :custom
  (ivy-prescient-enable-filtering nil)
  :config
  ;; Uncomment the following line to have sorting remembered across sessions!
                                        ;(prescient-persist-mode 1)
  (ivy-prescient-mode 1))

(use-package counsel
  :bind (:map minibuffer-local-map
              ("C-r" . 'counsel-minibuffer-history))
  :custom
  (counsel-linux-app-format-function #'counsel-linux-app-format-function-name-only)
  :config
  (counsel-mode 1))

(use-package ivy-posframe
  :demand t
  :after ivy
  :custom
  (ivy-posframe-display-functions-alist '(
                                          (swiper . ivy-display-function-fallback)
                                          (t . ivy-posframe-display-at-frame-center)
                                          ))
  :config
  (ivy-posframe-mode))

;; adjust font size for your system
(defvar k4i/default-font-size 160)
(defvar k4i/default-variable-font-size 160)

(setq inhibit-startup-message t)

(scroll-bar-mode -1) ; Disable visible scrollbar
(tool-bar-mode -1) ; Disable the toolbar
(tooltip-mode -1) ; Disable tooltips
(set-fringe-mode 8) ; Give some breathing room
(menu-bar-mode -1) ; Disable the menu bar
;; Set up the visible bell
(setq visible-bell t)
(set-frame-parameter (selected-frame) 'fullscreen 'maximized)
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode t)
(column-number-mode) ; show column number
;; Disable line numbers for some modes
(dolist (mode '(org-mode-hook
                term-mode-hook
                vterm-mode-hook
                shell-mode-hook
                eshell-mode-hook
                treemacs-mode-hook))
    (add-hook mode (lambda () (display-line-numbers-mode 0))))

(use-package autorevert
  :hook
  ;; reverts any buffer associated with a file when the file changes on disk
  (after-init-hook . global-auto-revert-mode)
  :custom
  (global-auto-revert-non-file-buffers t)
  (auto-revert-verbose t)
  :diminish)

(setq initial-scratch-message
      ";; Hello Hackers! Welcom to emacs!\n\n(setq debug-on-error t)\n\n;; proxys\n(proxy-socks-toggle)\n(proxy-http-toggle)\n\n(package-refresh-contents)")

;; default values
(setq-default
 help-window-select t
 show-trailing-whitespace t
 buffers-menu-max-size 60
 ;; searches are case insensitive
 case-fold-search t
 ;; toggle column number in the mode line
 column-number-mode t
 ediff-split-window-function 'split-window-horizontally
 ediff-window-setup-function 'ediff-setup-windows-plain
 ;; indent use tabs or spaces
 indent-tabs-mode nil
 create-lockfiles nil
 auto-save-default nil
 make-backup-files nil
 mouse-yank-at-point t
 save-interprogram-paste-before-kill t
 scroll-preserve-screen-position 'always
 set-mark-command-repeat-pop t
 tooltip-delay 1.0
 truncate-lines nil
 truncate-partial-width-windows nil)

(use-package dashboard
  :after all-the-icons
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-center-content t)
  (setq dashboard-vertically-center-content t)
  (setq dashboard-navigation-cycle t)
  (setq dashboard-heading-shorcut-format " [%s]")
  (setq dashboard-icon-type 'all-the-icons)  ; use `all-the-icons' package
  ;(setq initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name)))
  (setq initial-buffer-choice (lambda () (dashboard-refresh-buffer)))
  )

(use-package beacon
  :custom
  (beacon-lighter "")
  (beacon-size 30)
  :config
  (beacon-mode 1))

;; (setq x-pointer-shape x-pointer-top-left-arrow)
(setq x-pointer-shape x-pointer-pencil)
;; (setq x-pointer-sizing 240)
;; (setq x-sensitive-text-pointer-shape x-pointer-X-cursor)
;; (set-mouse-color "green")

(mouse-avoidance-mode 'banish)

(defun k4i/show-trailing-whitespace ()
  "Enable display of trailing whitespace in this buffer."
  (setq-local show-trailing-whitespace t))

(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook 'k4i/show-trailing-whitespace))

(add-hook 'before-save-hook
          'delete-trailing-whitespace)

;; M-SPC
(global-set-key [remap just-one-space] 'cycle-spacing)

(use-package whitespace
  :hook
  (prog-mode . whitespace-mode)
  :config
  (setq whitespace-style (quote (face spaces tabs newline space-mark tab-mark newline-mark)))
  (let ((foreground-color "gray80"))
    (set-face-attribute 'whitespace-space nil :background nil :foreground foreground-color)
    (set-face-attribute 'whitespace-tab nil :background nil :foreground foreground-color)
    (set-face-attribute 'whitespace-newline nil :background nil :foreground foreground-color)
    )
  (setq whitespace-display-mappings
        ;; all numbers are Unicode codepoint in decimal. try (insert-char 8617) to see it
        '((space-mark 32 [183] [46]) ; 32 SPACE, 183 MIDDLE DOT 「·」, 46 FULL STOP 「.」
          (newline-mark 10 [8617 10]) ; 10 LINE FEED↩
          (tab-mark 9 [9655 9] [92 9]) ; 9 TAB, 9655 WHITE RIGHT-POINTING TRIANGLE 「▷」
          ))
  )

(use-package electric
  :hook
  ;; smart indent based on the major mode
  (after-init-hook . electric-indent-mode))

(set-face-attribute 'default nil :font "DejaVu Sans Mono" :height k4i/default-font-size)

;; set the fixed pitch face
(set-face-attribute 'fixed-pitch nil :font "DejaVu Sans Mono" :height 1.0)

;; Set the variable pitch face
(set-face-attribute 'variable-pitch nil :font "Cantarell" :height 1.0 :weight 'regular)

(use-package all-the-icons)

(use-package rainbow-delimiters
  :hook
  (prog-mode . rainbow-delimiters-mode))

(add-hook 'after-init-hook 'show-paren-mode)

(use-package elec-pair
  :hook
  (after-init . electric-pair-mode))

(use-package rainbow-mode
  :hook
  (css-mode . rainbow-mode)
  :delight)

(use-package doom-themes
  :config
  (load-theme 'doom-gruvbox-light t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

(use-package doom-modeline
  :custom
  (doom-modeline-height 15)
  :hook
  (after-init . doom-modeline-mode))

(use-package command-log-mode
  :commands command-log-mode)

(use-package pyim-basedict)

(use-package pyim
  :after pyim-basedict
  :custom
  (pyim-page-length 9)
  :config
  (pyim-basedict-enable)
  (setq default-input-method "pyim")
  ;; use v to toggle previous punctuation
  (setq-default pyim-punctuation-translate-p '(no yes auto)))

(defun k4i/save-word-to-dict ()
  (interactive)
  (let ((current-location (point))
        (word (flyspell-get-word)))
    (when (and (consp word) (yes-or-no-p (format "save word %S?" (car word))))
      (flyspell-do-correct 'save nil (car word) current-location (cadr word) (caddr word) current-location)
      (message "saved %S to dict" (car word))
      )
    )
  )

(defun flyspell-on-for-buffer-type ()
  "Enable Flyspell appropriately for the major mode of the current buffer.  Uses `flyspell-prog-mode' for modes derived from `prog-mode', so only strings and comments get checked.  All other buffers get `flyspell-mode' to check all text.  If flyspell is already enabled, does nothing."
  (interactive)
  (if (not (symbol-value flyspell-mode)) ; if not already on
      (progn
        (if (derived-mode-p 'prog-mode)
            (progn
              (message "Flyspell on (code)")
              (flyspell-prog-mode))
          ;; else
          (progn
            (message "Flyspell on (text)")
            (flyspell-mode 1)))
        ;; I tried putting (flyspell-buffer) here but it didn't seem to work
        )))

(defun flyspell-toggle ()
  "Turn Flyspell on if it is off, or off if it is on.  When turning on, it uses `flyspell-on-for-buffer-type' so code-vs-text is handled appropriately."
  (interactive)
  (if (symbol-value flyspell-mode)
      (progn ; flyspell is on, turn it off
        (message "Flyspell off")
        (flyspell-mode -1))
    ;; else - flyspell is off, turn it on
    (flyspell-on-for-buffer-type)))

(use-package flyspell
  :custom
  (flyspell-issue-message-flag nil)
  :bind
  ("C-M-S-i" . k4i/save-word-to-dict)
  :hook
  ((find-file . flyspell-on-for-buffer-type)
  (after-change-major-mode . flyspell-on-for-buffer-type)))

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
  (setq evil-want-C-i-jump t)
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
    "d" '((lambda () (interactive) (dired default-directory)) :which-key "dired default dir")
    "f"  '(:ignore t :which-key "file")
    "fb"  '((lambda () (interactive) (find-file (expand-file-name "~/git-repo/blog/blog-src/content-org/all-posts.en.org"))) :which-key "blogs")
    "fd" '(:ignore t :which-key "dotfiles")
    "fde" '((lambda () (interactive) (find-file (expand-file-name "~/.dotfiles/.emacs.d/README.org"))) :which-key "emacs")
    "fdw" '((lambda () (interactive) (find-file (expand-file-name "~/.dotfiles/.config/i3/config"))) :which-key "window manager")
    "k" 'kill-this-buffer
    "o"  '(:ignore t :which-key "org")
    "oa" 'org-agenda
    "oc" 'org-capture
    "r" 'resize-window
    "t"  '(:ignore t :which-key "toggles")
    "tt" '(counsel-load-theme :which-key "choose theme")
    "tf" 'treemacs
    "ts" 'flyspell-toggle
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

(use-package helpful
  :commands (helpful-callable helpful-variable helpful-command helpful-key)
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key)
  :config
  ;; (add-to-list 'display-buffer-alist
  ;;              `("\\*help"
  ;;                (display-buffer-reuse-window display-buffer-in-side-window)
  ;;                (reusable-frames . visible)
  ;;                (side . right)
  ;;                (window-width . 0.3)
                 ;; ))
  )

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

(use-package centaur-tabs
  :hook emacs-startup
  :custom
  (centaur-tabs-background-color "#f2e5bc")
  (centaur-tabs-style "chamfer")
  (centaur-tabs-height 32)
  (centaur-tabs-height 32)
  (centaur-tabs-set-icons t)
  (centaur-tabs-set-modified-marker t)
  (centaur-tabs-show-navigation-buttons t)
  ;; (centaur-tabs-set-bar 'under)
  (x-underline-at-descent-line t)
  :config
  (centaur-tabs-headline-match)
  ;; (setq centaur-tabs-gray-out-icons 'buffer)
  ;; (centaur-tabs-enable-buffer-reordering)
  ;; (setq centaur-tabs-adjust-buffer-order t)
  (setq uniquify-separator "/")
  (setq uniquify-buffer-name-style 'forward)
  (defun centaur-tabs-buffer-groups ()
    "`centaur-tabs-buffer-groups' control buffers' group rules.

 Group centaur-tabs with mode if buffer is derived from `eshell-mode' `emacs-lisp-mode' `dired-mode' `org-mode' `magit-mode'.
 All buffer name start with * will group to \"Emacs\".
 Other buffer group by `centaur-tabs-get-group-name' with project name."
    (list
     (cond
      ;; ((not (eq (file-remote-p (buffer-file-name)) nil))
      ;; "Remote")
      ((derived-mode-p 'eshell-mode 'term-mode 'shell-mode 'vterm-mode)
     "Term")
      ((or (string-equal "*" (substring (buffer-name) 0 1))
           (memq major-mode '(magit-process-mode
                              magit-status-mode
                              magit-diff-mode
                              magit-log-mode
                              magit-file-mode
                              magit-blob-mode
                              magit-blame-mode
                              )))
       "Emacs")
      ((derived-mode-p 'prog-mode)
       "Editing")
      ((derived-mode-p 'dired-mode)
       "Dired")
      ((memq major-mode '(helpful-mode
                          help-mode))
       "Help")
      ((memq major-mode '(org-mode
                            org-agenda-clockreport-mode
                            org-src-mode
                            org-agenda-mode
                            org-beamer-mode
                            org-indent-mode
                            org-bullets-mode
                            org-cdlatex-mode
                            org-agenda-log-mode
                            diary-mode))
         "OrgMode")
      (t
       (centaur-tabs-get-group-name (current-buffer))))))
  :hook
  (dashboard-mode . centaur-tabs-local-mode)
  (term-mode . centaur-tabs-local-mode)
  (calendar-mode . centaur-tabs-local-mode)
  (org-agenda-mode . centaur-tabs-local-mode)
  (helpful-mode . centaur-tabs-local-mode)
  :bind
  ("C-<prior>" . centaur-tabs-backward)
  ("C-<next>" . centaur-tabs-forward)
  ("C-c t s" . centaur-tabs-counsel-switch-group)
  ("C-c t p" . centaur-tabs-group-by-projectile-project)
  ("C-c t g" . centaur-tabs-group-buffer-groups)
  (:map evil-normal-state-map
        ("g t" . centaur-tabs-forward)
        ("g T" . centaur-tabs-backward)))

(defun ivy-switch-tab ()
  (interactive)
  (let ((buffer (ivy-read "Switch to tab: "
                          (mapcar
                           (lambda (b)
                             (buffer-name (car b)))
                           (centaur-tabs-tabs (centaur-tabs-current-tabset))
                           ;; centaur-tabs--buffers
                           ))))
    (switch-to-buffer buffer)))

(defvar k4i/align-right-modes '(inferior-python-mode
                                slime-repl-mode
                                compilation-mode
                                helpful-mode
                                comint-mode
                                org-roam-mode))

(defun update-current-window-parameter ()
  "update window parameter of selected-window"
  (interactive)
  (set-window-parameter nil
                        (intern (read-from-minibuffer "parameter: "))
                        (read-from-minibuffer "value: ")))
;; side-window
(add-to-list 'display-buffer-alist
             `(,(lambda (buf act)
                  (member (with-current-buffer buf major-mode) k4i/align-right-modes))
               (display-buffer--maybe-same-window
                display-buffer-reuse-window
                display-buffer-reuse-mode-window
                display-buffer-in-side-window)
               (side . right)
               (mode . ,k4i/align-right-modes)
               (window-width . 0.3)
               (quit-restore ('window 'window nil nil))))


;; input buffer
(add-to-list 'display-buffer-alist
             `(,(lambda (buf act)
                  (when-let ((filename (with-current-buffer buf buffer-file-name)))
                    (string-equal "in.txt" (file-name-nondirectory filename))))
               (,(lambda (buf act)
                   (when-let ((window (window-with-parameter 'for-input-window)))
                     (set-window-buffer window buf)
                     window)))
               (quit-restore ('window 'window nil nil))))

;; output buffer
(add-to-list 'display-buffer-alist
             `(,(lambda (buf act)
                  (when-let ((filename (with-current-buffer buf buffer-file-name)))
                    (string-equal "out.txt" (file-name-nondirectory filename))))
               (,(lambda (buf act)
                   (when-let ((window (window-with-parameter 'for-output-window)))
                     (with-current-buffer buf (auto-revert-mode))
                     (set-window-buffer window buf)
                     window)))
               (quit-restore ('window 'window nil nil))))

(use-package eyebrowse
  :ensure t
  :config
  (eyebrowse-mode t))

(use-package burly
  :config
  (push (cons 'for-input-window 'writable) burly-window-persistent-parameters)
  (push (cons 'for-output-window 'writable) burly-window-persistent-parameters)
  )

(use-package yasnippet
  :hook ((prog-mode conf-mode text-mode snippet-mode) . yas-minor-mode)
  :config
  (yas-reload-all))

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
    (set-face-attribute (car face) nil :font "DejaVu Sans Mono" :weight 'bold :height (cdr face)))

  ;; Ensure that anything that should be fixed-pitch in Org files appears that way
  (set-face-attribute 'org-block nil    :foreground nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table nil    :inherit 'fixed-pitch)
  (set-face-attribute 'org-formula nil  :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil     :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-table nil    :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox nil  :inherit 'fixed-pitch)
  ;; (set-face-attribute 'line-number nil :inherit 'fixed-pitch)
  ;; (set-face-attribute 'line-number-current-line nil :inherit 'fixed-pitch)
  )

(defun toggle-func-of-hook (hook func)
  "add or remove func from hook"
  (if (member #'org-export-to-pdf-on-save (symbol-value hook))
      (progn
        (remove-hook hook func)
        (message "func %s disabled in hook %s" (symbol-name func) (symbol-name hook))
        )
    (progn
      (add-hook hook func)
      (message "func %s enabled in hook %s" (symbol-name func) (symbol-name hook))
      )
    )
  )

(defun toggle-org-export-to-pdf-on-save ()
  "Export current Org file to PDF."
  (interactive)
  (defun org-export-to-pdf-on-save ()
    (when (eq major-mode 'org-mode)
      (let* ((org-file (buffer-file-name))
             (pdf-file (concat (file-name-sans-extension org-file) ".pdf")))
        (message "start exporting to pdf")
        (org-latex-export-to-pdf t nil nil nil)
        )
      )
    )
  (toggle-func-of-hook 'after-save-hook 'org-export-to-pdf-on-save)
  )

(defun k4i/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (visual-line-mode 1)
  (setq-local electric-pair-inhibit-predicate `(lambda (c) (if (char-equal c ?<) t (,electric-pair-inhibit-predicate c)))))

(use-package org
  :pin org
  :commands (org-capture org-agenda)
  :hook (org-mode . k4i/org-mode-setup)
  :custom
  (org-pretty-entities t)
  (org-image-actual-width 900
                          ;; (/ (nth 3 (assq 'geometry (frame-monitor-attributes))) 3)
                          )
  (org-startup-folded t)
  (org-directory (expand-file-name "Org" (getenv "HOME")))
  ;; (org-ellipsis " ▾")
  (org-ellipsis "⇙")
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
  ;; latex preview with =C-c C-x C-l=, increase font size.
  (setq org-format-latex-options (plist-put org-format-latex-options :scale 2.0))
  (font-lock-add-keywords 'org-mode
                          '(("^ *\\([-]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

  ;; https://stackoverflow.com/questions/1218238/how-to-make-part-of-a-word-bold-in-org-mode
  ;; (setcar org-emphasis-regexp-components " \t('\"{[:alpha:]")
  ;; (setcar (nthcdr 1 org-emphasis-regexp-components) "[:alpha:]- \t.,:!?;'\")}\\")
  ;; (org-set-emph-re 'org-emphasis-regexp-components org-emphasis-regexp-components)

  ;; ;;
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d!)" "CANCELED(c)")
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
  ;; (org-download-timestamp "%Y%m%d-%H%M%S_")
  (org-download-timestamp "")
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
  (setq org-download-annotate-function #'(lambda (_link) ""))
  ;; second half of image directory from org header when org-download-heading is not nil
  (advice-add 'org-download--dir-2 :filter-return #'(lambda (dirname)
                                                      (when dirname (org-hugo-slug dirname)))))

(use-package plantuml-mode
  ;; :mode "\\.plu\\'"
  :init
  :custom
  (org-plantuml-jar-path (expand-file-name "~/app/plantuml/plantuml.jar"))
  (plantuml-jar-path (expand-file-name "~/app/plantuml/plantuml.jar"))
  ;; jar, executable, server (experimental)
  (plantuml-default-exec-mode 'jar)
  :config
  ;; https://plantuml.com/en/smetana02
  ;; use smetana insteand of graphviz
  (append plantuml-jar-args '("-Playout=smetana"))
  ;; (add-to-list 'org-src-lang-modes '("plantuml" . plantuml))
  )

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
  (setq org-latex-toc-command "\\tableofcontents \\clearpage")
  (require 'ox-beamer)
  ;; (setq org-latex-pdf-process '("pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))
  (add-to-list 'org-latex-classes
               '("elegantpaper"
                 "\\documentclass[lang=en]{elegantpaper}
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
                 "\\documentclass[presentation]{beamer}
                 [NO-DEFAULT-PACKAGES]
                 [PACKAGES]
                 [EXTRA]"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))
  (setq org-latex-listings 'minted)
  (setq org-latex-minted-options
        '(("frame" "none")
          ("linenos" "false")
          ("breaklines" "true")
          ("bgcolor" "lightgray")))
  (add-to-list 'org-latex-packages-alist '("" "minted"))
  (add-to-list 'org-latex-packages-alist '("" "svg"))
  )

(use-package ebib
  :ensure t
  :config
  (setq ebib-index-columns
        (quote
         (("timestamp" 12 t)
          ("Entry Key" 20 t)
          ("Author/Editor" 40 nil)
          ("Year" 6 t)
          ("Title" 50 t))))
  (setq ebib-index-default-sort (quote ("timestamp" . descend)))
  (setq ebib-index-default-sort (quote ("timestamp" . descend)))
  (setq ebib-preload-bib-files (quote ("~/science_works/bibliography.bib")))
  (setq ebib-timestamp-format "%Y.%m.%d")
  (setq ebib-use-timestamp t))

;; no need confirmation before evalution
(defun k4i/org-confirm-babel-evaluate (lang body)
  (not (member lang '("dot" "plantuml" "python" "shell" "emacs-lisp"))))

(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '(
     (emacs-lisp . t)
     (dot . t)
     (python . t)
     (plantuml . t)
     (shell . t)
     ))
  (setq org-confirm-babel-evaluate #'k4i/org-confirm-babel-evaluate)
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
               `("pe"
                 "Hugo Post (en)"
                 entry
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
  (setq org-roam-capture-templates
        '(("d" "default" plain "%?"
           :target (file+head "${slug}.org"
                              "#+title: ${title}\n")
           :unnarrowed t
           )))

  ;; changing title changes file name and refs automatically
  (defun org-rename-to-new-title ()
    (when-let*
        ((old-file (buffer-file-name))
         (is-roam-file (org-roam-file-p old-file))
         (file-node (save-excursion
                      (goto-char 1)
                      (org-roam-node-at-point)))
         (slug (org-roam-node-slug file-node))
         (new-file (expand-file-name (concat slug ".org")))
         (different-name? (not (string-equal old-file new-file))))
      (rename-buffer new-file)
      (rename-file old-file new-file)
      (set-visited-file-name new-file)
      (set-buffer-modified-p nil)))

  (add-hook 'after-save-hook 'org-rename-to-new-title)

  :bind
  (("C-c n f" . org-roam-node-find)
   ("C-c n r" . org-roam-node-random)
   :map org-mode-map
   ("C-c n i" . org-roam-node-insert)
   ("C-c n o" . org-id-get-create)
   ("C-c n t" . org-roam-tag-add)
   ("C-c n a" . org-roam-alias-add)
   ("C-c n l" . org-roam-buffer-toggle)
   ;; ("C-M-i" . completion-at-point)
   ))

(use-package org-roam-ui
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))

(use-package org-ref
    :after org
    :init
    :config
    (setq
         ; Let ivy makes completion.
         org-ref-completion-library 'org-ref-ivy-cite
         ; Use Helm to get pdf filename.
         org-ref-get-pdf-filename-function 'org-ref-get-pdf-filename-helm-bibtex
         ; Use the bibtext file exported from Zotero.
         ;; org-ref-default-bibliography (list (expand-file-name "library.bib" zotero-directory))
         ;; org-ref-bibliography-notes (expand-file-name "bibnotes.org" org-roam-directory)
         ; Use org-roam files as my reading notes.
         ;; org-ref-notes-directory org-roam-directory
         org-ref-notes-function 'orb-edit-notes
         ; Add templates for my reading notes.
         org-ref-note-title-format (concat
                                    "* TODO %y - %t\n"
                                    ":PROPERTIES:\n"
                                    ":Custom_ID: %k\n"
                                    ":NOTER_DOCUMENT: %F\n"
                                    ":ROAM_KEY: cite:%k\n"
                                    ":AUTHOR: %9a\n"
                                    ":JOURNAL: %j\n"
                                    ":YEAR: %y\n"
                                    ":VOLUME: %v\n"
                                    ":PAGES: %p\n"
                                    ":DOI: %D\n"
                                    ":URL: %U\n"
                                    ":END:\n\n"
                                    )
    ))

(use-package citeproc-org
  :config
  (citeproc-org-setup))

(require 'oc-biblatex)

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

(add-hook 'prog-mode-hook '(lambda ()
                             (setq truncate-lines t)))

(use-package flycheck
  :init (global-flycheck-mode)
  :custom
  (flycheck-display-errors-function #'flycheck-display-error-messages-unless-error-list)
  )

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

;; (use-package company-box
;;   :hook (company-mode . company-box-mode))

(use-package evil-nerd-commenter
  :bind ("C-/" . evilnc-comment-or-uncomment-lines))

(use-package format-all
  :hook
  ;; (prog-mode . format-all-mode) ;; format on save
  (format-all-mode . format-all-ensure-formatter))

(add-hook 'c++-mode-hook
          (lambda ()
            (set (make-local-variable 'compile-command)
                 (format
                  "clang++ -std=c++17 -g -I$HOME/include -o %s %s -DLOCAL_DEBUG "
                  (file-name-sans-extension buffer-file-name)
                  buffer-file-name
                  ))))

(defun bury-compile-buffer-if-successful (buffer string)
  "Bury a compilation buffer if succeeded without warnings "
  (if (and
       (string-match "compilation" (buffer-name buffer))
       (string-match "finished" string)
       (not
        (with-current-buffer buffer
          (goto-char (point-min))
          (search-forward "warning" nil t))))
      (run-with-timer 1 nil
                      (lambda (buf)
                        (bury-buffer buf)
                        (switch-to-prev-buffer (get-buffer-window buf) 'kill)
                        (delete-windows-on buf)
                        (message "compilation buffer buried")
                        )
                      buffer)
    (message "do not bury compilation buffer")))
(add-hook 'compilation-finish-functions 'bury-compile-buffer-if-successful)

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

(use-package docker
  :ensure t
  :bind ("C-c d" . docker))

(use-package dockerfile-mode
  :config
  (add-to-list 'auto-mode-alist '("Dockerfile\\'" . dockerfile-mode)))

(defun k4i/lsp-mode-setup ()
  (setq lsp-headerline-breadcrumb-segments '(path-up-to-project file symbols))
  (lsp-headerline-breadcrumb-mode))

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :custom
  ;; https://www.reddit.com/r/emacs/comments/eme5zk/lspmode_clangd_memory_consumption_problem/
  (lsp-clients-clangd-args '("--header-insertion-decorators=0" "--background-index=false" "--j=4"))
  :hook
  (lsp-mode . k4i/lsp-mode-setup)
  (c++-mode . lsp-deferred)
  (python-mode . lsp-deferred)
  (php-mode . lsp-deferred)
  (go-mode . lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l")  ;; Or 'C-l', 's-l'
  :config
  (lsp-enable-which-key-integration t))

(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode)
  :custom
  (lsp-ui-sideline-show-hover t)
  (lsp-ui-sideline-show-code-actions t)
  (lsp-ui-sideline-delay 0.1)
  (lsp-ui-doc-position 'top)
  (lsp-ui-doc-show-with-cursor t)
  (lsp-ui-doc-delay 0.1)
  (lsp-ui-peek-enable t)
  (lsp-ui-peek-show-directory t)
  (lsp-ui-imenu-auto-refresh t)
  )

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
  ;; dap-lldb can't get user input: https://github.com/emacs-lsp/dap-mode/issues/58
  (require 'dap-lldb)
  ;; native debug: https://marketplace.visualstudio.com/items?itemName=webfreak.debug
  ;; (require 'dap-gdb-lldb) ; then run dap-gdb-lldb-setup
  ;; (require 'dap-codelldb)
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

(use-package json-mode)

;; from: https://stackoverflow.com/a/3346308
;; function decides whether .h file is C or C++ header, sets C++ by
;; default because there's more chance of there being a .h without a
;; .cc than a .h without a .c (ie. for C++ template files)
(defun c-c++-header ()
  "sets either c-mode or c++-mode, whichever is appropriate for
header"
  (interactive)
  (let ((c-file (concat (substring (buffer-file-name) 0 -1) "c")))
    (if (file-exists-p c-file)
        (c-mode)
      (c++-mode))))
(add-to-list 'auto-mode-alist '("\\.h\\'" . c-c++-header))

(require 'cmake-mode)

(use-package python-mode
  :ensure t
  ;; :hook (python-mode . lsp-deferred)
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

;; (use-package lsp-python-ms
;;   :init (setq lsp-python-ms-auto-install-server t)
;;   :hook (python-mode . (lambda ()
;;                          (require 'lsp-python-ms)
;;                          (lsp-deferred))))  ; or lsp-deferred

(use-package slime
  :config
  (load (expand-file-name "~/quicklisp/slime-helper.el"))
  (setq inferior-lisp-program "sbcl")
  (slime-setup '(slime-fancy slime-company slime-cl-indent)))

(use-package slime-company
  :after (slime company)
  :config
  (setq slime-company-completion 'fuzzy
        slime-company-after-completion 'slime-company-just-one-space))

(use-package rust-mode
  :hook (rust-mode . lsp-deffered))

(use-package flycheck-rust
  :config
  (with-eval-after-load 'rust-mode
    (add-hook 'flycheck-mode-hook #'flycheck-rust-setup)))

(use-package cargo
  :hook (rust-mode . cargo-minor-mode)
  :diminish cargo-minor-mode)

(use-package go-mode
  :custom
  (gofmt-command "goimports")
  :hook
  (before-save . gofmt-before-save)
  )

(use-package company-go
  :init
  (with-eval-after-load 'company
    (add-to-list 'company-backends 'company-go)))

(use-package php-mode)

(use-package toml-mode
  :hook (toml-mode . lsp-deferred))

(use-package yaml-mode)

(use-package tex
  :ensure auctex
  :hook
  (LaTeX-mode . prettify-symbols-mode)
  :custom
  (TeX-engine 'xetex)
  )

(use-package cdlatex
  :hook ((LaTeX-mode  . turn-on-cdlatex)
         (org-mode    . turn-on-org-cdlatex)
         (cdlatex-tab . LaTeX-indent-line)))

(use-package graphviz-dot-mode
  :hook
  (graphviz-dot-mode . (lambda () (set-input-method 'TeX)))
  :mode "\\.dot\\'"
  :config
  (setq graphviz-dot-indent-width 4))

(use-package vterm
  :commands vterm
  :config
  (setq term-prompt-regexp "^[^#$%>❯\n]*[#$%>❯] *")  ;; Set this to match your custom shell prompt
  ;;(setq vterm-shell "zsh")                       ;; Set this to customize the shell to launch
  (setq vterm-max-scrollback 10000)
  (define-key vterm-mode-map [return]                      #'vterm-send-return)

  (setq vterm-keymap-exceptions nil)
  (evil-define-key 'insert vterm-mode-map (kbd "C-e")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-f")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-a")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-v")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-b")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-w")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-u")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-d")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-n")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-m")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-p")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-j")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-k")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-r")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-t")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-g")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-c")      #'vterm--self-insert)
  (evil-define-key 'insert vterm-mode-map (kbd "C-SPC")    #'vterm--self-insert)
  (evil-define-key 'normal vterm-mode-map (kbd "C-d")      #'vterm--self-insert)
  (evil-define-key 'normal vterm-mode-map (kbd ",c")       #'multi-vterm)
  (evil-define-key 'normal vterm-mode-map (kbd ",n")       #'multi-vterm-next)
  (evil-define-key 'normal vterm-mode-map (kbd ",p")       #'multi-vterm-prev)
  (evil-define-key 'normal vterm-mode-map (kbd "i")        #'evil-insert-resume)
  (evil-define-key 'normal vterm-mode-map (kbd "o")        #'evil-insert-resume)
  (evil-define-key 'normal vterm-mode-map (kbd "<return>") #'evil-insert-resume)
  )

(use-package vterm-toggle
  :custom
  (vterm-toggle-hide-method 'delete-window)
  :hook
  (vterm-toggle-show . evil-insert-state)
  :config
  (setq vterm-toggle-fullscreen-p nil)
  (defun vmacs-term-mode-p(&optional args)
    (derived-mode-p 'eshell-mode 'term-mode 'shell-mode 'vterm-mode))
  (setq vterm-toggle--vterm-buffer-p-function 'vmacs-term-mode-p)
  (add-to-list 'display-buffer-alist
               '((lambda (bufname _)
                   (with-current-buffer bufname (equal major-mode 'vterm-mode)))
                 ;; (display-buffer-reuse-window display-buffer-in-side-window)
                 (display-buffer-reuse-window display-buffer-in-direction)
                 ;;display-buffer-in-direction/direction/dedicated is added in emacs27
                 (direction . bottom)
                 ;; (dedicated . t) ;dedicated is supported in emacs27
                 (reusable-frames . visible)
                 (window-height . 0.3))))

(defun eshell-here ()
  "Opens up a new shell in the directory associated with the
    current buffer's file. The eshell is renamed to match that
    directory to make multiple eshell windows easier."
  (interactive)
  (let* ((parent (if (buffer-file-name)
                     (file-name-directory (buffer-file-name))
                   default-directory))
         (height (/ (window-total-height) 3))
         (name   (car (last (split-string parent "/" t)))))
    (split-window-vertically (- height))
    (other-window 1)
    (eshell "new")
    (rename-buffer (concat "*eshell: " name "*"))

    (insert (concat "ls"))
    (eshell-send-input)))

(global-set-key (kbd "C-!") 'eshell-here)

(defun eshell/x ()
  (insert "exit")
  (eshell-send-input)
  (delete-window))

(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :custom ((dired-listing-switches "-agho --group-directories-first"))
  :general
  (:states 'normal
   :keymaps 'dired-mode-map
   "c" '(nil :which-key "create")
   "cc" 'dired-do-compress-to
   "cf" 'dired-create-empty-file
   "cd" 'dired-create-directory
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

(use-package dired-ranger)

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

(use-package treemacs
  :custom
  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-width-is-initially-locked nil)
  ;; (treemacs-project-follow-mode t)
  )

(use-package treemacs-evil
  :after treemacs evil)

(use-package treemacs-projectile
  :after (treemacs projectile)
  :ensure t)

(use-package treemacs-magit
  :after (treemacs magit)
  :ensure t)

(use-package lsp-treemacs
  :after lsp)

(use-package tramp
  :ensure nil
  :defer t
  :config
  (setq tramp-default-user "root"
        tramp-default-method "ssh")
  (use-package counsel-tramp
    :bind ("C-c t" . counsel-tramp))
  (put 'temporary-file-directory 'standard-value '("/tmp")))

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
        socks-server '("Default server" "127.0.0.1" 1082 5))
  (setenv "all_proxy" "socks5://127.0.0.1:1082")
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
(setq my-http-proxy "127.0.0.1:8080")
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
