# For information about using M4 to generate HTML, see:
#
#     http://tldp.org/LDP/LG/issue22/using_m4.html
#

OBJS=download.html index.html links.html usage.html support.html install.html
DESTDIR=~/public_html/libkqueue

all: clean $(OBJS)

%.html:
	m4 -P < $@.in > $@
	tidy -q -m $@
	chmod 444 $@

clean:
	rm -f $(OBJS)

edit:
	$(EDITOR) *.in

install:
	cd $(DESTDIR) && rm -f $(OBJS)
	cp *.html *.css *.png ~/public_html/libkqueue/

