module V0 = struct
  module All_of = struct
    module Primary = struct
      module Ref_name = struct
        module Primary = struct
          module Exclude = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Include = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            exclude : Exclude.t option; [@default None]
            include_ : Include.t option; [@default None] [@key "include"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Repository_name = struct
        module Primary = struct
          module Exclude = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Include = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            exclude : Exclude.t option; [@default None]
            include_ : Include.t option; [@default None] [@key "include"]
            protected : bool option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        ref_name : Ref_name.t option; [@default None]
        repository_name : Repository_name.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Ref_name = struct
        module Primary = struct
          module Exclude = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Include = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            exclude : Exclude.t option; [@default None]
            include_ : Include.t option; [@default None] [@key "include"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Repository_name = struct
        module Primary = struct
          module Exclude = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Include = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            exclude : Exclude.t option; [@default None]
            include_ : Include.t option; [@default None] [@key "include"]
            protected : bool option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        ref_name : Ref_name.t option; [@default None]
        repository_name : Repository_name.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V1 = struct
  module All_of = struct
    module Primary = struct
      module Ref_name = struct
        module Primary = struct
          module Exclude = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Include = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            exclude : Exclude.t option; [@default None]
            include_ : Include.t option; [@default None] [@key "include"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Repository_id = struct
        module Primary = struct
          module Repository_ids = struct
            type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { repository_ids : Repository_ids.t option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        ref_name : Ref_name.t option; [@default None]
        repository_id : Repository_id.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Ref_name = struct
        module Primary = struct
          module Exclude = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Include = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            exclude : Exclude.t option; [@default None]
            include_ : Include.t option; [@default None] [@key "include"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Repository_id = struct
        module Primary = struct
          module Repository_ids = struct
            type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { repository_ids : Repository_ids.t option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        ref_name : Ref_name.t option; [@default None]
        repository_id : Repository_id.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

type t =
  | V0 of V0.t
  | V1 of V1.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
       (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
     ])

let to_yojson = function
  | V0 v -> V0.to_yojson v
  | V1 v -> V1.to_yojson v
