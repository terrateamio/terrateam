test-lite: test-lite.c kqlite.c lite.h
	gcc -g -O0 -Wall -Werror -fopenmp -o test-lite test-lite.c kqlite.c

check: test-lite
	./test-lite
