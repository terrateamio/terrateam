type t =
  | Access_token_create  (** Can create a new access token *)
  | Access_token_refresh
      (** Can only refresh an access token, this is used to turn a created access token into a
          usable acess token. *)
  | Installation_id of string  (** Limit the access token to the installation *)
  | Kv_store_read  (** Can read from the KV store *)
  | Kv_store_system_read
      (** Some KV store rows may be 'system' rows, this can be added to the kv store row to limit it
          to the system user. *)
  | Kv_store_system_write  (** System writes *)
  | Kv_store_write  (** Ability to write to the kv store. This includes deletes. *)
  | Mql_admin
      (** Allows the MQL endpoint to be accessed for any installation. This capability is
          intentionally absent from the public capabilities schema
          ([api_schemas/terrat/capabilities.json]) and therefore from the API and UI. It cannot be
          granted through the public access-token API (the create flow masks requested capabilities
          against the creating user's own, and no normal user holds this); tokens carrying it are
          minted out-of-band. *)
  | Vcs of string  (** Limit token to specific VCS. *)
[@@deriving show, eq, yojson]

(** Given a mask and a set of capabilities, return a new set capabilities that has, at most, the
    capabilities in the mask. *)
val mask : mask:t list -> t list -> t list
