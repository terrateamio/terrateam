select id, state from gitlab_installations where webhook_secret = $webhook_secret
