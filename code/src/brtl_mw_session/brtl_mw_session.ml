module Value = struct
  type 'a t = {
    is_dirty : bool;
    is_create : bool;
    v : 'a;
  }
end

type id = string

type cookie_name = string

type 'a load = id -> 'a option Abb.Future.t

type 'a store = id option -> 'a -> id Abb.Future.t

module Config = struct
  type 'a t = {
    key : 'a Value.t Hmap.key;
    cookie_name : cookie_name;
    load : 'a load;
    store : 'a store;
    expiration : [ `Session | `Max_age of Int64.t ];
    domain : string option;
    path : string option;
  }
end

let load_cookie cookie_name ctx =
  let headers = Brtl_ctx.(Request.headers (request ctx)) in
  let cookies = Cohttp.Cookie.Cookie_hdr.extract headers in
  CCList.Assoc.get ~eq:String.equal cookie_name cookies

let store_cookie config v ctx =
  let open Abb.Future.Infix_monad in
  let cookie_id =
    if v.Value.is_create then
      None
    else
      load_cookie config.Config.cookie_name ctx
  in
  config.Config.store cookie_id v.Value.v
  >>| fun cookie_id ->
  let cookie =
    Cohttp.Cookie.Set_cookie_hdr.make
      ?domain:config.Config.domain
      ?path:config.Config.path
      ~expiration:config.Config.expiration
      (config.Config.cookie_name, cookie_id)
  in
  let (cookie_header, cookie_value) = Cohttp.Cookie.Set_cookie_hdr.serialize cookie in
  ctx
  |> Brtl_ctx.response
  |> Brtl_rspnc.add_header cookie_header cookie_value
  |> CCFun.flip Brtl_ctx.set_response ctx

let pre_handler config ctx =
  match load_cookie config.Config.cookie_name ctx with
    | Some cookie_id ->
        let open Abb.Future.Infix_monad in
        config.Config.load cookie_id
        >>= fun v_opt ->
        let ctx =
          match v_opt with
            | Some v ->
                Brtl_ctx.md_add
                  config.Config.key
                  Value.{ is_dirty = false; is_create = false; v }
                  ctx
            | None   -> ctx
        in
        Abb.Future.return (Brtl_mw.Pre_handler.Cont ctx)
    | None           -> Abb.Future.return (Brtl_mw.Pre_handler.Cont ctx)

let post_handler config ctx =
  match Brtl_ctx.md_find config.Config.key ctx with
    | Some v when v.Value.is_dirty -> store_cookie config v ctx
    | _ -> Abb.Future.return ctx

let early_exit_handler = Brtl_mw.early_exit_handler_noop

let create config = Brtl_mw.Mw.create (pre_handler config) (post_handler config) early_exit_handler

let set_session_value key v ctx =
  match Brtl_ctx.md_find key ctx with
    | Some value -> ctx |> Brtl_ctx.md_add key Value.{ value with is_dirty = true; v }
    | None       -> ctx |> Brtl_ctx.md_add key Value.{ is_dirty = true; is_create = true; v }

let get_session_value key ctx = Brtl_ctx.md_find key ctx |> CCOpt.map (fun v -> v.Value.v)

let get_cookie_value = load_cookie

let rem_session_value = Brtl_ctx.md_rem

let create_key () = Hmap.Key.create ()
