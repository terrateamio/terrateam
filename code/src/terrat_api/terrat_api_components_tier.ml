module Features = struct
  type t = { num_users_per_month : int option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  features : Features.t;
  name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
