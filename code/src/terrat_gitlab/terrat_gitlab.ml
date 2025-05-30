module Oauth = struct
  module Http = Abb_curl.Make (Abb)

  type authorize_err =
    [ `Authorize_err of string
    | Http.request_err
    ]
  [@@deriving show]

  type refresh_err =
    [ `Refresh_err of string
    | `Bad_refresh_token
    | Http.request_err
    ]
  [@@deriving show]

  module Response = struct
    type t = {
      access_token : string;
      scope : string;
      token_type : string;
      refresh_token : string option; [@default None]
      refresh_token_expires_in : int option; [@default None]
      expires_in : int option; [@default None]
    }
    [@@deriving of_yojson { strict = false }, show]
  end

  module Response_err = struct
    type t = {
      error : string;
      error_description : string;
    }
    [@@deriving of_yojson { strict = false }, show]
  end

  let authorize ~config code =
    let open Abb.Future.Infix_monad in
    let headers =
      Http.Headers.of_list [ ("user-agent", "Terrateam"); ("content-type", "application/json") ]
    in
    let uri =
      Uri.of_string
        (Printf.sprintf
           "%s/oauth/authorize"
           (Uri.to_string (Terrat_config.Gitlab.web_base_url config)))
    in
    let body =
      Yojson.Safe.to_string
        (`Assoc
           [
             ("client_id", `String (Terrat_config.Github.app_client_id config));
             ("client_secret", `String (Terrat_config.Github.app_client_secret config));
             ("code", `String code);
           ])
    in
    Http.post ~headers ~body uri
    >>| function
    | Ok (resp, body) when Http.Status.is_success (Http.Response.status resp) -> (
        match Response.of_yojson (Yojson.Safe.from_string body) with
        | Ok value -> Ok value
        | Error _ -> Error (`Authorize_err body))
    | Ok (resp, body) -> Error (`Authorize_err body)
    | Error err -> Error err

  let refresh ~config refresh_token =
    let open Abb.Future.Infix_monad in
    let headers =
      Http.Headers.of_list
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
           (Uri.to_string (Terrat_config.Github.web_base_url config)))
    in
    let body =
      Yojson.Safe.to_string
        (`Assoc
           [
             ("client_id", `String (Terrat_config.Github.app_client_id config));
             ("client_secret", `String (Terrat_config.Github.app_client_secret config));
             ("grant_type", `String "refresh_token");
             ("refresh_token", `String refresh_token);
           ])
    in
    Http.post ~headers ~body uri
    >>| function
    | Ok (resp, body) when Http.Status.is_success (Http.Response.status resp) -> (
        match Response.of_yojson (Yojson.Safe.from_string body) with
        | Ok value -> Ok value
        | Error _ -> (
            match Response_err.of_yojson (Yojson.Safe.from_string body) with
            | Ok { Response_err.error = "bad_refresh_token"; _ } -> Error `Bad_refresh_token
            | _ -> Error (`Refresh_err body)))
    | Ok (resp, body) -> Error (`Refresh_err body)
    | Error err -> Error err
end
