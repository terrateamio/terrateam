module Process = Abb_process.Make (Abb)
module Org_admin = CCMap.Make (CCInt)

let terrateam_workflow_name = "Terrateam Workflow"
let terrateam_config_yml = ".terrateam/config.yml"
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
  | `Unsupported_media_type of
    Githubc2_apps.Create_installation_access_token.Responses.Unsupported_media_type.t
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

let create auth = Githubc2_abb.create ~user_agent:"Terrateam" auth

let get_installation_access_token config installation_id =
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
  Githubc2_abb.call
    client
    Githubc2_apps.Create_installation_access_token.(make (Parameters.make ~installation_id))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `Created token ->
      let installation_token = Githubc2_components.Installation_token.value token in
      Abb.Future.return (Ok installation_token.Githubc2_components.Installation_token.Primary.token)
  | ( `Unauthorized _
    | `Forbidden _
    | `Not_found _
    | `Unsupported_media_type _
    | `Unprocessable_entity _ ) as err -> Abb.Future.return (Error err)

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

let fetch_repo_config ~python ~access_token ~owner ~repo ref_ =
  let open Abbs_future_combinators.Infix_result_monad in
  let client = create (`Token access_token) in
  Githubc2_abb.call
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
        Abb.Future.return (Error (`Repo_config_parse_err ("Failed to parse repo config: " ^ str))))
  | `Not_found _ ->
      let json = `Assoc [] in
      Abb.Future.return (Ok (CCResult.get_exn (Terrat_repo_config.Version_1.of_yojson json)))
  | `OK (C.Content_directory _) -> Abb.Future.return (Error `Repo_config_is_dir)
  | `OK (C.Content_symlink _) -> Abb.Future.return (Error `Repo_config_is_symlink)
  | `OK (C.Content_submodule _) -> Abb.Future.return (Error `Repo_config_in_sub_module)
  | `Forbidden _ -> Abb.Future.return (Error `Repo_config_permission_denied)
  | `Found -> Abb.Future.return (Error `Repo_config_unknown_err)

let fetch_pull_request_files ~access_token ~owner ~pull_number repo =
  let client = create (`Token access_token) in
  Githubc2_abb.collect_all
    client
    Githubc2_pulls.List_files.(make (Parameters.make ~owner ~pull_number ~repo ()))

let fetch_changed_files ~access_token ~owner ~repo ~base head =
  let client = create (`Token access_token) in
  Githubc2_abb.call
    client
    Githubc2_repos.Compare_commits.(make Parameters.(make ~base ~head ~owner ~repo ()))

let fetch_pull_request ~access_token ~owner ~repo pull_number =
  let client = create (`Token access_token) in
  Githubc2_abb.call client Githubc2_pulls.Get.(make Parameters.(make ~owner ~repo ~pull_number))

let compare_commits ~access_token ~owner ~repo (base, head) =
  let client = create (`Token access_token) in
  Githubc2_abb.call
    client
    Githubc2_repos.Compare_commits.(make Parameters.(make ~base ~head ~owner ~repo ()))

let load_workflow ~access_token ~owner ~repo =
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
                (id, name))
              workflows
          in
          Abb.Future.return (Ok (workflows @ acc)))
    Githubc2_actions.List_repo_workflows.(make (Parameters.make ~owner ~repo ()))
  >>= fun workflows ->
  match CCList.filter (fun (_, name) -> CCString.equal name terrateam_workflow_name) workflows with
  | (id, _) :: _ -> Abb.Future.return (Ok (Some id))
  | [] -> Abb.Future.return (Ok None)

let publish_comment ~access_token ~owner ~repo ~pull_number body =
  let open Abbs_future_combinators.Infix_result_monad in
  let client = create (`Token access_token) in
  Githubc2_abb.call
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

let react_to_comment ~access_token ~owner ~repo ~comment_id () =
  let open Abbs_future_combinators.Infix_result_monad in
  let client = create (`Token access_token) in
  Githubc2_abb.call
    client
    Githubc2_reactions.Create_for_issue_comment.(
      make
        ~body:Request_body.(make Primary.(make ~content:"rocket"))
        Parameters.(make ~comment_id ~owner ~repo))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK _ | `Created _ -> Abb.Future.return (Ok ())
  | `Unprocessable_entity _ as err -> Abb.Future.return (Error err)

module Commit_status = struct
  type create_err = Githubc2_abb.call_err [@@deriving show]

  module Create = struct
    module T = struct
      type t = {
        target_url : string option;
        description : string option;
        context : string option;
        state : string;
      }

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
        let open Abbs_future_combinators.Infix_result_monad in
        Githubc2_abb.call
          client
          Githubc2_repos.Create_commit_status.(
            make
              ~body:Request_body.(make Primary.(make ?context ~description ~state ~target_url ()))
              Parameters.(make ~owner ~repo ~sha))
        >>= fun _ -> Abb.Future.return (Ok ()))
      creates
end
