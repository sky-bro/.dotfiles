;;; init-performance.el --- Performance and startup configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Performance optimizations and startup configuration

;;; Code:

;; Performance optimizations
;;;; Garbage Collection
;; Increase GC threshold during startup for better performance
;; (let ((normal-gc-cons-threshold (* 20 1024 1024))
      ;; (init-gc-cons-threshold (* 128 1024 1024)))
  ;; (setq gc-cons-threshold init-gc-cons-threshold)
  ;; (add-hook 'emacs-startup-hook
            ;; `(lambda () (setq gc-cons-threshold ,normal-gc-cons-threshold))))

;; BetterGC
(defvar better-gc-cons-threshold 134217728 ; 128mb
  "The default value to use for `gc-cons-threshold'.

If you experience freezing, decrease this.  If you experience stuttering, increase this.")

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold better-gc-cons-threshold)
            (setq file-name-handler-alist file-name-handler-alist-original)
            (makunbound 'file-name-handler-alist-original)))
;; -BetterGC

;; AutoGC
(add-hook 'emacs-startup-hook
          (lambda ()
            (if (boundp 'after-focus-change-function)
                (add-function :after after-focus-change-function
                              (lambda ()
                                (unless (frame-focus-state)
                                  (garbage-collect))))
              (add-hook 'after-focus-change-function 'garbage-collect))
            (defun gc-minibuffer-setup-hook ()
              (setq gc-cons-threshold (* better-gc-cons-threshold 2)))

            (defun gc-minibuffer-exit-hook ()
              (garbage-collect)
              (setq gc-cons-threshold better-gc-cons-threshold))

            (add-hook 'minibuffer-setup-hook #'gc-minibuffer-setup-hook)
            (add-hook 'minibuffer-exit-hook #'gc-minibuffer-exit-hook)))
;; -AutoGC

;;;; Startup Time Display
;; Function to display startup time
(defun k4i/display-startup-time ()
  (message "init completed in %.2f seconds with %d garbage collections."
           (float-time (time-subtract after-init-time before-init-time))
           gcs-done))

(add-hook 'after-init-hook #'k4i/display-startup-time)

;; Produce backtraces when errors occur: can be helpful to diagnose startup issues
;; you can turn it on and off with toggle-debug-on-error
;; (setq debug-on-error t)

;;;; Security
;; Disable risky local variable warnings
(advice-add 'risky-local-variable-p :override #'ignore)

(provide 'init-performance)
;;; init-performance.el ends here
