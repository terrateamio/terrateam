module Config : sig
  type t = {
    enabled : bool;
    endpoint : string;
  }

  val from_env : unit -> t
end

module Event : sig
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

  val to_json : t -> Yojson.Safe.t
end

val send : Config.t -> Event.t -> (unit, [> `Msg of string ]) result Abb.Future.t