/*
 * Copyright (c) 2011 Mark Heily <mark@heily.com>
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

/* Highest signal number supported. POSIX standard signals are < 32 */
#define SIGNAL_MAX      32

struct sentry {
    struct filter  *s_filt;
    struct knote   *s_knote;
    volatile uint32_t s_cnt;
};

static pthread_mutex_t sigtbl_mtx = PTHREAD_MUTEX_INITIALIZER;
static struct sentry sigtbl[SIGNAL_MAX];

static void
signal_handler(int sig)
{
    struct sentry *s;
   
    if (sig < 0 || sig > SIGNAL_MAX)
        abort();

    s = &sigtbl[sig];
    atomic_inc(&s->s_cnt);
    port_send(filter_epfd(s->s_filt), X_PORT_SOURCE_SIGNAL, &sigtbl[sig]);
    /* TODO: crash if port_send() fails? */
}

static int
catch_signal(struct filter *filt, struct knote *kn)
{
	int sig;
	struct sigaction sa;
    
    sig = kn->kev.ident;
	memset(&sa, 0, sizeof(sa));
	sa.sa_handler = signal_handler;
	sa.sa_flags |= SA_RESTART;
	sigfillset(&sa.sa_mask);

	if (sigaction(kn->kev.ident, &sa, NULL) == -1) {
		dbg_perror("sigaction");
		return (-1);
	}
    /* FIXME: will clobber previous entry, if any */
    pthread_mutex_lock(&sigtbl_mtx);
    sigtbl[kn->kev.ident].s_filt = filt;
    sigtbl[kn->kev.ident].s_knote = kn;
    pthread_mutex_unlock(&sigtbl_mtx);

    dbg_printf("installed handler for signal %d", sig);
    return (0);
}

static int
ignore_signal(int sig)
{
	struct sigaction sa;
    
	memset(&sa, 0, sizeof(sa));
	sa.sa_handler = SIG_IGN;
	sigemptyset(&sa.sa_mask);

	if (sigaction(sig, &sa, NULL) == -1) {
		dbg_perror("sigaction");
		return (-1);
	}
    pthread_mutex_lock(&sigtbl_mtx);
    sigtbl[sig].s_filt = NULL;
    sigtbl[sig].s_knote = NULL;
    pthread_mutex_unlock(&sigtbl_mtx);

    dbg_printf("removed handler for signal %d", sig);
    return (0);
}

int
evfilt_signal_knote_create(struct filter *filt, struct knote *kn)
{
    if (kn->kev.ident >= SIGNAL_MAX) {
        dbg_printf("unsupported signal number %u", 
                    (unsigned int) kn->kev.ident);
        return (-1);
    }

    kn->kev.flags |= EV_CLEAR;

    return catch_signal(filt, kn);
}

int
evfilt_signal_knote_modify(struct filter *filt, struct knote *kn, 
                const struct kevent *kev)
{
    kn->kev.flags = kev->flags | EV_CLEAR;
    return (0);
}

int
evfilt_signal_knote_delete(struct filter *filt, struct knote *kn)
{   
    return ignore_signal(kn->kev.ident);
}

int
evfilt_signal_knote_enable(struct filter *filt, struct knote *kn)
{
    return catch_signal(filt, kn);
}

int
evfilt_signal_knote_disable(struct filter *filt, struct knote *kn)
{
    return ignore_signal(kn->kev.ident);
}

int
evfilt_signal_copyout(struct kevent *dst, struct knote *src, void *ptr)
{
    dst->ident = src->kev.ident;
    dst->filter = EVFILT_SIGNAL;
    dst->udata = src->kev.udata;
    dst->flags = src->kev.flags; 
    dst->fflags = 0;
    dst->data = 1;

    if (src->kev.flags & EV_DISPATCH || src->kev.flags & EV_ONESHOT) 
        ignore_signal(src->kev.ident);

    return (1);
}

const struct filter evfilt_signal = {
    EVFILT_SIGNAL,
    NULL,
    NULL,
    evfilt_signal_copyout,
    evfilt_signal_knote_create,
    evfilt_signal_knote_modify,
    evfilt_signal_knote_delete,
    evfilt_signal_knote_enable,
    evfilt_signal_knote_disable,     
};
