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



#include "../common/private.h"

/*
* Conditionals on windows
*/
#if TARGET_WIN_VISTA
// These conditions are supported using Windows Vista and up only. We need a XP compatible workaround here

# define pthread_cond_init(c,x) InitializeConditionVariable((c))
# define pthread_cond_destroy(c)
# define pthread_cond_wait(c,m) SleepConditionVariableCS((c),(m), INFINITE)
# define pthread_cond_broadcast(c) WakeAllConditionVariable((c));
# define pthread_cond_signal(c) WakeConditionVariable((c));

#else

typedef struct {
	int unused;
} pthread_condattr_t;

/* Credits for this pthread_cond_t implementation on windows go to
the authors of http://www.cs.wustl.edu/~schmidt/win32-cv-1.html:
Douglas C. Schmidt and Irfan Pyarali
Department of Computer Science
Washington University, St. Louis, Missouri

Please note that this implementation is not a fully featured posix condition implementation
but only usable for our purposes as it allows only one thread calling cond_wait at a time.
*/

int
	pthread_cond_init (pthread_cond_t *cv,
	const pthread_condattr_t * attr)
{
	cv->waiters_count_ = 0;

	// Init the second mutex
	InitializeCriticalSection(&cv->waiters_count_lock_);

	// Create an auto-reset event.
	cv->events_[SIGNAL] = CreateEvent (NULL,  // no security
		FALSE, // auto-reset event
		FALSE, // non-signaled initially
		NULL); // unnamed

	// Create a manual-reset event.
	cv->events_[BROADCAST] = CreateEvent (NULL,  // no security
		TRUE,  // manual-reset
		FALSE, // non-signaled initially
		NULL); // unnamed

	return cv->events_[SIGNAL] == 0 || cv->events_[BROADCAST] == 0 ;
}

int pthread_cond_timedwait(pthread_cond_t *cv,
	pthread_mutex_t *external_mutex, const struct timespec* timeout)
{
	DWORD timeout_ms, rv;
	int last_waiter = 0;

	/* Convert timeout to milliseconds */
	/* NOTE: loss of precision for timeout values less than 1ms */
	if (timeout == NULL) {
		timeout_ms = INFINITE;
	} else {
		timeout_ms = 0;
		if (timeout->tv_sec > 0)
			timeout_ms += ((DWORD)timeout->tv_sec) / 1000;
		if (timeout->tv_sec > 0)
			timeout_ms += timeout->tv_nsec / 1000000;
	}



	// Avoid race conditions.
	EnterCriticalSection (&cv->waiters_count_lock_);
	cv->waiters_count_++;
	LeaveCriticalSection (&cv->waiters_count_lock_);

	// It's ok to release the <external_mutex> here since Win32
	// manual-reset events maintain state when used with
	// <SetEvent>.  This avoids the "lost wakeup" bug...
	LeaveCriticalSection (external_mutex);

	// Wait for either event to become signaled due to <pthread_cond_signal>
	// being called or <pthread_cond_broadcast> being called.
	rv = WaitForMultipleObjects (2, cv->events_, FALSE, timeout_ms);
	if( rv == WAIT_TIMEOUT) {
		int r = 0;
		return EVT_TIMEDOUT;
	} else if(rv == WAIT_FAILED) {
		dbg_lasterror("cond_timedwait failed");
		return EVT_ERR;
	}

	EnterCriticalSection (&cv->waiters_count_lock_);
	cv->waiters_count_--;
	last_waiter =
		rv == WAIT_OBJECT_0 + BROADCAST 
		&& cv->waiters_count_ == 0;
	LeaveCriticalSection (&cv->waiters_count_lock_);

	// Some thread called <pthread_cond_broadcast>.
	if (last_waiter)
		// We're the last waiter to be notified or to stop waiting, so
		// reset the manual event. 
		ResetEvent (cv->events_[BROADCAST]); 

	// Reacquire the <external_mutex>.
	EnterCriticalSection (external_mutex);

	return 0;
}

int
	pthread_cond_wait (pthread_cond_t *cv,
	pthread_mutex_t *external_mutex)
{
	return pthread_cond_timedwait(cv, external_mutex, NULL);
}

int
	pthread_cond_signal (pthread_cond_t *cv)
{
	int have_waiters = 0;

	// Avoid race conditions.
	EnterCriticalSection (&cv->waiters_count_lock_);
	have_waiters = cv->waiters_count_ > 0;
	LeaveCriticalSection (&cv->waiters_count_lock_);

	if (have_waiters)
		SetEvent (cv->events_[SIGNAL]);

	return 0;
}

int
	pthread_cond_destroy(pthread_cond_t *cv)
{
	CloseHandle(cv->events_[SIGNAL]);
	CloseHandle(cv->events_[BROADCAST]);

	return 0;
}
#endif

/*
* Event loop implementation
*/

void evt_init(evt_loop_t t){
	assert(t);
	pthread_mutex_init(&t->access, NULL);
	pthread_cond_init(&t->cond, NULL);
	t->used = TRUE;
}

evt_loop_t evt_create(){
	evt_loop_t neu = (evt_loop_t)malloc(sizeof(struct evt_loop_s));
	assert(neu);
	memset(neu,0,sizeof(struct evt_loop_s));

	evt_init(neu);

	return neu;
}

int evt_signal(evt_loop_t l, int type, void* data){
	// create new item
	evt_event_t i = (evt_event_t)malloc(sizeof(struct evt_event_s));

	assert(l);

	if (i == NULL)
		return -1; // creation failed
	i->type = type; // link with the given event type
	i->data = data;
	i->next = NULL;

	pthread_mutex_lock(&l->access);
	if (l->last != NULL)
		l->last->next = i;
	l->last = i;
	if (l->first == NULL) { // if this item is first one, signal waiting getitem call
		l->first = i;
		pthread_cond_signal(&l->cond);
	}
	pthread_mutex_unlock(&l->access);
	return 0;
}

int evt_run(evt_loop_t l, evt_event_t evt, int max_ct, const struct timespec* timeout){
	evt_event_t curr = NULL;

	assert(l);
	assert(evt);
	assert(max_ct > 0);

	pthread_mutex_lock(&l->access);
	while(1){
		// get item from list, if available
		if (l->first == NULL) {
			if( pthread_cond_timedwait(&l->cond, &l->access, timeout) == EVT_TIMEDOUT ) // no item available, wait for it
				return EVT_TIMEDOUT;

			// in this case we can be sure to hold the mutex again
			continue;
		}
		curr = l->first;
		l->first = curr->next; // remove item
		if (l->first == NULL)
			l->last = NULL; // this was the last item
		pthread_mutex_unlock(&l->access);

		assert(curr);
		// TODO: Real event array support
		// return the current event
		memcpy(&(evt[0]), curr, sizeof(struct evt_event_s));
		free(curr);
		return 1;

		pthread_mutex_lock(&l->access);
	}

}

void evt_destroy(evt_loop_t l){
	evt_event_t i = NULL, curr = NULL;

	assert(l);

	if (l->used == FALSE)
		return;

	// delete all waiting items
	i = l->first;
	while (i != NULL) {
		curr = i;
		i = i->next;
		free(curr);
	}

	// reset list
	l->first = NULL;
	l->last = NULL;

	pthread_mutex_destroy(&l->access);
	pthread_cond_destroy(&l->cond);

	free(l);
}
