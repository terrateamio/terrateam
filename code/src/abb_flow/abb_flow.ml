module type S = sig
  type of_string_err [@@deriving show]
  type step_err [@@deriving show]
  type t

  val to_string : t -> string
  val of_string : string -> (t, of_string_err) result
end

module type ID = sig
  type t [@@deriving show, eq]

  val to_string : t -> string
  val of_string : string -> t option
end

module Ret = struct
  type ('a, 'b, 'c) t =
    [ `Success of 'a
    | `Failure of 'b
    | `Yield of 'c
    ]
end

module Make (Fut : Abb_intf.Future.S) (Id : ID) (State : S) = struct
  type run_err =
    [ `Step_err of Id.t * State.step_err
    | `Step_exn_err of
      Id.t
      * (exn[@printer fun fmt exn -> fprintf fmt "%s" (Printexc.to_string exn)])
      * (Printexc.raw_backtrace
        [@printer fun fmt bt -> fprintf fmt "%s" (Printexc.raw_backtrace_to_string bt)])
        option
    ]
  [@@deriving show]

  module Yield = struct
    type of_string_err =
      [ `Decode_state_err of State.of_string_err
      | `Decode_err
      ]
    [@@deriving show]

    type t = {
      path : Id.t list;
      state : State.t; [@opaque]
    }
    [@@deriving show]

    let state t = t.state
    let set_state state t = { t with state }

    let to_string t =
      Containers_bencode.(
        Encode.to_string
          (map_of_list
             [
               ("state", string (State.to_string t.state));
               ("path", list (CCList.map CCFun.(Id.to_string %> string) t.path));
             ]))

    let of_string s =
      let module Cb = Containers_bencode in
      match Cb.Decode.of_string s with
      | Some (Cb.Map m) -> (
          match Cb.(Str_map.find_opt "path" m, Str_map.find_opt "state" m) with
          | Some (Cb.List path), Some (Cb.String state) -> (
              match State.of_string state with
              | Ok state ->
                  let open CCResult.Infix in
                  CCResult.map_l
                    (function
                      | Cb.String path ->
                          CCResult.map_err
                            (fun _ -> `Decode_err)
                            (CCResult.of_opt (Id.of_string path))
                      | _ -> Error `Decode_err)
                    path
                  >>= fun path -> Ok { path; state }
              | Error err -> Error (`Decode_state_err err))
          | _, _ -> Error `Decode_err)
      | Some _ | None -> Error `Decode_err
  end

  module Step = struct
    type 'a t = {
      id : Id.t;
      f : 'a -> State.t -> (State.t, State.step_err, State.t) Ret.t Fut.t;
    }

    let make ~id ~f () = { id; f }
    let id t = t.id
  end

  module Flow = struct
    type 'a t =
      | Seq of ('a t * 'a t)
      | Action of 'a Step.t list
      | Gen of ('a -> State.t -> 'a t)
      | Choice of {
          id : Id.t;
          f : ('a -> State.t -> (Id.t * State.t, State.step_err) result Fut.t[@opaque]);
          choices : (Id.t * 'a t) list;
        }
      | Finally of {
          id : Id.t;
          flow : 'a t;
          finally : 'a t;
        }
      | Recover of {
          id : Id.t;
          flow : 'a t;
          f : 'a -> State.t -> run_err -> (Id.t * State.t, State.step_err) result Fut.t;
          recover : (Id.t * 'a t) list;
        }

    let seq t1 t2 = Seq (t1, t2)
    let action steps = Action steps
    let gen f = Gen f
    let choice ~id ~f choices = Choice { id; f; choices }
    let finally ~id flow ~finally = Finally { id; flow; finally }
    let recover ~id flow ~f ~recover = Recover { id; flow; f; recover }

    let rec to_yojson = function
      | Seq (l, r) ->
          `Assoc [ ("type", `String "seq"); ("flow", `List [ to_yojson l; to_yojson r ]) ]
      | Action steps ->
          `Assoc
            [
              ("type", `String "action");
              ("steps", `List (CCList.map (fun { Step.id; _ } -> `String (Id.to_string id)) steps));
            ]
      | Gen _ -> `Assoc [ ("type", `String "gen") ]
      | Choice { id; choices; _ } ->
          `Assoc
            [
              ("type", `String "choice");
              ("id", `String (Id.to_string id));
              ( "choices",
                `Assoc
                  (CCList.map (fun (id, choice) -> (Id.to_string id, to_yojson choice)) choices) );
            ]
      | Finally { id; flow; finally } ->
          `Assoc
            [
              ("id", `String (Id.to_string id));
              ("flow", to_yojson flow);
              ("finally", to_yojson finally);
            ]
      | Recover { id; flow; f = _; recover } ->
          `Assoc
            [
              ("id", `String (Id.to_string id));
              ("flow", to_yojson flow);
              ( "recover",
                `Assoc (CCList.map (fun (id, flow) -> (Id.to_string id, to_yojson flow)) recover) );
            ]
  end

  module Event = struct
    type 'a t =
      | Step_start of ('a Step.t * State.t)
      | Step_end of ('a Step.t * (State.t, run_err, State.t) Ret.t * State.t)
      | Choice_start of (Id.t * State.t)
      | Choice_end of (Id.t * (Id.t * State.t, run_err) result * State.t)
      | Finally_start of (Id.t * State.t)
      | Finally_resume of (Id.t * State.t)
      | Recover_choice of (Id.t * Id.t * State.t)
      | Recover_start of (Id.t * State.t)
  end

  type 'a t = {
    flow : 'a Flow.t;
    log : 'a Event.t -> unit;
    path : Id.t list;
    resume_path : Id.t list;
  }

  let log_noop _ = ()
  let create ?(log = log_noop) flow = { flow; log; path = []; resume_path = [] }

  let rec run_steps t state run_data steps =
    match (steps, t.resume_path) with
    | { Step.id; _ } :: steps, id' :: resume_path when Id.equal id id' ->
        run_steps { t with resume_path; path = id :: t.path } state run_data steps
    | ({ Step.id; f } as step) :: xs, _ -> (
        assert (t.resume_path = []);
        t.log (Event.Step_start (step, state));
        try
          Fut.await_bind
            (function
              | `Det ret -> (
                  match ret with
                  | `Success state as ret ->
                      t.log (Event.Step_end (step, ret, state));
                      run_steps { t with path = id :: t.path } state run_data xs
                  | `Yield state as ret ->
                      t.log (Event.Step_end (step, ret, state));
                      (* The path is built in reverse, so reverse it for storage *)
                      Fut.return (`Yield { Yield.path = CCList.rev t.path; state })
                  | `Failure step_err ->
                      let err = `Failure (`Step_err (id, step_err)) in
                      t.log (Event.Step_end (step, err, state));
                      Fut.return err)
              | `Aborted -> assert false
              | `Exn (exn, bt) ->
                  let err = `Failure (`Step_exn_err (id, exn, bt)) in
                  t.log (Event.Step_end (step, err, state));
                  Fut.return err)
            (f run_data state)
        with exn ->
          let bt = Printexc.get_raw_backtrace () in
          let err = `Failure (`Step_exn_err (id, exn, Some bt)) in
          t.log (Event.Step_end (step, err, state));
          Fut.return err)
    | [], _ -> Fut.return (`Success (t, state))

  let resume_choice id choices = function
    | id' :: choice :: resume_path when Id.equal id' id -> (
        match CCList.Assoc.get ~eq:Id.equal choice choices with
        | Some flow -> `Ok (flow, choice, resume_path)
        | None -> assert false)
    | _ :: _ -> `Non_empty_resume_path
    | [] -> `Empty_resume_path

  let resume_finally id = function
    | id' :: resume_path when Id.equal id' id -> Some resume_path
    | _ -> None

  let choose_flow id f choices run_data state =
    let open Fut.Infix_monad in
    try
      f run_data state
      >>= function
      | Ok (choice, state) -> (
          match CCList.Assoc.get ~eq:Id.equal choice choices with
          | Some flow -> Fut.return (Ok (choice, state, flow))
          | None -> Fut.return (Error (`Choice_not_found choice)))
      | Error err ->
          let err = `Step_err (id, err) in
          Fut.return (Error (`Failed err))
    with exn ->
      let bt = Printexc.get_raw_backtrace () in
      let err = `Step_exn_err (id, exn, Some bt) in
      Fut.return (Error (`Failed err))

  let rec run_flow t state run_data = function
    | Flow.Seq (flow1, flow2) -> (
        let open Fut.Infix_monad in
        run_flow t state run_data flow1
        >>= function
        | `Success (t, state) -> run_flow t state run_data flow2
        | (`Yield _ | `Failure _) as ret -> Fut.return ret)
    | Flow.Action steps -> run_steps t state run_data steps
    | Flow.Gen f -> run_flow t state run_data (f run_data state)
    | Flow.Choice { id; f; choices } -> (
        match resume_choice id choices t.resume_path with
        | `Ok (flow, choice, resume_path) ->
            run_flow { t with resume_path; path = choice :: id :: t.path } state run_data flow
        | `Empty_resume_path -> (
            let open Fut.Infix_monad in
            t.log (Event.Choice_start (id, state));
            choose_flow id f choices run_data state
            >>= function
            | Ok (choice, state, flow) ->
                t.log (Event.Choice_end (id, Ok (choice, state), state));
                run_flow { t with path = choice :: id :: t.path } state run_data flow
            | Error (`Choice_not_found _) -> assert false
            | Error (`Failed err) ->
                t.log (Event.Choice_end (id, Error err, state));
                Fut.return (`Failure err))
        | `Non_empty_resume_path -> assert false)
    | Flow.Finally { id; flow; finally } -> (
        match resume_finally id t.resume_path with
        | Some resume_path ->
            (* A resume path that has the finally [id] means that the [finally]
               path has been executed, so we just return with our [id] on it. *)
            t.log (Event.Finally_resume (id, state));
            Fut.return (`Success ({ t with path = id :: t.path; resume_path }, state))
        | None -> (
            let open Fut.Infix_monad in
            (* We haven't started (or finished) executing the main flow. *)
            t.log (Event.Finally_start (id, state));
            run_flow t state run_data flow
            >>= function
            | `Success (t', state) -> (
                run_flow t' state run_data finally
                >>= function
                | `Success _ | `Failure _ ->
                    (* Need to do some surgery to get the finally id in there *)
                    let diff = CCList.length t'.path - CCList.length t.path in
                    let path = CCList.take diff t'.path @ [ id ] @ t.path in
                    Fut.return (`Success ({ t' with path }, state))
                | `Yield _ -> assert false)
            | `Failure _ as ret -> (
                run_flow { t with path = id :: t.path; resume_path = [] } state run_data finally
                >>= function
                | `Success _ | `Failure _ -> Fut.return ret
                | `Yield _ -> assert false)
            | `Yield _ as ret -> Fut.return ret))
    | Flow.Recover { id; flow; f; recover } -> (
        (* If the id of recover is not present, then do the main flow, if [id] is
           there then that means a recover path is being taken. *)
        match resume_choice id recover t.resume_path with
        | `Ok (flow, choice, resume_path) ->
            t.log (Event.Recover_choice (id, choice, state));
            run_flow { t with resume_path; path = choice :: id :: t.path } state run_data flow
        | `Empty_resume_path | `Non_empty_resume_path -> (
            let open Fut.Infix_monad in
            t.log (Event.Recover_start (id, state));
            run_flow t state run_data flow
            >>= function
            | (`Success _ | `Yield _) as ret -> Fut.return ret
            | `Failure err -> (
                choose_flow id (fun ctx state -> f ctx state err) recover run_data state
                >>= function
                | Ok (choice, state, flow) ->
                    t.log (Event.Recover_choice (id, choice, state));
                    run_flow
                      { t with path = choice :: id :: t.path; resume_path = [] }
                      state
                      run_data
                      flow
                | Error (`Choice_not_found _) -> assert false
                | Error (`Failed err) -> Fut.return (`Failure err))))

  let run run_data state t =
    let open Fut.Infix_monad in
    run_flow t state run_data t.flow
    >>= function
    | `Success (_, state) -> Fut.return (`Success state)
    | (`Yield _ | `Failure _) as r -> Fut.return r

  let resume run_data resume t =
    run run_data resume.Yield.state { t with path = []; resume_path = resume.Yield.path }

  let yield_of_state state = { Yield.path = []; state }
end
