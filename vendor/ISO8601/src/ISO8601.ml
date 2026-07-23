module Lexer = ISO8601_lexer

module Permissive = struct

    let date_lex lexbuf = Lexer.date lexbuf

    let time_tz_lex lexbuf =
      let t = Lexer.time lexbuf in
      let tz = Lexer.timezone lexbuf in
      let t = match tz with None -> t | Some o -> t -. o in
      (t, tz)

    let datetime_tz_lex ?(reqtime=true) lexbuf =
      let d = date_lex lexbuf in
      match Lexer.delim lexbuf with
      | None -> if reqtime then assert false else (d, None)
      | Some _ -> let (t, tz) = time_tz_lex lexbuf in
                  (d +. t, tz)

    let time_lex lexbuf =
      fst (time_tz_lex lexbuf)

    let datetime_lex ?(reqtime=true) lexbuf =
      fst (datetime_tz_lex ~reqtime:reqtime lexbuf)

    let date s = date_lex (Lexing.from_string s)

    let time s = time_lex (Lexing.from_string s)

    let time_tz s = time_tz_lex (Lexing.from_string s)

    let datetime_tz ?(reqtime=true) s =
      datetime_tz_lex ~reqtime:reqtime (Lexing.from_string s)

    let datetime ?(reqtime=true) s =
      datetime_lex ~reqtime:reqtime (Lexing.from_string s)

    (* FIXME: possible loss of precision. *)
    let pp_format fmt format x tz =

      let open Unix in
      let open Format in

      (* Be careful, do not forget to print timezone if there is one,
       * or information printed will be wrong. *)
      let x = gmtime (x -. tz) in

      let conversion =
        let pad2 = fprintf fmt "%02d" in
        let pad4 = fprintf fmt "%04d" in
        function

        (* Date *)
        | 'Y' -> pad4 (x.tm_year + 1900)
        | 'M' -> pad2 (x.tm_mon + 1)
        | 'D' -> pad2 x.tm_mday

        (* Time *)
        | 'h' -> pad2 x.tm_hour
        | 'm' -> pad2 x.tm_min
        | 's' -> pad2 x.tm_sec

        (* Timezone *)
        | 'Z' -> fprintf fmt "%0+3.0f" (tz /. 3600.) (* Hours *)
        | 'z' -> fprintf fmt "%02.0f" (mod_float (abs_float (tz /. 60.)) 60.0) (* Minutes *)

        | '%' -> pp_print_char fmt '%'
        |  c  -> failwith ("Bad format: %" ^ String.make 1 c)

      in

      let len = String.length format in
      let rec parse_format i =
        if i = len then ()
        else match String.get format i with
             | '%' -> conversion (String.get format (i + 1)) ;
                      parse_format (i + 2)
             |  c  -> pp_print_char fmt c ;
                      parse_format (i + 1) in

      parse_format 0

    let pp_date fmt x = pp_format fmt "%Y-%M-%D" x 0.

    let pp_time fmt x = pp_format fmt "%h:%m:%s" x 0.

    let pp_datetime fmt x = pp_format fmt "%Y-%M-%DT%h:%m:%s" x 0.

    let pp_datetimezone fmt (x, tz) =
      pp_format fmt "%Y-%M-%DT%h:%m:%s%Z:%z" x tz

    let pp_date_basic fmt x = pp_format fmt "%Y%M%D" x 0.

    let pp_time_basic fmt x = pp_format fmt "%h%m%s" x 0.

    let pp_datetime_basic fmt x = pp_format fmt "%Y%M%DT%h%m%s" x 0.

    let pp_datetimezone_basic fmt (x, tz) =
      pp_format fmt "%Y%M%DT%h%m%s%Z%z" x tz

    let string_of_aux printer x =
      let buf = Buffer.create 32 in
      let fmt = Format.formatter_of_buffer buf in
      printer fmt x ;
      Format.pp_print_flush fmt () ;
      Buffer.contents buf

    let string_of_date = string_of_aux pp_date

    let string_of_time = string_of_aux pp_time

    let string_of_datetime = string_of_aux pp_datetime

    let string_of_datetimezone = string_of_aux pp_datetimezone

    let string_of_date_basic = string_of_aux pp_date_basic

    let string_of_time_basic = string_of_aux pp_time_basic

    let string_of_datetime_basic = string_of_aux pp_datetime_basic

    let string_of_datetimezone_basic = string_of_aux pp_datetimezone_basic

end
