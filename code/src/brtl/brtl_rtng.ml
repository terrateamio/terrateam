module Ctx = Brtl_ctx
module Rspnc = Brtl_rspnc

module Handler = struct
  type t = ((string, unit) Ctx.t -> (string, Rspnc.t) Ctx.t Abb.Future.t)
end

module Route = struct
  include Furl
  include Furl_capture
end

module Method = struct
  type t = Cohttp.Code.meth
end

type t = { default : Handler.t
         ; routes : (Method.t, (Uri.t -> Handler.t)) Hashtbl.t
         }

let create ~default routes_list =
  let route_default _ = default in
  let tmp = Hashtbl.create 10 in
  ListLabels.iter
    ~f:(fun (meth, route) -> CCHashtbl.add_list tmp meth route)
    routes_list;
  let routes = Hashtbl.create 10 in
  Hashtbl.iter
    (fun meth rts -> Hashtbl.add routes meth (Route.match_url ~default:route_default rts))
    tmp;
  { default; routes }

let route ctx t =
  let uri = Ctx.(Request.uri (request ctx)) in
  match CCHashtbl.get t.routes Ctx.(Request.meth (request ctx)) with
    | Some routes ->
      routes uri
    | None ->
      t.default
