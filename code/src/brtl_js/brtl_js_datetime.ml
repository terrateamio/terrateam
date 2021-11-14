module Js = Js_of_ocaml.Js

type t = Js.date Js.t

let millisecond_day = 24.0 *. 60.0 *. 60.0 *. 1000.0

let constr = Js.Unsafe.global##._Date

let of_str_constr : (Js.js_string Js.t -> Js.date Js.t) Js.constr = constr

let of_string s = new%js of_str_constr (Js.string s)

let to_iso_string t = Js.to_string t##toISOString

let to_hh_mm d = Printf.sprintf "%02d:%02d" d##getHours d##getMinutes

let to_yyyy_mm_dd_hh_mm d =
  Printf.sprintf
    "%04d-%02d-%02d %02d:%02d"
    d##getFullYear
    (d##getMonth + 1)
    d##getDate
    d##getHours
    d##getMinutes

let to_yyyy_mm_dd d = Printf.sprintf "%04d-%02d-%02d" d##getFullYear (d##getMonth + 1) d##getDate

let to_yyyy_mm d = Printf.sprintf "%04d-%02d" d##getFullYear (d##getMonth + 1)

let rec range from until =
  if from##getTime < until##getTime then
    from :: range (new%js Js.date_fromTimeValue (from##getTime +. millisecond_day)) until
  else
    []

let add_milliseconds d ms = new%js Js.date_fromTimeValue (d##getTime +. ms)

let now () = new%js Js.date_now

let get_time d = d##getTime

let set_hours t hours = ignore (t##setHours hours)

let set_minutes t minutes = ignore (t##setMinutes minutes)
