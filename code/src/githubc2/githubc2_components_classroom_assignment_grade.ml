module Primary = struct
  type t = {
    assignment_name : string;
    assignment_url : string;
    github_username : string;
    group_name : string option; [@default None]
    points_available : int;
    points_awarded : int;
    roster_identifier : string;
    starter_code_url : string;
    student_repository_name : string;
    student_repository_url : string;
    submission_timestamp : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
