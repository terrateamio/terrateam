let src = Logs.Src.create "pgsql.pool"

module Logs = (val Logs.src_log src : Logs.LOG)

exception Pgsql_pool_closed

type err = [ `Pgsql_pool_error ] [@@deriving show]

module Msg = struct
  type t =
    | Get of (Pgsql_io.t, unit) result Abb.Future.Promise.t
    | Return of Pgsql_io.t
end

module Server = struct
  type t = {
    tls_config : [ `Require of Otls.Tls_config.t | `Prefer of Otls.Tls_config.t ] option;
    passwd : string option;
    port : int option;
    host : string;
    user : string;
    max_conns : int;
    connect_timeout : float;
    database : string;
    num_conns : int;
    conns : Pgsql_io.t list;
    waiting : (Pgsql_io.t, unit) result Abb.Future.Promise.t Queue.t;
  }

  (* Consume waiting promises until we find one that is undetermined.  Needed in
     case a waiting future was terminated while waiting. *)
  let rec take_until_undet waiting =
    match Queue.take_opt waiting with
    | Some p when Abb.Future.(state (Promise.future p)) = `Undet -> Some p
    | Some _ -> take_until_undet waiting
    | None -> None

  let verify_conns t =
    Abbs_future_combinators.List.fold_left
      ~f:(fun t conn ->
        let open Abb.Future.Infix_monad in
        Pgsql_io.ping conn
        >>= function
        | true -> Abb.Future.return { t with conns = conn :: t.conns }
        | false ->
            Pgsql_io.destroy conn
            >>= fun () -> Abb.Future.return { t with num_conns = t.num_conns - 1 })
      ~init:{ t with conns = [] }
      t.conns

  let rec loop t w r =
    let open Abb.Future.Infix_monad in
    Abbs_channel.recv r >>= handle_msg t w r

  and handle_msg t w r =
    let open Abb.Future.Infix_monad in
    function
    | `Ok (Msg.Get p) when t.conns = [] && t.num_conns = t.max_conns ->
        Queue.add p t.waiting;
        loop t w r
    | `Ok (Msg.Get p) -> (
        match t.conns with
        | c :: cs when Pgsql_io.connected c ->
            Abb.Future.Promise.set p (Ok c) >>= fun () -> loop { t with conns = cs } w r
        | _ :: _ ->
            (* If one connection is disconnected, maybe all of them are, so
               verify all the connections before handing out the next one.

               TODO: Find the next valid connection and hand it over and check
               valid connections in the background *)
            verify_conns t >>= fun t -> handle_msg t w r (`Ok (Msg.Get p))
        | [] -> (
            Abbs_future_combinators.timeout
              ~timeout:(Abb.Sys.sleep t.connect_timeout)
              (Pgsql_io.create
                 ?tls_config:t.tls_config
                 ?passwd:t.passwd
                 ?port:t.port
                 ~host:t.host
                 ~user:t.user
                 t.database)
            >>= function
            | `Ok (Ok conn) ->
                Abb.Future.Promise.set p (Ok conn)
                >>= fun () -> loop { t with num_conns = t.num_conns + 1 } w r
            | `Ok (Error (#Pgsql_io.create_err as err)) ->
                Logs.err (fun m -> m "PGSQL_POOL : ERROR : %s" (Pgsql_io.show_create_err err));
                Abb.Future.Promise.set p (Error ()) >>= fun () -> loop t w r
            | `Timeout -> Abb.Future.Promise.set p (Error ()) >>= fun () -> loop t w r))
    | `Ok (Msg.Return conn) when Pgsql_io.connected conn -> (
        match take_until_undet t.waiting with
        | Some p -> Abb.Future.Promise.set p (Ok conn) >>= fun () -> loop t w r
        | None -> loop { t with conns = conn :: t.conns } w r)
    | `Ok (Msg.Return conn) -> (
        Pgsql_io.destroy conn
        >>= fun () ->
        verify_conns t
        >>= fun t ->
        match take_until_undet t.waiting with
        | Some p -> handle_msg t w r (`Ok (Msg.Get p))
        | None -> loop t w r)
    | `Closed ->
        Abbs_future_combinators.List.iter
          ~f:(fun conn -> Abbs_future_combinators.ignore (Pgsql_io.destroy conn))
          t.conns
end

type t = Msg.t Abbs_service_local.w

let create ?tls_config ?passwd ?port ~connect_timeout ~host ~user ~max_conns database =
  let t =
    Server.
      {
        tls_config;
        passwd;
        port;
        host;
        user;
        max_conns;
        connect_timeout;
        database;
        num_conns = 0;
        conns = [];
        waiting = Queue.create ();
      }
  in
  Abbs_service_local.create (Server.loop t)

let destroy t = Abbs_future_combinators.ignore (Abbs_channel.close t)

let with_conn t ~f =
  let open Abb.Future.Infix_monad in
  let p = Abb.Future.Promise.create () in
  Abbs_channel.send t (Msg.Get p)
  >>= function
  | `Ok () -> (
      Abbs_future_combinators.on_failure
        (fun () -> Abb.Future.Promise.future p)
        ~failure:(fun () -> Abb.Future.(cancel (Promise.future p)))
      >>= function
      | Ok conn ->
          Abbs_future_combinators.with_finally
            (fun () -> f conn)
            ~finally:(fun () ->
              Abbs_channel.send t (Msg.Return conn)
              >>= function
              | `Ok () -> Abb.Future.return ()
              | `Closed -> Abbs_future_combinators.ignore (Pgsql_io.destroy conn))
      | Error () -> Abb.Future.return (Error `Pgsql_pool_error))
  | `Closed -> raise Pgsql_pool_closed
