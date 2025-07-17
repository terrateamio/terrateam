module Api = Terrat_vcs_api_github

module Result = struct
  let steps_has_changes steps =
    let module P = struct
      type t = { has_changes : bool [@default false] } [@@deriving of_yojson { strict = false }]
    end in
    let module O = Terrat_api_components.Workflow_step_output in
    match
      CCList.find_map
        (function
          | { O.step = "tf/plan" | "pulumi/plan" | "custom/plan" | "fly/plan"; payload; success; _ }
            -> (
              match P.of_yojson (O.Payload.to_yojson payload) with
              | Ok { P.has_changes } -> Some has_changes
              | _ -> None)
          | _ -> None)
        steps
    with
    | Some has_changes -> has_changes
    | None -> false

  let steps_success steps =
    let module O = Terrat_api_components.Workflow_step_output in
    CCList.for_all (fun { O.success; ignore_errors; _ } -> success || ignore_errors) steps
end

module S = struct
  type t = { client : Api.Client.t }

  type el = {
    dirspace : Terrat_dirspace.t;
    is_success : bool;
    rendered_length : int;
    step_outputs : Terrat_api_components_workflow_step_output.t list;
    strategy : Terrat_vcs_comment.Strategy.t;
  }

  type comment_id = int

  module Cmp = struct
    type t = bool * bool * Terrat_dirspace.t [@@deriving ord]
  end

  let query_comment_id t el = 1000
  let query_els_for_comment_id t cid = []
  let upsert_comment_id t els cid = Abb.Future.return (Ok ())
  let delete_comment t comment_id = Abb.Future.return (Ok ())
  let minimize_comment t comment_id = Abb.Future.return (Ok ())

  let post_comment t els =
    let module Gh = Terrat_vcs_api_github in
    let _request_id = "test" in
    Abb.Future.return (Ok 1)

  let rendered_length els = CCList.fold_left (fun acc el -> acc + el.rendered_length) 0 els
  let dirspace el = el.dirspace
  let strategy el = el.strategy

  (* TODO: For testing purposes only, will change this later *)
  (* TODO: Wirte with proper templates on Tmpl later *)
  let compact el = { el with rendered_length = 2048 }

  let compare_el el1 el2 =
    let dirspace1 = dirspace el1 in
    let steps1 = el1.step_outputs in
    let dirspace2 = dirspace el2 in
    let steps2 = el2.step_outputs in
    let has_changes1 = Result.steps_has_changes steps1 in
    let success1 = Result.steps_success steps2 in
    let has_changes2 = Result.steps_has_changes steps2 in
    let success2 = Result.steps_success steps2 in
    (* Negate has_changes because the order of [bool] is [false]
            before [true]. *)
    Cmp.compare (not has_changes1, success1, dirspace1) (not has_changes2, success2, dirspace2)

  (* Github Limits it to 2^16 = 65536
     https://github.com/mshick/add-pr-comment/issues/93#issuecomment-1531415467
     I set it to a smaller value *)
  let max_comment_length = 65536 / 2
end
