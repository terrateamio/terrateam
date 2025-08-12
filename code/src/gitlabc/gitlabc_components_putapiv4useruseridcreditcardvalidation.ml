type t = {
  credit_card_expiration_month : int;
  credit_card_expiration_year : int;
  credit_card_holder_name : string;
  credit_card_mask_number : string;
  credit_card_type : string;
  credit_card_validated_at : string;
  stripe_card_fingerprint : string option; [@default None]
  stripe_payment_method_xid : string option; [@default None]
  stripe_setup_intent_xid : string option; [@default None]
  zuora_payment_method_xid : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
