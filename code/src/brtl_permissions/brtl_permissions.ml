module Permission = struct
  type ('a, 'b) t = (string, 'a) Brtl_ctx.t -> 'b -> bool Abb.Future.t
end

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
