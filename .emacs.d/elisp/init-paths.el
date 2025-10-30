;;; init-paths.el --- Path and custom file configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Path configuration and custom file setup

;;; Code:

;; LoadPathConfiguration
;; add .emacs.d/lisp to load-path
(add-to-list 'load-path (locate-user-emacs-file "lisp"))
;; -LoadPathConfiguration

;; CustomFileSetup
(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))
;; -CustomFileSetup

;; ExecPathFromShell
(use-package exec-path-from-shell
  :config
  (dolist (var '("SSH_AUTH_SOCK"))
    (add-to-list 'exec-path-from-shell-variables var))
  (when (or (daemonp) (memq window-system '(mac ns x)))
    (exec-path-from-shell-initialize)))
;; -ExecPathFromShell

(provide 'init-paths)
;;; init-paths.el ends here