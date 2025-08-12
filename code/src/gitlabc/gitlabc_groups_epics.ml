module PostApiV4GroupsIdEpicsEpicIidAwardEmoji = struct
  module Parameters = struct
    type t = {
      epic_iid : int;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4GroupsIdEpicsEpicIidAwardEmoji.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/epics/{epic_iid}/award_emoji"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("epic_iid", Var (params.epic_iid, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4GroupsIdEpicsEpicIidAwardEmoji = struct
  module Parameters = struct
    type t = {
      epic_iid : int;
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/groups/{id}/epics/{epic_iid}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("epic_iid", Var (params.epic_iid, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4GroupsIdEpicsEpicIidAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      epic_iid : int;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/epics/{epic_iid}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("epic_iid", Var (params.epic_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4GroupsIdEpicsEpicIidAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      epic_iid : int;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/groups/{id}/epics/{epic_iid}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("epic_iid", Var (params.epic_iid, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4GroupsIdEpicsEpicIidNotesNoteIdAwardEmoji = struct
  module Parameters = struct
    type t = {
      epic_iid : int;
      id : int;
      note_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4GroupsIdEpicsEpicIidNotesNoteIdAwardEmoji.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/epics/{epic_iid}/notes/{note_id}/award_emoji"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int));
           ("epic_iid", Var (params.epic_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4GroupsIdEpicsEpicIidNotesNoteIdAwardEmoji = struct
  module Parameters = struct
    type t = {
      epic_iid : int;
      id : int;
      note_id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/groups/{id}/epics/{epic_iid}/notes/{note_id}/award_emoji"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int));
           ("epic_iid", Var (params.epic_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4GroupsIdEpicsEpicIidNotesNoteIdAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      epic_iid : int;
      id : int;
      note_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/epics/{epic_iid}/notes/{note_id}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("epic_iid", Var (params.epic_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4GroupsIdEpicsEpicIidNotesNoteIdAwardEmojiAwardId = struct
  module Parameters = struct
    type t = {
      award_id : int;
      epic_iid : int;
      id : int;
      note_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/groups/{id}/epics/{epic_iid}/notes/{note_id}/award_emoji/{award_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("award_id", Var (params.award_id, Int));
           ("id", Var (params.id, Int));
           ("epic_iid", Var (params.epic_iid, Int));
           ("note_id", Var (params.note_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
