type t = {
  credit_card_validated_at : string option; [@default None]
  user_id : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
