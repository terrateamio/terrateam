module Process = Abb_process.Make (Abb)
module Org_admin = CCMap.Make (CCInt)

module Metrics = struct
  let namespace = "terrat"
  let subsystem = "github"

  let call_retries_total =
    let help = "Number of retries in a call" in
    Prmths.Counter.v ~help ~namespace ~subsystem "call_retries_total"

  let fn_call_total =
    let help = "Number of calls of a function" in
    Prmths.Counter.v_label ~label_name:"fn" ~help ~namespace ~subsystem "fn_call_total"
end

let terrateam_workflow_name = "Terrateam Workflow"
let terrateam_workflow_path = ".github/workflows/terrateam.yml"
let terrateam_config_yml = [ ".terrateam/config.yml"; ".terrateam/config.yaml" ]
let installation_expiration = 60.0

type get_access_token_err =
  [ Pgsql_pool.err
  | Pgsql_io.err
  | `Refresh_token_err of Githubc2_abb.call_err
  | `Renew_refresh_token
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

type verify_user_installation_access_err =
  [ get_access_token_err
  | Githubc2_abb.call_err
  | `Forbidden
  ]
[@@deriving show]

type get_user_installations_err =
  [ get_access_token_err
  | Githubc2_abb.call_err
  ]
[@@deriving show]

type fetch_repo_config_err =
  [ Githubc2_abb.call_err
  | Abb_process.check_output_err
  | `Repo_config_in_sub_module
  | `Repo_config_is_symlink
  | `Repo_config_is_dir
  | `Repo_config_permission_denied
  | `Repo_config_parse_err of string
  | `Repo_config_unknown_err
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

type get_tree_err =
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

let create auth = Githubc2_abb.create ~user_agent:"Terrateam" auth

let call ?(tries = 3) t req =
  let num_tries = ref 1 in
  Abbs_future_combinators.retry
    ~f:(fun () -> Githubc2_abb.call t req)
    ~test:(function
      | Error _ -> tries < !num_tries
      | Ok resp -> Openapi.Response.status resp < 500 || tries < !num_tries)
    ~betwixt:(fun _ ->
      Prmths.Counter.inc_one Metrics.call_retries_total;
      incr num_tries;
      Abb.Sys.sleep 1.5)

let get_installation_access_token config installation_id =
  Prmths.Counter.inc_one (Metrics.fn_call_total "get_installation_access_token");
  let open Abb.Future.Infix_monad in
  Abb.Sys.time ()
  >>= fun time ->
  let payload =
    let module P = Jwt.Payload in
    let module C = Jwt.Claim in
    P.empty
    |> P.add_claim C.iss (`String (Terrat_config.github_app_id config))
    |> P.add_claim C.iat (`Int (Float.to_int (time -. installation_expiration)))
    |> P.add_claim C.exp (`Int (Float.to_int (time +. installation_expiration)))
  in
  let signer = Jwt.Signer.(RS256 (Priv_key.of_priv_key (Terrat_config.github_app_pem config))) in
  let header = Jwt.Header.create (Jwt.Signer.to_string signer) in
  let jwt = Jwt.of_header_and_payload signer header payload in
  let token = Jwt.token jwt in
  let open Abbs_future_combinators.Infix_result_monad in
  let client = create (`Bearer token) in
  call
    client
    Githubc2_apps.Create_installation_access_token.(make (Parameters.make ~installation_id))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `Created token ->
      let installation_token = Githubc2_components.Installation_token.value token in
      Abb.Future.return (Ok installation_token.Githubc2_components.Installation_token.Primary.token)
  | (`Unauthorized _ | `Forbidden _ | `Not_found _ | `Unprocessable_entity _) as err ->
      Abb.Future.return (Error err)

let parse_repo_config python content =
  let open Abb.Future.Infix_monad in
  Process.check_output
    ~input:content
    Abb_intf.Process.
      {
        exec_name = python;
        args =
          [
            python;
            "-c";
            CCString.concat
              "\n"
              [
                "import sys, yaml, json";
                "try:";
                "\tprint(json.dumps(yaml.safe_load(sys.stdin.read())))";
                "except yaml.parser.ParserError as exn:";
                "\tsys.stderr.write(str(exn) + '\\n')";
                "\tsys.exit(1)";
              ];
          ];
        env = None;
        cwd = None;
      }
  >>= function
  | Ok (stdout, _) -> Abb.Future.return (Ok stdout)
  | Error (`Run_error (_, _, stderr, _)) ->
      Abb.Future.return (Error (`Repo_config_parse_err stderr))
  | Error (#Abb_process.check_output_err as err) -> Abb.Future.return (Error err)

let rec fetch_repo_config' ~python ~access_token ~owner ~repo ref_ = function
  | [] ->
      let json = `Assoc [] in
      Abb.Future.return (Ok (CCResult.get_exn (Terrat_repo_config.Version_1.of_yojson json)))
  | terrateam_config_yml :: next_config_yml -> (
      let open Abbs_future_combinators.Infix_result_monad in
      let client = create (`Token access_token) in
      call
        client
        Githubc2_repos.Get_content.(
          make (Parameters.make ~owner ~repo ~ref_:(Some ref_) ~path:terrateam_config_yml ()))
      >>= fun resp ->
      let module C = Githubc2_repos.Get_content.Responses.OK in
      match Openapi.Response.value resp with
      | `OK (C.Content_file file) -> (
          let content =
            Githubc2_components.Content_file.(
              match file.primary.Primary.encoding with
              | "base64" ->
                  Base64.decode_exn (CCString.replace ~sub:"\n" ~by:"" file.primary.Primary.content)
              | _ -> file.primary.Primary.content)
          in
          parse_repo_config python content
          >>= fun stdout ->
          try
            let json =
              match stdout with
              | "" -> `Assoc []
              | stdout -> Yojson.Safe.from_string stdout
            in
            match Terrat_repo_config.Version_1.of_yojson json with
            | Ok config -> Abb.Future.return (Ok config)
            | Error err ->
                (* This is a cheap trick but we just want to make the error message a
                   little bit more friendly to users by replacing the parts of the
                   error message that are specific to the implementation. *)
                Abb.Future.return
                  (Error
                     (`Repo_config_parse_err
                       ("Failed to parse repo config: "
                       ^ (err
                         |> CCString.replace ~sub:"Terrat_repo_config." ~by:""
                         |> CCString.replace ~sub:".t" ~by:""
                         |> CCString.lowercase_ascii))))
          with Yojson.Json_error str ->
            Abb.Future.return
              (Error (`Repo_config_parse_err ("Failed to parse repo config: " ^ str))))
      | `Not_found _ -> fetch_repo_config' ~python ~access_token ~owner ~repo ref_ next_config_yml
      | `OK (C.Content_directory _) -> Abb.Future.return (Error `Repo_config_is_dir)
      | `OK (C.Content_symlink _) -> Abb.Future.return (Error `Repo_config_is_symlink)
      | `OK (C.Content_submodule _) -> Abb.Future.return (Error `Repo_config_in_sub_module)
      | `Forbidden _ -> Abb.Future.return (Error `Repo_config_permission_denied)
      | `Found -> Abb.Future.return (Error `Repo_config_unknown_err))

let fetch_repo_config ~python ~access_token ~owner ~repo ref_ =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_repo_config");
  fetch_repo_config' ~python ~access_token ~owner ~repo ref_ terrateam_config_yml

let fetch_pull_request_files ~access_token ~owner ~pull_number repo =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_pull_request_files");
  let client = create (`Token access_token) in
  Githubc2_abb.collect_all
    client
    Githubc2_pulls.List_files.(make (Parameters.make ~owner ~pull_number ~repo ()))

let fetch_changed_files ~access_token ~owner ~repo ~base head =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_changed_files");
  let client = create (`Token access_token) in
  call client Githubc2_repos.Compare_commits.(make Parameters.(make ~base ~head ~owner ~repo ()))

let fetch_pull_request ~access_token ~owner ~repo pull_number =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_pull_request");
  let client = create (`Token access_token) in
  call client Githubc2_pulls.Get.(make Parameters.(make ~owner ~repo ~pull_number))

let compare_commits ~access_token ~owner ~repo (base, head) =
  let open Abbs_future_combinators.Infix_result_monad in
  let module Cc = Githubc2_components.Commit_comparison in
  Prmths.Counter.inc_one (Metrics.fn_call_total "compare_commits");
  let client = create (`Token access_token) in
  call client Githubc2_repos.Compare_commits.(make Parameters.(make ~base ~head ~owner ~repo ()))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK { Cc.primary = { Cc.Primary.files = Some files; _ }; _ } -> Abb.Future.return (Ok files)
  | `OK { Cc.primary = { Cc.Primary.files = None; _ }; _ } -> Abb.Future.return (Ok [])
  | (`Internal_server_error _ | `Not_found _) as err -> Abb.Future.return (Error err)

let load_workflow ~access_token ~owner ~repo =
  Prmths.Counter.inc_one (Metrics.fn_call_total "load_workflow");
  let open Abbs_future_combinators.Infix_result_monad in
  let client = create (`Token access_token) in
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
  | (id, _, _) :: _ -> Abb.Future.return (Ok (Some id))
  | [] -> Abb.Future.return (Ok None)

let publish_comment ~access_token ~owner ~repo ~pull_number body =
  Prmths.Counter.inc_one (Metrics.fn_call_total "publish_comment");
  let open Abbs_future_combinators.Infix_result_monad in
  let client = create (`Token access_token) in
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

let react_to_comment ?(content = "rocket") ~access_token ~owner ~repo ~comment_id () =
  Prmths.Counter.inc_one (Metrics.fn_call_total "react_to_comment");
  let open Abbs_future_combinators.Infix_result_monad in
  let client = create (`Token access_token) in
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

let rec get_tree ~access_token ~owner ~repo ~sha () =
  Prmths.Counter.inc_one (Metrics.fn_call_total "get_tree");
  let open Abbs_future_combinators.Infix_result_monad in
  let client = create (`Token access_token) in
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
      | `OK tree ->
          (Abbs_future_combinators.List_result.fold_left ~init:[] ~f:(fun files item ->
               let module Items = Githubc2_components_git_tree.Primary.Tree.Items in
               match item.Items.primary.Items.Primary.type_ with
               | Some "tree" ->
                   get_tree
                     ~access_token
                     ~owner
                     ~repo
                     ~sha:(CCOption.get_exn_or "get_tree_sha" item.Items.primary.Items.Primary.sha)
                     ()
                   >>= fun fs ->
                   let path =
                     CCOption.get_exn_or "get_tree_path" item.Items.primary.Items.Primary.path
                   in
                   Abb.Future.return (Ok ([ path ] @ files @ fs))
               | Some "blob" ->
                   Abb.Future.return
                     (Ok
                        (CCOption.get_exn_or "get_tree_path" item.Items.primary.Items.Primary.path
                        :: files))
               | Some typ ->
                   Logs.err (fun m -> m "GET_TREE : UNKNOWN_TYPE : %s" typ);
                   Abb.Future.return (Ok files)
               | None ->
                   Logs.err (fun m -> m "GET_TREE : TYPE : NONE");
                   Abb.Future.return (Ok files)))
            Githubc2_components_git_tree.(tree.primary.Primary.tree)
      | `Not_found _ as err -> Abb.Future.return (Error err)
      | `Unprocessable_entity _ as err -> Abb.Future.return (Error err))
  | `OK tree ->
      let tree = Githubc2_components_git_tree.(tree.primary.Primary.tree) in
      let files =
        tree
        |> CCList.map (fun item ->
               let module Items = Githubc2_components_git_tree.Primary.Tree.Items in
               CCOption.get_exn_or "git_tree_item_path" item.Items.primary.Items.Primary.path)
      in
      Abb.Future.return (Ok files)
  | `Not_found _ as err -> Abb.Future.return (Error err)
  | `Unprocessable_entity _ as err -> Abb.Future.return (Error err)

let get_team_membership_in_org ~access_token ~org ~team ~user () =
  Prmths.Counter.inc_one (Metrics.fn_call_total "get_team_membership_in_org");
  let open Abbs_future_combinators.Infix_result_monad in
  let module Team = Githubc2_components.Team_membership in
  let client = create (`Token access_token) in
  call
    client
    Githubc2_teams.Get_membership_for_user_in_org.(
      make Parameters.(make ~org ~team_slug:team ~username:user))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `Not_found -> Abb.Future.return (Ok false)
  | `OK Team.{ primary = Primary.{ state; _ }; _ } -> Abb.Future.return (Ok (state = "active"))

let get_repo_collaborator_permission ~access_token ~org ~repo ~user () =
  Prmths.Counter.inc_one (Metrics.fn_call_total "get_repo_collaborator_permission");
  let open Abbs_future_combinators.Infix_result_monad in
  let module Permission = Githubc2_components.Repository_collaborator_permission in
  let client = create (`Token access_token) in
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

  let create_client = create

  let create ~access_token ~owner ~repo ~sha creates =
    let client = create_client (`Token access_token) in
    Abbs_future_combinators.List_result.iter
      ~f:(fun Create.T.{ target_url; description; context; state } ->
        Prmths.Counter.inc_one (Metrics.fn_call_total "commit_status_create");
        let open Abbs_future_combinators.Infix_result_monad in
        call
          client
          Githubc2_repos.Create_commit_status.(
            make
              ~body:Request_body.(make Primary.(make ?context ~description ~state ~target_url ()))
              Parameters.(make ~owner ~repo ~sha))
        >>= fun _ -> Abb.Future.return (Ok ()))
      creates

  let list ~access_token ~owner ~repo ~sha () =
    Prmths.Counter.inc_one (Metrics.fn_call_total "commit_status_list");
    let open Abb.Future.Infix_monad in
    let client = create_client (`Token access_token) in
    Githubc2_abb.collect_all
      client
      Githubc2_repos.List_commit_statuses_for_ref.(make Parameters.(make ~owner ~repo ~ref_:sha ()))
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error #list_err as err -> Abb.Future.return err
end

module Status_check = struct
  type list_err = Githubc2_abb.call_err [@@deriving show]

  let create_client = create

  let list ~access_token ~owner ~repo ~ref_ () =
    Prmths.Counter.inc_one (Metrics.fn_call_total "status_check_list");
    let open Abb.Future.Infix_monad in
    let client = create_client (`Token access_token) in
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

  let create_client = create

  let list ~access_token ~owner ~repo ~pull_number () =
    Prmths.Counter.inc_one (Metrics.fn_call_total "pull_request_reviews_list");
    let client = create_client (`Token access_token) in
    Githubc2_abb.collect_all
      client
      Githubc2_pulls.List_reviews.(make Parameters.(make ~owner ~repo ~pull_number ()))
end
