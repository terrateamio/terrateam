insert into jobs (
  context_id,
  type,
  parameters,
  state,
  initiator
) values (
  $context_id,
  $type,
  $parameters,
  $state,
  $initiator
)
returning
    id,
    to_char(created_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'),
    to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')

