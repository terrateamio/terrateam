(** A buffered I/O interface for anything supporting [read], [write], and
   [close].  This takes an I/O value and creates a reader and writer value that
   are buffered.  Buffered readers and writer store bytes in memory to reduce
   the cost of reading and writing small chunks of memory.  The buffered reader
   also provides line-based I/O functionality.

    The underlying I/O objects cannot be used stand-alone after being wrapped in
   a buffer. *)

type read_err =
  [ `E_io
  | Abb_intf.Errors.unexpected
  ]

type write_err =
  [ `E_io
  | `E_no_space
  | Abb_intf.Errors.unexpected
  ]

type close_err =
  [ `E_io
  | Abb_intf.Errors.unexpected
  ]

(** Primary interface for a buffered reader and writer.  Only depends on a
    futures implementation. *)
module Make (Fut : Abb_intf.Future.S) : sig
  (** The callbacks that can be passed in to created a buffered reader and
      writer. *)
  module View : sig
    type t = {
      read : buf:bytes -> pos:int -> len:int -> (int, read_err) result Fut.t;
      write : bufs:Abb_intf.Write_buf.t list -> (int, write_err) result Fut.t;
      close : unit -> (unit, close_err) result Fut.t;
    }
  end

  type 'a t

  type reader

  type writer

  (** Create an in-memory reader and writer that is seeded with the input bytes.
      The reader and writer target the same memory such that writing to the
      writer is readable through the reader.  However, writes to the buffer can
      be read only after a {!flushed} has been evaluated. *)
  val of_bytes : ?size:int -> bytes -> reader t * writer t

  (** Create a reader and writer from a view. *)
  val of_view : ?size:int -> View.t -> reader t * writer t

  (** Read, at most [len] bytes, into [buf] at position [pos]. *)
  val read : reader t -> buf:bytes -> pos:int -> len:int -> (int, [> read_err ]) result Fut.t

  (** Read a line.  A line ends in [\n] or [\r\n].  In both cases, the line
      ending is removed.  An empty line means EOF. *)
  val read_line : reader t -> (string, [> read_err ]) result Fut.t

  (** Read a line but return bytes.  A line ends in [\n] or [\r\n].  In both
      cases, the line ending is removed.  An empty line means EOF. *)
  val read_line_bytes : reader t -> (bytes, [> read_err ]) result Fut.t

  (** Read a line and place it into a buffer.  A line ends in [\n] or [\r\n].
      In both cases, the line ending is removed.  An empty line means EOF *)
  val read_line_buffer : reader t -> Buffer.t -> (unit, [> read_err ]) result Fut.t

  (** Write [bufs] to the writer.  The bytes are only guaranteed to be written
      after a call to {!flushed} has been evaluated.  A call to [write] may
      write to the underlying I/O object if the buffer is full.  It is
      guaranteed that, on success, [bufs] is completely consumed. *)
  val write : writer t -> bufs:Abb_intf.Write_buf.t list -> (int, [> write_err ]) result Fut.t

  (** Close a reader, any bytes in the buffer are discarded. *)
  val close : reader t -> (unit, [> close_err ]) result Fut.t

  (** Close a writer, this guarantees that all of the bytes in the buffer are flushed. *)
  val close_writer : writer t -> (unit, [> write_err | close_err ]) result Fut.t

  (** Flush any values in the buffer the underlying I/O object and evaluate when done. *)
  val flushed : writer t -> (unit, [> write_err ]) result Fut.t
end

(** Standard conversions of I/O types in defined in [Abb]. *)
module Of (Abb : Abb_intf.S) : sig
  (** Convert a file to a buffered reader and writer. *)
  val of_file :
    ?size:int ->
    Abb.File.t ->
    Make(Abb.Future).reader Make(Abb.Future).t * Make(Abb.Future).writer Make(Abb.Future).t

  (** Convert a tcp socket to a buffered reader and writer. *)
  val of_tcp_socket :
    ?size:int ->
    Abb.Socket.tcp Abb.Socket.t ->
    Make(Abb.Future).reader Make(Abb.Future).t * Make(Abb.Future).writer Make(Abb.Future).t
end
