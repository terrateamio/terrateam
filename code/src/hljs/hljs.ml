module Opts = struct
  type t = { language : string }

  let make ~language () = { language }
end

let highlight opts code =
  let hljs = Jv.get Jv.global "hljs" in
  let opts_js = Jv.obj Jv.[| ("language", of_string opts.Opts.language) |] in
  let ret = Jv.call hljs "highlight" [| Jv.of_string code; opts_js |] in
  Jv.to_string (Jv.get ret "value")
