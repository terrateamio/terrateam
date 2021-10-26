-- 344 is the length of 256 bytes encoded in base64
alter table installation_env_vars
      add column session_key varchar(344),
      add column nonce varchar(16);

-- We have to clean up all the secrets because they are no longer valid.
delete from installation_env_vars where secret;
