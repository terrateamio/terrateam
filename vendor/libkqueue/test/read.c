/*
 * Copyright (c) 2009 Mark Heily <mark@heily.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */


#include "common.h"


/*
 * Create a connected TCP socket.
 */
static void
create_socket_connection(int *client_fd, int *server_fd, int *listen_fd)
{
    struct sockaddr_in sain;
    socklen_t sa_len = sizeof(sain);
    int one = 1;
    int clnt, srvr, accepted;
    short port;

    /* Create a passive socket */
    memset(&sain, 0, sizeof(sain));
    sain.sin_family = AF_INET;
    sain.sin_port = 0;
    if ((srvr = socket(PF_INET, SOCK_STREAM, 0)) < 0)
    err(1, "socket");
    if (setsockopt(srvr, SOL_SOCKET, SO_REUSEADDR,
                (char *) &one, sizeof(one)) != 0)
    err(1, "setsockopt");
    if (bind(srvr, (struct sockaddr *) &sain, sa_len) < 0) {
        printf("unable to bind to auto-assigned port\n");
        err(1, "bind-1");
    }
    if (getsockname(srvr, (struct sockaddr *) &sain, &sa_len) < 0)
        err(1, "getsockname-1");
    port = ntohs(sain.sin_port);
    if (listen(srvr, 100) < 0)
    err(1, "listen");

    /* Simulate a client connecting to the server */
    sain.sin_family = AF_INET;
    sain.sin_port = htons(port);
    sain.sin_addr.s_addr = inet_addr("127.0.0.1");
    if ((clnt = socket(AF_INET, SOCK_STREAM, 0)) < 0)
       err(1, "clnt: socket");
    if (connect(clnt, (struct sockaddr *) &sain, sa_len) < 0)
       err(1, "clnt: connect");
    if ((accepted = accept(srvr, NULL, 0)) < 0)
       err(1, "srvr: accept");

    *client_fd = clnt;
    *server_fd = accepted;
    *listen_fd = srvr;
}

static void
kevent_socket_drain(struct test_context *ctx)
{
    char buf[1];

    /* Drain the read buffer, then make sure there are no more events. */
    if (recv(ctx->client_fd, buf, 1, 0) < 1)
        die("recv(2)");
}

static void
kevent_socket_fill(struct test_context *ctx, size_t len)
{
    uint8_t *data;

    data = malloc(len);
    memset(data, '.', len);

    if (send(ctx->server_fd, data, len, 0) < 1)
        die("send(2)");

    free(data);
}


void
test_kevent_socket_add(struct test_context *ctx)
{
    struct kevent kev;

    kevent_add(ctx->kqfd, &kev, ctx->client_fd, EVFILT_READ, EV_ADD, 0, 0, &ctx->client_fd);
}

void
test_kevent_socket_add_without_ev_add(struct test_context *ctx)
{
    struct kevent kev;

    /* Try to add a kevent without specifying EV_ADD */
    EV_SET(&kev, ctx->client_fd, EVFILT_READ, 0, 0, 0, &ctx->client_fd);
    kevent_rv_cmp(-1, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));

    kevent_socket_fill(ctx, 1);
    test_no_kevents(ctx->kqfd);
    kevent_socket_drain(ctx);

    /* Try to delete a kevent which does not exist */
    kev.flags = EV_DELETE;
    kevent_rv_cmp(-1, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));
}

void
test_kevent_socket_get(struct test_context *ctx)
{
    struct kevent kev, ret[1];

    EV_SET(&kev, ctx->client_fd, EVFILT_READ, EV_ADD, 0, 0, &ctx->client_fd);
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));

    kevent_socket_fill(ctx, 1);

    kev.data = 1;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    kevent_socket_drain(ctx);
    test_no_kevents(ctx->kqfd);

    kev.flags = EV_DELETE;
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));
}

void
test_kevent_socket_clear(struct test_context *ctx)
{
    struct kevent kev, ret[1];

    test_no_kevents(ctx->kqfd);
    kevent_socket_drain(ctx);

    EV_SET(&kev, ctx->client_fd, EVFILT_READ, EV_ADD | EV_CLEAR, 0, 0, &ctx->client_fd);
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));

    /*
     * write two bytes in one call.
     * This used to be two calls writing one byte, but macOS didn't
     * always reliably report the amount of pending data correctly
     * (1 byte instead of 2).
     *
     * Adding usleep(1000) on macOS also solved the issue, but this
     * seemed like a cleaner fix.
     */
    kevent_socket_fill(ctx, 2);

/* Solaris does not offer a way to get the amount of data pending */
#if defined(__sun__)
    kev.data = 1;
#else
    kev.data = 2;
#endif

    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1); /* data is pending, so we should get an event */
    kevent_cmp(&kev, ret);

    /* We filled twice, but drain once. Edge-triggered would not generate
       additional events.
     */
    kevent_socket_drain(ctx);   /* drain one byte, data is still pending... */
    test_no_kevents(ctx->kqfd); /* ...but because this is edge triggered we should get no events */

    kevent_socket_drain(ctx);
    EV_SET(&kev, ctx->client_fd, EVFILT_READ, EV_DELETE, 0, 0, &ctx->client_fd);
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));
}

void
test_kevent_socket_disable_and_enable(struct test_context *ctx)
{
    struct kevent kev, ret[1];

    /* Add an event, then disable it. */
    EV_SET(&kev, ctx->client_fd, EVFILT_READ, EV_ADD, 0, 0, &ctx->client_fd);
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));

    EV_SET(&kev, ctx->client_fd, EVFILT_READ, EV_DISABLE, 0, 0, &ctx->client_fd);
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));

    kevent_socket_fill(ctx, 1);
    test_no_kevents(ctx->kqfd);

    /* Re-enable the knote, then see if an event is generated */
    kev.flags = EV_ENABLE;
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));
    kev.flags = EV_ADD;
    kev.data = 1;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    kevent_socket_drain(ctx);

    kev.flags = EV_DELETE;
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));
}

void
test_kevent_socket_del(struct test_context *ctx)
{
    struct kevent kev;

    EV_SET(&kev, ctx->client_fd, EVFILT_READ, EV_DELETE, 0, 0, &ctx->client_fd);
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));
    kevent_socket_fill(ctx, 1);
    test_no_kevents(ctx->kqfd);
    kevent_socket_drain(ctx);
}

void
test_kevent_socket_oneshot(struct test_context *ctx)
{
    struct kevent kev, ret[1];

    /* Re-add the watch and make sure no events are pending */
    kevent_add(ctx->kqfd, &kev, ctx->client_fd, EVFILT_READ, EV_ADD | EV_ONESHOT, 0, 0, &ctx->client_fd);
    test_no_kevents(ctx->kqfd);

    kevent_socket_fill(ctx, 1);
    kev.data = 1;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    test_no_kevents(ctx->kqfd);

    /* Verify that the kernel watch has been deleted */
    kevent_socket_fill(ctx, 1);
    test_no_kevents(ctx->kqfd);
    kevent_socket_drain(ctx);

    /* Verify that the kevent structure does not exist. */
    kev.flags = EV_DELETE;
    kevent_rv_cmp(-1, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));
}

/*
 * Test if the data field returns 1 when a listen(2) socket has
 * a pending connection.
 */
void
test_kevent_socket_listen_backlog(struct test_context *ctx)
{
    struct kevent kev, ret[1];
    struct sockaddr_in sain;
    socklen_t sa_len = sizeof(sain);
    int one = 1;
    short port;
    int clnt, srvr;

    /* Create a passive socket */
    memset(&sain, 0, sizeof(sain));
    sain.sin_family = AF_INET;
    sain.sin_port = 0;
    if ((srvr = socket(PF_INET, SOCK_STREAM, 0)) < 0)
        err(1, "socket()");
    if (setsockopt(srvr, SOL_SOCKET, SO_REUSEADDR,
                (char *) &one, sizeof(one)) != 0)
        err(1, "setsockopt()");
    if (bind(srvr, (struct sockaddr *) &sain, sa_len) < 0)
        err(1, "bind-2");
    if (getsockname(srvr, (struct sockaddr *) &sain, &sa_len) < 0)
        err(1, "getsockname-2");
    port = ntohs(sain.sin_port);
    if (listen(srvr, 100) < 0)
        err(1, "listen()");

    /* Watch for events on the socket */
    test_no_kevents(ctx->kqfd);
    kevent_add(ctx->kqfd, &kev, srvr, EVFILT_READ, EV_ADD | EV_ONESHOT, 0, 0, NULL);
    test_no_kevents(ctx->kqfd);

    /* Simulate a client connecting to the server */
    sain.sin_family = AF_INET;
    sain.sin_port = htons(port);
    sain.sin_addr.s_addr = inet_addr("127.0.0.1");
    if ((clnt = socket(AF_INET, SOCK_STREAM, 0)) < 0)
        err(1, "socket()");
    if (connect(clnt, (struct sockaddr *) &sain, sa_len) < 0)
        err(1, "connect()");

    /* Verify that data=1 */
    kev.data = 1;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);
    test_no_kevents(ctx->kqfd);

    close(clnt);
    close(srvr);
}

#ifdef EV_DISPATCH
void
test_kevent_socket_dispatch(struct test_context *ctx)
{
    struct kevent kev, ret[1];

    /* Re-add the watch and make sure no events are pending */
    kevent_add(ctx->kqfd, &kev, ctx->client_fd, EVFILT_READ, EV_ADD | EV_DISPATCH, 0, 0, &ctx->client_fd);
    test_no_kevents(ctx->kqfd);

    /* The event will occur only once, even though EV_CLEAR is not
       specified. */
    kevent_socket_fill(ctx, 1);
    kev.data = 1;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);
    test_no_kevents(ctx->kqfd);

    /* Re-enable the kevent */
    /* FIXME- is EV_DISPATCH needed when rearming ? */
    kevent_add(ctx->kqfd, &kev, ctx->client_fd, EVFILT_READ, EV_ENABLE | EV_DISPATCH, 0, 0, &ctx->client_fd);
    kev.data = 1;
    kev.flags = EV_ADD | EV_DISPATCH;   /* FIXME: may not be portable */
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);
    test_no_kevents(ctx->kqfd);

    /* Since the knote is disabled, the EV_DELETE operation succeeds. */
    kevent_add(ctx->kqfd, &kev, ctx->client_fd, EVFILT_READ, EV_DELETE, 0, 0, &ctx->client_fd);

    kevent_socket_drain(ctx);
}
#endif  /* EV_DISPATCH */

#if BROKEN_ON_LINUX
void
test_kevent_socket_lowat(struct test_context *ctx)
{
    struct kevent kev, buf;

    test_begin(test_id);

    /* Re-add the watch and make sure no events are pending */
    puts("-- re-adding knote, setting low watermark to 2 bytes");
    EV_SET(&kev, ctx->client_fd, EVFILT_READ, EV_ADD | EV_ONESHOT, NOTE_LOWAT, 2, &ctx->client_fd);
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));
    test_no_kevents();

    puts("-- checking that one byte does not trigger an event..");
    kevent_socket_fill(ctx, 1);
    test_no_kevents();

    puts("-- checking that two bytes triggers an event..");
    kevent_socket_fill(ctx, 1);
    kevent_rv_cmp(1, kevent(ctx->kqfd, NULL, 0, &buf, 1, NULL));
    kevent_cmp(&kev, &buf);
    test_no_kevents();

    kevent_socket_drain(ctx);
    kevent_socket_drain(ctx);
}
#endif

void
test_kevent_socket_eof_clear(struct test_context *ctx)
{
    struct kevent kev, ret[1];
    uint8_t buff[1024];

    kevent_add(ctx->kqfd, &kev, ctx->client_fd, EVFILT_READ, EV_ADD | EV_CLEAR, 0, 0, &ctx->client_fd);
    test_no_kevents(ctx->kqfd);

    if (shutdown(ctx->server_fd, SHUT_RDWR) < 0)
        die("shutdown(2)");
    if (close(ctx->server_fd) < 0)
        die("close(2)");

    kev.flags |= EV_EOF;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1); /* edge triggered means no more events */
    kevent_cmp(&kev, ret);

    test_no_kevents(ctx->kqfd);;

    /* Delete the watch */
    kevent_add(ctx->kqfd, &kev, ctx->client_fd, EVFILT_READ, EV_DELETE, 0, 0, &ctx->client_fd);

    close(ctx->client_fd);
    close(ctx->listen_fd);

    /* Recreate the socket pair */
    create_socket_connection(&ctx->client_fd, &ctx->server_fd, &ctx->listen_fd);
}

/*
 * Different from the pipe eof test, as we get EPOLLRDHUP with EPOLLIN on close
 * on Linux.
 */
void
test_kevent_socket_eof(struct test_context *ctx)
{
    struct kevent kev, ret[10];
    uint8_t buff[1024];

    kevent_add_with_receipt(ctx->kqfd, &kev, ctx->client_fd, EVFILT_READ, EV_ADD, 0, 0, &ctx->client_fd);
    test_no_kevents(ctx->kqfd);

    if (shutdown(ctx->server_fd, SHUT_RDWR) < 0)
        die("shutdown(2)");

    kev.flags |= EV_EOF;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    /* Will repeatedly return EOF */
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    /*
     * The kqueue man page on FreeBSD states that EV_CLEAR
     * can be used to clear EOF, but in practice this appears
     * to do nothing with sockets...
     *
     * Additionally setting EV_CLEAR on a socket after it's
     * been added does nothing, even though kqueue returns
     * the flag with EV_RECEIPT.
     */
    kevent_add(ctx->kqfd, &kev, ctx->client_fd, EVFILT_READ, EV_ADD | EV_CLEAR, 0, 0, &ctx->client_fd);

    kev.flags |= EV_RECEIPT;
    kev.flags |= EV_EOF;
    kev.flags ^= EV_CLEAR;

    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    kevent_add(ctx->kqfd, &kev, ctx->client_fd, EVFILT_READ, EV_DELETE, 0, 0, NULL);

    close(ctx->client_fd);
    close(ctx->server_fd);
    close(ctx->listen_fd);

    /* Recreate the socket pair */
    create_socket_connection(&ctx->client_fd, &ctx->server_fd, &ctx->listen_fd);
}

/*
 * Different from the socket eof test, as we get EPOLLHUP with no EPOLLIN on close
 * on Linux.
 */
void
test_kevent_pipe_eof(struct test_context *ctx)
{
    struct kevent kev, ret[256];
    int pipefd[2];
    uint8_t buff[1024];

    if (pipe(pipefd) < 0)
        die("pipe(2)");

    kevent_add_with_receipt(ctx->kqfd, &kev, pipefd[0], EVFILT_READ, EV_ADD, 0, 0, &pipefd[0]);
    test_no_kevents(ctx->kqfd);

    if (close(pipefd[1]) < 0)
        die("close(2)");

    kev.flags |= EV_EOF;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    /* Will repeatedly return EOF */
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    /*
     * The kqueue man page on FreeBSD states that EV_CLEAR
     * can be used to clear EOF, but in practice this appears
     * to do nothing with sockets...
     *
     * Additionally setting EV_CLEAR on a socket after it's
     * been added does nothing, even though kqueue returns
     * the flag with EV_RECEIPT.
     */
    kevent_add(ctx->kqfd, &kev, pipefd[0], EVFILT_READ, EV_ADD | EV_CLEAR, 0, 0, &pipefd[0]);

    kev.flags |= EV_RECEIPT;
    kev.flags |= EV_EOF;
    kev.flags ^= EV_CLEAR;

    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    kevent_add(ctx->kqfd, &kev, pipefd[0], EVFILT_READ, EV_DELETE, 0, 0, NULL);

    close(pipefd[0]);
    close(pipefd[1]);
}

void
test_kevent_pipe_eof_multi(struct test_context *ctx)
{
    struct kevent kev, ret[256];
    int pipefd_a[2], pipefd_b[2];
    uint8_t buff[1024];

    if (pipe(pipefd_a) < 0)
        die("pipe(2)");

    if (pipe(pipefd_b) < 0)
        die("pipe(2)");

    kevent_add_with_receipt(ctx->kqfd, &kev, pipefd_a[0], EVFILT_READ, EV_ADD, 0, 0, &pipefd_a[0]);
    kevent_add_with_receipt(ctx->kqfd, &kev, pipefd_b[0], EVFILT_READ, EV_ADD, 0, 0, &pipefd_b[0]);
    test_no_kevents(ctx->kqfd);

    if (close(pipefd_a[1]) < 0)
        die("close(2)");
    if (close(pipefd_b[1]) < 0)
        die("close(2)");

    kev.flags |= EV_EOF;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 2);

    kev.ident = ret[0].ident;
    kevent_cmp(&kev, &ret[0]);

    kev.ident = ret[1].ident;
    kevent_cmp(&kev, &ret[1]);

    /* Will repeatedly return EOF */
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 2);

    kev.ident = ret[0].ident;
    kevent_cmp(&kev, &ret[0]);

    kev.ident = ret[1].ident;
    kevent_cmp(&kev, &ret[1]);

    kevent_add(ctx->kqfd, &kev, pipefd_a[0], EVFILT_READ, EV_DELETE, 0, 0, NULL);
    kevent_add(ctx->kqfd, &kev, pipefd_b[0], EVFILT_READ, EV_DELETE, 0, 0, NULL);

    close(pipefd_a[0]);
    close(pipefd_a[1]);
    close(pipefd_b[0]);
    close(pipefd_b[1]);
}

/* Test if EVFILT_READ works with regular files */
void
test_kevent_regular_file(struct test_context *ctx)
{
    struct kevent kev, ret[1];
    off_t curpos;
    int fd;

    fd = open("/etc/hosts", O_RDONLY);
    if (fd < 0)
        abort();

    EV_SET(&kev, fd, EVFILT_READ, EV_ADD, 0, 0, &fd);
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);

    /* Set file position to EOF-1 */
    ret->data--;
    if ((curpos = lseek(fd, ret->data, SEEK_SET)) != ret->data) {
        printf("seek to %u failed with rv=%lu\n",
                (unsigned int) ret->data, (unsigned long) curpos);
        abort();
    }

    /* Set file position to EOF */
    kevent_get(NULL, 0, ctx->kqfd, 1);
    ret->data = curpos + 1;
    if ((curpos = lseek(fd, ret->data, SEEK_SET)) != ret->data) {
        printf("seek to %u failed with rv=%lu\n",
                (unsigned int) ret->data, (unsigned long) curpos);
        abort();
    }

    test_no_kevents(ctx->kqfd);

    kev.flags = EV_DELETE;
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));

    close(fd);
}

/* Test transitioning a socket from EVFILT_WRITE to EVFILT_READ */
void
test_transition_from_write_to_read(struct test_context *ctx)
{
    struct kevent kev, ret[1];
    int kqfd;
    int sd[2];

    (void) ctx;
    if ((kqfd = kqueue()) < 0)
        err(1, "kqueue");

    if (socketpair(AF_LOCAL, SOCK_STREAM, 0, sd))
        err(1, "socketpair");

    EV_SET(&kev, sd[0], EVFILT_WRITE, EV_ADD, 0, 0, NULL);
    kevent_rv_cmp(0, kevent(kqfd, &kev, 1, NULL, 0, NULL));

    EV_SET(&kev, sd[0], EVFILT_READ, EV_ADD, 0, 0, NULL);
    kevent_rv_cmp(0, kevent(kqfd, &kev, 1, NULL, 0, NULL));

    close(sd[0]);
    close(sd[1]);
    close(kqfd);
}

void
test_evfilt_read(struct test_context *ctx)
{
    create_socket_connection(&ctx->client_fd, &ctx->server_fd, &ctx->listen_fd);

    test(kevent_socket_add, ctx);
    test(kevent_socket_del, ctx);
    test(kevent_socket_add_without_ev_add, ctx);
    test(kevent_socket_get, ctx);
    test(kevent_socket_disable_and_enable, ctx);
    test(kevent_socket_oneshot, ctx);
    test(kevent_socket_clear, ctx);
#ifdef EV_DISPATCH
    test(kevent_socket_dispatch, ctx);
#endif
    test(kevent_socket_listen_backlog, ctx);
    test(kevent_socket_eof_clear, ctx);
    test(kevent_socket_eof, ctx);
    test(kevent_pipe_eof, ctx);
    test(kevent_pipe_eof_multi, ctx);
    test(kevent_regular_file, ctx);
    close(ctx->client_fd);
    close(ctx->server_fd);
    close(ctx->listen_fd);

    create_socket_connection(&ctx->client_fd, &ctx->server_fd, &ctx->listen_fd);
    test(transition_from_write_to_read, ctx);
    close(ctx->client_fd);
    close(ctx->server_fd);
    close(ctx->listen_fd);
}
