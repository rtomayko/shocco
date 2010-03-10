PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
PROGRAMS = shocco
DOCS = shocco.html index.html
BROWSER = $(shell command -v xdg-open open firefox | head -1)

default: sup shocco shocco.html

sup:
	@cat README | head -8

shocco: shocco.sh
	cat shocco.sh > shocco
	chmod +x shocco

shocco.html: shocco
	/bin/sh shocco shocco.sh > shocco.html

index.html: shocco.html
	cp -p shocco.html index.html

install: shocco
	install -m 0755 shocco $(BINDIR)/shocco

preview: sup shocco.html
	$(BROWSER) ./shocco.html

clean:
	rm -f $(PROGRAMS) $(DOCS)
