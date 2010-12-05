;; developers.el - Localized development settings
;;
;; Author: Allan Caffee
;;
;; LocalWords:  ck cc cg Paren firebrick DOXYMACS py Zsh zsh XML xsd jikes javac
;; LocalWords:  spim zA CSVHDL tb halfadderb vhd regexp vhdl setq alist cf

;;;;;;;;; Programming Stuff
(global-set-key "\C-c[" 'compile)
(global-set-key "\C-ck" 'kill-compilation)

(setq-default indent-tabs-mode nil) ;;Indent with spaces _never_ with with tabs
(global-set-key "\C-cc" 'comment-region)
(global-set-key "\C-cg" 'goto-line)
(show-paren-mode 1) ;; Paren matching
(setq compilation-read-command nil)
(setq-default c-basic-offset 2)
(setq-default sh-basic-offset 2)

(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (load "emacs-lisp/lisp-mode")
            (local-set-key
             "\M-o" 'eval-current-buffer)))

(add-hook 'c-mode-common-hook
          (lambda ()
               (when (string-equal (file-name-extension (buffer-file-name))
                                   "pc")
                 (embed-sql-mode 1))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Font Lock ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(global-font-lock-mode 1)
(custom-set-faces
 '(font-lock-comment-face ((((class color)) (:foreground "cadet blue"))))
 '(font-lock-string-face ((((class color))  (:foreground "magenta"   ))))
 '(font-lock-keyword-face ((((class color)) (:foreground "firebrick1"))))
 '(font-lock-variable-name-face ((((class color))
                                            (:foreground "orange"    ))))
 '(sh-heredoc-face ((((class color) (background light)) (:foreground "green"))))
 )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; DOXYMACS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Only load doxymacs if all the prereqs are available.
(when (and (require 'custom nil t)
           (require 'xml-parse nil t)
           (require 'tempo nil t)
           (require 'doxymacs nil t))
      (add-hook 'c-mode-common-hook 'doxymacs-mode)
      (add-hook 'font-lock-mode-hook (lambda () 
                                       (when (or (eq major-mode 'c-mode)
                                                 (eq major-mode 'c++-mode))
                                         (doxymacs-font-lock)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Global Tags ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(if (require 'gtags nil t)
    (add-hook 'c-mode-common-hook
              (lambda ()
                (gtags-mode)
                (local-set-key "\C-c." 'gtags-find-rtag)))
  )

;;;;;;; Python Mode
(add-to-list 'auto-mode-alist '("\\.py$" . python-mode))
(add-to-list 'interpreter-mode-alist '("\\.py" . python-mode))
(autoload 'python-mode "python-mode" "Python editing mode." t)

;; Zsh shell scripts
(add-to-list 'auto-mode-alist '("\\.zsh$" . shell-script-mode))

;; XML Schema Definitions
(add-to-list 'auto-mode-alist '("\\.xsd$" . xml-mode))

;; Google Protocol Buffers
(when (require 'protobuf-mode nil t)
  (add-to-list 'auto-mode-alist '("\\.proto$" . protobuf-mode))
  )

;;;;;;; Java Mode
(add-hook 'java-mode-hook (lambda ()
                            (if (eq major-mode 'java-mode)
                                (setq compile-command "ant"))))
;; Java processing module
(add-to-list 'auto-mode-alist '("\\.pde$" . java-mode))


;;;;;;; Ant Build Tool
(require 'compile)
(setq-default compilation-error-regexp-alist
  (append (list
     '("At \\([a-z0-9A-Z_\\-\\.]+\\): (line \\([0-9]+\\))" 1 2)
     ;;works for jikes
     '("^\\s-*\\[[^]]*\\]\\s-*\\(.+\\):\\([0-9]+\\):\\([0-9]+\\):[0-9]+:[0-9]+:" 1 2 3)
     ;;works for javac
     '("^\\s-*\\[[^]]*\\]\\s-*\\(.+\\):\\([0-9]+\\):" 1 2)
     ;;works for Eclipse java Compiler
     '("----------\n[0-9]+. \\(ERROR\\|WARNING\\) in \\(.*\\) (at line \\([0-9]+\\))\n\\(\\(.*\n\\)+?\\).*^+\n\\(.*\n\\)"
       2 3)
     '("^spim.*error on line \\([0-9]+\\) of file \\([a-zA-Z0-9_\\-\\.]+\\)" 2 1)
     '("^\\(?:Error\\|Abort\\|Warning\\):.*: *\\([a-z0-9A-Z_\\-\\.]+\\): (line \\([0-9]+\\))" 1 2)
;; Error: CSVHDL0002: tb_halfadderb.vhd: (line 1): syntax error, unexpected IDENTIFIER
; (regexp-quote "Error: CSVHDL0002: tb_halfadderb.vhd: (line 1): syntax error, unexpected IDENTIFIER")
     )
  compilation-error-regexp-alist))

(require 'git nil t)

;; (require 'vhdl-mode)
;; (add-hook 'vhdl-mode-hook
;;           '(lambda nil
;;              (setq compilation-error-regexp-alist
;;                    (add-to-list 'compilation-error-regexp-alist
;;                                 '("^\\(?:Error\\|Abort\\):.*: *\\([a-z0-9A-Z_\\-\\.]+\\): (line \\([0-9]+\\))" 1 2)))
;;              (setq compilation-error-regexp-alist
;;                    (add-to-list 'compilation-error-regexp-alist
;;                                 '("At \\([a-z0-9A-Z_\\-\\.]+\\): (line \\([0-9]+\\))" 1 2)))))

(when (require 'devel-funcs nil t)
    (add-hook 'c-mode-common-hook
              (lambda ()
                (local-set-key
                 "\C-cf" 'ac-name-c-function)))
    (add-hook 'latex-mode-hook
              (lambda ()
                (local-set-key
                 "\C-cm" 'ac-latex-mathify)))
    )

(when (require 'protobuf-mode)
  (add-to-list 'auto-mode-alist '("\\.proto$" . protobuf-mode)))

;; Remove the call to auto-template from the find-file-hooks.  I really
;; need to shoot him an angry email about adding things to peoples
;; hooks.
(setq find-file-hooks
      (remove 'auto-template find-file-hooks))

(provide 'ac-devel)
