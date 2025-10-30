;;; init-keybindings.el --- Keybindings configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Custom keybindings and general configuration

;;; Code:

;; GeneralSetup
(use-package general
  :after evil
  :config
  (general-create-definer my-space-leader
    :keymaps '(normal visual)
    :prefix "SPC")

  (my-space-leader
    "d" '((lambda () (interactive) (dired default-directory)) :which-key "dired default dir")
    "f"  '(:ignore t :which-key "file")
    "fb"  '((lambda () (interactive) (find-file (expand-file-name "~/git-repo/blog/blog-src/content-org/all-posts.en.org"))) :which-key "blogs")
    "fd" '(:ignore t :which-key "dotfiles")
    "fde" '((lambda () (interactive) (find-file (expand-file-name "~/.dotfiles/.emacs.d/README.org"))) :which-key "emacs")
    "fdw" '((lambda () (interactive) (find-file (expand-file-name "~/.dotfiles/.config/i3/config"))) :which-key "window manager")
    "k" 'kill-this-buffer
    "o"  '(:ignore t :which-key "org")
    "oa" 'org-agenda
    "oc" 'org-capture
    "r" 'resize-window
    "t"  '(:ignore t :which-key "toggles")
    "tt" '(counsel-load-theme :which-key "choose theme")
    "tf" 'treemacs
    "ts" 'flyspell-toggle
    "'" 'vterm-toggle-cd
    "=" 'format-all-buffer)

  (general-create-definer my-comma-leader
    :keymaps '(normal visual)
    :prefix ",")

  (my-comma-leader
    "k"  'kill-this-buffer))
;; -GeneralSetup

;; WhichKey
(use-package which-key
  :init
  (which-key-mode)
  :diminish which-key-mode
  :custom
  (which-key-idle-delay 0.3)
  :diminish which-key-mode)
;; -WhichKey

;; HelpfulSetup
(use-package helpful
  :commands (helpful-callable helpful-variable helpful-command helpful-key)
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key)
  :config
  ;; (add-to-list 'display-buffer-alist
  ;;              `("\\*help"
  ;;                (display-buffer-reuse-window display-buffer-in-side-window)
  ;;                (reusable-frames . visible)
  ;;                (side . right)
  ;;                (window-width . 0.3)
  ;;                 ))
  )
;; -HelpfulSetup

;; ResizeWindowFunction
(defvar enlarge-window-height-char ?k)
(defvar shrink-window-height-char ?j)
(defvar enlarge-window-width-char ?l)
(defvar shrink-window-width-char ?h)
(defun resize-window (&optional arg)
   "Interactively resize the selected window.
Repeatedly prompt whether to enlarge or shrink the window until the
response is neither `enlarge-window-char' or `shrink-window-char'.
When called with a prefix arg, resize the window by ARG lines."
   (interactive "p")
   ;; by default arg is 1, too slow to resize
   (setq arg 3)
   (let ((prompt (format "Enlarge/Shrink window (%c/%c/%c/%c)? "
                         enlarge-window-height-char shrink-window-height-char
                         enlarge-window-width-char shrink-window-width-char))
        response)
     (while (progn
             (setq response (read-event prompt))
             (cond ((equal response enlarge-window-height-char)
                    (enlarge-window arg)
                    t)
                   ((equal response shrink-window-height-char)
                    (enlarge-window (- arg))
                    t)
                   ((equal response enlarge-window-width-char)
                    (enlarge-window-horizontally arg)
                    t)
                   ((equal response shrink-window-width-char)
                    (enlarge-window-horizontally (- arg))
                    t)
                   (t nil))))
     (push response unread-command-events)))
;; -ResizeWindowFunction

;; GlobalKeybindings
(global-set-key (kbd "C-x C-b") 'ibuffer)

;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)
;; -GlobalKeybindings

(provide 'init-keybindings)
;;; init-keybindings.el ends here