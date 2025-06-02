module PostApiV4ProjectsIdWikis = struct
  module Parameters = struct
    type t = {
      id : int;
      postapiv4projectsidwikis : Gitlabc_components.PostApiV4ProjectsIdWikis.t;
          [@key "postApiV4ProjectsIdWikis"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/wikis"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdWikis = struct
  module Parameters = struct
    type t = {
      id : int;
      with_content : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/wikis"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("with_content", Var (params.with_content, Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdWikisAttachments = struct
  module Parameters = struct
    type t = {
      id : int;
      postapiv4projectsidwikisattachments : Gitlabc_components.PostApiV4ProjectsIdWikisAttachments.t;
          [@key "postApiV4ProjectsIdWikisAttachments"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/wikis/attachments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdWikisSlug = struct
  module Parameters = struct
    type t = {
      id : int;
      slug : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/wikis/{slug}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("slug", Var (params.slug, String)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdWikisSlug = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4projectsidwikisslug : Gitlabc_components.PutApiV4ProjectsIdWikisSlug.t;
          [@key "putApiV4ProjectsIdWikisSlug"]
      slug : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/wikis/{slug}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("slug", Var (params.slug, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdWikisSlug = struct
  module Parameters = struct
    type t = {
      id : int;
      render_html : bool; [@default false]
      slug : string;
      version : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/projects/{id}/wikis/{slug}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("slug", Var (params.slug, String)); ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("version", Var (params.version, Option String));
           ("render_html", Var (params.render_html, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end
