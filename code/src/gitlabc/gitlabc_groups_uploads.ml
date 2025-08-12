module GetApiV4GroupsIdUploads = struct
  module Parameters = struct
    type t = {
      id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/groups/{id}/uploads"

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
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4GroupsIdUploadsSecretFilename = struct
  module Parameters = struct
    type t = {
      filename : string;
      id : int;
      secret : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/uploads/{secret}/{filename}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("secret", Var (params.secret, String));
           ("filename", Var (params.filename, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4GroupsIdUploadsSecretFilename = struct
  module Parameters = struct
    type t = {
      filename : string;
      id : int;
      secret : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/groups/{id}/uploads/{secret}/{filename}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("secret", Var (params.secret, String));
           ("filename", Var (params.filename, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4GroupsIdUploadsUploadId = struct
  module Parameters = struct
    type t = {
      id : int;
      upload_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/uploads/{upload_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("upload_id", Var (params.upload_id, Int)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4GroupsIdUploadsUploadId = struct
  module Parameters = struct
    type t = {
      id : int;
      upload_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [ ("200", fun _ -> Ok `OK); ("403", fun _ -> Ok `Forbidden); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/groups/{id}/uploads/{upload_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("upload_id", Var (params.upload_id, Int)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
