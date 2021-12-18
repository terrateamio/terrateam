type t = {
  dirspace : Terrat_change.Dirspace.t;
  hash : string;
  run_type : Terrat_work_manifest.Run_type.t;
  success : bool;
  work_manifest : Uuidm.t;
}
