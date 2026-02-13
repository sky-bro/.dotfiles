;;; init-ui.el --- UI configuration -*- lexical-binding: t -*-
;;; Commentary:
;; User interface configuration including fonts, themes, and visual elements

;;; Code:

;; BasicUIConfiguration
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
;; -BasicUIConfiguration

;; ScratchBufferMessage
(setq initial-scratch-message
      ";; Hello Hackers! Welcome to emacs!\n\n(setq debug-on-error t)\n\n;; proxys\n(proxy-socks-toggle)\n(proxy-http-toggle)\n\n(package-refresh-contents)")
;; -ScratchBufferMessage

;; DefaultValues
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
;; -DefaultValues

;; DashboardConfiguration
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
;; -DashboardConfiguration

;; BeaconConfiguration
(use-package beacon
  :custom
  (beacon-lighter "")
  (beacon-size 30)
  :config
  (beacon-mode 1))
;; -BeaconConfiguration

;; MouseConfiguration
;; (setq x-pointer-shape x-pointer-top-left-arrow)
(setq x-pointer-shape x-pointer-pencil)
;; (setq x-pointer-sizing 240)
;; (setq x-sensitive-text-pointer-shape x-pointer-X-cursor)
;; (set-mouse-color "green")

(mouse-avoidance-mode 'banish)
;; -MouseConfiguration

;; WhitespaceConfiguration
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
    (set-face-attribute 'whitespace-space nil :background 'unspecified :foreground foreground-color)
    (set-face-attribute 'whitespace-tab nil :background 'unspecified :foreground foreground-color)
    (set-face-attribute 'whitespace-newline nil :background 'unspecified :foreground foreground-color)
    )
  (setq whitespace-display-mappings
        ;; all numbers are Unicode codepoint in decimal. try (insert-char 8617) to see it
        '((space-mark 32 [183] [46]) ; 32 SPACE, 183 MIDDLE DOT 「·」, 46 FULL STOP 「.」
          (newline-mark 10 [8617 10]) ; 10 LINE FEED↩
          (tab-mark 9 [9655 9] [92 9]) ; 9 TAB, 9655 WHITE RIGHT-POINTING TRIANGLE 「▷」
          ))
  )
;; -WhitespaceConfiguration

;; ElectricConfiguration
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
;; -ElectricConfiguration

;; RainbowDelimiters
(use-package rainbow-delimiters
  :hook
  (prog-mode . rainbow-delimiters-mode))
;; -RainbowDelimiters

;; ParenMode
(add-hook 'after-init-hook 'show-paren-mode)
;; -ParenMode

;; ElectricPairMode
(use-package elec-pair
  :hook
  (after-init . electric-pair-mode))
;; -ElectricPairMode

;; RainbowMode
(use-package rainbow-mode
  :hook
  (css-mode . rainbow-mode)
  :delight)
;; -RainbowMode

;; ThemeConfiguration
(use-package doom-themes
  :config
  (load-theme 'doom-gruvbox-light t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))
;; -ThemeConfiguration

;; ModelineConfiguration
(use-package doom-modeline
  :custom
  (doom-modeline-height 15)
  :hook
  (after-init . doom-modeline-mode))
;; -ModelineConfiguration

;; CommandLogMode
(use-package command-log-mode
  :commands command-log-mode)
;; -CommandLogMode

;; CentaurTabs
(use-package centaur-tabs
  :hook emacs-startup
  :custom
  (centaur-tabs-background-color "#f2e5bc")
  (centaur-tabs-style "chamfer")
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
;; -CentaurTabs

(provide 'init-ui)
;;; init-ui.el ends here