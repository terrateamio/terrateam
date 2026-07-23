module List = ListLabels
module Sys_stdlib = Sys
module Unix = UnixLabels

module Native = struct
  type t = Unix.file_descr
end

module Fd_map = CCMap.Make (struct
  type t = Unix.file_descr

  let compare = compare
end)

module Timers = struct
  module Timer_map = Map.Make (struct
    type t = (Mtime.span[@compare Mtime.Span.compare]) * int [@@deriving ord]
  end)

  type 'a t = 'a Timer_map.t

  let empty = Timer_map.empty
  let add id timestamp f t = Timer_map.add (timestamp, id) f t
  let remove id timestamp t = Timer_map.remove (timestamp, id) t
  let next t = Timer_map.min_binding t
end

let sec_ns = Mtime.Span.(to_float_ns s)

(* El is short for Event Loop *)
module El = struct
  type task_data = {
    task_id : int;
    task_name : string option;
  }

  type t = {
    reads : (t Abb_fut.State.t -> t Abb_fut.State.t) Fd_map.t;
    writes : (t Abb_fut.State.t -> t Abb_fut.State.t) Fd_map.t;
    timers : (t Abb_fut.State.t -> t Abb_fut.State.t) Timers.t;
    next_timer_id : int;
    curr_time : float;
    mono_time : Mtime.span;
    exec_duration : float -> unit;
    thread_pool : (Unix.file_descr * Unix.file_descr) Abb_thread_pool.t;
    ignore_reads : Unix.file_descr list;
    ignore_writes : Unix.file_descr list;
    task_counter : int Atomic.t;
    (* Thunks to run on the next event-loop iteration. Used to deliver work
       (e.g. waking [Chan] waiters from [Chan.close]) that originates outside a
       future and so cannot thread the scheduler state itself. The [Queue.t] is
       a shared mutable object: every threaded [Abb_fut.State.t] copy points at
       this same queue. *)
    wakeups : (t Abb_fut.State.t -> t Abb_fut.State.t) Queue.t;
  }

  type t_ = t
  type task_data_ = task_data

  module Future = Abb_fut.Make (struct
    type data = task_data_

    let zero_data = { task_id = 0; task_name = None }

    type t = t_
  end)

  let create ?(thread_pool_size = 100) ?(exec_duration = fun _ -> ()) () =
    let t =
      {
        reads = Fd_map.empty;
        writes = Fd_map.empty;
        timers = Timers.empty;
        next_timer_id = 0;
        curr_time = Unix.gettimeofday ();
        mono_time = Mtime_clock.elapsed ();
        exec_duration;
        thread_pool = Abb_thread_pool.create ~capacity:thread_pool_size ~wait:Unix.pipe;
        ignore_reads = [];
        ignore_writes = [];
        task_counter = Atomic.make 1;
        wakeups = Queue.create ();
      }
    in
    t

  let destroy t = Abb_thread_pool.destroy t.thread_pool
  let read_fds t = Iter.to_list (Fd_map.keys t.reads)
  let write_fds t = Iter.to_list (Fd_map.keys t.writes)

  let dispatch fds get set ignores s =
    ListLabels.fold_left
      ~init:s
      ~f:(fun s fd ->
        let ignore_list = ignores s in
        if not (CCList.mem ~eq:( = ) fd ignore_list) then
          let m = get s in
          let f = Fd_map.find fd m in
          let s = set (Fd_map.remove fd m) s in
          f s
        else s)
      fds

  let dispatch_reads reads s =
    dispatch
      reads
      (fun s -> (Abb_fut.State.state s).reads)
      (fun reads s ->
        let t = Abb_fut.State.state s in
        Abb_fut.State.set_state { t with reads } s)
      (fun s -> (Abb_fut.State.state s).ignore_reads)
      s

  let dispatch_writes writes s =
    dispatch
      writes
      (fun s -> (Abb_fut.State.state s).writes)
      (fun writes s ->
        let t = Abb_fut.State.state s in
        Abb_fut.State.set_state { t with writes } s)
      (fun s -> (Abb_fut.State.state s).ignore_writes)
      s

  let rec dispatch_timers s =
    let t = Abb_fut.State.state s in
    try
      match Timers.next t.timers with
      | (ts, id), f when Mtime.Span.compare ts t.mono_time <= 0 ->
          let t = { t with timers = Timers.remove id ts t.timers } in
          let s = Abb_fut.State.set_state t s in
          dispatch_timers (f s)
      | _ -> s
    with Not_found -> s

  let wait_on_event s =
    let t = Abb_fut.State.state s in

    let timeout =
      try
        match Timers.next t.timers with
        | (ts, _), _ when Mtime.Span.compare ts t.mono_time > 0 ->
            Mtime.Span.(to_float_ns (abs_diff ts t.mono_time) /. sec_ns)
        | _ -> 0.0
      with Not_found -> -1.0
    in
    assert (timeout >= -1.0);
    let read = read_fds t in
    let write = write_fds t in
    assert ((not (CCList.is_empty read && CCList.is_empty write)) || timeout >= 0.0);
    let reads, writes, _ =
      try Unix.select ~read ~write ~except:[] ~timeout
      with Unix.Unix_error (Unix.EINTR, _, _) -> ([], [], [])
    in
    let t =
      {
        t with
        curr_time = Unix.gettimeofday ();
        mono_time = Mtime_clock.elapsed ();
        ignore_reads = [];
        ignore_writes = [];
      }
    in
    let s = Abb_fut.State.set_state t s in
    let s = s |> dispatch_reads reads |> dispatch_writes writes |> dispatch_timers in
    let end_time = Mtime_clock.elapsed () in
    let duration = Mtime.Span.(to_float_ns (abs_diff end_time t.mono_time) /. sec_ns) in
    (Abb_fut.State.state s).exec_duration duration;
    s

  (* Apply every queued wakeup thunk, threading the state through each. New
     thunks pushed by a thunk are picked up by the same drain. *)
  let rec drain_wakeups s =
    match Queue.take_opt (Abb_fut.State.state s).wakeups with
    | None -> s
    | Some f -> drain_wakeups (f s)

  let rec loop s done_fut =
    let s = drain_wakeups s in
    match Future.state done_fut with
    | `Det _ | `Aborted | `Exn _ -> s
    | `Undet ->
        let s = wait_on_event s in
        loop s done_fut
end

module Future = El.Future

module Scheduler = struct
  type t = El.t Abb_fut.State.t

  (* Single-domain scheduler: it advertises no [`Multi_domain] capability. *)
  let capabilities = []

  let create ?thread_pool_size ?exec_duration () =
    Abb_fut.State.create (El.create ?thread_pool_size ?exec_duration ())

  let destroy t = El.destroy (Abb_fut.State.state t)

  let run t f =
    ignore Sys.(signal sigpipe Signal_ignore);
    let ret = f () in
    let t = Future.run_with_state ret t in
    let t = El.loop t ret in
    match Future.state ret with
    | (`Det _ | `Aborted | `Exn _) as r -> (t, r)
    | `Undet -> assert false

  let run_with_state ?thread_pool_size ?exec_duration f =
    let t = create ?thread_pool_size ?exec_duration () in
    let t, r = run t f in
    destroy t;
    r
end

module Task = struct
  let id () =
    let open Future.Infix_monad in
    Future.get_data () >>| fun (d : El.task_data) -> d.El.task_id

  let name () =
    let open Future.Infix_monad in
    Future.get_data () >>| fun (d : El.task_data) -> d.El.task_name

  (* [?pinned] is accepted for interface compatibility but ignored: this
     scheduler is single-domain, so every task runs on the scheduler domain
     regardless. That satisfies the pinned contract, and is a permitted
     outcome for an unpinned task ("may run on the scheduler"). *)
  let run ?name ?pinned:_ f =
    Future.with_state (fun s ->
        let t = Abb_fut.State.state s in
        let new_id = Atomic.fetch_and_add t.El.task_counter 1 in
        let outer_data = Future.peek_chain_data () in
        let inner_chain =
          let open Future.Infix_monad in
          Future.set_data { El.task_id = new_id; task_name = name } >>= fun () -> f ()
        in
        (* Wrap so the awaiter inherits the outer chain's data, not the inner
           task's, when binding on the task future. *)
        let task =
          let open Future.Infix_monad in
          Future.fork (Future.set_data outer_data >>= fun () -> inner_chain)
        in
        (s, task))
end

module Sys = struct
  let sleep duration =
    Future.with_state (fun s ->
        let t = Abb_fut.State.state s in
        let timer_id = t.El.next_timer_id in
        (* Add one [ns] to the duration just to ensure we do not get caught in a
           tight loop by sleeping 0 seconds. *)
        let duration_span =
          CCOption.get_exn_or
            "negative sleep duration"
            (Mtime.Span.of_float_ns (duration *. sec_ns))
        in
        let ts = Mtime.Span.(add t.El.mono_time (add duration_span ns)) in
        let p =
          Future.Promise.create
            ~abort:(fun () ->
              Future.with_state (fun s ->
                  let t = Abb_fut.State.state s in
                  let t = { t with El.timers = Timers.remove timer_id ts t.El.timers } in
                  let s = Abb_fut.State.set_state t s in
                  (s, Future.return ())))
            ()
        in
        let f s = Future.run_with_state (Future.Promise.set p ()) s in
        let t =
          {
            t with
            El.next_timer_id = t.El.next_timer_id + 1;
            timers = Timers.add timer_id ts f t.El.timers;
          }
        in

        let s = Abb_fut.State.set_state t s in
        (s, Future.Promise.future p))

  let time () =
    Future.with_state (fun s ->
        let t = Abb_fut.State.state s in
        (s, Future.return t.El.curr_time))

  let monotonic () =
    Future.with_state (fun s ->
        let t = Abb_fut.State.state s in
        (s, Future.return Mtime.Span.(to_float_ns t.El.mono_time /. sec_ns)))
end

module Thread = struct
  (* Raised in place of a queued thread body when its future was aborted before
     a worker picked the thunk up; the body is skipped entirely. *)
  exception Aborted_before_start

  let run f =
    Future.with_state (fun s ->
        let t = Abb_fut.State.state s in
        let ret = ref None in
        (* [aborted] is set on the scheduler domain by [abort] and read on a
           worker thread, so it must be an [Atomic]. The body checks it before
           running: an abort that lands before a worker pops the thunk skips the
           body; a body already running cannot be stopped. *)
        let aborted = Atomic.make false in
        let f () = if Atomic.get aborted then raise Aborted_before_start else f () in
        let trigger (_, trigger) res =
          ret := Some res;
          (* Send something on the pipe to trigger the read side *)
          (try ignore (Unix.write trigger ~buf:(Bytes.of_string "0") ~pos:0 ~len:1)
           with Unix.Unix_error _ ->
             (* If the other side has closed the trigger, this write will fail,
                so ignore any write error. *)
             ());
          Unix.close trigger
        in
        let wait, _ = Abb_thread_pool.enqueue t.El.thread_pool ~f ~trigger in
        let abort () =
          Atomic.set aborted true;
          (* It would be nice to kill the thread here but several issues arise,
             including: the thread may have allocated resources it needs to clean
             up, and Thread.kill is not actually implemented. *)
          Future.with_state (fun s ->
              let t = Abb_fut.State.state s in
              let t =
                {
                  t with
                  El.reads = Fd_map.remove wait t.El.reads;
                  ignore_reads = wait :: t.El.ignore_reads;
                  ignore_writes = wait :: t.El.ignore_writes;
                }
              in
              Unix.close wait;
              let s = Abb_fut.State.set_state t s in
              (s, Future.return ()))
        in
        let p = Future.Promise.create ~abort () in
        let handler s =
          let open Future.Infix_monad in
          let fut =
            match !ret with
            | Some (Ok v) -> Future.Promise.set p v >>| fun () -> Unix.close wait
            | Some (Error exn) -> Future.Promise.set_exn p exn >>| fun () -> Unix.close wait
            | None -> assert false
          in
          Future.run_with_state fut s
        in
        let t = { t with El.reads = Fd_map.add wait handler t.El.reads } in
        let s = Abb_fut.State.set_state t s in
        (s, Future.Promise.future p))
end

let safe_call f = try Ok (f ()) with e -> Error (`Unexpected e)

(** The filesystem calls are implemented through a thread call because there is no guarantee that
    they will not block, for example on an NFS system. *)
module File = struct
  type t = Unix.file_descr

  let to_native t = t
  let of_native t = t
  let stdin = Unix.stdin
  let stdout = Unix.stdout
  let stderr = Unix.stderr

  let mode_of_flags flags =
    List.map
      ~f:
        Abb_intf.File.Flag.(
          function
          | Read_only -> Unix.O_RDONLY
          | Write_only -> Unix.O_WRONLY
          | Create _ -> Unix.O_CREAT
          | Read_write -> Unix.O_RDWR
          | Append -> Unix.O_APPEND
          | Truncate -> Unix.O_TRUNC
          | Exclusive -> Unix.O_EXCL)
      flags

  let perm_of_flags flags =
    let creates =
      List.filter
        ~f:
          Abb_intf.File.Flag.(
            function
            | Create _ -> true
            | _ -> false)
        flags
    in
    match creates with
    | [ Abb_intf.File.Flag.Create perm ] -> perm
    | _ -> 0

  let open_file ~flags path =
    Thread.run (fun () ->
        try
          let t = Unix.openfile path ~mode:(mode_of_flags flags) ~perm:(perm_of_flags flags) in
          (* FIXME Possible descriptor leak here? *)
          Unix.set_close_on_exec t;
          Ok t
        with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | EROFS | EPERM -> `E_permission
              | ELOOP -> `E_loop
              | ENFILE | EMFILE -> `E_file_table_full
              | ENOSPC -> `E_no_space
              | EIO -> `E_io
              | EEXIST -> `E_exists
              | EINVAL -> `E_invalid
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let safe_read t ~buf ~pos ~len =
    try Ok (Unix.read t ~buf ~pos ~len) with
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | EBADF -> `E_bad_file
          | EIO -> `E_io
          | EINVAL -> `E_invalid
          | EISDIR -> `E_is_dir
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  let read t ~buf ~pos ~len = Thread.run (fun () -> safe_read t ~buf ~pos ~len)

  let pread t ~offset ~buf ~pos ~len =
    Thread.run (fun () ->
        try
          let n = Unix.lseek t offset ~mode:Unix.SEEK_SET in
          assert (n = offset);
          safe_read t ~buf ~pos ~len
        with
        | Unix.Unix_error (Unix.ENXIO, _, _) -> Error `E_nxio
        | exn -> Error (`Unexpected exn))

  let rec write_buf t buf =
    let n =
      Unix.write
        t
        ~buf:buf.Abb_intf.Write_buf.buf
        ~pos:buf.Abb_intf.Write_buf.pos
        ~len:buf.Abb_intf.Write_buf.len
    in
    match n with
    | n when n < buf.Abb_intf.Write_buf.len ->
        let buf = Abb_intf.Write_buf.{ buf with pos = buf.pos + n; len = buf.len - n } in
        n + write_buf t buf
    | n -> n

  let write_bufs t bufs =
    let rec write_bufs' t = function
      | [] -> 0
      | b :: bs ->
          let n = write_buf t b in
          n + write_bufs' t bs
    in
    try Ok (write_bufs' t bufs) with
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | EBADF -> `E_bad_file
          | EPIPE -> `E_pipe
          | EINVAL -> `E_invalid
          | ENOSPC -> `E_no_space
          | EIO -> `E_io
          | EROFS -> `E_permission
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  let write t bufs = Thread.run (fun () -> write_bufs t bufs)

  let pwrite t ~offset bufs =
    Thread.run (fun () ->
        try
          let n = Unix.lseek t offset ~mode:Unix.SEEK_SET in
          assert (n = offset);
          write_bufs t bufs
        with
        | Unix.Unix_error (Unix.ENXIO, _, _) -> Error `E_nxio
        | exn -> Error (`Unexpected exn))

  let lseek' t ~offset = function
    | Abb_intf.File.Seek.Cur ->
        ignore (Unix.lseek t offset ~mode:Unix.SEEK_CUR);
        Ok ()
    | Abb_intf.File.Seek.Set ->
        ignore (Unix.lseek t offset ~mode:Unix.SEEK_SET);
        Ok ()
    | Abb_intf.File.Seek.End ->
        ignore (Unix.lseek t offset ~mode:Unix.SEEK_END);
        Ok ()

  let lseek t ~offset seek =
    try lseek' t ~offset seek with
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | EBADF -> `E_bad_file
          | ENXIO -> `E_nxio
          | EINVAL -> `E_invalid
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  let close t =
    Thread.run (fun () ->
        try Ok (Unix.close t) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EBADF -> `E_bad_file
              | ENOSPC -> `E_no_space
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let unlink path =
    Thread.run (fun () ->
        try Ok (Unix.unlink path) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | EISDIR -> `E_is_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EPERM -> `E_permission
              | EIO -> `E_io
              | ENOSPC -> `E_no_space
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let mkdir path perm =
    Thread.run (fun () ->
        try Ok (Unix.mkdir ~perm path) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | EISDIR -> `E_is_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EPERM -> `E_permission
              | EIO -> `E_io
              | ENOSPC -> `E_no_space
              | EEXIST -> `E_exists
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let rmdir path =
    Thread.run (fun () ->
        try Ok (Unix.rmdir path) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | ENOTEMPTY -> `E_not_empty
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EPERM -> `E_permission
              | EINVAL -> `E_invalid
              | EBUSY -> `E_busy
              | EIO -> `E_io
              | EEXIST -> `E_exists
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let readdir path =
    Thread.run (fun () -> safe_call (fun () -> Array.to_list (Sys_stdlib.readdir path)))

  let of_unix_stat stat =
    let of_file_kind = function
      | Unix.S_REG -> Abb_intf.File.File_kind.Regular
      | Unix.S_DIR -> Abb_intf.File.File_kind.Directory
      | Unix.S_CHR -> Abb_intf.File.File_kind.Char
      | Unix.S_BLK -> Abb_intf.File.File_kind.Block
      | Unix.S_LNK -> Abb_intf.File.File_kind.Symlink
      | Unix.S_FIFO -> Abb_intf.File.File_kind.Fifo
      | Unix.S_SOCK -> Abb_intf.File.File_kind.Socket
    in
    Abb_intf.File.Stat.
      {
        dev = stat.Unix.st_dev;
        inode = stat.Unix.st_ino;
        kind = of_file_kind stat.Unix.st_kind;
        perm = stat.Unix.st_perm;
        num_links = stat.Unix.st_nlink;
        uid = stat.Unix.st_uid;
        gid = stat.Unix.st_gid;
        rdev = stat.Unix.st_rdev;
        size = stat.Unix.st_size;
        atime = stat.Unix.st_atime;
        mtime = stat.Unix.st_mtime;
        ctime = stat.Unix.st_ctime;
      }

  let stat path =
    Thread.run (fun () ->
        try Ok (of_unix_stat (Unix.stat path)) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EACCES -> `E_access
              | EIO -> `E_io
              | ELOOP -> `E_loop
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | ENOTDIR -> `E_not_dir
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let fstat t =
    Thread.run (fun () ->
        try Ok (of_unix_stat (Unix.fstat t)) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EBADF -> `E_bad_file
              | EINVAL -> `E_invalid
              | EACCES -> `E_access
              | EIO -> `E_io
              | ELOOP -> `E_loop
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | ENOTDIR -> `E_not_dir
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let lstat path =
    Thread.run (fun () ->
        try Ok (of_unix_stat (Unix.lstat path)) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EACCES -> `E_access
              | EIO -> `E_io
              | ELOOP -> `E_loop
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | ENOTDIR -> `E_not_dir
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let rename ~src ~dst =
    Thread.run (fun () ->
        try Ok (Unix.rename ~src ~dst) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | EPERM | EROFS -> `E_permission
              | ELOOP -> `E_loop
              | ENOTDIR -> `E_not_dir
              | EISDIR -> `E_is_dir
              | ENOSPC -> `E_no_space
              | EIO -> `E_io
              | EINVAL -> `E_invalid
              | ENOTEMPTY -> `E_not_empty
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let truncate path len =
    Thread.run (fun () ->
        try Ok (Unix.truncate path ~len:(Int64.to_int len)) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EROFS | EPERM -> `E_permission
              | EISDIR -> `E_is_dir
              | EINVAL -> `E_invalid
              | EIO -> `E_io
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let ftruncate t len =
    Thread.run (fun () ->
        try Ok (Unix.ftruncate t ~len:(Int64.to_int len)) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EBADF -> `E_bad_file
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EROFS | EPERM -> `E_permission
              | EISDIR -> `E_is_dir
              | EINVAL -> `E_invalid
              | EIO -> `E_io
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let chmod path mode =
    Thread.run (fun () ->
        try Ok (Unix.chmod path ~perm:mode) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EROFS | EPERM -> `E_permission
              | EIO -> `E_io
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let fchmod t mode =
    Thread.run (fun () ->
        try Ok (Unix.fchmod t ~perm:mode) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EBADF -> `E_bad_file
              | EINVAL -> `E_invalid
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EROFS | EPERM -> `E_permission
              | EIO -> `E_io
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let symlink ~src ~dst =
    Thread.run (fun () ->
        try Ok (Unix.symlink ~to_dir:false ~src ~dst) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EEXIST -> `E_exists
              | EROFS | EPERM -> `E_permission
              | EIO -> `E_io
              | ENOSPC -> `E_no_space
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let link ~src ~dst =
    Thread.run (fun () ->
        try Ok (Unix.link ~follow:true ~src ~dst) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EOPNOTSUPP -> `E_op_not_supported
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EEXIST -> `E_exists
              | EROFS | EPERM -> `E_permission
              | EIO -> `E_io
              | ENOSPC -> `E_no_space
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let chown path ~uid ~gid =
    Thread.run (fun () ->
        try Ok (Unix.chown path ~uid ~gid) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EROFS | EPERM -> `E_permission
              | EIO -> `E_io
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let fchown t ~uid ~gid =
    Thread.run (fun () ->
        try Ok (Unix.fchown t ~uid ~gid) with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EBADF -> `E_bad_file
              | ENOTDIR -> `E_not_dir
              | ENAMETOOLONG -> `E_name_too_long
              | ENOENT -> `E_no_entity
              | EACCES -> `E_access
              | ELOOP -> `E_loop
              | EROFS | EPERM -> `E_permission
              | EIO -> `E_io
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))
end

module Socket = struct
  type tcp
  type udp
  type _ t = Abb_fd_socket.t

  (* Fail fast once the handle is closed; otherwise run [f] with the live fd.
     [`E_file_closed] is in every guarded op's error type ([Abb_intf.Errors]).
     [getsockname]/[getpeername] (no result type) and [readable]/[writable]
     (non-result future) skip the guard. *)
  let guarded t f =
    if Abb_fd_socket.is_closed t then Error `E_file_closed else f (Abb_fd_socket.fd t)

  let guarded_fut t f =
    if Abb_fd_socket.is_closed t then Future.return (Error `E_file_closed)
    else f (Abb_fd_socket.fd t)

  (* Register / un-register [fd] in the loop's readiness maps.  These collapse
     the repeated state-threading boilerplate each socket op used to inline. *)
  let add_read fd handler s =
    let el = Abb_fut.State.state s in
    Abb_fut.State.set_state { el with El.reads = Fd_map.add fd handler el.El.reads } s

  let remove_read fd s =
    let el = Abb_fut.State.state s in
    Abb_fut.State.set_state
      { el with El.reads = Fd_map.remove fd el.El.reads; ignore_reads = fd :: el.El.ignore_reads }
      s

  let add_write fd handler s =
    let el = Abb_fut.State.state s in
    Abb_fut.State.set_state { el with El.writes = Fd_map.add fd handler el.El.writes } s

  let remove_write fd s =
    let el = Abb_fut.State.state s in
    Abb_fut.State.set_state
      {
        el with
        El.writes = Fd_map.remove fd el.El.writes;
        ignore_writes = fd :: el.El.ignore_writes;
      }
      s

  let unix_of_domain = function
    | Abb_intf.Socket.Domain.Unix -> Unix.PF_UNIX
    | Abb_intf.Socket.Domain.Inet4 -> Unix.PF_INET
    | Abb_intf.Socket.Domain.Inet6 -> Unix.PF_INET6

  let domain_of_unix = function
    | Unix.PF_UNIX -> Abb_intf.Socket.Domain.Unix
    | Unix.PF_INET -> Abb_intf.Socket.Domain.Inet4
    | Unix.PF_INET6 -> Abb_intf.Socket.Domain.Inet6

  let socket_type_of_unix = function
    | Unix.SOCK_STREAM -> Abb_intf.Socket.Socket_type.Stream
    | Unix.SOCK_DGRAM -> Abb_intf.Socket.Socket_type.Dgram
    | Unix.SOCK_RAW -> Abb_intf.Socket.Socket_type.Raw
    | Unix.SOCK_SEQPACKET -> Abb_intf.Socket.Socket_type.Seqpacket

  let unix_of_socket_type = function
    | Abb_intf.Socket.Socket_type.Stream -> Unix.SOCK_STREAM
    | Abb_intf.Socket.Socket_type.Dgram -> Unix.SOCK_DGRAM
    | Abb_intf.Socket.Socket_type.Raw -> Unix.SOCK_RAW
    | Abb_intf.Socket.Socket_type.Seqpacket -> Unix.SOCK_SEQPACKET

  let addrinfo_of_unix_addrinfo ai =
    let family = domain_of_unix ai.Unix.ai_family in
    let sock_type = socket_type_of_unix ai.Unix.ai_socktype in
    let addr =
      match ai.Unix.ai_addr with
      | Unix.ADDR_UNIX s -> Abb_intf.Socket.Sockaddr.Unix s
      | Unix.ADDR_INET (a, p) -> Abb_intf.Socket.Sockaddr.(Inet { addr = a; port = p })
    in
    Abb_intf.Socket.Addrinfo.
      { family; sock_type; protocol = ai.Unix.ai_protocol; addr; canon_name = ai.Unix.ai_canonname }

  let unix_sockaddr_of_sockaddr = function
    | Abb_intf.Socket.Sockaddr.Unix s -> Unix.ADDR_UNIX s
    | Abb_intf.Socket.Sockaddr.Inet inet ->
        Abb_intf.Socket.Sockaddr.(Unix.ADDR_INET (inet.addr, inet.port))

  let sockaddr_of_unix_sockaddr = function
    | Unix.ADDR_UNIX s -> Abb_intf.Socket.Sockaddr.Unix s
    | Unix.ADDR_INET (addr, port) -> Abb_intf.Socket.Sockaddr.(Inet { addr; port })

  let getaddrinfo_options_of_hints hints =
    List.map
      ~f:
        Abb_intf.Socket.Addrinfo_hints.(
          function
          | Family domain -> Unix.AI_FAMILY (unix_of_domain domain)
          | Socket_type socktype -> Unix.AI_SOCKTYPE (unix_of_socket_type socktype)
          | Protocol p -> Unix.AI_PROTOCOL p
          | Numeric_host -> Unix.AI_NUMERICHOST
          | Canon_name -> Unix.AI_CANONNAME
          | Passive -> Unix.AI_PASSIVE)
      hints

  let getaddrinfo ?hints query =
    Thread.run (fun () ->
        safe_call (fun () ->
            let hints =
              match hints with
              | Some h -> h
              | None -> []
            in
            let ai =
              match query with
              | Abb_intf.Socket.Addrinfo_query.Host h ->
                  Unix.getaddrinfo h "" (getaddrinfo_options_of_hints hints)
              | Abb_intf.Socket.Addrinfo_query.Service s ->
                  Unix.getaddrinfo "" s (getaddrinfo_options_of_hints hints)
              | Abb_intf.Socket.Addrinfo_query.Host_service (h, s) ->
                  Unix.getaddrinfo h s (getaddrinfo_options_of_hints hints)
            in
            List.map ~f:addrinfo_of_unix_addrinfo ai))

  let getsockname t =
    match Unix.getsockname (Abb_fd_socket.fd t) with
    | Unix.ADDR_UNIX str -> Abb_intf.Socket.Sockaddr.Unix str
    | Unix.ADDR_INET (addr, port) -> Abb_intf.Socket.Sockaddr.(Inet { addr; port })

  let getpeername t =
    match Unix.getpeername (Abb_fd_socket.fd t) with
    | Unix.ADDR_UNIX str -> Abb_intf.Socket.Sockaddr.Unix str
    | Unix.ADDR_INET (addr, port) -> Abb_intf.Socket.Sockaddr.(Inet { addr; port })

  let recvfrom t ~buf ~pos ~len =
    guarded_fut t (fun fd ->
        let p =
          Future.Promise.create
            ~abort:(fun () -> Future.with_state (fun s -> (remove_read fd s, Future.return ())))
            ()
        in
        let handler s =
          Future.run_with_state
            (Future.Promise.set
               p
               (try
                  let n, addr = Unix.recvfrom fd ~buf ~pos ~len ~mode:[] in
                  Ok (n, sockaddr_of_unix_sockaddr addr)
                with
               | Unix.Unix_error (err, _, _) as exn ->
                   let open Unix in
                   Error
                     (match err with
                     | EBADF -> `E_bad_file
                     | ECONNRESET -> `E_connection_reset
                     | _ -> `Unexpected exn)
               | exn -> Error (`Unexpected exn)))
            s
        in
        Future.with_state (fun s -> (add_read fd handler s, Future.Promise.future p)))

  let sendto t ~bufs sockaddr =
    let addr = unix_sockaddr_of_sockaddr sockaddr in
    guarded_fut t (fun fd ->
        let p =
          Future.Promise.create
            ~abort:(fun () -> Future.with_state (fun s -> (remove_write fd s, Future.return ())))
            ()
        in
        let rec send' total = function
          | [] -> Future.Promise.set p (Ok total)
          | wb :: bufs -> (
              try
                let n =
                  Unix.sendto
                    fd
                    ~buf:wb.Abb_intf.Write_buf.buf
                    ~pos:wb.Abb_intf.Write_buf.pos
                    ~len:wb.Abb_intf.Write_buf.len
                    ~mode:[]
                    ~addr
                in
                (* FIXME Make this handle incomplete sends *)
                assert (n = wb.Abb_intf.Write_buf.len);
                send' (n + total) bufs
              with
              | Unix.Unix_error (Unix.EAGAIN, _, _) | Unix.Unix_error (Unix.EWOULDBLOCK, _, _) ->
                  let handler s = Future.run_with_state (send' total (wb :: bufs)) s in
                  Future.with_state (fun s -> (add_write fd handler s, Future.return ()))
              | Unix.Unix_error (err, _, _) as exn ->
                  let open Unix in
                  Future.Promise.set
                    p
                    (Error
                       (match err with
                       | EBADF -> `E_bad_file
                       | EACCES -> `E_access
                       | ENOBUFS -> `E_no_buffers
                       | EHOSTUNREACH -> `E_host_unreachable
                       | EHOSTDOWN -> `E_host_down
                       | ECONNREFUSED -> `E_connection_refused
                       | _ -> `Unexpected exn))
              | exn -> Future.Promise.set p (Error (`Unexpected exn)))
        in
        let open Future.Infix_monad in
        send' 0 bufs >>= fun () -> Future.Promise.future p)

  let close t =
    if Abb_fd_socket.close_once t then
      try
        Unix.close (Abb_fd_socket.fd t);
        Future.return (Ok ())
      with
      | Unix.Unix_error (err, _, _) as exn ->
          let open Unix in
          Future.return
            (Error
               (match err with
               | EBADF -> `E_bad_file
               | ECONNRESET -> `E_connection_reset
               | _ -> `Unexpected exn))
      | exn -> Future.return (Error (`Unexpected exn))
    else Future.return (Ok ())

  let listen t ~backlog =
    guarded t (fun fd ->
        try
          Unix.listen fd ~max:backlog;
          Ok ()
        with
        | Unix.Unix_error (err, _, _) as exn ->
            let open Unix in
            Error
              (match err with
              | EBADF -> `E_bad_file
              | EDESTADDRREQ -> `E_dest_address_required
              | EINVAL -> `E_invalid
              | EOPNOTSUPP -> `E_op_not_supported
              | _ -> `Unexpected exn)
        | exn -> Error (`Unexpected exn))

  let accept t =
    guarded_fut t (fun fd ->
        try
          let nfd, _ = Unix.accept ~cloexec:true fd in
          Unix.set_nonblock nfd;
          Future.return (Ok (Abb_fd_socket.make nfd))
        with Unix.Unix_error (Unix.EAGAIN, _, _) | Unix.Unix_error (Unix.EWOULDBLOCK, _, _) ->
          let p =
            Future.Promise.create
              ~abort:(fun () -> Future.with_state (fun s -> (remove_read fd s, Future.return ())))
              ()
          in
          let handler s =
            Future.run_with_state
              (Future.Promise.set
                 p
                 (try
                    let nfd, _ = Unix.accept fd in
                    Unix.set_nonblock nfd;
                    Ok (Abb_fd_socket.make nfd)
                  with
                 | Unix.Unix_error (err, _, _) as exn ->
                     let open Unix in
                     Error
                       (match err with
                       | EBADF -> `E_bad_file
                       | EMFILE | ENFILE -> `E_file_table_full
                       | EINVAL -> `E_invalid
                       | ECONNABORTED -> `E_connection_aborted
                       | _ -> `Unexpected exn)
                 | exn -> Error (`Unexpected exn)))
              s
          in
          Future.with_state (fun s -> (add_read fd handler s, Future.Promise.future p)))

  let readable t =
    let fd = Abb_fd_socket.fd t in
    let p =
      Future.Promise.create
        ~abort:(fun () -> Future.with_state (fun s -> (remove_read fd s, Future.return ())))
        ()
    in
    let handler s = Future.run_with_state (Future.Promise.set p ()) s in
    Future.with_state (fun s -> (add_read fd handler s, Future.Promise.future p))

  let writable t =
    let fd = Abb_fd_socket.fd t in
    let p =
      Future.Promise.create
        ~abort:(fun () -> Future.with_state (fun s -> (remove_write fd s, Future.return ())))
        ()
    in
    let handler s = Future.run_with_state (Future.Promise.set p ()) s in
    Future.with_state (fun s -> (add_write fd handler s, Future.Promise.future p))

  let create_sock ~kind ~domain =
    (* FIXME Possible leak here? *)
    try
      let fd = Unix.socket ~cloexec:true ~domain:(unix_of_domain domain) ~kind ~protocol:0 in
      Unix.set_nonblock fd;
      Ok (Abb_fd_socket.make fd)
    with
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | EACCES -> `E_access
          | EAFNOSUPPORT -> `E_address_family_not_supported
          | EMFILE | ENFILE -> `E_file_table_full
          | ENOBUFS -> `E_no_buffers
          | EPERM -> `E_permission
          | EPROTONOSUPPORT -> `E_protocol_not_supported
          | EPROTOTYPE -> `E_protocol_type
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  module Tcp = struct
    let to_native t = Abb_fd_socket.fd t
    let of_native t = Abb_fd_socket.make t
    let create = create_sock ~kind:Unix.SOCK_STREAM

    let bind t addr =
      guarded t (fun fd ->
          try
            Unix.setsockopt fd Unix.SO_REUSEADDR true;
            let sa = unix_sockaddr_of_sockaddr addr in
            Unix.bind fd ~addr:sa;
            Ok ()
          with
          | Unix.Unix_error (err, _, _) as exn ->
              let open Unix in
              Error
                (match err with
                | ENOTSOCK | EBADF -> `E_bad_file
                | EAGAIN -> `E_again
                | EINVAL -> `E_invalid
                | EADDRNOTAVAIL -> `E_address_not_available
                | EADDRINUSE -> `E_address_in_use
                | EAFNOSUPPORT -> `E_address_family_not_supported
                | EACCES -> `E_access
                | ENOTDIR -> `E_not_dir
                | EROFS | EPERM -> `E_permission
                | ENAMETOOLONG -> `E_name_too_long
                | ENOENT -> `E_no_entity
                | ELOOP -> `E_loop
                | EIO -> `E_io
                | EISDIR -> `E_is_dir
                | _ -> `Unexpected exn)
          | exn -> Error (`Unexpected exn))

    let connect t addr =
      let open Future.Infix_monad in
      let sa = unix_sockaddr_of_sockaddr addr in
      guarded_fut t (fun fd ->
          let p =
            Future.Promise.create
              ~abort:(fun () -> Future.with_state (fun s -> (remove_write fd s, Future.return ())))
              ()
          in
          try
            Unix.connect fd ~addr:sa;
            Future.Promise.set p (Ok ()) >>= fun () -> Future.Promise.future p
          with
          | Unix.Unix_error (Unix.EINPROGRESS, _, _) ->
              let handler s = Future.run_with_state (Future.Promise.set p (Ok ())) s in
              Future.with_state (fun s -> (add_write fd handler s, Future.Promise.future p))
          | Unix.Unix_error (err, _, _) as exn ->
              let open Unix in
              Future.return
                (Error
                   (match err with
                   | EBADF -> `E_bad_file
                   | EINVAL -> `E_invalid
                   | EADDRNOTAVAIL -> `E_address_not_available
                   | EAFNOSUPPORT -> `E_address_family_not_supported
                   | EISCONN -> `E_is_connected
                   | ECONNREFUSED -> `E_connection_refused
                   | ECONNRESET -> `E_connection_reset
                   | ENETUNREACH -> `E_network_unreachable
                   | EHOSTUNREACH -> `E_host_unreachable
                   | EADDRINUSE -> `E_address_in_use
                   | EACCES -> `E_access
                   | _ -> `Unexpected exn))
          | exn -> Future.return (Error (`Unexpected exn)))

    let recv t ~buf ~pos ~len =
      guarded_fut t (fun fd ->
          let p =
            Future.Promise.create
              ~abort:(fun () -> Future.with_state (fun s -> (remove_read fd s, Future.return ())))
              ()
          in
          let handler s =
            Future.run_with_state
              (Future.Promise.set
                 p
                 (try Ok (Unix.recv fd ~buf ~pos ~len ~mode:[]) with
                 | Unix.Unix_error (err, _, _) as exn ->
                     let open Unix in
                     Error
                       (match err with
                       | ENOTSOCK | EBADF -> `E_bad_file
                       | ECONNRESET -> `E_connection_reset
                       | ENOTCONN -> `E_not_connected
                       | _ -> `Unexpected exn)
                 | exn -> Error (`Unexpected exn)))
              s
          in
          Future.with_state (fun s -> (add_read fd handler s, Future.Promise.future p)))

    let send t ~bufs =
      guarded_fut t (fun fd ->
          let p =
            Future.Promise.create
              ~abort:(fun () -> Future.with_state (fun s -> (remove_write fd s, Future.return ())))
              ()
          in
          let rec send' total = function
            | [] -> Future.Promise.set p (Ok total)
            | wb :: bufs -> (
                try
                  let n =
                    Unix.send
                      fd
                      ~buf:wb.Abb_intf.Write_buf.buf
                      ~pos:wb.Abb_intf.Write_buf.pos
                      ~len:wb.Abb_intf.Write_buf.len
                      ~mode:[]
                  in
                  send' (total + n) bufs
                with
                | Unix.Unix_error (Unix.EAGAIN, _, _) | Unix.Unix_error (Unix.EWOULDBLOCK, _, _) ->
                    let handler s = Future.run_with_state (send' total (wb :: bufs)) s in
                    Future.with_state (fun s -> (add_write fd handler s, Future.return ()))
                | Unix.Unix_error (err, _, _) as exn ->
                    let open Unix in
                    Future.Promise.set
                      p
                      (Error
                         (match err with
                         | ENOTSOCK | EBADF -> `E_bad_file
                         | EACCES -> `E_access
                         | ENOBUFS -> `E_no_buffers
                         | EHOSTUNREACH -> `E_host_unreachable
                         | EHOSTDOWN -> `E_host_down
                         | EPIPE -> `E_pipe
                         | _ -> `Unexpected exn))
                | exn -> Future.Promise.set p (Error (`Unexpected exn)))
          in
          let open Future.Infix_monad in
          send' 0 bufs >>= fun () -> Future.Promise.future p)

    let nodelay t enabled =
      guarded t (fun fd ->
          try
            Unix.setsockopt fd Unix.TCP_NODELAY enabled;
            Ok ()
          with
          | Unix.Unix_error (err, _, _) as exn ->
              let open Unix in
              Error
                (match err with
                | ENOTSOCK | EBADF -> `E_bad_file
                | _ -> `Unexpected exn)
          | exn -> Error (`Unexpected exn))
  end

  module Udp = struct
    let to_native t = Abb_fd_socket.fd t
    let of_native t = Abb_fd_socket.make t
    let create = create_sock ~kind:Unix.SOCK_DGRAM
    let bind = Tcp.bind
  end
end

module Process = struct
  module Pid = struct
    type t = int
    type native = int

    let of_native n = n
    let to_native t = t
  end

  type t = {
    pid : Pid.t;
    exit_code : Abb_intf.Process.Exit_code.t Future.t;
  }

  let int_of_signal = function
    | Abb_intf.Process.Signal.SIGABRT -> Sys_stdlib.sigabrt
    | Abb_intf.Process.Signal.SIGFPE -> Sys_stdlib.sigfpe
    | Abb_intf.Process.Signal.SIGHUP -> Sys_stdlib.sighup
    | Abb_intf.Process.Signal.SIGILL -> Sys_stdlib.sigill
    | Abb_intf.Process.Signal.SIGINT -> Sys_stdlib.sigint
    | Abb_intf.Process.Signal.SIGKILL -> Sys_stdlib.sigkill
    | Abb_intf.Process.Signal.SIGSEGV -> Sys_stdlib.sigsegv
    | Abb_intf.Process.Signal.SIGTERM -> Sys_stdlib.sigterm
    | Abb_intf.Process.Signal.Num s -> s

  let signal_of_int n =
    if n = Sys_stdlib.sigabrt then Abb_intf.Process.Signal.SIGABRT
    else if n = Sys_stdlib.sigfpe then Abb_intf.Process.Signal.SIGFPE
    else if n = Sys_stdlib.sighup then Abb_intf.Process.Signal.SIGHUP
    else if n = Sys_stdlib.sigill then Abb_intf.Process.Signal.SIGILL
    else if n = Sys_stdlib.sigint then Abb_intf.Process.Signal.SIGINT
    else if n = Sys_stdlib.sigkill then Abb_intf.Process.Signal.SIGKILL
    else if n = Sys_stdlib.sigsegv then Abb_intf.Process.Signal.SIGSEGV
    else if n = Sys_stdlib.sigterm then Abb_intf.Process.Signal.SIGTERM
    else Abb_intf.Process.Signal.Num n

  let wait_on_pid pid =
    Thread.run (fun () ->
        let pid', signal = Unix.waitpid ~mode:[] pid in
        assert (pid = pid');
        match signal with
        | Unix.WEXITED code -> Abb_intf.Process.Exit_code.Exited code
        | Unix.WSIGNALED code -> Abb_intf.Process.Exit_code.Signaled (signal_of_int code)
        | Unix.WSTOPPED code -> Abb_intf.Process.Exit_code.Stopped (signal_of_int code))

  let spawn ~stdin ~stdout ~stderr init_args =
    try
      let pid =
        let module P = Abb_intf.Process in
        match init_args.P.env with
        | Some env ->
            let env =
              CCArray.of_list @@ CCList.map (fun (k, v) -> CCString.concat "=" [ k; v ]) env
            in
            Unix.create_process_env
              ~prog:init_args.P.exec_name
              ~args:(CCArray.of_list init_args.P.args)
              ~env
              ~stdin
              ~stdout
              ~stderr
        | None ->
            Unix.create_process
              ~prog:init_args.P.exec_name
              ~args:(CCArray.of_list init_args.P.args)
              ~stdin
              ~stdout
              ~stderr
      in
      Ok { pid; exit_code = wait_on_pid pid }
    with
    | Unix.Unix_error (err, _, _) as exn ->
        let open Unix in
        Error
          (match err with
          | EAGAIN -> `E_again
          | ENOMEM -> `E_no_memory
          | _ -> `Unexpected exn)
    | exn -> Error (`Unexpected exn)

  let pid t = t.pid
  let wait t = t.exit_code

  let exit_code t =
    match Future.state t.exit_code with
    | `Det exit_code -> Some exit_code
    | `Undet | `Aborted | `Exn _ -> None

  let signal_pid ~pid signal = Unix.kill ~pid ~signal:(int_of_signal signal)
  let signal t signal = signal_pid ~pid:t.pid signal
end

(** A bounded MPSC channel. This scheduler is single-domain, so the implementation needs no locks or
    atomics: [send], [recv] and the event loop all run on the one scheduler domain and touch the
    channel sequentially. *)
module Chan = struct
  type 'a parked_send = {
    ps_value : 'a;
    ps_promise : (unit, [ `Chan_closed ]) result Future.Promise.t;
    ps_aborted : bool ref;
  }

  type 'a parked_recv = {
    pr_promise : ('a, [ `Chan_closed ]) result Future.Promise.t;
    pr_aborted : bool ref;
  }

  type 'a t = {
    capacity : int;
    buffer : 'a Queue.t;
    parked_sends : 'a parked_send Queue.t;
    parked_recvs : 'a parked_recv Queue.t;
    mutable closed : bool;
    (* The event loop's wakeup queue, captured on the first [send]/[recv] (both
       run inside a future and so can see the scheduler state). [Chan.close]
       needs it to deliver wakeups but has no state of its own. *)
    mutable wakeups : (El.t Abb_fut.State.t -> El.t Abb_fut.State.t) Queue.t option;
  }

  let create ~capacity () =
    if capacity < 1 then
      raise (Invalid_argument (Printf.sprintf "Chan.create: capacity is %d, must be >= 1" capacity));
    {
      capacity;
      buffer = Queue.create ();
      parked_sends = Queue.create ();
      parked_recvs = Queue.create ();
      closed = false;
      wakeups = None;
    }

  (* Take the next non-aborted parked entry, discarding aborted ones. *)
  let rec take_live aborted q =
    match Queue.take_opt q with
    | None -> None
    | Some e when !(aborted e) -> take_live aborted q
    | Some e -> Some e

  let capture_wakeups ch s = ch.wakeups <- Some (Abb_fut.State.state s).El.wakeups

  (* Producer-side wake of the parked consumer. [send] queues this on the
     event loop's wakeup queue instead of handing the value over inline,
     so it leaves the value in the buffer where a racing fast-path [recv]
     may take it before this op fires. An open, empty channel at that
     point is not an error: re-park the consumer and let the next [send]
     deliver to it. Failing it with [`Chan_closed] would be a spurious
     close. *)
  let wake_parked_recv ch s =
    match take_live (fun pr -> pr.pr_aborted) ch.parked_recvs with
    | None -> s
    | Some pr -> (
        match Queue.take_opt ch.buffer with
        | Some v ->
            (* Popping freed a slot: pull a parked sender into the buffer. *)
            let s =
              match take_live (fun ps -> ps.ps_aborted) ch.parked_sends with
              | None -> s
              | Some ps ->
                  Queue.push ps.ps_value ch.buffer;
                  Future.run_with_state (Future.Promise.set ps.ps_promise (Ok ())) s
            in
            Future.run_with_state (Future.Promise.set pr.pr_promise (Ok v)) s
        | None when ch.closed ->
            Future.run_with_state (Future.Promise.set pr.pr_promise (Error `Chan_closed)) s
        | None ->
            (* Buffer drained by a racing [recv]: re-park the consumer. *)
            Queue.push pr ch.parked_recvs;
            s)

  let send ch v =
    let f =
      Future.with_state (fun s ->
          capture_wakeups ch s;
          if ch.closed then (s, Future.return (Error `Chan_closed))
          else if Queue.length ch.buffer < ch.capacity then (
            Queue.push v ch.buffer;
            (* If a consumer is parked, defer its wake through the loop's
               wakeup queue. The value stays in the buffer so a racing
               fast-path [recv] can take it; [wake_parked_recv] re-parks
               the consumer when that happens. *)
            if not (Queue.is_empty ch.parked_recvs) then
              CCOption.iter (Queue.push (wake_parked_recv ch)) ch.wakeups;
            (s, Future.return (Ok ())))
          else
            (* Buffer full: park until a [recv] makes room. *)
            let aborted = ref false in
            let p =
              Future.Promise.create
                ~abort:(fun () ->
                  aborted := true;
                  Future.return ())
                ()
            in
            Queue.push { ps_value = v; ps_promise = p; ps_aborted = aborted } ch.parked_sends;
            (s, Future.Promise.future p))
    in
    (f : (unit, [ `Chan_closed ]) result Future.t :> (unit, [> `Chan_closed ]) result Future.t)

  let recv ch =
    let f =
      Future.with_state (fun s ->
          capture_wakeups ch s;
          match Queue.take_opt ch.buffer with
          | Some v ->
              (* A slot just freed up: pull one parked sender into the buffer. *)
              let wake =
                CCOption.map_or
                  ~default:(Future.return ())
                  (fun ps ->
                    Queue.push ps.ps_value ch.buffer;
                    Future.Promise.set ps.ps_promise (Ok ()))
                  (take_live (fun ps -> ps.ps_aborted) ch.parked_sends)
              in
              let open Future.Infix_monad in
              (s, wake >>| fun () -> Ok v)
          | None ->
              if ch.closed then (s, Future.return (Error `Chan_closed))
              else
                (* Buffer empty: park until a [send] arrives. *)
                let aborted = ref false in
                let p =
                  Future.Promise.create
                    ~abort:(fun () ->
                      aborted := true;
                      Future.return ())
                    ()
                in
                Queue.push { pr_promise = p; pr_aborted = aborted } ch.parked_recvs;
                (s, Future.Promise.future p))
    in
    (f : ('a, [ `Chan_closed ]) result Future.t :> ('a, [> `Chan_closed ]) result Future.t)

  let close ch =
    if not ch.closed then (
      ch.closed <- true;
      (* If no [send]/[recv] ever ran, [wakeups] is [None] and nothing is parked. *)
      CCOption.iter
        (fun wakeups ->
          let fail promise aborted =
            if not !aborted then
              Queue.push
                (fun s -> Future.run_with_state (Future.Promise.set promise (Error `Chan_closed)) s)
                wakeups
          in
          Queue.iter (fun ps -> fail ps.ps_promise ps.ps_aborted) ch.parked_sends;
          Queue.iter (fun pr -> fail pr.pr_promise pr.pr_aborted) ch.parked_recvs;
          Queue.clear ch.parked_sends;
          Queue.clear ch.parked_recvs)
        ch.wakeups)
end
