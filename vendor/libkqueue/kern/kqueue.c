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
