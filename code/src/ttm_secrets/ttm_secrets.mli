module Mask : sig
  val do_mask :
    secrets:string list ->
    unmask:string list ->
    mask:Bytes.t ->
    fin:(Bytes.t -> int -> int -> int) ->
    fout:(Bytes.t -> int -> int -> unit) ->
    unit ->
    unit
end

val cmd : unit Cmdliner.Term.t -> unit Cmdliner.Cmd.t
