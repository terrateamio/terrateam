module Count = struct
  type t = {
    count : int;
    max_idx : int;
  }
end

module type S = sig
  (** The underlying store *)
  type t

  (** The type of a key *)
  type key

  (** The type of a path into a [data] value. *)
  type path

  (** The type of data stored in the store. *)
  type data

  (** The compute model of the store. *)
  module C : sig
    type 'a t
  end

  (** A record stored in the store. *)
  module Record : sig
    (** The type of a record, it is parameterized over the [data] type because in some cases records
        might not include the data attribute. *)
    type 'a t

    val committed : 'a t -> bool
    val created_at : 'a t -> string
    val data : 'a t -> 'a
    val idx : 'a t -> int
    val key : 'a t -> key
    val size : 'a t -> int
    val version : 'a t -> int
  end

  (** Get the record that corresponds to [key] from the store if it exists.

      If [select] is provided, the [data] returned will include only those paths.

      If [idx] is specified, retrieve that index, the default is [0].

      If [committed] is [false], included uncommitted records. *)
  val get :
    ?select:path list -> ?idx:int -> ?committed:bool -> key:key -> t -> data Record.t option C.t

  (** Set the [data] for [key] and return the created record.

      If [committed] is unset the default is [true]

      The default [idx] is [0]. *)
  val set : ?idx:int -> ?committed:bool -> key:key -> data -> t -> data Record.t C.t

  (** Perform a "compare and set" of the record for [key] at [idx]. The default value of [idx] is
      [0]. If the operation fails, [None] is returned.

      If [version] is set, the record in the database much have the same version for [cas] to
      succeed. If [version] is not set, the record must not exist for [cas] to succeed. *)
  val cas :
    ?idx:int -> ?committed:bool -> ?version:int -> key:key -> data -> t -> data Record.t option C.t

  (** Delete the record for [key] at [idx] (the default is [0]). If [version] is set, the version of
      the existing record must match for the delete to be successful. If [version] is not set, the
      delete is unconditional.

      If [delete] returns [true] then a delete was performed, [false] if the delete was
      unsuccessful. Deleting a record taht does not exist is considered unsuccessful. *)
  val delete : ?idx:int -> ?version:int -> key:key -> t -> bool C.t

  (** Retrieve the number of entries at a key as the maximum index. [count] will always be greater
      than 0 and [max_idx] might be greater than [count].

      [committed] defaults to [true] and only counts committed values. *)
  val count : ?committed:bool -> key:key -> t -> Count.t option C.t

  (** Get the size in number of bytes of [key]. If [idx] is not specified then it is the size of all
      indices under [key].

      [committed] defaults to [true] and computes the size of committed values.*)
  val size : ?idx:int -> ?committed:bool -> key:key -> t -> int option C.t

  (** Return a list of records that are greater than or greater than or equal to [key].

      [idx] specifies the index to start the first matching key.

      If [inclusive] is [true] then the first returning key is greater than or equal to
      [(key, idx)]. If it is [false] it is only greater than.

      If [committed] is [false] the uncommitted records are included in the result.

      [limit] specifies the maximum number of records that may be returned.

      [prefix] if [true], all returned keys are a have [key] as a prefix. *)
  val iter :
    ?select:path list ->
    ?idx:int ->
    ?inclusive:bool ->
    ?prefix:bool ->
    ?committed:bool ->
    ?limit:int ->
    key:key ->
    t ->
    data Record.t list C.t

  (** Given a list of keys, mark all of them as committed. Returning the list of keys that were
      updated. The list of keys include an optional index if only the particular index should
      committed. If no index is given, all of the indices under the key are committed *)
  val commit : keys:(key * int option) list -> t -> (key * int) list C.t
end
