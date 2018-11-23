module Make(Abb: Abb_intf.S with type Native.t = Unix.file_descr) : sig
  val create : unit -> Brtl.Make(Abb).Mw.Mw.t
end
