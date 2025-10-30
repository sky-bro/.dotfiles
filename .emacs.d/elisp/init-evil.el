;;; init-evil.el --- Evil mode configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Evil mode and related configurations

;;; Code:

;; EvilModeSetup
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
;; -EvilModeSetup

;; EvilCollection
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))
;; -EvilCollection

(provide 'init-evil)
;;; init-evil.el ends here