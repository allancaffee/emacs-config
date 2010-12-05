;; Development related functions

(defun ac-latex-add-graphic (image-file &optional caption-text)
  "Add the graphic `image-file' to a LaTeX document as a centered figure.
Optionally include the caption `caption-text' if provided.  When
called interactively prompt for arguments."
  (interactive "f Graphics file: \ns Caption text: ")
  (if (> (length image-file) 0)
      (insert "\\begin{figure}[ht]\n"
              "  \\begin{center}\n"
              "    \\includegraphics[width=\\textwidth]{"
              (file-name-sans-extension (file-relative-name image-file))
              "}\n"
              (when (> (length caption-text) 0)
                  (concat
                   "    \\caption{"
                   ;; Make the label
                   "\\label{fig:"
                   (replace-regexp-in-string " *" "" caption-text)
                   "}"
                   caption-text
                   "}\n"))
              "  \\end{center}\n"
              "\\end{figure}\n")))

(defun ac-latex-add-listing (source-file &caption-text)
  "Add a listing for `source-file' to a LaTeX document. TODO: Use the modemap to determine the language of the file.
"
  (interactive "f Source file: \ns Caption text: ")
  (when (> (length source-file) 0)
      (insert "\\lstinputlisting"
              (when (> (length caption-text) 0)
                  (concat
                   "[caption={"
                   caption-text
                   "},"
                   ;; Make the label
                   "label={lst:"
                   (replace-regexp-in-string " *" "" caption-text)
                   "}"
                   "]"))
              "{"
              (file-relative-name source-file)
              "}\n"
              )))

(defun ac-strings-only ()
  "Remove all text in region except that between double quotes.
For example `export foo=\"foovalue\"' would become `foovalue'.
This can be useful for pulling just the values out of XML
attributes."
  (interactive)
  (save-excursion
    (goto-char (region-beginning))
  (while (re-search-forward "[^\"]*\"\\([^\"]*\\)\"[^\"]*" (region-end) t)
    (replace-match "\\1\n" nil nil))))

(defun ac-config-header-include ()
  "Add an include directive for `config.h'."
  (interactive)
  (save-excursion
    (goto-char (line-beginning-position))
    (insert
     "#ifdef HAVE_CONFIG_H\n"
     "# include <config.h>\n"
     "#endif\n")))

(defun ac-find-header-filename ()
  "Find the filename of the header which is being included."
  (save-excursion
    (goto-char (line-beginning-position))
    (if (re-search-forward "<\\([^>]+\\)>" (line-end-position) t)
        (match-string-no-properties 1 nil)
      nil)))  ;; #include <config.h>

(defun ac-determine-availability-macro (filename)
  "Calculate the name of the macro which will be defined in
`<config.h>' when the header named in `filename' is available on
a system."
  (concat "HAVE_"
          (upcase
           (replace-regexp-in-string "[/\.]" "_" filename))))

;; (ac-determine-availability-macro "sys/stat.h")

;;;###autoload
(defun ac-protect-system-header ()
  "Surround the system header included on this line with the
appropriate ifdef statement to protect it from being included
when it is not available on the local system.
For example if the cursor were on a line like:

#include <sys/stat.h>

The line would be replaced with:

#ifdef HAVE_SYS_STAT_H
# include <sys/stat.h>
#endif
"
  (interactive)
  (save-excursion
    (let ((header-filename (ac-find-header-filename))
          (macro-name (ac-determine-availability-macro (ac-find-header-filename))))

      (save-excursion
        (goto-char (line-beginning-position))
        (insert "#ifdef " macro-name "\n"))

      (save-excursion
        (goto-char (line-end-position))
        (insert "\n#endif\n"))

      (goto-char (line-beginning-position))
      (if (re-search-forward "^# *include" (line-end-position) t)
          (replace-match "# include" nil nil))
      )))

(defun ac-tag-line-as-debug ()
  "This function appends a comment containing
`DEBUGGING-CODE-DO-NOT-COMMIT' to the current line so that it can
easily be removed later using a stream editor.  This convention also
allows the use of pre-commit hooks to prevent code which produces
debug output from being committed."
  (interactive)
  (save-excursion
    (goto-char (line-end-position))
    (comment-indent)
    (insert "DEBUGGING-CODE-DO-NOT-COMMIT")))

(defun ac-name-c-function ()
  "Echo the name of the C/C++ function where point is."
  (interactive)
  (save-excursion
    (c-beginning-of-defun)
    (if (re-search-forward "\\([^{]*\\)")
        (message "%s" (replace-regexp-in-string
                       "\n[\t ]*"
                       " "
                       (match-string 1)))
      nil))
  )

(defun ac-unwrap-text (start end)
  "Unwrap the text between `start' and `end'"
  (save-excursion
    (goto-char start)
    (if (>= (line-end-position) end)
        nil
      (progn
        (delete-indentation t)
        (ac-unwrap-text (line-end-position) end))
        )))

(defun ac-unwrap-region ()
  "Unwrap the text in region."
  (interactive)
  (save-excursion
    (let ((start (region-beginning))
          (end (region-end)))
          (ac-unwrap-text start end))
          ))

(defun ac-un-diffify (start end)
  "Remove `+' or `-' from the beginning of lines from `start' to
`end' and any whitespace leading up to them."
  (save-excursion
    (goto-char start)
    (while (re-search-forward "^[ \t]*[+\-]" end t)
        (replace-match "" nil nil))
    ))

(defun ac-undiffify-region ()
  "Remove evidence of a unified diff in region.  This is useful
when a part of a file under version control was accidentally
deleted, but we don't want to revert the whole file.  Just paste
the piece you want back into the file and clean it up."
  (interactive)
  (save-excursion
    (let ((start (region-beginning))
          (end (region-end)))
          (ac-un-diffify start end))))


(defun ac-file-autogenerated-p ()
  "Search the current buffer for a string that suggests it was
generated by one of the Autotools.  Return the name of the tool which
was used to generate the file or nil if the file does not appear to be
automatically generated."
  (save-excursion
    (let ((automake-re ;; This catches `.in' files generated by Automake.
           (concat (file-name-nondirectory (buffer-file-name))
                   "\\ generated by \\(automake\\) [^ ]* from "))
          (autogen-re ;; This one catches configure
           (concat (file-name-nondirectory (buffer-file-name))
                   "\\.  Generated \\(?:from .*\\)?by \\(.*\\)\\."))
          (autoconf-re "Generated by GNU \\(Autoconf\\) [^ ]* for"))
      (goto-char (point-min))
      (cond
       ((re-search-forward autogen-re (point-max) t)
        (match-string-no-properties 1))

       ((re-search-forward automake-re (point-max) t)
        (match-string-no-properties 1))

       ((re-search-forward autoconf-re (point-max) t)
        (match-string-no-properties 1))
       ))))

;;;###autoload
(defun ac-check-if-autogenerated-file ()
  "Search the current buffer for an indication that it was
automatically generated by one of the GNU Autotools.  If the
buffer appears to have been generated warn the user and ask for
permission to continue editing the file.  If the user responds
no, kill the buffer.

This function is designed to be added to the `find-file-hooks' so
that it will warn users if they open a generated file.  If you
want to be warned about auto-generated files add the code below to
your ~/.emacs file.  (We're assuming that you've already loaded
the library containing this function since you're reading this
documentation for it.)

(add-hook 'find-file-hooks 'ac-check-if-autogenerated-file)
"
  (interactive)
  (if (ac-file-autogenerated-p)
      (if (not (yes-or-no-p
                (concat "It appears that this file was generated by `"
                        (ac-file-autogenerated-p)
                        "'.  Edit it anyway? ")))
          (kill-buffer (buffer-name)))
    ))

(defun ac-unwrap-paragraph ()
  "Unwrap the current paragraph."
  (interactive)
  (save-excursion
    (let ((start (progn (start-of-paragraph-text)
                        (point)))
          (end (progn (end-of-paragraph-text)
                      (point))))
      (ac-unwrap-text start end))))

;;;###autoload
(defun ac-namespace-clarify ()
  "Go through the current buffer and prepend unqualified members
of the C++ std namespace type with their namespace qualifier.
For example find `string' and replace it with `std::string'."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward
            "\\(std::\\)?\\<\\(queue\\|list\\|vector\\|string\\|[io]\\{1,2\\}stream\\|map\\)\\>"
            (point-max) t)
      ;; Replace the match only if the line is not a preprocessor
      ;; directive (e.g. an include statement) and the name is not
      ;; already fully qualified.
      (if (and
           (not (match-beginning 1))
           (save-excursion
             (goto-char (line-beginning-position))
             ;; N.B. This is only safe to do because we only replace
             ;; something if the looking-at function returns false.
             ;; The `looking-at' function will clobber the match data
             ;; if it finds anything.
             (not (looking-at "#"))))
          (replace-match "std::\\2" nil nil)
        ))
    t))

;;;###autoload
(defun ac-quote-excerpt ()
  "Quote region as an excerpt from another file.  i.e. insert `|' at the
beginning of all lines within region."
  (interactive)
  (save-excursion
    (goto-char (region-beginning))
    (while (re-search-forward "^" (region-end))
      (replace-match "|"))))

(defun ac-latex-mathify (start end)
  "Quote region win `$' so that LaTeX know to treat it as inline math."
  (interactive "r")
  (goto-char end)
  (while (looking-back " " (- 2 (point)))
    (goto-char (- (point) 1)))
  (insert "$")
  (goto-char start)
  (while (looking-at " ")
    (goto-char (+ 1 (point))))
  (insert "$"))

(defun ac-py-print-var (variable)
  "Add a python print statement in for a particular variable."
  (interactive "sVariable name? ")
  (insert "print '" variable "=%s' % " variable "\n"))

(defun ac-python-2-java (start end)
  "Get a start on translating from Python to Java.  Obviously
this can't be fully autmatically with regular expressions."
  (interactive "r")
  (save-excursion
    (apply-replacement-to-region '(
                          ;; TODO: This could be a little smarter if I
                          ;; made a regexp that recognizes (almost)
                          ;; function definitions.  It could even tell
                          ;; whether or not to make the function
                          ;; static based on whether or not the
                          ;; function has "self" as a parameter.
                          ("\\(\\<def\\>.*(\\)self\\(?:,\\)? *" "\\1")
                          ("\\<def\\>" "public void")
                          ("#" "//")
                          (": *$" " {")
                          ("\\<self\\>" "this")
                          ("\\<True\\>" "true")
                          ("\\<False\\>" "false")
                          )
                                 start end)
    ))

(defun apply-replacement-to-region (replacements start end)
  "Apply a series of replacements to the specified region"
  (when (not (null replacements))
    (save-excursion
      (let ((repl (car replacements)))
        (goto-char start)
        (message (concat "Replacing " (car repl) " with " (car (cdr repl))))
        (while (re-search-forward (car repl) end t)
          (replace-match (car (cdr repl))))))
    (apply-replacement-to-region (cdr replacements) start end)))

(defun ac-kill-eol-whitespace (&optional no-prompt)
  "Kill whitespace at the end of lines.  If `no-prompt' is
non-nil then delete all eol-whitespace in the current buffer
without prompting.  Otherwise do an interactive find and
replace."
  (interactive "P")
  (save-excursion
    (goto-char 0)
    (if (null no-prompt)
        (query-replace-regexp "[ \t]\+$" "")
      (while (re-search-forward "[ \t]\+$" (point-max))
        (replace-match "")))))

(defun maybe (potential-text)
  "If the yas variable #text is not empty then return
potential-text.  This allows the implementation of conditional
fields."
  (if (string= text "") nil potential-text))

; LocalWords:  ns includegraphics textwidth foo foovalue XML config ifdef endif
; LocalWords:  ac STAT pre diff Autotools Automake autogenerated automake std
; LocalWords:  tomake toconf namespace eue io filename sys whitespace Autoconf
; LocalWords:  prepend preprocessor defun HandleTest

(provide 'devel-funcs)

