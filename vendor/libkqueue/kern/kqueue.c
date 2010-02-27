/*-
 * Copyright (c) 2010 Mark Heily <mark@heily.com>
 *
 * Includes portions of /usr/src/sys/kern/kern_event.c which is
 *
 * Copyright (c) 1999,2000,2001 Jonathan Lemon <jlemon@FreeBSD.org>
 * Copyright 2004 John-Mark Gurney <jmg@FreeBSD.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* Portions based on
   $FreeBSD: src/sys/kern/kern_event.c,v 1.126.2.1.2.1 2009/10/25 01:10:29 kensmith Exp $
 */

#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/kthread.h>
#include <linux/module.h>
#include <linux/syscalls.h>
#include <linux/uaccess.h>

#include "../include/sys/event.h"
#include "queue.h"

static int kqueue_open (struct inode *inode, struct file *file);
static int kqueue_release (struct inode *inode, struct file *file);
static int kqueue_ioctl(struct inode *inode, struct file *file,
        unsigned int cmd, unsigned long arg);
static ssize_t kqueue_read(struct file *file, char __user *buf, 
        size_t lbuf, loff_t *ppos);
static ssize_t kqueue_write(struct file *file, const char __user *buf, 
        size_t lbuf, loff_t *ppos);
 
struct file_operations fops = {
    .owner  =   THIS_MODULE,
    .ioctl	=   kqueue_ioctl,
    .open	=   kqueue_open,
    .release =  kqueue_release,
    .read	=   kqueue_read,
    .write	=   kqueue_write,
};

struct kqueue_data {
    spinlock_t  kq_lock;
};

/*
 * Flags for knote call
 */
#define KNF_LISTLOCKED  0x0001                  /* knlist is locked */
#define KNF_NOKQLOCK    0x0002                  /* do not keep KQ_LOCK */

#define KNOTE(list, hist, flags)        knote(list, hist, flags)
#define KNOTE_LOCKED(list, hint)        knote(list, hint, KNF_LISTLOCKED)
#define KNOTE_UNLOCKED(list, hint)      knote(list, hint, 0)

#define KNLIST_EMPTY(list)              SLIST_EMPTY(&(list)->kl_list)

/************* BEGIN COPY FROM sys/event.h ***************************/
struct knote;

/*
 * Flag indicating hint is a signal.  Used by EVFILT_SIGNAL, and also
 * shared by EVFILT_PROC  (all knotes attached to p->p_klist)
 */
#define NOTE_SIGNAL     0x08000000

struct filterops {
        int     f_isfd;         /* true if ident == filedescriptor */
        int     (*f_attach)(struct knote *kn);
        void    (*f_detach)(struct knote *kn);
        int     (*f_event)(struct knote *kn, long hint);
};

/*
 * Setting the KN_INFLUX flag enables you to unlock the kq that this knote
 * is on, and modify kn_status as if you had the KQ lock.
 *
 * kn_sfflags, kn_sdata, and kn_kevent are protected by the knlist lock.
 */
struct knote {
        SLIST_ENTRY(knote)      kn_link;        /* for kq */
        SLIST_ENTRY(knote)      kn_selnext;     /* for struct selinfo */
        struct                  knlist *kn_knlist;      /* f_attach populated */
        TAILQ_ENTRY(knote)      kn_tqe;
        struct                  kqueue *kn_kq;  /* which queue we are on */
        struct                  kevent kn_kevent;
        int                     kn_status;      /* protected by kq lock */
#define KN_ACTIVE       0x01                    /* event has been triggered */
#define KN_QUEUED       0x02                    /* event is on queue */
#define KN_DISABLED     0x04                    /* event is disabled */
#define KN_DETACHED     0x08                    /* knote is detached */
#define KN_INFLUX       0x10                    /* knote is in flux */
#define KN_MARKER       0x20                    /* ignore this knote */
#define KN_KQUEUE       0x40                    /* this knote belongs to a kq */
#define KN_HASKQLOCK    0x80                    /* for _inevent */
        int                     kn_sfflags;     /* saved filter flags */
        intptr_t                kn_sdata;       /* saved data field */
        union {
                struct          file *p_fp;     /* file data pointer */
                struct          proc *p_proc;   /* proc pointer */
                struct          aiocblist *p_aio;       /* AIO job pointer */
                struct          aioliojob *p_lio;       /* LIO job pointer */ 
        } kn_ptr;
        struct                  filterops *kn_fop;
        void                    *kn_hook;

#define kn_id           kn_kevent.ident
#define kn_filter       kn_kevent.filter
#define kn_flags        kn_kevent.flags
#define kn_fflags       kn_kevent.fflags
#define kn_data         kn_kevent.data
#define kn_fp           kn_ptr.p_fp
};
static void     filt_kqdetach(struct knote *kn);
static int      filt_kqueue(struct knote *kn, long hint);
static int      filt_procattach(struct knote *kn);
static void     filt_procdetach(struct knote *kn);
static int      filt_proc(struct knote *kn, long hint);
static int      filt_fileattach(struct knote *kn);
static void     filt_timerexpire(void *knx);
static int      filt_timerattach(struct knote *kn);
static void     filt_timerdetach(struct knote *kn);
static int      filt_timer(struct knote *kn, long hint);

static struct filterops file_filtops =
        { 1, filt_fileattach, NULL, NULL };
static struct filterops kqread_filtops =
        { 1, NULL, filt_kqdetach, filt_kqueue };
/* XXX - move to kern_proc.c?  */
static struct filterops proc_filtops =
        { 0, filt_procattach, filt_procdetach, filt_proc };
static struct filterops timer_filtops =
        { 0, filt_timerattach, filt_timerdetach, filt_timer };

/************* END COPY FROM sys/event.h ***************************/

struct kfilter {

    /* filter operations */

    int     (*kf_init)(struct filter *);
    void    (*kf_destroy)(struct filter *);
    int     (*kf_copyout)(struct filter *, struct kevent *, int);

    /* knote operations */

    int     (*kn_create)(struct filter *, struct knote *);
    int     (*kn_modify)(struct filter *, struct knote *, 
                            const struct kevent *);
    int     (*kn_delete)(struct filter *, struct knote *);
    int     (*kn_enable)(struct filter *, struct knote *);
    int     (*kn_disable)(struct filter *, struct knote *);

#if DEADWOOD
    struct eventfd *kf_efd;             /* Used by user.c */
    int       kf_pfd;                   /* fd to poll(2) for readiness */
    int       kf_wfd;                   /* fd to write when an event occurs */
    u_int     kf_timeres;               /* timer resolution, in miliseconds */
    sigset_t  kf_sigmask;
    struct evfilt_data *kf_data;	/* filter-specific data */
    RB_HEAD(knt, knote) kf_knote;
    TAILQ_HEAD(, knote)  kf_event;       /* events that have occurred */
    struct kqueue *kf_kqueue;
#endif
};

static int major;
static struct class *kqueue_class;
static struct task_struct *kq_thread;

//only for sleeping during testing
#include <linux/delay.h>
static int kqueue_main(void *arg)
{
    printk(KERN_INFO "kqueue thread started...\n");
    while (!kthread_should_stop()) {
        msleep(5000);
        printk(KERN_INFO "kqueue thread awake...\n");
    }
    printk(KERN_INFO "kqueue stopping...\n");

    return 0;
}

static int kqueue_open (struct inode *inode, struct file *file) 
{
    struct kqueue_data *kq;

    printk("kqueue_open\n");

    kq = kmalloc(sizeof(*kq), GFP_KERNEL);
    if (kq == NULL) {
        printk("kqueue: kmalloc failed\n");
        return -1;
    }
    spin_lock_init(&kq->kq_lock);
    file->private_data = kq;
    /* FIXME Unresolved symbols
    kq->kq_fd[0] = epoll_create1(0);
    kq->kq_fd[0] = sys_inotify_init();
    */

    return 0;
}

static int kqueue_release (struct inode *inode, struct file *file) 
{
    printk("kqueue_release\n");
    kfree(file->private_data);

    return 0;
}

static int kqueue_ioctl(struct inode *inode, struct file *file,
        unsigned int cmd, unsigned long arg) 
{
    int fd;

    if (copy_from_user(&fd, (int *)arg, sizeof(int)))
        return -EFAULT;

    printk(KERN_INFO "added fd %d\n", fd);

    return 0;
}

static ssize_t kqueue_read(struct file *file, char __user *buf, 
        size_t lbuf, loff_t *ppos)
{
    struct kqueue_data *kq = file->private_data;

    spin_lock(&kq->kq_lock);
    //STUB
    spin_unlock(&kq->kq_lock);

    return sizeof(struct kevent);
}

static ssize_t kqueue_write(struct file *file, const char __user *buf, 
        size_t lbuf, loff_t *ppos)
{
    struct kqueue_data *kq = file->private_data;

    char kbuf[4];

    spin_lock(&kq->kq_lock);
    copy_from_user(kbuf, buf, 4);
    printk("%zu bytes: %s", lbuf, kbuf);
    spin_unlock(&kq->kq_lock);

    return sizeof(struct kevent);
}

static int __init kqueue_start(void)
{
    int rv = 0;

    printk(KERN_INFO "Loading kqueue module...\n");

    /* Register as a character device */
    major = register_chrdev(0, "kqueue", &fops);
    if (major < 0) {
        printk(KERN_WARNING "register_chrdev() failed");
        return major;
    }

    /* Create /dev/kqueue */
    kqueue_class = class_create(THIS_MODULE, "kqueue");
    device_create(kqueue_class, NULL, MKDEV(major,0), NULL, "kqueue");

    printk(KERN_INFO "Creating helper thread...\n");
    kq_thread = kthread_create(kqueue_main, NULL, "kqueue");
    if (IS_ERR(kq_thread)) {
        rv = PTR_ERR(kq_thread);
        goto err_out;
    }
    wake_up_process(kq_thread);

    printk(KERN_INFO "Finished loading kqueue module...\n");
    return rv;

err_out:
    //TODO: cleanup
    return rv;
}

static void __exit kqueue_end(void)
{
    printk(KERN_INFO "Unloading kqueue module\n");

    /* Remove /dev/kqueue */
    device_destroy(kqueue_class, MKDEV(major,0));
    class_destroy(kqueue_class);
    unregister_chrdev(major, "kqueue");

    kthread_stop(kq_thread);
}

module_init(kqueue_start);
module_exit(kqueue_end);

MODULE_LICENSE("Dual BSD/GPL");
MODULE_AUTHOR("Mark Heily <mark@heily.com>");
MODULE_DESCRIPTION("kqueue(2) compatibility");
