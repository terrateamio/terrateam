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
DISTFILE=$(PROGRAM)-$(VERSION).tar.gz

include config.mk

.PHONY :: install uninstall check dist dist-upload publish-www clean merge distclean fresh-build rpm edit cscope

all: $(PROGRAM).so.$(ABI_VERSION)

%.o: %.c $(DEPS)
	$(CC) -c -o $@ -I./include -I./src/common $(CFLAGS) $<

$(PROGRAM).a: $(OBJS)
	$(AR) rcs $(PROGRAM).a $(OBJS)

$(PROGRAM).so.$(ABI_VERSION): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) $(LDADD)
	$(LN) -sf $(PROGRAM).so.$(ABI_VERSION) $(PROGRAM).so.$(ABI_MAJOR)
	$(LN) -sf $(PROGRAM).so.$(ABI_VERSION) $(PROGRAM).so

install: $(PROGRAM).so.$(ABI_VERSION)
	$(INSTALL) -d -m 755 $(INCLUDEDIR)/kqueue/sys
	$(INSTALL) -m 644 include/sys/event.h $(INCLUDEDIR)/kqueue/sys/event.h
	$(INSTALL) -d -m 755 $(LIBDIR) 
	$(INSTALL) -m 644 $(PROGRAM).so.$(ABI_VERSION) $(LIBDIR)
	$(INSTALL) -m 644 $(PROGRAM).so.$(ABI_MAJOR) $(LIBDIR)
	$(LN) -sf $(PROGRAM).so.$(ABI_VERSION) $(LIBDIR)/$(PROGRAM).so.$(ABI_MAJOR)
	$(LN) -sf $(PROGRAM).so.$(ABI_VERSION) $(LIBDIR)/$(PROGRAM).so
	$(INSTALL) -m 644 $(PROGRAM).la $(LIBDIR)
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

check: clean $(PROGRAM).so.$(ABI_VERSION)
	cd test && ./configure && make check

debug-check: clean
	cd test && ./configure && KQUEUE_DEBUG=y make check

$(DISTFILE): $(SOURCES) $(HEADERS)
	mkdir $(PROGRAM)-$(VERSION)
	cp  Makefile ChangeLog configure config.inc      \
        $(MANS) $(EXTRA_DIST)   \
        $(PROGRAM)-$(VERSION)
	cp -R $(SUBDIRS) $(PROGRAM)-$(VERSION)
	rm -rf `find $(PROGRAM)-$(VERSION) -type d -name .svn -o -name .libs`
	cd $(PROGRAM)-$(VERSION) && ./configure && cd test && ./configure && cd .. && make distclean
	tar zcf $(PROGRAM)-$(VERSION).tar.gz $(PROGRAM)-$(VERSION)
	rm -rf $(PROGRAM)-$(VERSION)

dist:
	rm -f $(DISTFILE)
	make $(DISTFILE)

dist-upload: $(DISTFILE)
	scp $(DISTFILE) $(DIST)

clean:
	rm -f tags *.a *.so *.so.* *.so.*.*
	find src -name '*.o' -exec rm {} \;
	rm -rf pkg
	cd test && make clean || true
	if [ -d www ] ; then cd www && make clean ; fi

distclean: clean
	rm -f *.tar.gz config.mk config.h $(PROGRAM).pc $(PROGRAM).la rpm.spec
	rm -rf $(PROGRAM)-$(VERSION) 2>/dev/null || true

fresh-build:
	rm -rf /tmp/$(PROGRAM)-testbuild 
	svn co svn://mark.heily.com/libkqueue/trunk /tmp/$(PROGRAM)-testbuild 
	cd /tmp/$(PROGRAM)-testbuild && ./configure && make check
	rm -rf /tmp/$(PROGRAM)-testbuild 

merge:
	svn diff $(REPOSITORY)/branches/stable $(REPOSITORY)/trunk | gvim -
	@printf "Merge changes from the trunk to the stable branch [y/N]? "
	@read x && test "$$x" = "y"
	echo "ok"

tags: $(SOURCES) $(HEADERS)
	ctags $(SOURCES) $(HEADERS)

edit: tags
	$(EDITOR) $(SOURCES) $(HEADERS)
    
cscope: tags
	cscope $(SOURCES) $(HEADERS)

# Creates an ~/rpmbuild tree
rpmbuild:
	mkdir -p $$HOME/rpmbuild
	cd $$HOME/rpmbuild && mkdir -p BUILD RPMS SOURCES SPECS SRPMS
	grep _topdir $$HOME/.rpmmacros || \
           echo "%_topdir %(echo $$HOME/rpmbuild)" >> $$HOME/.rpmmacros

rpm: rpmbuild clean $(DISTFILE)
	mkdir -p pkg
	cp $(DISTFILE) $$HOME/rpmbuild/SOURCES 
	rpmbuild -bb rpm.spec
	find $$HOME/rpmbuild -name '$(PROGRAM)-$(VERSION)*.rpm' -exec mv {} ./pkg \;

deb: clean $(DISTFILE)
	mkdir pkg && cd pkg ; \
	tar zxf ../$(DISTFILE) ; \
	cp ../$(DISTFILE) $(PROGRAM)_$(VERSION).orig.tar.gz ; \
	cp -R ../ports/debian $(PROGRAM)-$(VERSION) ; \
	rm -rf `find $(PROGRAM)-$(VERSION)/debian -type d -name .svn` ; \
	perl -pi -e 's/\@\@VERSION\@\@/$(VERSION)/' $(PROGRAM)-$(VERSION)/debian/changelog ; \
	cd $(PROGRAM)-$(VERSION) && dpkg-buildpackage -uc -us
	lintian -i pkg/*.deb
	@printf "\nThe following packages have been created:\n"
	@find ./pkg -name '*.deb' | sed 's/^/    /'

debug-install:
	./configure --prefix=/usr --debug=yes
	make clean && make && sudo make install

diff:
	if [ "`pwd | grep /trunk`" != "" ] ; then \
	   (cd .. ; $(DIFF) branches/stable trunk | less) ; \
    fi
	if [ "`pwd | grep /branches/stable`" != "" ] ; then \
	   (cd ../.. ; $(DIFF) branches/stable trunk | less) ; \
    fi

# Used for testing on a Solaris guest VM
#
solaris-test:
	make dist && scp -P 2222 libkqueue-1.0a.tar.gz localhost:/tmp && ssh -p 2222 localhost ". .profile ; cd /tmp ; rm -rf libkqueue-$(VERSION) ; gtar zxvf libkqueue-$(VERSION).tar.gz && cd libkqueue-$(VERSION) && ./configure && make && make check"
