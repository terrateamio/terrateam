type ('user, 'vcs_config) t = {
  client : Terrat_ui_js_client.t;
  installations : Terrat_api_components.Installation.t list Brtl_js2.Note.S.t;
  notifications : Terrat_ui_js_notification.t Brtl_js2.Note.E.t;
  notify : Terrat_ui_js_notification.t Brtl_js2.Note.E.send;
  selected_installation : Terrat_api_components.Installation.t;
  server_config : Terrat_api_components.Server_config.t;
  vcs_config : 'vcs_config;
  user : 'user;
}

let create ~client ~user ~installations ~selected_installation ~server_config ~vcs_config () =
  let notifications, notify = Brtl_js2.Note.E.create () in
  {
    client;
    user;
    installations;
    selected_installation;
    notifications;
    notify;
    server_config;
    vcs_config;
  }

let client t = t.client
let installations t = t.installations
let notifications t = t.notifications

let notify t msg =
  let notification = Terrat_ui_js_notification.make ~msg () in
  t.notify notification

let selected_installation t = t.selected_installation
let server_config t = t.server_config
let user t = t.user
let vcs_config t = t.vcs_config
