module Primary = struct
  module Students = struct
    type t = Githubc2_components_simple_classroom_user.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    assignment : Githubc2_components_simple_classroom_assignment.t;
    commit_count : int;
    grade : string;
    id : int;
    passing : bool;
    repository : Githubc2_components_simple_classroom_repository.t;
    students : Students.t;
    submitted : bool;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
