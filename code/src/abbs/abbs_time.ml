module Span = struct
  include Abb_time.Span
end

include Abb_time.Make (Abb.Future) (Abb.Sys)
