type t = {
  fd : Unix.file_descr;
  closed : bool Atomic.t;
}

let make fd = { fd; closed = Atomic.make false }
let fd t = t.fd
let is_closed t = Atomic.get t.closed
let close_once t = Atomic.compare_and_set t.closed false true
