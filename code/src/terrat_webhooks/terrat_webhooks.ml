module Config = struct
  type t = {
    enabled : bool;
    endpoint : string;
  }

  let from_env () =
    let enabled =
      match Sys.getenv_opt "TERRATEAM_WEBHOOKS_ENABLED" with
      | Some "true" -> true
      | Some "1" -> true
      | _ -> false
    in
    let endpoint =
      CCOption.get_or ~default:"" (Sys.getenv_opt "TERRATEAM_WEBHOOKS_ENDPOINT")
    in
    { enabled; endpoint }
end

module Event = struct
  type github_installation_event = 
    | Created of {
        installation_id : int;
        account : string;
        sender : string;
        target_type : string;
        created_at : string;
      }
    | Deleted of {
        installation_id : int;
        account : string;
        sender : string;
        deleted_at : string;
      }
    | Suspended of {
        installation_id : int;
        account : string;
        sender : string;
        suspended_at : string;
      }
    | Unsuspended of {
        installation_id : int;
        account : string;
        sender : string;
        unsuspended_at : string;
      }

  type t = 
    | GithubInstallation of github_installation_event

  let github_installation_to_json = function
    | Created data ->
        `Assoc [
          ("event_type", `String "github_installation_created");
          ("installation_id", `Int data.installation_id);
          ("account", `String data.account);
          ("sender", `String data.sender);
          ("target_type", `String data.target_type);
          ("created_at", `String data.created_at);
        ]
    | Deleted data ->
        `Assoc [
          ("event_type", `String "github_installation_deleted");
          ("installation_id", `Int data.installation_id);
          ("account", `String data.account);
          ("sender", `String data.sender);
          ("deleted_at", `String data.deleted_at);
        ]
    | Suspended data ->
        `Assoc [
          ("event_type", `String "github_installation_suspended");
          ("installation_id", `Int data.installation_id);
          ("account", `String data.account);
          ("sender", `String data.sender);
          ("suspended_at", `String data.suspended_at);
        ]
    | Unsuspended data ->
        `Assoc [
          ("event_type", `String "github_installation_unsuspended");
          ("installation_id", `Int data.installation_id);
          ("account", `String data.account);
          ("sender", `String data.sender);
          ("unsuspended_at", `String data.unsuspended_at);
        ]

  let to_json = function
    | GithubInstallation event -> github_installation_to_json event
end

let send config event =
  if not config.Config.enabled || config.Config.endpoint = "" then
    Abb.Future.return (Ok ())
  else
    let body = 
      event
      |> Event.to_json
      |> Yojson.Safe.to_string
    in
    let headers = 
      Cohttp.Header.of_list [
        ("Content-Type", "application/json");
        ("User-Agent", "Terrateam/1.0");
      ]
    in
    let uri = Uri.of_string config.Config.endpoint in
    let open Abb.Future.Infix_monad in
    Cohttp_abb.Client.post ~headers ~body:(Cohttp_abb.Body.of_string body) uri
    >>= fun (resp, _body) ->
    let status_code = Cohttp.Code.code_of_status (Cohttp.Response.status resp) in
    if status_code >= 200 && status_code < 300 then (
      Logs.info (fun m -> m "Webhook sent successfully to %s" config.Config.endpoint);
      Abb.Future.return (Ok ())
    ) else (
      Logs.warn (fun m -> 
        m "Failed to send webhook to %s: HTTP %d" config.Config.endpoint status_code);
      Abb.Future.return (Ok ())  (* Don't fail the main operation *)
    )