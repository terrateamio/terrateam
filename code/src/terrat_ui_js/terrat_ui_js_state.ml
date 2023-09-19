type t = {
  client : Terrat_ui_js_client.t;
  user : Terrat_api_components.User.t;
  installations : Terrat_api_components.Installation.t list Brtl_js2.Note.S.t;
  selected_installation : Terrat_api_components.Installation.t;
}

let create ~client ~user ~installations ~selected_installation () =
  { client; user; installations; selected_installation }

let user t = t.user
let client t = t.client
let installations t = t.installations
let selected_installation t = t.selected_installation
