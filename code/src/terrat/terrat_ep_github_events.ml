module Http = Cohttp_abb.Make (Abb)
module Process = Abb_process.Make (Abb)

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

  let update_service_discovery =
    Pgsql_io.Typed_sql.(
      sql
      /^ read_sql "update_service_discovery.sql"
      /% Var.bigint "installation_id"
      /% Var.(option (varchar "service_discovery_id")))

  let select_service_discovery =
    Pgsql_io.Typed_sql.(
      sql
      // (* service_discovery_id *) Ret.(option varchar)
      /^ read_sql "select_service_discovery.sql"
      /% Var.bigint "installation_id")
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

  module Service_discovery = struct
    module List_namespaces = struct
      type namespace = {
        id : string; [@key "Id"]
        arn : string; [@key "Arn"]
        name : string; [@key "Name"]
      }
      [@@deriving yojson { strict = false }]

      type output = { namespaces : namespace list [@key "Namespaces"] }
      [@@deriving yojson { strict = false }]
    end

    module Create_service = struct
      type service = {
        id : string; [@key "Id"]
        arn : string; [@key "Arn"]
      }
      [@@deriving yojson { strict = false }]

      type output = { service : service [@key "Service"] } [@@deriving yojson { strict = false }]
    end
  end

  let send_email region installation_id =
    let args =
      Abb_process.args
        "aws"
        [
          "--region";
          region;
          "ses";
          "send-email";
          "--to";
          "alerts@terrateam.io";
          "--from";
          "alerts@terrateam.io";
          "--subject";
          Printf.sprintf "New Installation: %Ld" installation_id;
          "--text";
          Int64.to_string installation_id;
        ]
    in
    Process.check_output args
end

module Aws = struct
  let make_arn prefix account_id postfix = Printf.sprintf "%s:%s:%s" prefix account_id postfix
end

let run_with_json_output decoder args =
  let open Abbs_future_combinators.Infix_result_monad in
  Process.check_output args
  >>= fun (stdout, _) ->
  try
    let json = Yojson.Safe.from_string stdout in
    match decoder json with
    | Ok obj -> Abb.Future.return (Ok obj)
    | Error err -> Abb.Future.return (Error (`Json_error (args, stdout, err)))
  with Yojson.Json_error err -> Abb.Future.return (Error (`Json_error (args, stdout, err)))

let aws_create_installation
    aws_account_id
    region
    backend_address
    atlantis_syslog_address
    github_app_id
    installation_id
    org_name
    private_key
    installation_secret
    run_id =
  let open Abbs_future_combinators.Infix_result_monad in
  let args = Abb_process.args "aws" [ "--region"; region; "servicediscovery"; "list-namespaces" ] in
  run_with_json_output Aws_cli.Service_discovery.List_namespaces.output_of_yojson args
  >>= fun sd_namespaces ->
  let namespace_id =
    CCList.(
      hd
      @@ map (fun ns -> ns.Aws_cli.Service_discovery.List_namespaces.id)
      @@ filter
           (fun ns -> ns.Aws_cli.Service_discovery.List_namespaces.name = "terrateam.local")
           sd_namespaces.Aws_cli.Service_discovery.List_namespaces.namespaces)
  in
  let service_name = Printf.sprintf "atlantis-%Ld" installation_id in
  let args =
    Abb_process.args
      "aws"
      [
        "--region";
        region;
        "servicediscovery";
        "create-service";
        "--name";
        service_name;
        "--namespace-id";
        namespace_id;
        "--dns-config";
        Printf.sprintf
          "NamespaceId=%s,RoutingPolicy=MULTIVALUE,DnsRecords=[{Type=SRV,TTL=10}]"
          namespace_id;
      ]
  in
  run_with_json_output Aws_cli.Service_discovery.Create_service.output_of_yojson args
  >>= fun sd_create_service ->
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
    Aws.make_arn
      "arn:aws:iam:"
      aws_account_id
      (Printf.sprintf "policy/terrateam-%Ld-atlantis-task-execution" installation_id)
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
                        (Aws.make_arn
                           (Printf.sprintf "arn:aws:ssm:%s" region)
                           aws_account_id
                           (Printf.sprintf
                              "parameter/terrateam/installation/%Ld/private_key"
                              installation_id)) );
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
                      `String
                        (Aws.make_arn
                           (Printf.sprintf "arn:aws:ecr:%s" region)
                           aws_account_id
                           "repository/terrateam-atlantis") );
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
  let ecs_task_role_arn =
    Aws.make_arn "arn:aws:iam:" aws_account_id (Printf.sprintf "role/%s" ecs_task_definition)
  in
  let ecs_execution_role_arn =
    Aws.make_arn
      "arn:aws:iam:"
      aws_account_id
      (Printf.sprintf "role/terrateam-%Ld-atlantis-ecs-task-execution" installation_id)
  in
  let container_definitions =
    Yojson.Safe.to_string
      (`Assoc
        [
          ("name", `String ecs_task_definition);
          ( "image",
            `String
              (Printf.sprintf
                 "%s.dkr.ecr.%s.amazonaws.com/terrateam-atlantis:latest"
                 aws_account_id
                 region) );
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
                  `Assoc
                    (match atlantis_syslog_address with
                    | Some addr -> [ ("syslog-address", `String addr) ]
                    | None -> []) );
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
                  [ ("name", `String "ATLANTIS_GH_HOSTNAME"); ("value", `String backend_address) ];
                `Assoc
                  [
                    ("name", `String "TERRATEAM_BACKEND_ADDRESS"); ("value", `String backend_address);
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
                        (Aws.make_arn
                           (Printf.sprintf "arn:aws:ssm:%s" region)
                           aws_account_id
                           (Printf.sprintf
                              "parameter/terrateam/installation/%Ld/private_key"
                              installation_id)) );
                  ];
                `Assoc
                  [
                    ("name", `String "ATLANTIS_GH_APP_KEY");
                    ( "valueFrom",
                      `String
                        (Aws.make_arn
                           (Printf.sprintf "arn:aws:ssm:%s" region)
                           aws_account_id
                           (Printf.sprintf
                              "parameter/terrateam/installation/%Ld/private_key"
                              installation_id)) );
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
  let sd_service_arn = Aws_cli.Service_discovery.Create_service.(sd_create_service.service.arn) in
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
        "--service-registries";
        Printf.sprintf
          "registryArn=%s,containerName=%s,containerPort=8080"
          sd_service_arn
          ecs_task_definition;
      ]
  in
  Process.check_output args
  >>= fun _ ->
  let service_discovery_id =
    Aws_cli.Service_discovery.Create_service.(sd_create_service.service.id)
  in
  Abb.Future.return (Ok service_discovery_id)

let aws_destroy_installation aws_account_id region installation_id service_discovery_id =
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
  (match service_discovery_id with
  | Some service_discovery_id ->
      let args =
        Abb_process.args
          "aws"
          [ "--region"; region; "servicediscovery"; "delete-service"; "--id"; service_discovery_id ]
      in
      Abbs_future_combinators.retry_times
        ~times:10
        ~on_failure:(fun _ ->
          Logs.info (fun m -> m "Delete service failed, retrying");
          Abb.Sys.sleep 20.0)
        (fun () ->
          Logs.info (fun m -> m "Deleting services");
          Process.check_output args)
      >>= fun _ -> Abb.Future.return (Ok ())
  | None -> Abb.Future.return (Ok ()))
  >>= fun () ->
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
    Aws.make_arn
      "arn:aws:iam:"
      aws_account_id
      (Printf.sprintf "policy/terrateam-%Ld-atlantis-task-execution" installation_id)
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
      | [] -> Abb.Future.return (Error `No_run_ids_available)
      | run_id :: _ ->
          Pgsql_io.Prepared_stmt.execute db Sql.insert_installation_run_id run_id inst_id
          >>= fun () -> Abb.Future.return (Ok run_id))
  >>= function
  | Ok run_id -> Abb.Future.return (Ok run_id)
  | Error `No_run_ids_available -> Abb.Future.return (Error `No_run_ids_available)
  | Error (`Integrity_err _) -> Abb.Sys.sleep 1.0 >>= fun () -> acquire_run_id db inst_id
  | Error (#Pgsql_io.err as err) -> Abb.Future.return (Error err)

let process_installation config storage =
  let open Abbs_future_combinators.Infix_result_monad in
  let module Gwei = Githubc_webhook.Event.Installation in
  let module Inst = Githubc_v3.Response.Installation in
  let module R = Githubc_v3.Response in
  let module Repo = Githubc_webhook.Repo in
  function
  | Gwei.{ action = `Created; repos; installation } ->
      let installation_id = Inst.id installation in
      Logs.info (fun m -> m "GITHUB_EVENT : INSTALLATION : %Ld : CREATING" installation_id);
      let priv_key = Mirage_crypto_pk.Rsa.generate ~bits:2048 () in
      let pub_key = Mirage_crypto_pk.Rsa.pub_of_priv priv_key in
      let priv_key_pem = Cstruct.to_string (X509.Private_key.encode_pem (`RSA priv_key)) in
      let pub_key_pem = Cstruct.to_string (X509.Public_key.encode_pem (`RSA pub_key)) in
      let installation_secret = Uuidm.create `V4 in
      Logs.debug (fun m ->
          m "GITHUB_EVENT : INSTALLATION : %Ld : ADDING_TO_DATABASE" installation_id);
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.tx db ~f:(fun () ->
              Pgsql_io.Prepared_stmt.execute
                db
                Sql.insert_installation
                (Uri.to_string (Inst.access_tokens_url installation))
                (Inst.created_at installation)
                (Uri.to_string (Inst.html_url installation))
                installation_id
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
                    installation_id
                    (Repo.name repo)
                    (Repo.node_id repo)
                    (Repo.private_ repo)
                    (Uri.to_string url))
                repos)
          >>= fun repo_urls ->
          Logs.debug (fun m ->
              m "GITHUB_EVENT : INSTALLATION : %Ld : ACQUIRING_RUN_ID" installation_id);
          acquire_run_id db installation_id
          >>= fun run_id ->
          Logs.debug (fun m ->
              m "GITHUB_EVENT : INSTALLATION : %Ld : ACQUIRED_RUN_ID : %d" installation_id run_id);
          Abb.Future.return (Ok (repo_urls, run_id)))
      >>= fun (repo_urls, run_id) ->
      Logs.debug (fun m ->
          m "GITHUB_EVENT : INSTALLATION : %Ld : ADDED_TO_DATABASE" installation_id);
      Logs.debug (fun m -> m "GITHUB_EVENT : INSTALLATION : %Ld : AWS_START" installation_id);
      aws_create_installation
        (Terrat_config.aws_account_id config)
        (Terrat_config.aws_region config)
        (Terrat_config.backend_address config)
        (Terrat_config.atlantis_syslog_address config)
        (Terrat_config.github_app_id config)
        installation_id
        (R.User.login (Inst.account installation))
        priv_key_pem
        installation_secret
        run_id
      >>= fun service_discovery_id ->
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.execute
            db
            Sql.update_service_discovery
            installation_id
            (Some service_discovery_id))
      >>= fun () ->
      Logs.debug (fun m -> m "GITHUB_EVENT : INSTALLATION : %Ld : AWS_COMPLETE" installation_id);
      Abbs_future_combinators.(
        to_result (ignore (Aws_cli.send_email (Terrat_config.aws_region config) installation_id)))
      >>= fun () -> Abb.Future.return (Ok ())
  | Gwei.{ action = `Deleted; installation } ->
      let installation_id = Inst.id installation in
      Logs.info (fun m -> m "GITHUB_EVENT : INSTALLATION : %Ld : DELETING" installation_id);
      Pgsql_pool.with_conn storage ~f:(fun db ->
          Pgsql_io.Prepared_stmt.fetch db Sql.select_service_discovery ~f:CCFun.id installation_id
          >>= function
          | [] -> Abb.Future.return (Ok None)
          | service_discover_id :: _ -> Abb.Future.return (Ok service_discover_id))
      >>= fun service_discovery_id ->
      aws_destroy_installation
        (Terrat_config.aws_account_id config)
        (Terrat_config.aws_region config)
        installation_id
        service_discovery_id
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

let proxy_event config storage dns req_headers req_body event =
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
  Terrat_dns.srv dns (Inst.id installation)
  >>= fun (host, port) ->
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.fetch
        db
        Sql.select_installation_secret
        ~f:CCFun.id
        (Inst.id installation))
  >>= function
  | secret :: _ ->
      let computed_sig = compute_signature (Uuidm.to_string secret) req_body in
      let endpoint = Uri.make ~scheme:"http" ~host ~port ~path:"/events" () in
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
  | [] -> assert false

let post config storage dns ctx =
  let open Abb.Future.Infix_monad in
  let request = Brtl_ctx.request ctx in
  let headers = Brtl_ctx.Request.headers request in
  let body = Brtl_ctx.body ctx in
  (* Background all webhook handling because it can take longer than github is
     going to wait for us *)
  Abb.Future.fork
    (match
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
            Logs.info (fun m -> m "GITHUB_EVENT : INSTALLATION : %Ld : SUCCESS" (Inst.id inst));
            Abb.Future.return ()
        | Error (`Run_error (args, stdout, stderr, _)) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVENT : INSTALLATION : FAILED : %s"
                  (CCString.concat " " args.Abb_intf.Process.args));
            Logs.err (fun m ->
                m "GITHUB_EVENT : INSTALLATION : %Ld : FAILED : %s" (Inst.id inst) stdout);
            Logs.err (fun m ->
                m "GITHUB_EVENT : INSTALLATION : %Ld : FAILED : %s" (Inst.id inst) stderr);
            Abb.Future.return ()
        | Error (#Abb_process.check_output_err as err) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVENT : INSTALLATION : %Ld : FAILED : %s"
                  (Inst.id inst)
                  (Abb_process.show_check_output_err err));
            Abb.Future.return ()
        | Error `No_run_ids_available ->
            Logs.err (fun m ->
                m "GITHUB_EVENT : INSTALLATION : %Ld : FAILED : NO_AVAILABLE_RUN_ID" (Inst.id inst));
            Abb.Future.return ()
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVENT : INSTALLATION : %Ld : FAILED : %s"
                  (Inst.id inst)
                  (Pgsql_pool.show_err err));
            Abb.Future.return ()
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVENT : INSTALLATION : %Ld : FAILED : %s"
                  (Inst.id inst)
                  (Pgsql_io.show_err err));
            Abb.Future.return ()
        | Error (`Json_error (args, stdout, err)) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVENT : INSTALLATION : FAILED : JSON : %s : %s : %s"
                  (Abb_intf.Process.show args)
                  stdout
                  err);
            Abb.Future.return ())
    | Ok Githubc_webhook.{ payload = `Installation_repositories installation_repositories; _ } -> (
        process_installation_repositories config storage installation_repositories
        >>= function
        | Ok _ -> Abb.Future.return ()
        | Error (`Run_error (args, stdout, stderr, _)) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVENT : INSTALLATION_REPOSITORY : FAILED : %s"
                  (CCString.concat " " args.Abb_intf.Process.args));
            Logs.err (fun m -> m "GITHUB_EVENT : INSTALLATION_REPOSITORY : FAILED : %s" stdout);
            Logs.err (fun m -> m "GITHUB_EVENT : INSTALLATION_REPOSITORY : FAILED : %s" stderr);
            Abb.Future.return ()
        | Error _ -> Abb.Future.return ())
    | Ok
        (Githubc_webhook.
           { payload = `Issue_comment _ | `Pull_request _ | `Pull_request_review _ | `Push _; _ } as
        event) -> (
        proxy_event config storage dns headers body event
        >>= function
        | Ok _ -> Abb.Future.return ()
        | Error `Dns_error ->
            Logs.err (fun m -> m "GITHUB_EVENT : PROXY : FAILED : DNS");
            Abb.Future.return ()
        | Error (#Cohttp_abb.request_err as err) ->
            Logs.err (fun m ->
                m "GITHUB_EVENT : PROXY : FAILED : HTTP : %s" (Cohttp_abb.show_request_err err));
            Logs.err (fun m -> m "%s" Githubc_webhook.(show Payload.pp event));
            Abb.Future.return ()
        | Error (#Pgsql_pool.err as err) ->
            Logs.err (fun m -> m "GITHUB_EVENT : PROXY : ERROR : DB : %s" (Pgsql_pool.show_err err));
            Abb.Future.return ()
        | Error (#Pgsql_io.err as err) ->
            Logs.err (fun m -> m "GITHUB_EVENT : PROXY : ERROR : DB : %s" (Pgsql_io.show_err err));
            Abb.Future.return ()
        | Error (`Json_error (args, stdout, err)) ->
            Logs.err (fun m ->
                m
                  "GITHUB_EVENT : PROXY : FAILED : JSON : %s : %s : %s"
                  (Abb_intf.Process.show args)
                  stdout
                  err);
            Logs.err (fun m -> m "%s" Githubc_webhook.(show Payload.pp event));
            Abb.Future.return ())
    | Ok Githubc_webhook.{ payload = `Unknown ((("create" | "check_suite") as event_name), _); _ }
      ->
        Logs.info (fun m -> m "GITHUB_EVENT : IGNORE_EVENT : %s" event_name);
        Abb.Future.return ()
    | Ok event ->
        Logs.info (fun m -> m "%s" Githubc_webhook.(show Payload.pp event));
        Abb.Future.return ()
    | Error (#Githubc_webhook.err as err) ->
        Logs.warn (fun m -> m "GITHUB_EVENT : ERROR : %s" (Githubc_webhook.show_err err));
        Abb.Future.return ())
  >>= fun _ -> Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK "") ctx)
