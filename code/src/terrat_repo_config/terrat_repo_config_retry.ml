type t = {
  backoff : float; [@default 1.5]
  enabled : bool; [@default false]
  initial_sleep : int; [@default 5]
  tries : int; [@default 3]
}
[@@deriving yojson { strict = true; meta = true }, make, show]
