module Check = struct
  type users_per_month = {
    users : string list;
    limit : int;
  }
  [@@deriving show]

  type t = {
    tier_name : string;
    users_per_month : users_per_month;
  }
  [@@deriving show]
end

module Retention = struct
  type t = { runs : int [@default CCInt.max_int] } [@@deriving make, show, eq, yojson]
end

type t = {
  num_users_per_month : int; [@default CCInt.max_int]
  retention_days : Retention.t; [@default Retention.make ()]
}
[@@deriving show, eq, yojson]
