module GetApiV4GroupsIdInvitedGroups = struct
  module Parameters = struct
    module Relation = struct
      module Items = struct
        let t_of_yojson = function
          | `String "direct" -> Ok "direct"
          | `String "inherited" -> Ok "inherited"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
      end

      type t = Items.t list [@@deriving show, eq]
    end

    type t = {
      id : string;
      min_access_level : int option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 20]
      relation : Relation.t option; [@default None]
      search : string option; [@default None]
      with_custom_attributes : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/groups/{id}/invited_groups"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("relation", Var (params.relation, Option (Array String)));
           ("search", Var (params.search, Option String));
           ("min_access_level", Var (params.min_access_level, Option Int));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("with_custom_attributes", Var (params.with_custom_attributes, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end
