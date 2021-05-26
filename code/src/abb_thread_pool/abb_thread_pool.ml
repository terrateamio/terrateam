type 'a f = unit -> 'a

type ('a, 'b) trigger = 'a -> ('b, exn * Printexc.raw_backtrace option) result -> unit

type work = Work : ('b * 'a f * ('b, 'a) trigger) -> work

type 'a t = {
  wait : unit -> 'a;
  work_queue : work Queue.t;
  mutex : Mutex.t;
  cond : Condition.t;
  shutdown : bool ref;
}

let rec thread (work_queue, mutex, cond, shutdown) =
  Mutex.lock mutex;
  while Queue.is_empty work_queue && not !shutdown do
    Condition.wait cond mutex
  done;
  if not !shutdown then (
    let (Work (wait_token, f, trigger)) = Queue.pop work_queue in
    Mutex.unlock mutex;
    (try
       let v = f () in
       trigger wait_token (Ok v)
     with exn -> trigger wait_token (Error (exn, Some (Printexc.get_raw_backtrace ()))));
    thread (work_queue, mutex, cond, shutdown)
  ) else
    Mutex.unlock mutex

let rec create_threads work_queue mutex cond shutdown = function
  | 0 -> ()
  | n ->
      ignore (Thread.create thread (work_queue, mutex, cond, shutdown));
      create_threads work_queue mutex cond shutdown (n - 1)

let create ~capacity ~wait =
  if capacity <= 0 then
    raise (Invalid_argument (Printf.sprintf "capacity is %d, must be greater than 0" capacity));

  let t =
    {
      wait;
      work_queue = Queue.create ();
      mutex = Mutex.create ();
      cond = Condition.create ();
      shutdown = ref false;
    }
  in
  create_threads t.work_queue t.mutex t.cond t.shutdown capacity;
  t

let enqueue t ~f ~trigger =
  let wait_token = t.wait () in
  let work = Work (wait_token, f, trigger) in
  Mutex.lock t.mutex;
  Queue.push work t.work_queue;
  Condition.broadcast t.cond;
  Mutex.unlock t.mutex;
  wait_token

let destroy t =
  Mutex.lock t.mutex;
  t.shutdown := true;
  Condition.broadcast t.cond;
  Mutex.unlock t.mutex
