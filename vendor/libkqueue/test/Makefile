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

check:
	if [ ! -f /usr/include/sys/event.h ] ; then \
        cd .. && ./configure --debug=yes && make build ; \
	fi
	$(CC) $(CFLAGS) $(SOURCES) $(LDADD)
	./a.out

# NOTE: copy+paste of 'make check'
valgrind:
	cd .. && make build CFLAGS="$(CFLAGS) -g -O0 -DKQUEUE_DEBUG -DUNIT_TEST"
	gcc -c $(CFLAGS) test.c
	gcc -g -O0 $(CFLAGS) test.c libkqueue.a $(LDADD)
	valgrind --tool=memcheck --leak-check=full --show-reachable=yes --num-callers=20 --track-fds=yes ./a.out


check-installed:
	gcc $(CFLAGS) -I$(PREFIX)/kqueue test.c -lkqueue
	./a.out

check-libtool:
	gcc $(CFLAGS) -c *.c
	libtool --mode=link gcc -g -O0 -o a.out *.o $(LIBDIR)/libkqueue.la
	./a.out

distclean: clean
	rm -f config.mk config.h a.out

clean:
	rm -f *.o 
