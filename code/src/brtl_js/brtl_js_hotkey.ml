open Js_of_ocaml

module Key_combo = struct
  include CCSet.Make (CCString)
end

module Key_map = struct
  include CCMap.Make (Key_combo)
end

let valid_keys = "abcdefghijklmnipqrstuvwxyz0123456789!@#$%^&*()=-+_/?.,><';\":][}{\\|"

let all_modifiers = Key_combo.of_list [ "Alt"; "Shift"; "Ctrl"; "Meta" ]

let ignore_elements = [ "INPUT"; "TEXTAREA"; "SELECT" ]

let map_key event =
  Js.Optdef.case
    event##.key
    (fun () -> None)
    (fun v ->
      match Js.to_string v##toLowerCase with
        | k when CCString.length k = 1 && CCString.contains valid_keys k.[0] -> Some k
        | " " -> Some "Space"
        | "Up" | "ArrowUp" -> Some "ArrowUp"
        | "Down" | "ArrowDown" -> Some "ArrowDown"
        | "Left" | "ArrowLeft" -> Some "ArrowLeft"
        | "Right" | "ArrowRight" -> Some "ArrowRight"
        | _ -> None)

let map_modifiers event =
  CCList.flatten
    [
      ( if Js.to_bool event##.altKey then
        [ "Alt" ]
      else
        [] );
      ( if Js.to_bool event##.shiftKey then
        [ "Shift" ]
      else
        [] );
      ( if Js.to_bool event##.ctrlKey then
        [ "Ctrl" ]
      else
        [] );
      ( if Js.to_bool event##.metaKey then
        [ "Meta" ]
      else
        [] );
    ]

let is_ignored_target event =
  Js.Opt.case
    event##.target
    (fun () -> false)
    (fun target -> CCList.mem ~eq:CCString.equal (Js.to_string target##.tagName) ignore_elements)

let onkeydown peak_keys current_keys (event : Dom_html.keyboardEvent Js.t) =
  if not (is_ignored_target event) then
    match (map_key event, map_modifiers event) with
      | (Some key, modifiers) ->
          let ks = Key_combo.of_list (key :: modifiers) in
          peak_keys := Key_combo.union !peak_keys ks;
          Js._true
      | _                     -> Js._true
  else
    Js._true

let onkeyup f peak_keys current_keys (event : Dom_html.keyboardEvent Js.t) =
  if not (is_ignored_target event) then
    match (map_key event, map_modifiers event) with
      | (Some k, modifiers) ->
          let keys_diff = Key_combo.(remove k (diff all_modifiers (of_list modifiers))) in
          current_keys := Key_combo.diff !current_keys keys_diff;
          if Key_combo.is_empty !current_keys then (
            let pk = !peak_keys in
            peak_keys := Key_combo.empty;
            current_keys := Key_combo.empty;
            Abb_js.Future.run (f pk)
          );
          Js._true
      | _                   -> Js._true
  else
    Js._true

let create f =
  let peak_keys = ref Key_combo.empty in
  let current_keys = ref Key_combo.empty in
  Dom_html.document##.onkeydown := Dom_html.handler (onkeydown peak_keys current_keys);
  Dom_html.document##.onkeyup := Dom_html.handler (onkeyup f peak_keys current_keys)
