module Unix = UnixLabels
module Sys_stdlib = Sys

module Native = struct
  type t = unit
end

module Future = Abb_fut.Make (struct
  type t = unit
end)

module Scheduler = struct
  type t = unit

  let create () = failwith "nyi"

  let destroy t = failwith "nyi"

  let run t f = failwith "nyi"

  let run_with_state f = failwith "nyi"

  let exec_duration t = failwith "nyi"
end

module Sys = struct
  let sleep duration = failwith "nyi"

  let time () = failwith "nyi"

  let monotonic () = failwith "nyi"
end

module File = struct
  type t = unit

  let to_native t = t

  let of_native t = t

  let stdin = ()

  let stdout = ()

  let stderr = ()

  let open_file ~flags path = failwith "nyi"

  let read t ~buf ~pos ~len = failwith "nyi"

  let pread t ~offset ~buf ~pos ~len = failwith "nyi"

  let write t bufs = failwith "nyi"

  let pwrite t ~offset bufs = failwith "nyi"

  let lseek t ~offset seek = failwith "nyi"

  let close t = failwith "nyi"

  let unlink path = failwith "nyi"

  let mkdir path perms = failwith "nyi"

  let rmdir path = failwith "nyi"

  let readdir path = failwith "nyi"

  let stat path = failwith "nyi"

  let fstat t = failwith "nyi"

  let lstat path = failwith "nyi"

  let rename ~src ~dst = failwith "nyi"

  let truncate path offset = failwith "nyi"

  let ftruncate t offset = failwith "nyi"

  let chmod path permissions = failwith "nyi"

  let fchmod t permissions = failwith "nyi"

  let symlink ~src ~dst = failwith "nyi"

  let link ~src ~dst = failwith "nyi"

  let chown path ~uid ~gid = failwith "nyi"

  let fchown t ~uid ~gid = failwith "nyi"
end

module Socket = struct
  type tcp

  type udp

  type 'a t = unit

  let getaddrinfo ?hints query = failwith "nyi"

  let getsockname t = failwith "nyi"

  let getpeername t = failwith "nyi"

  let recvfrom t ~buf ~pos ~len = failwith "nyi"

  let sendto t ~bufs sockaddr = failwith "nyi"

  let close t = failwith "nyi"

  let listen t ~backlog = failwith "nyi"

  let accept t = failwith "nyi"

  let readable t = failwith "nyi"

  let writable t = failwith "nyi"

  module Tcp = struct
    let to_native t = t

    let of_native t = t

    let create ~domain = failwith "nyi"

    let bind t addr = failwith "nyi"

    let connect t addr = failwith "nyi"

    let recv t ~buf ~pos ~len = failwith "nyi"

    let send t ~bufs = failwith "nyi"

    let nodelay t enabled = failwith "nyi"
  end

  module Udp = struct
    let to_native t = t

    let of_native t = t

    let create ~domain = failwith "nyi"

    let bind t addr = failwith "nyi"
  end
end

module Process = struct
  type t = unit

  module Pid = struct
    type t = unit

    type native = unit

    let of_native () = ()

    let to_native () = ()
  end

  let spawn p dups = failwith "nyi"

  let pid t = failwith "nyi"

  let wait t = failwith "nyi"

  let exit_code t = failwith "nyi"

  let signal t signal = failwith "nyi"

  let signal_pid ~pid signal = failwith "nyi"
end

module Thread = struct
  let run f = failwith "nyi"
end
