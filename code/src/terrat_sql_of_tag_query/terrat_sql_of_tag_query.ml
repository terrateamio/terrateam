type of_ast_err =
  [ `Error of string
  | `In_dir_not_supported
  | `Bad_date_format of string
  | `Unknown_tag of string
  ]
[@@deriving show]

module Tag_map = struct
  type t =
    | Bigint
    | Datetime
    | Int
    | Json_array of string
    | Json_obj of string
    | Smallint
    | String
    | Uuid
end

type t = {
  q : Buffer.t;
  strings : string CCVector.vector;
  smallints : int CCVector.vector;
  ints : int32 CCVector.vector;
  bigints : int64 CCVector.vector;
  json : string CCVector.vector;
  timezone : string;
  mutable sort_dir : [ `Asc | `Desc ];
}

let eq_json_array t n k v =
  CCVector.push t.json (Yojson.Safe.to_string (`List [ `Assoc [ (k, `String v) ] ]));
  Buffer.add_string t.q (Printf.sprintf "(%s @> (($json)[%d]::jsonb))" n (CCVector.size t.json));
  Ok ()

let eq_json_obj t n k v =
  CCVector.push t.json (Yojson.Safe.to_string (`Assoc [ (k, `String v) ]));
  Buffer.add_string t.q (Printf.sprintf "(%s @> (($json)[%d]::jsonb))" n (CCVector.size t.json));
  Ok ()

let eq_uuid t n v =
  CCVector.push t.strings v;
  Buffer.add_string t.q (Printf.sprintf "%s = ($strings)[%d]::uuid" n (CCVector.size t.strings));
  Ok ()

let eq_string t n = function
  | "" ->
      Buffer.add_string t.q (Printf.sprintf "(%s is null or %s = ''" n n);
      Ok ()
  | v ->
      CCVector.push t.strings v;
      Buffer.add_string t.q (Printf.sprintf "%s = ($strings)[%d]" n (CCVector.size t.strings));
      Ok ()

let eq_smallint t n v =
  match CCInt.of_string v with
  | Some v ->
      CCVector.push t.smallints v;
      Buffer.add_string t.q (Printf.sprintf "%s = ($smallints)[%d]" n (CCVector.size t.smallints));
      Ok ()
  | None -> Error (`Error v)

let eq_int t n v =
  match CCInt.of_string v with
  | Some v ->
      CCVector.push t.ints (CCInt32.of_int v);
      Buffer.add_string t.q (Printf.sprintf "%s = ($ints)[%d]" n (CCVector.size t.ints));
      Ok ()
  | None -> Error (`Error v)

let eq_bigint t n v =
  match CCInt64.of_string v with
  | Some v ->
      CCVector.push t.bigints v;
      Buffer.add_string t.q (Printf.sprintf "%s = ($bigints)[%d]" n (CCVector.size t.bigints));
      Ok ()
  | None -> Error (`Error v)

let lte_datetime t n v =
  CCVector.push t.strings v;
  Buffer.add_string
    t.q
    (Printf.sprintf
       "((to_timestamp(($strings)[%d], 'YYYY-MM-DD HH24:MI')::timestamp at time zone $tz) <= \
        created_at and created_at < now())"
       (CCVector.size t.strings));
  Ok ()

let gt_datetime t n v =
  CCVector.push t.strings v;
  Buffer.add_string
    t.q
    (Printf.sprintf
       "%s < (to_timestamp(($strings)[%d], 'YYYY-MM-DD HH24:MI')::timestamp at time zone $tz)"
       n
       (CCVector.size t.strings));
  Ok ()

let between_datetime t n l r =
  CCVector.push t.strings l;
  CCVector.push t.strings r;
  Buffer.add_string
    t.q
    (Printf.sprintf
       "((to_timestamp(($strings)[%d], 'YYYY-MM-DD HH24:MI')::timestamp at time zone $tz) <= %s \
        and %s < (to_timestamp(($strings)[%d], 'YYYY-MM-DD HH24:MI')::timestamp at time zone $tz))"
       (CCVector.size t.strings - 1)
       n
       n
       (CCVector.size t.strings));
  Ok ()

let eq_date t n v =
  CCVector.push t.strings v;
  Buffer.add_string
    t.q
    (Printf.sprintf
       "((to_timestamp(($strings)[%d], 'YYYY-MM-DD H24:MI')::timestamp at time zone $tz) <= %s and \
        %s < ((to_timestamp(($strings)[%d], 'YYYY-MM-DD HH24:MI')::timestamp at time zone $tz) + \
        interval '1 day'))"
       (CCVector.size t.strings)
       n
       n
       (CCVector.size t.strings));
  Ok ()

let eq_datetime t n v =
  CCVector.push t.strings v;
  Buffer.add_string
    t.q
    (Printf.sprintf
       "((to_timestamp(($strings)[%d], 'YYYY-MM-DD HH24:MI')::timestamp at time zone $tz) <= %s \
        and %s < (to_timestamp(($strings)[%d], 'YYYY-MM-DD HH24:MI')::timestamp at time zone $tz) \
        + interval '1 min')"
       (CCVector.size t.strings)
       n
       n
       (CCVector.size t.strings));
  Ok ()

let date_only s = not (CCString.contains s ' ')

let rec of_ast' ~tag_map t =
  let module T = Terrat_tag_query_parser_value in
  function
  | T.Tag tag -> (
      match CCString.Split.left ~by:":" tag with
      | None -> Error (`Unknown_tag tag)
      | Some ("sort", "asc") ->
          t.sort_dir <- `Asc;
          (* Cheap hack but we replace these meta attributes with [true]. *)
          Buffer.add_string t.q "true";
          Ok ()
      | Some ("sort", "desc") ->
          t.sort_dir <- `Desc;
          (* Cheap hack but we replace these meta attributes with [true]. *)
          Buffer.add_string t.q "true";
          Ok ()
      | Some (tag, value) -> (
          match CCList.Assoc.get ~eq:CCString.equal tag tag_map with
          | None -> Error (`Unknown_tag tag)
          | Some (Tag_map.Datetime, n) -> (
              match CCString.Split.left ~by:".." value with
              | Some ("", "") -> Error (`Bad_date_format value)
              | Some (v, "") -> lte_datetime t n v
              | Some ("", v) -> gt_datetime t n v
              | Some (l, r) -> between_datetime t n l r
              | None when date_only value -> eq_date t n value
              | None -> eq_datetime t n value)
          | Some (Tag_map.Bigint, n) -> eq_bigint t n value
          | Some (Tag_map.Int, n) -> eq_int t n value
          | Some (Tag_map.Smallint, n) -> eq_smallint t n value
          | Some (Tag_map.String, n) -> eq_string t n value
          | Some (Tag_map.Uuid, n) -> eq_uuid t n value
          | Some (Tag_map.Json_array k, n) -> eq_json_array t n k value
          | Some (Tag_map.Json_obj k, n) -> eq_json_obj t n k value))
  | T.Or (l, r) ->
      let open CCResult.Infix in
      Buffer.add_char t.q '(';
      of_ast' ~tag_map t l
      >>= fun () ->
      Buffer.add_string t.q ") or (";
      of_ast' ~tag_map t r
      >>= fun () ->
      Buffer.add_char t.q ')';
      Ok ()
  | T.And (l, r) ->
      let open CCResult.Infix in
      Buffer.add_char t.q '(';
      of_ast' ~tag_map t l
      >>= fun () ->
      Buffer.add_string t.q ") and (";
      of_ast' ~tag_map t r
      >>= fun () ->
      Buffer.add_char t.q ')';
      Ok ()
  | T.Not e ->
      let open CCResult.Infix in
      Buffer.add_string t.q "not (";
      of_ast' ~tag_map t e
      >>= fun () ->
      Buffer.add_char t.q ')';
      Ok ()
  | T.In_dir _ -> Error `In_dir_not_supported

let empty ?(timezone = "UTC") ?(sort_dir = `Asc) () =
  {
    q = Buffer.create 50;
    strings = CCVector.create ();
    smallints = CCVector.create ();
    ints = CCVector.create ();
    bigints = CCVector.create ();
    json = CCVector.create ();
    timezone;
    sort_dir;
  }

let of_ast ?timezone ?sort_dir ~tag_map ast =
  let t = empty ?timezone ?sort_dir () in
  let open CCResult.Infix in
  of_ast' ~tag_map t ast >>= fun () -> Ok t

let sql t = Buffer.contents t.q
let bigints t = CCVector.to_list t.bigints
let ints t = CCVector.to_list t.ints
let json t = CCVector.to_list t.json
let smallints t = CCVector.to_list t.smallints
let strings t = CCVector.to_list t.strings
let timezone t = t.timezone
let sort_dir t = t.sort_dir
