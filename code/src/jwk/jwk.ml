module String_map = CCMap.Make (CCString)

module Key = struct
  type t = string String_map.t

  let get = String_map.get
end

type t = Key.t String_map.t

let get_kid = String_map.get

let of_string =
  CCOpt.wrap (fun s ->
      let json = Yojson.Basic.from_string s in
      let keys = Yojson.Basic.Util.(to_list (member "keys" json)) in
      CCListLabels.fold_left
        ~f:(fun acc k ->
          let kid = Yojson.Basic.Util.(to_string (member "kid" k)) in
          let assoc = Yojson.Basic.Util.to_assoc k in
          String_map.add
            kid
            (String_map.of_list
               (CCList.map
                  (fun (k, v) ->
                    let v = Yojson.Basic.Util.to_string v in
                    (k, v))
                  assoc))
            acc)
        ~init:String_map.empty
        keys)
