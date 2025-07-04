module Oth_abb = Oth_abb.Make (Abb)
module El_set = Set.Make (Int)

module Fake_db = struct
  type db_comment = {
    id : int;
    elements : El_set.t;
    index : int;
    content : string;
    strategy : Terrat_vcs_comment.Strategy.t;
  }

  type db_element = {
    id : int;
    content : string;
    is_error : bool;
    dirspace : string;
  }

  type db = {
    mutable comments : db_comment list;
    mutable elements : db_element list;
  }

  let init () = { comments = []; elements = [] }
  let find_by_comment_id db id = CCList.find_opt (fun (c : db_comment) -> c.id = id) db.comments

  let find_by_element_id db id =
    CCList.find_opt (fun (c : db_comment) -> El_set.mem id c.elements) db.comments

  let fetch_elements db (c : db_comment) =
    CCList.filter (fun (e : db_element) -> El_set.mem e.id c.elements) db.elements

  let insert_comment db comment = db.comments <- comment :: db.comments

  let update_comment db id (f : db_comment -> db_comment) =
    let cs = CCList.map (fun (c : db_comment) -> if c.id = id then f c else c) db.comments in
    db.comments <- cs

  let update_comment_elements db id els =
    update_comment db id (fun c -> { c with elements = El_set.union els c.elements })

  let update_comment_strategy db id st = update_comment db id (fun c -> { c with strategy = st })
end

module Fake_api = struct
  type vcs_comment = {
    id : int;
    index : int;
    content : string;
    strategy : Terrat_vcs_comment.Strategy.t;
  }

  type api = {
    mutable comments : vcs_comment list;
    mutable next_id : int;
  }

  let init () = { comments = []; next_id = 1 }

  let next api =
    let n = api.next_id in
    api.next_id <- api.next_id + 1;
    n

  let add api c = api.comments <- c :: api.comments

  let show api =
    let module C = Terrat_vcs_comment in
    CCList.filter (fun c -> c.strategy <> C.Strategy.Delete) api.comments
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
    is_error : bool;
    dirspace : string;
  }

  type comment_id = int

  let query_comment_id t el =
    let module F = Fake_db in
    Abb.Future.return
      (match F.find_by_element_id t.db el.id with
      | Some c -> Ok (Some c.F.id)
      | None -> Ok None)

  let query_els_for_comment_id t comment_id =
    let module F = Fake_db in
    Abb.Future.return
      (match F.find_by_comment_id t.db comment_id with
      | Some c ->
          let els =
            F.fetch_elements t.db c
            |> CCList.map (fun (e : F.db_element) ->
                   { id = e.id; content = c.content; is_error = e.is_error; dirspace = e.dirspace })
          in
          Ok els
      | None -> Ok [])

  let upsert_comment_id t els cid =
    let open Abb.Future.Infix_monad in
    let module A = Fake_api in
    let module F = Fake_db in
    Abb.Future.return
      (let eids = CCList.map (fun el -> el.id) els |> El_set.of_list in
       let content = CCString.concat "\n" (CCList.map (fun el -> el.content) els) in
       match F.find_by_comment_id t.db cid with
       | Some _ ->
           F.update_comment_elements t.db cid eids;
           Ok ()
       | None ->
           let id = A.next t.api in
           let c =
             F.
               {
                 id;
                 elements = eids;
                 index = 1;
                 content;
                 strategy = Terrat_vcs_comment.Strategy.Append;
               }
           in
           F.insert_comment t.db c;
           Ok ())

  let delete_comment t cid =
    let module C = Terrat_vcs_comment in
    let module F = Fake_db in
    Abb.Future.return
      (try
         F.update_comment_strategy t.db cid C.Strategy.Delete;
         Ok ()
       with _ -> Error `Error)

  let minimize_comment t cid =
    let module C = Terrat_vcs_comment in
    let module F = Fake_db in
    Abb.Future.return
      (try
         F.update_comment_strategy t.db cid C.Strategy.Minimize;
         Ok ()
       with _ -> Error `Error)

  let post_comment t els =
    let open Abb.Future.Infix_monad in
    let module C = Terrat_vcs_comment in
    let module F = Fake_db in
    let module A = Fake_api in
    let id = t.api.A.next_id in
    let content = CCString.concat "\n" (CCList.map (fun el -> el.content) els) in
    let c : A.vcs_comment = { id; content; index = 0; strategy = C.Strategy.Append } in
    A.add t.api c;
    Abb.Future.return (Ok id)

  let rendered_length el = CCString.length el.content
  let content el = el.content
  let dirspace el = el.dirspace
  let is_from_error_report el = el.is_error

  let strategy t el =
    let module F = Fake_db in
    Abb.Future.return
      (match F.find_by_element_id t.db el.id with
      | Some c -> Ok c.F.strategy
      | None -> Error `Error)

  let max_comment_length = 100
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
