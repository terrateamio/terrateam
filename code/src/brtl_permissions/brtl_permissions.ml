module Permission = struct
  type ('a, 'b) t = (string, 'a) Brtl_ctx.t -> 'b -> bool Abb.Future.t
end

module Auth = struct
  type t = Bearer of string [@@deriving show]
end

type get_auth_err =
  [ `No_auth
  | `Unknown_auth of string
  ]
[@@deriving show]

let with_permissions perms ctx v f =
  let open Abb.Future.Infix_monad in
  Abbs_future_combinators.all (CCList.map (fun p -> p ctx v) perms)
  >>= fun res ->
  if CCList.for_all CCFun.id res then f ()
  else Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx)

let with_permissions_ep perms v ctx =
  let open Abb.Future.Infix_monad in
  Abbs_future_combinators.all (CCList.map (fun p -> p ctx v) perms)
  >>| fun res ->
  if CCList.for_all CCFun.id res then Ok ctx else Error (Brtl_ctx.set_response `Forbidden ctx)

let get_auth ctx =
  match
    ctx
    |> Brtl_ctx.request
    |> Cohttp.Request.headers
    |> CCFun.flip Cohttp.Header.get "authorization"
  with
  | Some s -> (
      match CCString.Split.left ~by:" " s with
      | Some (typ, token) when CCString.equal_caseless typ "bearer" ->
          Ok (Auth.Bearer (CCString.trim token))
      | _ -> Error (`Unknown_auth s))
  | None -> Error `No_auth
