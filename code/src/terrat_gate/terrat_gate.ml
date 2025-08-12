module Match = Terrat_base_repo_config_v1.Access_control.Match

type t = {
  all_of : Match.t list; [@default []]
  any_of : Match.t list; [@default []]
  any_of_count : int; [@default 0]
}
[@@deriving yojson { strict = false }, show]

module Result = struct
  type t_ = t [@@deriving show]

  (** A result is the remaining gate that needs to pass. *)
  type t = t_ [@@deriving show]
end
