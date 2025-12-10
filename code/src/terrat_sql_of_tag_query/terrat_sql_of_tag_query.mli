type of_ast_err =
  [ `Error of string
  | `In_dir_not_supported
  | `Bad_date_format of string
  | `Unknown_tag of string
  ]
[@@deriving show]

module Tag_map : sig
  type t =
    | Bigint
    | Bool
    | Datetime
    | Int
    | Json_array of string
    | Json_obj of string
    | Raw of (int -> string -> (string, [ `Error of string ]) result)
        (** Give raw access to building the query string. The first parameter is the index into the
            'strings' array this entry is, the second is the value of the tag. *)
    | Really_raw of (string CCVector.vector -> string -> (string, [ `Error of string ]) result)
        (** Get access to the underlying "strings" variable and do with it what you will. *)
    | Smallint
    | String
    | Uuid
end

type t

val empty : ?timezone:string -> ?sort_dir:[ `Asc | `Desc ] -> unit -> t

val of_ast :
  ?timezone:string ->
  ?sort_dir:[ `Asc | `Desc ] ->
  tag_map:(string * (Tag_map.t * string)) list ->
  Terrat_tag_query_parser_value.t ->
  (t, [> of_ast_err ]) result

val sql : t -> string
val bigints : t -> CCInt64.t list
val ints : t -> CCInt32.t list
val json : t -> string list
val smallints : t -> int list
val strings : t -> string list
val timezone : t -> string
val sort_dir : t -> [ `Asc | `Desc ]
