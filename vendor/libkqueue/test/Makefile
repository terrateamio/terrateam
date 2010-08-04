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

include config.mk

all: kqtest

kqtest: $(SOURCES)
	$(CC) -o kqtest $(CFLAGS) $(SOURCES) $(LDADD)

check: kqtest
	KQUEUE_DEBUG=1 ./kqtest

valgrind: kqtest
	valgrind --tool=memcheck --leak-check=full --show-reachable=yes --num-callers=20 --track-fds=yes ./kqtest

check-installed:
	$(CC) -o kqtest $(CFLAGS) $(SOURCES) $(LDADD) -lkqueue
	./kqtest

check-libtool:
	gcc $(CFLAGS) -c *.c
	libtool --mode=link gcc -g -O0 -o kqtest *.o $(LIBDIR)/libkqueue.la
	./kqtest

distclean: clean 
	rm -f config.mk config.h
	for x in libdispatch stress; do cd $$x && make distclean ; done

edit:
	$(EDITOR) *.[ch]

clean:
	rm -f *.o *.a kqtest
