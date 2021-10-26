module Http = Cohttp_abb.Make (Abb)
module Process = Abb_process.Make (Abb)

let region = "us-west-2"

let ecs_cluster = "terrateam-atlantis"

let terrateam_host = "https://app.terrateam.io/"

module Sql = struct
  let read_sql fname = CCOpt.get_exn_or fname (Terrat_files_github.read fname)

  let insert_installation =
    Pgsql_io.Typed_sql.(
      sql
      /^ read_sql "insert_installation.sql"
      /% Var.varchar "access_tokens_url"
      /% Var.timestamptz "created_at"
      /% Var.varchar "html_url"
      /% Var.bigint "id"
      /% Var.varchar "login"
      /% Var.(option (timestamptz "suspended_at"))
      /% Var.varchar "target_type"
      /% Var.timestamptz "updated_at"
      /% Var.varchar "login_url"
      /% Var.varchar "pub_key"
      /% Var.uuid "secret")

  let insert_installation_repository =
    Pgsql_io.Typed_sql.(
      sql
      /^ read_sql "insert_installation_repository.sql"
      /% Var.varchar "full_name"
      /% Var.bigint "id"
      /% Var.bigint "installation_id"
      /% Var.varchar "name"
      /% Var.varchar "node_id"
      /% Var.boolean "private"
      /% Var.varchar "url")

  let delete_installation_repository =
    Pgsql_io.Typed_sql.(
      sql
      /^ read_sql "delete_installation_repository.sql"
      /% Var.bigint "id"
      /% Var.bigint "installation_id")

  let delete_installation =
    Pgsql_io.Typed_sql.(sql /^ read_sql "delete_installation.sql" /% Var.bigint "id")

  let delete_installation_repositories =
    Pgsql_io.Typed_sql.(sql /^ read_sql "delete_installation_repositories.sql" /% Var.bigint "id")

  let delete_user_installations =
    Pgsql_io.Typed_sql.(
      sql /^ read_sql "delete_user_installations.sql" /% Var.bigint "installation_id")

  let delete_installation_config =
    Pgsql_io.Typed_sql.(
      sql /^ read_sql "delete_installation_config.sql" /% Var.bigint "installation_id")

  let delete_installation_env_vars =
    Pgsql_io.Typed_sql.(
      sql /^ read_sql "delete_installation_env_vars.sql" /% Var.bigint "installation_id")

  let delete_installation_feedback =
    Pgsql_io.Typed_sql.(
      sql /^ read_sql "delete_installation_feedback.sql" /% Var.bigint "installation_id")

  let select_installation_secret =
    Pgsql_io.Typed_sql.(
      sql
      // (* secret *) Ret.uuid
      /^ read_sql "select_installation_secret.sql"
      /% Var.bigint "installation_id")

  let select_next_installation_run_id =
    Pgsql_io.Typed_sql.(
      sql
      // (* run id *) Ret.smallint
      /^ read_sql "select_next_installation_run_id.sql"
      /% Var.integer "min"
      /% Var.integer "max")

  let insert_installation_run_id =
    Pgsql_io.Typed_sql.(
      sql
      /^ read_sql "insert_installation_run_id.sql"
      /% Var.smallint "id"
      /% Var.bigint "installation_id")

  let delete_installation_run_id =
    Pgsql_io.Typed_sql.(
      sql /^ read_sql "delete_installation_run_id.sql" /% Var.bigint "installation_id")
end

let max_run_id = Int32.of_int 1000

module Aws_cli = struct
  module Ecs = struct
    module List_tasks = struct
      type output = { task_arns : string list [@key "taskArns"] }
      [@@deriving yojson { strict = false }]
    end

    module Describe_tasks = struct
      type network_binding = { host_port : int [@key "hostPort"] }
      [@@deriving yojson { strict = false }]

      type container = {
        name : string;
        network_bindings : network_binding list; [@key "networkBindings"]
      }
      [@@deriving yojson { strict = false }]

      type task = {
        containers : container list;
        container_inst_arn : string; [@key "containerInstanceArn"]
      }
      [@@deriving yojson { strict = false }]

      type output = { tasks : task list } [@@deriving yojson { strict = false }]
    end

    module Describe_container_instances = struct
      type container = { ec2_instance_id : string [@key "ec2InstanceId"] }
      [@@deriving yojson { strict = false }]

      type output = { containers : container list [@key "containerInstances"] }
      [@@deriving yojson { strict = false }]
    end
  end

  module Ec2 = struct
    module Describe_instances = struct
      type instance = { private_ip_address : string [@key "PrivateIpAddress"] }
      [@@deriving yojson { strict = false }]

      type reservation = { instances : instance list [@key "Instances"] }
      [@@deriving yojson { strict = false }]

      type output = { reservations : reservation list [@key "Reservations"] }
      [@@deriving yojson { strict = false }]
    end
  end
end

let run_with_json_output decoder args =
  let open Abbs_future_combinators.Infix_result_monad in
  Process.check_output args
  >>= fun (stdout, _) ->
  try
    let json = Yojson.Safe.from_string stdout in
    match decoder json with
      | Ok obj    -> Abb.Future.return (Ok obj)
      | Error err -> Abb.Future.return (Error (`Json_error (args, stdout, err)))
  with Yojson.Json_error err -> Abb.Future.return (Error (`Json_error (args, stdout, err)))

let aws_create_installation
    github_app_id
    installation_id
    org_name
    private_key
    installation_secret
    run_id =
  let open Abbs_future_combinators.Infix_result_monad in
  let ecs_task_role_name = Printf.sprintf "terrateam-%Ld-atlantis" installation_id in
  let assume_role_policy_document =
    Yojson.Safe.to_string
      (`Assoc
        [
          ("Version", `String "2012-10-17");
          ( "Statement",
            `List
              [
                `Assoc
                  [
                    ("Sid", `String "");
                    ("Effect", `String "Allow");
                    ("Action", `String "sts:AssumeRole");
                    ("Principal", `Assoc [ ("Service", `String "ecs-tasks.amazonaws.com") ]);
                  ];
              ] );
        ])
  in
  let args =
    Abb_process.args
      "aws"
      [
        "iam";
        "create-role";
        "--path";
        "/";
        "--role-name";
        ecs_task_role_name;
        "--assume-role-policy-document";
        assume_role_policy_document;
        "--description";
        ecs_task_role_name;
      ]
  in
  Process.check_output args
  >>= fun _ ->
  let atlantis_ecs_task_exec_role_name =
    Printf.sprintf "terrateam-%Ld-atlantis-ecs-task-execution" installation_id
  in
  let atlantis_ecs_task_exec_role =
    Yojson.Safe.to_string
      (`Assoc
        [
          ("Version", `String "2012-10-17");
          ( "Statement",
            `List
              [
                `Assoc
                  [
                    ("Sid", `String "");
                    ("Effect", `String "Allow");
                    ("Principal", `Assoc [ ("Service", `String "ecs-tasks.amazonaws.com") ]);
                    ("Action", `String "sts:AssumeRole");
                  ];
              ] );
        ])
  in
  let args =
    Abb_process.args
      "aws"
      [
        "iam";
        "create-role";
        "--role-name";
        atlantis_ecs_task_exec_role_name;
        "--assume-role-policy-document";
        atlantis_ecs_task_exec_role;
      ]
  in
  Process.check_output args
  >>= fun _ ->
  let atlantis_task_exec_policy_name =
    Printf.sprintf "terrateam-%Ld-atlantis-task-execution" installation_id
  in
  let atlantis_task_exec_policy_arn =
    Printf.sprintf
      "arn:aws:iam::654862118936:policy/terrateam-%Ld-atlantis-task-execution"
      installation_id
  in
  let atlantis_task_exec_policy =
    Yojson.Safe.to_string
      (`Assoc
        [
          ("Version", `String "2012-10-17");
          ( "Statement",
            `List
              [
                `Assoc
                  [
                    ("Action", `List [ `String "ssm:GetParameters" ]);
                    ("Effect", `String "Allow");
                    ( "Resource",
                      `String
                        (Printf.sprintf
                           "arn:aws:ssm:us-west-2:654862118936:parameter/terrateam/installation/%Ld/private_key"
                           installation_id) );
                  ];
                `Assoc
                  [
                    ( "Action",
                      `List
                        [
                          `String "ecr:BatchCheckLayerAvailability";
                          `String "ecr:GetDownloadUrlForLayer";
                          `String "ecr:BatchGetImage";
                        ] );
                    ("Effect", `String "Allow");
                    ( "Resource",
                      `String "arn:aws:ecr:us-west-2:654862118936:repository/terrateam-atlantis" );
                  ];
                `Assoc
                  [
                    ("Action", `List [ `String "ecr:GetAuthorizationToken" ]);
                    ("Effect", `String "Allow");
                    ("Resource", `String "*");
                  ];
              ] );
        ])
  in
  let args =
    Abb_process.args
      "aws"
      [
        "iam";
        "create-policy";
        "--policy-name";
        atlantis_task_exec_policy_name;
        "--policy-document";
        atlantis_task_exec_policy;
      ]
  in
  Process.check_output args
  >>= fun _ ->
  let args =
    Abb_process.args
      "aws"
      [
        "iam";
        "attach-role-policy";
        "--policy-arn";
        atlantis_task_exec_policy_arn;
        "--role-name";
        atlantis_ecs_task_exec_role_name;
      ]
  in
  Process.check_output args
  >>= fun _ ->
  Abbs_future_combinators.to_result (Abb.Sys.sleep 15.0)
  >>= fun () ->
  let ecs_task_definition = Printf.sprintf "terrateam-%Ld-atlantis" installation_id in
  let ecs_task_role_arn = Printf.sprintf "arn:aws:iam::654862118936:role/%s" ecs_task_definition in
  let ecs_execution_role_arn =
    Printf.sprintf
      "arn:aws:iam::654862118936:role/terrateam-%Ld-atlantis-ecs-task-execution"
      installation_id
  in
  let container_definitions =
    Yojson.Safe.to_string
      (`Assoc
        [
          ("name", `String ecs_task_definition);
          ("image", `String "654862118936.dkr.ecr.us-west-2.amazonaws.com/terrateam-atlantis:latest");
          ("cpu", `Int 64);
          ("memory", `Int 512);
          ("memoryReservation", `Int 32);
          ("user", `String (Printf.sprintf "tt_%d:tt_%d" run_id run_id));
          ( "portMappings",
            `List
              [
                `Assoc
                  [
                    ("containerPort", `Int 8080); ("hostPort", `Int 0); ("protocol", `String "tcp");
                  ];
              ] );
          ("essential", `Bool true);
          ( "logConfiguration",
            `Assoc
              [
                ("logDriver", `String "syslog");
                ( "options",
                  `Assoc [ ("syslog-address", `String "udp://logs6.papertrailapp.com:39309") ] );
              ] );
          ( "environment",
            `List
              [
                `Assoc [ ("name", `String "ATLANTIS_GH_ORG"); ("value", `String org_name) ];
                `Assoc
                  [ ("name", `String "ATLANTIS_ATLANTIS_HOST"); ("value", `String terrateam_host) ];
                `Assoc [ ("name", `String "ATLANTIS_LOG_LEVEL"); ("value", `String "debug") ];
                `Assoc [ ("name", `String "ATLANTIS_WRITE_GIT_CREDS"); ("value", `String "true") ];
                `Assoc
                  [
                    ("name", `String "ATLANTIS_GH_APP_ID");
                    ("value", `String (Int64.to_string installation_id));
                  ];
                `Assoc [ ("name", `String "ATLANTIS_REPO_ALLOWLIST"); ("value", `String "*") ];
                `Assoc
                  [
                    ("name", `String "ATLANTIS_GH_HOSTNAME");
                    ("value", `String "app.terrateam.io:8081");
                  ];
              ] );
          ( "secrets",
            `List
              [
                `Assoc
                  [
                    ("name", `String "TERRATEAM_PRIVATE_KEY");
                    ( "valueFrom",
                      `String
                        (Printf.sprintf
                           "arn:aws:ssm:us-west-2:654862118936:parameter/terrateam/installation/%Ld/private_key"
                           installation_id) );
                  ];
                `Assoc
                  [
                    ("name", `String "ATLANTIS_GH_APP_KEY");
                    ( "valueFrom",
                      `String
                        (Printf.sprintf
                           "arn:aws:ssm:us-west-2:654862118936:parameter/terrateam/installation/%Ld/private_key"
                           installation_id) );
                  ];
              ] );
        ])
  in
  let args =
    Abb_process.args
      "aws"
      [
        "--region";
        region;
        "ecs";
        "register-task-definition";
        "--family";
        ecs_task_definition;
        "--task-role-arn";
        ecs_task_role_arn;
        "--execution-role-arn";
        ecs_execution_role_arn;
        "--container-definitions";
        container_definitions;
      ]
  in
  Process.check_output args
  >>= fun _ ->
  let args =
    Abb_process.args
      "aws"
      [
        "--region";
        region;
        "ssm";
        "put-parameter";
        "--name";
        Printf.sprintf "/terrateam/installation/%Ld/private_key" installation_id;
        "--type";
        "SecureString";
        "--value";
        private_key;
      ]
  in
  Process.check_output args
  >>= fun _ ->
  let ecs_service_name = Printf.sprintf "terrateam-%Ld-atlantis" installation_id in
  let deployment_configuration =
    Yojson.Safe.to_string
      (`Assoc [ ("maximumPercent", `Int 100); ("minimumHealthyPercent", `Int 0) ])
  in
  let placement_strategy =
    Yojson.Safe.to_string (`Assoc [ ("type", `String "spread"); ("field", `String "instanceId") ])
  in
  let args =
    Abb_process.args
      "aws"
      [
        "--region";
        region;
        "ecs";
        "create-service";
        "--cluster";
        ecs_cluster;
        "--service-name";
        ecs_service_name;
        "--task-definition";
        ecs_task_definition;
        "--desired-count";
        "1";
        "--deployment-configuration";
        deployment_configuration;
        "--placement-strategy";
        placement_strategy;
      ]
  in
  Process.check_output args >>= fun _ -> Abb.Future.return (Ok ())

let aws_destroy_installation installation_id =
  let open Abbs_future_combinators.Infix_result_monad in
  let ecs_service_name = Printf.sprintf "terrateam-%Ld-atlantis" installation_id in
  let ecs_task_role_name = Printf.sprintf "terrateam-%Ld-atlantis" installation_id in
  let args =
    Abb_process.args
      "aws"
      [
        "--region";
        region;
        "ecs";
        "update-service";
        "--cluster";
        ecs_cluster;
        "--service";
        ecs_service_name;
        "--desired-count";
        "0";
      ]
  in
  Process.check_output args
  >>= fun _ ->
  let args =
    Abb_process.args
      "aws"
      [
        "--region";
        region;
        "ecs";
        "delete-service";
        "--cluster";
        ecs_cluster;
        "--service";
        ecs_service_name;
      ]
  in
  Process.check_output args
  >>= fun _ ->
  let args =
    Abb_process.args
      "aws"
      [
        "--region";
        region;
        "ssm";
        "delete-parameter";
        "--name";
        Printf.sprintf "/terrateam/installation/%Ld/private_key" installation_id;
      ]
  in
  Process.check_output args
  >>= fun _ ->
  let atlantis_task_exec_policy_name =
    Printf.sprintf "terrateam-%Ld-atlantis-ecs-task-execution" installation_id
  in
  let atlantis_task_exec_policy_arn =
    Printf.sprintf
      "arn:aws:iam::654862118936:policy/terrateam-%Ld-atlantis-task-execution"
      installation_id
  in
  let args =
    Abb_process.args
      "aws"
      [
        "iam";
        "detach-role-policy";
        "--role-name";
        atlantis_task_exec_policy_name;
        "--policy-arn";
        atlantis_task_exec_policy_arn;
      ]
  in
  Process.check_output args
  >>= fun _ ->
  let args =
    Abb_process.args "aws" [ "iam"; "delete-policy"; "--policy-arn"; atlantis_task_exec_policy_arn ]
  in
  Process.check_output args
  >>= fun _ ->
  let args =
    Abb_process.args "aws" [ "iam"; "delete-role"; "--role-name"; atlantis_task_exec_policy_name ]
  in
  Process.check_output args
  >>= fun _ ->
  let args = Abb_process.args "aws" [ "iam"; "delete-role"; "--role-name"; ecs_task_role_name ] in
  Process.check_output args >>= fun _ -> Abb.Future.return (Ok ())

let rec acquire_run_id db inst_id =
  let open Abb.Future.Infix_monad in
  Pgsql_io.tx db ~f:(fun () ->
      let open Abbs_future_combinators.Infix_result_monad in
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_next_installation_run_id
        ~f:CCFun.id
        Int32.zero
        max_run_id
      >>= function
      | []          -> Abb.Future.return (Error `No_run_ids_available)
      | run_id :: _ ->
          Pgsql_io.Prepared_stmt.execute db Sql.insert_installation_run_id run_id inst_id
          >>= fun () -> Abb.Future.return (Ok run_id))
  >>= function
  | Ok run_id                    -> Abb.Future.return (Ok run_id)
  | Error `No_run_ids_available  -> Abb.Future.return (Error `No_run_ids_available)
  | Error (`Integrity_err _)     -> Abb.Sys.sleep 1.0 >>= fun () -> acquire_run_id db inst_id
  | Error (#Pgsql_io.err as err) -> Abb.Future.return (Error err)

let process_installation config storage =
  let open Abbs_future_combinators.Infix_result_monad in
  let module Gwei = Githubc_webhook.Event.Installation in
  let module Inst = Githubc_v3.Response.Installation in
  let module R = Githubc_v3.Response in
  let module Repo = Githubc_webhook.Repo in
  function
  | Gwei.{ action = `Created; repos; installation } ->
      let priv_key = Mirage_crypto_pk.Rsa.generate ~bits:2048 () in
      let pub_key = Mirage_crypto_pk.Rsa.pub_of_priv priv_key in
      let priv_key_pem = Cstruct.to_string (X509.Private_key.encode_pem (`RSA priv_key)) in
      let pub_key_pem = Cstruct.to_string (X509.Public_key.encode_pem (`RSA pub_key)) in
      let installation_secret = Uuidm.create `V4 in
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              Pgsql_io.Prepared_stmt.execute
                db
                Sql.insert_installation
                (Uri.to_string (Inst.access_tokens_url installation))
                (Inst.created_at installation)
                (Uri.to_string (Inst.html_url installation))
                (Inst.id installation)
                (R.User.login (Inst.account installation))
                (Inst.suspended_at installation)
                (Inst.target_type installation)
                (Inst.updated_at installation)
                (Uri.to_string (R.User.url (Inst.account installation)))
                pub_key_pem
                installation_secret
              >>= fun () ->
              Abbs_future_combinators.List_result.iter
                ~f:(fun repo ->
                  let base_url = R.User.html_url (Inst.account installation) in
                  let path = Uri.path base_url ^ "/" ^ Repo.name repo in
                  let url = Uri.with_path base_url path in
                  Pgsql_io.Prepared_stmt.execute
                    db
                    Sql.insert_installation_repository
                    (Repo.full_name repo)
                    (Repo.id repo)
                    (Inst.id installation)
                    (Repo.name repo)
                    (Repo.node_id repo)
                    (Repo.private_ repo)
                    (Uri.to_string url))
                repos)
          >>= fun repo_urls ->
          acquire_run_id db (Inst.id installation)
          >>= fun run_id -> Abb.Future.return (Ok (repo_urls, run_id)))
      >>= fun (repo_urls, run_id) ->
      aws_create_installation
        (Terrat_config.github_app_id config)
        (Inst.id installation)
        (R.User.login (Inst.account installation))
        priv_key_pem
        installation_secret
        run_id
  | Gwei.{ action = `Deleted; installation } ->
      let installation_id = Inst.id installation in
      aws_destroy_installation installation_id
      >>= fun () ->
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              Pgsql_io.Prepared_stmt.execute db Sql.delete_installation_run_id installation_id
              >>= fun () ->
              Pgsql_io.Prepared_stmt.execute db Sql.delete_user_installations installation_id
              >>= fun () ->
              Pgsql_io.Prepared_stmt.execute db Sql.delete_installation_config installation_id
              >>= fun () ->
              Pgsql_io.Prepared_stmt.execute db Sql.delete_installation_env_vars installation_id
              >>= fun () ->
              Pgsql_io.Prepared_stmt.execute db Sql.delete_installation_feedback installation_id
              >>= fun () ->
              Pgsql_io.Prepared_stmt.execute db Sql.delete_installation_repositories installation_id
              >>= fun () ->
              Pgsql_io.Prepared_stmt.execute db Sql.delete_installation installation_id))
  | _ -> failwith "nyi"

let process_installation_repositories config storage =
  let open Abbs_future_combinators.Infix_result_monad in
  let module Inst = Githubc_v3.Response.Installation in
  let module Inst_repo = Githubc_webhook.Event.Installation_repositories in
  let module Repo = Githubc_webhook.Repo in
  let module R = Githubc_v3.Response in
  function
  | Inst_repo.{ repos_added; repos_removed; installation; _ } ->
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              Abbs_future_combinators.List_result.iter
                ~f:(fun repo ->
                  let base_url = R.User.html_url (Inst.account installation) in
                  let path = Uri.path base_url ^ "/" ^ Repo.name repo in
                  let url = Uri.with_path base_url path in
                  Pgsql_io.Prepared_stmt.execute
                    db
                    Sql.insert_installation_repository
                    (Repo.full_name repo)
                    (Repo.id repo)
                    (Inst.id installation)
                    (Repo.name repo)
                    (Repo.node_id repo)
                    (Repo.private_ repo)
                    (Uri.to_string url))
                repos_added
              >>= fun () ->
              Abbs_future_combinators.List_result.iter
                ~f:(fun repo ->
                  Pgsql_io.Prepared_stmt.execute
                    db
                    Sql.delete_installation_repository
                    (Repo.id repo)
                    (Inst.id installation))
                repos_removed))

let compute_signature secret body =
  let computed_sig =
    Cstruct.to_string
      (Mirage_crypto.Hash.SHA256.hmac ~key:(Cstruct.of_string secret) (Cstruct.of_string body))
  in
  let buf = Buffer.create 64 in
  CCString.iter (fun c -> Buffer.add_string buf (Printf.sprintf "%02x" (Char.code c))) computed_sig;
  "sha256=" ^ Buffer.contents buf

let proxy_event config storage req_headers req_body event =
  let open Abbs_future_combinators.Infix_result_monad in
  let module E = Githubc_webhook.Event in
  let module Inst = Githubc_webhook.Installation in
  let installation =
    match event with
      | Githubc_webhook.
          {
            payload =
              ( `Issue_comment E.Issue_comment.{ installation; _ }
              | `Pull_request E.Pull_request.{ installation; _ }
              | `Pull_request_review E.Pull_request_review.{ installation; _ }
              | `Push E.Push.{ installation; _ } );
            _;
          } -> installation
  in
  let ecs_service_name = Printf.sprintf "terrateam-%Ld-atlantis" (Inst.id installation) in
  let args =
    Abb_process.args
      "aws"
      [
        "ecs";
        "list-tasks";
        "--region";
        region;
        "--cluster";
        ecs_cluster;
        "--service-name";
        ecs_service_name;
        "--desired-status";
        "RUNNING";
      ]
  in
  run_with_json_output Aws_cli.Ecs.List_tasks.output_of_yojson args
  >>= fun tasks ->
  let task_arn =
    match CCString.Split.right ~by:"/" (CCList.hd tasks.Aws_cli.Ecs.List_tasks.task_arns) with
      | Some (_, arn) -> arn
      | None          -> assert false
  in
  let args =
    Abb_process.args
      "aws"
      [ "ecs"; "describe-tasks"; "--region"; region; "--cluster"; ecs_cluster; "--tasks"; task_arn ]
  in
  run_with_json_output Aws_cli.Ecs.Describe_tasks.output_of_yojson args
  >>= fun tasks ->
  let atlantis_name = Printf.sprintf "terrateam-%Ld-atlantis" (Inst.id installation) in
  let atlantis_container =
    tasks.Aws_cli.Ecs.Describe_tasks.tasks
    |> CCList.hd
    |> (fun task -> task.Aws_cli.Ecs.Describe_tasks.containers)
    |> CCList.filter (fun c -> CCString.equal atlantis_name c.Aws_cli.Ecs.Describe_tasks.name)
    |> CCList.hd
  in
  let host_port =
    atlantis_container
    |> (fun c -> c.Aws_cli.Ecs.Describe_tasks.network_bindings)
    |> CCList.hd
    |> fun nb -> nb.Aws_cli.Ecs.Describe_tasks.host_port
  in
  let container_inst_arn =
    tasks.Aws_cli.Ecs.Describe_tasks.tasks
    |> CCList.hd
    |> fun c -> c.Aws_cli.Ecs.Describe_tasks.container_inst_arn
  in
  let args =
    Abb_process.args
      "aws"
      [
        "ecs";
        "describe-container-instances";
        "--region";
        region;
        "--cluster";
        ecs_cluster;
        "--container-instances";
        container_inst_arn;
      ]
  in
  run_with_json_output Aws_cli.Ecs.Describe_container_instances.output_of_yojson args
  >>= fun container_instances ->
  let ec2_instance_id =
    container_instances.Aws_cli.Ecs.Describe_container_instances.containers
    |> CCList.hd
    |> fun c -> c.Aws_cli.Ecs.Describe_container_instances.ec2_instance_id
  in
  let args =
    Abb_process.args
      "aws"
      [ "ec2"; "describe-instances"; "--region"; region; "--instance-ids"; ec2_instance_id ]
  in
  run_with_json_output Aws_cli.Ec2.Describe_instances.output_of_yojson args
  >>= fun instance ->
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_installation_secret
        ~f:CCFun.id
        (Inst.id installation))
  >>= function
  | secret :: _ ->
      let computed_sig = compute_signature (Uuidm.to_string secret) req_body in
      let private_ip_addr =
        instance.Aws_cli.Ec2.Describe_instances.reservations
        |> CCList.hd
        |> (fun c -> c.Aws_cli.Ec2.Describe_instances.instances)
        |> CCList.hd
        |> fun inst -> inst.Aws_cli.Ec2.Describe_instances.private_ip_address
      in
      let endpoint =
        Uri.make ~scheme:"http" ~host:private_ip_addr ~port:host_port ~path:"/events" ()
      in
      let headers =
        [
          "content-type";
          "x-github-delivery";
          "x-github-event";
          "x-github-hook-id";
          "x-github-installation-target-id";
          "x-github-hook-installation-target-type";
        ]
        |> CCList.map (fun h -> CCOpt.map (fun v -> (h, v)) (Cohttp.Header.get req_headers h))
        |> CCList.keep_some
        |> Cohttp.Header.of_list
        |> (fun hs -> Cohttp.Header.add hs "x-hub-signature-256" computed_sig)
        |> fun hs -> Cohttp.Header.add hs "x-hub-signature" computed_sig
      in
      Http.Client.call ~headers ~body:(`String req_body) `POST endpoint
  | []          -> assert false

let post config storage ctx =
  let open Abb.Future.Infix_monad in
  let request = Brtl_ctx.request ctx in
  let headers = Brtl_ctx.Request.headers request in
  let body = Brtl_ctx.body ctx in
  match
    Githubc_webhook.decode ?secret:(Terrat_config.github_webhook_secret config) headers body
  with
    | Ok
        Githubc_webhook.
          {
            payload = `Installation (Event.Installation.{ installation = inst; _ } as installation);
            _;
          } -> (
        let module Inst = Githubc_v3.Response.Installation in
        process_installation config storage installation
        >>= function
        | Ok () ->
            Logs.info (fun m -> m "GITHUB_EVENT : INSTALLATION : SUCCESS : %Ld" (Inst.id inst));
            Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
        | Error (`Run_error (args, stdout, stderr, _)) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVENT : INSTALLATION : FAILED : %s"
                  (CCString.concat " " args.Abb_intf.Process.args));
            Logs.err (fun m -> m "GITHUB_EVENT : INSTALLATION : FAILED : %s" stdout);
            Logs.err (fun m -> m "GITHUB_EVENT : INSTALLATION : FAILED : %s" stderr);
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error (#Abb_process.check_output_err as err) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVENT : INSTALLATION : FAILED : %s"
                  (Abb_process.show_check_output_err err));
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error `No_run_ids_available ->
            Logs.err (fun m -> m "GITHUB_EVENT : INSTALLATION : FAILED : NO_AVAILABLE_RUN_ID");
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m "GITHUB_EVENT : INSTALLATION : FAILED : %s" (Pgsql_pool.show_err err));
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m "GITHUB_EVENT : INSTALLATION : FAILED : %s" (Pgsql_io.show_err err));
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
    | Ok Githubc_webhook.{ payload = `Installation_repositories installation_repositories; _ } -> (
        process_installation_repositories config storage installation_repositories
        >>= function
        | Ok _ -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
        | Error (`Run_error (args, stdout, stderr, _)) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVENT : INSTALLATION_REPOSITORY : FAILED : %s"
                  (CCString.concat " " args.Abb_intf.Process.args));
            Logs.err (fun m -> m "GITHUB_EVENT : INSTALLATION_REPOSITORY : FAILED : %s" stdout);
            Logs.err (fun m -> m "GITHUB_EVENT : INSTALLATION_REPOSITORY : FAILED : %s" stderr);
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error _ ->
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
    | Ok
        (Githubc_webhook.
           { payload = `Issue_comment _ | `Pull_request _ | `Pull_request_review _ | `Push _; _ } as
        event) -> (
        proxy_event config storage headers body event
        >>= function
        | Ok _ -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
        | Error (#Abb_process.check_output_err as err) ->
            Logs.err (fun m ->
                m "GITHUB_EVENT : PROXY : FAILED : AWS : %s" (Abb_process.show_check_output_err err));
            Logs.err (fun m -> m "%s" Githubc_webhook.(show Payload.pp event));
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error (#Cohttp_abb.request_err as err) ->
            Logs.err (fun m ->
                m "GITHUB_EVENT : PROXY : FAILED : HTTP : %s" (Cohttp_abb.show_request_err err));
            Logs.err (fun m -> m "%s" Githubc_webhook.(show Payload.pp event));
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m -> m "GITHUB_EVENT : PROXY : ERROR : DB : %s" (Pgsql_pool.show_err err));
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m -> m "GITHUB_EVENT : PROXY : ERROR : DB : %s" (Pgsql_io.show_err err));
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
        | Error (`Json_error (args, stdout, err)) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVENT : PROXY : FAILED : JSON : %s : %s : %s"
                  (Abb_intf.Process.show args)
                  stdout
                  err);
            Logs.err (fun m -> m "%s" Githubc_webhook.(show Payload.pp event));
            Abb.Future.return
              (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
    | Ok Githubc_webhook.{ payload = `Unknown ((("create" | "check_suite") as event_name), _); _ }
      ->
        Logs.info (fun m -> m "GITHUB_EVENT : IGNORE_EVENT : %s" event_name);
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
    | Ok event ->
        Logs.info (fun m -> m "%s" Githubc_webhook.(show Payload.pp event));
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
    | Error (#Githubc_webhook.err as err) ->
        Logs.warn (fun m -> m "GITHUB_EVENT : ERROR : %s" (Githubc_webhook.show_err err));
        Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)
