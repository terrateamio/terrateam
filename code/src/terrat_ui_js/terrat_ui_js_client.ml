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
  type 'a t = {
    elts : 'a list;
    next : string list option;
    prev : string list option;
  }
  [@@deriving eq, show]

  let empty () = { elts = []; next = None; prev = None }
  let page t = t.elts
  let next t = t.next
  let prev t = t.prev

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
            { elts; next; prev }
        | None ->
            Brtl_js2.Brr.Console.(log [ Jstr.v "Could not parse links"; Jstr.v link ]);
            { elts; next = None; prev = None })
    | None -> { elts; next = None; prev = None }
end

type t = unit

let call = Api.call
let create () = ()

let whoami t =
  let open Abb_js_future_combinators.Infix_result_monad in
  call (Terrat_api_user.Whoami.make ())
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK user -> Abb_js.Future.return (Ok (Some user))
  | `Forbidden -> Abb_js.Future.return (Ok None)

let client_id t =
  let open Abb_js_future_combinators.Infix_result_monad in
  call (Terrat_api_api_v1.Client_id.make ())
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK Terrat_api_api_v1.Client_id.Responses.OK.{ client_id } ->
      Abb_js.Future.return (Ok client_id)
  | `Forbidden -> Abb_js.Future.return (Error `Forbidden)

let installations t =
  let open Abb_js_future_combinators.Infix_result_monad in
  call (Terrat_api_user.List_installations.make ())
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK res -> Abb_js.Future.return (Ok res)
  | `Forbidden -> Abb_js.Future.return (Error `Forbidden)

let work_manifests ?page ?pull_number ?dir ~installation_id t =
  let open Abb_js_future_combinators.Infix_result_monad in
  let module R = Terrat_api_installations.List_work_manifests.Responses.OK in
  call
    Terrat_api_installations.List_work_manifests.(
      make
        Parameters.(
          make
            ~d:
              (CCOption.map
                 (function
                   | `Asc -> "asc"
                   | `Desc -> "desc")
                 dir)
            ~page
            ~pr:pull_number
            ~installation_id
            ()))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK R.{ work_manifests } -> Abb_js.Future.return (Ok (Page.of_response resp work_manifests))
  | `Forbidden -> Abb_js.Future.return (Error `Forbidden)

let pull_requests ?page ?pull_number ~installation_id t =
  let open Abb_js_future_combinators.Infix_result_monad in
  let module R = Terrat_api_installations.List_pull_requests.Responses.OK in
  call
    Terrat_api_installations.List_pull_requests.(
      make Parameters.(make ~page ~pr:pull_number ~installation_id ()))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK R.{ pull_requests } -> Abb_js.Future.return (Ok (Page.of_response resp pull_requests))
  | `Forbidden -> Abb_js.Future.return (Error `Forbidden)