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
	] [@@deriving sexp]

	type t = {
	  s_scheme: string sexp_option;
	  s_userinfo: string sexp_option;
	  s_host: string sexp_option;
	  s_port: int sexp_option;
	  s_path: string;
	  s_query: (string * string list) list;
	  s_fragment: string sexp_option
	} [@@deriving sexp]

end

open Derived

let component_of_sexp = component_of_sexp
let sexp_of_component = sexp_of_component

let t_of_sexp sexp =
	let t = t_of_sexp sexp in
	Uri.make
		?scheme:t.s_scheme
		?userinfo:t.s_userinfo
		?host:t.s_host
		?port:t.s_port
		~path:t.s_path
		~query:t.s_query
		?fragment:t.s_fragment
		()

let sexp_of_t t =
	sexp_of_t {
		s_scheme = scheme t;
		s_userinfo = userinfo t;
		s_host = host t;
		s_port = port t;
		s_path = path t;
		s_query = query t;
		s_fragment = fragment t
	}
