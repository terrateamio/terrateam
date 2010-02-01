/*
 * Copyright (c) 2010 Mark Heily <mark@heily.com>
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

#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/uaccess.h>

/* Max. number of descriptors that can be associated with a kqueue descriptor */
#define KQUEUE_FD_MAX 10

static int kqueue_open (struct inode *inode, struct file *file);
static int kqueue_release (struct inode *inode, struct file *file);
static int kqueue_ioctl(struct inode *inode, struct file *file,
        unsigned int cmd, unsigned long arg);
 
struct file_operations fops = {
    .owner  =   THIS_MODULE,
    .ioctl	=   kqueue_ioctl,
    .open	=   kqueue_open,
    .release =  kqueue_release,
};

struct kqueue_data {
    int     kq_fd[KQUEUE_FD_MAX];
    size_t  kq_cnt; 
};

static int major;
static struct class *kqueue_class;

static int kqueue_open (struct inode *inode, struct file *file) 
{
    struct kqueue_data *kq;

    printk("kqueue_open\n");

    kq = kmalloc(sizeof(*kq), GFP_KERNEL);
    if (kq == NULL) {
        printk("kqueue: kmalloc failed\n");
        return -1;
    }
    memset(kq, 0, sizeof(*kq));
    file->private_data = kq;

    return 0;
}

static int kqueue_release (struct inode *inode, struct file *file) 
{
    struct kqueue_data *kq = file->private_data;
    int i;

    printk("kqueue_release\n");
    for (i = 0; i < kq->kq_cnt; i++) {
        printk(KERN_INFO "also close fd %d...\n", kq->kq_fd[i]);
    }
    kfree(file->private_data);

    return 0;
}

static int kqueue_ioctl(struct inode *inode, struct file *file,
        unsigned int cmd, unsigned long arg) 
{
    struct kqueue_data *kq = file->private_data;
    int fd;

    if (copy_from_user(&fd, (int *)arg, sizeof(int)))
        return -EFAULT;

    if (kq->kq_cnt >= KQUEUE_FD_MAX)
        return -EMFILE;
    kq->kq_fd[kq->kq_cnt++] = fd;

    printk(KERN_INFO "added fd %d\n", fd);

    return 0;
}

static int __init kqueue_start(void)
{
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

    printk(KERN_INFO "Finished loading kqueue module...\n");

    return 0;
}

static void __exit kqueue_end(void)
{
    printk(KERN_INFO "Unloading kqueue module\n");

    /* Remove /dev/kqueue */
    device_destroy(kqueue_class, MKDEV(major,0));
    class_destroy(kqueue_class);

    unregister_chrdev(major, "kqueue");
}

module_init(kqueue_start);
module_exit(kqueue_end);

MODULE_LICENSE("Dual BSD/GPL");
MODULE_AUTHOR("Mark Heily <mark@heily.com>");
MODULE_DESCRIPTION("kqueue(2) compatibility");
