//from kern_event.c

/* XXX - ensure not KN_INFLUX?? */
#define KNOTE_ACTIVATE(kn, islock) do {                                 \
        if ((islock))                                                   \
                mtx_assert(&(kn)->kn_kq->kq_lock, MA_OWNED);            \
        else                                                            \
                KQ_LOCK((kn)->kn_kq);                                   \
        (kn)->kn_status |= KN_ACTIVE;                                   \
        if (((kn)->kn_status & (KN_QUEUED | KN_DISABLED)) == 0)         \
                knote_enqueue((kn));                                    \
        if (!(islock))                                                  \
                KQ_UNLOCK((kn)->kn_kq);                                 \
} while(0)
#define KQ_LOCK(kq) do {                                                \
        mtx_lock(&(kq)->kq_lock);                                       \
} while (0)
#define KQ_FLUX_WAKEUP(kq) do {                                         \
        if (((kq)->kq_state & KQ_FLUXWAIT) == KQ_FLUXWAIT) {            \
                (kq)->kq_state &= ~KQ_FLUXWAIT;                         \
                wakeup((kq));                                           \
        }                                                               \
} while (0)
#define KQ_UNLOCK_FLUX(kq) do {                                         \
        KQ_FLUX_WAKEUP(kq);                                             \
        mtx_unlock(&(kq)->kq_lock);                                     \
} while (0)
#define KQ_UNLOCK(kq) do {                                              \
        mtx_unlock(&(kq)->kq_lock);                                     \
} while (0)
#define KQ_OWNED(kq) do {                                               \
        mtx_assert(&(kq)->kq_lock, MA_OWNED);                           \
} while (0)
#define KQ_NOTOWNED(kq) do {                                            \
        mtx_assert(&(kq)->kq_lock, MA_NOTOWNED);                        \
} while (0)
#define KN_LIST_LOCK(kn) do {                                           \
        if (kn->kn_knlist != NULL)                                      \
                kn->kn_knlist->kl_lock(kn->kn_knlist->kl_lockarg);      \
} while (0)
#define KN_LIST_UNLOCK(kn) do {                                         \
        if (kn->kn_knlist != NULL)                                      \
                kn->kn_knlist->kl_unlock(kn->kn_knlist->kl_lockarg);    \
} while (0)
#define KNL_ASSERT_LOCK(knl, islocked) do {                             \
        if (islocked)                                                   \
                KNL_ASSERT_LOCKED(knl);                         \
        else                                                            \
                KNL_ASSERT_UNLOCKED(knl);                               \
} while (0)
#ifdef INVARIANTS
#define KNL_ASSERT_LOCKED(knl) do {                                     \
        knl->kl_assert_locked((knl)->kl_lockarg);                       \
} while (0)
#define KNL_ASSERT_UNLOCKED(knl) do {                                   \
        knl->kl_assert_unlocked((knl)->kl_lockarg);                     \
} while (0)
#else /* !INVARIANTS */
#define KNL_ASSERT_LOCKED(knl) do {} while(0)
#define KNL_ASSERT_UNLOCKED(knl) do {} while (0)
#endif /* INVARIANTS */

#define KN_HASHSIZE             64              /* XXX should be tunable */
#define KN_HASH(val, mask)      (((val) ^ (val >> 8)) & (mask))

/*
 * add a knote to a knlist
 */
void
knlist_add(struct knlist *knl, struct knote *kn, int islocked)
{
        KNL_ASSERT_LOCK(knl, islocked);
        KQ_NOTOWNED(kn->kn_kq);
        KASSERT((kn->kn_status & (KN_INFLUX|KN_DETACHED)) ==
            (KN_INFLUX|KN_DETACHED), ("knote not KN_INFLUX and KN_DETACHED"));
        if (!islocked)
                knl->kl_lock(knl->kl_lockarg);
        SLIST_INSERT_HEAD(&knl->kl_list, kn, kn_selnext);
        if (!islocked)
                knl->kl_unlock(knl->kl_lockarg);
        KQ_LOCK(kn->kn_kq);
        kn->kn_knlist = knl;
        kn->kn_status &= ~KN_DETACHED;
        KQ_UNLOCK(kn->kn_kq);
}

static void
knlist_remove_kq(struct knlist *knl, struct knote *kn, int knlislocked, int kqislocked)
{
        KASSERT(!(!!kqislocked && !knlislocked), ("kq locked w/o knl locked"));
        KNL_ASSERT_LOCK(knl, knlislocked);
        mtx_assert(&kn->kn_kq->kq_lock, kqislocked ? MA_OWNED : MA_NOTOWNED);
        if (!kqislocked)
                KASSERT((kn->kn_status & (KN_INFLUX|KN_DETACHED)) == KN_INFLUX,
    ("knlist_remove called w/o knote being KN_INFLUX or already removed"));
        if (!knlislocked)
                knl->kl_lock(knl->kl_lockarg);
        SLIST_REMOVE(&knl->kl_list, kn, knote, kn_selnext);
        kn->kn_knlist = NULL;
        if (!knlislocked)
                knl->kl_unlock(knl->kl_lockarg);
        if (!kqislocked)
                KQ_LOCK(kn->kn_kq);
        kn->kn_status |= KN_DETACHED;
        if (!kqislocked)
                KQ_UNLOCK(kn->kn_kq);
}

/*
 * remove all knotes from a specified klist
 */
void
knlist_remove(struct knlist *knl, struct knote *kn, int islocked)
{

        knlist_remove_kq(knl, kn, islocked, 0);
}

/*
 * remove knote from a specified klist while in f_event handler.
 */
void
knlist_remove_inevent(struct knlist *knl, struct knote *kn)
{

        knlist_remove_kq(knl, kn, 1,
            (kn->kn_status & KN_HASKQLOCK) == KN_HASKQLOCK);
}

int
knlist_empty(struct knlist *knl)
{
        KNL_ASSERT_LOCKED(knl);
        return SLIST_EMPTY(&knl->kl_list);
}

static struct mtx       knlist_lock;
MTX_SYSINIT(knlist_lock, &knlist_lock, "knlist lock for lockless objects",
        MTX_DEF);
static void knlist_mtx_lock(void *arg);
static void knlist_mtx_unlock(void *arg);

static void
knlist_mtx_lock(void *arg)
{
        mtx_lock((struct mtx *)arg);
}

static void
knlist_mtx_unlock(void *arg)
{
        mtx_unlock((struct mtx *)arg);
}

static void
knlist_mtx_assert_locked(void *arg)
{
        mtx_assert((struct mtx *)arg, MA_OWNED);
}

static void
knlist_mtx_assert_unlocked(void *arg)
{
        mtx_assert((struct mtx *)arg, MA_NOTOWNED);
}

void
knlist_init(struct knlist *knl, void *lock, void (*kl_lock)(void *),
    void (*kl_unlock)(void *),
    void (*kl_assert_locked)(void *), void (*kl_assert_unlocked)(void *))
{

        if (lock == NULL)
                knl->kl_lockarg = &knlist_lock;
        else
                knl->kl_lockarg = lock;

        if (kl_lock == NULL)
                knl->kl_lock = knlist_mtx_lock;
        else
                knl->kl_lock = kl_lock;
        if (kl_unlock == NULL)
                knl->kl_unlock = knlist_mtx_unlock;
        else
                knl->kl_unlock = kl_unlock;
        if (kl_assert_locked == NULL)
                knl->kl_assert_locked = knlist_mtx_assert_locked;
        else
                knl->kl_assert_locked = kl_assert_locked;
        if (kl_assert_unlocked == NULL)
                knl->kl_assert_unlocked = knlist_mtx_assert_unlocked;
        else
                knl->kl_assert_unlocked = kl_assert_unlocked;

        SLIST_INIT(&knl->kl_list);
}

void
knlist_init_mtx(struct knlist *knl, struct mtx *lock)
{

        knlist_init(knl, lock, NULL, NULL, NULL, NULL);
}

void
knlist_destroy(struct knlist *knl)
{

#ifdef INVARIANTS
        /*
         * if we run across this error, we need to find the offending
         * driver and have it call knlist_clear.
         */
        if (!SLIST_EMPTY(&knl->kl_list))
                printf("WARNING: destroying knlist w/ knotes on it!\n");
#endif

        knl->kl_lockarg = knl->kl_lock = knl->kl_unlock = NULL;
        SLIST_INIT(&knl->kl_list);
}

/*
 * Even if we are locked, we may need to drop the lock to allow any influx
 * knotes time to "settle".
 */
void
knlist_cleardel(struct knlist *knl, struct thread *td, int islocked, int killkn)
{
        struct knote *kn, *kn2;
        struct kqueue *kq;

        if (islocked)
                KNL_ASSERT_LOCKED(knl);
        else {
                KNL_ASSERT_UNLOCKED(knl);
again:          /* need to reacquire lock since we have dropped it */
                knl->kl_lock(knl->kl_lockarg);
        }

        SLIST_FOREACH_SAFE(kn, &knl->kl_list, kn_selnext, kn2) {
                kq = kn->kn_kq;
                KQ_LOCK(kq);
                if ((kn->kn_status & KN_INFLUX)) {
                        KQ_UNLOCK(kq);
                        continue;
                }
                knlist_remove_kq(knl, kn, 1, 1);
                if (killkn) {
                        kn->kn_status |= KN_INFLUX | KN_DETACHED;
                        KQ_UNLOCK(kq);
                        knote_drop(kn, td);
                } else {
                        /* Make sure cleared knotes disappear soon */
                        kn->kn_flags |= (EV_EOF | EV_ONESHOT);
                        KQ_UNLOCK(kq);
                }
                kq = NULL;
        }

        if (!SLIST_EMPTY(&knl->kl_list)) {
                /* there are still KN_INFLUX remaining */
                kn = SLIST_FIRST(&knl->kl_list);
                kq = kn->kn_kq;
                KQ_LOCK(kq);
                KASSERT(kn->kn_status & KN_INFLUX,
                    ("knote removed w/o list lock"));
                knl->kl_unlock(knl->kl_lockarg);
                kq->kq_state |= KQ_FLUXWAIT;
                msleep(kq, &kq->kq_lock, PSOCK | PDROP, "kqkclr", 0);
                kq = NULL;
                goto again;
        }

        if (islocked)
                KNL_ASSERT_LOCKED(knl);
        else {
                knl->kl_unlock(knl->kl_lockarg);
                KNL_ASSERT_UNLOCKED(knl);
        }
}

/*
 * Remove all knotes referencing a specified fd must be called with FILEDESC
 * lock.  This prevents a race where a new fd comes along and occupies the
 * entry and we attach a knote to the fd.
 */
void
knote_fdclose(struct thread *td, int fd)
{
        struct filedesc *fdp = td->td_proc->p_fd;
        struct kqueue *kq;
        struct knote *kn;
        int influx;

        FILEDESC_XLOCK_ASSERT(fdp);

        /*
         * We shouldn't have to worry about new kevents appearing on fd
         * since filedesc is locked.
         */
                KNL_ASSERT_UNLOCKED(knl);
        }
}

/*
 * Remove all knotes referencing a specified fd must be called with FILEDESC
 * lock.  This prevents a race where a new fd comes along and occupies the
 * entry and we attach a knote to the fd.
 */
void
knote_fdclose(struct thread *td, int fd)
{
        struct filedesc *fdp = td->td_proc->p_fd;
        struct kqueue *kq;
        struct knote *kn;
        int influx;

        FILEDESC_XLOCK_ASSERT(fdp);

        /*
         * We shouldn't have to worry about new kevents appearing on fd
         * since filedesc is locked.
         */
        SLIST_FOREACH(kq, &fdp->fd_kqlist, kq_list) {
                KQ_LOCK(kq);

again:
                influx = 0;
                while (kq->kq_knlistsize > fd &&
                    (kn = SLIST_FIRST(&kq->kq_knlist[fd])) != NULL) {
                        if (kn->kn_status & KN_INFLUX) {
                                /* someone else might be waiting on our knote */
                                if (influx)
                                        wakeup(kq);
                                kq->kq_state |= KQ_FLUXWAIT;
                                msleep(kq, &kq->kq_lock, PSOCK, "kqflxwt", 0);
                                goto again;
                        }
                        kn->kn_status |= KN_INFLUX;
                        KQ_UNLOCK(kq);
                        if (!(kn->kn_status & KN_DETACHED))
                                kn->kn_fop->f_detach(kn);
                        knote_drop(kn, td);
                        influx = 1;
                        KQ_LOCK(kq);
                }
                KQ_UNLOCK_FLUX(kq);
        }
}

static int
knote_attach(struct knote *kn, struct kqueue *kq)
{
        struct klist *list;

        KASSERT(kn->kn_status & KN_INFLUX, ("knote not marked INFLUX"));
        KQ_OWNED(kq);

        if (kn->kn_fop->f_isfd) {
                if (kn->kn_id >= kq->kq_knlistsize)
                        return ENOMEM;
                list = &kq->kq_knlist[kn->kn_id];
        } else {
                if (kq->kq_knhash == NULL)
                        return ENOMEM;
                list = &kq->kq_knhash[KN_HASH(kn->kn_id, kq->kq_knhashmask)];
        }

        SLIST_INSERT_HEAD(list, kn, kn_link);
#ifdef INVARIANTS
        /*
         * if we run across this error, we need to find the offending
         * driver and have it call knlist_clear.
         */
        if (!SLIST_EMPTY(&knl->kl_list))
                printf("WARNING: destroying knlist w/ knotes on it!\n");
#endif

        knl->kl_lockarg = knl->kl_lock = knl->kl_unlock = NULL;
        SLIST_INIT(&knl->kl_list);
}

/*
 * Even if we are locked, we may need to drop the lock to allow any influx
 * knotes time to "settle".
 */
void
knlist_cleardel(struct knlist *knl, struct thread *td, int islocked, int killkn)
{
        struct knote *kn, *kn2;
        struct kqueue *kq;

        if (islocked)
                KNL_ASSERT_LOCKED(knl);
        else {
                KNL_ASSERT_UNLOCKED(knl);
again:          /* need to reacquire lock since we have dropped it */
                knl->kl_lock(knl->kl_lockarg);
        }

        SLIST_FOREACH_SAFE(kn, &knl->kl_list, kn_selnext, kn2) {
                kq = kn->kn_kq;
                KQ_LOCK(kq);
                if ((kn->kn_status & KN_INFLUX)) {
                        KQ_UNLOCK(kq);
                        continue;
                }
                knlist_remove_kq(knl, kn, 1, 1);
                if (killkn) {
                        kn->kn_status |= KN_INFLUX | KN_DETACHED;
                        KQ_UNLOCK(kq);
                        knote_drop(kn, td);
                } else {
                        /* Make sure cleared knotes disappear soon */
                        kn->kn_flags |= (EV_EOF | EV_ONESHOT);
                        KQ_UNLOCK(kq);
                }
                kq = NULL;
        }

        if (!SLIST_EMPTY(&knl->kl_list)) {
                /* there are still KN_INFLUX remaining */
                kn = SLIST_FIRST(&knl->kl_list);
                kq = kn->kn_kq;
                KQ_LOCK(kq);
                KASSERT(kn->kn_status & KN_INFLUX,
                    ("knote removed w/o list lock"));
                knl->kl_unlock(knl->kl_lockarg);
                kq->kq_state |= KQ_FLUXWAIT;
                msleep(kq, &kq->kq_lock, PSOCK | PDROP, "kqkclr", 0);
                kq = NULL;
                goto again;
        }

        if (islocked)
                KNL_ASSERT_LOCKED(knl);
        else {
                knl->kl_unlock(knl->kl_lockarg);
                KNL_ASSERT_UNLOCKED(knl);
        }
}

