include Snabela

let render_string ?(transformers = []) string kv =
  match Template.of_utf8_string string with
  | Ok tmpl -> apply (of_template tmpl transformers) kv
  | Error _ as err -> err
