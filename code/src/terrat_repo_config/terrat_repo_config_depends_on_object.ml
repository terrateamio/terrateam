type t = {
  prune_on_no_change : bool; [@default false]
  tag_query : string;
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
