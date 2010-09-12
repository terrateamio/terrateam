SOURCES=download.html index.html links.html usage.html support.html install.html

all: clean $(SOURCES)

%.html:
	m4 -P < $@.in > $@
	chmod 444 $@

clean:
	rm -f $(SOURCES)
