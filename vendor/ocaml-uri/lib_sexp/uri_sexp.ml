open Uri

module Derived =
struct

	open Sexplib0.Sexp_conv

	type component = [
	  | `Scheme
	  | `Authority
	  | `Userinfo (* subcomponent of authority in some schemes *)
	  | `Host (* subcomponent of authority in some schemes *)
	  | `Path
	  | `Query
	  | `Query_key
	  | `Query_value
	  | `Fragment
          | `Generic
          | `Custom of (component * string * string)
	] [@@deriving sexp]

	type t = {
          scheme: string option [@default None] [@sexp_drop_default.sexp];
          userinfo: string option [@default None] [@sexp_drop_default.sexp];
          host: string option [@default None] [@sexp_drop_default.sexp];
          port: int option [@default None] [@sexp_drop_default.sexp];
          path: string [@default ""] [@sexp_drop_default.sexp];
          query: (string * string list) list [@sexp.list];
          fragment: string option [@default None] [@sexp_drop_default.sexp]
	} [@@deriving sexp]

end

open Derived

let component_of_sexp = component_of_sexp
let sexp_of_component = sexp_of_component

let t_of_sexp sexp =
	let t = t_of_sexp sexp in
	Uri.make
		?scheme:t.scheme
		?userinfo:t.userinfo
		?host:t.host
		?port:t.port
		~path:t.path
		~query:t.query
		?fragment:t.fragment
		()

let sexp_of_t t =
	sexp_of_t {
		scheme = scheme t;
		userinfo = userinfo t;
		host = host t;
		port = port t;
		path = path t;
		query = query t;
		fragment = fragment t
	}

type component = Uri.component
let compare a b = Uri.compare a b
let equal a b = Uri.equal a b
type t = Uri.t
