module Primary = struct
  type t = {
    branches_to_be_notified : string option; [@default None]
    disable_diffs : bool option; [@default None]
    push_events : bool option; [@default None]
    recipients : string;
    send_from_committer_email : bool option; [@default None]
    tag_push_events : bool option; [@default None]
    use_inherited_settings : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
