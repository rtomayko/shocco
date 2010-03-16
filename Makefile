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
	echo "shocco built at \`$(sourcedir)/shocco' ..."
	echo "run \`make install' to install under $(bindir) ..."
	echo "or, just copy the \`$(sourcedir)/shocco' file where you need it."

shocco: shocco.sh
	$(SHELL) -n shocco.sh
	sed -e 's|@@MARKDOWN@@|$(MARKDOWN)|g' \
	    -e 's|@@PYGMENTIZE@@|$(PYGMENTIZE)|g' \
	< shocco.sh > shocco+
	mv shocco+ shocco
	chmod 0755 shocco

doc: shocco.html

shocco.html: shocco
	./shocco shocco.sh > shocco.html+
	mv shocco.html+ shocco.html

index.html: shocco.html
	cp -p shocco.html index.html

install-markdown:
	test -f shocco
	mkdir -p "$(bindir)"
	cp Markdown.pl "$(bindir)/markdown"
	chmod 0755 "$(bindir)/markdown"

install: $(INSTALL_PREREQUISITES)
	test -f shocco
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
