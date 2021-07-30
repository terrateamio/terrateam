module Make (Abb : Abb_intf.S) : sig
  val with_filename :
    ?temp_dir:string ->
    prefix:string ->
    suffix:string ->
    (string -> ('a, ([> `Temp_file_error of string ] as 'e)) result Abb.Future.t) ->
    ('a, 'e) result Abb.Future.t

  val with_dirname :
    ?temp_dir:string ->
    prefix:string ->
    suffix:string ->
    (string -> ('a, ([> `Temp_dir_error ] as 'e)) result Abb.Future.t) ->
    ('a, 'e) result Abb.Future.t
end
