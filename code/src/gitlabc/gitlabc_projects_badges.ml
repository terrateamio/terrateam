module PostApiV4ProjectsIdBadges = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidbadges : Gitlabc_components.PostApiV4ProjectsIdBadges.t;
          [@key "postApiV4ProjectsIdBadges"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/projects/{id}/badges"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdBadges = struct
  module Parameters = struct
    type t = {
      id : string;
      name : string option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/badges"

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
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("name", Var (params.name, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdBadgesRender = struct
  module Parameters = struct
    type t = {
      id : string;
      image_url : string;
      link_url : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/badges/render"

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
           ("link_url", Var (params.link_url, String)); ("image_url", Var (params.image_url, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdBadgesBadgeId = struct
  module Parameters = struct
    type t = {
      badge_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/badges/{badge_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("badge_id", Var (params.badge_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdBadgesBadgeId = struct
  module Parameters = struct
    type t = {
      badge_id : int;
      id : string;
      putapiv4projectsidbadgesbadgeid : Gitlabc_components.PutApiV4ProjectsIdBadgesBadgeId.t;
          [@key "putApiV4ProjectsIdBadgesBadgeId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/badges/{badge_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("badge_id", Var (params.badge_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdBadgesBadgeId = struct
  module Parameters = struct
    type t = {
      badge_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/badges/{badge_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("badge_id", Var (params.badge_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
