;;; init-shell.el --- Terminal and shell configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Terminal, shell, and related configurations

;;; Code:

;; Vterm
(use-package vterm
  :commands vterm
  :config
  (setq term-prompt-regexp "^[^#$%>❯\n]*[#$%>❯] *")  ;; Set this to match your custom shell prompt
  ;;(setq vterm-shell "zsh")                       ;; Set this to customize the shell to launch
  (setq vterm-max-scrollback 10000)
  (define-key vterm-mode-map [return]                      #'vterm-send-return)

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
;; -Vterm

;; VtermToggle
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
;; -VtermToggle

;; Eshell
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
;; -Eshell

;; Dired
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
   ;; "h" 'dired-single-up-directory
   ;; "l" 'dired-single-buffer
   ))
;; -Dired

;; DiredIcons
;; use all-the-icons icon in dired
(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode))
;; -DiredIcons

;; DiredSubtree
(use-package dired-subtree
  :after dired
  :bind (:map dired-mode-map
              ("<tab>" . dired-subtree-toggle)
              ("<C-tab>" . dired-subtree-cycle)
              ("<S-iso-lefttab>" . dired-subtree-remove)))
;; -DiredSubtree

;; DiredRanger
(use-package dired-ranger)
;; -DiredRanger

;; DiredOpen
(use-package dired-open
  :commands (dired dired-jump)
  :general
  ("C-c o" 'dired-open-xdg)
  :config
  ;; by default <Enter> does not use dired-open-xdg
  ;; (add-to-list 'dired-open-functions #'dired-open-xdg t)
  (setq dired-open-extensions '(("png" . "feh")
                                ("mkv" . "mpv"))))
;; -DiredOpen

;; DiredHideDotfiles
(use-package dired-hide-dotfiles
  ;; :hook (dired-mode . dired-hide-dotfiles-mode)
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "H" 'dired-hide-dotfiles-mode))
;; -DiredHideDotfiles

;; Treemacs
(use-package treemacs
  :custom
  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-width-is-initially-locked nil)
  ;; (treemacs-project-follow-mode t)
  )
;; -Treemacs

;; TreemacsEvil
(use-package treemacs-evil
  :after treemacs evil)
;; -TreemacsEvil

;; TreemacsProjectile
(use-package treemacs-projectile
  :after (treemacs projectile)
  :ensure t)
;; -TreemacsProjectile

;; TreemacsMagit
(use-package treemacs-magit
  :after (treemacs magit)
  :ensure t)
;; -TreemacsMagit

;; TreemacsLsp
(use-package lsp-treemacs
  :after lsp)
;; -TreemacsLsp

;; Tramp
(use-package tramp
  :ensure nil
  :defer t
  :config
  (setq tramp-default-user "root"
        tramp-default-method "ssh")
  (use-package counsel-tramp
    :bind ("C-c t" . counsel-tramp))
  (put 'temporary-file-directory 'standard-value '("/tmp")))
;; -Tramp

;; ProxySocks
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
;; -ProxySocks

;; ProxyHttp
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
;; -ProxyHttp

(provide 'init-shell)
;;; init-shell.el ends here