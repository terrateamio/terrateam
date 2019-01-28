module Permission = struct
  type 'a t = ('a -> bool Abb.Future.t)
end

let with_permissions perms ctx v f =
  let open Abb.Future.Infix_monad in
  Abbs_future_combinators.all (CCList.map (fun p -> p v) perms)
  >>= fun res ->
  if CCList.for_all CCFun.id res then
    f ()
  else
    Abb.Future.return
      (Brtl_ctx.set_response
         (Brtl_rspnc.create ~status:`Forbidden "")
         ctx)
