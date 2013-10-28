.POSIX:
SHELL = /bin/sh

# The default target ...
all::

config.mk:
	@echo "Please run ./configure before running make"
	exit 1

include config.mk

sourcedir = .
PROGRAMS = shocco
DOCS = shocco.html index.html
DISTFILES = config.mk config.sh

all:: sup build

sup:
	echo "==========================================================="
	head -8 < README
	echo "==========================================================="

build: shocco
	echo "run \`make install' to install under $(bindir) ..."
	echo "or, just copy the \`$(sourcedir)/shocco' file where you need it."

shocco: shocco.sh
	$(SHELL) -n $<
	sed -e 's|@@MARKDOWN@@|$(MARKDOWN)|g' \
	    -e 's|@@PYGMENTIZE@@|$(PYGMENTIZE)|g' \
	< $< > shocco+
	mv shocco+ $@
	chmod 0755 $@
	echo "shocco built at \`$(sourcedir)/shocco' ..."

doc: shocco.html

shocco.html: shocco shocco.sh
	./$< $< shocco.sh > shocco.html+
	mv shocco.html+ $@

install-markdown:
	mkdir -p "$(bindir)"
	cp Markdown.pl "$(bindir)/markdown"
	chmod 0755 "$(bindir)/markdown"

install: shocco $(INSTALL_PREREQUISITES)
	mkdir -p "$(bindir)"
	cp shocco "$(bindir)/shocco"
	chmod 0755 $(bindir)/shocco

read: sup doc
	$(BROWSER) ./shocco.html

clean:
	rm -f $(PROGRAMS) $(DOCS)

distclean: clean
	rm -f $(DISTFILES)

.SUFFIXES:

.SILENT: build sup shocco
