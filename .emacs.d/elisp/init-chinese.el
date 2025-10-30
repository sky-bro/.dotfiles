;;; init-chinese.el --- Chinese input method configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Chinese input method and related configurations

;;; Code:

;; PyimSetup
(use-package pyim-basedict)

(use-package pyim
  :after pyim-basedict
  :custom
  (pyim-page-length 9)
  :config
  (pyim-basedict-enable)
  (setq default-input-method "pyim")
  ;; use v to toggle previous punctuation
  (setq-default pyim-punctuation-translate-p '(no yes auto)))
;; -PyimSetup

;; WordSavingFunction
(defun k4i/save-word-to-dict ()
  (interactive)
  (let ((current-location (point))
        (word (flyspell-get-word)))
    (when (and (consp word) (yes-or-no-p (format "save word %S?" (car word))))
      (flyspell-do-correct 'save nil (car word) current-location (cadr word) (caddr word) current-location)
      (message "saved %S to dict" (car word))
      )
    )
  )
;; -WordSavingFunction

;; FlyspellConfiguration
(defun flyspell-on-for-buffer-type ()
  "Enable Flyspell appropriately for the major mode of the current buffer.  Uses `flyspell-prog-mode' for modes derived from `prog-mode', so only strings and comments get checked.  All other buffers get `flyspell-mode' to check all text.  If flyspell is already enabled, does nothing."
  (interactive)
  (if (not (symbol-value flyspell-mode)) ; if not already on
      (progn
        (if (derived-mode-p 'prog-mode)
            (progn
              (message "Flyspell on (code)")
              (flyspell-prog-mode))
          ;; else
          (progn
            (message "Flyspell on (text)")
            (flyspell-mode 1)))
        ;; I tried putting (flyspell-buffer) here but it didn't seem to work
        )))

(defun flyspell-toggle ()
  "Turn Flyspell on if it is off, or off if it is on.  When turning on, it uses `flyspell-on-for-buffer-type' so code-vs-text is handled appropriately."
  (interactive)
  (if (symbol-value flyspell-mode)
      (progn ; flyspell is on, turn it off
        (message "Flyspell off")
        (flyspell-mode -1))
    ;; else - flyspell is off, turn it on
    (flyspell-on-for-buffer-type)))

(use-package flyspell
  :custom
  (flyspell-issue-message-flag nil)
  :bind
  ("C-M-S-i" . k4i/save-word-to-dict)
  :hook
  ((find-file . flyspell-on-for-buffer-type)
  (after-change-major-mode . flyspell-on-for-buffer-type)))
;; -FlyspellConfiguration

(provide 'init-chinese)
;;; init-chinese.el ends here