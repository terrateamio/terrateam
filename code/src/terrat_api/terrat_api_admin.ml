module Drifts = struct
  module Parameters = struct end

  module Responses = struct
    module OK = struct
      module Results = struct
        module Items = struct
          module Run_type = struct
            let t_of_yojson = function
              | `String "plan" -> Ok "plan"
              | `String "apply" -> Ok "apply"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = false }, show, eq]
          end

          type t = {
            completed_at : string option; [@default None]
            created_at : string;
            id : string;
            name : string;
            owner : string;
            run_type : Run_type.t;
            state : string;
          }
          [@@deriving yojson { strict = true; meta = true }, show, eq]
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = false }, show, eq]
      end

      type t = { results : Results.t } [@@deriving yojson { strict = true; meta = true }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/api/v1/admin/drifts"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
