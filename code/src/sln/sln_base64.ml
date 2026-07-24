(* Padded RFC 4648, the variant {!is_valid} accepts. Padding is not optional: a padded encoding
   carries its own length, so a value that was truncated in transit or in storage fails to decode
   instead of decoding into a shorter string that looks intact. *)
let encode s = Base64.encode_string ~pad:true s

(* Fails rather than best-efforts. [Base64.decode_exn] pads a malformed input out with trailing NULs
   and returns it, which is the one outcome a caller storing opaque bytes must never get: it turns a
   damaged row into a plausible value nothing downstream can distinguish from the real one. *)
let decode s = Base64.decode ~pad:true s

let is_alphabet = function
  | 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '+' | '/' -> true
  | _ -> false

(* Checked by walking the string rather than by decoding it: the values this guards are plans large
   enough to have needed fragmenting in the first place, and decoding one only to discard the result
   would allocate the whole plan to answer a yes/no question. *)
let is_valid s =
  let len = CCString.length s in
  if len mod 4 <> 0 then false
  else
    let pad =
      if len = 0 then 0
      else if not (CCChar.equal (CCString.get s (len - 1)) '=') then 0
      else if CCChar.equal (CCString.get s (len - 2)) '=' then 2
      else 1
    in
    let stop = len - pad in
    let rec loop i = i >= stop || (is_alphabet (CCString.get s i) && loop (i + 1)) in
    loop 0
