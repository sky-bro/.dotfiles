;;; init-completion.el --- Completion and search configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Ivy, counsel, and related completion frameworks

;;; Code:

;; IvySetup
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
;; -IvySetup

;; IvyRich
(use-package ivy-rich
  :after ivy
  :config
  (ivy-rich-mode 1))
;; -IvyRich

;; IvyPrescient
;; ivy will show recently selected candidates first
(use-package ivy-prescient
  :after counsel
  :custom
  (ivy-prescient-enable-filtering nil)
  :config
  ;; Uncomment the following line to have sorting remembered across sessions!
  ;; (prescient-persist-mode 1)
  (ivy-prescient-mode 1))
;; -IvyPrescient

;; CounselSetup
(use-package counsel
  :bind (:map minibuffer-local-map
              ("C-r" . 'counsel-minibuffer-history))
  :custom
  (counsel-linux-app-format-function #'counsel-linux-app-format-function-name-only)
  :config
  (counsel-mode 1))
;; -CounselSetup

;; IvyPosframe
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
;; -IvyPosframe

;; Wgrep
(use-package wgrep)
;; -Wgrep

(provide 'init-completion)
;;; init-completion.el ends here