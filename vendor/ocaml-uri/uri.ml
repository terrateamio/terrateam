type absolute = {
  scheme: string;
  authority: string option;
  path: string;
  query: string option;
  fragment: string option;
}  

let absolute_uri_to_string uri =
  let opt = function |None -> "???" |Some x -> x in
  Printf.sprintf "%s %s %s %s %s" 
    uri.scheme (opt uri.authority) uri.path (opt uri.query) (opt uri.fragment)
