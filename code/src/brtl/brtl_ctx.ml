module Make(Abb : Abb_intf.S) = struct
  module Request = Cohttp.Request

  type ('a, 'b) t = { request : Request.t
                    ; metadata : Hmap.t
                    ; body: 'a
                    ; response : 'b
                    }

  let create request = { request; metadata = Hmap.empty; body = (); response = () }

  let request t = t.request

  let md_find key t = Hmap.find key t.metadata

  let md_add key v t = { t with metadata = Hmap.add key v t.metadata }

  let body t = t.body
  let set_body b t = { t with body = b }

  let response t = t.response
  let set_response r t = { t with response = r }
end
