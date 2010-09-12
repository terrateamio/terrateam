# For information about using M4 to generate HTML, see:
#
#     http://tldp.org/LDP/LG/issue22/using_m4.html
#

SOURCES=download.html index.html links.html usage.html support.html install.html

all: clean $(SOURCES)

%.html:
	m4 -P < $@.in > $@
	chmod 444 $@

clean:
	rm -f $(SOURCES)
