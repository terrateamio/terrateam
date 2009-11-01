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
PREFIX=/usr
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
	mkdir -p $(PREFIX)/include/kqueue/sys
	cp event.h $(PREFIX)/include/kqueue/sys
	cp libkqueue.so $(PREFIX)/lib
	cp libkqueue.pc $(PREFIX)/lib/pkgconfig
	cp kqueue.2 $(PREFIX)/share/man/man2/kqueue.2
	ln -s kqueue.2 $(PREFIX)/share/man/man2/kevent.2

uninstall:
	rm $(PREFIX)/include/kqueue/sys/event.h
	rmdir $(PREFIX)/include/kqueue/sys
	rmdir $(PREFIX)/include/kqueue
	rm $(PREFIX)/lib/libkqueue.so 
	rm $(PREFIX)/lib/pkgconfig/libkqueue.pc 
	rm $(PREFIX)/share/man/man2/kqueue.2
	rm $(PREFIX)/share/man/man2/kevent.2

check:
	make build CFLAGS="$(CFLAGS) -g -O0 -DKQUEUE_DEBUG -DUNIT_TEST"
	gcc -c $(CFLAGS) test.c
	gcc -g -O0 $(CFLAGS) test.c libkqueue.a -lpthread -lrt
	./a.out

check-installed:
	gcc -g -O0 -Wall -Werror -I$(PREFIX)/kqueue test.c -lkqueue
	./a.out

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
