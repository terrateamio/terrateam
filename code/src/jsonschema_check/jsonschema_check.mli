module Validation_err : sig
  type t = {
    msg : string;
    path : string;
  }
  [@@deriving show]
end

val validate_json_schema : schema:string -> string -> (unit, Validation_err.t list) result
