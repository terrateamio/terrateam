module type Settings = sig
  type t = {
    max_length : int;
    max_requests : int;
  }
end

module Settings : Settings = struct
  type t = {
    max_length : int;
    max_requests : int;
  }
end

module type Strategy = sig
  type t =
    | Append
    | Delete
    | Minimize
end

module Strategy : Strategy = struct
  type t =
    | Append
    | Delete
    | Minimize
end

module type Output = sig
  (* Use better ID types than 'string' *)
  type t = {
    id : string;
    index : int;
    dirspace: string;
    (* Replace this boolean value with DU *)
    is_error: bool;
    content : string;
  }
end

module Output : Output = struct
  type t = {
    id : string;
    index : int;
    dirspace: string;
    is_error: bool;
    content : string;
  }
end

module type Protocol = sig
  module O : Output
  module S : Settings
  module St : Strategy

  type input
  type 'a t

  (** Breaks a sigle input into one or more chunks *)
  val break : S.t -> input -> 'a t

  (** Combines multiple inputs while respecting a particular strategy. *)
  val combine : S.t -> St.t -> input list -> 'a t

  (** Queries an output with certain id, sorted by the indexes *)
  val query: string -> 'a t

  (** Publishes an output *)
  val publish: string -> unit
end

module Make (O : Output) (S : Settings) (St : Strategy) :
  Protocol with module S = S and module St = St and type input = string * string * bool and type 'a t = O.t list =
struct
  module S = S
  module St = St
  module O = O

  type input = string * string * bool
  type 'a t = O.t list

  let break settings (dirspace, i, is_error) =
    let id = Ouuid.to_string (Ouuid.v4 ()) in
    let limit = settings.S.max_length in
    let rec loop remaining index acc =
      if CCString.length remaining <= limit then
        let o : O.t = { id; index; dirspace; is_error; content = remaining } in
        acc @ [ o ]
      else
        let part = CCString.sub remaining 0 limit in
        let o : O.t = { id; index; dirspace; is_error; content = part } in
        let updated = acc @ [ o ] in
        loop (CCString.drop limit remaining) (index + 1) updated
    in
    loop i 1 []

  let combine settings strategy inputs =
    match strategy with
    | St.Append -> CCList.flat_map (break settings) inputs
    | St.Delete -> []
    | St.Minimize -> []
    |> CCList.sort (fun (a: O.t) (b: O.t) -> (Bool.compare a.is_error b.is_error) + Int.abs(a.index - b.index))

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
module P = Make(Output)(Settings)(Strategy);;
P.break s c1;;
let c2 = [CCString.init 5 (fun _ -> 'a')] @ [CCString.init 15 (fun _ -> 'b')] @ [CCString.init 17 (fun _ -> 'c')];;
P.combine s st c2;;
*)
