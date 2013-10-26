test-lite: test-lite.c kqlite.c lite.h
	gcc -D_GNU_SOURCE=1 -g -O0 -std=c99 -Wall -Werror -fopenmp -o test-lite test-lite.c kqlite.c

check: test-lite
	./test-lite
