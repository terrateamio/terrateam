type t = {
  port : int;
  read_header_timeout : Duration.t option;
  handler_timeout : Duration.t option;
}

let create ~port ~read_header_timeout ~handler_timeout =
  { port; read_header_timeout; handler_timeout }

let port t = t.port

let read_header_timeout t = t.read_header_timeout

let handler_timeout t = t.handler_timeout
