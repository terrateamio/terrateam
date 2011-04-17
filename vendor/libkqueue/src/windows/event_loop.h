/*
* Copyright (c) 2011 Marius Zwicker <marius@mlba-team.de>
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


#ifndef KQUEUE_WINDOWS_EVENTLOOP_H
#define KQUEUE_WINDOWS_EVENTLOOP_H

// some condition variable typedefs
#if TARGET_WIN_VISTA
// These conditions are supported using Windows Vista and up only. We need a XP compatible workaround here

typedef CONDITION_VARIABLE pthread_cond_t;

#else

typedef struct {
	u_int waiters_count_;
	// Count of the number of waiters.

	CRITICAL_SECTION waiters_count_lock_;
	// Serialize access to <waiters_count_>.

#define SIGNAL 0
#define BROADCAST 1
#define	MAX_EVENTS 2

	HANDLE events_[MAX_EVENTS];
	// Signal and broadcast event HANDLEs.
} pthread_cond_t;

#endif

//
//	A single event item
//	
typedef struct evt_event_s {
	int type;
	void* data;
	struct evt_event_s* next;
}* evt_event_t;

#define EVT_EVENT_INITIALIZER { 0, NULL, NULL }

//
//	An event loop, normally you have one loop per thread
//	
typedef struct evt_loop_s {
	int id;
	void* data;
	evt_event_t first;
	evt_event_t last;
	pthread_mutex_t access;
	pthread_cond_t cond;
	unsigned char used;
}* evt_loop_t;

//
//	The different event types
//	
enum evt_type {
	EVT_WAKEUP =0, /* Simply wake the thread, the callback will know what to do */
	EVT_EXIT =1, /* Immediately exit the event loop */
	EVT_CUSTOM =2 /* Some custom event */
};

//
//	Flags describing the return values of evt_run
//	
enum evt_flags {
	EVT_ERR = -3, /* An error occured */
	EVT_TIMEDOUT = -5, /* Timeout elapsed before receiving an event */
};

//
//	Creates a new event loop
//	
evt_loop_t evt_create();

//
//  Initializes an existing eventloop (as if it was new)
//
void evt_init(evt_loop_t t);

//
//	Destroys the given event loop, make sure
//	that evt-run returned before. This will 
//	erase all pending events as well
//	
void evt_destroy(evt_loop_t l);

//
//	Sends an event of type type with the given data 
//	to the given event loop
//	
int evt_signal(evt_loop_t l, int type, void* data);

//
//	Executes the given event loop.
//	Will return in two casees only:
//		- The timeout expired (return value EVT_TIMEDOUT) 
//		- An event was returned (return value corresponds to the number of events returned)
//  evt will contain the returned events as an array, with max_ct events maximum
//	
int evt_run(evt_loop_t l, evt_event_t evt, int max_ct, const struct timespec* timeout);

#endif /* KQUEUE_WINDOWS_EVENTLOOP_H */
