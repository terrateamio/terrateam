module Module : sig
  type t

  val name : t -> string
  val source : t -> string
  val is_source_local_path : t -> bool
end

val collect_modules : Hcl_ast.t -> Module.t list
