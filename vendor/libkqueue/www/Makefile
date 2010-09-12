SOURCES=download.html

all: clean $(SOURCES)

%.html:
	m4 -P < $@.in > $@
	chmod 444 $@

clean:
	rm -f $(SOURCES)
