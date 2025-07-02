module Oth_abb = Oth_abb.Make (Abb)

type comment_status =
  | Active
  | Minimized
  | Deleted

module Fake_db = struct
  type db_comment = {
    comment_id : int;
    index : int;
    content : string;
    status : comment_status;
  }

  type db = { rows : db_comment list }

  let init () = { rows = [] }
end

module Fake_api = struct
  type api = { mutable next_id : int }

  let init () = { next_id = 1 }
  let next s = { next_id = s.next_id + 1 }
end

(* This modules represents a synthetic VCS *)
module Synthetic = struct
  type t = {
    api : Fake_api.api;
    db : Fake_db.db;
  }

  type el = {
    content : string;
    dirspace : string;
    status : comment_status;
  }

  type comment_id = int

  let query_comment_id t el =
    Abb.Future.return
      (try
         Ok (None)
       with
      | Not_found -> Ok None
      | _ -> Error `Error)

  let upsert_comment_id t els cid = raise (Failure "nyi")
  let delete_comment _ _ = raise (Failure "nyi")
  let minimize_comment _ _ = raise (Failure "nyi")
  let post_comment _ _ = raise (Failure "nyi")
  let rendered_length _ = raise (Failure "nyi")
  let max_comment_length = 100
  let strategy _ _ = raise (Failure "nyi")
end

let test_basic =
  Oth_abb.test ~name:"Basic Flow" (fun () ->
      let module C = Terrat_vcs_comment.Make (Synthetic) in
      let open Abb.Future.Infix_monad in
      C.run () [] >>= fun _ -> Abb.Future.return ())

let test = Oth_abb.(to_sync_test (parallel [ test_basic ]))

let () =
  Random.self_init ();
  Oth.run test
