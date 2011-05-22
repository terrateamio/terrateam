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

tests=kqtest lockstat static-lib-test

include config.mk

all: $(tests)

lockstat: lockstat.c
	$(CC) -o lockstat $(CFLAGS) lockstat.c $(LDADD)

kqtest: $(SOURCES)
	$(CC) -o kqtest $(CFLAGS) $(SOURCES) $(LDADD)

static-lib-test: $(SOURCES)
	$(CC) -o static-lib-test -DMAKE_STATIC=1 $(CFLAGS) $(SOURCES) ../libkqueue.a -lpthread

check: kqtest
	LD_LIBRARY_PATH="..:/usr/sfw/lib/64" PATH="$$PATH:.." ./kqtest

debug: kqtest
	LD_LIBRARY_PATH="..:/usr/sfw/lib/64" PATH="$$PATH:.." gdb ./kqtest

valgrind: kqtest
	LD_LIBRARY_PATH="..:/usr/sfw/lib/64" \
	valgrind --tool=memcheck --leak-check=full --show-reachable=yes --num-callers=20 --track-fds=yes ./kqtest

helgrind: kqtest
	LD_LIBRARY_PATH="..:/usr/sfw/lib/64" \
	valgrind --tool=helgrind ./kqtest

cachegrind: kqtest
	LD_LIBRARY_PATH="..:/usr/sfw/lib/64" \
	valgrind --tool=cachegrind --branch-sim=yes ./kqtest

check-installed:
	$(CC) -o kqtest $(CFLAGS) $(SOURCES) $(LDADD) -lkqueue
	./kqtest

check-libtool:
	gcc $(CFLAGS) -c *.c
	libtool --mode=link gcc -g -O0 -o kqtest *.o $(LIBDIR)/libkqueue.la
	./kqtest

distclean: clean 
	rm -f config.mk config.h
	for x in libdispatch stress; do cd $$x && make distclean && cd .. ; done

edit:
	$(EDITOR) *.[ch]

clean:
	rm -f *.o *.a $(tests)
	for x in libdispatch stress; do cd $$x && make clean && cd ..; done
