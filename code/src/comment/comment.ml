module Settings = struct
  type t = {
    limit: int;
    max_requests: int;
  }
end

module Strategy = struct
  type t =
    | Append
    | Delete
    | Minimize
end

(* TODO: Find a better name for this *)
module Output = struct
  type t = {
    title: string;
    subtitle: string;
    content: string;
  }
end

(* TODO: Make Settings a module's argument *)
module type Protocol = sig
  (* Breaks larger content into smaller chunks, each chunk
     shares the original's ID, so it is assembled back
     later. *)
  (* TODO: The ID will be moved later to a record type *)
  val break : string -> Settings.t -> string -> string list

  val combine : Settings.t -> string list -> string list
end

module Make : Protocol = struct
  let break id settings output =
    let rec loop remaining id acc =
      let limit = settings.Settings.limit in
      let len = CCString.length remaining in
      if len <= limit then
        CCList.append acc [remaining]
      else
        let part = CCString.sub remaining 0 limit in
        loop (CCString.drop limit remaining) id (CCList.append acc [part])
    in
    loop output id []

  let combine settings outputs = CCList.flat_map (break "ID" settings) outputs
end

(*
#require "containers";;
#mod_use "src/comment/comment.ml";;
open Comment;;

let s = Settings.{ limit = 10; max_requests = 10; };;
let input1 = CCString.init 15 (fun _ -> 'a') ^ CCString.init 15 (fun _ -> 'b') ^ CCString.init 17 (fun _ -> 'c');;
Make.break "ID" s input1;;
let input2 = [CCString.init 5 (fun _ -> 'a')] @ [CCString.init 15 (fun _ -> 'b')] @ [CCString.init 17 (fun _ -> 'c')];;
Make.combine s input2;;
*)
