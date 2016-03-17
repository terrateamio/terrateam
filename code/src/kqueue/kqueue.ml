module C = Ctypes
module F = Foreign
module P = PosixTypes

module Stubs = Kqueue_bindings.Stubs(Kqueue_stubs)

module Event = Kqueue_event
module Change = Kqueue_change

module Eventlist = struct
  type t = { kevents : Stubs.Kevent.t C.ptr
           ; capacity : int
           ; mutable size : int
           }

  let create count =
    { kevents = C.allocate_n Stubs.Kevent.t ~count
    ; capacity = count
    ; size = count
    }

  let capacity t = t.capacity

  let size t = t.size

  let set_size t size = t.size <- size

  let null = { kevents = C.(coerce (ptr void) (ptr Stubs.Kevent.t) null)
             ; capacity = 0
             ; size = 0
             }

  let set_from_list t kevents =
    let l = List.length kevents in
    assert (t.capacity <= l);
    t.size <- l;
    List.iteri
      (fun idx k ->
        C.((t.kevents +@ idx) <-@ k))
      kevents

  let of_list kevents =
    let count = List.length kevents in
    let t = create count in
    set_from_list t kevents;
    t

  let fold ~f ~init t =
    let rec f' acc = function
      | idx when idx < t.size ->
        f' (f acc C.(!@ (t.kevents +@ idx))) (idx + 1)
      | _ ->
        acc
    in
    f' init 0

  let to_list t =
    List.rev
      (fold ~f:(fun acc k -> k::acc) ~init:[] t)

  let iter ~f t =
    fold ~f:(fun () -> f) ~init:() t
end

module Timeout = struct
  type t = Stubs.Timespec.t

  let create ~sec ~nsec =
    let ts = C.make Stubs.Timespec.t in
    C.setf ts Stubs.Timespec.tv_sec (P.Time.of_int sec);
    C.setf ts Stubs.Timespec.tv_nsec (Signed.Long.of_int nsec);
    ts
end

module Bindings = struct
  let kqueue =
    F.foreign
      "kqueue"
      C.(void @-> returning int)

  let kevent =
    F.foreign
      "kevent"
      C.(int @->
         ptr Stubs.Kevent.t @->
         int @->
         ptr Stubs.Kevent.t @->
         int @->
         ptr Stubs.Timespec.t @->
         returning int)
end

type t = int

let create () = Bindings.kqueue ()

let kevent t ~changelist ~eventlist ~timeout =
  let timeout =
    match timeout with
      | Some ts -> C.addr ts
      | None -> C.(from_voidp Stubs.Timespec.t null)
  in
  let ret =
    Bindings.kevent
      t
      changelist.Eventlist.kevents
      changelist.Eventlist.capacity
      eventlist.Eventlist.kevents
      eventlist.Eventlist.size
      timeout
  in
  if ret > -1 then
    eventlist.Eventlist.size <- ret
  else
    eventlist.Eventlist.size <- 0;
  ret

external unsafe_int_of_file_descr : Unix.file_descr -> int = "%identity"
external unsafe_file_descr_of_int : int -> Unix.file_descr = "%identity"
