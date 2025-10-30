;;; init-server.el --- Server configuration -*- lexical-binding: t -*-
;;; Commentary:
;; Emacs server configuration

;;; Code:

(require 'server)
(unless (server-running-p) (server-start))

(provide 'init-server)
;;; init-server.el ends here