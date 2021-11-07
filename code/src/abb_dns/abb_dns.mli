module Make (Abb : Abb_intf.S) : sig
  module Transport :
    Dns_client.S
      with type io_addr = [ `Plaintext of Ipaddr.t * int ]
       and type +'a io = 'a Abb.Future.t
       and type stack = unit

  include module type of Dns_client.Make (Transport)
end
