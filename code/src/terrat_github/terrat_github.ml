module Org_admin = CCMap.Make (CCInt)

module Metrics = struct
  module Call_retry_wait_histograph = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_exponential 30.0 1.2 20
  end)

  let namespace = "terrat"
  let subsystem = "github"

  let call_retries_total =
    let help = "Number of retries in a call" in
    Prmths.Counter.v ~help ~namespace ~subsystem "call_retries_total"

  let rate_limit_retry_wait_seconds =
    let help = "Number of seconds a call has spent waiting due to rate limit" in
    Call_retry_wait_histograph.v ~help ~namespace ~subsystem "rate_limit_retry_wait_seconds"

  let fn_call_total =
    let help = "Number of calls of a function" in
    Prmths.Counter.v_label ~label_name:"fn" ~help ~namespace ~subsystem "fn_call_total"
end

let terrateam_workflow_name = "Terrateam Workflow"
let terrateam_workflow_path = ".github/workflows/terrateam.yml"
let installation_expiration_sec = 60.0
let call_timeout = 10.0

type user_err =
  [ Githubc2_abb.call_err
  | `Unauthorized of Githubc2_components.Basic_error.t
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_modified
  | `Unauthorized of Githubc2_components.Basic_error.t
  ]
[@@deriving show]

type get_installation_access_token_err =
  [ Githubc2_abb.call_err
  | `Unauthorized of Githubc2_components.Basic_error.t
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type get_user_installations_err =
  [ Githubc2_abb.call_err
  | `Unauthorized of Githubc2_components.Basic_error.t
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_modified
  ]
[@@deriving show]

type get_installation_repos_err =
  [ Githubc2_abb.call_err
  | `Not_modified
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unauthorized of Githubc2_components.Basic_error.t
  ]
[@@deriving show]

type fetch_file_err =
  [ Githubc2_abb.call_err
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Found
  | `Not_file
  ]
[@@deriving show]

type fetch_repo_err =
  [ Githubc2_abb.call_err
  | `Moved_permanently of Githubc2_repos.Get.Responses.Moved_permanently.t
  | `Forbidden of Githubc2_repos.Get.Responses.Forbidden.t
  | `Not_found of Githubc2_repos.Get.Responses.Not_found.t
  ]
[@@deriving show]

type create_pull_request_err =
  [ Githubc2_abb.call_err
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type create_ref_err =
  [ Githubc2_abb.call_err
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type fetch_branch_err =
  [ Githubc2_abb.call_err
  | `Moved_permanently of Githubc2_repos.Get_branch.Responses.Moved_permanently.t
  | `Not_found of Githubc2_repos.Get_branch.Responses.Not_found.t
  ]
[@@deriving show]

type publish_comment_err =
  [ Githubc2_abb.call_err
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_found of Githubc2_components.Basic_error.t
  | `Gone of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type publish_reaction_err =
  [ Githubc2_abb.call_err
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type get_tree_raw_err =
  [ Githubc2_abb.call_err
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type get_tree_err =
  [ Githubc2_abb.call_err
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type create_tree_err =
  [ Githubc2_abb.call_err
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type create_commit_err =
  [ Githubc2_abb.call_err
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type get_team_membership_in_org_err = Githubc2_abb.call_err [@@deriving show]
type get_repo_collaborator_permission_err = Githubc2_abb.call_err [@@deriving show]

type compare_commits_err =
  [ Githubc2_abb.call_err
  | `Not_found of Githubc2_components.Basic_error.t
  | `Internal_server_error of Githubc2_components.Basic_error.t
  ]
[@@deriving show]

let max_get_tree_chunks = 20

let is_secondary_rate_limit_error resp =
  let headers = Openapi.Response.headers resp in
  let get k = CCList.Assoc.get ~eq:CCString.equal_caseless k headers in
  Openapi.Response.status resp = 403
  &&
  match (get "retry-after", get "x-ratelimit-remaining", get "x-ratelimit-reset") with
  | Some _, _, _ | None, Some "0", Some _ -> true
  | _, _, _ -> false

let rate_limit_wait resp =
  let headers = Openapi.Response.headers resp in
  let get k = CCList.Assoc.get ~eq:CCString.equal_caseless k headers in
  if Openapi.Response.status resp = 403 then
    match (get "retry-after", get "x-ratelimit-remaining", get "x-ratelimit-reset") with
    | (Some _ as retry_after), _, _ ->
        Abb.Future.return
          (CCOption.map
             CCFloat.of_int
             (CCOption.map_or ~default:(Some 60) CCInt.of_string retry_after))
    | None, Some "0", Some retry_time -> (
        match CCFloat.of_string_opt retry_time with
        | Some retry_time ->
            let open Abb.Future.Infix_monad in
            Abb.Sys.time () >>= fun now -> Abb.Future.return (Some (retry_time -. now))
        | None -> Abb.Future.return (Some 60.0))
    | _, _, _ -> Abb.Future.return None
  else Abb.Future.return None

let create config auth =
  Githubc2_abb.create
    ~base_url:(Terrat_config.github_api_base_url config)
    ~user_agent:"Terrateam"
    ~call_timeout
    auth

let with_client config auth f =
  let client = create config auth in
  f client

let retry_wait default_wait resp =
  let open Abb.Future.Infix_monad in
  rate_limit_wait resp
  >>= function
  | Some retry_after ->
      Metrics.Call_retry_wait_histograph.observe Metrics.rate_limit_retry_wait_seconds retry_after;
      Abb.Future.return retry_after
  | None -> Abb.Future.return default_wait

let call ?(tries = 3) t req =
  Abbs_future_combinators.retry
    ~f:(fun () -> Githubc2_abb.call t req)
    ~while_:
      (Abbs_future_combinators.finite_tries tries (function
          | Error _ -> true
          | Ok resp -> Openapi.Response.status resp >= 500 || is_secondary_rate_limit_error resp))
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

let user ~config ~access_token () =
  let open Abbs_future_combinators.Infix_result_monad in
  Prmths.Counter.inc_one (Metrics.fn_call_total "user");
  let client = create config (`Token access_token) in
  call client (Githubc2_users.Get_authenticated.make ())
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK user -> Abb.Future.return (Ok user)
  | (`Forbidden _ | `Not_modified | `Unauthorized _) as err -> Abb.Future.return (Error err)

let get_installation_access_token
    ?(expiration_sec = installation_expiration_sec)
    ?permissions
    config
    installation_id =
  Prmths.Counter.inc_one (Metrics.fn_call_total "get_installation_access_token");
  let open Abb.Future.Infix_monad in
  Abb.Sys.time ()
  >>= fun time ->
  let payload =
    let module P = Jwt.Payload in
    let module C = Jwt.Claim in
    P.empty
    |> P.add_claim C.iss (`String (Terrat_config.github_app_id config))
    |> P.add_claim C.iat (`Int (Float.to_int (time -. expiration_sec)))
    |> P.add_claim C.exp (`Int (Float.to_int (time +. expiration_sec)))
  in
  let signer = Jwt.Signer.(RS256 (Priv_key.of_priv_key (Terrat_config.github_app_pem config))) in
  let header = Jwt.Header.create (Jwt.Signer.to_string signer) in
  let jwt = Jwt.of_header_and_payload signer header payload in
  let token = Jwt.token jwt in
  let open Abbs_future_combinators.Infix_result_monad in
  let client = create config (`Bearer token) in
  call
    client
    Githubc2_apps.Create_installation_access_token.(
      make
        ~body:Request_body.(make Primary.(make ~permissions ()))
        (Parameters.make ~installation_id))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `Created token ->
      let installation_token = Githubc2_components.Installation_token.value token in
      Abb.Future.return (Ok installation_token.Githubc2_components.Installation_token.Primary.token)
  | (`Unauthorized _ | `Forbidden _ | `Not_found _ | `Unprocessable_entity _) as err ->
      Abb.Future.return (Error err)

let create_pull_request ~owner ~repo ~base_branch ~branch ~title ~body client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "create_pull_request");
  let open Abbs_future_combinators.Infix_result_monad in
  call
    client
    Githubc2_pulls.Create.(
      make
        ~body:
          Request_body.(
            make
              Primary.(make ~base:base_branch ~body:(Some body) ~head:branch ~title:(Some title) ()))
        Parameters.(make ~owner ~repo))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `Created pr -> Abb.Future.return (Ok pr)
  | (`Forbidden _ | `Unprocessable_entity _) as err -> Abb.Future.return (Error err)

let create_ref ~owner ~repo ~ref_ ~sha client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "create_ref");
  let open Abbs_future_combinators.Infix_result_monad in
  call
    client
    Githubc2_git.Create_ref.(
      make ~body:Request_body.(make Primary.(make ~ref_ ~sha)) Parameters.(make ~owner ~repo))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `Created _ -> Abb.Future.return (Ok ())
  | `Unprocessable_entity _ as err -> Abb.Future.return (Error err)

let fetch_repo ~owner ~repo client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_repo");
  let open Abbs_future_combinators.Infix_result_monad in
  call client Githubc2_repos.Get.(make (Parameters.make ~owner ~repo))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK repo -> Abb.Future.return (Ok repo)
  | (`Forbidden _ | `Moved_permanently _ | `Not_found _) as err -> Abb.Future.return (Error err)

let fetch_branch ~owner ~repo ~branch client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_branch");
  let open Abbs_future_combinators.Infix_result_monad in
  call client Githubc2_repos.Get_branch.(make (Parameters.make ~branch ~owner ~repo))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK branch -> Abb.Future.return (Ok branch)
  | (`Moved_permanently _ | `Not_found _) as err -> Abb.Future.return (Error err)

let fetch_file ~owner ~repo ~ref_ ~path client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_file");
  let open Abbs_future_combinators.Infix_result_monad in
  call
    client
    Githubc2_repos.Get_content.(make (Parameters.make ~owner ~repo ~ref_:(Some ref_) ~path ()))
  >>= fun resp ->
  let module C = Githubc2_repos.Get_content.Responses.OK in
  match Openapi.Response.value resp with
  | `OK (C.Content_file file) -> Abb.Future.return (Ok (Some file))
  | `OK _ -> Abb.Future.return (Error `Not_file)
  | `Not_found _ -> Abb.Future.return (Ok None)
  | (`Forbidden _ | `Found) as err -> Abb.Future.return (Error err)

let fetch_pull_request_files ~owner ~repo ~pull_number client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_pull_request_files");
  Githubc2_abb.collect_all
    client
    Githubc2_pulls.List_files.(make (Parameters.make ~per_page:100 ~owner ~pull_number ~repo ()))

let fetch_changed_files ~owner ~repo ~base ~head client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_changed_files");
  call client Githubc2_repos.Compare_commits.(make Parameters.(make ~base ~head ~owner ~repo ()))

let fetch_pull_request ~owner ~repo ~pull_number client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_pull_request");
  call client Githubc2_pulls.Get.(make Parameters.(make ~owner ~repo ~pull_number))

let compare_commits ~owner ~repo (base, head) client =
  let open Abbs_future_combinators.Infix_result_monad in
  let module Cc = Githubc2_components.Commit_comparison in
  Prmths.Counter.inc_one (Metrics.fn_call_total "compare_commits");
  call client Githubc2_repos.Compare_commits.(make Parameters.(make ~base ~head ~owner ~repo ()))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK { Cc.primary = { Cc.Primary.files = Some files; _ }; _ } -> Abb.Future.return (Ok files)
  | `OK { Cc.primary = { Cc.Primary.files = None; _ }; _ } -> Abb.Future.return (Ok [])
  | (`Internal_server_error _ | `Not_found _) as err -> Abb.Future.return (Error err)

let get_user_installations client =
  let open Abbs_future_combinators.Infix_result_monad in
  let module R = Githubc2_apps.List_installations_for_authenticated_user.Responses in
  Prmths.Counter.inc_one (Metrics.fn_call_total "get_user_installations");
  call
    client
    Githubc2_apps.List_installations_for_authenticated_user.(
      make Parameters.(make ~per_page:100 ()))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK R.OK.{ primary = Primary.{ installations; _ }; _ } -> Abb.Future.return (Ok installations)
  | (`Forbidden _ | `Not_modified | `Unauthorized _) as err -> Abb.Future.return (Error err)

let get_installation_repos client =
  let module R = Githubc2_apps.List_repos_accessible_to_installation.Responses in
  Prmths.Counter.inc_one (Metrics.fn_call_total "get_installation_repos");
  Githubc2_abb.fold
    client
    ~init:[]
    ~f:(fun acc resp ->
      match Openapi.Response.value resp with
      | `OK { R.OK.primary = { R.OK.Primary.repositories; _ }; _ } ->
          Abb.Future.return (Ok (acc @ repositories))
      | (`Forbidden _ | `Not_found _ | `Not_modified | `Unauthorized _) as err ->
          Abb.Future.return (Error err))
    Githubc2_apps.List_repos_accessible_to_installation.(make Parameters.(make ()))

let load_workflow' ~owner ~repo client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "load_workflow");
  let open Abbs_future_combinators.Infix_result_monad in
  Githubc2_abb.fold
    client
    ~init:[]
    ~f:(fun acc resp ->
      let module Lrwr = Githubc2_actions.List_repo_workflows.Responses.OK in
      match Openapi.Response.value resp with
      | `OK { Lrwr.primary = { Lrwr.Primary.workflows; _ }; _ } ->
          let module Workflow = Githubc2_components.Workflow in
          let workflows =
            CCList.map
              (fun { Workflow.primary; _ } ->
                let id = primary.Workflow.Primary.id in
                let name = primary.Workflow.Primary.name in
                let path = primary.Workflow.Primary.path in
                (id, name, path))
              workflows
          in
          Abb.Future.return (Ok (workflows @ acc)))
    Githubc2_actions.List_repo_workflows.(make (Parameters.make ~owner ~repo ()))
  >>= fun workflows ->
  match
    CCList.filter
      (fun (_, name, path) ->
        CCString.equal name terrateam_workflow_name || CCString.equal path terrateam_workflow_path)
      workflows
  with
  | res :: _ -> Abb.Future.return (Ok (Some res))
  | [] -> Abb.Future.return (Ok None)

let find_workflow_file ~owner ~repo client =
  Abbs_future_combinators.retry
    ~f:(fun () ->
      let open Abbs_future_combinators.Infix_result_monad in
      load_workflow' ~owner ~repo client
      >>= fun res -> Abb.Future.return (Ok (CCOption.map (fun (_, _, path) -> path) res)))
    ~while_:(Abbs_future_combinators.finite_tries 3 CCResult.is_error)
    ~betwixt:
      (Abbs_future_combinators.series ~start:1.5 ~step:(( *. ) 1.5) (fun n _ ->
           Prmths.Counter.inc_one Metrics.call_retries_total;
           Abb.Sys.sleep n))

let load_workflow ~owner ~repo client =
  Abbs_future_combinators.retry
    ~f:(fun () ->
      let open Abbs_future_combinators.Infix_result_monad in
      load_workflow' ~owner ~repo client
      >>= fun res -> Abb.Future.return (Ok (CCOption.map (fun (id, _, _) -> id) res)))
    ~while_:(Abbs_future_combinators.finite_tries 3 CCResult.is_error)
    ~betwixt:
      (Abbs_future_combinators.series ~start:1.5 ~step:(( *. ) 1.5) (fun n _ ->
           Prmths.Counter.inc_one Metrics.call_retries_total;
           Abb.Sys.sleep n))

let publish_comment ~owner ~repo ~pull_number ~body client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "publish_comment");
  let open Abbs_future_combinators.Infix_result_monad in
  call
    client
    Githubc2_issues.Create_comment.(
      make
        ~body:Request_body.(make Primary.{ body })
        Parameters.(make ~issue_number:pull_number ~owner ~repo))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `Created _ -> Abb.Future.return (Ok ())
  | (`Forbidden _ | `Not_found _ | `Gone _ | `Unprocessable_entity _) as err ->
      Abb.Future.return (Error err)

let react_to_comment ?(content = "rocket") ~owner ~repo ~comment_id client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "react_to_comment");
  let open Abbs_future_combinators.Infix_result_monad in
  call
    client
    Githubc2_reactions.Create_for_issue_comment.(
      make
        ~body:Request_body.(make Primary.(make ~content))
        Parameters.(make ~comment_id ~owner ~repo))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK _ | `Created _ -> Abb.Future.return (Ok ())
  | `Unprocessable_entity _ as err -> Abb.Future.return (Error err)

let get_tree_raw ?(recursive = true) ~owner ~repo ~sha client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "get_tree");
  let open Abbs_future_combinators.Infix_result_monad in
  call
    client
    Githubc2_git.Get_tree.(
      make
        Parameters.(make ~recursive:(Some (Bool.to_string recursive)) ~owner ~repo ~tree_sha:sha ()))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK tree -> Abb.Future.return (Ok tree)
  | (`Not_found _ | `Unprocessable_entity _) as err -> Abb.Future.return (Error err)

let rec get_tree ~owner ~repo ~sha client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "get_tree");
  let open Abbs_future_combinators.Infix_result_monad in
  call
    client
    Githubc2_git.Get_tree.(
      make Parameters.(make ~recursive:(Some "true") ~owner ~repo ~tree_sha:sha ()))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK tree when Githubc2_components_git_tree.(tree.primary.Primary.truncated) -> (
      call client Githubc2_git.Get_tree.(make Parameters.(make ~owner ~repo ~tree_sha:sha ()))
      >>= fun resp ->
      match Openapi.Response.value resp with
      | `OK tree -> (
          let open Abb.Future.Infix_monad in
          (* In the case that the response is truncated, we need to preform
             the recursive calls ourselves.  We will do that in parallel, with
             maximum number of concurrent lookups per level being
             [max_get_tree_chunks]. *)
          let num_items = CCList.length Githubc2_components_git_tree.(tree.primary.Primary.tree) in
          let num_per_chunk =
            match num_items / max_get_tree_chunks with
            | 0 -> num_items
            | n -> n
          in
          let items =
            CCList.chunks num_per_chunk Githubc2_components_git_tree.(tree.primary.Primary.tree)
          in
          Abbs_future_combinators.List.map_par
            ~f:(fun items ->
              let open Abbs_future_combinators.Infix_result_monad in
              Abbs_future_combinators.List_result.fold_left
                ~init:[]
                ~f:(fun files item ->
                  let module Items = Githubc2_components_git_tree.Primary.Tree.Items in
                  match item.Items.primary.Items.Primary.type_ with
                  | Some "tree" ->
                      get_tree
                        ~owner
                        ~repo
                        ~sha:
                          (CCOption.get_exn_or "get_tree_sha" item.Items.primary.Items.Primary.sha)
                        client
                      >>= fun fs ->
                      let path =
                        CCOption.get_exn_or "get_tree_path" item.Items.primary.Items.Primary.path
                      in
                      let fs = CCList.map (Filename.concat path) fs in
                      Abb.Future.return (Ok (files @ fs))
                  | Some "blob" ->
                      Abb.Future.return
                        (Ok
                           (CCOption.get_exn_or
                              "get_tree_path"
                              item.Items.primary.Items.Primary.path
                           :: files))
                  | Some typ ->
                      Logs.err (fun m -> m "GET_TREE : UNKNOWN_TYPE : %s" typ);
                      Abb.Future.return (Ok files)
                  | None ->
                      Logs.err (fun m -> m "GET_TREE : TYPE : NONE");
                      Abb.Future.return (Ok files))
                items)
            items
          >>= fun res ->
          match CCResult.flatten_l res with
          | Ok files -> Abb.Future.return (Ok (CCList.flatten files))
          | Error _ as err -> Abb.Future.return err)
      | `Not_found _ as err -> Abb.Future.return (Error err)
      | `Unprocessable_entity _ as err -> Abb.Future.return (Error err))
  | `OK tree ->
      let tree = Githubc2_components_git_tree.(tree.primary.Primary.tree) in
      let files =
        tree
        |> CCList.filter_map (fun item ->
               let module Items = Githubc2_components_git_tree.Primary.Tree.Items in
               match item.Items.primary.Items.Primary.type_ with
               | Some "blob" -> item.Items.primary.Items.Primary.path
               | _ -> None)
      in
      Abb.Future.return (Ok files)
  | `Not_found _ as err -> Abb.Future.return (Error err)
  | `Unprocessable_entity _ as err -> Abb.Future.return (Error err)

let create_tree ~owner ~repo ~base_tree ~tree client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "create_tree");
  let module Git_tree = Githubc2_components.Git_tree in
  let open Abbs_future_combinators.Infix_result_monad in
  let tree =
    CCList.map (fun item -> Githubc2_git.Create_tree.Request_body.Primary.Tree.Items.make item) tree
  in
  let body =
    Githubc2_git.Create_tree.Request_body.(make (Primary.make ~base_tree:(Some base_tree) ~tree ()))
  in
  call client Githubc2_git.Create_tree.(make ~body Parameters.(make ~owner ~repo))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `Created { Git_tree.primary = { Git_tree.Primary.sha; _ }; _ } -> Abb.Future.return (Ok sha)
  | (`Forbidden _ | `Not_found _ | `Unprocessable_entity _) as err -> Abb.Future.return (Error err)

let create_commit ~owner ~repo ~msg ~parent ~tree_sha client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "create_commit");
  let module C = Githubc2_git.Create_commit in
  let module Commit = Githubc2_components.Git_commit in
  let open Abbs_future_combinators.Infix_result_monad in
  let body =
    C.Request_body.(make Primary.(make ~message:msg ~parents:(Some [ parent ]) ~tree:tree_sha ()))
  in
  call client C.(make ~body Parameters.(make ~owner ~repo))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `Created { Commit.primary = { Commit.Primary.sha; _ }; _ } -> Abb.Future.return (Ok sha)
  | (`Not_found _ | `Unprocessable_entity _) as err -> Abb.Future.return (Error err)

let get_team_membership_in_org ~org ~team ~user client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "get_team_membership_in_org");
  let open Abbs_future_combinators.Infix_result_monad in
  let module Team = Githubc2_components.Team_membership in
  call
    client
    Githubc2_teams.Get_membership_for_user_in_org.(
      make Parameters.(make ~org ~team_slug:team ~username:user))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `Not_found -> Abb.Future.return (Ok false)
  | `OK Team.{ primary = Primary.{ state; _ }; _ } -> Abb.Future.return (Ok (state = "active"))

let get_repo_collaborator_permission ~org ~repo ~user client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "get_repo_collaborator_permission");
  let open Abbs_future_combinators.Infix_result_monad in
  let module Permission = Githubc2_components.Repository_collaborator_permission in
  call
    client
    Githubc2_repos.Get_collaborator_permission_level.(
      make Parameters.(make ~owner:org ~repo ~username:user))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `Not_found _ -> Abb.Future.return (Ok None)
  | `OK Permission.{ primary = Primary.{ role_name; _ }; _ } ->
      Abb.Future.return (Ok (Some role_name))

module Commit_status = struct
  type create_err = Githubc2_abb.call_err [@@deriving show]

  type list_err =
    [ Githubc2_abb.call_err
    | `Error
    | `Moved_permanently of Githubc2_components.Basic_error.t
    ]
  [@@deriving show]

  module Create = struct
    module T = struct
      type t = {
        target_url : string option;
        description : string option;
        context : string option;
        state : string;
      }
      [@@deriving show]

      let make ?target_url ?description ?context ~state () =
        { target_url; description; context; state }
    end

    type t = T.t list
  end

  let create ~owner ~repo ~sha ~creates client =
    let max_parallel = 20 in
    let open Abb.Future.Infix_monad in
    Abbs_future_combinators.List.map_par
      ~f:(fun creates ->
        Abbs_future_combinators.List_result.iter
          ~f:(fun Create.T.{ target_url; description; context; state } ->
            Prmths.Counter.inc_one (Metrics.fn_call_total "commit_status_create");
            let open Abbs_future_combinators.Infix_result_monad in
            call
              client
              Githubc2_repos.Create_commit_status.(
                make
                  ~body:
                    Request_body.(make Primary.(make ?context ~description ~state ~target_url ()))
                  Parameters.(make ~owner ~repo ~sha))
            >>= fun _ -> Abb.Future.return (Ok ()))
          creates)
      (CCList.chunks (CCInt.max 1 (CCList.length creates / max_parallel)) creates)
    >>= fun res ->
    match CCResult.flatten_l res with
    | Ok _ -> Abb.Future.return (Ok ())
    | Error _ as err -> Abb.Future.return err

  let list ~owner ~repo ~sha client =
    Prmths.Counter.inc_one (Metrics.fn_call_total "commit_status_list");
    let open Abb.Future.Infix_monad in
    Abbs_future_combinators.retry
      ~f:(fun () ->
        Githubc2_abb.collect_all
          client
          Githubc2_repos.List_commit_statuses_for_ref.(
            make Parameters.(make ~owner ~repo ~ref_:sha ())))
      ~while_:(Abbs_future_combinators.finite_tries 3 CCResult.is_error)
      ~betwixt:
        (Abbs_future_combinators.series ~start:1.5 ~step:(( *. ) 1.5) (fun n _ ->
             Prmths.Counter.inc_one Metrics.call_retries_total;
             Abb.Sys.sleep n))
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error #list_err as err -> Abb.Future.return err
end

module Status_check = struct
  type list_err = Githubc2_abb.call_err [@@deriving show]

  let list ~owner ~repo ~ref_ client =
    Prmths.Counter.inc_one (Metrics.fn_call_total "status_check_list");
    let open Abb.Future.Infix_monad in
    call client Githubc2_checks.List_for_ref.(make Parameters.(make ~owner ~repo ~ref_ ()))
    >>= function
    | Ok resp ->
        let module OK = Githubc2_checks.List_for_ref.Responses.OK in
        let (`OK OK.{ primary = Primary.{ check_runs; _ }; _ }) = Openapi.Response.value resp in
        Abb.Future.return (Ok check_runs)
    | Error _ as err -> Abb.Future.return err
end

module Pull_request_reviews = struct
  type list_err =
    [ `Error
    | Githubc2_abb.call_err
    ]
  [@@deriving show]

  let list ~owner ~repo ~pull_number client =
    Prmths.Counter.inc_one (Metrics.fn_call_total "pull_request_reviews_list");
    Githubc2_abb.collect_all
      client
      Githubc2_pulls.List_reviews.(make Parameters.(make ~owner ~repo ~pull_number ()))
end

module Oauth = struct
  module Http = Cohttp_abb.Make (Abb)

  let tls_config =
    let cfg = Otls.Tls_config.create () in
    Otls.Tls_config.insecure_noverifycert cfg;
    cfg

  module Response = struct
    type t = {
      access_token : string;
      scope : string;
      token_type : string;
      refresh_token : string option; [@default None]
      refresh_token_expires_in : int option; [@default None]
      expires_in : int option; [@default None]
    }
    [@@deriving yojson { strict = false }, show]
  end

  let authorize ~config code =
    let open Abb.Future.Infix_monad in
    let headers =
      Cohttp.Header.of_list
        [
          ("user-agent", "Terrateam");
          ("content-type", "application/json");
          ("accept", "application/vnd.github.v3+json");
        ]
    in
    let uri =
      Uri.of_string
        (Printf.sprintf
           "%s/login/oauth/access_token"
           (Uri.to_string (Terrat_config.github_web_base_url config)))
    in
    let body =
      Cohttp.Body.of_string
        (Yojson.Safe.to_string
           (`Assoc
             [
               ("client_id", `String (Terrat_config.github_app_client_id config));
               ("client_secret", `String (Terrat_config.github_app_client_secret config));
               ("code", `String code);
             ]))
    in
    Http.Client.call ~headers ~tls_config ~body `POST uri
    >>| function
    | Ok (resp, body)
      when Cohttp.Code.is_success (Cohttp.Code.code_of_status (Http.Response.status resp)) -> (
        match Response.of_yojson (Yojson.Safe.from_string body) with
        | Ok value -> Ok value
        | Error _ -> Error `Error)
    | Ok (resp, _) -> Error `Error
    | Error _ -> Error `Error

  let refresh ~config refresh_token =
    let open Abb.Future.Infix_monad in
    let headers =
      Cohttp.Header.of_list
        [
          ("user-agent", "Terrateam");
          ("accept", "application/json");
          ("content-type", "application/json");
        ]
    in
    let uri =
      Uri.of_string
        (Printf.sprintf
           "%s/login/oauth/access_token"
           (Uri.to_string (Terrat_config.github_web_base_url config)))
    in
    let body =
      Cohttp.Body.of_string
        (Yojson.Safe.to_string
           (`Assoc
             [
               ("client_id", `String (Terrat_config.github_app_client_id config));
               ("client_secret", `String (Terrat_config.github_app_client_secret config));
               ("grant_type", `String "refresh_token");
               ("refresh_token", `String refresh_token);
             ]))
    in
    Http.Client.call ~headers ~tls_config ~body `POST uri
    >>| function
    | Ok (resp, body)
      when Cohttp.Code.is_success (Cohttp.Code.code_of_status (Http.Response.status resp)) -> (
        match Response.of_yojson (Yojson.Safe.from_string body) with
        | Ok value -> Ok value
        | Error _ -> Error `Error)
    | Ok (resp, _) -> Error `Error
    | Error _ -> Error `Error
end
