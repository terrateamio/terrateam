module Primary = struct
  module Parameters = struct
    module Primary = struct
      module Allowed_merge_methods = struct
        module Items = struct
          let t_of_yojson = function
            | `String "merge" -> Ok "merge"
            | `String "squash" -> Ok "squash"
            | `String "rebase" -> Ok "rebase"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        allowed_merge_methods : Allowed_merge_methods.t option; [@default None]
        automatic_copilot_code_review_enabled : bool option; [@default None]
        dismiss_stale_reviews_on_push : bool;
        require_code_owner_review : bool;
        require_last_push_approval : bool;
        required_approving_review_count : int;
        required_review_thread_resolution : bool;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Type = struct
    let t_of_yojson = function
      | `String "pull_request" -> Ok "pull_request"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    parameters : Parameters.t option; [@default None]
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
