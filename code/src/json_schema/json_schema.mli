module String_map : module type of CCMap.Make (CCString)

module Format : sig
  module Uri : sig
    type t = Uri.t [@@deriving yojson, show]
  end

  module Uritmpl : sig
    type t = Uritmpl.t [@@deriving yojson, show]
  end

  module Date_time : sig
    type t = float [@@deriving yojson, show]
  end
end

(** This serializes into a Yojson.Safe.t but guarantees that the it's an object,
   not a scalar such as [string] or [int] *)
module Obj : sig
  type t = Yojson.Safe.t [@@deriving yojson, show]
end

(** Represents an object with no elements to be serialized/deserialized.  This
   does not ensure that the object is empty, just that the any object is
   accepted and none of its attributes are serialized/deserialized. *)
module Empty_obj : sig
  type t [@@deriving yojson, show]

  module Yojson_meta : sig
    val keys : string list
  end
end

(** Represents an object to be validated that has additional properties.  It is
   broken up into two parts: the known portions of the object and the additional
   fields, which must match some schema.  The primary portion must have the JSON
   meta data in order to know what the keys are such that they can be avoided in
   decoding the additional parts. *)
module Additional_properties : sig
  module type Primary = sig
    type t [@@deriving yojson, show]

    module Yojson_meta : sig
      val keys : string list
    end
  end

  module type Additional = sig
    type t [@@deriving yojson, show]
  end

  module Make (P : Primary) (A : Additional) : sig
    type t [@@deriving yojson, show]

    val value : t -> P.t

    val additional : t -> A.t String_map.t
  end
end

val one_of : (Yojson.Safe.t -> ('a, string) result) list -> Yojson.Safe.t -> ('a, string) result

val any_of : (Yojson.Safe.t -> ('a, string) result) list -> Yojson.Safe.t -> ('a, string) result
