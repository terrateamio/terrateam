type to_yaml_string_err = [ `Error ] [@@deriving show]
type of_yaml_string_err = [ `Error ] [@@deriving show]

val to_yaml_string : Yojson.Safe.t -> (string, [> to_yaml_string_err ]) result Abb.Future.t
val of_yaml_string : string -> (Yojson.Safe.t, [> of_yaml_string_err ]) result Abb.Future.t
