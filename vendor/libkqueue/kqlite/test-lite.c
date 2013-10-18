#include "./lite.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
    kqueue_t kq;

    kq = kq_init();
    kq_free(kq);

    puts("ok");
    exit(0);
}
