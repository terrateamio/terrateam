let port_of_uri ?default lookupfn uri =
  match Uri.port uri with
  |Some port as x -> x
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
