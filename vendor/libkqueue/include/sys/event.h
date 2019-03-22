/*-
 * Copyright (c) 2009 Mark Heily <mark@heily.com>
 * Copyright (c) 1999,2000,2001 Jonathan Lemon <jlemon@FreeBSD.org>
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
 *
 * $FreeBSD SVN Revision 197533$
 */

#ifndef _SYS_EVENT_H_
#define _SYS_EVENT_H_

#include <sys/types.h>

#ifdef __KERNEL__
#define intptr_t long
#else
#include <sys/types.h>
#if defined(_WIN32) && _MSC_VER < 1600 && !defined(__MINGW32__)
# include "../../src/windows/stdint.h"
#else
# include <stdint.h>
#endif
#define LIBKQUEUE       1
#endif

struct timespec;

/** Populate a kevent structure in the <em>changelist</em>
 *
 * @param[in] _kevp    The kevent structure to populate.
 * @param[in] _ident   The unique identifier for this event.
 * @param[in] _filter  The unique identifier for this event.
 * @param[in] _flags   Filter specific flags.
 * @param[in] _data    Additional data for the filter.
 * @param[in] _udata   Opaque user data identifier.  Not interpreted by libkqueue.
 */
#define EV_SET(_kevp, _ident, _filter, _flags, _fflags, _data, _udata) do { \
    struct kevent *kevp = (_kevp);     \
    (kevp)->ident = (_ident);          \
    (kevp)->filter = (_filter);         \
    (kevp)->flags = (_flags);          \
    (kevp)->fflags = (_fflags);        \
    (kevp)->data = (_data);            \
    (kevp)->udata = (_udata);          \
} while(0)

/** Structure to hold an event registration or notification
 *
 * A list of kevent structures are passed in by the application as the <em>changelist</em>
 * to set which notifications the application wishes to received.
 *
 * A list of kevent structures are passed back to the application as the <em>eventlist</em>
 * to inform the application of events which occurred or filter states.
 */
struct kevent {
    uintptr_t           ident;         //!< The unique identifier for this event.
    short               filter;        //!< The unique identifier for this event.
    unsigned short      flags;         //!< One or more of the EV_* macros or'd together.
    unsigned int        fflags;        //!< Filter specific flags.
    intptr_t            data;          //!< Additional data for the filter.
    void                *udata;        //!< Opaque user data identifier.
};

/** @name Filters
 *
 * @{
 */
#define EVFILT_READ          (-1)      //!< Read I/O event.
#define EVFILT_WRITE         (-2)      //!< Write I/O event.
#define EVFILT_AIO           (-3)      //!< Attached to aio requests.
#define EVFILT_VNODE         (-4)      //!< Attached to vnodes.
#define EVFILT_PROC          (-5)      //!< attached to struct proc.
#define EVFILT_SIGNAL        (-6)      //!< Attached to struct proc.
#define EVFILT_TIMER         (-7)      //!< Timers.
#define EVFILT_NETDEV        (-8)      //!< Network devices.
#define EVFILT_FS            (-9)      //!< Filesystem events.
#define EVFILT_LIO           (-10)     //!< Attached to lio requests.
#define EVFILT_USER          (-11)     //!< User events.
#define EVFILT_SYSCOUNT        11
/** @} */

/** @name Actions
 *
 * @{
 */
#define EV_ADD          0x0001         //!< Add event to kq (implies enable).
#define EV_DELETE       0x0002         //!< Delete event from kq.
#define EV_ENABLE       0x0004         //!< Enable event.
#define EV_DISABLE      0x0008         //!< Disable event (not reported).
/** @} */

/** @name Flags
 *
 * @{
 */
#define EV_ONESHOT      0x0010         //!< Only report one occurrence.
#define EV_CLEAR        0x0020         //!< Clear event state after reporting.
#define EV_RECEIPT      0x0040         //!< Force EV_ERROR on success, data=0.
#define EV_DISPATCH     0x0080         //!< Disable event after reporting.

#define EV_SYSFLAGS     0xF000         //!< Reserved by system.
#define EV_FLAG1        0x2000         //!< Filter-specific flag.
/** @} */

/** @name Returned values
 *
 * @{
 */
#define EV_EOF          0x8000         //!< EOF detected.
#define EV_ERROR        0x4000         //!< Error, data contains errno.
/** @} */

/** @name Data/hint flags/masks for EVFILT_USER
 *
 * On input, the top two bits of fflags specifies how the lower twenty four
 * bits should be applied to the stored value of fflags.
 *
 * On output, the top two bits will always be set to NOTE_FFNOP and the
 * remaining twenty four bits will contain the stored fflags value.
 * @{
 */
#define NOTE_FFNOP      0x00000000     //!< Ignore input fflags.
#define NOTE_FFAND      0x40000000     //!< AND fflags.
#define NOTE_FFOR       0x80000000     //!< OR fflags.
#define NOTE_FFCOPY     0xc0000000     //!< Copy fflags.
#define NOTE_FFCTRLMASK 0xc0000000     //!< Masks for operations.
#define NOTE_FFLAGSMASK 0x00ffffff

#define NOTE_TRIGGER    0x01000000     //!< Cause the event to be triggered for output.
/** @} */

/** @name Data/hint flags for EVFILT_{READ|WRITE}
 *
 * @{
 */
#define NOTE_LOWAT      0x0001         //!< Low water mark.
#undef  NOTE_LOWAT      /* Not supported on Linux */
/** @} */

/** @name Data/hint flags for EVFILT_VNODE
 *
 * @{
 */
#define NOTE_DELETE     0x0001         //!< Vnode was removed.
#define NOTE_WRITE      0x0002         //!< Data contents changed.
#define NOTE_EXTEND     0x0004         //!< Size increased.
#define NOTE_ATTRIB     0x0008         //!< Attributes changed.
#define NOTE_LINK       0x0010         //!< Link count changed.
#define NOTE_RENAME     0x0020         //!< Vnode was renamed.
#define NOTE_REVOKE     0x0040         //!< Vnode access was revoked.
#undef  NOTE_REVOKE     /* Not supported on Linux */
/** @} */

/** @name Data/hint flags for EVFILT_PROC
 *
 * @{
 */
#define    NOTE_EXIT    0x80000000     //!< Process exited.
#define    NOTE_FORK    0x40000000     //!< Process forked.
#define    NOTE_EXEC    0x20000000     //!< Process exec'd.
#define    NOTE_PCTRLMASK 0xf0000000   //!< Mask for hint bits.
#define    NOTE_PDATAMASK 0x000fffff   //!< Mask for pid.
/** @} */

/** @name Additional flags for EVFILT_PROC
 *
 * @{
 */
#define    NOTE_TRACK   0x00000001     //!< Follow across forks.
#define    NOTE_TRACKERR 0x00000002    //!< Could not track child.
#define    NOTE_CHILD   0x00000004     //!< Am a child process.
/** @} */

/** @name Data/hint flags for EVFILT_NETDEV
 *
 * @{
 */
#define NOTE_LINKUP     0x0001         //!< Link is up.
#define NOTE_LINKDOWN   0x0002         //!< Link is down.
#define NOTE_LINKINV    0x0004         //!< Link state is invalid.
/** @} */

/** @name vfsquery flags
 *
 * @note KLUDGE: This is from <sys/mount.h> on FreeBSD and is used by the EVFILT_FS filter.
 *
 * @{
 */
#define VQ_NOTRESP      0x0001         //!< Server down.
#define VQ_NEEDAUTH     0x0002         //!< server bad auth.
#define VQ_LOWDISK      0x0004         //!< we're low on space.
#define VQ_MOUNT        0x0008         //!< new filesystem arrived.
#define VQ_UNMOUNT      0x0010         //!< filesystem has left.
#define VQ_DEAD         0x0020         //!< filesystem is dead, needs force unmount.
#define VQ_ASSIST       0x0040         //!< filesystem needs assistance from external program.
#define VQ_NOTRESPLOCK  0x0080         //!< server lockd down.
/** @} */

/** @name Data/hint flags for EVFILT_TIMER as suported and defined in kevent64
 *
 * @{
 */
#define NOTE_SECONDS    0x0001         //!< Time specified in seconds.
#define NOTE_USECONDS   0x0002         //!< Time specified in micro seconds.
#define NOTE_NSECONDS   0x0004         //!< Time specified in nano seconds.
#define NOTE_ABSOLUTE   0x0008         //!< Data is an absolute timeout.
/** @} */

#ifndef __KERNEL__
#ifdef  __cplusplus
extern "C" {
#endif

#ifdef _WIN32

#if (_MSC_VER < 1900)
struct timespec {
    time_t  tv_sec;
    long    tv_nsec;
};
#else
#include <time.h>
#endif

__declspec(dllexport) int
kqueue(void);

__declspec(dllexport) int
kevent(int kq, const struct kevent *changelist, int nchanges,
        struct kevent *eventlist, int nevents,
        const struct timespec *timeout);

#ifdef MAKE_STATIC
__declspec(dllexport) int
libkqueue_init();
#endif

#else
int     kqueue(void);
int     kevent(int kq, const struct kevent *changelist, int nchanges,
        struct kevent *eventlist, int nevents,
        const struct timespec *timeout);
#ifdef MAKE_STATIC
int     libkqueue_init();
#endif
#endif

#ifdef  __cplusplus
}
#endif
#endif /* !__KERNEL__* */

#endif /* !_SYS_EVENT_H_ */
