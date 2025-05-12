let src = Logs.Src.create "pgsql.pool"

module Logs = (val Logs.src_log src : Logs.LOG)

exception Pgsql_pool_closed

type err = [ `Pgsql_pool_error ] [@@deriving show]

module Metrics = struct
  type t = {
    num_conns : int;
    idle_conns : int;
  }
end

module Conn = struct
  type t = {
    conn : Pgsql_io.t;
    last_used : float;
  }
end

module Msg = struct
  type t =
    | Get of (Pgsql_io.t, unit) result Abb.Future.Promise.t
    | Conn_timeout_check
    | Return of Pgsql_io.t
end

module Server = struct
  type t = {
    metrics : Metrics.t -> unit Abb.Future.t;
    idle_check : Duration.t;
    conn_timeout_check : Duration.t;
    tls_config : [ `Require of Otls.Tls_config.t | `Prefer of Otls.Tls_config.t ] option;
    passwd : string option;
    port : int option;
    host : string;
    user : string;
    max_conns : int;
    connect_timeout : float;
    database : string;
    num_conns : int;
    conns : Conn.t list;
    waiting : (Pgsql_io.t, unit) result Abb.Future.Promise.t Queue.t;
  }

  let rec conn_timeout_check' timeout w =
    let open Abb.Future.Infix_monad in
    Abb.Sys.sleep @@ Duration.to_f timeout
    >>= fun () ->
    Abbs_channel.send w Msg.Conn_timeout_check
    >>= function
    | `Ok () -> conn_timeout_check' timeout w
    | `Closed -> Abb.Future.return ()

  (* Consume waiting promises until we find one that is undetermined.  Needed in
     case a waiting future was terminated while waiting. *)
  let rec take_until_undet waiting =
    match Queue.take_opt waiting with
    | Some p when Abb.Future.(state (Promise.future p)) = `Undet -> Some p
    | Some _ -> take_until_undet waiting
    | None -> None

  let verify_conn Conn.{ conn; _ } =
    let open Abb.Future.Infix_monad in
    Pgsql_io.ping conn
    >>= function
    | true ->
        Abb.Sys.monotonic () >>= fun last_used -> Abb.Future.return (Some Conn.{ conn; last_used })
    | false -> Pgsql_io.destroy conn >>= fun () -> Abb.Future.return None

  let verify_conns t =
    Abbs_future_combinators.List.fold_left
      ~f:(fun t conn ->
        let open Abb.Future.Infix_monad in
        verify_conn conn
        >>= function
        | Some conn -> Abb.Future.return { t with conns = conn :: t.conns }
        | None -> Abb.Future.return { t with num_conns = t.num_conns - 1 })
      ~init:{ t with conns = [] }
      t.conns

  let rec loop t w r =
    let open Abb.Future.Infix_monad in
    Abbs_channel.recv r >>= handle_msg t w r

  and handle_msg t w r =
    let open Abb.Future.Infix_monad in
    function
    | `Ok (Msg.Get p) when t.conns = [] && t.num_conns = t.max_conns ->
        t.metrics Metrics.{ num_conns = t.num_conns; idle_conns = CCList.length t.conns }
        >>= fun () ->
        Queue.add p t.waiting;
        loop t w r
    | `Ok (Msg.Get p) -> (
        t.metrics Metrics.{ num_conns = t.num_conns; idle_conns = CCList.length t.conns }
        >>= fun () ->
        Abb.Sys.monotonic ()
        >>= fun now ->
        match t.conns with
        | (Conn.{ conn; last_used } as c) :: cs
          when Pgsql_io.connected conn && now -. last_used >= Duration.to_f t.idle_check -> (
            (* Verify the connection is still alive, and if so give it back.
               Otherwise, remove it and  handle the message again. *)
            verify_conn c
            >>= function
            | Some Conn.{ conn; _ } ->
                Abb.Future.Promise.set p (Ok conn) >>= fun () -> loop { t with conns = cs } w r
            | None ->
                handle_msg { t with num_conns = t.num_conns - 1; conns = cs } w r (`Ok (Msg.Get p)))
        | Conn.{ conn; _ } :: cs when Pgsql_io.connected conn ->
            Abb.Future.Promise.set p (Ok conn) >>= fun () -> loop { t with conns = cs } w r
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
                Logs.err (fun m -> m "ERROR : %s" (Pgsql_io.show_create_err err));
                Abb.Future.Promise.set p (Error ()) >>= fun () -> loop t w r
            | `Timeout -> Abb.Future.Promise.set p (Error ()) >>= fun () -> loop t w r))
    | `Ok (Msg.Return conn) when Pgsql_io.connected conn -> (
        t.metrics Metrics.{ num_conns = t.num_conns; idle_conns = CCList.length t.conns }
        >>= fun () ->
        match take_until_undet t.waiting with
        | Some p -> Abb.Future.Promise.set p (Ok conn) >>= fun () -> loop t w r
        | None ->
            Abb.Sys.monotonic ()
            >>= fun last_used -> loop { t with conns = Conn.{ conn; last_used } :: t.conns } w r)
    | `Ok (Msg.Return conn) -> (
        t.metrics Metrics.{ num_conns = t.num_conns; idle_conns = CCList.length t.conns }
        >>= fun () ->
        Pgsql_io.destroy conn
        >>= fun () ->
        verify_conns t
        >>= fun t ->
        match take_until_undet t.waiting with
        | Some p -> handle_msg t w r (`Ok (Msg.Get p))
        | None -> loop t w r)
    | `Ok Msg.Conn_timeout_check ->
        let conn_timeout_check = Duration.to_f t.conn_timeout_check in
        Logs.debug (fun m ->
            m
              "CONN_TIMEOUT_CHECK : STARTED : num_conns=%d : timeout=%0.0f"
              t.num_conns
              conn_timeout_check);
        Abb.Sys.monotonic ()
        >>= fun now ->
        Abbs_future_combinators.List.fold_left
          ~f:(fun t ({ Conn.conn; last_used } as c) ->
            let age = now -. last_used in
            Logs.debug (fun m -> m "CONN_TIMEOUT_CHECK : TEST : age=%0.0f" age);
            if age >= conn_timeout_check then
              Pgsql_io.destroy conn
              >>= fun _ -> Abb.Future.return { t with num_conns = t.num_conns - 1 }
            else Abb.Future.return { t with conns = c :: t.conns })
          ~init:{ t with conns = [] }
          t.conns
        >>= fun t ->
        Logs.debug (fun m -> m "CONN_TIMEOUT_CHECK : COMPLETED : num_conns=%d" t.num_conns);
        loop t w r
    | `Closed ->
        Abbs_future_combinators.List.iter
          ~f:(fun Conn.{ conn; _ } -> Abbs_future_combinators.ignore (Pgsql_io.destroy conn))
          t.conns

  let run t w r =
    let open Abb.Future.Infix_monad in
    Abb.Future.fork (conn_timeout_check' t.conn_timeout_check w) >>= fun _ -> loop t w r
end

type t = Msg.t Abbs_service_local.w

let create
    ?(metrics = fun _ -> Abbs_future_combinators.unit)
    ?(idle_check = Duration.of_min 5)
    ?(conn_timeout_check = Duration.of_min 1)
    ?tls_config
    ?passwd
    ?port
    ~connect_timeout
    ~host
    ~user
    ~max_conns
    database =
  let t =
    Server.
      {
        metrics;
        idle_check;
        conn_timeout_check;
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
  Abbs_service_local.create (Server.run t)

let destroy t = Abbs_future_combinators.ignore (Abbs_channel.close t)

let with_conn t ~f =
  let open Abb.Future.Infix_monad in
  Abbs_future_combinators.protect_finally
    ~setup:(fun () ->
      let p = Abb.Future.Promise.create () in
      Abbs_channel.send t (Msg.Get p)
      >>= function
      | `Ok () -> Abb.Future.Promise.future p
      | `Closed -> raise Pgsql_pool_closed)
    (function
      | Ok conn -> f conn
      | Error () -> Abb.Future.return (Error `Pgsql_pool_error))
    ~finally:(function
      | Ok conn -> (
          (* Cleanup any prepared statements. *)
          Pgsql_io.Prepared_stmt.execute conn Pgsql_io.Typed_sql.(sql /^ "DEALLOCATE")
          >>= fun _ ->
          Abbs_channel.send t (Msg.Return conn)
          >>= function
          | `Ok () -> Abb.Future.return ()
          | `Closed -> Abbs_future_combinators.ignore (Pgsql_io.destroy conn))
      | Error () -> Abb.Future.return ())
