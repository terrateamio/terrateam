#include "./lite.h"

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>


void test_evfilt_write(kqueue_t kq) {
    struct kevent kev;
    int sockfd[2];

    puts("testing EVFILT_WRITE.. ");

    if (socketpair(AF_UNIX, SOCK_STREAM, 0, sockfd) < 0)
      abort();

    EV_SET(&kev, sockfd[1], EVFILT_WRITE, EV_ADD | EV_ENABLE, 0, 0, NULL);
    kq_event(kq, &kev, 1, 0, 0, NULL);
    puts("installed EVFILT_WRITE handler");

    if (write(sockfd[0], "hi", 2) < 2)
        abort();

    /* wait for the event */
    puts("waiting for event");
    kq_event(kq, NULL, 0, &kev, 1, NULL);
    puts ("got it");

    close(sockfd[0]);
    close(sockfd[1]);
}

void install_sighandler(kqueue_t kq) {
    struct kevent kev;

    signal(SIGUSR1, SIG_IGN);

    EV_SET(&kev, SIGUSR1, EVFILT_SIGNAL, EV_ADD | EV_ENABLE, 0, 0, NULL);
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
    //install_sighandler(kq);
    test_evfilt_write(kq);
    kq_free(kq);

    puts("ok");
    exit(0);
}
