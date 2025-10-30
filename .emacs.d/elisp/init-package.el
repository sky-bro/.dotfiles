;;; init-package.el --- Package management configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Package management setup using package.el and use-package

;;; Code:

;; PackageRepositorySetup
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
;; -PackageRepositorySetup

;; PackageInitialization
(unless package-archive-contents
  (package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
;; -PackageInitialization

;; UsePackageConfiguration
(require 'use-package)
(setq use-package-always-ensure t)

(use-package async
  :config (setq async-bytecomp-package-mode 1))
;; -UsePackageConfiguration

(provide 'init-package)
;;; init-package.el ends here