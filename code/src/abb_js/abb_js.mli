module Future : module type of Abb_fut_js with type 'a t = 'a Abb_fut_js.t

val sleep : float -> unit Future.t
