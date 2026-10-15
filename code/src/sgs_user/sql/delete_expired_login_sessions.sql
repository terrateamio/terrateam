delete from access_tokens
where kind = 'login'
  and expiration is not null
  and expiration < now()
returning id
