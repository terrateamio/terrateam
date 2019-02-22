type err = [ Cohttp_abb.request_err | `Bad_response ]

val fetch : Uri.t -> (Jwk.t option, [> err ]) result Abb.Future.t
