;;; init.el --- Main configuration file -*- lexical-binding: t -*-
;;; Commentary:
;; Main Emacs configuration file that loads modular configuration files

;;; Code:

;; CheckVer
(cond ((version< emacs-version "26.1")
       (warn "M-EMACS requires Emacs 26.1 and above!"))
      ((let* ((early-init-f (expand-file-name "early-init.el" user-emacs-directory))
              (early-init-do-not-edit-d (expand-file-name "early-init-do-not-edit/" user-emacs-directory))
              (early-init-do-not-edit-f (expand-file-name "early-init.el" early-init-do-not-edit-d)))
         (and (version< emacs-version "27")
              (or (not (file-exists-p early-init-do-not-edit-f))
                  (file-newer-than-file-p early-init-f early-init-do-not-edit-f)))
         (make-directory early-init-do-not-edit-d t)
         (copy-file early-init-f early-init-do-not-edit-f t t t t)
         (add-to-list 'load-path early-init-do-not-edit-d)
         (require 'early-init))))
;; -CheckVer

;; LoadPath
(defun update-to-load-path (folder)
  "Update FOLDER and its subdirectories to `load-path'."
  (let ((base folder))
    (unless (member base load-path)
      (add-to-list 'load-path base))
    (dolist (f (directory-files base))
      (let ((name (concat base "/" f)))
        (when (and (file-directory-p name)
                   (not (equal f ".."))
                   (not (equal f ".")))
          (unless (member base load-path)
            (add-to-list 'load-path name)))))))

(update-to-load-path (expand-file-name "elisp" user-emacs-directory))
;; -LoadPath

;; Performance optimizations
(require 'init-performance)

;; Server configuration
(require 'init-server)

;; Package management
(require 'init-package)

;; Path and custom file configuration
(require 'init-paths)

;; Chinese input method
(require 'init-chinese)

;; Completion and search
(require 'init-completion)

;; UI configuration
(require 'init-ui)

;; Evil mode
(require 'init-evil)

;; Keybindings
(require 'init-keybindings)

;; Org mode
(require 'init-org)

;; Programming support
(require 'init-prog)

;; Shell and terminal
(require 'init-shell)

;; Utilities
(require 'init-utils)

(provide 'init)
;;; init.el ends here
