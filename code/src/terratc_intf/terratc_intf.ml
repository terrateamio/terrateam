module Repo_config = struct
  type fetch_err =
    [ Terrat_base_repo_config_v1.of_version_1_err
    | `Repo_config_parse_err of string * string
    | Jsonu.merge_err
    | `Json_decode_err of string * string
    | `Unexpected_err of string
    | `Yaml_decode_err of string * string
    | `Error
    ]
  [@@deriving show]
end

module type S = sig
  module Github : sig
    module Client : sig
      type t
    end

    module Repo : sig
      type t

      val to_string : t -> string
      val owner : t -> string
      val name : t -> string
    end

    module Ref : sig
      type t

      val to_string : t -> string
    end

    module Remote_repo : sig
      type t

      val to_repo : t -> Repo.t
      val default_branch : t -> Ref.t
    end

    module Repo_config : sig
      val fetch_with_provenance :
        ?built_config:Yojson.Safe.t ->
        string ->
        Client.t ->
        Repo.t ->
        Ref.t ->
        ( string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t,
          [> Repo_config.fetch_err ] )
        result
        Abb.Future.t
    end
  end
end
