# A makefile to compile Emacs lisp files for faster loading.
EMACS = emacs
EMACS_FLAGS = --no-site-file --no-init-file --batch

all :
	$(EMACS) $(EMACS_FLAGS) --eval '(batch-byte-recompile-directory 0)' .
	$(EMACS) $(EMACS_FLAGS) --eval \
	'(progn (setq backup-inhibited t) ;\
	(setq generated-autoload-file "$(PWD)/loaddefs.el") ;\
	(update-directory-autoloads "."))'
clean:
	rm -f *.elc loaddefs.el
