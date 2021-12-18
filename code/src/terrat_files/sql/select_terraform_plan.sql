select encode(data, 'base64') from terraform_plans
where change = $change and dir_path = $dir_path and workspace = $workspace
