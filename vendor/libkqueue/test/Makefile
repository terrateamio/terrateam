include config.mk

all:
	gcc $(CFLAGS) main.c evfilt_read.c evfilt_signal.c \
		      evfilt_vnode.c $(LDADD)

clean:
	rm -f *.o 
