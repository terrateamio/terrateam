module Oth_abb = Oth_abb.Make (Abb)

type comment_status =
  | Active
  | Minimized
  | Deleted

module Fake_db = struct
  type db_comment = {
    comment_id : int;
    elements : int list;
    index : int;
    content : string;
    status : comment_status;
  }

  type db = { rows : db_comment list }

  let init () = { rows = [] }

  let find_by_id db comment_id =
    List.find_opt (fun comment -> comment.comment_id = comment_id) db.rows

  let find_by_status db status = List.filter (fun comment -> comment.status = status) db.rows
end

module Fake_api = struct
  type api = { mutable next_id : int }

  let init () = { next_id = 1 }
  let next s = { next_id = s.next_id + 1 }
end

(* This modules represents a synthetic VCS *)
module Synthetic = struct
  type t = {
    mutable api : Fake_api.api;
    mutable db : Fake_db.db;
  }

  type el = {
    id : int;
    content : string;
    dirspace : string;
  }

  type comment_id = int

  let query_comment_id t el =
    let module F = Fake_db in
    Abb.Future.return
      (try
         let rows = t.db.F.rows in
         let c = CCList.find_opt (fun c -> CCList.mem el.id c.F.elements) rows in
         match c with
         | Some comment -> Ok (Some comment.F.comment_id)
         | None -> Ok None
       with _ -> Error `Error)

  let upsert_comment_id t els cid =
    let module A = Fake_api in
    let module F = Fake_db in
    Abb.Future.return
      (try
         let eids = CCList.map (fun el -> el.id) els in
         let content = CCString.concat "\n" (List.map (fun el -> el.content) els) in

         match Fake_db.find_by_id t.db cid with
         | Some _ ->
             let updated_rows =
               CCList.map
                 (fun comment ->
                   if comment.F.comment_id = cid then { comment with F.elements = eids; content }
                   else comment)
                 t.db.F.rows
             in
             t.db <- { F.rows = updated_rows };
             Ok ()
         | None ->
             let new_id = t.api.A.next_id in
             let new_comment =
               { F.comment_id = new_id; F.elements = eids; F.index = 1; content; F.status = Active }
             in
             t.api <- A.next t.api;
             t.db <- { F.rows = new_comment :: t.db.F.rows };
             Ok ()
       with _ -> Error `Error)

  let delete_comment t cid =
    let module F = Fake_db in
    Abb.Future.return
      (try
         let updated_rows =
           CCList.map
             (fun comment ->
               if comment.F.comment_id = cid then { comment with F.status = Deleted } else comment)
             t.db.F.rows
         in

         t.db <- { F.rows = updated_rows };
         Ok ()
       with _ -> Error `Error)

  let minimize_comment t cid =
    let module F = Fake_db in
    Abb.Future.return
      (try
         let updated_rows =
           CCList.map
             (fun comment ->
               if comment.F.comment_id = cid then { comment with F.status = Minimized } else comment)
             t.db.F.rows
         in

         t.db <- { F.rows = updated_rows };
         Ok ()
       with _ -> Error `Error)

  (* TODO: Set a comments status to minimized *)
  let post_comment _ _ = raise (Failure "nyi")

  (* TODO: Take the length out of an element content *)
  let rendered_length el = raise (Failure "nyi")
  let max_comment_length = 100
  let strategy t el = raise (Failure "nyi")
end

let test_basic =
  Oth_abb.test ~name:"Basic Flow" (fun () ->
      let module A = Fake_api in
      let module F = Fake_db in
      let module S = Synthetic in
      let module C = Terrat_vcs_comment.Make (Synthetic) in
      let t = { S.api = A.init (); S.db = F.init () } in
      let open Abb.Future.Infix_monad in
      C.run t [] >>= fun _ -> Abb.Future.return ())

let test = Oth_abb.(to_sync_test (parallel [ test_basic ]))

let () =
  Random.self_init ();
  Oth.run test
