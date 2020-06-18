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

#include "private.h"

#if HAVE_SYS_SIGNALFD_H
# include <sys/signalfd.h>
#else
#define signalfd(a,b,c) syscall(SYS_signalfd, (a), (b), (c))
#define SFD_NONBLOCK 04000
struct signalfd_siginfo
{
  uint32_t ssi_signo;
  int32_t ssi_errno;
  int32_t ssi_code;
  uint32_t ssi_pid;
  uint32_t ssi_uid;
  int32_t ssi_fd;
  uint32_t ssi_tid;
  uint32_t ssi_band;
  uint32_t ssi_overrun;
  uint32_t ssi_trapno;
  int32_t ssi_status;
  int32_t ssi_int;
  uint64_t ssi_ptr;
  uint64_t ssi_utime;
  uint64_t ssi_stime;
  uint64_t ssi_addr;
  uint8_t __pad[48];
};
#endif

static void
signalfd_reset(int sigfd)
{
    struct signalfd_siginfo sig;
    ssize_t n;

    /* Discard any pending signal */
    n = read(sigfd, &sig, sizeof(sig));
    if (n < 0 || n != sizeof(sig)) {
        if (errno == EWOULDBLOCK)
            return;
        //FIXME: eintr?
        dbg_perror("read(2) from signalfd");
        abort();
    }
}

static int
signalfd_add(int epoll_fd, int sigfd, struct knote *kn)
{
    int rv;

    /* Add the signalfd to the kqueue's epoll descriptor set */
    KN_UDATA(kn);   /* populate this knote's kn_udata field */
    rv = epoll_ctl(epoll_fd, EPOLL_CTL_ADD, sigfd, EPOLL_EV_KN(EPOLLIN, kn));
    if (rv < 0) {
        dbg_perror("epoll_ctl(2)");
        return (-1);
    }

    return (0);
}

static int
signalfd_create(int epoll_fd, struct knote *kn, int signum)
{
    static int flags = SFD_NONBLOCK;
    sigset_t sigmask;
    int sigfd;

    /* Create a signalfd */
    sigemptyset(&sigmask);
    sigaddset(&sigmask, signum);
    sigfd = signalfd(-1, &sigmask, flags);

    /* WORKAROUND: Flags are broken on kernels older than Linux 2.6.27 */
    if (sigfd < 0 && errno == EINVAL && flags != 0) {
        flags = 0;
        sigfd = signalfd(-1, &sigmask, flags);
    }
    if (sigfd < 0) {
        if ((errno == EMFILE) || (errno == ENFILE)) {
            dbg_perror("signalfd(2) fd_used=%u fd_max=%u", get_fd_used(), get_fd_limit());
        } else {
            dbg_perror("signalfd(2)");
        }
        goto errout;
    }

    /* Block the signal handler from being invoked */
    if (sigprocmask(SIG_BLOCK, &sigmask, NULL) < 0) {
        dbg_perror("sigprocmask(2)");
        goto errout;
    }

    signalfd_reset(sigfd);

    if (signalfd_add(epoll_fd, sigfd, kn) < 0)
        goto errout;

    dbg_printf("sig_fd=%d - sigfd added to epoll_fd=%d (signum=%d)", sigfd, epoll_fd, signum);

    return (sigfd);

errout:
    (void) close(sigfd);
    return (-1);
}

int
evfilt_signal_copyout(struct kevent *dst, struct knote *src, void *x UNUSED)
{
    int sigfd;

    sigfd = src->kdata.kn_signalfd;

    signalfd_reset(sigfd);

    memcpy(dst, &src->kev, sizeof(*dst));
    /* NOTE: dst->data should be the number of times the signal occurred,
       but that information is not available.
     */
    dst->data = 1;

    return (0);
}

int
evfilt_signal_knote_create(struct filter *filt, struct knote *kn)
{
    int fd;

    fd = signalfd_create(filter_epoll_fd(filt), kn, kn->kev.ident);
    if (fd > 0) {
        kn->kev.flags |= EV_CLEAR;
        kn->kdata.kn_signalfd = fd;
        return (0);
    } else {
        kn->kdata.kn_signalfd = -1;
        return (-1);
    }
}

int
evfilt_signal_knote_modify(struct filter *filt UNUSED,
        struct knote *kn UNUSED,
        const struct kevent *kev UNUSED)
{
    /* Nothing to do since the signal number does not change. */

    return (0);
}

int
evfilt_signal_knote_delete(struct filter *filt, struct knote *kn)
{
    const int sigfd = kn->kdata.kn_signalfd;
    int       rv = 0;

    /* Needed so that delete() can be called after disable() */
    if (kn->kdata.kn_signalfd == -1)
        return (0);

    rv = epoll_ctl(filter_epoll_fd(filt), EPOLL_CTL_DEL, sigfd, NULL);
    if (rv < 0) {
        dbg_perror("epoll_ctl(2)");
    } else {
        dbg_printf("sig_fd=%i - removed from epoll_fd=%i", sigfd, filter_epoll_fd(filt));
    }

    dbg_printf("sig_fd=%d - closed", sigfd);
    if (close(sigfd) < 0) {
        dbg_perror("close(2)");
        return (-1);
    }

    /* NOTE: This does not call sigprocmask(3) to unblock the signal. */
    kn->kdata.kn_signalfd = -1;

    return (rv);
}

int
evfilt_signal_knote_enable(struct filter *filt, struct knote *kn)
{
    return evfilt_signal_knote_create(filt, kn);
}

int
evfilt_signal_knote_disable(struct filter *filt, struct knote *kn)
{
    return evfilt_signal_knote_delete(filt, kn);
}


const struct filter evfilt_signal = {
    .kf_id      = EVFILT_SIGNAL,
    .kf_copyout = evfilt_signal_copyout,
    .kn_create  = evfilt_signal_knote_create,
    .kn_modify  = evfilt_signal_knote_modify,
    .kn_delete  = evfilt_signal_knote_delete,
    .kn_enable  = evfilt_signal_knote_enable,
    .kn_disable = evfilt_signal_knote_disable,
};
