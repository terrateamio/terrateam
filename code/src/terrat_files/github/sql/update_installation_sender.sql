update github_installations
set sender = $sender,
    updated_at = now()
where id = $id