(require 'cli (concat (file-name-directory load-file-name) "org-export-cli.el"))

;; (byte-compile-file (concat (file-name-directory load-file-name) "cli.el"))
(setq options-alist
      '(("--infile" "path to input .org file (required)")
	("--outfile" "path to output .pdf file (use base name of infile by default)"
	 nil)
	("--evaluate" "evaluate source code blocks" nil)
	("--package-dir" "directory containing elpa packages" "~/.org-export")
	("--verbose" "enable debugging message on error" nil)
	))

(setq args (cli-parse-args options-alist "
Note that code block evaluation is disabled by default; use
'--evaluate' to set a default value of ':eval yes' for all code
blocks. If you would like to evaluate by default without requiring
this option, include '#+PROPERTY: header-args :eval yes' in the file
header. Individual blocks can be selectively evaluated using ':eval
yes' in the block header.
"))
(defun getopt (name) (gethash name args))
(cli-el-get-setup
 (getopt "package-dir") '(htmlize org color-theme))

(require 'ox)
(require 'ox-latex)
;; following doesn't work
;; (require 'ox-koma-letter)

;; this does!
(require 'find-lisp)
(defun find-and-load-file-p (dir regexp)
  (let ((load-it (lambda (f)
                   ;; (print  f)
                   (load-file f))
                 ))
    (mapc load-it (find-lisp-find-files dir regexp))))
(find-and-load-file-p "~/.emacs.d/" "ox-koma-letter.el")


;; provides colored syntax highlighting
(require 'color-theme)

(setq debug-on-error (getopt "verbose"))
;; (setq debug-on-signal (getopt "debug"))

;; general configuration
(setq make-backup-files nil)

;; ess configuration
;; (add-hook 'ess-mode-hook
;; 	  '(lambda ()
;; 	     (setq ess-ask-for-ess-directory nil)))


;; org-mode and export configuration

;; store the execution path for the current environment and provide it
;; to sh code blocks - otherwise, some system directories are
;; prepended in the code block's environment. Would be nice to figure
;; out where these are coming from. This solves the problem for shell
;; code blocks, but not for other languages (like python).
(defvar exec-path-str
  (mapconcat 'identity exec-path ":"))
(defvar sh-src-prologue
  (format "export PATH=\"%s\"" exec-path-str))

(add-hook 'org-mode-hook
	  '(lambda ()
	     ;; (font-lock-mode)
	     ;; (setq org-src-fontify-natively t)
	     ;; (setq htmlize-output-type 'inline-css)
	     (setq org-confirm-babel-evaluate nil)
	     (setq org-export-allow-BIND 1)
	     ;; (setq org-export-preserve-breaks t)
	     ;; (setq org-export-with-sub-superscripts nil)
	     ;; (setq org-export-with-section-numbers nil)
	     ;; (setq org-html-head-extra my-html-head-extra)
	     (setq org-babel-sh-command "bash")
	     (setq org-babel-default-header-args
		   (list `(:session . "none")
			 `(:eval . ,(if (getopt "evaluate") "yes" "no"))
			 `(:results . "output replace")
			 `(:exports . "both")
			 `(:cache . "no")
			 `(:noweb . "no")
			 `(:hlines . "no")
			 `(:tangle . "no")
			 `(:padnewline . "yes")
			 ))

	     ;; explicitly set the PATH in sh code blocks; note that
	     ;; `list`, the backtick, and the comma are required to
	     ;; dereference sh-src-prologue as a variable; see
	     ;; http://stackoverflow.com/questions/24188100
	     (setq org-babel-default-header-args:sh
		   (list `(:prologue . ,sh-src-prologue)))
       ;; (org-link-set-parameters "tel" :export (lambda (path desc format) (concat "tel:" desc))) 
       (org-link-set-parameters "tel")

       (add-to-list 'org-latex-classes
                    '("a4-labels"
                      "\\documentclass[a4paper,12pt]{article}
                             \\usepackage[newdimens]{labels}
                             \\LabelCols=3% Number of columns of labels per page
                             \\LabelRows=8% Number of rows of labels per page
                             \\LeftPageMargin=7mm% These four parameters give the
                             \\RightPageMargin=7mm% page gutter sizes. The outer edges of
                             \\TopPageMargin=15mm% the outer labels are the specified
                             \\BottomPageMargin=15mm% distances from the edge of the paper.
                             \\InterLabelColumn=2mm% Gap between columns of labels
                             \\numberoflabels=24
                             "
                      ))
              (add-to-list 'org-latex-classes
                           '("letter-de"
                             "\\documentclass[DIV=14,
                                fontsize=11pt,
                                parskip=half,
                                backaddress=false,
                                fromemail=true,
                                fromphone=true,
                              fromalign=left]{scrlttr2}
                             \\usepackage[ngerman]{babel}"
                             ))
              (add-to-list 'org-latex-classes
                           '("letter-en"
                             "\\documentclass[DIV=14,
                                fontsize=11pt,
                                parskip=half,
                                backaddress=false,
                                fromemail=true,
                                fromphone=true,
                              fromalign=left]{scrlttr2}
                              \\usepackage[english]{babel}"
                             ))
	     (org-babel-do-load-languages
	      'org-babel-load-languages (cli-get-org-babel-load-languages))

	     )) ;; end org-mode-hook

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; compile and export ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar infile (getopt "infile"))
(defvar outfile
  (file-truename
   (or (getopt "outfile") (replace-regexp-in-string "\.org$" ".pdf" infile))))

;; remember the current directory; find-file changes it
(defvar cwd default-directory)
;; copy the source file to a temporary file; note that using the
;; infile as the base name defines the working directory as the same
;; as the input file
;(defvar infile-temp (make-temp-name (format "%s.temp." infile)))
;(copy-file infile infile-temp t)
(find-file infile)
(org-mode)
(message (format "org-mode version %s" org-version))
(org-koma-letter-export-to-pdf)
;(write-file outfile)

;; clean up
(setq default-directory cwd)
;(delete-file infile-temp)
