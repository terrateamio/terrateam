(** Provides an interface for working with the current state of the stacks modified by a pull
    request. Two interfaces are provided:

    1. HTTP - Provides HTTP endpoints for getting the current state of a stack.

    2. API - Provide API calls for getting the state of the stacks.

    Stacks are hierarchical and can be thought of as having a path, like a file path. A path might
    be [dev -> dev-us-east-1 -> dev-compute], where [dev] contains all of the development stacks,
    [dev-us-east-1] contains all development stacks in [us-east-1] and then [dev-compute] contains
    all dev resources for compute in that region.

    To represent this hierarchy in a consumable way, stacks are represented in three layers:

    1. Outer stack - This is the highest level stack in the hierarchy. For example, if stacks are
    arranged into [base], [prod], [staging], [dev], this outer stack would be each one of those.

    2. Inner stack - Each outer stack contains a list of one or more inner stacks. These correspond
    to the leaf stacks under the outer stack. Inner stack contains its name, as well as any paths to
    that stack, of which there is at least one.

    3. Dirspaces - This is the list of dirspaces associated with an inner stack.

    To use the example above. If we have the stack hierarchy [dev -> dev-us-east-1 -> dev-compute],
    [dev] would be the outer stack, [dev-compute] would be an inner stack, and
    [dev, dev-us-east-1, dev-compute] would be a path listed in the inner stack. Any dirspaces in
    the [dev-compute] stack would be listed as well.

    State - The state of outer and inner stacks are based on the state of the dirspaces they
    contain. The algorithm to compute the state of an outer and inner stack is:

    1. Define the ordering of states, see the [stack_state_ordering] value. Note that "no_changes"
    is not in the list because that is treated specially.

    2. Get the state of all dirspaces under a stack.

    3. Determine the lowest index in the state ordering list of all dirspaces. If the lowest value
    is found, use that, otherwise use "no_changes" if no lowest value was found.

    Ordering - The outer stacks are represented as a list that roughly correspond to the order that
    they will be planned and applied in. Stacks that can be planned and applied at the same time do
    not have a well-defined ordering in the list. That is to say, if stack A is before stack B in
    the list, it may be because A has to planned and applied before B or it may be because A and B
    can be planned and applied at the same time. *)

module Dirspace_state : sig
  type t = {
    dirspace : Terrat_dirspace.t;
    state : Terrat_api_components.Stack_state.t;
  }
  [@@deriving show, eq]
end

module type M = sig
  module Installation_id : Terrat_vcs_api.ID
  module Repo_id : Terrat_vcs_api.ID
  module Pull_request_id : Terrat_vcs_api.ID
  module Config : Terrat_vcs_api.CONFIG

  type db

  val vcs : string
  val route_root : unit -> ('a, 'a) Brtl_rtng.Route.t

  val store_stacks :
    request_id:string ->
    installation_id:Installation_id.t ->
    repo_id:Repo_id.t ->
    pull_request_id:Pull_request_id.t ->
    Terrat_api_components.Stacks.t ->
    db ->
    (unit, [> `Error ]) result Abb.Future.t

  val query_stacks :
    request_id:string ->
    installation_id:Installation_id.t ->
    repo_id:Repo_id.t ->
    pull_request_id:Pull_request_id.t ->
    db ->
    (Terrat_api_components.Stacks.t option, [> `Error ]) result Abb.Future.t

  val query_dirspace_states :
    request_id:string ->
    installation_id:Installation_id.t ->
    repo_id:Repo_id.t ->
    pull_request_id:Pull_request_id.t ->
    db ->
    (Dirspace_state.t list, [> `Error ]) result Abb.Future.t

  val enforce_installation_access :
    request_id:string ->
    Terrat_user.t ->
    Installation_id.t ->
    Pgsql_io.t ->
    (unit, [> `Forbidden ]) result Abb.Future.t
end

module type S = sig
  module Installation_id : Terrat_vcs_api.ID
  module Repo_id : Terrat_vcs_api.ID
  module Pull_request_id : Terrat_vcs_api.ID
  module Config : Terrat_vcs_api.CONFIG

  type db

  val store :
    request_id:string ->
    installation_id:Installation_id.t ->
    repo_id:Repo_id.t ->
    pull_request_id:Pull_request_id.t ->
    Terrat_change_match3.Config.t ->
    db ->
    (unit, [> `Error ]) result Abb.Future.t

  val query :
    request_id:string ->
    installation_id:Installation_id.t ->
    repo_id:Repo_id.t ->
    pull_request_id:Pull_request_id.t ->
    db ->
    (Terrat_api_components.Stacks.t option, [> `Error ]) result Abb.Future.t

  val routes :
    Config.t ->
    Terrat_storage.t ->
    (Brtl_rtng.Method.t * Brtl_rtng.Handler.t Brtl_rtng.Route.Route.t) list
end

module Make (M : M with type db = Pgsql_io.t) :
  S
    with type Installation_id.t = M.Installation_id.t
     and type Repo_id.t = M.Repo_id.t
     and type Pull_request_id.t = M.Pull_request_id.t
     and type Config.t = M.Config.t
     and type db = M.db
