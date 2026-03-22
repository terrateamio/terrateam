module Delete =
  struct
    module Parameters =
      struct
        type t = {
          id: string ;
          installation_id: int ;
          vcs: string }[@@deriving (make, show, eq)]
      end
    module Responses =
      struct
        module OK = struct  end
        module Forbidden = struct  end
        type t = [ `OK  | `Forbidden ][@@deriving (show, eq)]
        let t =
          [("200", ((fun _ -> Ok `OK))); ("403", ((fun _ -> Ok `Forbidden)))]
      end
    let url = "/api/v1/{vcs}/installations/{installation_id}/api-users"
    let make params =
      Openapi.Request.make ~headers:[]
        ~url_params:(let open Openapi.Request.Var in
                       let open Parameters in
                         [("vcs", (Var (params.vcs, String)));
                         ("installation_id",
                           (Var (params.installation_id, Int)))])
        ~query_params:(let open Openapi.Request.Var in
                         let open Parameters in
                           [("id", (Var (params.id, String)))]) ~url
        ~responses:Responses.t `Delete
  end
module Create =
  struct
    module Parameters =
      struct
        type t = {
          installation_id: int ;
          vcs: string }[@@deriving (make, show, eq)]
      end
    module Request_body =
      struct
        type t = Terrat_api_components.Api_user_create.t[@@deriving
                                                          ((yojson
                                                              {
                                                                strict =
                                                                  false;
                                                                meta = true
                                                              }), show, eq)]
      end
    module Responses =
      struct
        module OK =
          struct
            type t = Terrat_api_components.Api_user.t[@@deriving
                                                       ((yojson
                                                           {
                                                             strict = false;
                                                             meta = false
                                                           }), show, eq)]
          end
        module Forbidden = struct  end
        module Not_found = struct  end
        type t = [ `OK of OK.t  | `Forbidden  | `Not_found ][@@deriving
                                                              (show, eq)]
        let t =
          [("200", (Openapi.of_json_body (fun v -> `OK v) OK.of_yojson));
          ("403", ((fun _ -> Ok `Forbidden)));
          ("404", ((fun _ -> Ok `Not_found)))]
      end
    let url = "/api/v1/{vcs}/installations/{installation_id}/api-users"
    let make ~body =
      fun params ->
        Openapi.Request.make ~body:(Request_body.to_yojson body) ~headers:[]
          ~url_params:(let open Openapi.Request.Var in
                         let open Parameters in
                           [("vcs", (Var (params.vcs, String)));
                           ("installation_id",
                             (Var (params.installation_id, Int)))])
          ~query_params:[] ~url ~responses:Responses.t `Post
  end
module List =
  struct
    module Parameters =
      struct
        type t =
          {
          installation_id: int ;
          limit: int option [@default None];
          vcs: string }[@@deriving (make, show, eq)]
      end
    module Responses =
      struct
        module OK =
          struct
            type t = Terrat_api_components.Api_user_page.t[@@deriving
                                                            ((yojson
                                                                {
                                                                  strict =
                                                                    false;
                                                                  meta =
                                                                    false
                                                                }), show, eq)]
          end
        module Forbidden = struct  end
        module Not_found = struct  end
        type t = [ `OK of OK.t  | `Forbidden  | `Not_found ][@@deriving
                                                              (show, eq)]
        let t =
          [("200", (Openapi.of_json_body (fun v -> `OK v) OK.of_yojson));
          ("403", ((fun _ -> Ok `Forbidden)));
          ("404", ((fun _ -> Ok `Not_found)))]
      end
    let url = "/api/v1/{vcs}/installations/{installation_id}/api-users"
    let make params =
      Openapi.Request.make ~headers:[]
        ~url_params:(let open Openapi.Request.Var in
                       let open Parameters in
                         [("vcs", (Var (params.vcs, String)));
                         ("installation_id",
                           (Var (params.installation_id, Int)))])
        ~query_params:(let open Openapi.Request.Var in
                         let open Parameters in
                           [("limit", (Var (params.limit, (Option Int))))])
        ~url ~responses:Responses.t `Get
  end
