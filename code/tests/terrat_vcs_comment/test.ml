module Oth_abb = Oth_abb.Make (Abb)

module Eh = struct
  type el = {
    rendered_length : int;
    dirspace : Terrat_dirspace.t;
    is_success : bool;
    strategy : Terrat_vcs_comment.Strategy.t;
  }
  [@@deriving show]

  type comment_id = int [@@deriving ord, show]

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
  type el = Eh.el [@@deriving show]
  type comment_id = Eh.comment_id [@@deriving ord, show]

  module Cmp = struct
    type t = bool * Terrat_dirspace.t [@@deriving ord]
  end

  let query_comment_id t el1 =
    match !t with
    (* | Eh.Query_comment_id (el2, cmd_result) :: rest when el1 = el2 -> *)
    | Eh.Query_comment_id (el2, cmd_result) :: rest ->
        t := rest;
        let abb_result = Abb.Future.return cmd_result in
        (abb_result : ('a, [ `Error ]) result Abb.Future.t :> ('a, [> `Error ]) result Abb.Future.t)
    | es ->
        Printf.printf "\n\tQUERY COMMENT_ID LOG: %s%!\n" (Eh.show_commands es);
        assert false

  let query_els_for_comment_id t cid =
    match !t with
    | Eh.Query_els_for_comment_id (cid2, cmd_result) :: rest when cid = cid2 ->
        t := rest;
        let abb_result = Abb.Future.return cmd_result in
        (abb_result : ('a, [ `Error ]) result Abb.Future.t :> ('a, [> `Error ]) result Abb.Future.t)
    | es ->
        Printf.printf "\n\tQUERY ELS FOR COMMENT_ID LOG: %s%!\n" (Eh.show_commands es);
        assert false

  let upsert_comment_id t els cid =
    match !t with
    | Eh.Upsert_comment_id (els2, cid2, cmd_result) :: rest when cid = cid2 ->
        t := rest;
        let abb_result = Abb.Future.return cmd_result in
        (abb_result : ('a, [ `Error ]) result Abb.Future.t :> ('a, [> `Error ]) result Abb.Future.t)
    | es ->
        Printf.printf "\n\tUPSERT LOG: %s%!\n" (Eh.show_commands es);
        assert false

  let delete_comment t cid =
    match !t with
    | Eh.Delete_comment (cid2, cmd_result) :: rest when cid = cid2 ->
        t := rest;
        let abb_result = Abb.Future.return cmd_result in
        (abb_result : ('a, [ `Error ]) result Abb.Future.t :> ('a, [> `Error ]) result Abb.Future.t)
    | es ->
        Printf.printf "\n\tDELETE LOG: %s%!\n" (Eh.show_commands es);
        assert false

  let minimize_comment t cid =
    match !t with
    | Eh.Minimize_comment (cid2, cmd_result) :: rest when cid = cid2 ->
        t := rest;
        let abb_result = Abb.Future.return cmd_result in
        (abb_result : ('a, [ `Error ]) result Abb.Future.t :> ('a, [> `Error ]) result Abb.Future.t)
    | es ->
        Printf.printf "\n\tMINIMIZE LOG: %s%!\nCID_INPUT=%d\n%!" (Eh.show_commands es) cid;
        assert false

  let post_comment t els =
    match !t with
    | Eh.Post_comment (els2, cmd_result) :: rest when els = els2 ->
        t := rest;
        let abb_result = Abb.Future.return cmd_result in
        (abb_result : ('a, [ `Error ]) result Abb.Future.t :> ('a, [> `Error ]) result Abb.Future.t)
    | es ->
        let show = [%show: Eh.el list] in
        Printf.printf "\n\tPOST COMMENT INPUTS: %s%!\n" (show els);
        Printf.printf "\n\tPOST COMMENT LOG: %s%!\n" (Eh.show_commands es);
        assert false

  let rendered_length _ els = CCList.fold_left (fun acc el -> acc + el.Eh.rendered_length) 0 els
  let strategy el = el.Eh.strategy
  let compact el = { el with Eh.rendered_length = 1 }

  let compare_el el1 el2 =
    Cmp.compare (el1.Eh.is_success, el1.Eh.dirspace) (el2.Eh.is_success, el2.Eh.dirspace)

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
    let open Abb.Future.Infix_monad in
    let module C = Terrat_vcs_comment in
    let module D = Terrat_dirspace in
    let module Cm = Terrat_vcs_comment.Make (H) in
    Cm.run t els
    >>= function
    | Ok () -> (
        match !t with
        | [] -> Abb.Future.return (Ok ())
        | es ->
            Printf.printf "\n\tT: %s%!\n" (Eh.show_commands es);
            assert false)
    | Error e -> Abb.Future.return (Error e)
end

let test_basic =
  let _empty_els =
    Oth_abb.test ~desc:"Noop flow" ~name:"[Basic] Empty elements" (fun () ->
        let open Abb.Future.Infix_monad in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let els = [] in
        let t = ref [] in
        Make_wrapper.run t els
        >>= function
        | Ok () -> Abb.Future.return ()
        | Error _ -> assert false)
  in
  let simple_post =
    Oth_abb.test ~name:"[Basic] Single post comment flow" (fun () ->
        let open Abb.Future.Infix_monad in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let module Shr = Shared in
        (* TODO: Remove this random data gen *)
        let els = Shared.gen_els 1 10 20 in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let t = ref [ Eh.Post_comment (els, Ok cid1); Eh.Upsert_comment_id (els, cid1, Ok ()) ] in
        Make_wrapper.run t els
        >>= function
        | Ok r -> Abb.Future.return ()
        | Error _ -> assert false)
  in
  Oth_abb.parallel [ simple_post ]

let test_errors =
  let post_comment =
    Oth_abb.test
      ~desc:"Errors during post_comment are handled correctly"
      ~name:"[Error] Check error handling"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module Cm = Terrat_vcs_comment.Make (H) in
        (* TODO: Remove this random data gen *)
        let els = Shared.gen_els 1 10 20 in
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
        "Given 3 elements with rendered length smaller than the ceiling, but that can't be \
         combined into a single cluster, we will generate 3 comments"
      ~name:"[Append] Multiple Small #1"
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
        | Ok () -> Abb.Future.return ()
        | Error _ -> assert false)
  in
  let multiple_big =
    Oth_abb.test
      ~desc:
        "Given 3 elements with rendered length bigger than the ceiling, but will be compacted to \
         fit into a single cluster, generate a single comment"
      ~name:"[Append] Multiple Big #1"
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
        let elsc = CCList.map H.compact [ el1; el3; el2 ] in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let t = ref [ Eh.Post_comment (elsc, Ok cid1); Eh.Upsert_comment_id (elsc, cid1, Ok ()) ] in
        Make_wrapper.run t els
        >>= function
        | Ok r -> Abb.Future.return ()
        | Error _ -> assert false)
  in
  let multiple_mixed =
    Oth_abb.test
      ~desc:
        "Given 4 elements with mixed rendered lengths, get smaller comments into a single cluster, \
         compact the big ones and also fit them into a smaller cluster"
      ~name:"[Append] Mixed #1"
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
        let el4c = H.compact el4 in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let cid2 = API_id.next counter in
        let t =
          ref
            [
              Eh.Post_comment ([ el1; el3 ], Ok cid1);
              Eh.Upsert_comment_id ([ el1; el3 ], cid1, Ok ());
              Eh.Post_comment ([ el2; el4c ], Ok cid2);
              Eh.Upsert_comment_id ([ el2; el4c ], cid2, Ok ());
            ]
        in
        Make_wrapper.run t els
        >>= function
        | Ok () -> Abb.Future.return ()
        | Error _ -> assert false)
  in
  Oth_abb.parallel [ multiple_small; multiple_big; multiple_mixed ]

let test_delete_strategy =
  let multiple_small =
    Oth_abb.test
      ~desc:
        "Given 3 elements with rendered length smaller than the ceiling, but that can't be \
         combined into a single cluster, we will generate 3 comments"
      ~name:"[Delete] Multiple Small #1"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let len = H.max_comment_length - 1 in
        let st = C.Strategy.Delete in
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
              Eh.Query_comment_id (el1, Ok None);
              Eh.Post_comment ([ el1 ], Ok cid1);
              Eh.Upsert_comment_id ([ el1 ], cid1, Ok ());
              Eh.Query_comment_id (el3, Ok None);
              Eh.Post_comment ([ el3 ], Ok cid3);
              Eh.Upsert_comment_id ([ el3 ], cid3, Ok ());
              Eh.Query_comment_id (el2, Ok None);
              Eh.Post_comment ([ el2 ], Ok cid2);
              Eh.Upsert_comment_id ([ el2 ], cid2, Ok ());
            ]
        in
        Make_wrapper.run t els
        >>= function
        | Ok () -> Abb.Future.return ()
        | Error _ -> assert false)
  in
  let multiple_big =
    Oth_abb.test
      ~desc:
        "Given 3 elements with rendered length bigger than the ceiling, but will be compacted to \
         fit into a single cluster, generate a single comment"
      ~name:"[Delete] Multiple Big #1"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let len = H.max_comment_length + 1 in
        let st = C.Strategy.Delete in
        let el1 = Shared.create_el "A" "A" false len st in
        let el2 = Shared.create_el "B" "B" true len st in
        let el3 = Shared.create_el "C" "C" false len st in
        let els = [ el1; el2; el3 ] in
        let elsc = CCList.map H.compact [ el1; el3; el2 ] in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let t =
          ref
            [
              Eh.Query_comment_id (el1, Ok None);
              Eh.Query_comment_id (el3, Ok None);
              Eh.Query_comment_id (el2, Ok None);
              Eh.Post_comment (elsc, Ok cid1);
              Eh.Upsert_comment_id (elsc, cid1, Ok ());
            ]
        in
        Make_wrapper.run t els
        >>= function
        | Ok r -> Abb.Future.return ()
        | Error _ -> assert false)
  in
  let multiple_mixed =
    Oth_abb.test
      ~desc:
        "Given 4 elements with mixed rendered lengths, get smaller comments into a single cluster, \
         compact the big ones and also fit them into a smaller cluster"
      ~name:"[Delete] Mixed #1"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let half = H.max_comment_length / 2 in
        let st = C.Strategy.Delete in
        let el1 = Shared.create_el "A" "A" false half st in
        let el2 = Shared.create_el "B" "B" true (half - 1) st in
        let el3 = Shared.create_el "C" "C" false (half - 1) st in
        let el4 = Shared.create_el "D" "D" true (H.max_comment_length + 1) st in
        let els = [ el1; el2; el3; el4 ] in
        let el4c = H.compact el4 in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let cid2 = API_id.next counter in
        let t =
          ref
            [
              Eh.Query_comment_id (el1, Ok None);
              Eh.Query_comment_id (el3, Ok None);
              Eh.Post_comment ([ el1; el3 ], Ok cid1);
              Eh.Upsert_comment_id ([ el1; el3 ], cid1, Ok ());
              Eh.Query_comment_id (el2, Ok None);
              Eh.Query_comment_id (el4, Ok None);
              Eh.Post_comment ([ el2; el4c ], Ok cid2);
              Eh.Upsert_comment_id ([ el2; el4c ], cid2, Ok ());
            ]
        in
        Make_wrapper.run t els
        >>= function
        | Ok () -> Abb.Future.return ()
        | Error _ -> assert false)
  in
  Oth_abb.parallel [ multiple_small; multiple_big; multiple_mixed ]

let test_minimize_strategy =
  let multiple_small =
    Oth_abb.test
      ~desc:
        "Given 3 elements with rendered length smaller than the ceiling, but that can't be \
         combined into a single cluster, we will generate 3 comments"
      ~name:"[Minimize] Multiple Small #1"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let len = H.max_comment_length - 1 in
        let st = C.Strategy.Minimize in
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
              Eh.Query_comment_id (el1, Ok None);
              Eh.Post_comment ([ el1 ], Ok cid1);
              Eh.Upsert_comment_id ([ el1 ], cid1, Ok ());
              Eh.Query_comment_id (el3, Ok None);
              Eh.Post_comment ([ el3 ], Ok cid3);
              Eh.Upsert_comment_id ([ el3 ], cid3, Ok ());
              Eh.Query_comment_id (el2, Ok None);
              Eh.Post_comment ([ el2 ], Ok cid2);
              Eh.Upsert_comment_id ([ el2 ], cid2, Ok ());
            ]
        in
        Make_wrapper.run t els
        >>= function
        | Ok () -> Abb.Future.return ()
        | Error _ -> assert false)
  in
  let multiple_small_with_old_comment =
    Oth_abb.test
      ~desc:
        "Given 2 elements with rendered length smaller than the ceiling, but that can't be \
         combined into a single cluster, and 1 comment that is an older version of the first one, \
         We'll generate two new comments and minimize the old one."
      ~name:"[Minimize] Multiple Small #2"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let len = H.max_comment_length - 1 in
        let st = C.Strategy.Minimize in
        let el1 = Shared.create_el "A" "A" false len st in
        let el2 = Shared.create_el "B" "B" true len st in
        let els1 = [ el1; el2 ] in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let cid2 = API_id.next counter in
        let t1 =
          ref
            [
              Eh.Query_comment_id (el1, Ok None);
              Eh.Post_comment ([ el1 ], Ok cid1);
              Eh.Upsert_comment_id ([ el1 ], cid1, Ok ());
              Eh.Query_comment_id (el2, Ok None);
              Eh.Post_comment ([ el2 ], Ok cid2);
              Eh.Upsert_comment_id ([ el2 ], cid2, Ok ());
            ]
        in
        Make_wrapper.run t1 els1
        >>= function
        | Ok () -> (
            (* Dirspace A/A is re-run and now evaluates to true *)
            let el3 = Shared.create_el "A" "A" true len st in
            let els2 = [ el3 ] in
            let cid3 = API_id.next counter in
            let t2 =
              ref
                [
                  (* Check that C1 is already posted, minimize it *)
                  Eh.Query_comment_id (el3, Ok (Some cid1));
                  Eh.Minimize_comment (cid1, Ok ());
                  Eh.Query_els_for_comment_id (cid1, Ok []);
                  Eh.Post_comment ([ el3 ], Ok cid3);
                  Eh.Upsert_comment_id ([ el3 ], cid3, Ok ());
                ]
            in
            Make_wrapper.run t2 els2
            >>= function
            | Ok () -> Abb.Future.return ()
            | Error _ -> assert false)
        | Error _ -> assert false)
  in
  let multiple_big =
    Oth_abb.test
      ~desc:
        "Given 3 elements with rendered length bigger than the ceiling, but that will be compacted \
         to fit into a single cluster, generate a single comment"
      ~name:"[Minimize] Multiple Big #1"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let len = H.max_comment_length + 1 in
        let st = C.Strategy.Minimize in
        let el1 = Shared.create_el "A" "A" false len st in
        let el2 = Shared.create_el "B" "B" true len st in
        let el3 = Shared.create_el "C" "C" false len st in
        let els = [ el1; el2; el3 ] in
        let elsc = CCList.map H.compact [ el1; el3; el2 ] in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let t =
          ref
            [
              Eh.Query_comment_id (el1, Ok None);
              Eh.Query_comment_id (el3, Ok None);
              Eh.Query_comment_id (el2, Ok None);
              Eh.Post_comment (elsc, Ok cid1);
              Eh.Upsert_comment_id (elsc, cid1, Ok ());
            ]
        in
        Make_wrapper.run t els
        >>= function
        | Ok r -> Abb.Future.return ()
        | Error _ -> assert false)
  in
  let multiple_big_with_old_comment =
    Oth_abb.test
      ~desc:
        "Given 3 elements with rendered length bigger than the ceiling, but that will be compacted \
         to fit into a single cluster, generate a single comment"
      ~name:"[Minimize] Multiple Big #2"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let len = H.max_comment_length + 1 in
        let st = C.Strategy.Minimize in
        let el1 = Shared.create_el "A" "A" false len st in
        let el2 = Shared.create_el "B" "B" true len st in
        let el3 = Shared.create_el "C" "C" false len st in
        let els1 = [ el1; el2; el3 ] in
        let elsc = CCList.map H.compact [ el1; el3; el2 ] in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let t1 =
          ref
            [
              Eh.Query_comment_id (el1, Ok None);
              Eh.Query_comment_id (el3, Ok None);
              Eh.Query_comment_id (el2, Ok None);
              Eh.Post_comment (elsc, Ok cid1);
              Eh.Upsert_comment_id (elsc, cid1, Ok ());
            ]
        in
        Make_wrapper.run t1 els1
        >>= function
        | Ok () -> (
            (* Dirspaces A/A and C/C are re-run and now evaluate to true *)
            let el1t = Shared.create_el "A" "A" true len st in
            let el3t = Shared.create_el "C" "C" true len st in
            let els2 = [ el1t; el3t ] in
            let el2c = H.compact el2 in
            let els_expected = [ el1t; el2; el3t ] in
            let els2c = CCList.map H.compact els_expected in
            let cid2 = API_id.next counter in
            let t2 =
              ref
                [
                  Eh.Query_comment_id (el1t, Ok (Some cid1));
                  Eh.Query_comment_id (el3t, Ok (Some cid1));
                  Eh.Minimize_comment (cid1, Ok ());
                  Eh.Query_els_for_comment_id (cid1, Ok [ el2c ]);
                  Eh.Post_comment (els2c, Ok cid2);
                  Eh.Upsert_comment_id (els2c, cid2, Ok ());
                ]
            in
            Make_wrapper.run t2 els2
            >>= function
            | Ok () -> Abb.Future.return ()
            | Error _ -> assert false)
        | Error _ -> assert false)
  in
  let multiple_mixed =
    Oth_abb.test
      ~desc:
        "Given 4 elements with mixed rendered lengths, get smaller comments into a single cluster, \
         compact the big ones and also fit them into a smaller cluster"
      ~name:"[Minimize] Mixed #1"
      (fun () ->
        let open Abb.Future.Infix_monad in
        let module C = Terrat_vcs_comment in
        let module D = Terrat_dirspace in
        let module Cm = Terrat_vcs_comment.Make (H) in
        let half = H.max_comment_length / 2 in
        let st = C.Strategy.Delete in
        let el1 = Shared.create_el "A" "A" false half st in
        let el2 = Shared.create_el "B" "B" true (half - 1) st in
        let el3 = Shared.create_el "C" "C" false (half - 1) st in
        let el4 = Shared.create_el "D" "D" true (H.max_comment_length + 1) st in
        let els = [ el1; el2; el3; el4 ] in
        let el4c = H.compact el4 in
        let counter = API_id.create 0 in
        let cid1 = API_id.next counter in
        let cid2 = API_id.next counter in
        let t =
          ref
            [
              Eh.Query_comment_id (el1, Ok None);
              Eh.Query_comment_id (el3, Ok None);
              Eh.Post_comment ([ el1; el3 ], Ok cid1);
              Eh.Upsert_comment_id ([ el1; el3 ], cid1, Ok ());
              Eh.Query_comment_id (el2, Ok None);
              Eh.Query_comment_id (el4, Ok None);
              Eh.Post_comment ([ el2; el4c ], Ok cid2);
              Eh.Upsert_comment_id ([ el2; el4c ], cid2, Ok ());
            ]
        in
        Make_wrapper.run t els
        >>= function
        | Ok () -> Abb.Future.return ()
        | Error _ -> assert false)
  in
  Oth_abb.parallel
    [
      multiple_small;
      multiple_small_with_old_comment;
      multiple_big;
      multiple_big_with_old_comment;
      multiple_mixed;
    ]

let test =
  Oth_abb.(
    to_sync_test
      (parallel
         [
           test_basic;
           test_errors;
           test_append_strategy;
           test_delete_strategy;
           test_minimize_strategy;
         ]))

let () =
  Random.self_init ();
  Oth.run test
