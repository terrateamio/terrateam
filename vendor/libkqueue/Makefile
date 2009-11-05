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
PROGRAM=libkqueue
INSTALL=/usr/bin/install
DISTFILES=*.c *.h kqueue.2 README Makefile configure os sys
SOURCES=src/$(UNAME)/*.c
CFLAGS=-fPIC -D_REENTRANT -I. -Wall -Werror -fvisibility=hidden
FILTERS=vnode.c timer.c signal.c socket.c user.c

include config.mk

build:
	gcc $(CFLAGS) -c *.c
	rm test.o
	ar rcs libkqueue.a *.o
	gcc -shared -Wl,-soname,libkqueue.so -o libkqueue.so *.o

install:
	$(INSTALL) -d -m 755 $(INCLUDEDIR)/kqueue
	$(INSTALL) -d -m 755 $(INCLUDEDIR)/kqueue/sys
	$(INSTALL) -d -m 755 $(MANDIR)/man2
	$(INSTALL) -m 644 sys/event.h $(INCLUDEDIR)/kqueue/sys/event.h
	$(INSTALL) -m 644 libkqueue.so $(LIBDIR)/libkqueue.so
	$(INSTALL) -m 644 libkqueue.pc $(LIBDIR)/pkgconfig
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
	mkdir $(PROGRAM)
	cp -R $(DISTFILES) $(PROGRAM)
	tar zcvf $(PROGRAM)-`date +%y%m%d_%H%M`.tar.gz $(PROGRAM)
	rm -rf $(PROGRAM)

publish-www:
	rm -rf ~/public_html/libkqueue/ ; cp -R www ~/public_html/libkqueue/

clean:
	rm -f a.out *.a *.o *.so

distclean: clean
	rm -f *.tar.gz config.mk $(FILTERS)
