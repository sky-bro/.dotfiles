;;; init-package.el --- Package management configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Package management setup using straight.el and use-package

;;; Code:

;; PackageRepositorySetup
(when (>= emacs-major-version 24)
  (progn
    ;; Configure package archives for straight.el to use
    (let (;; tsinghua
          ;; (archives '(\"http://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/\"
          ;;             \"http://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/\"
          ;;             \"http://mirrors.tuna.tsinghua.edu.cn/elpa/nongnu/\"))
          ;; ustc
          (archives '(\"https://mirrors.ustc.edu.cn/elpa/melpa/\"
                      \"https://mirrors.ustc.edu.cn/elpa/gnu/\"
                      \"https://mirrors.ustc.edu.cn/elpa/nongnu/\"))
          ;; official
          ;; (archives '(\"https://melpa.org/packages/\"
          ;;             \"https://elpa.gnu.org/packages/\"
          ;;             \"http://elpa.nongnu.org/nongnu\"))
          )
      (setq package-archives `((\"melpa\" . ,(nth 0 archives))
                               (\"gnu\" . ,(nth 1 archives))
                               (\"nongnu\" . ,(nth 2 archives)))))
    ;; Package.el is not being loaded since we're using straight.el exclusively
    )

  ;; does not eagerly load installed packages, just add their directories to `load-path` and evaluate their `autoloads`
  ;; (when (< emacs-major-version 27) (package-initialize))
  ;; (package-initialize) ;; use straight.el, remove this
  )

;; -PackageRepositorySetup

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; PackageInitialization
;; (unless package-archive-contents
;;   (package-refresh-contents))

;; Initialize use-package - now done via straight.el below
;; -PackageInitialization

;; UsePackageConfiguration
;; Bootstrap straight.el first
(straight-use-package 'org)
(straight-use-package 'use-package)

(setq straight-use-package-by-default t)
;; (setq use-package-always-ensure t)

(require 'use-package)

(use-package async
  :config (setq async-bytecomp-package-mode 1))
;; -UsePackageConfiguration

(provide 'init-package)
;;; init-package.el ends here
