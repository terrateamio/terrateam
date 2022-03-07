module Create = struct
  module Parameters = struct end

  module Request_body = struct
    module Primary = struct
      module Files = struct
        module Additional = struct
          module Primary = struct
            type t = { content : string } [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
      end

      module Public = struct
        module V0 = struct
          type t = bool [@@deriving yojson { strict = false; meta = true }, show]
        end

        module V1 = struct
          let t_of_yojson = function
            | `String "true" -> Ok "true"
            | `String "false" -> Ok "false"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t =
          | V0 of V0.t
          | V1 of V1.t
        [@@deriving show]

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
      end

      type t = {
        description : string option; [@default None]
        files : Files.t;
        public : Public.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Gist_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `Created of Created.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/gists"

  let make ~body () =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
      since : string option; [@default None]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Base_gist.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
      ]
  end

  let url = "/gists"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("since", Var (params.since, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_public = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
      since : string option; [@default None]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Base_gist.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/gists/public"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("since", Var (params.since, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_starred = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
      since : string option; [@default None]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Base_gist.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
      ]
  end

  let url = "/gists/starred"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("since", Var (params.since, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update = struct
  module Parameters = struct
    type t = { gist_id : string } [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Files = struct
          module Additional = struct
            module V0 = struct
              module Primary = struct
                type t = {
                  content : string;
                  filename : string option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module V1 = struct
              module Primary = struct
                type t = {
                  content : string option; [@default None]
                  filename : string option;
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module V2 = struct
              module Primary = struct
                type t = {
                  content : string option; [@default None]
                  filename : string option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t =
              | V0 of V0.t
              | V1 of V1.t
              | V2 of V2.t
            [@@deriving show]

            let of_yojson =
              Json_schema.any_of
                (let open CCResult in
                [
                  (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                  (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                  (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
                ])

            let to_yojson = function
              | V0 v -> V0.to_yojson v
              | V1 v -> V1.to_yojson v
              | V2 v -> V2.to_yojson v
          end

          include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
        end

        type t = {
          description : string;
          files : Files.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module V1 = struct
      module Primary = struct
        module Files = struct
          module Additional = struct
            module V0 = struct
              module Primary = struct
                type t = {
                  content : string;
                  filename : string option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module V1 = struct
              module Primary = struct
                type t = {
                  content : string option; [@default None]
                  filename : string option;
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module V2 = struct
              module Primary = struct
                type t = {
                  content : string option; [@default None]
                  filename : string option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t =
              | V0 of V0.t
              | V1 of V1.t
              | V2 of V2.t
            [@@deriving show]

            let of_yojson =
              Json_schema.any_of
                (let open CCResult in
                [
                  (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                  (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                  (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
                ])

            let to_yojson = function
              | V0 v -> V0.to_yojson v
              | V1 v -> V1.to_yojson v
              | V2 v -> V2.to_yojson v
          end

          include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
        end

        type t = {
          description : string option; [@default None]
          files : Files.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t =
      | V0 of V0.t
      | V1 of V1.t
    [@@deriving show]

    let of_yojson =
      Json_schema.any_of
        (let open CCResult in
        [
          (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
          (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
        ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
      | V1 v -> V1.to_yojson v
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Gist_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/gists/{gist_id}"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete = struct
  module Parameters = struct
    type t = { gist_id : string } [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `No_content
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/gists/{gist_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get = struct
  module Parameters = struct
    type t = { gist_id : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Gist_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Forbidden = struct
      module Primary = struct
        module Block = struct
          module Primary = struct
            type t = {
              created_at : string option; [@default None]
              html_url : string option; [@default None]
              reason : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          block : Block.t option; [@default None]
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/gists/{gist_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Create_comment = struct
  module Parameters = struct
    type t = { gist_id : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = { body : string } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Gist_comment.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `Created of Created.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/gists/{gist_id}/comments"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_comments = struct
  module Parameters = struct
    type t = {
      gist_id : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Gist_comment.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/gists/{gist_id}/comments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update_comment = struct
  module Parameters = struct
    type t = {
      comment_id : int;
      gist_id : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = { body : string } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Gist_comment.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/gists/{gist_id}/comments/{comment_id}"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)); ("comment_id", Var (params.comment_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete_comment = struct
  module Parameters = struct
    type t = {
      comment_id : int;
      gist_id : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `No_content
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/gists/{gist_id}/comments/{comment_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)); ("comment_id", Var (params.comment_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_comment = struct
  module Parameters = struct
    type t = {
      comment_id : int;
      gist_id : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Gist_comment.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Forbidden = struct
      module Primary = struct
        module Block = struct
          module Primary = struct
            type t = {
              created_at : string option; [@default None]
              html_url : string option; [@default None]
              reason : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          block : Block.t option; [@default None]
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/gists/{gist_id}/comments/{comment_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)); ("comment_id", Var (params.comment_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_commits = struct
  module Parameters = struct
    type t = {
      gist_id : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Gist_commit.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/gists/{gist_id}/commits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Fork = struct
  module Parameters = struct
    type t = { gist_id : string } [@@deriving make, show]
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Base_gist.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `Created of Created.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/gists/{gist_id}/forks"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_forks = struct
  module Parameters = struct
    type t = {
      gist_id : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Gist_simple.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/gists/{gist_id}/forks"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Unstar = struct
  module Parameters = struct
    type t = { gist_id : string } [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `No_content
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/gists/{gist_id}/star"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Star = struct
  module Parameters = struct
    type t = { gist_id : string } [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `No_content
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/gists/{gist_id}/star"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Check_is_starred = struct
  module Parameters = struct
    type t = { gist_id : string } [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Json_schema.Empty_obj.t [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `No_content
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/gists/{gist_id}/star"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Get_revision = struct
  module Parameters = struct
    type t = {
      gist_id : string;
      sha : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Gist_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/gists/{gist_id}/{sha}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("gist_id", Var (params.gist_id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_for_user = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
      since : string option; [@default None]
      username : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Base_gist.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/users/{username}/gists"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("username", Var (params.username, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("since", Var (params.since, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end
