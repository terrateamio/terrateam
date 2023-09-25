module Primary = struct
  module Details = struct
    type t =
      | Secret_scanning_location_commit of Githubc2_components_secret_scanning_location_commit.t
      | Secret_scanning_location_issue_title of
          Githubc2_components_secret_scanning_location_issue_title.t
      | Secret_scanning_location_issue_body of
          Githubc2_components_secret_scanning_location_issue_body.t
      | Secret_scanning_location_issue_comment of
          Githubc2_components_secret_scanning_location_issue_comment.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v ->
             map
               (fun v -> Secret_scanning_location_commit v)
               (Githubc2_components_secret_scanning_location_commit.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_issue_title v)
               (Githubc2_components_secret_scanning_location_issue_title.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_issue_body v)
               (Githubc2_components_secret_scanning_location_issue_body.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_issue_comment v)
               (Githubc2_components_secret_scanning_location_issue_comment.of_yojson v));
         ])

    let to_yojson = function
      | Secret_scanning_location_commit v ->
          Githubc2_components_secret_scanning_location_commit.to_yojson v
      | Secret_scanning_location_issue_title v ->
          Githubc2_components_secret_scanning_location_issue_title.to_yojson v
      | Secret_scanning_location_issue_body v ->
          Githubc2_components_secret_scanning_location_issue_body.to_yojson v
      | Secret_scanning_location_issue_comment v ->
          Githubc2_components_secret_scanning_location_issue_comment.to_yojson v
  end

  module Type = struct
    let t_of_yojson = function
      | `String "commit" -> Ok "commit"
      | `String "issue_title" -> Ok "issue_title"
      | `String "issue_body" -> Ok "issue_body"
      | `String "issue_comment" -> Ok "issue_comment"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    details : Details.t;
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
