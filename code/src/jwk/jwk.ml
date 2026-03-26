module Key = struct
  type t = string Sln_map.String.t

  let get = Sln_map.String.get
end

type t = Key.t Sln_map.String.t

let get_kid = Sln_map.String.get

let of_string =
  CCOption.wrap (fun s ->
      let json = Yojson.Basic.from_string s in
      let keys = Yojson.Basic.Util.(to_list (member "keys" json)) in
      CCListLabels.fold_left
        ~f:(fun acc k ->
          let kid = Yojson.Basic.Util.(to_string (member "kid" k)) in
          let assoc = Yojson.Basic.Util.to_assoc k in
          Sln_map.String.add
            kid
            (Sln_map.String.of_list
               (CCList.map
                  (fun (k, v) ->
                    let v = Yojson.Basic.Util.to_string v in
                    (k, v))
                  assoc))
            acc)
        ~init:Sln_map.String.empty
        keys)
