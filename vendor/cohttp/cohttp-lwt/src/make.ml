module Request (IO : S.IO) = struct
  include Cohttp.Request
  include (Make (IO) : module type of Make (IO) with type t := t)
  end

module Response (IO : S.IO) = struct
  include Cohttp.Response
  include (Make (IO) : module type of Make (IO) with type t := t)
  end
