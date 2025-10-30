;;; init-org.el --- Org mode configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Org mode and related configurations

;;; Code:

;; OrgFontSetup
(defun k4i/org-font-setup ()
  ;; Set faces for heading levels
  (dolist (face '((org-level-1 . 1.2)
                  (org-level-2 . 1.1)
                  (org-level-3 . 1.05)
                  (org-level-4 . 1.0)
                  (org-level-5 . 1.1)
                  (org-level-6 . 1.1)
                  (org-level-7 . 1.1)
                  (org-level-8 . 1.1)))
    (set-face-attribute (car face) nil :font "DejaVu Sans Mono" :weight 'bold :height (cdr face)))

  ;; Ensure that anything that should be fixed-pitch in Org files appears that way
  (set-face-attribute 'org-block nil    :foreground nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table nil    :inherit 'fixed-pitch)
  (set-face-attribute 'org-formula nil  :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil     :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-table nil    :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox nil  :inherit 'fixed-pitch)
  ;; (set-face-attribute 'line-number nil :inherit 'fixed-pitch)
  ;; (set-face-attribute 'line-number-current-line nil :inherit 'fixed-pitch)
  )
;; -OrgFontSetup

;; ToggleFunctions
(defun toggle-func-of-hook (hook func)
  "add or remove func from hook"
  (if (member #'org-export-to-pdf-on-save (symbol-value hook))
      (progn
        (remove-hook hook func)
        (message "func %s disabled in hook %s" (symbol-name func) (symbol-name hook))
        )
    (progn
      (add-hook hook func)
      (message "func %s enabled in hook %s" (symbol-name func) (symbol-name hook))
      )
    )
  )

(defun toggle-org-export-to-pdf-on-save ()
  "Export current Org file to PDF."
  (interactive)
  (defun org-export-to-pdf-on-save ()
    (when (eq major-mode 'org-mode)
      (let* ((org-file (buffer-file-name))
             (pdf-file (concat (file-name-sans-extension org-file) ".pdf")))
        (message "start exporting to pdf")
        (org-latex-export-to-pdf t nil nil nil)
        )
      )
    )
  (toggle-func-of-hook 'after-save-hook 'org-export-to-pdf-on-save)
  )
;; -ToggleFunctions

;; OrgModeSetup
(defun k4i/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (visual-line-mode 1)
  (setq-local electric-pair-inhibit-predicate `(lambda (c) (if (char-equal c ?<) t (,electric-pair-inhibit-predicate c)))))

(use-package org
  :pin org
  :commands (org-capture org-agenda)
  :hook (org-mode . k4i/org-mode-setup)
  :custom
  (org-pretty-entities t)
  (org-image-actual-width 900
                          ;; (/ (nth 3 (assq 'geometry (frame-monitor-attributes))) 3)
                          )
  (org-startup-folded t)
  (org-directory (expand-file-name "Org" (getenv "HOME")))
  ;; (org-ellipsis " ▾")
  (org-ellipsis "⇙")
  (org-agenda-start-with-log-mode t)
  ;; (org-hide-emphasis-markers t)
  (org-log-done 'time)
  (org-log-into-drawer t)
  ;; org-directory/GTD
  (org-agenda-files (list (expand-file-name "GTD" org-directory)))
  ;; tags: C-c C-q
  (org-tag-alist
   '((:startgroup)
     ("@notes" . ?n)
     ("@workspace_setup" . ?w)
     ("@Data_Structure_and_Algorithm" . ?d)
     (:endgroup)
     ("idea" . ?i)))
  :config
  ;; latex preview with =C-c C-x C-l=, increase font size.
  (setq org-format-latex-options (plist-put org-format-latex-options :scale 2.0))
  (font-lock-add-keywords 'org-mode
                          '(("^ *\\([-]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

  ;; https://stackoverflow.com/questions/1218238/how-to-make-part-of-a-word-bold-in-org-mode
  ;; (setcar org-emphasis-regexp-components " \t('\"{[:alpha:]")
  ;; (setcar (nthcdr 1 org-emphasis-regexp-components) "[:alpha:]- \t.,:!?;'\"}\\\\")
  ;; (org-set-emph-re 'org-emphasis-regexp-components org-emphasis-regexp-components)

  ;; ;;
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d!)" "CANCELED(c)")
          (sequence "BACKLOG(b)" "PLAN(p)" "READY(r)" "ACTIVE(a)" "REVIEW(v)" "WAIT(w@/!)" "HOLD(h)" "|" "COMPLETED(c)" "CANC(k@)")))

  (setq org-refile-targets
        '((( "Archive.org" :maxlevel . 1)
          ( "Tasks.org" :maxlevel . 1))))

  ;; Save Org buffers after refiling!
  (advice-add 'org-refile :after 'org-save-all-org-buffers)
  (k4i/org-font-setup))
;; -OrgModeSetup

;; OrgBullets
(use-package org-bullets
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")))
;; -OrgBullets

;; VisualFillColumn
(defun k4i/org-mode-visual-fill ()
  (setq visual-fill-column-width 100
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(use-package visual-fill-column
  :hook (org-mode . k4i/org-mode-visual-fill)
  :config
  (advice-add 'text-scale-adjust :after #'visual-fill-column-adjust))
;; -VisualFillColumn

;; OrgKeybindings
(general-evil-define-key '(normal visual insert) org-mode-map
  "M-h" 'org-metaleft
  "M-H" 'org-shiftmetaleft
  "M-l" 'org-metaright
  "M-L" 'org-shiftmetaright
  "M-j" 'org-metadown
  "M-J" 'org-shiftmetadown
  "M-k" 'org-metaup
  "M-K" 'org-shiftmetaup)
;; -OrgKeybindings

;; OrgAgendaCustomCommands
;; Configure custom agenda views
(with-eval-after-load 'org-agenda
  (setq org-agenda-custom-commands
        '(("d" "Dashboard"
           ((agenda "" ((org-deadline-warning-days 14)))
            (todo "NEXT"
                  ((org-agenda-overriding-header "Next Tasks")))
            (tags-todo "agenda/ACTIVE" ((org-agenda-overriding-header "Active Projects")))))

          ("n" "Next Tasks"
           ((todo "NEXT"
                  ((org-agenda-overriding-header "Next Tasks")))))

          ("w" "Workflow Status"
           ((todo "WAIT"
                  ((org-agenda-overriding-header "Waiting on External")
                   (org-agenda-files org-agenda-files)))
            (todo "REVIEW"
                  ((org-agenda-overriding-header "In Review")
                   (org-agenda-files org-agenda-files)))
            (todo "PLAN"
                  ((org-agenda-overriding-header "In Planning")
                   (org-agenda-todo-list-sublevels nil)
                   (org-agenda-files org-agenda-files)))
            (todo "BACKLOG"
                  ((org-agenda-overriding-header "Project Backlog")
                   (org-agenda-todo-list-sublevels nil)
                   (org-agenda-files org-agenda-files)))
            (todo "READY"
                  ((org-agenda-overriding-header "Ready for Work")
                   (org-agenda-files org-agenda-files)))
            (todo "ACTIVE"
                  ((org-agenda-overriding-header "Active Projects")
                   (org-agenda-files org-agenda-files)))
            (todo "COMPLETED"
                  ((org-agenda-overriding-header "Completed Projects")
                   (org-agenda-files org-agenda-files)))
            (todo "CANC"
                  ((org-agenda-overriding-header "Cancelled Projects")
                   (org-agenda-files org-agenda-files))))))))
;; -OrgAgendaCustomCommands

;; OrgHabit
(with-eval-after-load 'org
  (require 'org-habit)
  (add-to-list 'org-modules 'org-habit)
  (setq org-habit-graph-column 60))
;; -OrgHabit

;; OrgDownload
(use-package org-download
  :after org
  :hook ((org-mode dired-mode) . org-download-enable)
  :custom
  (org-download-image-dir "images")
  (org-download-method 'directory)
  (org-download-heading-lvl nil)
  ;; (org-download-timestamp "%Y%m%d-%H%M%S_")
  (org-download-timestamp "")
  :bind
  ("C-M-y" .
   (lambda (&optional noask)
     (interactive "P")
     (let ((file
            (if (not noask)
                (read-string (format "Filename [%s]: " org-download-screenshot-basename)
                             nil nil org-download-screenshot-basename)
              nil)))
       (org-download-clipboard file))))
  :config
  (setq org-download-annotate-function #'(lambda (_link) ""))
  ;; second half of image directory from org header when org-download-heading is not nil
  (advice-add 'org-download--dir-2 :filter-return #'(lambda (dirname)
                                                      (when dirname (org-hugo-slug dirname)))))
;; -OrgDownload

;; PlantumlMode
(use-package plantuml-mode
  ;; :mode "\\.plu\\'"
  :init
  :custom
  (org-plantuml-jar-path (expand-file-name "~/app/plantuml/plantuml.jar"))
  (plantuml-jar-path (expand-file-name "~/app/plantuml/plantuml.jar"))
  ;; jar, executable, server (experimental)
  (plantuml-default-exec-mode 'jar)
  :config
  ;; https://plantuml.com/en/smetana02
  ;; use smetana insteand of graphviz
  (append plantuml-jar-args '("-Playout=smetana"))
  ;; (add-to-list 'org-src-lang-modes '("plantuml" . plantuml))
  )
;; -PlantumlMode

;; OrgReveal
(use-package ox-reveal
  :after ox
  :custom
  ;; or use a online revealjs
  ;; #+REVEAL_ROOT: https://cdn.jsdelivr.net/npm/reveal.js
  (org-reveal-root (concat "file://" (expand-file-name "~/app/revealjs/reveal.js-master/"))))
;; -OrgReveal

;; OrgHugo
(use-package ox-hugo
  :after ox)
;; -OrgHugo

;; OrgLatexExport
(with-eval-after-load 'ox-latex
  ;; http://orgmode.org/worg/org-faq.html#using-xelatex-for-pdf-export
  ;; latexmk runs pdflatex/xelatex (whatever is specified) multiple times
  ;; automatically to resolve the cross-references.
  (setq org-latex-pdf-process '("latexmk -xelatex -quiet -shell-escape -f %f"))
  (setq org-latex-toc-command "\\tableofcontents \\clearpage")
  (require 'ox-beamer)
  ;; (setq org-latex-pdf-process '("pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))
  (add-to-list 'org-latex-classes
               '("elegantpaper"
                 "\\documentclass[lang=en]{elegantpaper}
                 [NO-DEFAULT-PACKAGES]
                 [PACKAGES]
                 [EXTRA]"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
  (add-to-list 'org-latex-classes
               '("beamer"
                 "\\documentclass[presentation]{beamer}
                 [NO-DEFAULT-PACKAGES]
                 [PACKAGES]
                 [EXTRA]"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))
  (setq org-latex-listings 'minted)
  (setq org-latex-minted-options
        '(("frame" "none")
          ("linenos" "false")
          ("breaklines" "true")
          ("bgcolor" "lightgray")))
  (add-to-list 'org-latex-packages-alist '("" "minted"))
  (add-to-list 'org-latex-packages-alist '("" "svg"))
  )
;; -OrgLatexExport

;; Ebib
(use-package ebib
  :ensure t
  :config
  (setq ebib-index-columns
        (quote
         (("timestamp" 12 t)
          ("Entry Key" 20 t)
          ("Author/Editor" 40 nil)
          ("Year" 6 t)
          ("Title" 50 t))))
  (setq ebib-index-default-sort (quote ("timestamp" . descend)))
  (setq ebib-preload-bib-files (quote ("~/science_works/bibliography.bib")))
  (setq ebib-timestamp-format "%Y.%m.%d")
  (setq ebib-use-timestamp t))
;; -Ebib

;; OrgBabel
;; no need confirmation before evalution
(defun k4i/org-confirm-babel-evaluate (lang body)
  (not (member lang '("dot" "plantuml" "python" "shell" "emacs-lisp"))))

(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '(
     (emacs-lisp . t)
     (dot . t)
     (python . t)
     (plantuml . t)
     (shell . t)
     ))
  (setq org-confirm-babel-evaluate #'k4i/org-confirm-babel-evaluate)
  (push '("conf-unix" . conf-unix) org-src-lang-modes))
;; -OrgBabel

;; OrgBabelTangle
;; Automatically tangle our org config file in the emacs directory when we save it
(defun k4i/org-babel-tangle-config ()
  "tangle any org-mode file inside user-emacs-directory"
  (when (string-equal (file-name-directory (buffer-file-name))

                      (let (
                            ;; (emacs-config-dir user-emacs-directory)
                            (emacs-config-dir "~/.dotfiles/.emacs.d/")
                            )
                        (expand-file-name emacs-config-dir))
                      )
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'k4i/org-babel-tangle-config)))
;; -OrgBabelTangle

;; OrgCaptureTemplates
(with-eval-after-load 'org-capture
  (add-to-list 'org-capture-templates
               '("t" "Task"  entry
                 (file "GTD/Tasks.org")
                 "* TODO %?\nDEADLINE: %(format-time-string \"<<%Y-%m-%d %a>>\")\n"
                 :unnarrowed t)))

(with-eval-after-load 'org-capture
  (add-to-list 'org-capture-templates
               '("c" "Contact"  entry
                 (file "GTD/Contacts.org")
                 "* %?\n:PROPERTIES:\n:ADDRESS:\n:PHONE:\n:BDAY: %(format-time-string \"<<%Y-%m-%d %a +1y>>\")\n:EMAIL:\n:END:\n"
                 :unnarrowed t)))

(with-eval-after-load 'org-capture
  (add-to-list 'org-capture-templates
               '("h" "Habit"  entry
                 (file "GTD/Habits.org")
                 "* NEXT %?\nSCHEDULED: %(format-time-string \"<<%Y-%m-%d %a .+1d/3d>>\")\n:PROPERTIES:\n:STYLE: habit\n:REPEAT_TO_STATE: NEXT\n:END:\n"
                 :unnarrowed t)))

(defun org-hugo-new-subtree-post-capture-template ()
  "Returns `org-capture' template string for new Hugo post.
 See `org-capture-templates' for more information."
  (let* (;; http://www.holgerschurig.de/en/emacs-blog-from-org-to-hugo/
         (date (format-time-string (org-time-stamp-format :long :inactive) (org-current-time)))
         (title (read-from-minibuffer "Post Title: ")) ;Prompt to enter the post title
         (fname (org-hugo-slug title)))
    (mapconcat #'identity
               `(
                 ,(concat "\n* TODO " title "  :@cat:tag:")
                 ":PROPERTIES:"
                 ,(concat ":EXPORT_HUGO_BUNDLE: " fname)
                 ":EXPORT_FILE_NAME: index"
                 ,(concat ":EXPORT_DATE: " date) ;Enter current date and time
                 ":EXPORT_HUGO_CUSTOM_FRONT_MATTER: :image \"/images/icons/tortoise.png\""
                 ":EXPORT_HUGO_CUSTOM_FRONT_MATTER+: :libraries '(mathjax)"
                 ":EXPORT_HUGO_CUSTOM_FRONT_MATTER+: :description \"this is a description\""
                 ":END:"
                 "%?\n")
               "\n")))

(with-eval-after-load 'org-capture
  (setq hugo-content-org-dir "~/git-repo/blog/blog-src/content-org")
  (add-to-list 'org-capture-templates
               `("pe"
                 "Hugo Post (en)"
                 entry
                 (file ,(expand-file-name "all-posts.en.org" hugo-content-org-dir))
                 (function org-hugo-new-subtree-post-capture-template)))
  (add-to-list 'org-capture-templates
               `("pz"
                 "Hugo Post (zh)"
                 entry
                 (file ,(expand-file-name "all-posts.zh.org" hugo-content-org-dir))
                 (function org-hugo-new-subtree-post-capture-template)))
  (add-to-list 'org-capture-templates '("p" "Hugo Post")))
;; -OrgCaptureTemplates

;; OrgRoam
(use-package org-roam
  :after org
  :init
  (setq org-roam-v2-ack t)
  :custom
  (org-roam-directory (expand-file-name "Org-Roam" org-directory))
  (org-roam-complete-everywhere t)
  :config
  (org-roam-setup)
  (setq org-roam-capture-templates
        '(("d" "default" plain "%?"
           :target (file+head "${slug}.org"
                              "#+title: ${title}\n")
           :unnarrowed t
           )))

  ;; changing title changes file name and refs automatically
  (defun org-rename-to-new-title ()
    (when-let*
        ((old-file (buffer-file-name))
         (is-roam-file (org-roam-file-p old-file))
         (file-node (save-excursion
                      (goto-char 1)
                      (org-roam-node-at-point)))
         (slug (org-roam-node-slug file-node))
         (new-file (expand-file-name (concat slug ".org")))
         (different-name? (not (string-equal old-file new-file))))
      (rename-buffer new-file)
      (rename-file old-file new-file)
      (set-visited-file-name new-file)
      (set-buffer-modified-p nil)))

  (add-hook 'after-save-hook 'org-rename-to-new-title)

  :bind
  (("C-c n f" . org-roam-node-find)
   ("C-c n r" . org-roam-node-random)
   :map org-mode-map
   ("C-c n i" . org-roam-node-insert)
   ("C-c n o" . org-id-get-create)
   ("C-c n t" . org-roam-tag-add)
   ("C-c n a" . org-roam-alias-add)
   ("C-c n l" . org-roam-buffer-toggle)
   ;; ("C-M-i" . completion-at-point)
   ))
;; -OrgRoam

;; OrgRoamUI
(use-package org-roam-ui
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))
;; -OrgRoamUI

;; OrgRef
(use-package org-ref
    :after org
    :init
    :config
    (setq
         ; Let ivy makes completion.
         org-ref-completion-library 'org-ref-ivy-cite
         ; Use Helm to get pdf filename.
         org-ref-get-pdf-filename-function 'org-ref-get-pdf-filename-helm-bibtex
         ; Use the bibtext file exported from Zotero.
         ;; org-ref-default-bibliography (list (expand-file-name "library.bib" zotero-directory))
         ;; org-ref-bibliography-notes (expand-file-name "bibnotes.org" org-roam-directory)
         ; Use org-roam files as my reading notes.
         ;; org-ref-notes-directory org-roam-directory
         org-ref-notes-function 'orb-edit-notes
         ; Add templates for my reading notes.
         org-ref-note-title-format (concat
                                    "* TODO %y - %t\n"
                                    ":PROPERTIES:\n"
                                    ":Custom_ID: %k\n"
                                    ":NOTER_DOCUMENT: %F\n"
                                    ":ROAM_KEY: cite:%k\n"
                                    ":AUTHOR: %9a\n"
                                    ":JOURNAL: %j\n"
                                    ":YEAR: %y\n"
                                    ":VOLUME: %v\n"
                                    ":PAGES: %p\n"
                                    ":DOI: %D\n"
                                    ":URL: %U\n"
                                    ":END:\n\n"
                                    )
    ))
;; -OrgRef

;; CiteprocOrg
(use-package citeproc-org
  :config
  (citeproc-org-setup))
;; -CiteprocOrg

;; OrgBiblatex
(require 'oc-biblatex)
;; -OrgBiblatex

;; OxGfm
(use-package ox-gfm
  :defer t)
;; -OxGfm

(provide 'init-org)
;;; init-org.el ends here