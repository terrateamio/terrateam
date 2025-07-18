let src = Logs.Src.create "terrat_vcs_api_gitlab"

module Logs = (val Logs.src_log src : Logs.LOG)

module Metrics = struct
  module Call_retry_wait_histograph = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_exponential ~start:30.0 ~factor:1.2 ~count:20
  end)

  module Rate_limit_remaining_histograph = Prmths.Histogram (struct
    let spec =
      Prmths.Histogram_spec.of_list
        [ 100.0; 500.0; 1000.0; 2000.0; 3000.0; 4000.0; 5000.0; 6000.0; 10000.0 ]
  end)

  let namespace = "terrat_vcs_api"
  let subsystem = "gitlab"

  let call_retries_total =
    let help = "Number of retries in a call" in
    Prmths.Counter.v ~help ~namespace ~subsystem "call_retries_total"

  let rate_limit_retry_wait_seconds =
    let help = "Number of seconds a call has spent waiting due to rate limit" in
    Call_retry_wait_histograph.v ~help ~namespace ~subsystem "rate_limit_retry_wait_seconds"

  let rate_limit_remaining_count =
    let help = "Number of calls remaining in the rate limit window." in
    Rate_limit_remaining_histograph.v ~help ~namespace ~subsystem "rate_limit_remaining_count"

  let fn_call_total =
    let help = "Number of calls of a function" in
    Prmths.Counter.v_label ~label_name:"fn" ~help ~namespace ~subsystem "fn_call_total"
end

let fetch_pull_request_tries = 6
let one_minute = Duration.(to_f (of_min 1))
let call_timeout = Duration.(to_f (of_sec 10))

(* let log_call = function *)
(*   | `Req req -> *)
(*       Logs.debug (fun m -> *)
(*           m "req = %a" (Openapi.Request.pp (fun fmt _ -> Format.fprintf fmt "<opaque>")) req) *)
(*   | `Resp resp -> *)
(*       Logs.debug (fun m -> *)
(*           m "resp = %a" (Openapi.Response.pp (fun fmt _ -> Format.fprintf fmt "<opaque>")) resp) *)
(*   | `Err (#Openapic_abb.call_err as err) -> *)
(*       Logs.debug (fun m -> m "err = %a" Openapic_abb.pp_call_err err) *)

let rate_limit_wait resp =
  let headers = Openapi.Response.headers resp in
  let get k = CCList.Assoc.get ~eq:CCString.equal_caseless k headers in
  if Openapi.Response.status resp = 403 then
    match (get "retry-after", get "ratelimit-remaining", get "ratelimit-reset") with
    | (Some ra as retry_after), _, _ ->
        Logs.debug (fun m -> m "RATE_LIMIT : RETRY_AFTER : %s" ra);
        Abb.Future.return
          (CCOption.map_or
             ~default:(Some one_minute)
             CCFun.(CCInt.of_string %> CCOption.map CCFloat.of_int)
             retry_after)
    | None, Some "0", Some retry_time -> (
        Logs.debug (fun m -> m "RATE_LIMIT : RETRY_TIME : %s" retry_time);
        match CCFloat.of_string_opt retry_time with
        | Some retry_time ->
            let open Abb.Future.Infix_monad in
            Abb.Sys.time ()
            >>= fun now ->
            (* Make sure we wait at least one minute before retrying *)
            Abb.Future.return (Some (CCFloat.max one_minute (retry_time -. now)))
        | None -> Abb.Future.return (Some one_minute))
    | _, _, _ -> Abb.Future.return None
  else Abb.Future.return None

let get_rate_limit_remaining resp =
  let headers = Openapi.Response.headers resp in
  let get k = CCList.Assoc.get ~eq:CCString.equal_caseless k headers in
  CCOption.map CCFloat.of_int @@ CCOption.flat_map CCInt.of_string @@ get "ratelimit-remaining"

let retry_wait default_wait resp =
  let open Abb.Future.Infix_monad in
  rate_limit_wait resp
  >>= function
  | Some retry_after ->
      Logs.debug (fun m -> m "RATE_LIMIT : wait=%f" retry_after);
      Metrics.Call_retry_wait_histograph.observe Metrics.rate_limit_retry_wait_seconds retry_after;
      Abb.Future.return retry_after
  | None ->
      Logs.debug (fun m -> m "RATE_LIMIT : wait=%f" default_wait);
      Abb.Future.return default_wait

let call ?(tries = 3) t req =
  Abbs_future_combinators.retry
    ~f:(fun () ->
      let open Abbs_future_combinators.Infix_result_monad in
      Openapic_abb.call t req
      >>= fun resp ->
      CCOption.iter (fun remaining ->
          Metrics.Rate_limit_remaining_histograph.observe
            Metrics.rate_limit_remaining_count
            remaining)
      @@ get_rate_limit_remaining resp;
      Abb.Future.return (Ok resp))
    ~while_:
      (Abbs_future_combinators.finite_tries tries (function
        | Error _ -> true
        | Ok resp -> Openapi.Response.status resp >= 500))
    ~betwixt:
      (Abbs_future_combinators.series ~start:1.5 ~step:(( *. ) 1.5) (fun n resp ->
           Prmths.Counter.inc_one Metrics.call_retries_total;
           (* If it's a rate limit error, sleep until GitHub says we can try
              again *)
           match resp with
           | Error (`Missing_response resp) ->
               let open Abb.Future.Infix_monad in
               retry_wait n resp >>= Abb.Sys.sleep
           | Ok resp ->
               let open Abb.Future.Infix_monad in
               retry_wait n resp >>= Abb.Sys.sleep
           | Error _ -> Abb.Sys.sleep n))

let create config auth =
  Openapic_abb.create
    ~base_url:(Terrat_config.Gitlab.api_base_url config)
    ~user_agent:"Terrateam"
    ~call_timeout
    auth

module Config = struct
  type t = {
    config : Terrat_config.t;
    gitlab : Terrat_config.Gitlab.t;
  }

  type vcs_config = Terrat_config.Gitlab.t

  let make ~config ~vcs_config () = { config; gitlab = vcs_config }
  let config t = t.config
  let vcs_config t = t.gitlab
end

module User = struct
  module Id = struct
    type t = string [@@deriving yojson, show, eq]

    let of_string = CCOption.return
    let to_string = CCFun.id
  end

  type t = string [@@deriving yojson]

  let make = CCFun.id
  let id = CCFun.id
  let to_string = CCFun.id
end

module Account = struct
  module Id = struct
    type t = int [@@deriving yojson, show, eq]

    let of_string = CCInt.of_string
    let to_string = CCInt.to_string
  end

  type t = { installation_id : int } [@@deriving make, yojson, eq]

  let make installation_id = { installation_id }
  let id t = t.installation_id
  let to_string t = CCInt.to_string t.installation_id
end

module Repo = struct
  module Id = struct
    type t = int [@@deriving yojson, show, eq]

    let of_string = CCInt.of_string
    let to_string = CCInt.to_string
  end

  type t = {
    id : int;
    owner : string;
    name : string;
  }
  [@@deriving eq, yojson]

  let make ~id ~name ~owner () = { id; owner; name }
  let name t = t.name
  let owner t = t.owner
  let to_string t = t.owner ^ "/" ^ t.name
  let id t = t.id
end

module Remote_repo = struct
  module P = Gitlabc_components.API_Entities_ProjectWithAccess

  type t = P.t [@@deriving yojson]

  let to_repo t =
    match CCString.Split.left ~by:"/" t.P.path_with_namespace with
    | Some (owner, name) -> { Repo.id = t.P.id; owner; name }
    | None -> assert false

  let default_branch t = t.P.default_branch
end

module Ref = struct
  type t = string [@@deriving eq, yojson]

  let to_string = CCFun.id
  let of_string = CCFun.id
end

module Pull_request = struct
  module Id = struct
    type t = int [@@deriving yojson, show, eq]

    let of_string = CCInt.of_string
    let to_string = CCInt.to_string
  end

  include Terrat_pull_request

  type ('diff, 'checks) t = (Id.t, 'diff, 'checks, Repo.t, Ref.t) Terrat_pull_request.t
  [@@deriving to_yojson]
end

module Client = struct
  type t = {
    account : Account.t;
    client : Openapic_abb.t;
  }

  type native = Openapic_abb.t

  let make ~account ~client ~config () = { account; client }
  let to_native t = t.client
end

let fetch_branch_sha ~request_id client repo ref_ =
  let run =
    let module Gl = Gitlabc_projects_repository.GetApiV4ProjectsIdRepositoryBranchesBranch in
    let open Abbs_future_combinators.Infix_result_monad in
    call
      client.Client.client
      Gl.(make (Parameters.make ~id:(CCInt.to_string @@ Repo.id repo) ~branch:ref_))
    >>= fun resp ->
    let module B = Gitlabc_components.API_Entities_Branch in
    let module C = Gitlabc_components_api_entities_commit in
    match Openapi.Response.value resp with
    | `OK { B.commit = { C.id; _ }; _ } -> Abb.Future.return (Ok (Some id))
    | `Not_found -> Abb.Future.return (Ok None)
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as ret -> Abb.Future.return ret
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m -> m "%s : FETCH_BRANCH_SHA : %a" request_id Openapic_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let fetch_file ~request_id client repo ref_ path =
  let run =
    let module Gl = Gitlabc_projects_repository.GetApiV4ProjectsIdRepositoryFilesFilePath in
    let open Abbs_future_combinators.Infix_result_monad in
    call
      client.Client.client
      Gl.(make (Parameters.make ~id:(CCInt.to_string @@ Repo.id repo) ~file_path:path ~ref_))
    >>= fun resp ->
    let module OK = Gl.Responses.OK in
    match Openapi.Response.value resp with
    | `OK { OK.content; encoding = Some "base64"; _ } ->
        Abb.Future.return
          (Ok (Some (Base64.decode_exn (CCString.replace ~sub:"\n" ~by:"" content))))
    | `OK { OK.content; _ } -> Abb.Future.return (Ok (Some content))
    | `Not_found -> Abb.Future.return (Ok None)
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as ret -> Abb.Future.return ret
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m -> m "%s : FETCH_FILE : %a" request_id Openapic_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let fetch_remote_repo' ~request_id client repo =
  let module Gl = Gitlabc_projects.GetApiV4ProjectsId in
  let open Abbs_future_combinators.Infix_result_monad in
  let id = CCInt.to_string @@ Repo.id repo in
  call client.Client.client Gl.(make (Parameters.make ~id ()))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK p -> Abb.Future.return (Ok (Some p))
  | `Not_found -> Abb.Future.return (Ok None)

let fetch_remote_repo ~request_id client repo =
  let open Abb.Future.Infix_monad in
  fetch_remote_repo' ~request_id client repo
  >>= function
  | Ok (Some repo) -> Abb.Future.return (Ok repo)
  | Ok None ->
      Logs.err (fun m ->
          m "%s : FETCH_REMOTE_REPO : repo=%s : `Not_found" request_id (Repo.to_string repo));
      Abb.Future.return (Error `Error)
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m ->
          m
            "%s : FETCH_REMOTE_REPO : repo=%s : %a"
            request_id
            (Repo.to_string repo)
            Openapic_abb.pp_call_err
            err);
      Abb.Future.return (Error `Error)

let fetch_centralized_repo ~request_id client owner =
  let open Abb.Future.Infix_monad in
  fetch_remote_repo' ~request_id client (Repo.make ~id:0 ~owner ~name:"terrateam" ())
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m ->
          m
            "%s : FETCH_CENTRALIZED_REPO : owner=%s : %a"
            request_id
            owner
            Openapic_abb.pp_call_err
            err);
      Abb.Future.return (Error `Error)

let create_client ~request_id config account =
  let vcs_config = Config.vcs_config config in
  let gitlab_client =
    Openapic_abb.create
      ~user_agent:"Terrateam"
      ~base_url:(Terrat_config.Gitlab.api_base_url vcs_config)
      (`Bearer (Terrat_config.Gitlab.access_token vcs_config))
  in
  Abb.Future.return (Ok (Client.make ~account ~config ~client:gitlab_client ()))

let fetch_tree ~request_id client repo ref_ =
  let module Gl = Gitlabc_projects_repository.GetApiV4ProjectsIdRepositoryTree in
  let run =
    let open Abbs_future_combinators.Infix_result_monad in
    Openapic_abb.collect_all
      ~page:Openapic_abb.Page.gitlab
      client.Client.client
      Gl.(
        make
          (Parameters.make
             ~id:(CCInt.to_string @@ Repo.id repo)
             ~ref_:(Some ref_)
             ~recursive:true
             ()))
    >>= fun tree ->
    let module T = Gitlabc_components_api_entities_treeobject in
    Abb.Future.return
      (Ok
         (CCList.filter_map
            (function
              | { T.path; type_ = "blob"; _ } -> Some path
              | _ -> None)
            tree))
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error `Error ->
      Logs.err (fun m -> m "%s : FETCH_TREE" request_id);
      Abb.Future.return (Error `Error)
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m -> m "%s : FETCH_TREE : %a" request_id Openapic_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let comment_on_pull_request ~request_id client pull_request body =
  let module Gl =
    Gitlabc_projects_merge_requests.PostApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNotesId
  in
  let run =
    let open Abbs_future_combinators.Infix_result_monad in
    let body = { Gl.Request_body.body } in
    call
      client.Client.client
      Gl.(
        make
          ~body
          (Parameters.make
             ~id:(CCInt.to_string @@ Repo.id @@ Terrat_pull_request.repo pull_request)
             ~merge_request_iid:(Terrat_pull_request.id pull_request)))
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK -> Abb.Future.return (Ok ())
    | `Created _ -> Abb.Future.return (Ok ())
    | `Not_found -> Abb.Future.return (Error `Not_found)
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error (#Gl.Responses.t as err) ->
      Logs.err (fun m -> m "%s : COMMENT_ON_PULL_REQUEST : %a" request_id Gl.Responses.pp err);
      Abb.Future.return (Error `Error)
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m ->
          m "%s : COMMENT_ON_PULL_REQUEST : %a" request_id Openapic_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let fetch_diff ~request_id ~client ~repo merge_request_iid =
  let module Gl =
    Gitlabc_projects_merge_requests.GetApiV4ProjectsIdMergeRequestsMergeRequestIidDiffs
  in
  let run =
    let open Abbs_future_combinators.Infix_result_monad in
    Openapic_abb.collect_all
      ~page:Openapic_abb.Page.gitlab
      client.Client.client
      Gl.(make (Parameters.make ~id:(CCInt.to_string @@ Repo.id repo) ~merge_request_iid ()))
    >>= fun diff ->
    let module Tcd = Terrat_change.Diff in
    let module D = Gitlabc_components_api_entities_diff in
    Abb.Future.return
      (Ok
         (CCList.map
            (function
              | { D.old_path = filename; deleted_file = true; _ } -> Tcd.Remove { filename }
              | { D.old_path = previous_filename; new_path = filename; _ }
                when not (CCString.equal previous_filename filename) ->
                  Tcd.Move { previous_filename; filename }
              | { D.new_path = filename; new_file = true; _ } -> Tcd.Add { filename }
              | { D.new_path = filename; _ } -> Tcd.Change { filename })
            diff))
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error `Error ->
      Logs.err (fun m -> m "%s : FETCH_DIFF" request_id);
      Abb.Future.return (Error `Error)
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m -> m "%s : FETCH_DIFF : %a" request_id Openapic_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let fetch_pull_request' ~request_id ~client ~repo merge_request_iid =
  let module Gl = Gitlabc_projects_merge_requests.GetApiV4ProjectsIdMergeRequestsMergeRequestIid in
  let module Mr = Gitlabc_components_api_entities_mergerequest in
  let open Abbs_future_combinators.Infix_result_monad in
  Abbs_future_combinators.retry
    ~f:(fun () ->
      call
        client.Client.client
        Gl.(make (Parameters.make ~id:(CCInt.to_string @@ Repo.id repo) ~merge_request_iid ())))
    ~while_:
      (Abbs_future_combinators.finite_tries fetch_pull_request_tries (function
        | Ok resp -> (
            match Openapi.Response.value resp with
            | `OK { Mr.diff_refs = None; _ } -> true
            | `OK { Mr.detailed_merge_status = Some "checking"; _ } -> true
            | _ -> false)
        | Error _ -> true))
    ~betwixt:
      (Abbs_future_combinators.series ~start:2.0 ~step:(( *. ) 1.5) (fun n _ ->
           Abb.Sys.sleep (CCFloat.min n 8.0)))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK ({ Mr.diff_refs = Some diff_refs; _ } as mr) -> Abb.Future.return (Ok (diff_refs, mr))
  | `OK { Mr.diff_refs = None; _ } -> assert false
  | `Not_found -> Abb.Future.return (Error `Not_found)

let fetch_pull_request ~request_id account client repo merge_request_iid =
  let run =
    let open Abbs_future_combinators.Infix_result_monad in
    Abbs_future_combinators.Infix_result_app.(
      (fun mr diff -> (mr, diff))
      <$> fetch_pull_request' ~request_id ~client ~repo merge_request_iid
      <*> fetch_diff ~request_id ~client ~repo merge_request_iid)
    >>= fun ((diff_refs, mr), diff) ->
    let module Ub = Gitlabc_components_api_entities_userbasic in
    let module Mr = Gitlabc_components_api_entities_mergerequest in
    let module Dr = Gitlabc_components_api_entities_diffrefs in
    let { Dr.head_sha = branch_ref; base_sha = base_ref; _ } = diff_refs in
    let {
      Mr.author = { Ub.username; _ };
      detailed_merge_status;
      draft;
      merge_commit_sha;
      merged_at;
      source_branch = branch_name;
      state;
      target_branch = base_branch_name;
      title;
      _;
    } =
      mr
    in
    let mergeable = CCOption.map (CCString.equal "mergeable") detailed_merge_status in
    let checks =
      state = "merged"
      || CCOption.map_or
           ~default:false
           (fun status ->
             not (CCList.mem ~eq:CCString.equal status [ "ci_must_pass"; "ci_still_running" ]))
           detailed_merge_status
    in
    let state =
      match (state, detailed_merge_status, merge_commit_sha, merged_at) with
      | "opened", Some "conflict", _, _ ->
          Terrat_pull_request.State.(Open Open_status.Merge_conflict)
      | "opened", _, _, _ -> Terrat_pull_request.State.(Open Open_status.Mergeable)
      | "merged", _, Some merge_commit_sha, Some merged_at ->
          Terrat_pull_request.State.(Merged { Merged.merged_hash = merge_commit_sha; merged_at })
      | "closed", _, _, _ -> Terrat_pull_request.State.Closed
      | _, _, _, _ -> assert false
    in
    let draft = CCOption.get_or ~default:false draft in
    let provisional_merge_ref = None in
    Logs.info (fun m ->
        m
          "%s : MERGEABLE : detailed_merge_status=%s : merge_commit_sha=%s "
          request_id
          (CCOption.get_or ~default:"" detailed_merge_status)
          (CCOption.get_or ~default:"" merge_commit_sha));
    Abb.Future.return
      (Ok
         (Terrat_pull_request.make
            ~base_branch_name
            ~base_ref
            ~branch_name
            ~branch_ref
            ~id:merge_request_iid
            ~state
            ~title:(Some title)
            ~user:(Some username)
            ~repo
            ~checks
            ~diff
            ~draft
            ~mergeable
            ~provisional_merge_ref
            ()))
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error `Error ->
      Logs.err (fun m -> m "%s : FETCH_PULL_REQUEST" request_id);
      Abb.Future.return (Error `Error)
  | Error `Not_found ->
      Logs.err (fun m -> m "%s : FETCH_PULL_REQUEST : `Not_found" request_id);
      Abb.Future.return (Error `Error)
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m -> m "%s : FETCH_PULL_REQUEST : %a" request_id Openapic_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let react_to_comment ~request_id client pull_request comment_id =
  let module Gl =
    Gitlabc_projects_merge_requests
    .PostApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNoteIdAwardEmoji
  in
  let run =
    let open Abbs_future_combinators.Infix_result_monad in
    call
      client.Client.client
      Gl.(
        make
          (Parameters.make
             ~id:(Repo.id @@ Terrat_pull_request.repo pull_request)
             ~merge_request_iid:(Terrat_pull_request.id pull_request)
             ~note_id:comment_id
             ~name:"rocket"))
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `Created _ -> Abb.Future.return (Ok ())
    | (`Bad_request | `Not_found) as err -> Abb.Future.return (Error err)
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error (#Gl.Responses.t as err) ->
      Logs.err (fun m -> m "%s : REACT_TO_COMMENT : %a" request_id Gl.Responses.pp err);
      Abb.Future.return (Error `Error)
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m -> m "%s : REACT_TO_COMMENT : %a" request_id Openapic_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let create_commit_checks ~request_id client repo ref_ checks =
  let module Gl = Gitlabc_projects_statuses.PostApiV4ProjectsIdStatusesSha in
  let run =
    let open Abbs_future_combinators.Infix_result_monad in
    let module Glg = Gitlabc_projects_repository.GetApiV4ProjectsIdRepositoryCommitsShaStatuses in
    let module Glc = Gitlabc_components_api_entities_commitstatus in
    Openapic_abb.collect_all
      ~page:Openapic_abb.Page.gitlab
      client.Client.client
      Glg.(
        make
          (Parameters.make
             ~id:(CCInt.to_string @@ Repo.id repo)
             ~sha:ref_
             ~name:(Some "terrateam apply")
             ()))
    >>= fun existing_checks ->
    let pipeline_id =
      match existing_checks with
      | { Glc.pipeline_id; _ } :: _ -> pipeline_id
      | _ -> None
    in
    Logs.info (fun m ->
        m
          "%s : CREATE_COMMIT_CHECKS : UPDATING_WITH_PIPELINE_ID : pipeline_id=%s"
          request_id
          (CCOption.map_or ~default:"" CCInt.to_string pipeline_id));
    let module C = Terrat_commit_check in
    let module Body = Gitlabc_components_postapiv4projectsidstatusessha in
    Abbs_future_combinators.List_result.iter
      ~f:(fun { C.status; title; description; _ } ->
        let body =
          {
            Body.context = "terrateam external";
            coverage = None;
            description = Some description;
            name = title;
            pipeline_id;
            ref_ = None;
            state =
              (match status with
              | C.Status.Queued -> "pending"
              | C.Status.Running -> "running"
              | C.Status.Completed -> "success"
              | C.Status.Failed -> "failed"
              | C.Status.Canceled -> "canceled");
            target_url = None;
          }
        in
        Logs.info (fun m ->
            m "%s: CREATE_COMMIT_CHECKS : name=%s : status=%a" request_id title C.Status.pp status);
        call
          client.Client.client
          Gl.(make ~body (Parameters.make ~id:(CCInt.to_string @@ Repo.id repo) ~sha:ref_))
        >>= fun resp ->
        let module Cs = Gitlabc_components_api_entities_commitstatus in
        match Openapi.Response.value resp with
        | `Created { Cs.pipeline_id; _ } ->
            Logs.info (fun m ->
                m
                  "%s : CREATE_COMMIT_CHECKS : pipeline_id=%s"
                  request_id
                  (CCOption.map_or ~default:"" CCInt.to_string pipeline_id));
            Abb.Future.return (Ok ())
        | `Bad_request { Gl.Responses.Bad_request.message = Some message }
          when CCString.mem ~sub:"Cannot transition status via" message -> Abb.Future.return (Ok ())
        | (`Bad_request _ | `Unauthorized _ | `Forbidden _ | `Not_found _) as err ->
            Abb.Future.return (Error err))
      checks
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error `Error ->
      Logs.err (fun m -> m "%s : CREATE_COMMIT_CHECKS" request_id);
      Abb.Future.return (Error `Error)
  | Error (#Gl.Responses.t as err) ->
      Logs.err (fun m -> m "%s : CREATE_COMMIT_CHECKS : %a" request_id Gl.Responses.pp err);
      Abb.Future.return (Error `Error)
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m -> m "%s : CREATE_COMMIT_CHECKS : %a" request_id Openapic_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let fetch_commit_checks ~request_id client repo ref_ =
  let module Gl = Gitlabc_projects_repository.GetApiV4ProjectsIdRepositoryCommitsShaStatuses in
  let run =
    let open Abbs_future_combinators.Infix_result_monad in
    let module C = Terrat_commit_check in
    let module Glc = Gitlabc_components_api_entities_commitstatus in
    Openapic_abb.collect_all
      ~page:Openapic_abb.Page.gitlab
      client.Client.client
      Gl.(make (Parameters.make ~id:(CCInt.to_string @@ Repo.id repo) ~sha:ref_ ()))
    >>= fun checks ->
    Abb.Future.return
      (Ok
         (CCList.map
            (fun { Glc.description; name; status; _ } ->
              {
                C.details_url = "";
                description = CCOption.get_or ~default:"" description;
                title = name;
                status =
                  (match status with
                  | "pending" -> C.Status.Queued
                  | "running" -> C.Status.Running
                  | "success" -> C.Status.Completed
                  | "failed" -> C.Status.Failed
                  | "canceled" -> C.Status.Failed
                  | "skipped" -> C.Status.Completed
                  | _ -> C.Status.Queued);
              })
            checks))
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error `Error ->
      Logs.err (fun m -> m "%s : FETCH_COMMIT_CHECKS" request_id);
      Abb.Future.return (Error `Error)
  | Error (#Gl.Responses.t as err) ->
      Logs.err (fun m -> m "%s : FETCH_COMMIT_CHECKS : %a" request_id Gl.Responses.pp err);
      Abb.Future.return (Error `Error)
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m -> m "%s : FETCH_COMMIT_CHECKS : %a" request_id Openapic_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let fetch_pull_request_reviews ~request_id client repo pull_number =
  (* TODO: Implement *)
  Abb.Future.return (Ok [])

let merge_pull_request ~request_id client pull_request =
  let module Gl =
    Gitlabc_projects_merge_requests.PutApiV4ProjectsIdMergeRequestsMergeRequestIidMerge
  in
  let run =
    let open Abbs_future_combinators.Infix_result_monad in
    call
      client.Client.client
      Gl.(
        make
          (Parameters.make
             ~id:(CCInt.to_string @@ Repo.id @@ Terrat_pull_request.repo pull_request)
             ~merge_request_iid:(Terrat_pull_request.id pull_request)))
    >>= fun resp -> raise (Failure "nyi")
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error (#Gl.Responses.t as err) ->
      Logs.err (fun m -> m "%s : MERGE_PULL_REQUEST : %a" request_id Gl.Responses.pp err);
      Abb.Future.return (Error `Error)
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m -> m "%s : MERGE_PULL_REQUEST : %a" request_id Openapic_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let delete_branch ~request_id client repo branch =
  let module Gl = Gitlabc_projects_repository.DeleteApiV4ProjectsIdRepositoryBranchesBranch in
  let run =
    let open Abbs_future_combinators.Infix_result_monad in
    call
      client.Client.client
      Gl.(make (Parameters.make ~id:(CCInt.to_string @@ Repo.id repo) ~branch))
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `No_content -> Abb.Future.return (Ok ())
    | `Not_found -> Abb.Future.return (Error `Not_found)
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error (#Gl.Responses.t as err) ->
      Logs.err (fun m -> m "%s : DELETE_BRANCH : %a" request_id Gl.Responses.pp err);
      Abb.Future.return (Error `Error)
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m -> m "%s : DELETE_BRANCH : %a" request_id Openapic_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let fetch_member_of_team ~request_id ~team ~user client =
  let module Glu = Gitlabc_users.GetApiV4Users in
  let module Glg = Gitlabc_groups_members.GetApiV4GroupsIdMembersAllUserId in
  let run =
    let open Abbs_future_combinators.Infix_result_monad in
    call client.Client.client Glu.(make (Parameters.make ~username:(Some (User.to_string user)) ()))
    >>= fun resp ->
    let module U = Gitlabc_components_api_entities_userbasic in
    match Openapi.Response.value resp with
    | `OK ({ U.id = user_id; _ } :: _) -> (
        let group_id = Uri.pct_encode team in
        call client.Client.client Glg.(make (Parameters.make ~id:group_id ~user_id))
        >>= fun resp ->
        match Openapi.Response.value resp with
        | `OK m -> Abb.Future.return (Ok (Some m))
        | `Not_found -> Abb.Future.return (Ok None))
    | `OK [] -> Abb.Future.return (Ok None)
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error (#Openapic_abb.call_err as err) -> Abb.Future.return (Error err)

let is_member_of_team ~request_id ~team ~user repo client =
  let run =
    let open Abbs_future_combinators.Infix_result_monad in
    fetch_member_of_team ~request_id ~team ~user client
    >>= fun res -> Abb.Future.return (Ok (CCOption.is_some res))
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m -> m "%s : IS_MEMBER_OF_TEAM : %a" request_id Openapic_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let get_repo_role ~request_id repo user client =
  let module Glu = Gitlabc_users.GetApiV4Users in
  let module Glp = Gitlabc_projects_members.GetApiV4ProjectsIdMembersAllUserId in
  let run =
    let open Abbs_future_combinators.Infix_result_monad in
    call client.Client.client Glu.(make (Parameters.make ~username:(Some (User.to_string user)) ()))
    >>= fun resp ->
    let module U = Gitlabc_components_api_entities_userbasic in
    match Openapi.Response.value resp with
    | `OK ({ U.id = user_id; _ } :: _) -> (
        call
          client.Client.client
          Glp.(make (Parameters.make ~id:(CCInt.to_string @@ Repo.id repo) ~user_id))
        >>= fun resp ->
        let module M = Gitlabc_components_api_entities_member in
        match Openapi.Response.value resp with
        | `OK { M.access_level; _ } ->
            let al =
              match access_level with
              | 0 -> None
              | 5 -> Some "read"
              | 10 -> Some "read"
              | 15 -> Some "read"
              | 20 -> Some "read"
              | 30 -> Some "write"
              | 40 -> Some "maintain"
              | 50 -> Some "maintain"
              | 60 -> Some "admin"
              | _ -> None
            in
            Abb.Future.return (Ok al)
        | `Not_found -> Abb.Future.return (Ok None))
    | `OK [] -> Abb.Future.return (Error `Not_found)
  in
  let open Abb.Future.Infix_monad in
  run
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error (#Glp.Responses.t as err) ->
      Logs.err (fun m -> m "%s : GET_REPO_ROLE : %a" request_id Glp.Responses.pp err);
      Abb.Future.return (Error `Error)
  | Error (#Openapic_abb.call_err as err) ->
      Logs.err (fun m -> m "%s : GET_REPO_ROLE : %a" request_id Openapic_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let find_workflow_file ~request_id _repo _client = Abb.Future.return (Ok (Some ".gitlab-ci.yml"))
