#
# Copyright (c) 2009 Mark Heily <mark@heily.com>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

REPOSITORY=svn+ssh://mark.heily.com/$$HOME/svn/$(PROGRAM)
DIST=heily.com:$$HOME/public_html/$(PROGRAM)/dist

include config.mk

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $(CFLAGS) $<

$(PROGRAM).so: $(OBJS)
	$(AR) rcs $(PROGRAM).a $(OBJS)
	$(LD) $(LDFLAGS) -o $(PROGRAM).so $(OBJS) $(LDADD)

install: $(PROGRAM).so
	$(INSTALL) -d -m 755 $(INCLUDEDIR)/kqueue/sys
	$(INSTALL) -m 644 include/sys/event.h $(INCLUDEDIR)/kqueue/sys/event.h
	$(INSTALL) -d -m 755 $(LIBDIR) 
	$(INSTALL) -m 644 $(PROGRAM).so $(PROGRAM).la $(PROGRAM).a $(LIBDIR)
	$(INSTALL) -d -m 755 $(LIBDIR)/pkgconfig
	$(INSTALL) -m 644 libkqueue.pc $(LIBDIR)/pkgconfig
	$(INSTALL) -d -m 755 $(MANDIR)/man2
	$(INSTALL) -m 644 kqueue.2 $(MANDIR)/man2/kqueue.2
	$(INSTALL) -m 644 kqueue.2 $(MANDIR)/man2/kevent.2

uninstall:
	rm -f $(INCLUDEDIR)/kqueue/sys/event.h
	rm -f $(LIBDIR)/libkqueue.so 
	rm -f $(LIBDIR)/pkgconfig/libkqueue.pc 
	rm -f $(MANDIR)/man2/kqueue.2 
	rm -f $(MANDIR)/man2/kevent.2 
	rmdir $(INCLUDEDIR)/kqueue/sys $(INCLUDEDIR)/kqueue

check:
	cd test && ./configure && make check

dist:
	cd test && make distclean || true
	mkdir $(PROGRAM)-$(VERSION)
	cp  Makefile ChangeLog configure config.inc      \
        $(MANS) $(EXTRA_DIST)   \
        $(PROGRAM)-$(VERSION)
	cp -R $(SUBDIRS) $(PROGRAM)-$(VERSION)
	rm -rf `find $(PROGRAM)-$(VERSION) -type d -name .svn`
	tar zcf $(PROGRAM)-$(VERSION).tar.gz $(PROGRAM)-$(VERSION)
	rm -rf $(PROGRAM)-$(VERSION)

dist-upload: dist
	scp $(PROGRAM)-$(VERSION).tar.gz $(DIST)

publish-www:
	rm ~/public_html/libkqueue/*.html ; cp -R www/*.html ~/public_html/libkqueue/

clean:
	rm -f *.a $(OBJS) *.so rpm.spec

merge:
	svn diff $(REPOSITORY)/branches/stable $(REPOSITORY)/trunk | gvim -
	@printf "Merge changes from the trunk to the stable branch [y/N]? "
	@read x && test "$$x" = "y"
	echo "ok"

distclean: clean
	rm -f *.tar.gz config.mk config.h $(PROGRAM).pc $(PROGRAM).la
