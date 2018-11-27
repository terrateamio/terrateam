(* TODO: Make the dirty check be more specific to the actual session key being
     updated.  Right now if one session data is updated, it's all updated. *)
module Is_dirty : sig
  type t
  val key : t Hmap.key
  val is_dirty : t -> bool
  val dirty : t
  val not_dirty : t
end = struct
  type t = bool
  let key = Hmap.Key.create ()
  let is_dirty t = t
  let dirty = true
  let not_dirty = false
end

type id = string
type cookie_name = string

type 'a load = (id -> 'a option Abb.Future.t)
type 'a store = (id option -> 'a -> id Abb.Future.t)

module Config = struct
  type 'a t = { key : 'a Hmap.key
              ; cookie_name : cookie_name
              ; load : 'a load
              ; store : 'a store
              ; expiration : [ `Session | `Max_age of Int64.t ]
              ; domain : string option
              ; path : string option
              }
end

let load_cookie cookie_name ctx =
  let headers = Brtl_ctx.(Request.headers (request ctx)) in
  let cookies = Cohttp.Cookie.Cookie_hdr.extract headers in
  CCList.Assoc.get ~eq:String.equal cookie_name cookies

let store_cookie config v ctx =
  let open Abb.Future.Infix_monad in
  let cookie_id = load_cookie config.Config.cookie_name ctx in
  config.Config.store cookie_id v
  >>| fun cookie_id ->
  let cookie =
    Cohttp.Cookie.Set_cookie_hdr.make
      ?domain:config.Config.domain
      ?path:config.Config.path
      ~expiration:config.Config.expiration
      (config.Config.cookie_name, cookie_id)
  in
  let (cookie_header, cookie_value) = Cohttp.Cookie.Set_cookie_hdr.serialize cookie in
  Logs.info (fun m -> m "Setting cookie %s %s" cookie_header cookie_value);
  ctx
  |> Brtl_ctx.response
  |> Brtl_rspnc.add_header cookie_header cookie_value
  |> CCFun.flip Brtl_ctx.set_response ctx

let pre_handler config ctx =
  let ctx = Brtl_ctx.md_add Is_dirty.key Is_dirty.not_dirty ctx in
  match load_cookie config.Config.cookie_name ctx with
    | Some cookie_id ->
      let open Abb.Future.Infix_monad in
      config.Config.load cookie_id
      >>= fun v_opt ->
      let ctx =
        match v_opt with
          | Some v -> Brtl_ctx.md_add config.Config.key v ctx
          | None -> ctx
      in
      Abb.Future.return (Brtl_mw.Pre_handler.Cont ctx)
    | None ->
      Abb.Future.return (Brtl_mw.Pre_handler.Cont ctx)

let post_handler config ctx =
  match Brtl_ctx.(md_find Is_dirty.key ctx, md_find config.Config.key ctx) with
    | (Some dirty, Some v) when Is_dirty.is_dirty dirty -> begin
      Logs.info (fun m -> m "Storing cookie");
      store_cookie config v ctx
    end
    | (_, _) ->
      Abb.Future.return ctx

let early_exit_handler = Brtl_mw.early_exit_handler_noop

let create config =
  Brtl_mw.Mw.create (pre_handler config) (post_handler config) early_exit_handler

let set_session_value key v ctx =
  ctx
  |> Brtl_ctx.md_add Is_dirty.key Is_dirty.dirty
  |> Brtl_ctx.md_add key v

let get_session_value = Brtl_ctx.md_find
