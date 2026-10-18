type err = Pgsql_io.err [@@deriving show]

type row = {
  step : string;
  outputs : Yojson.Safe.t option;
}
[@@deriving show, eq]

module Sql = struct
  let select_output_baseline_sql = Mql_sql.read [%blob "sql/select_output_baseline.sql"]
  let select_output_current_sql = Mql_sql.read [%blob "sql/select_output_current.sql"]

  let select stmt =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* step *)
      Ret.text
      //
      (* outputs *)
      Ret.(option json)
      /^ stmt
      /% Var.uuid "repo"
      /% Var.uuid "pull_request"
      /% Var.text "dir"
      /% Var.text "workspace")

  let select_output_baseline () = select select_output_baseline_sql
  let select_output_current () = select select_output_current_sql
end

let fetch stmt db ~repo ~pull_request ~dirspace:{ Terrat_dirspace.dir; workspace } =
  let open Abbs_fc.Infix_result_monad in
  Pgsql_io.Prepared_stmt.fetch
    db
    stmt
    ~f:(fun step outputs -> { step; outputs })
    repo
    pull_request
    dir
    workspace
  >>| CCList.head_opt

let query db ~repo ~pull_request ~dirspace =
  fetch (Sql.select_output_baseline ()) db ~repo ~pull_request ~dirspace

let current db ~repo ~pull_request ~dirspace =
  fetch (Sql.select_output_current ()) db ~repo ~pull_request ~dirspace

let shape_of_step = function
  | "tf/apply" -> Terrat_output_diff.Tf_wrapped
  | _ -> Terrat_output_diff.Raw

let outputs db ~repo ~pull_request ~dirspace =
  let open Abbs_fc.Infix_result_monad in
  current db ~repo ~pull_request ~dirspace
  >>= function
  | None -> Abb.Future.return (Ok None)
  | Some { step; outputs = current } ->
      query db ~repo ~pull_request ~dirspace
      >>| fun baseline ->
      let shape = shape_of_step step in
      let baseline =
        CCOption.flat_map
          (fun { step; outputs } ->
            match (shape_of_step step, shape) with
            | Terrat_output_diff.Tf_wrapped, Terrat_output_diff.Tf_wrapped
            | Terrat_output_diff.Raw, Terrat_output_diff.Raw -> outputs
            | Terrat_output_diff.Tf_wrapped, Terrat_output_diff.Raw
            | Terrat_output_diff.Raw, Terrat_output_diff.Tf_wrapped -> None)
          baseline
      in
      Some { Terrat_output_diff.shape; baseline; current }
