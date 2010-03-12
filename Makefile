# The default target ...
all::

SHELL = /bin/sh
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
SOURCEDIR = .

PROGRAMS = shocco
DOCS = shocco.html index.html
BROWSER = $(shell for c in xdg-open open firefox;do command -v $$c && break;done)

all:: sup build

sup:
	@cat README | head -8

build: shocco shocco.html
	@echo "==========================================================="
	@echo "shocco built at \`$(SOURCEDIR)/shocco' ..."
	@echo "run \`make install' to install under $(BINDIR) ..."
	@echo "or, just copy the \`$(SOURCEDIR)/shocco' file where you need it."


shocco: shocco.sh
	@echo "==========================================================="
	$(SHELL) -n shocco.sh
	cp shocco.sh shocco
	chmod 0755 shocco

shocco.html: shocco
	$(SHELL) shocco shocco.sh > shocco.html

index.html: shocco.html
	cp -p shocco.html index.html

install: shocco
	mkdir -p $(BINDIR)
	cp shocco $(BINDIR)/shocco
	chmod 0755 $(BINDIR)/shocco

read: sup shocco.html
	$(BROWSER) ./shocco.html

clean:
	rm -f $(PROGRAMS) $(DOCS)

.PHONY: sup clean read install
