module Work_manifests : sig
  module Tag_query_sql : sig
    type t = {
      q : Buffer.t;
      strings : string CCVector.vector;
      bigints : int64 CCVector.vector;
      json : string CCVector.vector;
      timezone : string;
      mutable sort_dir : [ `Asc | `Desc ];
      mutable sort_by : string;
    }

    val empty : ?timezone:string -> unit -> t

    val of_ast :
      t ->
      Terrat_tag_query_parser_value.t ->
      ( unit,
        [> `Error of string
        | `In_dir_not_supported
        | `Bad_date_format of string
        | `Unknown_tag of string
        ] )
      result
  end

  val get :
    Terrat_config.t ->
    Terrat_storage.t ->
    int ->
    string option ->
    string option ->
    (string * Uuidm.t) Brtl_ep_paginate.Param.t option ->
    int ->
    Brtl_rtng.Handler.t
end

module Dirspaces : sig
  module Tag_query_sql : sig
    type t = {
      q : Buffer.t;
      strings : string CCVector.vector;
      bigints : int64 CCVector.vector;
      json : string CCVector.vector;
      timezone : string;
      mutable sort_dir : [ `Asc | `Desc ];
      mutable sort_by : string;
    }

    val empty : ?timezone:string -> unit -> t

    val of_ast :
      t ->
      Terrat_tag_query_parser_value.t ->
      ( unit,
        [> `Error of string
        | `In_dir_not_supported
        | `Bad_date_format of string
        | `Unknown_tag of string
        ] )
      result
  end

  val get :
    Terrat_config.t ->
    Terrat_storage.t ->
    int ->
    string option ->
    string option ->
    (string * string * string * Uuidm.t) Brtl_ep_paginate.Param.t option ->
    int ->
    Brtl_rtng.Handler.t
end

module Pull_requests : sig
  val get :
    Terrat_config.t ->
    Terrat_storage.t ->
    int ->
    int option ->
    int64 Brtl_ep_paginate.Param.t option ->
    int ->
    Brtl_rtng.Handler.t
end

module Repos : sig
  val get :
    Terrat_config.t ->
    Terrat_storage.t ->
    int ->
    string Brtl_ep_paginate.Param.t option ->
    int ->
    Brtl_rtng.Handler.t

  module Refresh : sig
    val post : Terrat_config.t -> Terrat_storage.t -> int -> Brtl_rtng.Handler.t
  end
end
