external minijinja_render_template :
  string -> string -> (string, string) result
  = "caml_minijinja_render_template"

(* Main template rendering function *)
let render_template template_str json =
  let json_str = Yojson.Safe.to_string json in
  minijinja_render_template template_str json_str
