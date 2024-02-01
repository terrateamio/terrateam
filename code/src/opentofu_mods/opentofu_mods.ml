module Module = struct
  type t = {
    name : string;
    source : string;
  }

  let make ~name ~source () = { name; source }
  let name t = t.name
  let source t = t.source

  let is_source_local_path t =
    CCString.prefix ~pre:"./" t.source || CCString.prefix ~pre:"../" t.source
end

let rec walk mods =
  let module Hpv = Hcl_parser_value in
  function
  | Hpv.Attribute (_, _) -> mods
  | Hpv.(Block { type_ = "module"; labels = Hpv.Block_label.Lit name :: _; body }) ->
      CCList.fold_left (fun mods body -> walk_mod_body mods name body) mods body
  | Hpv.(Block { body; _ }) -> CCList.fold_left (fun mods body -> walk mods body) mods body

and walk_mod_body mods name =
  let module Hpv = Hcl_parser_value in
  function
  | Hpv.Attribute ("source", Hpv.Expr.String source) -> Module.make ~name ~source () :: mods
  | Hpv.Attribute (_, _) -> mods
  | Hpv.Block _ -> mods

let collect_modules hcl = CCList.fold_left (fun acc ast -> walk acc ast) [] hcl
