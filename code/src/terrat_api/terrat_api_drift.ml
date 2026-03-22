module Initiate =
  struct
    module Parameters =
      struct
        type t = {
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
    let url = "/api/v1/{vcs}/installations/{installation_id}/drift"
    let make params =
      Openapi.Request.make ~headers:[]
        ~url_params:(let open Openapi.Request.Var in
                       let open Parameters in
                         [("vcs", (Var (params.vcs, String)));
                         ("installation_id",
                           (Var (params.installation_id, Int)))])
        ~query_params:[] ~url ~responses:Responses.t `Post
  end
