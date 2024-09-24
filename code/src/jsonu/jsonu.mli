type to_yaml_string_err = Abb_process.check_output_err [@@deriving show]

type of_yaml_string_err =
  [ `Json_decode_err of string
  | `Unexpected_err
  | `Yaml_decode_err of string
  ]
[@@deriving show]

type merge_err = [ `Type_mismatch_err of string option * Yojson.Safe.t * Yojson.Safe.t ]
[@@deriving show]

val to_yaml_string : Yojson.Safe.t -> (string, [> to_yaml_string_err ]) result Abb.Future.t
val of_yaml_string : string -> (Yojson.Safe.t, [> of_yaml_string_err ]) result Abb.Future.t

(** [merge] takes a a starting json, [base], and merges another json, [override] on top of
    it.  The following rules are applied for merging:

    - If a key is in [base] and [override] and has a scalar type, the value from
      [override] is taken.

    - If a key is in [base] and [override] and it is a list then the items from
      [override] are prepended to the items in [base].

    - If a key is in [base] and [override] and it is a dictionary, [merge] is
      recursively applied.

    - If a key is in [base] and [override] and either has a value of [null],
      then the value from [override] is taken.

    - If a key is in [base] and [override] and no other rule applies, then a
      [`Type_mismatch_err key] is returned.

    - All keys from [override] are added to the result.


    Note that no deep merging of lists is performed.
 *)
val merge : base:Yojson.Safe.t -> Yojson.Safe.t -> (Yojson.Safe.t, [> merge_err ]) result
