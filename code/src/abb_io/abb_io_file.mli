module Make (Abb : Abb_intf.S) : sig
  type with_file_err =
    [ Abb_intf.Errors.open_file
    | Abb_intf.Errors.close
    ]
  [@@deriving show]

  val with_file_in :
    f:(Abb.File.t -> ('a, 'e) result Abb.Future.t) ->
    string ->
    ('a, ([> with_file_err ] as 'e)) result Abb.Future.t

  val with_file_out :
    ?permissions:int ->
    f:(Abb.File.t -> ('a, 'e) result Abb.Future.t) ->
    string ->
    ('a, ([> with_file_err ] as 'e)) result Abb.Future.t

  val with_file_app :
    ?permissions:int ->
    f:(Abb.File.t -> ('a, 'e) result Abb.Future.t) ->
    string ->
    ('a, ([> with_file_err ] as 'e)) result Abb.Future.t

  val read_file :
    ?buf_size:int ->
    string ->
    (string, [> with_file_err | Abb_intf.Errors.read ]) result Abb.Future.t

  val write_file :
    fname:string -> string -> (unit, [> with_file_err | Abb_intf.Errors.write ]) result Abb.Future.t
end
