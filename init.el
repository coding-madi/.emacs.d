;; https://akrl.sdf.org/#orgc15a10d
(setq garbage-collection-messages t)
;; Set garbage collection threshold to 1GB.
(setq gc-cons-threshold #x40000000)

(require 'package)
(setq package-enable-at-startup nil
      package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa" . "https://melpa.org/packages/")
                         ; ("melpa-stable" . "https://stable.melpa.org/packages/")
                         ;("org" . "https://orgmode.org/elpa/")
                         )
)
;; (setq gnutls-algorithm-priority "normal:-vers-tls1.3")
(package-initialize)

(unless (package-installed-p 'use-package)
  ;; only fetch the archives if you don't have use-package installed
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(require 'transient)


;; Download Evil
(unless (package-installed-p 'evil)
  (package-install 'evil))

(require 'evil)
(evil-mode 1)

;; Have to set it up here, otherwise it won't take effect in org mode doc
(setq inhibit-startup-echo-area-message user-login-name)
(setq use-package-always-ensure nil)

(load (locate-user-emacs-file "readme.el"))

;; Mac only
;;(add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
;;(add-to-list 'default-frame-alist '(ns-appearance . dark))
;;(setq ns-use-proxy-icon nil)


