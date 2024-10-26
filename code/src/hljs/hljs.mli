module Opts : sig
  type t

  val make : language:string -> unit -> t
end

val highlight : Opts.t -> string -> string
