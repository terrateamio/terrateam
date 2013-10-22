#include "./lite.h"

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>

void install_sighandler(kqueue_t kq) {
    struct kevent kev;

    signal(SIGUSR1, SIG_IGN);

    EV_SET(&kev, SIGINT, EVFILT_SIGNAL, EV_ADD | EV_ENABLE, 0, 0, NULL);
    kq_event(kq, &kev, 1, 0, 0, NULL);
    puts("installed SIGUSR1 handler");

    if (kill(getpid(), SIGUSR1) < 0)
        abort();

    /* wait for the event */
    puts("waiting for SIGUSR1");
    kq_event(kq, NULL, 0, &kev, 1, NULL);
    puts ("got it");
}

int main() {
    kqueue_t kq;

    kq = kq_init();
    install_sighandler(kq);
    kq_free(kq);

    puts("ok");
    exit(0);
}
