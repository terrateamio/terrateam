module type ID = sig
  type t [@@deriving yojson, eq, show]

  val of_string : string -> t option
  val to_string : t -> string
end

module type Settings = sig
  type t = {
    limit : int;
    max_requests : int;
  }
end

module type Strategy = sig
  type t =
    | Append
    | Delete
    | Minimize
end

(* TODO: Find a better name for this *)
module Output = struct
  type t = {
    title : string;
    subtitle : string;
    content : string;
  }
end

(* TODO: Make Settings a module's argument *)
module type Protocol = sig
  module Id : ID
  module S : Settings
  module St : Strategy

  val break : Id.t -> S.t -> string -> string list
  val combine : S.t -> string list -> string list
end

module Make (I : ID) (S : Settings) (St : Strategy) :
  Protocol with module Id = I and module S = S and module St = St = struct
  module Id = I
  module S = S
  module St = St

  let break id settings output =
    let rec loop remaining id acc =
      let limit = settings.S.limit in
      let len = CCString.length remaining in
      if len <= limit then CCList.append acc [ remaining ]
      else
        let part = CCString.sub remaining 0 limit in
        loop (CCString.drop limit remaining) id (CCList.append acc [ part ])
    in
    loop output id []

  let combine settings outputs =
    let id =
      match Id.of_string "test" with
      | Some id -> id
      | None -> failwith "Could not create ID"
    in
    CCList.flat_map (break id settings) outputs
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
