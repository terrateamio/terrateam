type input = {
  dirspace : string;
  is_error : bool;
  content : string;
}

type settings = {
  max_length : int;
  max_requests : int;
}

type strategy =
  | Append
  | Delete
  | Minimize

(* Use better ID types than 'string' *)
type output = {
  id : string;
  index : int;
  dirspace : string;
  (* Replace this boolean value with DU *)
  is_error : bool;
  content : string;
}

module type Protocol = sig
  type i
  type s
  type st
  type 'a t

  (** Breaks a sigle input into one or more chunks *)
  val break : s -> i -> 'a t

  (** Combines multiple inputs while respecting a particular strategy. *)
  val combine : s -> st -> i list -> 'a t

  (** Queries an output with certain id, sorted by the indexes *)
  val query : string -> 'a t

  (** Publishes an output *)
  val publish : string -> unit
end

module Make :
  Protocol
    with type i = input
     and type s = settings
     and type st = strategy
     and type 'a t = output list = struct
  type i = input
  type s = settings
  type st = strategy
  type 'a t = output list

  let break settings (input : input) =
    let limit = settings.max_length in
    let id = Ouuid.to_string (Ouuid.v4 ()) in
    let rec loop id dirspace is_error content index acc =
      if CCString.length content <= limit then
        let o : output = { id; index; dirspace; is_error; content } in
        acc @ [ o ]
      else
        let part = CCString.sub content 0 limit in
        let o : output = { id; index; dirspace; is_error; content = part } in
        let updated = acc @ [ o ] in
        loop id dirspace is_error (CCString.drop limit content) (index + 1) updated
    in
    loop id input.dirspace input.is_error input.content 1 []

  let combine settings strategy inputs =
    let compare (a : output) (b : output) =
      let id_cmp = String.compare a.id b.id in
      let error_cmp = Bool.compare a.is_error b.is_error in
      let dirspace_cmp = String.compare a.dirspace b.dirspace in
      let index_cmp = Int.compare a.index b.index in

      match (id_cmp, error_cmp, dirspace_cmp, index_cmp) with
      | id, _, _, _ when id <> 0 -> id
      | _, err, _, _ when err <> 0 -> err
      | _, _, dir, _ when dir <> 0 -> dir
      | _, _, _, idx when idx <> 0 -> idx
      | _ -> -1
    in
    let out =
      match strategy with
      | Append -> CCList.flat_map (break settings) inputs
      | Delete -> []
      | Minimize -> []
    in
    CCList.sort compare out

  let query _ = []
  let publish _ = ()
end

(*
#require "containers";;
#require "uuidm";;
#mod_use "src/ouuid/ouuid.ml";;
#mod_use "src/comment/comment.ml";;
open Comment;;

let s = Settings.{ max_length = 10; max_requests = 3};;
let st = Strategy.Append;;
let c1 = CCString.init 15 (fun _ -> 'a') ^ CCString.init 15 (fun _ -> 'b') ^ CCString.init 17 (fun _ -> 'c');;
let i1 = ("a", c1, true);;
module P = Make(Output)(Settings)(Strategy);;
P.break s i1;;
let i2 = [("a", CCString.init 5 (fun _ -> 'a'), true); ("b", CCString.init 15 (fun _ -> 'b'), false); ("c", CCString.init 17 (fun _ -> 'c'), true)];;
P.combine s st i2;;
*)
