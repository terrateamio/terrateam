module type Settings = sig
  type t = {
    max_length: int;
    max_requests : int;
  }

  val default : unit -> t
end

module GithubSettings : Settings = struct
  type t = {
    max_length: int;
    max_requests : int;
  }

  let default () = { max_length = 10; max_requests = 3}
end

module type Strategy = sig
  type t =
    | Append
    | Delete
    | Minimize

  val supported: unit -> t list
end

module GithubStrategy : Strategy = struct
  type t =
    | Append
    | Delete
    | Minimize

  let supported () = [ Append ]
end

module type Output = sig
  type t = {
    id : string;
    index: int;
    content : string;
  }
end

module Output : Output = struct
  type t = {
    id : string;
    index: int;
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
  val break : S.t -> input -> O.t t

  (** Combines multiple outputs while respecting a
      particular strategy. *)
  val combine : S.t -> St.t -> O.t t -> O.t t
end

module Make (O : Output) (S : Settings) (St : Strategy) : Protocol with
  module S = S and
  module St = St and
  type input = string and
  type 'a t = O.t list = struct

  module S = S
  module St = St
  module O = O

  type input = string
  type 'a t = O.t list

  let break settings i =
    let id = Ouuid.to_string (Ouuid.v4 ()) in
    let limit = settings.S.max_length in
    let rec loop remaining index acc =
      if CCString.length remaining <= limit then 
        let o: O.t = { id; index; content = remaining } in
        acc @ [ o ]
      else
        let part = CCString.sub remaining 0 limit in
        let o: O.t = { id; index; content = part } in
        let updated = acc @ [ o ] in
        loop (CCString.drop limit remaining) (index + 1) updated
    in
    loop i 1 []

  let combine settings strategy outputs =
    match strategy with
    | St.Append -> []
    | St.Delete -> []
    | St.Minimize -> []
end

(*
#require "containers";;
#require "uuidm";;
#mod_use "src/ouuid/ouuid.ml";;
#mod_use "src/comment/comment.ml";;
open Comment;;

let s = GithubSettings.default();;
let c1 = CCString.init 15 (fun _ -> 'a') ^ CCString.init 15 (fun _ -> 'b') ^ CCString.init 17 (fun _ -> 'c');;
module Github_protocol = Make(Output)(GithubSettings)(GithubStrategy);;
Github_protocol.break s c1;;
let input2 = [CCString.init 5 (fun _ -> 'a')] @ [CCString.init 15 (fun _ -> 'b')] @ [CCString.init 17 (fun _ -> 'c')];;
Make.combine s input2;;
*)
