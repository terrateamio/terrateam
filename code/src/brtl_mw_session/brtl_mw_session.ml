module Auth = struct
  type 'a t =
    | Cookie of 'a
    | Bearer of 'a
end

module Value = struct
  type 'a t = {
    is_dirty : bool;
    is_create : bool;
    v : 'a Auth.t;
  }
end

type id = string
type cookie_name = string
type 'a load = id -> 'a option Abb.Future.t
type 'a store = id option -> 'a -> (string, Brtl_rspnc.t) Brtl_ctx.t -> id Abb.Future.t

module Config = struct
  module Cookie = struct
    type 'a t = {
      name : cookie_name;
      expiration : [ `Session | `Max_age of Int64.t ];
      domain : string option;
      path : string option;
      load : 'a load;
      store : 'a store;
    }
  end

  module Bearer = struct
    type 'a t = {
      load : 'a load;
      store : 'a store;
    }
  end

  type 'a t = {
    key : 'a Value.t Hmap.key;
    cookie : 'a Cookie.t option;
    bearer : 'a Bearer.t option;
  }
end

let load_cookie cookie_name ctx =
  let headers = Brtl_ctx.(Request.headers (request ctx)) in
  let cookies = Cohttp.Cookie.Cookie_hdr.extract headers in
  CCList.Assoc.get ~eq:String.equal cookie_name cookies

let get_auth ctx =
  CCOption.flat_map
    (fun s ->
      match CCString.Split.left ~by:" " s with
      | Some (typ, token) when CCString.equal_caseless typ "bearer" -> Some (CCString.trim token)
      | _ -> None)
    (Cohttp.Header.get (Cohttp.Request.headers @@ Brtl_ctx.request ctx) "authorization")

let load_bearer = get_auth

let store_cookie config cookie value v ctx =
  let open Abb.Future.Infix_monad in
  let cookie_id =
    if value.Value.is_create || value.Value.is_dirty then None
    else load_cookie cookie.Config.Cookie.name ctx
  in
  cookie.Config.Cookie.store cookie_id v ctx
  >>| fun cookie_id ->
  let cookie =
    Cohttp.Cookie.Set_cookie_hdr.make
      ?domain:cookie.Config.Cookie.domain
      ?path:cookie.Config.Cookie.path
      ~secure:true
      ~http_only:true
      ~expiration:cookie.Config.Cookie.expiration
      (cookie.Config.Cookie.name, cookie_id)
  in
  let cookie_header, cookie_value = Cohttp.Cookie.Set_cookie_hdr.serialize cookie in
  ctx
  |> Brtl_ctx.response
  |> Brtl_rspnc.add_header cookie_header cookie_value
  |> CCFun.flip Brtl_ctx.set_response ctx

let get_auth_token config ctx =
  let cookie =
    CCOption.flat_map (fun cookie -> load_cookie cookie.Config.Cookie.name ctx) config.Config.cookie
  in
  let bearer = CCOption.flat_map (fun _ -> load_bearer ctx) config.Config.bearer in
  match (bearer, cookie) with
  | Some bearer, _ -> Some (Auth.Bearer bearer)
  | _, Some cookie -> Some (Auth.Cookie cookie)
  | None, None -> None

let pre_handler config ctx =
  match get_auth_token config ctx with
  | Some (Auth.Bearer token) -> (
      match config.Config.bearer with
      | Some bearer ->
          let open Abb.Future.Infix_monad in
          bearer.Config.Bearer.load token
          >>= fun v_opt ->
          let ctx =
            match v_opt with
            | Some v ->
                Brtl_ctx.md_add
                  config.Config.key
                  Value.{ is_dirty = false; is_create = false; v = Auth.Bearer v }
                  ctx
            | None -> ctx
          in
          Abb.Future.return (Brtl_mw.Pre_handler.Cont ctx)
      | None -> Abb.Future.return (Brtl_mw.Pre_handler.Cont ctx))
  | Some (Auth.Cookie cookie_id) -> (
      match config.Config.cookie with
      | Some cookie ->
          let open Abb.Future.Infix_monad in
          cookie.Config.Cookie.load cookie_id
          >>= fun v_opt ->
          let ctx =
            match v_opt with
            | Some v ->
                Brtl_ctx.md_add
                  config.Config.key
                  Value.{ is_dirty = false; is_create = false; v = Auth.Cookie v }
                  ctx
            | None -> ctx
          in
          Abb.Future.return (Brtl_mw.Pre_handler.Cont ctx)
      | None -> Abb.Future.return (Brtl_mw.Pre_handler.Cont ctx))
  | None -> Abb.Future.return (Brtl_mw.Pre_handler.Cont ctx)

let post_handler config ctx =
  match Brtl_ctx.md_find config.Config.key ctx with
  | Some ({ Value.is_dirty = true; v = Auth.Cookie v; _ } as value) -> (
      match config.Config.cookie with
      | Some cookie -> store_cookie config cookie value v ctx
      | None -> assert false)
  | _ -> Abb.Future.return ctx

let early_exit_handler = Brtl_mw.early_exit_handler_noop
let create config = Brtl_mw.Mw.create (pre_handler config) (post_handler config) early_exit_handler

let set_session_value key v ctx =
  match Brtl_ctx.md_find key ctx with
  | Some value -> ctx |> Brtl_ctx.md_add key Value.{ value with is_dirty = true; v }
  | None -> ctx |> Brtl_ctx.md_add key Value.{ is_dirty = true; is_create = true; v }

let get_session_value key ctx = Brtl_ctx.md_find key ctx |> CCOption.map (fun v -> v.Value.v)
let get_session_key = load_cookie
let rem_session_value = Brtl_ctx.md_rem
let create_key () = Hmap.Key.create ()
