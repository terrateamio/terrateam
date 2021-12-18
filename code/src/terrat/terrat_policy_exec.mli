(* (\** Specifies the desired state of the system.  That is to say: these are
 *    necessarily imperative operations.  For example, the [Debug] value will
 *    always perform debug output, but the [Installation_create] state says that
 *    the desired state of the system is that installation is created.  If the
 *    installation already exists, then no operation is performed.
 *    [Github_action_run] is the similar: it specifies that we would like a
 *    workflow run against the specified reference, and if a run for that reference
 *    exists then we don't need to do anything (unless the workflow run is being
 *    forced). *\)
 * type t =
 *   | Debug of string
 *   | Comment of {
 *       installation_id : int;
 *       owner : string;
 *       repo : string;
 *       pull_number : int;
 *       msg : string;
 *     }
 *   | Installation_create of Githubc2_webhooks.Installation.t
 *   | Github_action_run of Terrat_github_action_runner.t
 * 
 * val run :
 *   config:Terrat_config.t -> storage:Terrat_storage.t -> token:string -> t list -> unit Abb.Future.t *)
