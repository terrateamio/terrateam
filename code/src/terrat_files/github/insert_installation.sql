insert into github_installations (
       access_tokens_url,
       created_at,
       html_url,
       id,
       login,
       suspended_at,
       target_type,
       updated_at,
       login_url,
       active,
       pub_key,
       secret
)
VALUES (
       $access_tokens_url,
       $created_at,
       $html_url,
       $id,
       $login,
       $suspended_at,
       $target_type,
       $updated_at,
       $login_url,
       true,
       $pub_key,
       $secret
)
on conflict do nothing
