module Primary = struct
  module Links_ = struct
    module Primary = struct
      type t = {
        html : string;
        self : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    links_ : Links_.t; [@key "_links"]
    commit : Githubc2_components_commit.t;
    name : string;
    pattern : string option; [@default None]
    protected : bool;
    protection : Githubc2_components_branch_protection.t;
    protection_url : string;
    required_approving_review_count : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
