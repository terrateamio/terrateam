module Http = Abb_js_fetch

module Io_err = struct
  type t = {
    name : string;
    message : string;
    stack : string;
  }
  [@@deriving show]

  let of_js_error err =
    {
      name = Jstr.to_string (Jv.Error.name err);
      message = Jstr.to_string (Jv.Error.message err);
      stack = Jstr.to_string (Jv.Error.stack err);
    }
end

type err =
  [ `Conversion_err of string * string Openapi.Response.t
  | `Missing_response of string Openapi.Response.t
  | `Io_err of (Jv.Error.t[@printer fun fmt v -> Io_err.(pp fmt (of_js_error v))])
  | `Forbidden
  | `Not_found
  ]
[@@deriving show]

type work_manifests_err =
  [ err
  | `Bad_request of Terrat_api_installations.List_work_manifests.Responses.Bad_request.t
  ]
[@@deriving show]

type work_manifest_outputs_err =
  [ err
  | `Bad_request of Terrat_api_installations.Get_work_manifest_outputs.Responses.Bad_request.t
  ]
[@@deriving show]

type dirspaces_err =
  [ err
  | `Bad_request of Terrat_api_installations.List_dirspaces.Responses.Bad_request.t
  ]
[@@deriving show]

module Io = struct
  type 'a t = 'a Abb_js.Future.t
  type err = Jv.Error.t

  let ( >>= ) = Abb_js.Future.Infix_monad.( >>= )
  let return = Abb_js.Future.return

  let call ?body ~headers ~meth url =
    let url = Uri.to_string url in
    let meth =
      match meth with
      | `Get -> `GET
      | `Delete -> `DELETE
      | `Patch -> assert false
      | `Put -> `PUT
      | `Post -> `POST
    in
    Http.fetch ?body ~headers ~meth ~url ()
    >>= function
    | Ok resp ->
        return
          (Ok
             (Openapi.Response.make
                ~headers:(Http.Response.headers resp)
                ~status:(Http.Response.status resp)
                (Http.Response.text resp)))
    | Error (`Js_err err) -> return (Error (`Io_err err))
end

module Api = Openapi.Make (Io)

module Page = struct
  let parse_link s =
    let open CCOption.Infix in
    CCString.Split.left ~by:"; " s
    >>= fun (link, rel) ->
    let uri = Uri.of_string (String.sub link 1 (String.length link - 2)) in
    CCString.Split.left ~by:"=" rel
    >>= function
    | "rel", n ->
        let name = String.sub n 1 (String.length n - 2) in
        Some (name, uri)
    | _ -> None

  let rec parse_links s =
    if String.length s > 0 then
      let open CCOption.Infix in
      match CCString.Split.left ~by:", " s with
      | Some (left, right) ->
          parse_link left >>= fun link -> parse_links right >>= fun rest -> Some (link :: rest)
      | None -> parse_link s >>= fun link -> Some [ link ]
    else Some []

  let of_response resp elts =
    let headers = Openapi.Response.headers resp in
    match CCList.Assoc.get ~eq:CCString.equal "link" headers with
    | Some link -> (
        match parse_links link with
        | Some links ->
            let next =
              CCOption.flat_map
                (CCFun.flip Uri.get_query_param' "page")
                (CCList.Assoc.get ~eq:CCString.equal "next" links)
            in
            let prev =
              CCOption.flat_map
                (CCFun.flip Uri.get_query_param' "page")
                (CCList.Assoc.get ~eq:CCString.equal "prev" links)
            in
            Brtl_js2_page.Page.make ?next ?prev elts
        | None ->
            Brtl_js2.Brr.Console.(log [ Jstr.v "Could not parse links"; Jstr.v link ]);
            Brtl_js2_page.Page.make elts)
    | None -> Brtl_js2_page.Page.make elts
end

type t = unit

let call = Api.call
let create () = ()

let logout t =
  let open Abb_js_future_combinators.Infix_result_monad in
  call (Terrat_api_user.Logout.make ())
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK -> Abb_js.Future.return (Ok ())
  | `Forbidden -> Abb_js.Future.return (Ok ())

let whoami t =
  let open Abb_js_future_combinators.Infix_result_monad in
  call (Terrat_api_user.Whoami.make ())
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK user -> Abb_js.Future.return (Ok (Some user))
  | `Forbidden -> Abb_js.Future.return (Ok None)

let task ~id t =
  let open Abb_js_future_combinators.Infix_result_monad in
  call Terrat_api_tasks.Get.(make Parameters.(make ~id))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK r -> Abb_js.Future.return (Ok r)
  | `Forbidden -> Abb_js.Future.return (Error `Forbidden)

let server_config t =
  let open Abb_js_future_combinators.Infix_result_monad in
  call Terrat_api_server.Config.(make ())
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK r -> Abb_js.Future.return (Ok r)
