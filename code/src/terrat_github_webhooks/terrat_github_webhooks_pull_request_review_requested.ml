module V0 = struct
  module Primary = struct
    module Action = struct
      let t_of_yojson = function
        | `String "review_requested" -> Ok `Review_requested
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Review_requested -> `String "review_requested"

      type t = ([ `Review_requested ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      action : Action.t;
      installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
      number : int;
      organization : Terrat_github_webhooks_organization.t option; [@default None]
      pull_request : Terrat_github_webhooks_pull_request.t;
      repository : Terrat_github_webhooks_repository.t;
      requested_reviewer : Terrat_github_webhooks_user.t;
      sender : Terrat_github_webhooks_user.t;
    }
    [@@deriving yojson { strict = false; meta = true }, make, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module V1 = struct
  module Primary = struct
    module Action = struct
      let t_of_yojson = function
        | `String "review_requested" -> Ok `Review_requested
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Review_requested -> `String "review_requested"

      type t = ([ `Review_requested ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      action : Action.t;
      installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
      number : int;
      organization : Terrat_github_webhooks_organization.t option; [@default None]
      pull_request : Terrat_github_webhooks_pull_request.t;
      repository : Terrat_github_webhooks_repository.t;
      requested_team : Terrat_github_webhooks_team.t;
      sender : Terrat_github_webhooks_user.t;
    }
    [@@deriving yojson { strict = false; meta = true }, make, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t =
  | V0 of V0.t
  | V1 of V1.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
       (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
     ])

let to_yojson = function
  | V0 v -> V0.to_yojson v
  | V1 v -> V1.to_yojson v
