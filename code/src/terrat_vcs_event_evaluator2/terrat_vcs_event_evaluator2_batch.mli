(** Partitioning of dirspaceflows into batches, where each batch becomes its own work manifest. *)

module Run_params : sig
  (** The parameters a run is performed with. Dirspaceflows that do not agree on these cannot share
      a work manifest. *)
  type t = string option * Yojson.Safe.t option [@@deriving eq]
end

val partition_by_run_params :
  max_workspaces_per_batch:int ->
  Terrat_change.Dirspaceflow.Workflow.t option Terrat_change.Dirspaceflow.t list ->
  (Run_params.t * Terrat_change.Dirspaceflow.Workflow.t option Terrat_change.Dirspaceflow.t list)
  list
