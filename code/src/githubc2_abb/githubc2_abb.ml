module Http = Cohttp_abb.Make (Abb)

let base_url = Uri.of_string "https://api.github.com/"

let tls_config =
  let cfg = Otls.Tls_config.create () in
  Otls.Tls_config.insecure_noverifycert cfg;
  cfg

module Io = struct
  type 'a t = 'a Abb.Future.t

  let ( >>= ) = Abb.Future.Infix_monad.( >>= )
  let return = Abb.Future.return

  let call ?body ~headers ~meth uri =
    let meth =
      match meth with
      | `Get -> `GET
      | `Delete -> `DELETE
      | `Patch -> `PATCH
      | `Put -> `PUT
      | `Post -> `POST
    in
    let headers = Cohttp.Header.of_list headers in
    let body = CCOpt.map Cohttp.Body.of_string body in
    Http.Client.call ?body ~tls_config ~headers meth uri
    >>= function
    | Ok (resp, body) ->
        let headers = resp |> Http.Response.headers |> Cohttp.Header.to_list in
        let status = resp |> Http.Response.status |> Cohttp.Code.code_of_status in
        return (Ok (Openapi.Response.make ~headers ~status body))
    | Error _ -> return (Error `Error)
end

module Api = Openapi.Make (Io)

module Authorization = struct
  type t =
    [ `Token of string
    | `Bearer of string
    ]
end

type call_err =
  [ `Conversion_err of string * string Openapi.Response.t
  | `Missing_response of string Openapi.Response.t
  | `Error
  ]
[@@deriving show]

type t = {
  auth : Authorization.t;
  base_url : Uri.t;
  headers : (string * string) list;
}

let create ?(user_agent = "Githubc2_abb") ?(base_url = base_url) auth =
  {
    auth;
    base_url;
    headers =
      [
        ("user-agent", user_agent);
        ("content-type", "application/json");
        ("accept", "application/vnd.github.v3+json");
        ( "authorization",
          match auth with
          | `Token token -> "token " ^ token
          | `Bearer bearer -> "Bearer " ^ bearer );
      ];
  }

let call t req = Api.call Openapi.Request.(req |> with_base_url t.base_url |> add_headers t.headers)

let parse_link s =
  let open CCOpt.Infix in
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
    let open CCOpt.Infix in
    match CCString.Split.left ~by:", " s with
    | Some (left, right) ->
        parse_link left >>= fun link -> parse_links right >>= fun rest -> Some (link :: rest)
    | None -> parse_link s >>= fun link -> Some [ link ]
  else Some []

let links resp =
  CCOpt.get_or
    ~default:[]
    (parse_links
       (CCOpt.get_or
          ~default:""
          (Cohttp.Header.get (Cohttp.Header.of_list (Openapi.Response.headers resp)) "link")))

let rec fold t ~init ~f req =
  let open Abbs_future_combinators.Infix_result_monad in
  call t req
  >>= fun resp ->
  f init resp
  >>= fun init ->
  match List.assoc_opt "next" (links resp) with
  | Some next ->
      let req = Openapi.Request.with_url next req in
      fold t ~init ~f req
  | None -> Abb.Future.return (Ok init)

let collect_all t req =
  fold
    ~init:[]
    ~f:(fun acc resp ->
      match Openapi.Response.value resp with
      | `OK vs -> Abb.Future.return (Ok (vs @ acc))
      | _ -> Abb.Future.return (Error `Error))
    t
    req
