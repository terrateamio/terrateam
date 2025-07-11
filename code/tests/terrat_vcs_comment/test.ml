module Oth_abb = Oth_abb.Make (Abb)

module Eh = struct
  type el = {
    rendered_length : int;
    dirspace : Terrat_dirspace.t;
    is_success : bool;
    strategy : Terrat_vcs_comment.Strategy.t;
  }
  [@@deriving show]

  type comment_id = int [@@deriving show]

  type t =
    | Query_comment_id of el * (comment_id option, [ `Error ]) result
    | Query_els_for_comment_id of comment_id * (el list, [ `Error ]) result
    | Upsert_comment_id of el list * comment_id * (unit, [ `Error ]) result
    | Delete_comment of comment_id * (unit, [ `Error ]) result
    | Minimize_comment of comment_id * (unit, [ `Error ]) result
    | Post_comment of el list * (comment_id, [ `Error ]) result
  [@@deriving show]

  type commands = t list [@@deriving show]
end

module API_id = struct
  type t = int Atomic.t

  let create start = Atomic.make start
  let get counter = Atomic.get counter
  let next counter = Atomic.fetch_and_add counter 1 + 1
end

module H = struct
  type t = Eh.commands ref
  type el = Eh.el
  type comment_id = Eh.comment_id

  let query_comment_id t el1 =
    match !t with
    | Eh.Query_comment_id (el2, cmd_result) :: rest when el1 = el2 ->
        t := rest;
        let abb_result = Abb.Future.return cmd_result in
        (abb_result : ('a, [ `Error ]) result Abb.Future.t :> ('a, [> `Error ]) result Abb.Future.t)
    | es ->
        Printf.printf "\n\tCOMMAND LOG: %s%!\n" (Eh.show_commands es);
        assert false

  let query_els_for_comment_id t cid =
    match !t with
    | Eh.Query_els_for_comment_id (cid2, cmd_result) :: rest when cid = cid2 ->
        t := rest;
        let abb_result = Abb.Future.return cmd_result in
        (abb_result : ('a, [ `Error ]) result Abb.Future.t :> ('a, [> `Error ]) result Abb.Future.t)
    | es ->
        Printf.printf "\n\tCOMMAND LOG: %s%!\n" (Eh.show_commands es);
        assert false

  let upsert_comment_id t els cid =
    match !t with
    | Eh.Upsert_comment_id (els2, cid2, cmd_result) :: rest when cid = cid2 ->
        t := rest;
        let abb_result = Abb.Future.return cmd_result in
        (abb_result : ('a, [ `Error ]) result Abb.Future.t :> ('a, [> `Error ]) result Abb.Future.t)
    | es ->
        Printf.printf "\n\tCOMMAND LOG: %s%!\n" (Eh.show_commands es);
        assert false

  let delete_comment t cid =
    match !t with
    | Eh.Delete_comment (cid2, cmd_result) :: rest when cid = cid2 ->
        t := rest;
        let abb_result = Abb.Future.return cmd_result in
        (abb_result : ('a, [ `Error ]) result Abb.Future.t :> ('a, [> `Error ]) result Abb.Future.t)
    | es ->
        Printf.printf "\n\tCOMMAND LOG: %s%!\n" (Eh.show_commands es);
        assert false

  let minimize_comment t cid =
    match !t with
    | Eh.Minimize_comment (cid2, cmd_result) :: rest when cid = cid2 ->
        t := rest;
        let abb_result = Abb.Future.return cmd_result in
        (abb_result : ('a, [ `Error ]) result Abb.Future.t :> ('a, [> `Error ]) result Abb.Future.t)
    | es ->
        Printf.printf "\n\tCOMMAND LOG: %s%!\n" (Eh.show_commands es);
        assert false

  let post_comment t els =
    match !t with
    | Eh.Post_comment (_, cmd_result) :: rest ->
        t := rest;
        let abb_result = Abb.Future.return cmd_result in
        (abb_result : ('a, [ `Error ]) result Abb.Future.t :> ('a, [> `Error ]) result Abb.Future.t)
    | es ->
        Printf.printf "\n\tCOMMAND LOG: %s%!\n" (Eh.show_commands es);
        assert false

  let rendered_length els = CCList.fold_left (fun acc el -> acc + el.Eh.rendered_length) 0 els
  let dirspace el = el.Eh.dirspace
  let is_success el = el.Eh.is_success
  let strategy el = el.Eh.strategy
  let compact el = { el with Eh.rendered_length = 1 }
  let max_comment_length = 100
end

module Shared = struct
  let random_string n =
    let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" in
    let len = String.length chars in
    let result = Bytes.create n in
    for i = 0 to n - 1 do
      let random_index = Random.int len in
      Bytes.set result i chars.[random_index]
    done;
    Bytes.to_string result

  let random_el min_len max_len =
    let module C = Terrat_vcs_comment in
    let module D = Terrat_dirspace in
    let rendered_length = Random.int_in_range ~min:min_len ~max:max_len in
    let dirspace = D.{ dir = random_string 10; workspace = random_string 10 } in
    let is_success = Random.bool () in
    let strategy =
      match Random.int_in_range ~min:0 ~max:2 with
      | 0 -> C.Strategy.Append
      | _ -> C.Strategy.Append
    in
    Eh.{ rendered_length; dirspace; is_success; strategy }

  let create_el dir workspace is_success rendered_length strategy =
    let module D = Terrat_dirspace in
    let dirspace = D.{ dir; workspace } in
    Eh.{ rendered_length; dirspace; is_success; strategy }

  let gen_els n min max = CCList.init n (fun _ -> random_el min max)
end

module Make_wrapper = struct
  let run t els =
    let module C = Terrat_vcs_comment in
    let module D = Terrat_dirspace in
    let module Cm = Terrat_vcs_comment.Make (H) in
    match !t with
    | [] -> Abb.Future.return (Ok ())
    | s -> Cm.run t els
end

let test_basic =
  let empty_els =
    Oth_abb.test ~desc:"Noop flow" ~name:"[Basic] Empty elements" (fun () ->
        let open Abb.Future.Infix_monad in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let els = [] in
        let t = ref [] in
        Make_wrapper.run t els
        >>= function
        | Ok r ->
            assert (r = ());
            Abb.Future.return ()
        | Error _ -> assert false)
  in
  let simple_post =
    Oth_abb.test ~name:"[Basic] Single post comment flow" (fun () ->
        let open Abb.Future.Infix_monad in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let module Shr = Shared in
        let els = Shared.gen_els 1 10 20 in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let t = ref [ Eh.Post_comment (els, Ok cid1); Eh.Upsert_comment_id (els, cid1, Ok ()) ] in
        Make_wrapper.run t els
        >>= function
        | Ok r ->
            assert (r = ());
            Abb.Future.return ()
        | Error _ -> assert false)
  in
  Oth_abb.parallel [ empty_els; simple_post ]

let test_errors =
  let post_comment =
    Oth_abb.test
      ~desc:"Errors during post_comment are handled correctly"
      ~name:"[Error] Check error handling"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let els = Shared.gen_els 5 10 20 in
        let t = ref [ Eh.Post_comment (els, Error `Error) ] in
        Make_wrapper.run t els
        >>= function
        | Ok _ -> assert false
        | Error `Error -> Abb.Future.return ()
        | Error _ -> assert false)
  in
  Oth_abb.parallel [ post_comment ]

let test_append_strategy =
  let multiple_small =
    Oth_abb.test
      ~desc:
        "Given 3 elements with rendered length smaller than the ceiling, but that can't be combine \
         into a single cluster, we will generate 3 comments"
      ~name:"[Append] Check grouping #1"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let len = H.max_comment_length - 1 in
        let st = C.Strategy.Append in
        let el1 = Shared.create_el "A" "A" false len st in
        let el2 = Shared.create_el "B" "B" true len st in
        let el3 = Shared.create_el "C" "C" false len st in
        let els = [ el1; el2; el3 ] in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let cid2 = API_id.next counter in
        let cid3 = API_id.next counter in
        let t =
          ref
            [
              Eh.Post_comment ([ el1 ], Ok cid1);
              Eh.Upsert_comment_id ([ el1 ], cid1, Ok ());
              Eh.Post_comment ([ el3 ], Ok cid2);
              Eh.Upsert_comment_id ([ el3 ], cid2, Ok ());
              Eh.Post_comment ([ el2 ], Ok cid3);
              Eh.Upsert_comment_id ([ el2 ], cid3, Ok ());
            ]
        in
        Make_wrapper.run t els
        >>= function
        | Ok r ->
            assert (r = ());
            Abb.Future.return ()
        | Error _ -> assert false)
  in
  let multiple_big =
    Oth_abb.test
      ~desc:
        "Given 3 elements with rendered length bigger than the ceiling, but will be compacted to \
         fit into a single cluster, generate a single comment"
      ~name:"[Append] Check grouping #2"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let len = H.max_comment_length + 1 in
        let st = C.Strategy.Append in
        let el1 = Shared.create_el "A" "A" false len st in
        let el2 = Shared.create_el "B" "B" true len st in
        let el3 = Shared.create_el "C" "C" false len st in
        let els = [ el1; el2; el3 ] in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let t = ref [ Eh.Post_comment (els, Ok cid1); Eh.Upsert_comment_id (els, cid1, Ok ()) ] in
        Make_wrapper.run t els
        >>= function
        | Ok r ->
            assert (r = ());
            Abb.Future.return ()
        | Error _ -> assert false)
  in
  let multiple_mixed =
    Oth_abb.test
      ~desc:
        "Given 4 elements with mixed rendered lengths, get smaller comments into a single cluster, \
         compact the big ones and also fit them into a smaller cluster"
      ~name:"[Append] Check grouping #3"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let half = H.max_comment_length / 2 in
        let st = C.Strategy.Append in
        let el1 = Shared.create_el "A" "A" false half st in
        let el2 = Shared.create_el "B" "B" true (half - 1) st in
        let el3 = Shared.create_el "C" "C" false (half - 1) st in
        let el4 = Shared.create_el "D" "D" true (H.max_comment_length + 1) st in
        let els = [ el1; el2; el3; el4 ] in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let cid2 = API_id.next counter in
        let t =
          ref
            [
              Eh.Post_comment ([ el1; el3 ], Ok cid1);
              Eh.Upsert_comment_id ([ el1; el3 ], cid1, Ok ());
              Eh.Post_comment ([ el2; el4 ], Ok cid2);
              Eh.Upsert_comment_id ([ el2; el4 ], cid2, Ok ());
            ]
        in
        Make_wrapper.run t els
        >>= function
        | Ok r ->
            assert (r = ());
            Abb.Future.return ()
        | Error _ -> assert false)
  in
  let scenario_03 =
    Oth_abb.test
      ~desc:
        "A sequence of post comments is appended separately, a subset of dirspaces is then re-run."
      ~name:"[Append] Scenario #03"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let open Abbs_future_combinators.Infix_result_app in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let len = H.max_comment_length / 3 in
        let st = C.Strategy.Append in
        let el1 = Shared.create_el "A" "A" false len st in
        let el2 = Shared.create_el "B" "B" true len st in
        let el3 = Shared.create_el "C" "C" true len st in
        let els = [ el1; el2; el3 ] in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let t =
          ref
            [
              Eh.Post_comment (els, Ok cid1); Eh.Upsert_comment_id ([ el1; el2; el3 ], cid1, Ok ());
            ]
        in
        Make_wrapper.run t els
        >>= function
        | Ok r -> (
            assert (r = ());
            let el1 = Shared.create_el "A" "A" true len st in
            let el2 = Shared.create_el "B" "B" false len st in
            let els2 = [ el1; el2 ] in
            let cid2 = API_id.next counter in
            let t2 =
              ref [ Eh.Post_comment (els2, Ok cid2); Eh.Upsert_comment_id (els2, cid2, Ok ()) ]
            in
            Make_wrapper.run t2 els2
            >>= fun r ->
            match r with
            | Ok r ->
                assert (r = ());
                Abb.Future.return ()
            | Error _ -> assert false)
        | Error _ -> assert false)
  in
  let scenario_07 =
    Oth_abb.test
      ~desc:"User runs 'terrateam plan A B', then proceeds to run 'terrateam plan B C'"
      ~name:"[Append] Scenario #07"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let len = H.max_comment_length / 10 in
        let st = C.Strategy.Append in
        let el1 = Shared.create_el "A" "A" false len st in
        let el2 = Shared.create_el "B" "B" true len st in
        let els = [ el1; el2 ] in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let t =
          ref [ Eh.Post_comment (els, Ok cid1); Eh.Upsert_comment_id ([ el1; el2 ], cid1, Ok ()) ]
        in
        Make_wrapper.run t els
        >>= function
        | Ok r -> (
            assert (r = ());
            let el1 = Shared.create_el "B" "B" true len st in
            let el2 = Shared.create_el "C" "C" false len st in
            let els2 = [ el1; el2 ] in
            let cid2 = API_id.next counter in
            let t2 =
              ref [ Eh.Post_comment (els2, Ok cid2); Eh.Upsert_comment_id (els2, cid2, Ok ()) ]
            in
            Make_wrapper.run t2 els2
            >>= fun r ->
            match r with
            | Ok r ->
                assert (r = ());
                Abb.Future.return ()
            | Error _ -> assert false)
        | Error _ -> assert false)
  in
  let scenario_08 =
    Oth_abb.test
      ~desc:"User runs 'terrateam plan A', then proceeds to run 'terrateam plan B'"
      ~name:"[Append] Scenario #08"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let len = H.max_comment_length / 10 in
        let st = C.Strategy.Append in
        let el1 = Shared.create_el "A" "A" false len st in
        let els = [ el1 ] in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let t =
          ref [ Eh.Post_comment (els, Ok cid1); Eh.Upsert_comment_id ([ el1 ], cid1, Ok ()) ]
        in
        Make_wrapper.run t els
        >>= function
        | Ok r -> (
            assert (r = ());
            let el2 = Shared.create_el "B" "B" true len st in
            let els2 = [ el2 ] in
            let cid2 = API_id.next counter in
            let t2 =
              ref [ Eh.Post_comment (els2, Ok cid2); Eh.Upsert_comment_id (els2, cid2, Ok ()) ]
            in
            Make_wrapper.run t2 els2
            >>= fun r ->
            match r with
            | Ok r ->
                assert (r = ());
                Abb.Future.return ()
            | Error _ -> assert false)
        | Error _ -> assert false)
  in
  Oth_abb.parallel
    [ multiple_small; multiple_big; multiple_mixed; scenario_03; scenario_07; scenario_08 ]

let test = Oth_abb.(to_sync_test (parallel [ test_basic; test_errors; test_append_strategy ]))

let () =
  Random.self_init ();
  Oth.run test
