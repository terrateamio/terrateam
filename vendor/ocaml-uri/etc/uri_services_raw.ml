let search_string keys k =
  let rec loop keys k low high =
    if low > high then (-1)
    else begin
      let mid = (high + low) / 2 in
      let diff = String.compare k keys.(mid) in
      if diff < 0 then loop keys k low (mid - 1)
      else if diff > 0 then loop keys k (mid + 1) high
      else mid
    end
  in loop keys k 0 (Array.length keys - 1)

let search_int keys k =
  let rec loop keys k low high =
    if low > high then (-1)
    else begin
      let mid = (high + low) / 2 in
      let diff = k - keys.(mid) in
      if diff < 0 then loop keys k low (mid - 1)
      else if diff > 0 then loop keys k (mid + 1) high
      else mid
    end
  in loop keys k 0 (Array.length keys - 1)

let lookup search (keys, values) k =
  let i = search keys k in
  if i < 0 then []
  else values.(i)

let service_of_tcp_port p =
  lookup search_int service_of_tcp_port_tables p

let service_of_udp_port p =
  lookup search_int service_of_udp_port_tables p

let tcp_port_of_service s =
  lookup search_string tcp_port_of_service_tables s

let udp_port_of_service s =
  lookup search_string udp_port_of_service_tables s

let port_of_uri ?default lookupfn uri =
  match Uri.port uri with
  |Some _port as x -> x
  |None -> begin
    match Uri.scheme uri, default with
    |None, None -> None
    |None, Some scheme
    |Some scheme, _ -> begin
      match lookupfn scheme with
      |[] -> None
      |hd::_ -> Some hd
     end
  end

let tcp_port_of_uri ?default uri =
  port_of_uri ?default tcp_port_of_service uri

let udp_port_of_uri ?default uri =
  port_of_uri ?default udp_port_of_service uri
