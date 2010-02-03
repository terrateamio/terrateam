CFLAGS=-I../../include
LDADD=-lpthread
PROGRAM=stresstest
SOURCES=main.c ../timer.c ../user.c ../kevent.c ../read.c ../vnode.c ../test.c

all: $(PROGRAM)

$(PROGRAM): $(SOURCES)
	$(CC) -o $(PROGRAM) $(CFLAGS) $(SOURCES) ../../libkqueue.a $(LDADD)

check: $(PROGRAM)
	./$(PROGRAM)

valgrind: $(PROGRAM)
	valgrind --tool=memcheck --leak-check=full --show-reachable=yes \
	         --num-callers=20 --track-fds=yes ./$(PROGRAM)

clean:
	rm -f $(PROGRAM) *.o

edit:
	ctags $(SOURCES)
	$(EDITOR) $(SOURCES)

distclean: clean
	rm -f $(PROGRAM) 
