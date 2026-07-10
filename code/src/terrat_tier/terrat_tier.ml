module Check = struct
  type users_per_month = {
    users : string list;
    limit : int;
  }
  [@@deriving show]

  type runs_per_month = {
    used : int;
    limit : int;
  }
  [@@deriving show]

  type t = {
    tier_name : string;
    users_per_month : users_per_month option;
    runs_per_month : runs_per_month option;
  }
  [@@deriving show]
end

module Retention = struct
  type t = { runs : int [@default CCInt.max_int] }
  [@@deriving make, show, eq, yojson { strict = false }]
end

(* Features are stored as jsonb in the tiers table and rows are added in
   production ahead of code deploys, so parsing must ignore unknown fields. *)
type t = {
  num_users_per_month : int; [@default CCInt.max_int]
  runs_per_month : int; [@default CCInt.max_int]
  private_runners : int; [@default CCInt.max_int]
  retention_days : Retention.t; [@default Retention.make ()]
}
[@@deriving show, eq, yojson { strict = false }]
