module Remove_restrictions_for_org = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/interaction-limits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Set_restrictions_for_org = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Request_body = struct
    type t = Githubc2_components.Interaction_limit.t
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Interaction_limit_response.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/orgs/{org}/interaction-limits"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_restrictions_for_org = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module V1 = struct
        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
      end

      type t =
        | V0 of Githubc2_components.Interaction_limit_response.t
        | V1 of V1.t
      [@@deriving show]

      let of_yojson =
        Json_schema.any_of
          (let open CCResult in
          [
            (fun v ->
              map (fun v -> V0 v) (Githubc2_components.Interaction_limit_response.of_yojson v));
            (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
          ])

      let to_yojson = function
        | V0 v -> Githubc2_components.Interaction_limit_response.to_yojson v
        | V1 v -> V1.to_yojson v
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/interaction-limits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_restrictions_for_repo = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Conflict = struct end

    let t = [ ("204", fun _ -> Ok `No_content); ("409", fun _ -> Ok `Conflict) ]
  end

  let url = "/repos/{owner}/{repo}/interaction-limits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Set_restrictions_for_repo = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    type t = Githubc2_components.Interaction_limit.t
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Interaction_limit_response.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Conflict = struct end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson); ("409", fun _ -> Ok `Conflict);
      ]
  end

  let url = "/repos/{owner}/{repo}/interaction-limits"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_restrictions_for_repo = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module V1 = struct
        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
      end

      type t =
        | V0 of Githubc2_components.Interaction_limit_response.t
        | V1 of V1.t
      [@@deriving show]

      let of_yojson =
        Json_schema.any_of
          (let open CCResult in
          [
            (fun v ->
              map (fun v -> V0 v) (Githubc2_components.Interaction_limit_response.of_yojson v));
            (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
          ])

      let to_yojson = function
        | V0 v -> Githubc2_components.Interaction_limit_response.to_yojson v
        | V1 v -> V1.to_yojson v
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/interaction-limits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_restrictions_for_authenticated_user = struct
  module Parameters = struct end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/user/interaction-limits"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Set_restrictions_for_authenticated_user = struct
  module Parameters = struct end

  module Request_body = struct
    type t = Githubc2_components.Interaction_limit.t
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Interaction_limit_response.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/user/interaction-limits"

  let make ~body () =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_restrictions_for_authenticated_user = struct
  module Parameters = struct end

  module Responses = struct
    module OK = struct
      module V1 = struct
        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
      end

      type t =
        | V0 of Githubc2_components.Interaction_limit_response.t
        | V1 of V1.t
      [@@deriving show]

      let of_yojson =
        Json_schema.any_of
          (let open CCResult in
          [
            (fun v ->
              map (fun v -> V0 v) (Githubc2_components.Interaction_limit_response.of_yojson v));
            (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
          ])

      let to_yojson = function
        | V0 v -> Githubc2_components.Interaction_limit_response.to_yojson v
        | V1 v -> V1.to_yojson v
    end

    module No_content = struct end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson); ("204", fun _ -> Ok `No_content);
      ]
  end

  let url = "/user/interaction-limits"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end