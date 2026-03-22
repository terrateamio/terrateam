module Results =
  struct
    type t = Terrat_api_components_api_user_item.t list[@@deriving
                                                         ((yojson
                                                             {
                                                               strict = false;
                                                               meta = true
                                                             }), show, eq)]
  end
type t = {
  results: Results.t }[@@deriving
                        ((yojson { strict = false; meta = true }), show, eq)]
