(** Abb_intf defines the interface that users of Abb should program against as
    well as what backends should implement.  A monadic interface is requires as
    well as low-level OS operations. This is targeted at POSIX-like OS's.

    Unless otherwise specified, no operations on a single value (such as a file
    or socket) are safe to execute concurrent operations. *)

module Errors = struct
  let pp_exn fmt exn = Format.fprintf fmt "%s" (Printexc.to_string exn)
  let equal_exn = ( = )

  type unexpected = [ `Unexpected of exn ] [@@deriving show, eq]

  type open_file =
    [ `E_not_dir
    | `E_name_too_long
    | `E_no_entity
    | `E_access
    | `E_permission
    | `E_loop
    | `E_file_table_full
    | `E_no_space
    | `E_io
    | `E_exists
    | `E_invalid
    | unexpected
    ]
  [@@deriving show, eq]

  type read =
    [ `E_bad_file
    | `E_io
    | `E_invalid
    | `E_is_dir
    | unexpected
    ]
  [@@deriving show, eq]

  type pread =
    [ `E_nxio
    | read
    ]

  type write =
    [ `E_bad_file
    | `E_pipe
    | `E_invalid
    | `E_no_space
    | `E_io
    | `E_permission
    | unexpected
    ]
  [@@deriving show, eq]

  type pwrite =
    [ `E_nxio
    | write
    ]

  type lseek =
    [ `E_bad_file
    | `E_nxio
    | `E_invalid
    | unexpected
    ]
  [@@deriving show, eq]

  type close =
    [ `E_bad_file
    | `E_no_space
    | unexpected
    ]
  [@@deriving show, eq]

  type unlink =
    [ `E_not_dir
    | `E_is_dir
    | `E_name_too_long
    | `E_no_entity
    | `E_access
    | `E_loop
    | `E_permission
    | `E_io
    | `E_no_space
    | unexpected
    ]
  [@@deriving show, eq]

  type mkdir =
    [ `E_not_dir
    | `E_is_dir
    | `E_name_too_long
    | `E_no_entity
    | `E_access
    | `E_loop
    | `E_permission
    | `E_io
    | `E_no_space
    | `E_exists
    | unexpected
    ]
  [@@deriving show, eq]

  type rmdir =
    [ `E_not_dir
    | `E_name_too_long
    | `E_no_entity
    | `E_not_empty
    | `E_access
    | `E_loop
    | `E_permission
    | `E_invalid
    | `E_busy
    | `E_io
    | `E_exists
    | unexpected
    ]
  [@@deriving show, eq]

  type readdir = unexpected [@@deriving show, eq]

  type stat =
    [ `E_access
    | `E_io
    | `E_loop
    | `E_name_too_long
    | `E_no_entity
    | `E_not_dir
    | unexpected
    ]
  [@@deriving show, eq]

  type fstat =
    [ `E_bad_file
    | `E_invalid
    | stat
    ]
  [@@deriving show, eq]

  type rename =
    [ `E_name_too_long
    | `E_no_entity
    | `E_access
    | `E_permission
    | `E_loop
    | `E_not_dir
    | `E_is_dir
    | `E_no_space
    | `E_io
    | `E_invalid
    | `E_not_empty
    | unexpected
    ]
  [@@deriving show, eq]

  type truncate =
    [ `E_not_dir
    | `E_name_too_long
    | `E_no_entity
    | `E_access
    | `E_loop
    | `E_permission
    | `E_is_dir
    | `E_invalid
    | `E_io
    | unexpected
    ]
  [@@deriving show, eq]

  type ftruncate =
    [ `E_bad_file
    | truncate
    ]
  [@@deriving show, eq]

  type chmod =
    [ `E_not_dir
    | `E_name_too_long
    | `E_no_entity
    | `E_access
    | `E_loop
    | `E_permission
    | `E_io
    | unexpected
    ]
  [@@deriving show, eq]

  type fchmod =
    [ `E_bad_file
    | `E_invalid
    | chmod
    ]
  [@@deriving show, eq]

  type symlink =
    [ `E_not_dir
    | `E_name_too_long
    | `E_no_entity
    | `E_access
    | `E_loop
    | `E_exists
    | `E_permission
    | `E_io
    | `E_no_space
    | unexpected
    ]
  [@@deriving show, eq]

  type link =
    [ `E_not_dir
    | `E_name_too_long
    | `E_no_entity
    | `E_op_not_supported
    | `E_access
    | `E_loop
    | `E_exists
    | `E_permission
    | `E_no_space
    | `E_io
    | unexpected
    ]
  [@@deriving show, eq]

  type chown =
    [ `E_not_dir
    | `E_name_too_long
    | `E_no_entity
    | `E_access
    | `E_loop
    | `E_permission
    | `E_io
    | unexpected
    ]
  [@@deriving show, eq]

  type fchown =
    [ `E_bad_file
    | chown
    ]
  [@@deriving show, eq]

  type recvfrom =
    [ `E_bad_file
    | `E_connection_reset
    | unexpected
    ]
  [@@deriving show, eq]

  type sendto =
    [ `E_bad_file
    | `E_access
    | `E_no_buffers
    | `E_host_unreachable
    | `E_host_down
    | `E_connection_refused
    | unexpected
    ]
  [@@deriving show, eq]

  type sock_close =
    [ `E_bad_file
    | `E_connection_reset
    | unexpected
    ]
  [@@deriving show, eq]

  type listen =
    [ `E_bad_file
    | `E_dest_address_required
    | `E_invalid
    | `E_op_not_supported
    | unexpected
    ]
  [@@deriving show, eq]

  type accept =
    [ `E_bad_file
    | `E_file_table_full
    | `E_invalid
    | `E_connection_aborted
    | unexpected
    ]
  [@@deriving show, eq]

  type sock_create =
    [ `E_access
    | `E_address_family_not_supported
    | `E_file_table_full
    | `E_no_buffers
    | `E_permission
    | `E_protocol_not_supported
    | `E_protocol_type
    | unexpected
    ]
  [@@deriving show, eq]

  type bind =
    [ `E_bad_file
    | `E_again
    | `E_invalid
    | `E_address_not_available
    | `E_address_in_use
    | `E_address_family_not_supported
    | `E_access
    | `E_permission
    | `E_not_dir
    | `E_name_too_long
    | `E_no_entity
    | `E_loop
    | `E_io
    | `E_is_dir
    | unexpected
    ]
  [@@deriving show, eq]

  type tcp_sock_connect =
    [ `E_bad_file
    | `E_invalid
    | `E_address_not_available
    | `E_address_family_not_supported
    | `E_is_connected
    | `E_connection_refused
    | `E_connection_reset
    | `E_network_unreachable
    | `E_host_unreachable
    | `E_address_in_use
    | `E_access
    | unexpected
    ]
  [@@deriving show, eq]

  type recv =
    [ `E_bad_file
    | `E_connection_reset
    | `E_not_connected
    | unexpected
    ]
  [@@deriving show, eq]

  type send =
    [ `E_bad_file
    | `E_access
    | `E_no_buffers
    | `E_host_unreachable
    | `E_host_down
    | `E_network_down
    | `E_pipe
    | unexpected
    ]
  [@@deriving show, eq]

  type nodelay =
    [ `E_bad_file
    | unexpected
    ]
  [@@deriving show, eq]

  type spawn =
    [ `E_again
    | `E_no_memory
    | unexpected
    ]
  [@@deriving show, eq]
end

(** An implementation of future must provide an interface which works
    within  these types. *)
module Future = struct
  module State = struct
    type 'a t =
      [ `Det of 'a
      | `Undet
      | `Aborted
      | `Exn of (exn * Printexc.raw_backtrace option[@opaque])
      ]
    [@@deriving show]
  end

  module Set = struct
    type 'a t =
      [ `Det of 'a
      | `Aborted
      | `Exn of exn * Printexc.raw_backtrace option
      ]
  end

  module type S = sig
    type +'a t
    type abort = unit -> unit t

    (** A promise is the value used to set a [Future].  The promise can be
       aborted by turning it into a future with {!Promise.future} and then
       calling {!abort}. *)
    module Promise : sig
      type 'a fut = 'a t
      type 'a t

      (** Create a promise with an optional function to call on abort.  When
         aborting or canceling a future, the processing of the dependency tree
         is executed depth-first and the each abort is executed to completion
         before working back up the stack of aborts.  If calling the [abort]
         function raises and exception, then that exception is what is
         propagated through the tree, replacing whatever the existing error
         was. *)
      val create : ?abort:abort -> unit -> 'a t

      (** Return a future for the promise. *)
      val future : 'a t -> 'a fut

      (** Set the promise to a value and kick any values waiting for it.  If the
          promise is determined already, this is a no-op. *)
      val set : 'a t -> 'a -> unit fut

      (** Set the promise to an exception, this will fail all of the connected
         futures with the exception, causing their abort function to be
         executed.  The returned future is not determined until all aborts have
         been executed.  This is a no-op if the promise has already been
         determined. *)
      val set_exn : 'a t -> exn * Printexc.raw_backtrace option -> unit fut
    end

    (** Infix operators for the monadic interface *)
    module Infix_monad : sig
      val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
      val ( >>| ) : 'a t -> ('a -> 'b) -> 'b t
    end

    (** Infix operators for applicative interface *)
    module Infix_app : sig
      val ( <$> ) : ('a -> 'b) -> 'a t -> 'b t
      val ( <*> ) : ('a -> 'b) t -> 'a t -> 'b t
    end

    val return : 'a -> 'a t
    val bind : 'a t -> ('a -> 'b t) -> 'b t
    val app : ('a -> 'b) t -> 'a t -> 'b t
    val map : ('a -> 'b) -> 'a t -> 'b t

    (** Execute a future without waiting for it to complete.  The future can be
       applied with [bind], [app], or [map] later in order to get the value. *)
    val fork : 'a t -> 'a t t

    (** Query the state of the Future *)
    val state : 'a t -> 'a State.t

    (** Create a future that will evaluate to the determined state of the
       queried future.  If the await is aborted, the input future is aborted as
       well. *)
    val await : 'a t -> 'a Set.t t

    val await_map : ('a Set.t -> 'b) -> 'a t -> 'b t
    val await_bind : ('a Set.t -> 'b t) -> 'a t -> 'b t

    (** Abort a future and all of its undetermined dependencies.  The returned
       future will not be determined until all aborts of dependencies have been
       completed.  If a future has been determined already then {!abort} is a
       no-op. *)
    val abort : 'a t -> unit t

    (** Cancel a future, this is like an abort except it only spreads to
       watchers.  The returned future will not be determined until all aborts of
       dependencies have been completed.  If the future has been determined
       already then {!cancel} is a no-op. *)
    val cancel : 'a t -> unit t

    (** Add [dep] future as a dependency to the given future. *)
    val add_dep : dep:'a t -> 'b t -> unit
  end
end

module Future_set = Future.Set

module Write_buf = struct
  type t = {
    buf : bytes;
    pos : int;
    len : int;
  }
end

(** Flags and structures related to the file system *)
module File = struct
  module Permissions = struct
    type t = int [@@deriving show, eq]
  end

  module Flag = struct
    type t =
      | Read_only
      | Write_only
      | Read_write
      | Create of Permissions.t  (** Create the file with the specified permissions *)
      | Append
      | Truncate
      | Exclusive
    [@@deriving show, eq]
  end

  module File_kind = struct
    type t =
      | Regular  (** Regular file *)
      | Directory  (** Directory *)
      | Char  (** Character device *)
      | Block  (** Block device *)
      | Symlink  (** Symbolic link *)
      | Fifo  (** Named pipe *)
      | Socket  (** Socket *)
    [@@deriving show, eq]
  end

  (** The result of a file stat *)
  module Stat = struct
    type t = {
      dev : int;  (** Device number *)
      inode : int;  (** Inode number *)
      kind : File_kind.t;  (** Kind of the file *)
      perm : Permissions.t;  (** Access rights *)
      num_links : int;  (** Number of links *)
      uid : int;  (** User id of the owner *)
      gid : int;  (** Group ID of the file's group *)
      rdev : int;  (** Device minor number *)
      size : int;  (** Size in bytes *)
      atime : float;  (** Last access time *)
      mtime : float;  (** Last modification time *)
      ctime : float;  (** Last status change time *)
    }
    [@@deriving show, eq]
  end

  (** Seek commands for read and write *)
  module Seek = struct
    type t =
      | Cur  (** Relative to the current location *)
      | Set  (** Relative to the beginning *)
      | End  (** Relative to the end *)
    [@@deriving show, eq]
  end
end

(** Flags and structures related to sockets *)
module Socket = struct
  module Sockaddr = struct
    type inet = {
      addr : Unix.inet_addr;
      port : int;
    }

    type t =
      | Unix of string
      | Inet of inet
  end

  module Domain = struct
    type t =
      | Unix
      | Inet4
      | Inet6
  end

  module Socket_type = struct
    type t =
      | Stream
      | Dgram
      | Raw
      | Seqpacket
  end

  module Addrinfo_query = struct
    type t =
      | Host of string
      | Service of string
      | Host_service of (string * string)
  end

  module Addrinfo_hints = struct
    type t =
      | Family of Domain.t  (** Impose the given socket domain *)
      | Socket_type of Socket_type.t  (** Impose the given socket type *)
      | Protocol of int  (** Impose the given protocol *)
      | Numeric_host  (** Do not call name resolver, expect numeric IP address *)
      | Canon_name  (** Fill the ai_canonname field of the result *)
      | Passive  (** Set address to ``any'' address for use with Unix.bind *)
  end

  module Addrinfo = struct
    type t = {
      family : Domain.t;  (** protocol family for socket *)
      sock_type : Socket_type.t;  (** socket type *)
      protocol : int;  (** protocol for socket *)
      addr : Sockaddr.t;  (** socket-address for socket *)
      canon_name : string;  (** canonical name for service location *)
    }
  end
end

(** Data structures for handling process management *)
module Process = struct
  module Signal = struct
    type t =
      | SIGHUP
      | SIGINT
      | SIGQUIT
      | SIGABRT
      | SIGKILL
      | SIGBUS
      | SIGSEGV
      | SIGPIPE
      | SIGALRM
      | SIGTERM
      | SIGSTOP
      | SIGCONT
      | SIGCHLD
      | SIGUSR1
      | SIGUSR2
      | Num of int  (** If the signal cannot be put into any of the predefined ones *)
    [@@deriving show, eq]
  end

  module Exit_code = struct
    type t =
      | Exited of int
      | Signaled of Signal.t
      | Stopped of Signal.t
    [@@deriving show, eq]
  end

  (** A Dup represents a relationship between two values.  This is purely a
      container that expresses that relationship, it does not create anything.

      The relationship a Dup expresses is that one value should replace another
      value.  The usecase for this is when creating a new process and wanting to
      reassign [Native.t]s to other ones.  For example, replacing [stdin] in the
      spawned process with one from the parent program. *)
  module Dup : sig
    type 'a t

    val create : src:'a -> dst:'a -> 'a t
    val src : 'a t -> 'a
    val dst : 'a t -> 'a
  end = struct
    type 'a t = 'a * 'a

    let create ~src ~dst = (src, dst)
    let src = fst
    let dst = snd
  end

  type t = {
    exec_name : string;
    args : string list;
    env : (string * string) list option;
    cwd : string option;
  }
  [@@deriving show, eq]
end

(** The scheduler interface.  This only has those types and value that the
    implementation must specify.  Common values across all schedulers are pulled
    out of the module type *)
module type S = sig
  (** The Native module represents the underlying native platform type of files
      and sockets.  This does assume that files and sockets have the same
      underlying representation.  The type, [Native.t] must be available to the
      user. *)
  module Native : sig
    type t
  end

  (** {2 Futures} *)

  module Future : Future.S

  (** {2 Scheduler Management} *)

  module Scheduler : sig
    type t

    val create : unit -> t
    val destroy : t -> unit
    val run : t -> (unit -> 'a Future.t) -> t * 'a Future_set.t
    val run_with_state : (unit -> 'a Future.t) -> 'a Future_set.t
    val exec_duration : t -> float array
  end

  (** {2 System operations} *)

  module Sys : sig
    (** Sleep for the given number of seconds, fractional sections allowed. *)
    val sleep : float -> unit Future.t

    (** Get the wallclock time.  This is updated only once for each loop of the
        event loop.  Successive calls to [time] provide no guarantee about their
        values relative to each other. *)
    val time : unit -> float Future.t

    (** Return a monotonically increasing value.  The value is updated only once
        for each loop of the event loop.  The value itself represents the number
        of seconds since a stable arbitrary point in the past.  The values are
        guaranteed to always be equal to or greater than the previous call and
        subtracting them will give the number of seconds elapsed. *)
    val monotonic : unit -> float Future.t
  end

  (** {2 File operations} *)

  module File : sig
    type t

    (** Convert the underlying type to the native representation.  This is here
        as an escape hatch if a user needs to perform some system specific
        work. *)
    val to_native : t -> Native.t

    (** Convert the native representation to the underlying type. *)
    val of_native : Native.t -> t

    val stdin : t
    val stdout : t
    val stderr : t

    (** Open a file path with the specified flags.  The file created will be
        automatically closed during {!Process.spawn}. *)
    val open_file : flags:File.Flag.t list -> string -> (t, [> Errors.open_file ]) result Future.t

    (** Read bytes from a {!File.t}.

        @param buf buffer to read the contents into

        @param pos the position in the buffer to begin reading bytes into

        @param len the length of the buffer that can be used, starting at [pos]

        @return the number of bytes read *)
    val read : t -> buf:bytes -> pos:int -> len:int -> (int, [> Errors.read ]) result Future.t

    (** Read bytes from a {!File.t} from a particular offset within the file.
        It is undefined if the cursor within the file is modified after this
        operation or not.

        @param offset offset relative to the beginning of the file to start
        reading

        @param buf buffer to read the contents into

        @param pos the position in the buffer to begin reading bytes into

        @param len the length of the buffer that can be used, starting at [pos]

        @return the number of bytes read *)
    val pread :
      t -> offset:int -> buf:bytes -> pos:int -> len:int -> (int, [> Errors.pread ]) result Future.t

    (** Write the list of buffers to the file in the order they are specified.
        Not all bytes are guaranteed to be written.

        @return the number of bytes written *)
    val write : t -> Write_buf.t list -> (int, [> Errors.write ]) result Future.t

    (** Write the list of buffers to the file in the order they are specified
        starting from the specified offset.  Not all bytes are guaranteed to be
        written.  It is undefined if the cursor within the file is modified
        after this operation or not.

        @param offset offset relative to the beginning of the file to start
        writing

        @return the number of bytes written *)
    val pwrite : t -> offset:int -> Write_buf.t list -> (int, [> Errors.pwrite ]) result Future.t

    (** Seek to a point in the file relative to the [File.Seek.t] *)
    val lseek : t -> offset:int -> File.Seek.t -> (unit, [> Errors.lseek ]) result

    (** Close a {!File.t}. *)
    val close : t -> (unit, [> Errors.close ]) result Future.t

    (** Unlink a file path. *)
    val unlink : string -> (unit, [> Errors.unlink ]) result Future.t

    (** Make a directory with the specified permissions.  This will fail if the
        directory already exists but does not have the correct permissions. *)
    val mkdir : string -> File.Permissions.t -> (unit, [> Errors.mkdir ]) result Future.t

    (** Deleted a directory, this may fail if the directory is not empty. *)
    val rmdir : string -> (unit, [> Errors.rmdir ]) result Future.t

    (** Read the contents of a directory.  The returned list will not contain
        any path information, just the name of the entries in the directory. *)
    val readdir : string -> (string list, [> Errors.readdir ]) result Future.t

    (** Return stat information about a file path. *)
    val stat : string -> (File.Stat.t, [> Errors.stat ]) result Future.t

    (** Return stat information about the {!File.t}. *)
    val fstat : t -> (File.Stat.t, [> Errors.fstat ]) result Future.t

    (** Like {!stat} except in the case where the file path is a symbolic link
        it returns information about the link. *)
    val lstat : string -> (File.Stat.t, [> Errors.stat ]) result Future.t

    (** Rename a file path in [src] to [dst].  This may fail if the underlying
        OS does not support renaming the particular file, for example across
        mount point. *)
    val rename : src:string -> dst:string -> (unit, [> Errors.rename ]) result Future.t

    (** Truncate a file path to the given size (possibly growing it if it is
        larger than the file's size *)
    val truncate : string -> Int64.t -> (unit, [> Errors.truncate ]) result Future.t

    (** Truncate a {!File.t} to the given size (possibly growing it if it is
        larger than the file's size *)
    val ftruncate : t -> Int64.t -> (unit, [> Errors.ftruncate ]) result Future.t

    (** Modify the permissions of a file path where the permissions are
        specified as an [int]. *)
    val chmod : string -> File.Permissions.t -> (unit, [> Errors.chmod ]) result Future.t

    (** Modify the permissions of a {!File.t} where the permissions are
        specified as an [int]. *)
    val fchmod : t -> File.Permissions.t -> (unit, [> Errors.fchmod ]) result Future.t

    (** Make a symbolic link to a file or directory in [src] to the destination
        [dst], specified as a path. *)
    val symlink : src:string -> dst:string -> (unit, [> Errors.symlink ]) result Future.t

    (** Hard link a file or directory in [src] to the destination [dst],
        specified as a path. *)
    val link : src:string -> dst:string -> (unit, [> Errors.link ]) result Future.t

    (** Change the owner of a file, specified as a path, to a uid and a gid
        encoded as an int *)
    val chown : string -> uid:int -> gid:int -> (unit, [> Errors.chown ]) result Future.t

    (** Change the owner of a {!File.t} to a uid and a gid encoded as an int *)
    val fchown : t -> uid:int -> gid:int -> (unit, [> Errors.fchown ]) result Future.t
  end

  (** {2 Socket operations} *)

  module Socket : sig
    type tcp
    type udp

    (** A socket is parameterized over what type of socket it is. *)
    type 's t

    (** @param hints any hints for the look up

        @param query the address query to perform

        @return on success, the list of addresses *)
    val getaddrinfo :
      ?hints:Socket.Addrinfo_hints.t list ->
      Socket.Addrinfo_query.t ->
      (Socket.Addrinfo.t list, [> Errors.unexpected ]) result Future.t

    val getsockname : 'a t -> Socket.Sockaddr.t
    val getpeername : 'a t -> Socket.Sockaddr.t

    (** @param socket the tcp socket to receive on

        @param buf bytes to to place received data into

        @param pos position in the buf to start placing data

        @param len length of the buffer available for storing data

        @return on success, the number of bytes read and the sockaddr of the
        sender *)
    val recvfrom :
      'a t ->
      buf:bytes ->
      pos:int ->
      len:int ->
      (int * Socket.Sockaddr.t, [> Errors.recvfrom ]) result Future.t

    (** @param socket tcp the socket to send on

        @param bufs list of buffers to write, in order

        @param sockaddr the address to send to

        @return on success, the number of bytes written, this could be less
        than the length of the write bufs *)
    val sendto :
      'a t ->
      bufs:Write_buf.t list ->
      Socket.Sockaddr.t ->
      (int, [> Errors.sendto ]) result Future.t

    (** Close a socket, block until the close is finished. *)
    val close : 'a t -> (unit, [> Errors.sock_close ]) result Future.t

    (** Set a socket to listen. *)
    val listen : 'a t -> backlog:int -> (unit, [> Errors.listen ]) result

    (** Accept a new connection on a listening socket. *)
    val accept : 'a t -> ('a t, [> Errors.accept ]) result Future.t

    (** Set the future when the socket has data to be read. *)
    val readable : 'a t -> unit Future.t

    (** Set the future when the socket has data to be written. *)
    val writable : 'a t -> unit Future.t

    (** {2 TCP sockets} *)

    module Tcp : sig
      (** Convert the underlying type to the native representation.  This is here
          as an escape hatch if a user needs to perform some system specific
          work. *)
      val to_native : tcp t -> Native.t

      (** Convert the native representation to the underlying type. *)
      val of_native : Native.t -> tcp t

      (** Create a new TCP socket. The socket will be automatically closed
          during {!Process.spawn}. *)
      val create : domain:Socket.Domain.t -> (tcp t, [> Errors.sock_create ]) result

      (** Bind to a port and address. *)
      val bind : tcp t -> Socket.Sockaddr.t -> (unit, [> Errors.bind ]) result

      (** Connect to an address. *)
      val connect :
        tcp t -> Socket.Sockaddr.t -> (unit, [> Errors.tcp_sock_connect ]) result Future.t

      (** @param socket the tcp socket to receive on

          @param buf bytes to to place received data into

          @param pos position in the buf to start placing data

          @param len length of the buffer available for storing data

          @return on success, the number of bytes read *)
      val recv : tcp t -> buf:bytes -> pos:int -> len:int -> (int, [> Errors.recv ]) result Future.t

      (** @param socket tcp the socket to send on

          @param bufs list of buffers to write, in order

          @return on success, the number of bytes written, this could be less
          than the length of the write bufs *)
      val send : tcp t -> bufs:Write_buf.t list -> (int, [> Errors.send ]) result Future.t

      (** Set Nagle's algorithm on and off. *)
      val nodelay : tcp t -> bool -> (unit, [> Errors.nodelay ]) result
    end

    (** {2 UDP sockets} *)

    module Udp : sig
      (** Convert the underlying type to the native representation.  This is here
          as an escape hatch if a user needs to perform some system specific
          work. *)
      val to_native : udp t -> Native.t

      (** Convert the native representation to the underlying type. *)
      val of_native : Native.t -> udp t

      (** Create a new UDP socket.  The socket will be automatically closed
          during {!Process.spawn}. *)
      val create : domain:Socket.Domain.t -> (udp t, [> Errors.sock_create ]) result

      val bind : udp t -> Socket.Sockaddr.t -> (unit, [> Errors.bind ]) result
    end
  end

  (** {2 Process management} *)

  module Process : sig
    type t

    (** A [Pid.t] is a process identifier. *)
    module Pid : sig
      type t

      (** The native representation for a pid.  This type must be public to the
          user. *)
      type native

      val of_native : native -> t
      val to_native : t -> native
    end

    (** Spawn a process with a list of Dups.  The [src] side of the Dup will be
       closed once the [dst] has been replaced in the spawned process and the
       [src] will be closed in the parent process after forking.  In this case
       the Dups are {!Native}s because any descriptor type can be inherited by a
       spawned process.

        @return on success, the handle to the running process *)
    val spawn : Process.t -> Native.t Process.Dup.t list -> (t, [> Errors.spawn ]) result

    (** Get the pid of a process. *)
    val pid : t -> Pid.t

    (** Create a future that is determined when the process terminates. *)
    val wait : t -> Process.Exit_code.t Future.t

    (** Get the exit code of a process if it has terminated.

        @return the exit code of the process or [None] if it has not
        terminated *)
    val exit_code : t -> Process.Exit_code.t option

    (** Send the specified signal to the process handle. *)
    val signal : t -> Process.Signal.t -> unit

    (** Send the specified signal to an arbitrary process. *)
    val signal_pid : pid:Pid.t -> Process.Signal.t -> unit
  end

  module Thread : sig
    (** Run a function in a thread.  Aborting this future is not guaranteed to
        abort stop the thread. *)
    val run : (unit -> 'a) -> 'a Future.t
  end
end
