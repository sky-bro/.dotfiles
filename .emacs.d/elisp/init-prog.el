;;; init-prog.el --- Programming language support -*- lexical-binding: t -*-
;;; Commentary:
;; Programming language support and development tools

;;; Code:

;; BasicProgrammingSetup
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
;; -BasicProgrammingSetup

;; Flycheck
(use-package flycheck
  :init (global-flycheck-mode)
  :custom
  (flycheck-display-errors-function #'flycheck-display-error-messages-unless-error-list)
  )
;; -Flycheck

;; Company
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
  (company-tooltip-align-annotations t)
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
          (unless (memq (char-before (- (point) (length prefix))) '(?. ?> ?\\())
            prefix))
      (funcall fun command arg)))
  (advice-add #'company-yasnippet :around #'my-company-yasnippet-disable-inline)
  :diminish company-mode))
;; -Company

;; EvilNerdCommenter
(use-package evil-nerd-commenter
  :bind ("C-/" . evilnc-comment-or-uncomment-lines))
;; -EvilNerdCommenter

;; FormatAll
(use-package format-all
  :hook
  ;; (prog-mode . format-all-mode) ;; format on save
  (format-all-mode . format-all-ensure-formatter))
;; -FormatAll

;; CppMode
(add-hook 'c++-mode-hook
          (lambda ()
            (set (make-local-variable 'compile-command)
                 (format
                  "clang++ -std=c++17 -g -I$HOME/include -o %s %s -DLOCAL_DEBUG "
                  (file-name-sans-extension buffer-file-name)
                  buffer-file-name
                  ))))
;; -CppMode

;; CompilationBuffer
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
;; -CompilationBuffer

;; Projectile
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
;; -Projectile

;; CounselProjectile
(use-package counsel-projectile
  :after projectile
  :config (counsel-projectile-mode))
;; -CounselProjectile

;; Magit
(use-package magit
  :commands magit-status
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  ;; Performance optimizations for responsiveness
  (magit-refresh-verbose nil)
  ;; Cache expensive operations
  (magit-section-visibility-cache t)
  (magit-section-show-child-count t)
  ;; Limit number of commits shown initially to improve performance
  (magit-log-arguments '("--graph" "--decorate" "--color" "--pretty=format:%h %ad | %s%d [%an]" "--date=iso" "-n256"))
  ;; Reduce processing of hunk diffs by default
  (magit-diff-refine-hunk nil)
  ;; Slow down auto refresh to improve responsiveness
  (magit-auto-refresh-mode nil)  ; Disable auto-refresh, update manually when needed
  ;; Reduce refresh frequency of status buffer
  (magit-status-headers-hook nil)  ; Reduce processing in status headers
  :config
  (add-hook 'magit-mode-hook
            (lambda ()
              ;; Reduce processing in magit buffers
              (setq show-trailing-whitespace nil)
              ;; Disable some features in magit for better performance
              (when (bound-and-true-p global-hl-line-mode)
                (hl-line-mode -1))
              ;; Disable cursor blinking
              (setq blink-cursor-mode nil)
              ;; Reduce additional refresh triggers in magit mode
              (remove-hook 'post-command-hook 'magit-refresh-post-command t))))
;; -Magit

;; Forge
;; NOTE: Make sure to configure a GitHub token before using this package!
;; - https://magit.vc/manual/forge/Token-Creation.html#Token-Creation
;; - https://magit.vc/manual/ghub/Getting-Started.html#Getting-Started
(use-package forge
  :after magit)
;; -Forge

;; Docker
(use-package docker
  :bind ("C-c d" . docker))

(use-package dockerfile-mode
  :config
  (add-to-list 'auto-mode-alist '("Dockerfile\\'" . dockerfile-mode)))
;; -Docker

;; LspMode
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
  (python . lsp-deferred)
  (php-mode . lsp-deferred)
  (go-mode . lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l")  ;; Or 'C-l', 's-l'
  :config
  (lsp-enable-which-key-integration t))
;; -LspMode

;; LspUI
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
;; -LspUI

;; LspIvy
(use-package lsp-ivy
  :after lsp)
;; -LspIvy

;; DapMode
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
  (require 'dap-python)
  ;; (dap-node-setup) ;; Automatically installs Node debug adapter if needed

  ;; C/C++
  ;; lldb is a debugger that supports: C, C++, Objective-C, Swift
  ;; dap-lldb can't get user input: https://github.com/emacs-lsp/dap-mode/issues/58
  ;; (require 'dap-lldb)
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
;; -DapMode

;; Python debugging for DAP
;; (use-package dap-python
;;   :after (dap-mode python)
;;   :config
;;   (require 'dap-python))
;; -DapPython

;; TypeScriptMode
(use-package typescript-mode
  :mode "\\.ts\\'"
  :hook (typescript-mode . lsp-deferred)
  :config
  (setq typescript-indent-level 2))
;; -TypeScriptMode

;; JsonMode
(use-package json-mode)
;; -JsonMode

;; CHeaderMode
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
;; -CHeaderMode

;; CMakeMode
(use-package cmake-mode
  :mode ("CMakeLists.txt\\'" . cmake-mode)
  :straight t)
;; -CMakeMode

;; PythonMode
(use-package python
  :mode ("\\.py\\'" . python-mode)
  :hook (python-mode . lsp-deferred)
  :custom
  ;; NOTE: Set these if Python 3 is called "python3" on your system!
  ;; (python-shell-interpreter "python3")
  ;; (dap-python-executable "python3")
  (dap-python-debugger 'debugpy))
;; -PythonMode

;; Pyvenv
(use-package pyvenv
  :after python
  :config
  (pyvenv-mode 1))
;; -Pyvenv

;; Slime
;; (use-package slime
;;   :init
;;   (progn
;;     (require 'slime-autoloads)
;;     (add-hook 'slime-mode-hook
;;               (lambda ()
;;                 (unless (slime-connected-p)
;;                   (save-excursion (slime))))))
;;   :config
;;     (setq inferior-lisp-program "sbcl")
;;     (slime-setup '(slime-fancy slime-company slime-cl-indent)))
;; -Slime

;; SlimeCompany
;; (use-package slime-company
;;   :after (slime company)
;;   :config
;;   (setq slime-company-completion 'fuzzy
;;         slime-company-after-completion 'slime-company-just-one-space))
;; -SlimeCompany

;; RustMode
(use-package rust-mode
  :hook (rust-mode . lsp-deferred))
;; -RustMode

;; FlycheckRust
(use-package flycheck-rust
  :config
  (with-eval-after-load 'rust-mode
    (add-hook 'flycheck-mode-hook #'flycheck-rust-setup)))
;; -FlycheckRust

;; Cargo
(use-package cargo
  :hook (rust-mode . cargo-minor-mode)
  :diminish cargo-minor-mode)
;; -Cargo

;; GoMode
(use-package go-mode
  :custom
  (gofmt-command "goimports")
  :hook
  (before-save . gofmt-before-save)
  )
;; -GoMode

;; CompanyGo
(use-package company-go
  :init
  (with-eval-after-load 'company
    (add-to-list 'company-backends 'company-go)))
;; -CompanyGo

;; PhpMode
(use-package php-mode)
;; -PhpMode

;; TomlMode
(use-package toml-mode
  :straight t
  :hook (toml-mode . lsp-deferred))
;; -TomlMode

;; YamlMode
(use-package yaml-mode
  :straight t)
;; -YamlMode

;; TexMode
(use-package tex
  :straight auctex
  :hook
  (LaTeX-mode . prettify-symbols-mode)
  :custom
  (TeX-engine 'xetex)
  )
;; -TexMode

;; Cdlatex
(use-package cdlatex
  ;;:straight (:host github :repo "abo-abo/cdlatex")
  :hook ((LaTeX-mode  . turn-on-cdlatex)
         (org-mode    . turn-on-org-cdlatex)
         (cdlatex-tab . LaTeX-indent-line)))
;; -Cdlatex

;; GraphvizDotMode
(use-package graphviz-dot-mode
  :hook
  (graphviz-dot-mode . (lambda () (set-input-method 'TeX)))
  :mode "\\.dot\\'"
  :config
  (setq graphviz-dot-indent-width 4))
;; -GraphvizDotMode

(provide 'init-prog)
;;; init-prog.el ends here
