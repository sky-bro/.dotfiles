;;; init-utils.el --- Utility functions -*- lexical-binding: t -*-
;;; Commentary:
;; Utility functions and miscellaneous configurations

;;; Code:

;; NoLittering
(use-package no-littering
  :demand t
  :config
  ;; This code runs ONLY after no-littering is loaded
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t))))
;; -NoLittering

;; WindowManagement
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
                     window))
               (quit-restore ('window 'window nil nil)))))

;; output buffer
(add-to-list 'display-buffer-alist
             `(,(lambda (buf act)
                  (when-let ((filename (with-current-buffer buf buffer-file-name)))
                    (string-equal "out.txt" (file-name-nondirectory filename))))
               (,(lambda (buf act)
                   (when-let ((window (window-with-parameter 'for-output-window)))
                     (with-current-buffer buf (auto-revert-mode))
                     (set-window-buffer window buf)
                     window))
               (quit-restore ('window 'window nil nil)))))
;; -WindowManagement

;; Eyebrowse
(use-package eyebrowse
  :straight (eyebrowse :type git :host github :repo "wasamasa/eyebrowse")
  :config
  (eyebrowse-mode t))
;; -Eyebrowse

;; Burly
(use-package burly
  :config
  (push (cons 'for-input-window 'writable) burly-window-persistent-parameters)
  (push (cons 'for-output-window 'writable) burly-window-persistent-parameters)
  )
;; -Burly

;; Yasnippet
(use-package yasnippet
  :hook ((prog-mode conf-mode text-mode snippet-mode) . yas-minor-mode)
  :config
  (yas-reload-all))

(use-package yasnippet-snippets
  :after (yasnippet))
;; -Yasnippet

;; UndoFu
(use-package undo-fu)
;; -UndoFu

;; ClaudeCodeIDE
;; (use-package claude-code-ide
;;   :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
;;   :bind ("C-c C-'" . claude-code-ide-menu) ; Set your favorite keybinding
;;   :config
;;   (claude-code-ide-emacs-tools-setup)) ; Optionally enable Emacs MCP tools
;; -ClaudeCodeIDE

;; IvySwitchTab
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
;; -IvySwitchTab

;; OrgRoamRebuildHelper
(defun k4i/rebuild-org-roam-packages ()
  "Helper function to clear org-roam related compilation caches."
  (interactive)
  (when (y-or-n-p "This will clear org-roam and org-roam-ui compiled caches. Are you sure? ")
    (let ((build-dir (expand-file-name "straight/build" user-emacs-directory)))
      ;; Clear compiled files
      (when (file-directory-p (expand-file-name "org-roam" build-dir))
        (shell-command (format "rm -f %s/org-roam/*.elc" build-dir)))
      (when (file-directory-p (expand-file-name "org-roam-ui" build-dir))
        (shell-command (format "rm -f %s/org-roam-ui/*.elc" build-dir)))
      (let ((eln-cache-dir (expand-file-name "eln-cache" user-emacs-directory)))
        (when (file-directory-p eln-cache-dir)
          (shell-command (format "find %s -name '*org-roam*' -delete" eln-cache-dir))))
      (message "Org-roam compilation caches cleared. You may need to restart Emacs."))))

;; -OrgRoamRebuildHelper

(provide 'init-utils)
;;; init-utils.el ends here
