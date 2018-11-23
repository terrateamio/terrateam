module Make (Abb : Abb_intf.S ) : sig
  include Cohttp.S.IO
    with type 'a t = 'a Abb.Future.t
     and type ic = Abb_io_buffered.Make(Abb.Future).reader Abb_io_buffered.Make(Abb.Future).t
     and type oc = Abb_io_buffered.Make(Abb.Future).writer Abb_io_buffered.Make(Abb.Future).t
end
